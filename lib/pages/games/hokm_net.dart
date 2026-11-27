import 'dart:async';
import 'dart:math';

import '../../services/offline_mesh_service.dart';
import 'game_play_page.dart' show NearbyGameLink;
import 'hokm_match.dart';
import 'hokm_prefs.dart';

/// اتصال چهار گوشی با شبکه‌ی Nearby (همان شبکه‌ی چت آفلاین).
/// میزبان تنها مرجع بازی است؛ هر گوشی فقط کارت‌های خودش را می‌گیرد.
/// پیام‌ها: {g:'hokm', t:نوع, room:کد اتاق, to:شناسه‌ی گیرنده (اختیاری)}؛ فرستنده را سرویس در 'u' می‌گذارد.
class HokmNet {
  HokmNet({required this.isHost, required this.room});

  final bool isHost;
  final String room;

  final OfflineMeshService _mesh = OfflineMeshService.instance;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _tick;

  /// صندلی من
  int mySeat = 0;

  /// نفرات اتاق (فقط انسان‌ها؛ جای خالی null)
  final List<Map<String, String>?> seats = <Map<String, String>?>[null, null, null, null];
  final Map<String, int> _last = <String, int>{}; // uid → زمان آخرین پیام
  bool started = false;
  bool joined = false;
  int _lastHost = 0;

  HokmMatch? match; // فقط میزبان

  void Function()? onLobby;
  void Function(Map<String, dynamic> view)? onView;
  void Function(int seat, String text)? onChat;
  void Function(String reason)? onClosed;
  void Function(String err)? onError;

  String get myUid => _mesh.myUid;
  int _now() => DateTime.now().millisecondsSinceEpoch;

  static String newCode() => '${1000 + Random().nextInt(9000)}';

  void open() {
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onMsg);
    _tick = Timer.periodic(const Duration(milliseconds: 1500), (_) => _every());
    if (isHost) {
      seats[0] = <String, String>{'uid': myUid, 'name': HokmPrefs.instance.name, 'avatar': HokmPrefs.instance.avatar};
      mySeat = 0;
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
    match?.destroy();
    NearbyGameLink.instance.detach();
  }

