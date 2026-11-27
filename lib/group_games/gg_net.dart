import 'dart:async';
import 'dart:math';

import '../pages/games/game_play_page.dart' show NearbyGameLink;
import '../services/offline_mesh_service.dart';
import 'gg_prefs.dart';

/// اتصال ۲ تا ۴ گوشی با شبکه‌ی Nearby (همان شبکه‌ی چت آفلاین و بازی حکم).
/// میزبان تنها مرجع بازی است. پیام‌ها: {g:'gg', gm:'hockey'|'golf', room:کد چهار رقمی, t:نوع, to:گیرنده(اختیاری)}؛
/// فرستنده را سرویس در 'u' می‌گذارد.
class GgNet {
  GgNet({required this.isHost, required this.room, required this.game});

  final bool isHost;
  final String room;
  final String game;

  static const int maxPlayers = 4;

  final OfflineMeshService _mesh = OfflineMeshService.instance;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _tick;

  int mySeat = 0;
  final List<Map<String, String>?> seats = List<Map<String, String>?>.filled(maxPlayers, null);
  final Map<String, int> _last = <String, int>{};
  String hostUid = '';
  bool started = false;
  bool joined = false;
  int _lastHost = 0;
  Map<String, dynamic> startCfg = <String, dynamic>{};

  void Function()? onLobby;
  void Function(Map<String, dynamic> cfg)? onStart;
  void Function(int seat, Map<String, dynamic> m)? onGame;
  void Function(int seat, bool connected)? onConn;
  void Function(String reason)? onClosed;
  void Function(String err)? onError;

  String get myUid => _mesh.myUid;
  int _now() => DateTime.now().millisecondsSinceEpoch;
  static String newCode() => '${1000 + Random().nextInt(9000)}';

  Map<String, String> get _me => <String, String>{'uid': myUid, 'name': GgPrefs.instance.name, 'col': '${GgPrefs.instance.hkMallet}'};

