import 'dart:async';
import 'dart:convert';
import 'dart:io' show NetworkInterface, InternetAddressType;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_transfer_service.dart' show PendingConn;
import 'offline_mesh_service.dart';
import 'user_profile_service.dart';

const MethodChannel _screenChannel = MethodChannel('cyrus/livecall');

/// تماس تصویری زنده بین دو گوشی بدون اینترنت (نسخهٔ آزمایشی).
///
/// - پیدا کردن گوشی مقابل و تأیید کد: با Nearby Connections (مثل تماس صوتی آفلاین).
/// - علامت‌دهی (offer/answer/ICE): از همان اتصال Nearby، فقط چند پیام کوچک JSON.
/// - تصویر و صدا: با WebRTC مستقیم بین دو گوشی، بدون هیچ سرور (iceServers خالی). WebRTC صدا و تصویر را
///   با DTLS‑SRTP رمز می‌کند و خودش کیفیت را با شبکه تنظیم می‌کند.
/// - شرط شبکه: دو گوشی باید روی یک شبکهٔ محلی باشند (یک وای‌فای، حتی مودم بدون اینترنت، یا هات‌اسپات یکی از دو گوشی).
///   Nearby به برنامه آدرس IP نمی‌دهد؛ اگر شبکهٔ مشترکی نباشد اتصال تصویر برقرار نمی‌شود و پیام مناسب نشان داده می‌شود.
///
/// این سرویس از تماس صوتی/تصویری آنلاین (call_service / call_session) کاملاً جداست و به آن‌ها دست نمی‌زند.
class LiveVideoService extends ChangeNotifier {
  LiveVideoService._();
  static final LiveVideoService instance = LiveVideoService._();

  static const String _serviceId = 'ir.cyrustourist.video';

  /// idle | wait | search | connecting | incall | ended | lost
  String stage = 'idle';

  /// '' | perm | cam | start | rejected | failed | net | media
  String error = '';
  String myName = '';
  String peerName = '';
  PendingConn? pending;
  final Map<String, String> found = <String, String>{};

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;

  /// 0 = ۳۶۰p، 1 = ۴۸۰p، 2 = ۷۲۰p (قبل از شروع انتخاب می‌شود)
  int quality = 1;

  bool muted = false;
  bool cameraOff = false;
  bool speaker = true;
  bool frontCamera = true;
  bool remoteVideoOn = false;
  int seconds = 0;

  // آمار برای سنجش
  int? rttMs;
  int lossPct = 0;
  int rxKbps = 0;
  int fps = 0;
  String resolution = '';
  String pathInfo = '';
  String myFp = '';
  String peerFp = '';

  /// آدرس‌های شبکهٔ محلی دو گوشی (برای عیب‌یابی وقتی تصویر وصل نمی‌شود)
  String myIps = '';
  String peerIps = '';
  bool _restarted = false;
  bool _wifiBound = false;
  Timer? _restartTimer;

  String _mode = '';
  String _peerId = '';
  bool _nearbyOpen = false;
  final Map<String, String> _names = <String, String>{};

  RTCPeerConnection? _pc;
  MediaStream? _local;
  RTCDataChannel? _dc;
  bool _remoteSet = false;
  bool _ending = false;
  bool _preparing = false;
  final List<Map<String, dynamic>> _early = <Map<String, dynamic>>[];
  final List<RTCIceCandidate> _pendingCands = <RTCIceCandidate>[];

  Timer? _clockTimer;
  Timer? _statsTimer;
  Timer? _connTimeout;
  DateTime? _t0;
  int _prevBytes = 0;
  int _prevLost = 0;
  int _prevRecv = 0;
  DateTime? _prevAt;

  Future<void> _ident() async {
    if (myName.isNotEmpty) return;
    var n = '';
    try {
      final prof = await UserProfileService.load();
      n = prof.displayName.trim().isNotEmpty ? prof.displayName.trim() : prof.username.trim();
    } catch (_) {}
    myName = n.isEmpty ? 'Traveler' : n;
  }