  void _send(Map<String, dynamic> m) {
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'hokm', 'room': room, ...m});
  }

  void _sendJoin() => _send(<String, dynamic>{'t': 'join', 'name': HokmPrefs.instance.name, 'avatar': HokmPrefs.instance.avatar});

  int _seatOf(String uid) => seats.indexWhere((s) => s != null && s['uid'] == uid);

  // ---------------------------------------------------------------- میزبان
  void _shareLobby() {
    _send(<String, dynamic>{'t': 'lobby', 'seats': seats});
    onLobby?.call();
  }

  /// شروع بازی: جاهای خالی با ربات پر می‌شود.
  void hostStart() {
    if (!isHost || started) return;
    started = true;
    const botNames = <String>['داریوش', 'میترا', 'کتایون', 'آرش', 'آناهیتا', 'مهرداد', 'شیرین', 'بهرام'];
    const botAv = <String, String>{'داریوش': '2', 'میترا': '1', 'کتایون': '3', 'آرش': '0', 'آناهیتا': '1', 'مهرداد': '5', 'شیرین': '7', 'بهرام': '2'};
    final used = seats.whereType<Map<String, String>>().map((s) => s['name']).toSet();
    final free = botNames.where((n) => !used.contains(n)).toList();
    var k = 0;
    final pl = <HokmPlayer>[];
    for (var i = 0; i < 4; i++) {
      final s = seats[i];
      if (s != null) {
        pl.add(HokmPlayer(name: s['name']!, avatar: s['avatar']!, uid: s['uid']!));
      } else {
        final n = free[k++];
        pl.add(HokmPlayer(name: n, avatar: botAv[n] ?? '0', bot: true));
      }
    }
    match = HokmMatch(players: pl, target: HokmPrefs.instance.target);
    match!.speedPercent = HokmPrefs.instance.speed;
    match!.onChange = _hostChanged;
    match!.start();
  }

  void _hostChanged() {
    final m = match;
    if (m == null) return;
    onView?.call(m.view(0));
    for (var i = 1; i < 4; i++) {
      final p = m.players[i];
      if (!p.bot && p.uid.isNotEmpty) _send(<String, dynamic>{'t': 'view', 'to': p.uid, 'v': m.view(i)});
    }
  }

  void hostChat(int seat, String text) {
    _send(<String, dynamic>{'t': 'chat', 'seat': seat, 'text': text});
    onChat?.call(seat, text);
  }

  void _every() {
    final t = _now();
    if (isHost) {
      _send(<String, dynamic>{'t': 'ping'});
      for (var i = 1; i < 4; i++) {
        final s = seats[i];
        if (s == null) continue;
        final last = _last[s['uid']] ?? t;
        if (t - last > 8000) {
          if (started) {
            match?.setConn(i, false);
          } else {
            seats[i] = null;
            _shareLobby();
          }
        }
      }
      if (!started) _shareLobby();
    } else if (!joined) {
      // هنوز خوش‌آمد نگرفته‌ایم: درخواست پیوستن را تکرار می‌کنیم (اتصال Nearby ممکن است چند ثانیه بعد برقرار شود)
      _sendJoin();
    } else if (joined) {
      _send(<String, dynamic>{'t': 'hb'});
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
    if (m['g'] != 'hokm' || '${m['room']}' != room) return;
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
        final name = '${m['name'] ?? 'بازیکن'}';
        final av = '${m['avatar'] ?? '0'}';
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
        final nm = name.length > 16 ? name.substring(0, 16) : name;
        seats[s] = <String, String>{'uid': from, 'name': nm, 'avatar': av};
        _send(<String, dynamic>{'t': 'welcome', 'to': from, 'seat': s});
        if (started && match != null) {
          match!.players[s]
            ..uid = from
            ..name = nm
            ..avatar = av;
          match!.setConn(s, true);
          _send(<String, dynamic>{'t': 'view', 'to': from, 'v': match!.view(s)});
        } else {
          _shareLobby();
        }
        break;
      case 'seat':
        final want = (m['want'] as num?)?.toInt() ?? -1;
        if (i > 0 && !started && want > 0 && want < 4 && seats[want] == null) {
          seats[want] = seats[i];
          seats[i] = null;
          _send(<String, dynamic>{'t': 'welcome', 'to': from, 'seat': want});
          _shareLobby();
        }
        break;
      case 'hb':
        if (i > 0 && started && match != null && !match!.players[i].conn) match!.setConn(i, true);
        break;
      case 'act':
        if (i > 0 && match != null) {
          final mv = Map<String, dynamic>.from(m['m'] as Map);
          if (!match!.act(i, mv)) _send(<String, dynamic>{'t': 'view', 'to': from, 'v': match!.view(i)});
        }
        break;
      case 'sync':
        if (i > 0 && match != null) _send(<String, dynamic>{'t': 'view', 'to': from, 'v': match!.view(i)});
        break;
      case 'chat':
        if (i > 0) {
          final tx = '${m['text'] ?? ''}';
          hostChat(i, tx.length > 60 ? tx.substring(0, 60) : tx);
        }
        break;
      case 'leave':
        if (i > 0) {
          if (started) {
            match?.setConn(i, false);
          } else {
            seats[i] = null;
            _shareLobby();
          }
        }
        break;
    }
  }

  void _client(Map<String, dynamic> m, String from) {
    _lastHost = _now();
    switch (m['t']) {
      case 'welcome':
        joined = true;
        mySeat = (m['seat'] as num).toInt();
        onLobby?.call();
        break;
      case 'lobby':
        final l = m['seats'] as List;
        for (var i = 0; i < 4; i++) {
          final e = l[i];
          seats[i] = e == null ? null : Map<String, String>.from((e as Map).map((k, v) => MapEntry('$k', '$v')));
        }
        final me = _seatOf(myUid);
        if (me >= 0) mySeat = me;
        onLobby?.call();
        break;
      case 'view':
        onView?.call(Map<String, dynamic>.from(m['v'] as Map));
        break;
      case 'chat':
        final s = (m['seat'] as num).toInt();
        if (s != mySeat) onChat?.call(s, '${m['text']}');
        break;
      case 'full':
        onClosed?.call('اتاق پر است.');
        break;
      case 'busy':
        onClosed?.call('بازی در این اتاق شروع شده است.');
        break;
      case 'closed':
        onClosed?.call('میزبان بازی را بست.');
        break;
    }
  }

  // ---------------------------------------------------------------- ارسال از صفحه
  void act(Map<String, dynamic> m) {
    if (isHost) {
      match?.act(0, m);
    } else {
      _send(<String, dynamic>{'t': 'act', 'm': m});
    }
  }

  void chat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final s = t.length > 60 ? t.substring(0, 60) : t;
    if (isHost) {
      hostChat(0, s);
    } else {
      onChat?.call(mySeat, s);
      _send(<String, dynamic>{'t': 'chat', 'text': s});
    }
  }

  void wantSeat(int s) => _send(<String, dynamic>{'t': 'seat', 'want': s});

  void requestSync() => _send(<String, dynamic>{'t': 'sync'});
}