  void open() {
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onMsg);
    _tick = Timer.periodic(const Duration(milliseconds: 1500), (_) => _every());
    if (isHost) {
      seats[0] = _me;
      mySeat = 0;
      hostUid = myUid;
      joined = true;
    } else {
      _sendJoin();
    }
  }

  void close({bool notify = true}) {
    if (notify) {
      if (isHost) {
        _send(<String, dynamic>{'t': 'closed'});
      } else if (joined) {
        _send(<String, dynamic>{'t': 'leave'});
      }
    }
    _tick?.cancel();
    _sub?.cancel();
    NearbyGameLink.instance.detach();
  }

  void _send(Map<String, dynamic> m) {
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'gg', 'gm': game, 'room': room, ...m});
  }

  void _sendJoin() => _send(<String, dynamic>{'t': 'join', ..._me});

  int _seatOf(String uid) => seats.indexWhere((s) => s != null && s['uid'] == uid);

  int get humanCount => seats.where((s) => s != null).length;

  // ---------------------------------------------------------------- میزبان
  void _shareLobby() {
    _send(<String, dynamic>{'t': 'lobby', 'seats': seats});
    onLobby?.call();
  }

  /// شروع مسابقه؛ cfg (شامل فهرست بازیکنان و ربات‌ها) برای همه فرستاده می‌شود.
  void hostStart(Map<String, dynamic> cfg) {
    if (!isHost || started) return;
    started = true;
    startCfg = cfg;
    _send(<String, dynamic>{'t': 'start', 'cfg': cfg});
  }

  /// ارسال پیام بازی از میزبان به همه
  void hostSend(Map<String, dynamic> m) => _send(<String, dynamic>{'t': 'rel', 'seat': 0, 'm': m});

  /// ارسال پیام بازی از مهمان به میزبان؛ relay=true یعنی میزبان برای بقیه هم بفرستد.
  void clientSend(Map<String, dynamic> m, {bool relay = false}) {
    if (isHost) {
      if (relay) hostSend(m);
    } else {
      _send(<String, dynamic>{'t': 'gm', 'to': hostUid, 'rl': relay ? 1 : 0, 'm': m});
    }
  }

  void _every() {
    final t = _now();
    if (isHost) {
      _send(<String, dynamic>{'t': 'ping'});
      for (var i = 1; i < maxPlayers; i++) {
        final s = seats[i];
        if (s == null) continue;
        final last = _last[s['uid']] ?? t;
        if (t - last > 8000) {
          if (started) {
            onConn?.call(i, false);
          } else {
            seats[i] = null;
            _shareLobby();
          }
        }
      }
      if (!started) _shareLobby();
    } else if (!joined) {
      _sendJoin();
    } else if (joined) {
      _send(<String, dynamic>{'t': 'hb', 'to': hostUid.isEmpty ? null : hostUid});
      if (_lastHost != 0 && t - _lastHost > 7000) {
        onError?.call('ارتباط با میزبان قطع شد؛ در حال اتصال دوباره…');
        _sendJoin();
      } else {
        onError?.call('');
      }
    }
  }

  // ---------------------------------------------------------------- دریافت
  void _onMsg(Map<String, dynamic> m) {
    if (m['g'] != 'gg' || '${m['gm']}' != game || '${m['room']}' != room) return;
    final from = '${m['u']}';
    if (from == myUid) return;
    final to = m['to'];
    if (to != null && '$to' != myUid) return;
    try {
      isHost ? _host(m, from) : _client(m, from);
    } catch (_) {}
  }

  void _host(Map<String, dynamic> m, String from) {
    _last[from] = _now();
    final i = _seatOf(from);
    switch (m['t']) {
      case 'join':
        var s = i;
        final nm = '${m['name'] ?? 'بازیکن'}';
        final name = nm.length > 14 ? nm.substring(0, 14) : nm;
        final col = '${m['col'] ?? '0'}';
        if (s < 0) {
          if (started) {
            _send(<String, dynamic>{'t': 'busy', 'to': from});
            return;
          }
          s = seats.indexWhere((e) => e == null, 1);
          if (s < 0) {
            _send(<String, dynamic>{'t': 'full', 'to': from});
            return;
          }
        }
        seats[s] = <String, String>{'uid': from, 'name': name, 'col': col};
        _send(<String, dynamic>{'t': 'welcome', 'to': from, 'seat': s});
        if (started) {
          _send(<String, dynamic>{'t': 'start', 'to': from, 'cfg': startCfg});
          onConn?.call(s, true);
        } else {
          _shareLobby();
        }
        break;
      case 'hb':
        if (i > 0 && started) onConn?.call(i, true);
        break;
      case 'gm':
        if (i > 0) {
          final mv = Map<String, dynamic>.from(m['m'] as Map);
          onGame?.call(i, mv);
          if ('${m['rl']}' == '1') _send(<String, dynamic>{'t': 'rel', 'seat': i, 'm': mv});
        }
        break;
      case 'leave':
        if (i > 0) {
          if (started) {
            onConn?.call(i, false);
          } else {
            seats[i] = null;
            _shareLobby();
          }
        }
        break;
    }
  }

  void _client(Map<String, dynamic> m, String from) {
    if (hostUid.isNotEmpty && from != hostUid) return;
    if (hostUid.isEmpty && m['t'] != 'welcome' && m['t'] != 'lobby') return;
    _lastHost = _now();
    switch (m['t']) {
      case 'welcome':
        hostUid = from;
        joined = true;
        mySeat = (m['seat'] as num).toInt();
        onLobby?.call();
        break;
      case 'lobby':
        hostUid = from;
        final l = m['seats'] as List;
        for (var i = 0; i < maxPlayers; i++) {
          final e = l[i];
          seats[i] = e == null ? null : Map<String, String>.from((e as Map).map((k, v) => MapEntry('$k', '$v')));
        }
        final me = _seatOf(myUid);
        if (me >= 0) mySeat = me;
        onLobby?.call();
        break;
      case 'start':
        if (!started) {
          started = true;
          startCfg = Map<String, dynamic>.from(m['cfg'] as Map);
          onStart?.call(startCfg);
        }
        break;
      case 'rel':
        final s = (m['seat'] as num).toInt();
        if (s != mySeat) onGame?.call(s, Map<String, dynamic>.from(m['m'] as Map));
        break;
      case 'full':
        onClosed?.call('اتاق پر است.');
        break;
      case 'busy':
        onClosed?.call('مسابقه در این اتاق شروع شده است.');
        break;
      case 'closed':
        onClosed?.call('میزبان مسابقه را بست.');
        break;
    }
  }
}