  Future<bool> _prepare() async {
    error = '';
    stage = 'idle';
    await _stopNearby();
    final mesh = OfflineMeshService.instance;
    if (mesh.running) await mesh.stop();
    await _ident();
    if (!await mesh.askPermissions()) {
      error = 'perm';
      notifyListeners();
      return false;
    }
    try {
      final cam = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!cam.isGranted || !mic.isGranted) {
        error = 'cam';
        notifyListeners();
        return false;
      }
    } catch (_) {
      error = 'cam';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _stopNearby() async {
    final n = Nearby();
    try {
      await n.stopAdvertising();
    } catch (_) {}
    try {
      await n.stopDiscovery();
    } catch (_) {}
    try {
      await n.stopAllEndpoints();
    } catch (_) {}
    _nearbyOpen = false;
    _peerId = '';
    pending = null;
    found.clear();
    _names.clear();
  }

  // ------------------------------------------------------------------ پیدا کردن و اتصال Nearby

  Future<bool> startWaiting() async {
    if (!await _prepare()) return false;
    _mode = 'wait';
    try {
      final ok = await Nearby().startAdvertising(
        myName,
        Strategy.P2P_POINT_TO_POINT,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
        serviceId: _serviceId,
      );
      if (!ok) throw StateError('advertising failed');
      stage = 'wait';
      notifyListeners();
      return true;
    } catch (e) {
      await _fail('start', '$e');
      return false;
    }
  }

  Future<bool> startSearch() async {
    if (!await _prepare()) return false;
    _mode = 'search';
    try {
      final ok = await Nearby().startDiscovery(
        myName,
        Strategy.P2P_POINT_TO_POINT,
        onEndpointFound: (id, name, serviceId) {
          found[id] = name;
          notifyListeners();
        },
        onEndpointLost: (id) {
          found.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
      if (!ok) throw StateError('discovery failed');
      stage = 'search';
      notifyListeners();
      return true;
    } catch (e) {
      await _fail('start', '$e');
      return false;
    }
  }

  Future<void> connectTo(String id) async {
    if (stage != 'search') return;
    stage = 'connecting';
    notifyListeners();
    try {
      await Nearby().requestConnection(
        myName,
        id,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
      );
    } catch (e) {
      stage = 'search';
      error = 'failed';
      notifyListeners();
    }
  }

  Future<void> _fail(String code, String detail) async {
    debugPrint('LiveVideo $code: $detail');
    await _stopNearby();
    stage = 'idle';
    error = code;
    notifyListeners();
  }

  void _onInit(String id, ConnectionInfo info) {
    _names[id] = info.endpointName;
    pending = PendingConn(id, info.endpointName, '${info.authenticationToken}');
    notifyListeners();
  }

  Future<void> accept() async {
    final p = pending;
    if (p == null) return;
    pending = null;
    notifyListeners();
    try {
      await Nearby().acceptConnection(
        p.id,
        onPayLoadRecieved: _onPayload,
        onPayloadTransferUpdate: (id, u) {},
      );
    } catch (e) {
      await _fail('failed', '$e');
    }
  }

  Future<void> reject() async {
    final p = pending;
    if (p == null) return;
    pending = null;
    try {
      await Nearby().rejectConnection(p.id);
    } catch (_) {}
    if (stage == 'connecting') stage = _mode == 'search' ? 'search' : 'wait';
    notifyListeners();
  }

  void _onResult(String id, Status s) {
    if (s == Status.CONNECTED) {
      _peerId = id;
      _nearbyOpen = true;
      peerName = _names[id] ?? '';
      error = '';
      stage = 'connecting';
      notifyListeners();
      _startMedia();
    } else {
      pending = null;
      stage = _mode == 'search' ? 'search' : 'wait';
      error = 'rejected';
      notifyListeners();
    }
  }

  void _onDisc(String id) {
    if (id != _peerId || !_nearbyOpen) return;
    // قبل از وصل‌شدن تصویر اگر اتصال Nearby قطع شود، کار تمام است؛ بعد از آن Nearby عمداً بسته شده.
    if (stage == 'connecting') {
      _end('ended', false, errorCode: 'failed');
    }
  }

  // ------------------------------------------------------------------ WebRTC

  Map<String, dynamic> _videoConstraints() {
    final w = quality == 0 ? 640 : (quality == 2 ? 1280 : 640);
    final h = quality == 0 ? 360 : (quality == 2 ? 720 : 480);
    final f = quality == 2 ? 30 : (quality == 0 ? 20 : 24);
    return <String, dynamic>{
      'mandatory': <String, String>{'minWidth': '$w', 'minHeight': '$h', 'minFrameRate': '$f'},
      'facingMode': 'user',
      'optional': <dynamic>[],
    };
  }

  Future<void> _startMedia() async {
    if (_preparing || _pc != null) return;
    _preparing = true;
    muted = false;
    cameraOff = false;
    speaker = true;
    frontCamera = true;
    remoteVideoOn = false;
    seconds = 0;
    rttMs = null;
    lossPct = 0;
    rxKbps = 0;
    fps = 0;
    resolution = '';
    pathInfo = '';
    myFp = '';
    peerFp = '';
    peerIps = '';
    _restarted = false;
    _remoteSet = false;
    _pendingCands.clear();
    _prevBytes = 0;
    _prevLost = 0;
    _prevRecv = 0;
    _prevAt = null;
    notifyListeners();
    try {
      if (!_renderersReady) {
        await localRenderer.initialize();
        await remoteRenderer.initialize();
        _renderersReady = true;
      }
      final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': <String, dynamic>{'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
        'video': _videoConstraints(),
      });
      _local = stream;
      localRenderer.srcObject = stream;

      // ترافیک برنامه در طول تماس روی وای‌فای برود (حتی اگر وای‌فای اینترنت نداشته باشد و دیتای موبایل روشن باشد)
      await _bindWifi();
      myIps = await _localIps();
      _sendSig(<String, dynamic>{'k': 'ips', 'v': myIps});

      // iceServers خالی: فقط آدرس‌های شبکهٔ محلی (host)، بدون STUN/TURN و بدون اینترنت
      final pc = await createPeerConnection(<String, dynamic>{
        'iceServers': <dynamic>[],
        'sdpSemantics': 'unified-plan',
        'continualGatheringPolicy': 'gather_continually',
        'tcpCandidatePolicy': 'enabled',
        'iceCandidatePoolSize': 0,
      });
      _pc = pc;

      pc.onIceCandidate = (RTCIceCandidate c) {
        final line = c.candidate;
        if (line == null || line.isEmpty) return;
        _sendSig(<String, dynamic>{'k': 'cand', 'c': line, 'm': c.sdpMid, 'i': c.sdpMLineIndex});
      };
      pc.onTrack = (RTCTrackEvent e) {
        if (e.track.kind == 'video' && e.streams.isNotEmpty) {
          remoteRenderer.srcObject = e.streams.first;
          remoteVideoOn = true;
          notifyListeners();
        }
      };
      pc.onDataChannel = (RTCDataChannel ch) => _bindDc(ch);
      pc.onConnectionState = _onConnState;

      for (final t in stream.getTracks()) {
        await pc.addTrack(t, stream);
      }

      _connTimeout?.cancel();
      _connTimeout = Timer(const Duration(seconds: 30), () {
        if (stage == 'connecting') _end('ended', true, errorCode: 'net');
      });
      // اگر تا ۱۰ ثانیه وصل نشد، تماس‌گیرنده یک بار جست‌وجوی مسیر را از نو شروع می‌کند (ICE restart)
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 10), () => _iceRestart());

      if (_mode == 'search') {
        // تماس‌گیرنده: کانال کنترل را می‌سازد و offer می‌فرستد
        _bindDc(await pc.createDataChannel('ctl', RTCDataChannelInit()));
        final offer = await pc.createOffer(<String, dynamic>{});
        await pc.setLocalDescription(offer);
        myFp = _fingerprint(offer.sdp);
        _sendSig(<String, dynamic>{'k': 'offer', 'sdp': offer.sdp, 'type': offer.type});
      }
      _preparing = false;
      final queued = List<Map<String, dynamic>>.from(_early);
      _early.clear();
      for (final m in queued) {
        await _handleSig(m);
      }
    } catch (e) {
      _preparing = false;
      debugPrint('LiveVideo media: $e');
      await _end('ended', true, errorCode: 'media');
    }
  }

  void _bindDc(RTCDataChannel ch) {
    _dc = ch;
    ch.onMessage = (RTCDataChannelMessage m) {
      if (!m.isBinary && m.text == 'bye') _end('ended', false);
    };
  }

  void _onConnState(RTCPeerConnectionState s) {
    if (_ending) return;
    switch (s) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        if (stage != 'incall') _onConnected();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _end(stage == 'incall' ? 'lost' : 'ended', false, errorCode: stage == 'incall' ? '' : 'net');
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        // چند ثانیه صبر می‌کنیم؛ اگر برنگشت، قطع می‌شود
        Future<void>.delayed(const Duration(seconds: 10), () {
          final st = _pc?.connectionState;
          if (!_ending && stage == 'incall' && st == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
            _end('lost', false);
          }
        });
        break;
      default:
        break;
    }
  }

  Future<void> _onConnected() async {
    _connTimeout?.cancel();
    _restartTimer?.cancel();
    stage = 'incall';
    _t0 = DateTime.now();
    notifyListeners();
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {}
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (stage == 'incall') {
        try {
          await Helper.setSpeakerphoneOn(speaker);
        } catch (_) {}
      }
    });
    try {
      await _screenChannel.invokeMethod<bool>('screen', <String, dynamic>{'on': true});
    } catch (_) {}
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final t0 = _t0;
      if (stage == 'incall' && t0 != null) {
        seconds = DateTime.now().difference(t0).inSeconds;
        notifyListeners();
      }
    });
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStats());
    // اتصال مستقیم برقرار شد؛ Nearby دیگر لازم نیست و کنار گذاشته می‌شود (پیام پایان از کانال WebRTC می‌رود)
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      if (stage == 'incall') await _stopNearby();
    });
  }

  // ------------------------------------------------------------------ شبکهٔ محلی

  Future<void> _bindWifi() async {
    try {
      _wifiBound = (await _screenChannel.invokeMethod<bool>('wifiBind')) ?? false;
    } catch (_) {
      _wifiBound = false;
    }
  }

  Future<void> _unbindWifi() async {
    if (!_wifiBound) return;
    _wifiBound = false;
    try {
      await _screenChannel.invokeMethod<bool>('wifiUnbind');
    } catch (_) {}
  }

  /// فهرست آدرس‌های IPv4 همهٔ رابط‌های شبکه (wlan0، ap0 برای هات‌اسپات و ...)
  Future<String> _localIps() async {
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      final out = <String>[];
      for (final i in list) {
        for (final a in i.addresses) {
          out.add('${i.name}:${a.address}');
        }
      }
      return out.join(', ');
    } catch (_) {
      return '';
    }
  }

  static List<String> _ipOnly(String s) => s
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => e.contains(':') ? e.substring(e.indexOf(':') + 1) : e)
      .toList();

  static String _net24(String ip) {
    final p = ip.split('.');
    return p.length == 4 ? '${p[0]}.${p[1]}.${p[2]}' : ip;
  }

  /// آیا دو گوشی یک زیرشبکه دارند؟ null = نامعلوم
  bool? get sameSubnet {
    final a = _ipOnly(myIps);
    final b = _ipOnly(peerIps);
    if (a.isEmpty || b.isEmpty) return null;
    for (final x in a) {
      for (final y in b) {
        if (_net24(x) == _net24(y)) return true;
      }
    }
    return false;
  }

  /// متن عیب‌یابی که زیر پیام خطا نشان داده می‌شود
  String get diagnostics {
    final same = sameSubnet;
    final s = same == null ? '؟' : (same ? 'بله' : 'خیر');
    return 'IP من: ${myIps.isEmpty ? '—' : myIps}\nIP مقابل: ${peerIps.isEmpty ? '—' : peerIps}\nهم‌شبکه: $s';
  }

  Future<void> _iceRestart() async {
    final pc = _pc;
    if (pc == null || _ending || stage != 'connecting' || _restarted || _mode != 'search') return;
    _restarted = true;
    try {
      _remoteSet = false;
      final offer = await pc.createOffer(<String, dynamic>{'iceRestart': true});
      await pc.setLocalDescription(offer);
      _sendSig(<String, dynamic>{'k': 'offer', 'sdp': offer.sdp, 'type': offer.type});
    } catch (e) {
      debugPrint('LiveVideo iceRestart: $e');
    }
  }

  // ------------------------------------------------------------------ علامت‌دهی روی Nearby

  void _sendSig(Map<String, dynamic> m) {
    if (_peerId.isEmpty || !_nearbyOpen) return;
    Nearby().sendBytesPayload(_peerId, Uint8List.fromList(utf8.encode(jsonEncode(m)))).catchError((_) {});
  }

  void _onPayload(String from, Payload p) {
    if (p.type != PayloadType.BYTES) return;
    final b = p.bytes;
    if (b == null || b.isEmpty) return;
    try {
      final m = jsonDecode(utf8.decode(b));
      if (m is! Map) return;
      final msg = Map<String, dynamic>.from(m);
      if (_pc == null || _preparing) {
        _early.add(msg);
        return;
      }
      _handleSig(msg);
    } catch (_) {}
  }

  Future<void> _handleSig(Map<String, dynamic> m) async {
    final pc = _pc;
    if (pc == null || _ending) return;
    final k = '${m['k']}';
    try {
      if (k == 'offer' && _mode == 'wait') {
        final sdp = '${m['sdp']}';
        await pc.setRemoteDescription(RTCSessionDescription(sdp, '${m['type']}'));
        _remoteSet = true;
        peerFp = _fingerprint(sdp);
        final ans = await pc.createAnswer(<String, dynamic>{});
        await pc.setLocalDescription(ans);
        myFp = _fingerprint(ans.sdp);
        _sendSig(<String, dynamic>{'k': 'answer', 'sdp': ans.sdp, 'type': ans.type});
        await _flushCands();
      } else if (k == 'answer' && _mode == 'search') {
        final sdp = '${m['sdp']}';
        await pc.setRemoteDescription(RTCSessionDescription(sdp, '${m['type']}'));
        _remoteSet = true;
        peerFp = _fingerprint(sdp);
        await _flushCands();
      } else if (k == 'ips') {
        peerIps = '${m['v'] ?? ''}';
      } else if (k == 'cand') {
        final c = RTCIceCandidate('${m['c']}', m['m'] as String?, (m['i'] as num?)?.toInt());
        if (_remoteSet) {
          await pc.addCandidate(c);
        } else {
          _pendingCands.add(c);
        }
      } else if (k == 'bye') {
        _end('ended', false);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('LiveVideo signal $k: $e');
    }
  }

  Future<void> _flushCands() async {
    final pc = _pc;
    if (pc == null) return;
    final list = List<RTCIceCandidate>.from(_pendingCands);
    _pendingCands.clear();
    for (final c in list) {
      try {
        await pc.addCandidate(c);
      } catch (_) {}
    }
  }

  /// اثر انگشت DTLS از SDP (برای مقایسهٔ دستی بین دو گوشی)
  String _fingerprint(String? sdp) {
    if (sdp == null) return '';
    for (final line in sdp.split('\n')) {
      final t = line.trim();
      if (t.startsWith('a=fingerprint:')) {
        final parts = t.substring(14).split(' ');
        if (parts.length >= 2) return parts[1];
      }
    }
    return '';
  }

  // ------------------------------------------------------------------ آمار

  num? _n(dynamic v) => v is num ? v : num.tryParse('$v');

  Future<void> _pollStats() async {
    final pc = _pc;
    if (pc == null || stage != 'incall') return;
    try {
      final reports = await pc.getStats();
      final byId = <String, Map<dynamic, dynamic>>{};
      for (final r in reports) {
        byId[r.id] = r.values;
      }
      Map<dynamic, dynamic>? pair;
      for (final r in reports) {
        if (r.type != 'candidate-pair') continue;
        final v = r.values;
        final okState = '${v['state']}' == 'succeeded';
        final sel = '${v['nominated']}' == 'true' || '${v['selected']}' == 'true';
        if (okState && (sel || pair == null)) pair = v;
      }
      if (pair != null) {
        final rtt = _n(pair['currentRoundTripTime']);
        if (rtt != null) rttMs = (rtt * 1000).round();
        final lc = byId['${pair['localCandidateId']}'];
        final rc = byId['${pair['remoteCandidateId']}'];
        if (lc != null && rc != null) {
          final lt = '${lc['candidateType']}';
          final li = '${lc['address'] ?? lc['ip'] ?? ''}';
          final ri = '${rc['address'] ?? rc['ip'] ?? ''}';
          pathInfo = '$lt  $li → $ri';
        }
      }
      int bytes = 0;
      int lost = 0;
      int recv = 0;
      for (final r in reports) {
        if (r.type != 'inbound-rtp') continue;
        final v = r.values;
        final kind = '${v['kind'] ?? v['mediaType']}';
        if (kind != 'video') continue;
        bytes = (_n(v['bytesReceived']) ?? 0).toInt();
        lost = (_n(v['packetsLost']) ?? 0).toInt();
        recv = (_n(v['packetsReceived']) ?? 0).toInt();
        fps = (_n(v['framesPerSecond']) ?? 0).round();
        final w = _n(v['frameWidth']);
        final h = _n(v['frameHeight']);
        if (w != null && h != null && w > 0) resolution = '${w.toInt()}×${h.toInt()}';
      }
      final now = DateTime.now();
      final prev = _prevAt;
      if (prev != null) {
        final dt = now.difference(prev).inMilliseconds;
        if (dt > 0 && bytes >= _prevBytes) rxKbps = (((bytes - _prevBytes) * 8) / dt).round();
        final dl = lost - _prevLost;
        final dr = recv - _prevRecv;
        final tot = dl + dr;
        lossPct = tot <= 0 ? 0 : ((dl.clamp(0, tot) * 100) / tot).round();
      }
      _prevAt = now;
      _prevBytes = bytes;
      _prevLost = lost;
      _prevRecv = recv;
      notifyListeners();
    } catch (_) {}
  }

  // ------------------------------------------------------------------ کنترل‌ها

  Future<void> toggleMute() async {
    muted = !muted;
    for (final t in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  Future<void> toggleCamera() async {
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
    try {
      await Helper.setSpeakerphoneOn(speaker);
    } catch (_) {}
  }

  Future<void> hangUp() => _end('ended', true);

  Future<void> _end(String reason, bool notifyPeer, {String errorCode = ''}) async {
    if (_ending) return;
    _ending = true;
    final wasCall = stage == 'incall';
    _clockTimer?.cancel();
    _clockTimer = null;
    _statsTimer?.cancel();
    _statsTimer = null;
    _connTimeout?.cancel();
    _connTimeout = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    if (notifyPeer) {
      try {
        final dc = _dc;
        if (dc != null && dc.state == RTCDataChannelState.RTCDataChannelOpen) {
          await dc.send(RTCDataChannelMessage('bye'));
        }
      } catch (_) {}
      _sendSig(<String, dynamic>{'k': 'bye'});
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await _closeMedia();
    await _stopNearby();
    await _unbindWifi();
    try {
      await _screenChannel.invokeMethod<bool>('screen', <String, dynamic>{'on': false});
    } catch (_) {}
    if (errorCode.isNotEmpty) error = errorCode;
    if (wasCall) {
      stage = reason == 'lost' ? 'lost' : 'ended';
    } else {
      stage = errorCode.isNotEmpty ? 'idle' : (stage == 'incall' ? 'ended' : 'idle');
    }
    _ending = false;
    notifyListeners();
  }

  Future<void> _closeMedia() async {
    _preparing = false;
    _early.clear();
    _pendingCands.clear();
    _remoteSet = false;
    try {
      await _dc?.close();
    } catch (_) {}
    _dc = null;
    try {
      remoteRenderer.srcObject = null;
      localRenderer.srcObject = null;
    } catch (_) {}
    remoteVideoOn = false;
    final pc = _pc;
    _pc = null;
    try {
      await pc?.close();
    } catch (_) {}
    final st = _local;
    _local = null;
    try {
      for (final t in st?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await st?.dispose();
    } catch (_) {}
  }

  /// بازگشت به صفحهٔ انتخاب
  Future<void> reset() async {
    if (stage == 'incall') {
      await _end('ended', true);
    } else {
      await _closeMedia();
      await _stopNearby();
      await _unbindWifi();
    }
    stage = 'idle';
    error = '';
    peerName = '';
    seconds = 0;
    notifyListeners();
  }
}
