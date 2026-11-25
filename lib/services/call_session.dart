import 'dart:async';
import 'dart:math' as math;

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
    this.isVideo = false,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String offerSdp;
  final bool hasPhoto;
  final bool isFriend;
  final bool isVideo;

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
      isVideo: '${j['call_type'] ?? ''}' == 'video',
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
    this.isVideo = false,
  })  : isCaller = true,
        _remoteOffer = null {
    speaker = isVideo;
  }

  CallSession.incoming(IncomingCall c)
      : isCaller = false,
        peerUid = c.fromUid,
        peerName = c.fromName,
        callId = c.id,
        isFriend = c.isFriend,
        hasPhoto = c.hasPhoto,
        isVideo = c.isVideo,
        _remoteOffer = c.offerSdp {
    phase = CallPhase.ringing;
    speaker = isVideo;
  }

  final bool isCaller;

  /// تماس تصویری؟ (با کلید «تماس تصویری» در پنل مدیریت روشن/خاموش می‌شود)
  final bool isVideo;
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

  // تماس تصویری
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;
  bool remoteVideoOn = false;
  bool cameraOff = false;
  bool frontCamera = true;

  /// نمایش‌دهنده‌های تصویر آمادهٔ استفاده‌اند (بعد از پایان تماس false می‌شود)
  bool get videoReady => _renderersReady && !_closed;
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
  // کانال کنترل مستقیم گوشی‌به‌گوشی: پایان تماس فوری و بدون سرور؛ پایش سرور بعد از اتصال کند می‌شود
  RTCDataChannel? _ctl;
  bool _ctlOpen = false;
  bool _byeSent = false;
  bool _audioEntered = false;
  // تعداد تماس‌هایی که حالت صدای تماس را باز نگه داشته‌اند (تا پایان یک تماس، تماس بعدی را خراب نکند)
  static int _audioUsers = 0;
  int _pollFails = 0;
  int _tick = 0;

  bool get isActive => !_closed && phase != CallPhase.ended;

  // لاگ زمان‌بندی: هر مرحله با فاصله از شروع (زدن «پاسخ» برای گیرنده، شروع تماس برای تماس‌گیرنده).
  // در logcat با فیلتر «call-timing» دیده می‌شود. آخرین گزارش در lastTimingReport هم می‌ماند.
  static String lastTimingReport = '';
  final Stopwatch _sw = Stopwatch();
  final List<String> _marks = [];

  void _mark(String label) {
    if (!_sw.isRunning) _sw.start();
    final line = '+${_sw.elapsedMilliseconds}ms $label';
    _marks.add(line);
    lastTimingReport = '${isCaller ? 'caller' : 'callee'} ${_marks.join(' | ')}';
    debugPrint('call-timing ${isCaller ? 'caller' : 'callee'} $line');
  }

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

  // پاسخ /api/call/config (ICE + کلیدهای پنل) با کش ۶۰ ثانیه‌ای: «بررسی کلید» و «گرفتن ICE» یک درخواست مشترک دارند.
  static Map<String, dynamic>? _cfg;
  static DateTime? _cfgAt;
  static Future<Map<String, dynamic>?>? _cfgInflight;

  /// پاسخ config را برمی‌گرداند؛ null یعنی ورکر جواب نداد. [force] کش را نادیده می‌گیرد.
  static Future<Map<String, dynamic>?> loadConfig({bool force = false}) {
    final at = _cfgAt;
    if (!force && _cfg != null && at != null && DateTime.now().difference(at) < const Duration(seconds: 60)) {
      return Future.value(_cfg);
    }
    return _cfgInflight ??= () async {
      try {
        final uid = await BadgeService.userUid();
        final j = await BadgeService.call('GET', '/api/call/config', query: {'user_uid': uid}, timeout: const Duration(seconds: 6));
        if (j != null) {
          _cfg = j;
          _cfgAt = DateTime.now();
          final list = j['ice_servers'];
          if (list is List && list.isNotEmpty) {
            _iceCache = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            _iceAt = DateTime.now();
          }
        }
        return j;
      } catch (_) {
        return null;
      } finally {
        _cfgInflight = null;
      }
    }();
  }

  static Future<List<Map<String, dynamic>>> _loadIceStatic() async {
    final cached = _iceCache;
    final at = _iceAt;
    if (cached != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 40)) {
      return cached;
    }
    await loadConfig(force: true);
    return _iceCache ?? cached ?? _fallbackIce;
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

  /// میکروفن (و در تماس تصویری دوربین). تصویر اول با کیفیت بهتر (حدود qHD، ۲۴ فریم) خواسته می‌شود؛
  /// اگر دوربین نپذیرفت، همان تصویر سبک قبلی (۳۲۰×۲۴۰، ۱۵ فریم). بیت‌ریت واقعی بعد از اتصال محدود می‌شود.
  Future<MediaStream?> _openMedia() async {
    final nav = navigator.mediaDevices;
    if (!isVideo) {
      try {
        return await nav.getUserMedia({'audio': true, 'video': false});
      } catch (_) {
        return null;
      }
    }
    try {
      return await nav.getUserMedia({
        'audio': true,
        'video': {
          'mandatory': {'minWidth': '960', 'minHeight': '540', 'minFrameRate': '24'},
          'facingMode': 'user',
          'optional': [],
        },
      });
    } catch (_) {}
    try {
      return await nav.getUserMedia({
        'audio': true,
        'video': {
          'mandatory': {'minWidth': '320', 'minHeight': '240', 'minFrameRate': '15'},
          'facingMode': 'user',
          'optional': [],
        },
      });
    } catch (_) {
      return null;
    }
  }

  Future<bool>? _peerBuild;
  Future<bool>? _offerApplied;

  /// ساخت اتصال (بدون میکروفن). برای گیرنده همان لحظهٔ زنگ خوردن صدا زده می‌شود تا با زدن «پاسخ» آماده باشد.
  Future<bool> _ensurePeer() => _peerBuild ??= _buildPeer();

  /// گیرنده: هنگام زنگ خوردن اتصال را می‌سازد و offer را می‌گذارد؛ میکروفن باز نمی‌شود.
  /// آدرس‌های ICE (از جمله relay) در این فاصله از پیش جمع می‌شوند (iceCandidatePoolSize)،
  /// پس موقع پاسخ دیگر چند ثانیه منتظر relay نمی‌مانیم.
  Future<bool> _ensureOfferApplied() => _offerApplied ??= () async {
        if (isCaller || _remoteOffer == null) return false;
        if (!await _ensurePeer()) return false;
        final pc = _pc;
        if (pc == null || _closed) return false;
        await pc.setRemoteDescription(RTCSessionDescription(_remoteOffer, 'offer'));
        _mark('offer applied (prewarm)');
        return true;
      }();

  Future<bool> _preparePeer() async {
    // میکروفن و ساخت اتصال هم‌زمان پیش می‌روند (اگر اتصال از زمان زنگ خوردن آماده باشد، فقط میکروفن می‌ماند)
    final micF = _openMedia();
    if (!await _ensurePeer()) {
      await _dropMic(micF);
      return false;
    }
    final pc = _pc;
    if (pc == null || _closed) {
      await _dropMic(micF);
      return false;
    }
    return _attachMedia(pc, micF);
  }

  Future<void> _dropMic(Future<MediaStream?> micF) async {
    try {
      final m = await micF;
      for (final t in m?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await m?.dispose();
    } catch (_) {}
  }

  Future<bool> _buildPeer() async {
    final ice = await _loadIce();
    if (_closed) return false;
    _gatherDone = Completer<void>();
    _candidateReady = Completer<void>();
    _wantRelay = _hasTurn(ice);

    final pc = await createPeerConnection({
      'iceServers': ice,
      'sdpSemantics': 'unified-plan',
      // یک مسیر مشترک برای صدا و تصویر (نصف آدرس‌ها و آزمون‌های اتصال) و جمع‌آوری آدرس از پیش
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 2,
    });
    _pc = pc;
    // کانال کنترل: تماس‌گیرنده می‌سازد (قبل از offer)، گیرنده از onDataChannel می‌گیرد.
    // اگر طرف مقابل نسخهٔ قدیمی باشد کانال باز نمی‌شود و همان پایش سریع قبلی کار می‌کند.
    pc.onDataChannel = (RTCDataChannel ch) {
      if (ch.label == 'ctl') _bindCtl(ch);
    };
    if (isCaller) {
      try {
        _bindCtl(await pc.createDataChannel('ctl', RTCDataChannelInit()..ordered = true));
      } catch (_) {}
    }
    if (isVideo) {
      try {
        await localRenderer.initialize();
        await remoteRenderer.initialize();
        _renderersReady = true;
      } catch (_) {}
    }

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

    pc.onTrack = (RTCTrackEvent e) {
      if (_closed || !isVideo || !_renderersReady) return;
      if (e.track.kind == 'video' && e.streams.isNotEmpty) {
        remoteRenderer.srcObject = e.streams.first;
        remoteVideoOn = true;
        notifyListeners();
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
            _mark('connected');
            unawaited(_pathKind().then((k) => _mark('path=$k')));
            _set(CallPhase.connected, 'وصل شد');
            // مسیر صدا (گوشی/بلندگو) را بعد از شروع صدای تماس دوباره اعمال می‌کنیم؛
            // WebRTC گاهی هنگام شروع صدا مسیر را به‌هم می‌زند.
            unawaited(_applyRoute());
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (!_closed) unawaited(_applyRoute());
            });
            if (isVideo) {
              unawaited(_tuneVideoSender());
              // مسیر انتخاب‌شده ممکن است چند ثانیه بعد از رله به مستقیم عوض شود
              Future<void>.delayed(const Duration(seconds: 8), () {
                if (!_closed) unawaited(_tuneVideoSender());
              });
            }
          } else if (statusText != 'وصل شد') {
            // اتصال بعد از «اتصال ضعیف است…» برگشت
            statusText = 'وصل شد';
            notifyListeners();
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
    if (_closed) {
      try {
        await pc.close();
      } catch (_) {}
      return false;
    }
    return true;
  }

  Future<bool> _attachMedia(RTCPeerConnection pc, Future<MediaStream?> micF) async {
    _local = await micF;
    _mark('media opened');
    if (_local == null) {
      await _finish(isVideo ? 'دسترسی به میکروفن یا دوربین داده نشد. در تنظیمات گوشی اجازه را فعال کنید.' : 'دسترسی به میکروفن داده نشد. در تنظیمات گوشی اجازه را فعال کنید.', notifyServer: false);
      return false;
    }
    for (final t in _local!.getTracks()) {
      await pc.addTrack(t, _local!);
    }
    if (isVideo && _renderersReady) localRenderer.srcObject = _local;
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
    unawaited(CallService.startForegroundCall(peerName, video: isVideo));
    return true;
  }

  void _bindCtl(RTCDataChannel ch) {
    _ctl = ch;
    _ctlOpen = ch.state == RTCDataChannelState.RTCDataChannelOpen;
    ch.onDataChannelState = (RTCDataChannelState s) {
      _ctlOpen = s == RTCDataChannelState.RTCDataChannelOpen;
      // کانال که باز شد، وضعیت نمایش و کیفیت من را به طرف مقابل می‌گوییم
      if (_ctlOpen) _sendViewState();
    };
    ch.onMessage = (RTCDataChannelMessage m) {
      final t = m.text;
      if (t == 'bye') {
        unawaited(_peerBye());
      } else if (t.startsWith('view:')) {
        final v = double.tryParse(t.substring(5));
        if (v != null) {
          _peerViewArea = v.clamp(0.05, 1.0).toDouble();
          unawaited(_tuneVideoSender());
        }
      } else if (t.startsWith('q:')) {
        _peerQuality = t.substring(2);
        unawaited(_tuneVideoSender());
      } else if (t.startsWith('weak:')) {
        _peerWeak = t.endsWith('1');
        unawaited(_tuneVideoSender());
      }
    };
  }

  /// طرف مقابل از همین کانال مستقیم گفت تماس تمام شد (فوری، بدون سرور).
  Future<void> _peerBye() async {
    if (_closed) return;
    _byeSent = true; // پیام برگشتی نفرستیم
    await _finish('تماس پایان یافت.', notifyServer: false);
  }

  /// نوع مسیر انتخاب‌شدهٔ اتصال از getStats: 'direct' | 'relay' | 'unknown'.
  Future<String> _pathKind() async {
    try {
      final pc = _pc;
      if (pc == null) return 'unknown';
      final reports = await pc.getStats();
      final byId = <String, StatsReport>{for (final r in reports) r.id: r};
      StatsReport? pair;
      for (final r in reports) {
        if (r.type == 'transport' && r.values['selectedCandidatePairId'] != null) {
          pair = byId['${r.values['selectedCandidatePairId']}'];
          if (pair != null) break;
        }
      }
      if (pair == null) {
        for (final r in reports) {
          if (r.type == 'candidate-pair' && '${r.values['state']}' == 'succeeded' && '${r.values['nominated']}' == 'true') {
            pair = r;
            break;
          }
        }
      }
      if (pair == null) return 'unknown';
      final l = byId['${pair.values['localCandidateId']}'];
      final rm = byId['${pair.values['remoteCandidateId']}'];
      if (l == null && rm == null) return 'unknown';
      final lt = '${l?.values['candidateType'] ?? ''}';
      final rt = '${rm?.values['candidateType'] ?? ''}';
      if (lt == 'relay' || rt == 'relay') return 'relay';
      if (lt.isEmpty && rt.isEmpty) return 'unknown';
      return 'direct';
    } catch (_) {
      return 'unknown';
    }
  }

  // ------------------------------------------------------------------
  // کیفیت تطبیقی تصویر: رزولوشن و بیت‌ریت ارسالی با اندازهٔ قابی که طرف مقابل
  // برای تصویر من استفاده می‌کند (کانال کنترل مستقیم، بدون سرور) و با ضعف گوشی و مسیر رله تنظیم می‌شود.
  // ------------------------------------------------------------------
  static const List<int> _tierH = [240, 360, 480, 540, 720];
  static const List<int> _tierKbps = [150, 300, 450, 550, 900];
  static const List<String> qualityModes = ['auto', '240', '360', '480', '540', '720'];

  /// کیفیتی که من می‌خواهم دریافت کنم: 'auto' یا یکی از ارتفاع‌های بالا (برای طرف مقابل ارسال می‌شود)
  String qualityMode = 'auto';

  /// گوشی ضعیف: سقف ۵۴۰p و فریم کمتر (برای طرف مقابل هم ارسال می‌شود)
  bool weakDevice = false;

  /// خلاصهٔ آخرین تنظیم ارسال، مثلاً «۳۶۰p · ۳۰۰kbps · مستقیم»
  String sendInfo = '';

  double _myViewArea = 1.0; // سهم قاب تصویر مقابل از صفحهٔ من
  double _peerViewArea = 1.0; // سهم قابی که طرف مقابل به تصویر من می‌دهد
  String _peerQuality = 'auto';
  bool _peerWeak = false;
  bool _tuning = false;
  bool _tuneAgain = false;

  /// صفحه سهم قاب تصویر مقابل را (۰ تا ۱) اعلام می‌کند؛ طرف مقابل رزولوشن ارسال را با آن تنظیم می‌کند.
  void setViewArea(double area) {
    final a = area.clamp(0.05, 1.0).toDouble();
    if ((a - _myViewArea).abs() < 0.03) return;
    _myViewArea = a;
    _sendViewState(onlyArea: true);
  }

  void setQualityMode(String mode) {
    if (!qualityModes.contains(mode)) return;
    qualityMode = mode;
    _sendViewState();
    notifyListeners();
  }

  void setWeakDevice(bool v) {
    weakDevice = v;
    _sendViewState();
    unawaited(_tuneVideoSender());
    notifyListeners();
  }

  void _sendViewState({bool onlyArea = false}) {
    if (!_ctlOpen) return;
    try {
      _ctl?.send(RTCDataChannelMessage('view:${_myViewArea.toStringAsFixed(2)}'));
      if (!onlyArea) {
        _ctl?.send(RTCDataChannelMessage('q:$qualityMode'));
        _ctl?.send(RTCDataChannelMessage('weak:${weakDevice ? 1 : 0}'));
      }
    } catch (_) {}
  }

  /// سقف بیت‌ریت، رزولوشن و فریم تصویرِ خروجی را تنظیم می‌کند (وسط تماس هم بدون برقراری دوباره).
  /// تخمین پهنای باند خود WebRTC باز هم با شبکه تطبیق می‌دهد؛ این‌ها فقط سقف‌اند.
  Future<void> _tuneVideoSender() async {
    if (_closed || !isVideo) return;
    if (_tuning) {
      _tuneAgain = true;
      return;
    }
    _tuning = true;
    try {
      final pc = _pc;
      if (pc == null) return;
      final kind = await _pathKind();
      final anyWeak = weakDevice || _peerWeak;

      int idx;
      if (_peerQuality == 'auto') {
        final a = _peerViewArea;
        idx = a <= 0.32 ? 0 : (a <= 0.55 ? 1 : (a <= 0.80 ? 3 : 4));
        if (anyWeak) idx -= 1;
      } else {
        idx = _tierH.indexOf(int.tryParse(_peerQuality) ?? 720);
        if (idx < 0) idx = 4;
      }
      if (anyWeak) idx = math.min(idx, 3);
      if (kind == 'relay') idx = math.min(idx, 2); // مسیر رله: سهمیهٔ سرور نسوزد
      if (kind == 'unknown') idx = math.min(idx, 3);
      idx = math.max(idx, 0);

      final targetH = _tierH[idx];
      final kbps = _tierKbps[idx];
      var fps = 30;
      if (kind == 'relay') fps = 20;
      if (_peerWeak) fps = math.min(fps, 20);
      if (weakDevice) fps = 15;

      // ضلع کوتاه تصویر دوربین (۵۴۰ اگر نامشخص بود) تا به ارتفاع هدف کوچک شود
      var shortSide = 540;
      for (final t in _local?.getVideoTracks() ?? <MediaStreamTrack>[]) {
        try {
          final st = t.getSettings();
          final w = (st['width'] as num?)?.toInt() ?? 0;
          final h = (st['height'] as num?)?.toInt() ?? 0;
          if (w > 0 && h > 0) shortSide = math.min(w, h);
        } catch (_) {}
      }
      final scale = math.max(1.0, shortSide / targetH);

      for (final s in await pc.getSenders()) {
        if (s.track?.kind != 'video') continue;
        final params = s.parameters;
        final enc = params.encodings;
        if (enc == null || enc.isEmpty) continue;
        for (final e in enc) {
          e.maxBitrate = kbps * 1000;
          e.maxFramerate = fps;
          e.scaleResolutionDownBy = scale;
        }
        await s.setParameters(params);
      }
      final nextInfo = '${targetH}p · ${kbps}kbps · $fps fps · ${kind == 'relay' ? 'relay' : (kind == 'direct' ? 'direct' : '?')}';
      if (nextInfo != sendInfo) {
        sendInfo = nextInfo;
        notifyListeners();
      }
      debugPrint('call video tuned: path=$kind $nextInfo area=${_peerViewArea.toStringAsFixed(2)} q=$_peerQuality');
    } catch (e) {
      debugPrint('call video tune failed: $e');
    } finally {
      _tuning = false;
      if (_tuneAgain) {
        _tuneAgain = false;
        unawaited(_tuneVideoSender());
      }
    }
  }

  // سقف پهنای باند تصویر (کیلوبیت بر ثانیه) در SDP؛ مصرف TURN و اینترنت کاربر را کم می‌کند.
  // سقف دقیق‌تر بعد از اتصال و بر اساس اندازهٔ قاب، ضعف گوشی و نوع مسیر در _tuneVideoSender اعمال می‌شود.
  static const int _videoMaxKbps = 900;

  static String _capVideo(String sdp) {
    if (sdp.isEmpty || !sdp.contains('m=video')) return sdp;
    try {
      final eol = sdp.contains('\r\n') ? '\r\n' : '\n';
      final lines = sdp.split(eol);
      final out = <String>[];
      var inVideo = false;
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (l.startsWith('m=')) inVideo = l.startsWith('m=video');
        out.add(l);
        if (inVideo && l.startsWith('c=') && !(i + 1 < lines.length && lines[i + 1].startsWith('b='))) {
          out.add('b=AS:$_videoMaxKbps');
        }
      }
      return out.join(eol);
    } catch (_) {
      return sdp;
    }
  }

  // سقف بیت‌ریت صدا (Opus): حجم مصرف TURN و پهنای باند را کم می‌کند.
  // اگر کیفیت کافی نبود فقط همین عدد را بالا ببرید (مثلاً 32000).
  static const int _opusMaxBitrate = 24000;

  /// پارامترهای Opus را در SDP محدود می‌کند (maxaveragebitrate + مونو + FEC + DTX).
  /// هر طرف در SDP خودش می‌گوید «حداکثر چقدر برایم بفرست»؛ پس روی هر دو گوشی اعمال می‌شود.
  static String _capOpus(String? sdp) {
    if (sdp == null || sdp.isEmpty) return sdp ?? '';
    try {
      final eol = sdp.contains('\r\n') ? '\r\n' : '\n';
      final lines = sdp.split(eol);
      String? pt;
      int rtpmapIdx = -1;
      for (var i = 0; i < lines.length; i++) {
        final m = RegExp(r'^a=rtpmap:(\d+) opus/48000', caseSensitive: false).firstMatch(lines[i]);
        if (m != null) {
          pt = m.group(1);
          rtpmapIdx = i;
          break;
        }
      }
      if (pt == null) return sdp;
      final want = <String, String>{
        'maxaveragebitrate': '$_opusMaxBitrate',
        'stereo': '0',
        'useinbandfec': '1',
        'usedtx': '1',
      };
      final fmtpPrefix = 'a=fmtp:$pt ';
      var fmtpIdx = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith(fmtpPrefix)) {
          fmtpIdx = i;
          break;
        }
      }
      if (fmtpIdx >= 0) {
        final old = lines[fmtpIdx].substring(fmtpPrefix.length).split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
        final kept = old.where((e) => !want.containsKey(e.split('=').first.toLowerCase())).toList();
        final merged = [...kept, ...want.entries.map((e) => '${e.key}=${e.value}')];
        lines[fmtpIdx] = fmtpPrefix + merged.join(';');
      } else {
        lines.insert(rtpmapIdx + 1, fmtpPrefix + want.entries.map((e) => '${e.key}=${e.value}').join(';'));
      }
      return lines.join(eol);
    } catch (_) {
      return sdp;
    }
  }

  Future<String?> _localSdpAfterGathering() async {
    try {
      final done = _gatherDone?.future;
      final early = _candidateReady?.future.then((_) => Future<void>.delayed(const Duration(milliseconds: 250)));
      final waits = <Future<void>>[if (done != null) done, if (early != null) early];
      if (waits.isNotEmpty) {
        await Future.any<void>(waits).timeout(const Duration(seconds: 3), onTimeout: () {});
      }
    } catch (_) {}
    final d = await _pc?.getLocalDescription();
    final sdp = d?.sdp;
    _mark('ice ready (relay=${sdp?.contains(' typ relay') ?? false}, wantRelay=$_wantRelay)');
    return (sdp == null || sdp.isEmpty) ? null : sdp;
  }

  // ------------------------------------------------------------------
  // تماس‌گیرنده
  // ------------------------------------------------------------------
  Future<void> startOutgoing() async {
    _mark('start');
    _set(CallPhase.preparing, 'در حال آماده‌سازی…');
    await _enterAudio();
    if (_closed) return;
    if (!await _preparePeer()) return;
    try {
      final offer = await _pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': isVideo ? 1 : 0});
      await _pc!.setLocalDescription(RTCSessionDescription(_capVideo(_capOpus(offer.sdp)), offer.type));
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
        'call_type': isVideo ? 'video' : 'voice',
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
          'not_registered' || 'no_name' => 'برای تماس، ابتدا پروفایل خود را کامل کنید.',
          _ => '${j['message'] ?? 'تماس برقرار نشد.'}',
        };
        await _finish(msg, notifyServer: false);
        return;
      }
      callId = '${j['call_id']}';
      _mark('start posted, ringing');
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
    _sw
      ..reset()
      ..start();
    _marks.clear();
    _mark('accept tapped (prewarmed=${_offerApplied != null})');
    _set(CallPhase.connecting, 'در حال اتصال…');
    await _enterAudio();
    if (_closed) return;
    if (!await _preparePeer()) return;
    try {
      // اگر موقع زنگ خوردن انجام شده باشد همان نتیجه برمی‌گردد؛ وگرنه همین‌جا انجام می‌شود
      if (!await _ensureOfferApplied()) {
        if (!_closed) await _finish('اتصال برقرار نشد.', notifyServer: true);
        return;
      }
      final answer = await _pc!.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': isVideo ? 1 : 0});
      await _pc!.setLocalDescription(RTCSessionDescription(_capVideo(_capOpus(answer.sdp)), answer.type));
      final sdp = await _localSdpAfterGathering();
      if (sdp == null) {
        await _finish('پاسخ به تماس ناموفق بود.', notifyServer: true);
        return;
      }
      _mark('answer ready, posting');
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/call/answer', body: {
        'user_uid': uid,
        'call_id': callId,
        'answer_sdp': sdp,
      });
      _mark('answer posted (ok=${j?['success'] == true})');
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

  void toggleCamera() {
    cameraOff = !cameraOff;
    for (final t in _local?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !cameraOff;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final tracks = _local?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    try {
      await Helper.switchCamera(tracks.first);
      frontCamera = !frontCamera;
      notifyListeners();
    } catch (_) {}
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
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _pollOnce());
  }

  /// پایش لغو/پایان تماس هنگام زنگ خوردن در گوشی گیرنده (تا زنگ بعد از لغو ادامه پیدا نکند).
  void startRingWatch({bool silent = false}) {
    if (isCaller || callId == null) return;
    if (!silent) unawaited(CallAudio.startRing());
    _startPolling();
    // آماده‌سازی هنگام زنگ خوردن: ساخت اتصال + جمع‌آوری آدرس‌ها + offer، بدون باز کردن میکروفن
    _sw.start();
    _mark('ringing, prewarm start');
    unawaited(_ensureOfferApplied().catchError((Object e) {
      debugPrint('call prewarm failed: $e');
      return false;
    }));
  }

  bool _pollBusy = false;

  Future<void> _pollOnce() async {
    if (_closed || callId == null || _pollBusy) return;
    // کم‌فشار برای ورکر (تایمر ۵۰۰ms؛ هر «تیک» نیم ثانیه):
    //  - تماس‌گیرنده منتظر جواب: ۱ث   - در حال اتصال: ۱ث   - گیرنده در حال زنگ: ۲ث
    //  - وصل‌شده و کانال مستقیم باز: ۳۰ث (پایان تماس از همان کانال می‌رسد؛ سرور فقط پشتیبان است)
    //  - وصل‌شده بدون کانال: ۴ث
    // بعد از خطاهای پیاپی فاصله بیشتر می‌شود تا ورکر زیر فشار بیشتر نرود.
    _tick++;
    final base = phase == CallPhase.connected
        ? (_ctlOpen ? 60 : 8)
        : ((isCaller && phase == CallPhase.ringing) || phase == CallPhase.connecting ? 2 : 4);
    final every = base * (1 + (_pollFails > 4 ? 4 : _pollFails));
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
        _mark('answer received by poll');
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
    final disposeRenderers = _renderersReady;
    _renderersReady = false;
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
    // پایان فوری برای طرف مقابل از مسیر مستقیم گوشی‌به‌گوشی (سرور فقط پشتیبان است)
    if (_ctlOpen && !_byeSent && _everConnected) {
      _byeSent = true;
      try {
        await _ctl?.send(RTCDataChannelMessage('bye'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
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
    if (disposeRenderers) {
      // یک فریم صبر می‌کنیم تا نمایش تصویر از صفحه برداشته شود، بعد نمایش‌دهنده‌ها بسته شوند
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      try {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
        await localRenderer.dispose();
        await remoteRenderer.dispose();
      } catch (_) {}
    }
    _local = null;
    _pc = null;
    _ctl = null;
    _ctlOpen = false;

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
