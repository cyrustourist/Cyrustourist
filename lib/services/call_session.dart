import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'badge_service.dart';
import 'call_audio.dart';
import 'call_service.dart';
import 'call_texts.dart';

/// مشخصات یک تماس ورودی (از /api/call/incoming).
class IncomingCall {
  const IncomingCall({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromUsername,
    required this.offerSdp,
    this.hasPhoto = true,
    this.isFriend = false,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String offerSdp;
  final bool hasPhoto;
  final bool isFriend;

  static IncomingCall? fromJson(dynamic j) {
    if (j is! Map) return null;
    final id = '${j['id'] ?? ''}';
    final sdp = '${j['offer_sdp'] ?? ''}';
    if (id.isEmpty || sdp.isEmpty) return null;
    return IncomingCall(
      id: id,
      fromUid: '${j['from_uid'] ?? ''}',
      fromName: '${j['from_name'] ?? 'کاربر'}',
      fromUsername: '${j['from_username'] ?? ''}',
      offerSdp: sdp,
      hasPhoto: j['from_has_photo'] != false,
      isFriend: j['is_friend'] == true,
    );
  }
}

enum CallPhase { preparing, ringing, connecting, connected, ended }

/// یک تماس صوتی کامل (WebRTC، فقط صدا).
/// سیگنالینگ: یک offer و یک answer (بدون trickle) از طریق Worker؛ صدا مستقیم بین دو گوشی.
class CallSession extends ChangeNotifier {
  CallSession.outgoing({
    required this.peerUid,
    required this.peerName,
    this.isFriend = false,
    this.hasPhoto = true,
  })  : isCaller = true,
        _remoteOffer = null;

  CallSession.incoming(IncomingCall c)
      : isCaller = false,
        peerUid = c.fromUid,
        peerName = c.fromName,
        callId = c.id,
        isFriend = c.isFriend,
        hasPhoto = c.hasPhoto,
        _remoteOffer = c.offerSdp {
    phase = CallPhase.ringing;
  }

  final bool isCaller;
  final String peerUid;
  final String peerName;
  final bool hasPhoto;

  /// طرف مقابل در لیست دوستان من هست؟ (در حین تماس با «افزودن به دوستان» true می‌شود)
  bool isFriend;

  /// اگر گیرنده تماس را با پیام آماده رد کرد (فقط برای تماس‌گیرنده)
  String? peerMessageKey;
  String? callId;
  final String? _remoteOffer;

  CallPhase phase = CallPhase.preparing;
  String statusText = '';
  bool muted = false;
  bool speaker = false;
  Duration elapsed = Duration.zero;

  RTCPeerConnection? _pc;
  MediaStream? _local;
  Timer? _pollTimer;
  Timer? _clock;
  Timer? _connectTimeout;
  Timer? _disconnectTimer;
  DateTime? _connectedAt;
  Completer<void>? _gatherDone;
  Completer<void>? _candidateReady;
  bool _wantRelay = false;
  bool _answerApplied = false;
  bool _closed = false;
  bool _everConnected = false;
  bool _audioEntered = false;
  // تعداد تماس‌هایی که حالت صدای تماس را باز نگه داشته‌اند (تا پایان یک تماس، تماس بعدی را خراب نکند)
  static int _audioUsers = 0;
  int _pollFails = 0;
  int _tick = 0;

  bool get isActive => !_closed && phase != CallPhase.ended;

  static const List<Map<String, dynamic>> _fallbackIce = [
    {
      'urls': ['stun:stun.cloudflare.com:3478']
    },
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']
    },
  ];

  void _set(CallPhase p, String text) {
    phase = p;
    statusText = text;
    if (!_closed) _applySound(p);
    if (!_closed || p == CallPhase.ended) notifyListeners();
  }

  /// صدای هر مرحله: انتظار = بوق بلند تکراری، وصل شد = دو بیپ کوتاه، (پایان در _finish)
  void _applySound(CallPhase p) {
    switch (p) {
      case CallPhase.ringing:
        if (isCaller) {
          unawaited(CallAudio.ringback());
        } else {
          unawaited(CallAudio.startRing());
        }
        break;
      case CallPhase.connecting:
        unawaited(CallAudio.stopTone());
        unawaited(CallAudio.stopRing());
        break;
      case CallPhase.connected:
        unawaited(CallAudio.stopRing());
        unawaited(CallAudio.connected());
        break;
      default:
        break;
    }
  }

  /// حالت «تماس» سیستم صدا را (یک‌بار برای هر تماس) باز می‌کند.
  Future<void> _enterAudio() async {
    if (_audioEntered) return;
    _audioEntered = true;
    _audioUsers++;
    await CallAudio.enterCall();
  }

  // ------------------------------------------------------------------
  // آماده‌سازی مشترک: ICE + اتصال + میکروفن
  // ------------------------------------------------------------------
  // تنظیمات ICE از ورکر؛ حدود ۴۰ دقیقه نگه داشته می‌شود (اعتبار TURN یک‌ساعته است)
  static List<Map<String, dynamic>>? _iceCache;
  static DateTime? _iceAt;

  /// پیش‌دریافت تنظیمات اتصال تا موقع تماس یک درخواست کمتر لازم باشد.
  static Future<void> prefetchIce() async {
    await _loadIceStatic();
  }

  static Future<List<Map<String, dynamic>>> _loadIceStatic() async {
    final cached = _iceCache;
    final at = _iceAt;
    if (cached != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 40)) {
      return cached;
    }
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('GET', '/api/call/config', query: {'user_uid': uid});
      final list = j?['ice_servers'];
      if (list is List && list.isNotEmpty) {
        final parsed = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _iceCache = parsed;
        _iceAt = DateTime.now();
        return parsed;
      }
    } catch (_) {}
    return cached ?? _fallbackIce;
  }

  Future<List<Map<String, dynamic>>> _loadIce() => _loadIceStatic();

  static bool _hasTurn(List<Map<String, dynamic>> ice) {
    for (final s in ice) {
      final u = s['urls'];
      final list = u is List ? u : [u];
      if (list.any((e) => '$e'.startsWith('turn:') || '$e'.startsWith('turns:'))) return true;
    }
    return false;
  }

  bool _fgStarted = false;

  Future<bool> _preparePeer() async {
    final ice = await _loadIce();
    _gatherDone = Completer<void>();
    _candidateReady = Completer<void>();
    _wantRelay = _hasTurn(ice);

    final pc = await createPeerConnection({
      'iceServers': ice,
      'sdpSemantics': 'unified-plan',
    });
    _pc = pc;

    // به‌محض رسیدن اولین آدرس عمومی (srflx؛ و اگر TURN داریم relay) دیگر منتظر پایان کامل نمی‌مانیم
    pc.onIceCandidate = (RTCIceCandidate c) {
      final line = c.candidate ?? '';
      final good = _wantRelay ? line.contains(' typ relay') : (line.contains(' typ srflx') || line.contains(' typ relay'));
      if (good && _candidateReady != null && !_candidateReady!.isCompleted) {
        _candidateReady!.complete();
      }
    };

    pc.onIceGatheringState = (RTCIceGatheringState s) {
      if (s == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          _gatherDone != null &&
          !_gatherDone!.isCompleted) {
        _gatherDone!.complete();
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState s) {
      if (_closed) return;
      switch (s) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _disconnectTimer?.cancel();
          _connectTimeout?.cancel();
          if (phase != CallPhase.connected) {
            _connectedAt = DateTime.now();
            _clock?.cancel();
            _clock = Timer.periodic(const Duration(seconds: 1), (_) {
              if (_connectedAt != null) {
                elapsed = DateTime.now().difference(_connectedAt!);
                notifyListeners();
              }
            });
            _everConnected = true;
            _set(CallPhase.connected, 'وصل شد');
            // مسیر صدا (گوشی/بلندگو) را بعد از شروع صدای تماس دوباره اعمال می‌کنیم؛
            // WebRTC گاهی هنگام شروع صدا مسیر را به‌هم می‌زند.
            unawaited(_applyRoute());
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (!_closed) unawaited(_applyRoute());
            });
          }
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          if (phase == CallPhase.connected) {
            statusText = 'اتصال ضعیف است…';
            notifyListeners();
            _disconnectTimer?.cancel();
            _disconnectTimer = Timer(const Duration(seconds: 12), () {
              _finish('اتصال قطع شد.', notifyServer: true);
            });
          }
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _finish('اتصال برقرار نشد. ممکن است شبکه اجازهٔ ارتباط مستقیم ندهد.', notifyServer: true);
          break;
        default:
          break;
      }
    };

    try {
      _local = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    } catch (_) {
      await _finish('دسترسی به میکروفن داده نشد. در تنظیمات گوشی اجازه را فعال کنید.', notifyServer: false);
      return false;
    }
    for (final t in _local!.getAudioTracks()) {
      await pc.addTrack(t, _local!);
    }
    if (_closed) {
      // کاربر در حین آماده‌سازی قطع کرده بود
      try {
        for (final t in _local?.getTracks() ?? <MediaStreamTrack>[]) {
          await t.stop();
        }
        await _local?.dispose();
        await pc.close();
      } catch (_) {}
      _local = null;
      _pc = null;
      return false;
    }
    // سرویس پیش‌زمینه: تا وقتی کاربر از برنامه بیرون می‌رود، اندروید میکروفن را قطع نکند
    _fgStarted = true;
    unawaited(CallService.startForegroundCall(peerName));
    return true;
  }

  Future<String?> _localSdpAfterGathering() async {
    try {
      final done = _gatherDone?.future;
      final early = _candidateReady?.future.then((_) => Future<void>.delayed(const Duration(milliseconds: 700)));
      final waits = <Future<void>>[if (done != null) done, if (early != null) early];
      if (waits.isNotEmpty) {
        await Future.any<void>(waits).timeout(const Duration(seconds: 4), onTimeout: () {});
      }
    } catch (_) {}
    final d = await _pc?.getLocalDescription();
    final sdp = d?.sdp;
    return (sdp == null || sdp.isEmpty) ? null : sdp;
  }

  // ------------------------------------------------------------------
  // تماس‌گیرنده
  // ------------------------------------------------------------------
  Future<void> startOutgoing() async {
    _set(CallPhase.preparing, 'در حال آماده‌سازی…');
    await _enterAudio();
    if (_closed) return;
    if (!await _preparePeer()) return;
    try {
      final offer = await _pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
      await _pc!.setLocalDescription(offer);
      final sdp = await _localSdpAfterGathering();
      if (sdp == null) {
        await _finish('ساخت تماس ناموفق بود.', notifyServer: false);
        return;
      }
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/call/start', body: {
        'user_uid': uid,
        'to_uid': peerUid,
        'offer_sdp': sdp,
      });
      if (_closed) {
        // کاربر در حین آماده‌سازی قطع کرد
        final id = '${j?['call_id'] ?? ''}';
        if (id.isNotEmpty) {
          unawaited(BadgeService.call('POST', '/api/call/action', body: {'user_uid': uid, 'call_id': id, 'action': 'end'}));
        }
        return;
      }
      if (j == null) {
        await _finish('ارتباط با سرور برقرار نشد.', notifyServer: false);
        return;
      }
      if (j['success'] != true) {
        final err = '${j['error'] ?? ''}';
        final msg = switch (err) {
          'busy' => 'کاربر در تماس دیگری است.',
          'cannot_call' => 'امکان تماس با این کاربر وجود ندارد.',
          'slow_down' => 'تماس‌های شما زیاد شده؛ کمی بعد دوباره تلاش کنید.',
          'calls_disabled' => 'تماس صوتی موقتاً غیرفعال است.',
          'not_registered' || 'no_name' => 'برای تماس، ابتدا پروفایل خود را کامل کنید.',
          _ => '${j['message'] ?? 'تماس برقرار نشد.'}',
        };
        await _finish(msg, notifyServer: false);
        return;
      }
      callId = '${j['call_id']}';
      _set(CallPhase.ringing, 'در حال زنگ زدن…');
      _startPolling();
    } catch (e) {
      debugPrint('call start error: $e');
      await _finish('تماس برقرار نشد.', notifyServer: false);
    }
  }

  // ------------------------------------------------------------------
  // گیرنده
  // ------------------------------------------------------------------
  Future<void> acceptIncoming() async {
    if (isCaller || _remoteOffer == null || callId == null) return;
    _set(CallPhase.connecting, 'در حال اتصال…');
    await _enterAudio();
    if (_closed) return;
    if (!await _preparePeer()) return;
    try {
      await _pc!.setRemoteDescription(RTCSessionDescription(_remoteOffer, 'offer'));
      final answer = await _pc!.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
      await _pc!.setLocalDescription(answer);
      final sdp = await _localSdpAfterGathering();
      if (sdp == null) {
        await _finish('پاسخ به تماس ناموفق بود.', notifyServer: true);
        return;
      }
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/call/answer', body: {
        'user_uid': uid,
        'call_id': callId,
        'answer_sdp': sdp,
      });
      if (j == null || j['success'] != true) {
        await _finish('تماس منقضی شده یا لغو شده است.', notifyServer: false);
        return;
      }
      _armConnectTimeout();
      _startPolling();
    } catch (e) {
      debugPrint('call accept error: $e');
      await _finish('اتصال برقرار نشد.', notifyServer: true);
    }
  }

  Future<void> decline({String? msgKey, String? reason}) async {
    await _finish(reason ?? 'تماس رد شد.', notifyServer: false, action: 'decline', msgKey: msgKey);
  }

  Future<void> hangUp() async {
    await _finish('تماس پایان یافت.', notifyServer: true);
  }

  void toggleMute() {
    muted = !muted;
    for (final t in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speaker = !speaker;
    notifyListeners();
    await _applyRoute();
  }

  /// بلندگو/گوشی: هم از طریق flutter_webrtc و هم مستقیم از AudioManager اندروید
  /// (اگر یکی کار نکرد دیگری مسیر را درست می‌کند).
  Future<void> _applyRoute() async {
    try {
      await Helper.setSpeakerphoneOn(speaker);
    } catch (_) {}
    await CallAudio.setSpeaker(speaker);
  }

  // ------------------------------------------------------------------
  // پایش وضعیت تماس روی Worker
  // ------------------------------------------------------------------
  void _armConnectTimeout() {
    _connectTimeout?.cancel();
    _connectTimeout = Timer(const Duration(seconds: 25), () {
      if (phase != CallPhase.connected) {
        _finish('اتصال برقرار نشد. ممکن است شبکه اجازهٔ ارتباط مستقیم ندهد.', notifyServer: true);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollOnce());
  }

  /// پایش لغو/پایان تماس هنگام زنگ خوردن در گوشی گیرنده (تا زنگ بعد از لغو ادامه پیدا نکند).
  void startRingWatch() {
    if (isCaller || callId == null) return;
    unawaited(CallAudio.startRing());
    _startPolling();
  }

  bool _pollBusy = false;

  Future<void> _pollOnce() async {
    if (_closed || callId == null || _pollBusy) return;
    // فاصلهٔ پایش: تماس‌گیرنده هنگام زنگ هر ۱ ثانیه (پاسخ زودتر دیده شود)، هنگام اتصال هر ۲ ثانیه،
    // وقتی وصل هستیم هر ۴ ثانیه (کم‌کردن درخواست)
    _tick++;
    final every = phase == CallPhase.connected ? 4 : ((isCaller && phase == CallPhase.ringing) ? 1 : 2);
    if (_tick % every != 0) return;
    _pollBusy = true;
    try {
      await _pollInner();
    } finally {
      _pollBusy = false;
    }
  }

  Future<void> _pollInner() async {

    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/call/poll', query: {'user_uid': uid, 'call_id': callId!});
    if (_closed) return;
    if (j == null) {
      _pollFails++;
      if (_pollFails >= 8 && phase != CallPhase.connected) {
        await _finish('ارتباط با سرور قطع شد.', notifyServer: false);
      }
      return;
    }
    _pollFails = 0;
    if (j['success'] != true) {
      if ('${j['error']}' == 'not_found') await _finish('تماس پیدا نشد.', notifyServer: false);
      return;
    }
    final status = '${j['status']}';

    if (isCaller && status == 'accepted' && !_answerApplied) {
      final ans = '${j['answer_sdp'] ?? ''}';
      if (ans.isNotEmpty) {
        _answerApplied = true;
        try {
          await _pc?.setRemoteDescription(RTCSessionDescription(ans, 'answer'));
          _set(CallPhase.connecting, 'در حال اتصال…');
          _armConnectTimeout();
        } catch (e) {
          await _finish('اتصال برقرار نشد.', notifyServer: true);
        }
      }
      return;
    }

    switch (status) {
      case 'declined':
        final mk = '${j['message'] ?? ''}';
        if (isCaller && mk.isNotEmpty) {
          peerMessageKey = mk;
          await _finish(CT.t('peer_msg', {'name': peerName, 'msg': CT.msg(mk)}), notifyServer: false);
        } else {
          await _finish('تماس رد شد.', notifyServer: false);
        }
        break;
      case 'missed':
        await _finish(isCaller ? 'پاسخ داده نشد.' : 'تماس از دست رفت.', notifyServer: false);
        break;
      case 'canceled':
        await _finish('تماس لغو شد.', notifyServer: false);
        break;
      case 'accepted':
        // حساب من روی چند گوشی است و تماس را گوشی دیگر جواب داده
        if (!isCaller && phase == CallPhase.ringing) {
          await _finish('تماس روی دستگاه دیگر پاسخ داده شد.', notifyServer: false);
        }
        break;
      case 'ended':
        await _finish('تماس پایان یافت.', notifyServer: false);
        break;
    }
  }

  // ------------------------------------------------------------------
  // پایان (یک‌بار)
  // ------------------------------------------------------------------
  Future<void> _finish(String reason, {required bool notifyServer, String action = 'end', String? msgKey}) async {
    if (_closed) return;
    // بوق پایان: اگر تماس وصل بوده، در حال اتصال بوده یا تماس‌گیرنده منتظر جواب بوده
    final playEnd = _everConnected ||
        phase == CallPhase.connecting ||
        (isCaller && phase == CallPhase.ringing);
    _closed = true;
    unawaited(CallAudio.stopRing());
    if (playEnd) {
      unawaited(CallAudio.ended());
    } else {
      unawaited(CallAudio.stopTone());
    }
    _pollTimer?.cancel();
    _clock?.cancel();
    _connectTimeout?.cancel();
    _disconnectTimer?.cancel();

    final id = callId;
    if (id != null && (notifyServer || action == 'decline')) {
      try {
        final uid = await BadgeService.userUid();
        unawaited(BadgeService.call('POST', '/api/call/action', body: {
          'user_uid': uid,
          'call_id': id,
          'action': action,
          if (msgKey != null && action == 'decline') 'msg': msgKey,
        }));
      } catch (_) {}
    }
    if (_fgStarted) {
      _fgStarted = false;
      unawaited(CallService.stopForegroundCall());
    }

    try {
      for (final t in _local?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await _local?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _local = null;
    _pc = null;

    phase = CallPhase.ended;
    statusText = reason;
    notifyListeners();
    _leaveAudioLater(playEnd);
  }

  /// حالت صدای تماس را (بعد از پخش بوق پایان) به حالت عادی برمی‌گرداند،
  /// مگر اینکه تماس دیگری همین حالا شروع شده باشد.
  void _leaveAudioLater(bool waitForTone) {
    if (!_audioEntered) return;
    _audioEntered = false;
    Future<void>.delayed(Duration(milliseconds: waitForTone ? 800 : 50), () {
      if (_audioUsers > 0) _audioUsers--;
      if (_audioUsers == 0) unawaited(CallAudio.leaveCall());
    });
  }

  /// فراخوانی هنگام بسته‌شدن صفحه (مثلاً دکمهٔ برگشت).
  void disposeSession() {
    if (!_closed) {
      unawaited(_finish('تماس پایان یافت.', notifyServer: true, action: (!isCaller && phase == CallPhase.ringing) ? 'decline' : 'end'));
    }
  }
}
