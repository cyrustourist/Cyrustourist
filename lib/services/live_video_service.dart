import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_transfer_service.dart' show PendingConn;
import 'offline_mesh_service.dart';
import 'user_profile_service.dart';

const MethodChannel _ch = MethodChannel('cyrus/livecall');
const EventChannel _micChannel = EventChannel('cyrus/livecall/mic');
const EventChannel _camChannel = EventChannel('cyrus/livecall/cam');

/// تماس تصویری زنده بین دو گوشی بدون اینترنت و بدون نیاز به آدرس IP (نسخهٔ آزمایشی).
///
/// همه‌چیز (پیدا کردن گوشی، تأیید کد، صدا، تصویر) روی یک اتصال Nearby Connections می‌رود. Nearby خودش
/// بهترین راه ارتباطی بین دو گوشی را انتخاب می‌کند: وای‌فای مشترک (مودم)، هات‌اسپات، Wi‑Fi Direct یا بلوتوث،
/// و ارتباط را رمز می‌کند (کلید مشترک + کد تأییدی که روی هر دو گوشی نشان داده و قبول می‌شود).
/// هر گوشی یک شناسهٔ جدا دارد؛ نه IP مشترک لازم است و نه یک وای‌فای خاص.
///
/// - صدا: موتور صدای بومی همان «تماس صوتی آفلاین» (μ‑law، ۸ کیلوهرتز).
/// - تصویر: فریم‌های JPEG از دوربین بومی؛ با کنترل جریان (حداکثر ۲ فریم منتظر تأیید) تا روی شبکهٔ ضعیف
///   تأخیر انباشته نشود، و کیفیت JPEG خودکار با سرعت اتصال تنظیم می‌شود.
///
/// این سرویس از تماس صوتی/تصویری آنلاین (call_service / call_session) کاملاً جداست.
class LiveVideoService extends ChangeNotifier {
  LiveVideoService._();
  static final LiveVideoService instance = LiveVideoService._();

  static const String _serviceId = 'ir.cyrustourist.video';
  static const int _chunk = 28000; // سقف هر بستهٔ Nearby ۳۲ کیلوبایت است

  /// idle | wait | search | connecting | incall | ended | lost
  String stage = 'idle';

  /// '' | perm | cam | start | rejected | failed | audio | media
  String error = '';
  String myName = '';
  String peerName = '';
  PendingConn? pending;
  final Map<String, String> found = <String, String>{};

  /// آخرین فریم‌ها (JPEG) و چرخش لازم برای نمایش (تعداد ربع‌دور ساعت‌گرد)
  Uint8List? remoteFrame;
  int remoteRot = 0;
  Uint8List? localFrame;
  int localRot = 0;

  /// 0 = ۳۶۰p، 1 = ۴۸۰p، 2 = ۷۲۰p (قبل از شروع انتخاب می‌شود)
  int quality = 1;

  bool muted = false;
  bool cameraOff = false;
  bool speaker = true;
  bool frontCamera = true;
  bool remoteVideoOn = false;
  int seconds = 0;

  // آمار
  int? rttMs;
  int lossPct = 0;
  int rxKbps = 0;
  int fps = 0;
  String resolution = '';
  String pathInfo = '';
  String myFp = '';
  String peerFp = '';

  String _mode = '';
  String _peerId = '';
  bool _nearbyOpen = false;
  bool _ending = false;
  final Map<String, String> _names = <String, String>{};

  StreamSubscription<dynamic>? _micSub;
  StreamSubscription<dynamic>? _camSub;
  Timer? _clockTimer;
  Timer? _tickTimer;
  DateTime? _t0;

  // صدا
  int _aSeq = 0;
  int _aExpected = -1;
  int _aRx = 0;
  int _aLost = 0;
  int _wRx = 0;
  int _wLost = 0;

  // تصویر (ارسال)
  int _vId = 0;
  int _lastAck = -1;
  DateTime _lastAckAt = DateTime.now();
  int _sentFrames = 0;
  double _ackMs = 0;
  final Map<int, DateTime> _sentAt = <int, DateTime>{};
  int _jpegQ = 45;

