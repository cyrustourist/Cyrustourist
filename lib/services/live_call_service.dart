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

const MethodChannel _callChannel = MethodChannel('cyrus/livecall');
const EventChannel _micChannel = EventChannel('cyrus/livecall/mic');

/// تماس صوتی زنده بین دو گوشی بدون اینترنت (نسخهٔ آزمایشی).
/// صدا در کد بومی ضبط و با μ-law فشرده می‌شود (هر ۴۰ میلی‌ثانیه ۳۲۰ بایت ≈ ۶۴ kbps) و به‌صورت بسته‌های
/// کوچک روی اتصال دونفرهٔ Nearby (که در صورت امکان به وای‌فای مستقیم ارتقا می‌یابد) رد و بدل می‌شود.
/// برای سنجش کیفیت، تأخیر رفت‌وبرگشت (RTT)، درصد بستهٔ گم‌شده و لرزش (jitter) نمایش داده می‌شود.
/// این سرویس از شبکهٔ چت و انتقال فایل جداست؛ با شروع آن شبکهٔ چت خاموش می‌شود.
class LiveCallService extends ChangeNotifier {
  LiveCallService._();
  static final LiveCallService instance = LiveCallService._();

  static const String _serviceId = 'ir.cyrustourist.call';

  /// idle | wait | search | connecting | incall | ended | lost
  String stage = 'idle';

  /// '' | perm | mic | start | rejected | failed | audio
  String error = '';
  String myName = '';
  String peerName = '';
  PendingConn? pending;
  final Map<String, String> found = <String, String>{};

  bool muted = false;
  bool speaker = false;
  int seconds = 0;
  int? rttMs;
  int lossPct = 0;
  int jitterMs = 0;
  int rxKbps = 0;

  String _mode = '';
  String _peerId = '';
  final Map<String, String> _names = <String, String>{};
  StreamSubscription<dynamic>? _micSub;
  Timer? _timer;
  bool _ending = false;
  DateTime? _t0;

