import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/badge_service.dart';
import 'game_api.dart';

/// اتصال مستقیم گوشی‌به‌گوشی برای بازی آنلاین (WebRTC DataChannel).
///
/// ورکر فقط پیام‌های اولیهٔ اتصال (offer / answer) را جابه‌جا می‌کند؛
/// بعد از وصل شدن، حرکت‌ها و چت مستقیم بین دو گوشی می‌روند و هیچ درخواستی به ورکر نمی‌رود.
/// اگر اتصال وصل نشود، صفحهٔ بازی خودکار به مسیر قدیمی (ورکر) برمی‌گردد.
class GameP2p {
  GameP2p({
    required this.roomId,
    required this.isHost,
    required this.onConfirmed,
    required this.onMessage,
    required this.onClosed,
  });

  final String roomId;

  /// میزبان (بازیکن اول) offer می‌سازد؛ مهمان answer می‌دهد.
  final bool isHost;

  /// هر دو طرف پیام «سلام» را رد و بدل کرده‌اند؛ کانال آماده است.
  final void Function() onConfirmed;
  final void Function(Map<String, dynamic> m) onMessage;

  /// کانال بعد از تأیید قطع شد.
  final void Function() onClosed;

  static const List<Map<String, dynamic>> _fallbackIce = [
    {
      'urls': ['stun:stun.cloudflare.com:3478']
    },
    {
      'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']
    },
  ];

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  bool _closed = false;
  bool _confirmed = false;
  int _after = 0;
  Timer? _helloTimer;

  bool get confirmed => _confirmed && !_closed;

  Future<List<Map<String, dynamic>>> _loadIce() async {
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call(
        'GET',
        '/api/call/config',
        query: <String, String>{'user_uid': uid},
        timeout: const Duration(seconds: 5),
      );
      final list = j?['ice_servers'];
      if (list is List && list.isNotEmpty) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return _fallbackIce;
  }

  Future<void> start() async {
    try {
      final ice = await _loadIce();
      if (_closed) return;
      final pc = await createPeerConnection(<String, dynamic>{
        'iceServers': ice,
        'sdpSemantics': 'unified-plan',
      });
      if (_closed) {
        await pc.close();
        return;
      }
      _pc = pc;

      final gathered = Completer<void>();
      pc.onIceGatheringState = (RTCIceGatheringState s) {
        if (s == RTCIceGatheringState.RTCIceGatheringStateComplete && !gathered.isCompleted) {
          gathered.complete();
        }
      };
      pc.onConnectionState = (RTCPeerConnectionState s) {
        if (_closed) return;
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _lost();
        }
      };

      if (isHost) {
        final dc = await pc.createDataChannel('game', RTCDataChannelInit()..ordered = true);
        _bindChannel(dc);
        final offer = await pc.createOffer(<String, dynamic>{});
        await pc.setLocalDescription(offer);
        final sdp = await _sdpAfterGathering(gathered);
        if (sdp == null || _closed) return;
        await GameApi.post('/api/game/signal', <String, dynamic>{'room_id': roomId, 'kind': 'offer', 'data': sdp});
        await _waitSignal('answer', (data) async {
          await pc.setRemoteDescription(RTCSessionDescription(data, 'answer'));
        });
      } else {
        pc.onDataChannel = (RTCDataChannel dc) => _bindChannel(dc);
        await _waitSignal('offer', (data) async {
          await pc.setRemoteDescription(RTCSessionDescription(data, 'offer'));
          final answer = await pc.createAnswer(<String, dynamic>{});
          await pc.setLocalDescription(answer);
          final sdp = await _sdpAfterGathering(gathered);
          if (sdp == null || _closed) return;
          await GameApi.post('/api/game/signal', <String, dynamic>{'room_id': roomId, 'kind': 'answer', 'data': sdp});
        });
      }
    } catch (_) {
      // وصل نشد؛ صفحهٔ بازی بعد از مهلت به مسیر ورکر برمی‌گردد.
    }
  }

  Future<String?> _sdpAfterGathering(Completer<void> gathered) async {
    try {
      await gathered.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    } catch (_) {}
    final d = await _pc?.getLocalDescription();
    final sdp = d?.sdp;
    return (sdp == null || sdp.isEmpty) ? null : sdp;
  }

  /// هر ۸۰۰ میلی‌ثانیه پیام حریف را می‌پرسد (فقط تا ۱۶ ثانیه و فقط هنگام برقراری اتصال).
  Future<void> _waitSignal(String kind, Future<void> Function(String data) onData) async {
    final end = DateTime.now().add(const Duration(seconds: 16));
    while (!_closed && !_confirmed && DateTime.now().isBefore(end)) {
      final j = await GameApi.get('/api/game/signal', <String, String>{'room_id': roomId, 'after': '$_after'});
      if (_closed) return;
      if (j != null && j['success'] == true && j['signals'] is List) {
        for (final s in (j['signals'] as List).whereType<Map>()) {
          final id = (s['id'] as num?)?.toInt() ?? 0;
          if (id > _after) _after = id;
          if ('${s['kind']}' == kind) {
            await onData('${s['data']}');
            return;
          }
        }
      } else if (j != null && j['error'] == 'room_gone') {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
  }

  void _bindChannel(RTCDataChannel dc) {
    _dc = dc;
    dc.onDataChannelState = (RTCDataChannelState s) {
      if (_closed) return;
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        if (!isHost) _startHello();
      } else if (s == RTCDataChannelState.RTCDataChannelClosed) {
        _lost();
      }
    };
    dc.onMessage = (RTCDataChannelMessage m) {
      if (_closed || m.isBinary) return;
      Map<String, dynamic> j;
      try {
        final d = jsonDecode(m.text);
        if (d is! Map) return;
        j = Map<String, dynamic>.from(d);
      } catch (_) {
        return;
      }
      final t = j['t'];
      if (t == 'hi' && isHost) {
        _rawSend(<String, dynamic>{'t': 'hi2'});
        _confirm();
        return;
      }
      if (t == 'hi2' && !isHost) {
        _confirm();
        return;
      }
      if (!_confirmed) return;
      onMessage(j);
    };
  }

  /// مهمان تا رسیدن پاسخ میزبان چند بار «سلام» می‌فرستد.
  void _startHello() {
    var n = 0;
    _helloTimer?.cancel();
    _helloTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      n++;
      if (_closed || _confirmed || n > 20) {
        t.cancel();
        return;
      }
      _rawSend(<String, dynamic>{'t': 'hi'});
    });
    _rawSend(<String, dynamic>{'t': 'hi'});
  }

  void _confirm() {
    if (_confirmed || _closed) return;
    _confirmed = true;
    _helloTimer?.cancel();
    onConfirmed();
  }

  void _lost() {
    if (_closed) return;
    final wasConfirmed = _confirmed;
    _closed = true;
    _helloTimer?.cancel();
    _dispose();
    if (wasConfirmed) onClosed();
  }

  bool _rawSend(Map<String, dynamic> m) {
    final dc = _dc;
    if (dc == null || _closed) return false;
    try {
      dc.send(RTCDataChannelMessage(jsonEncode(m)));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ارسال پیام بازی (فقط بعد از تأیید کانال).
  bool send(Map<String, dynamic> m) => _confirmed && _rawSend(m);

  void _dispose() {
    final dc = _dc;
    final pc = _pc;
    _dc = null;
    _pc = null;
    try {
      dc?.close();
    } catch (_) {}
    try {
      pc?.close();
    } catch (_) {}
  }

  /// بستن دستی (بدون صدا زدن onClosed).
  Future<void> close() async {
    _closed = true;
    _helloTimer?.cancel();
    _dispose();
  }
}