  // تصویر (دریافت)
  int _rId = -1;
  int _rCnt = 0;
  int _rNext = 0;
  final List<Uint8List> _rParts = <Uint8List>[];
  int _rRot = 0;
  int _rW = 0;
  int _rH = 0;
  int _wFrames = 0;
  int _wBytes = 0;
  DateTime _lastRxAny = DateTime.now();
  DateTime _lastVideoAt = DateTime.now();

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
    myFp = p.token;
    peerFp = p.token;
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
    // اتصال Nearby قطع شد: قبل از شروع تماس یعنی ناموفق، بعد از شروع یعنی ارتباط از دست رفته
    if (stage == 'incall') {
      _end('lost', false);
    } else if (stage == 'connecting') {
      _end('ended', false, errorCode: 'failed');
    }
  }

  // ------------------------------------------------------------------ تماس

  (int, int, int, int) get _preset {
    // عرض، ارتفاع، فریم بر ثانیه، کیفیت JPEG
    switch (quality) {
      case 0:
        return (320, 240, 12, 50);
      case 2:
        return (1280, 720, 6, 40);
      default:
        return (640, 480, 10, 45);
    }
  }

  Future<void> _startMedia() async {
    if (stage == 'incall') return;
    muted = false;
    cameraOff = false;
    speaker = true;
    frontCamera = true;
    remoteVideoOn = false;
    remoteFrame = null;
    localFrame = null;
    seconds = 0;
    rttMs = null;
    lossPct = 0;
    rxKbps = 0;
    fps = 0;
    resolution = '';
    pathInfo = 'Nearby (encrypted)';
    _aSeq = 0;
    _aExpected = -1;
    _aRx = 0;
    _aLost = 0;
    _wRx = 0;
    _wLost = 0;
    _vId = 0;
    _lastAck = -1;
    _lastAckAt = DateTime.now();
    _sentFrames = 0;
    _ackMs = 0;
    _sentAt.clear();
    _rId = -1;
    _rCnt = 0;
    _rNext = 0;
    _rParts.clear();
    _wFrames = 0;
    _wBytes = 0;
    _lastRxAny = DateTime.now();
    _lastVideoAt = DateTime.now();
    _jpegQ = _preset.$4;
    _t0 = DateTime.now();
    stage = 'incall';
    notifyListeners();

    try {
      await Nearby().stopAdvertising();
    } catch (_) {}
    try {
      await Nearby().stopDiscovery();
    } catch (_) {}

    // صدا
    _micSub?.cancel();
    _micSub = _micChannel.receiveBroadcastStream().listen(_onMic, onError: (_) {});
    var ok = false;
    try {
      ok = await _ch.invokeMethod<bool>('start') ?? false;
    } catch (_) {}
    if (!ok) {
      error = 'audio';
      await _end('ended', true, errorCode: 'audio');
      return;
    }
    try {
      await _ch.invokeMethod<bool>('speaker', <String, dynamic>{'on': true});
      await _ch.invokeMethod<bool>('screen', <String, dynamic>{'on': true});
    } catch (_) {}

    // تصویر
    await _startCamera();

    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final t0 = _t0;
      if (stage == 'incall' && t0 != null) {
        seconds = DateTime.now().difference(t0).inSeconds;
        notifyListeners();
      }
    });
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
  }

  Future<void> _startCamera() async {
    _camSub?.cancel();
    _camSub = _camChannel.receiveBroadcastStream().listen(_onCamFrame, onError: (_) {});
    final p = _preset;
    var ok = false;
    try {
      ok = await _ch.invokeMethod<bool>('camStart', <String, dynamic>{
            'front': frontCamera,
            'w': p.$1,
            'h': p.$2,
            'fps': p.$3,
            'q': _jpegQ,
          }) ??
          false;
    } catch (_) {}
    if (!ok) {
      // دوربین راه نیفتاد؛ صدا ادامه دارد و مقابل فقط تصویر نمی‌بیند
      cameraOff = true;
      _sendCtl(<String, dynamic>{'k': 'cam', 'on': false});
    }
    notifyListeners();
  }

  Future<void> _stopCamera() async {
    try {
      await _camSub?.cancel();
    } catch (_) {}
    _camSub = null;
    try {
      await _ch.invokeMethod<bool>('camStop');
    } catch (_) {}
  }

  // ---- ارسال

  void _onMic(dynamic d) {
    if (stage != 'incall' || _peerId.isEmpty || d is! Uint8List) return;
    _aSeq = (_aSeq + 1) & 0xffff;
    final b = Uint8List(3 + d.length);
    b[0] = 1;
    b[1] = (_aSeq >> 8) & 0xff;
    b[2] = _aSeq & 0xff;
    b.setRange(3, b.length, d);
    Nearby().sendBytesPayload(_peerId, b).catchError((_) {});
  }

  void _sendCtl(Map<String, dynamic> m) {
    if (_peerId.isEmpty || !_nearbyOpen) return;
    final body = utf8.encode(jsonEncode(m));
    final b = Uint8List(1 + body.length);
    b[0] = 2;
    b.setRange(1, b.length, body);
    Nearby().sendBytesPayload(_peerId, b).catchError((_) {});
  }

  void _onCamFrame(dynamic d) {
    if (stage != 'incall' || d is! Uint8List || d.length < 8) return;
    final rot = d[0] & 3;
    final front = d[1] == 1;
    final w = (d[2] << 8) | d[3];
    final h = (d[4] << 8) | d[5];
    // پیش‌نمایش خودم (همیشه)
    if (!cameraOff) {
      localFrame = Uint8List.sublistView(d, 6);
      localRot = rot;
      frontCamera = front;
      notifyListeners();
    }
    if (cameraOff || _peerId.isEmpty) return;

    // کنترل جریان: حداکثر ۲ فریم بدون تأیید در راه باشد (اگر تأیید ۲ ثانیه نیامد، دوباره اجازه می‌دهیم)
    final inflight = _lastAck < 0 ? _sentFrames : ((_vId - _lastAck) & 0xffff);
    if (inflight >= 2 && DateTime.now().difference(_lastAckAt).inMilliseconds < 2000) return;

    final jpg = Uint8List.sublistView(d, 6);
    final id = _vId = (_vId + 1) & 0xffff;
    _sentFrames++;
    _sentAt[id] = DateTime.now();
    if (_sentAt.length > 8) _sentAt.remove(_sentAt.keys.first);
    final cnt = (jpg.length + _chunk - 1) ~/ _chunk;
    if (cnt > 250) return;
    for (var i = 0; i < cnt; i++) {
      final s = i * _chunk;
      final e = (s + _chunk) > jpg.length ? jpg.length : s + _chunk;
      final part = Uint8List(11 + (e - s));
      part[0] = 3;
      part[1] = (id >> 8) & 0xff;
      part[2] = id & 0xff;
      part[3] = i;
      part[4] = cnt;
      part[5] = rot;
      part[6] = front ? 1 : 0;
      part[7] = (w >> 8) & 0xff;
      part[8] = w & 0xff;
      part[9] = (h >> 8) & 0xff;
      part[10] = h & 0xff;
      part.setRange(11, part.length, jpg.sublist(s, e));
      Nearby().sendBytesPayload(_peerId, part).catchError((_) {});
    }
  }

  // ---- دریافت

  void _onPayload(String from, Payload p) {
    if (p.type != PayloadType.BYTES) return;
    final b = p.bytes;
    if (b == null || b.isEmpty) return;
    _lastRxAny = DateTime.now();
    _wBytes += b.length;
    switch (b[0]) {
      case 1:
        _onAudio(b);
        break;
      case 2:
        _onCtl(b);
        break;
      case 3:
        _onVideoChunk(b);
        break;
      case 4:
        if (b.length >= 3) _onAck((b[1] << 8) | b[2]);
        break;
    }
  }

  void _onAudio(Uint8List b) {
    if (stage != 'incall' || b.length < 4) return;
    final seq = (b[1] << 8) | b[2];
    if (_aExpected < 0) {
      _aExpected = (seq + 1) & 0xffff;
    } else {
      final gap = (seq - _aExpected) & 0xffff;
      if (gap < 500) {
        _aLost += gap;
        _wLost += gap;
        _aExpected = (seq + 1) & 0xffff;
      } else {
        return;
      }
    }
    _aRx++;
    _wRx++;
    _ch.invokeMethod<bool>('play', <String, dynamic>{'bytes': Uint8List.sublistView(b, 3)}).catchError((_) => false);
  }

  void _onVideoChunk(Uint8List b) {
    if (stage != 'incall' || b.length < 12) return;
    final id = (b[1] << 8) | b[2];
    final idx = b[3];
    final cnt = b[4];
    if (idx == 0) {
      _rId = id;
      _rCnt = cnt;
      _rNext = 0;
      _rParts.clear();
      _rRot = b[5] & 3;
      _rW = (b[7] << 8) | b[8];
      _rH = (b[9] << 8) | b[10];
    }
    if (id != _rId || idx != _rNext) {
      _rId = -1; // بستهٔ ناقص؛ این فریم دور ریخته می‌شود
      return;
    }
    _rParts.add(Uint8List.sublistView(b, 11));
    _rNext++;
    if (_rNext == _rCnt) {
      final total = _rParts.fold<int>(0, (s, e) => s + e.length);
      final out = Uint8List(total);
      var o = 0;
      for (final part in _rParts) {
        out.setRange(o, o + part.length, part);
        o += part.length;
      }
      _rParts.clear();
      _rId = -1;
      remoteFrame = out;
      remoteRot = _rRot;
      remoteVideoOn = true;
      resolution = '$_rW×$_rH';
      _wFrames++;
      _lastVideoAt = DateTime.now();
      // تأیید دریافت فریم برای کنترل جریان
      if (_peerId.isNotEmpty && _nearbyOpen) {
        final ack = Uint8List(3);
        ack[0] = 4;
        ack[1] = (id >> 8) & 0xff;
        ack[2] = id & 0xff;
        Nearby().sendBytesPayload(_peerId, ack).catchError((_) {});
      }
      notifyListeners();
    }
  }

  void _onAck(int id) {
    _lastAck = id;
    _lastAckAt = DateTime.now();
    final at = _sentAt.remove(id);
    if (at != null) {
      final ms = DateTime.now().difference(at).inMilliseconds.toDouble();
      _ackMs = _ackMs == 0 ? ms : (_ackMs * 0.7 + ms * 0.3);
    }
  }

  void _onCtl(Uint8List b) {
    try {
      final m = jsonDecode(utf8.decode(Uint8List.sublistView(b, 1)));
      if (m is! Map) return;
      final k = '${m['k']}';
      if (k == 'ping') {
        _sendCtl(<String, dynamic>{'k': 'pong', 't': m['t']});
      } else if (k == 'pong') {
        final t = (m['t'] as num?)?.toInt();
        if (t != null) {
          final rtt = DateTime.now().millisecondsSinceEpoch - t;
          if (rtt >= 0 && rtt < 20000) rttMs = rtt;
        }
      } else if (k == 'cam') {
        if (m['on'] == false) {
          remoteVideoOn = false;
          remoteFrame = null;
          notifyListeners();
        }
      } else if (k == 'bye') {
        _end('ended', false);
      }
    } catch (_) {}
  }

  void _onTick() {
    if (stage != 'incall') return;
    _sendCtl(<String, dynamic>{'k': 'ping', 't': DateTime.now().millisecondsSinceEpoch});
    rxKbps = ((_wBytes * 8) / 2000).round();
    fps = (_wFrames / 2).round();
    final tot = _wRx + _wLost;
    lossPct = tot <= 0 ? 0 : ((_wLost * 100) / tot).round();
    _wBytes = 0;
    _wFrames = 0;
    _wRx = 0;
    _wLost = 0;
    if (DateTime.now().difference(_lastVideoAt).inSeconds > 4 && remoteVideoOn) {
      remoteVideoOn = false;
    }
    // تنظیم خودکار کیفیت JPEG با سرعت اتصال
    final base = _preset.$4;
    var q = _jpegQ;
    if (_ackMs > 450 && q > 22) {
      q -= 8;
    } else if (_ackMs > 0 && _ackMs < 150 && q < base) {
      q += 4;
    }
    q = q.clamp(22, base);
    if (q != _jpegQ) {
      _jpegQ = q;
      _ch.invokeMethod<bool>('camQ', <String, dynamic>{'q': q}).catchError((_) => false);
    }
    // اگر ۱۰ ثانیه هیچ بسته‌ای نیامد، ارتباط از دست رفته است
    if (DateTime.now().difference(_lastRxAny).inSeconds > 10) {
      _end('lost', false);
      return;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------ کنترل‌ها

  Future<void> toggleMute() async {
    muted = !muted;
    notifyListeners();
    try {
      await _ch.invokeMethod<bool>('mute', <String, dynamic>{'on': muted});
    } catch (_) {}
  }

  Future<void> toggleCamera() async {
    cameraOff = !cameraOff;
    if (cameraOff) {
      localFrame = null;
      await _stopCamera();
      _sendCtl(<String, dynamic>{'k': 'cam', 'on': false});
    } else {
      await _startCamera();
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (cameraOff) return;
    frontCamera = !frontCamera;
    await _startCamera();
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speaker = !speaker;
    notifyListeners();
    try {
      await _ch.invokeMethod<bool>('speaker', <String, dynamic>{'on': speaker});
    } catch (_) {}
  }

  Future<void> hangUp() => _end('ended', true);

  Future<void> _end(String reason, bool notifyPeer, {String errorCode = ''}) async {
    if (_ending) return;
    _ending = true;
    final wasCall = stage == 'incall';
    _clockTimer?.cancel();
    _clockTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    if (notifyPeer) {
      _sendCtl(<String, dynamic>{'k': 'bye'});
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await _closeMedia();
    await _stopNearby();
    try {
      await _ch.invokeMethod<bool>('screen', <String, dynamic>{'on': false});
    } catch (_) {}
    if (errorCode.isNotEmpty) error = errorCode;
    if (wasCall) {
      stage = reason == 'lost' ? 'lost' : 'ended';
    } else {
      stage = 'idle';
    }
    _ending = false;
    notifyListeners();
  }

  Future<void> _closeMedia() async {
    await _stopCamera();
    try {
      await _micSub?.cancel();
    } catch (_) {}
    _micSub = null;
    try {
      await _ch.invokeMethod<bool>('stop');
    } catch (_) {}
    remoteVideoOn = false;
    remoteFrame = null;
    localFrame = null;
    _rParts.clear();
    _sentAt.clear();
  }

  /// بازگشت به صفحهٔ انتخاب
  Future<void> reset() async {
    if (stage == 'incall') {
      await _end('ended', true);
    } else {
      await _closeMedia();
      await _stopNearby();
    }
    stage = 'idle';
    error = '';
    peerName = '';
    seconds = 0;
    notifyListeners();
  }
}