  int _seq = 0;
  int _expected = -1;
  int _rx = 0;
  int _lost = 0;
  int _rxBytes = 0;
  int _wRx = 0;
  int _wLost = 0;
  int _wBytes = 0;
  double _jit = 0;
  DateTime? _lastRx;
  int _tick = 0;

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
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        error = 'mic';
        notifyListeners();
        return false;
      }
    } catch (_) {
      error = 'mic';
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
    _peerId = '';
    pending = null;
    found.clear();
    _names.clear();
  }

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
    debugPrint('LiveCall $code: $detail');
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
      peerName = _names[id] ?? '';
      error = '';
      _startCall();
    } else {
      pending = null;
      stage = _mode == 'search' ? 'search' : 'wait';
      error = 'rejected';
      notifyListeners();
    }
  }

  void _onDisc(String id) {
    if (id != _peerId) return;
    if (stage == 'incall') _end('lost', false);
  }

  // ------------------------------------------------------------------ تماس

  Future<void> _startCall() async {
    stage = 'incall';
    muted = false;
    speaker = false;
    seconds = 0;
    rttMs = null;
    lossPct = 0;
    jitterMs = 0;
    rxKbps = 0;
    _seq = 0;
    _expected = -1;
    _rx = 0;
    _lost = 0;
    _rxBytes = 0;
    _wRx = 0;
    _wLost = 0;
    _wBytes = 0;
    _jit = 0;
    _lastRx = null;
    _tick = 0;
    _t0 = DateTime.now();
    notifyListeners();
    try {
      await Nearby().stopAdvertising();
    } catch (_) {}
    try {
      await Nearby().stopDiscovery();
    } catch (_) {}
    _micSub?.cancel();
    _micSub = _micChannel.receiveBroadcastStream().listen(_onMic, onError: (_) {});
    var ok = false;
    try {
      ok = await _callChannel.invokeMethod<bool>('start') ?? false;
    } catch (_) {}
    if (!ok) {
      error = 'audio';
      await _end('ended', true);
      return;
    }
    try {
      await _callChannel.invokeMethod<bool>('screen', <String, dynamic>{'on': true});
    } catch (_) {}
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onMic(dynamic d) {
    if (stage != 'incall' || _peerId.isEmpty || d is! Uint8List) return;
    _seq = (_seq + 1) & 0xffff;
    final b = Uint8List(3 + d.length);
    b[0] = 1;
    b[1] = (_seq >> 8) & 0xff;
    b[2] = _seq & 0xff;
    b.setRange(3, b.length, d);
    Nearby().sendBytesPayload(_peerId, b).catchError((_) {});
  }

  void _sendCtl(Map<String, dynamic> m) {
    if (_peerId.isEmpty) return;
    final body = utf8.encode(jsonEncode(m));
    final b = Uint8List(1 + body.length);
    b[0] = 2;
    b.setRange(1, b.length, body);
    Nearby().sendBytesPayload(_peerId, b).catchError((_) {});
  }

  void _onPayload(String from, Payload p) {
    if (p.type != PayloadType.BYTES) return;
    final b = p.bytes;
    if (b == null || b.isEmpty) return;
    if (b[0] == 1) {
      if (stage != 'incall' || b.length < 4) return;
      final seq = (b[1] << 8) | b[2];
      final now = DateTime.now();
      if (_expected < 0) {
        _expected = (seq + 1) & 0xffff;
      } else {
        final gap = (seq - _expected) & 0xffff;
        if (gap < 500) {
          _lost += gap;
          _wLost += gap;
          _expected = (seq + 1) & 0xffff;
        } else {
          return; // بستهٔ دیررسیده یا تکراری؛ پخش نمی‌شود
        }
      }
      _rx++;
      _wRx++;
      _rxBytes += b.length;
      _wBytes += b.length;
      final last = _lastRx;
      if (last != null) {
        final dt = now.difference(last).inMilliseconds;
        _jit += ((dt - 40).abs() - _jit) / 16;
      }
      _lastRx = now;
      _callChannel.invokeMethod<bool>('play', <String, dynamic>{'bytes': Uint8List.sublistView(b, 3)}).catchError((_) => false);
      return;
    }
    if (b[0] == 2) {
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
            if (rtt >= 0 && rtt < 20000) {
              final old = rttMs;
              rttMs = old == null ? rtt : ((old * 3 + rtt) / 4).round();
            }
          }
        } else if (k == 'bye') {
          _end('ended', false);
        }
      } catch (_) {}
    }
  }

  void _onTick() {
    if (stage != 'incall') return;
    _tick++;
    final t0 = _t0;
    if (t0 != null) seconds = DateTime.now().difference(t0).inSeconds;
    if (_tick % 2 == 0) {
      _sendCtl(<String, dynamic>{'k': 'ping', 't': DateTime.now().millisecondsSinceEpoch});
      final total = _wRx + _wLost;
      lossPct = total == 0 ? 0 : ((_wLost * 100) / total).round();
      rxKbps = ((_wBytes * 8) / 2000).round();
      jitterMs = _jit.round();
      _wRx = 0;
      _wLost = 0;
      _wBytes = 0;
    }
    final last = _lastRx;
    final silent = last == null ? DateTime.now().difference(_t0 ?? DateTime.now()).inSeconds > 20 : DateTime.now().difference(last).inSeconds > 15;
    if (silent) {
      _end('lost', false);
      return;
    }
    notifyListeners();
  }

  Future<void> toggleMute() async {
    muted = !muted;
    notifyListeners();
    try {
      await _callChannel.invokeMethod<bool>('mute', <String, dynamic>{'on': muted});
    } catch (_) {}
  }

  Future<void> toggleSpeaker() async {
    speaker = !speaker;
    notifyListeners();
    try {
      await _callChannel.invokeMethod<bool>('speaker', <String, dynamic>{'on': speaker});
    } catch (_) {}
  }

  Future<void> hangUp() => _end('ended', true);

  Future<void> _end(String reason, bool notifyPeer) async {
    if (_ending) return;
    _ending = true;
    final wasCall = stage == 'incall';
    _timer?.cancel();
    _timer = null;
    if (notifyPeer && _peerId.isNotEmpty) {
      _sendCtl(<String, dynamic>{'k': 'bye'});
    }
    try {
      await _micSub?.cancel();
    } catch (_) {}
    _micSub = null;
    try {
      await _callChannel.invokeMethod<bool>('stop');
      await _callChannel.invokeMethod<bool>('screen', <String, dynamic>{'on': false});
    } catch (_) {}
    if (notifyPeer) await Future<void>.delayed(const Duration(milliseconds: 300));
    await _stopNearby();
    if (wasCall || stage == 'incall') {
      stage = reason == 'lost' ? 'lost' : 'ended';
    } else {
      stage = 'idle';
    }
    _ending = false;
    notifyListeners();
  }

  /// بازگشت به صفحهٔ انتخاب
  Future<void> reset() async {
    if (stage == 'incall') {
      await _end('ended', true);
    } else {
      await _stopNearby();
    }
    stage = 'idle';
    error = '';
    peerName = '';
    notifyListeners();
  }
}
