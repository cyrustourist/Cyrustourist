import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'dice_games.dart' show sharedDie, sharedDiceChip, sharedResultCard;
import 'game_api.dart';
import 'game_engine.dart' show BotLevel;
import 'game_p2p.dart';
import 'game_play_page.dart' show NearbyGameLink;
import 'game_texts.dart';

/// تخته‌نرد دو نفره: با ربات، دو نفره روی یک گوشی، گوشی‌های نزدیک (بدون اینترنت) و آنلاین (اتصال مستقیم).
/// قوانین کامل: میله، زدن مهره، خروج مهره، جفت‌ها (۴ حرکت) و «استفاده از بیشترین تعداد تاس».
/// در حالت شبکه‌ای، گوشی میزبان (بازیکن اول) تاس و قوانین را اجرا می‌کند و وضعیت را برای حریف می‌فرستد.

enum BgMode { bot, local, nearby, online }

const Color _bgFrame = Color(0xff5a3a28);
const Color _bgBoard = Color(0xff0f2a33);
const Color _bgPtA = Color(0xffd9b26f);
const Color _bgPtB = Color(0xff2a8a8d);
const Color _bgCheckerA = Color(0xfff4ead2);
const Color _bgCheckerB = Color(0xffc0392b);

const Map<String, Map<String, String>> _btx = {
  'roll': {'fa': 'تاس بینداز', 'en': 'Roll the dice'},
  'rolling': {'fa': 'در حال انداختن…', 'en': 'Rolling…'},
  'no_moves': {'fa': 'حرکتی ممکن نیست؛ نوبت حریف', 'en': 'No legal moves; opponent’s turn'},
  'pick': {'fa': 'مهره‌ای را انتخاب کنید', 'en': 'Select a checker'},
  'dest': {'fa': 'مقصد را انتخاب کنید', 'en': 'Choose a destination'},
  'bear': {'fa': 'خروج مهره', 'en': 'Bear off'},
  'hit': {'fa': 'مهرهٔ حریف زده شد!', 'en': 'Hit!'},
  'lost': {'fa': 'ارتباط با حریف قطع شد', 'en': 'Connection to the opponent was lost'},
  'host': {'fa': 'ساخت بازی (میزبان)', 'en': 'Host a game'},
  'join': {'fa': 'پیوستن به بازی', 'en': 'Join a game'},
  'join_short': {'fa': 'پیوستن', 'en': 'Join'},
  'wait_join': {'fa': 'منتظر پیوستن حریف…\\nحریف باید «پیوستن به بازی» را بزند.', 'en': 'Waiting for an opponent…\\nThey must tap “Join a game”.'},
  'wait_host': {'fa': 'پیوستید. منتظر شروع بازی…', 'en': 'Joined. Waiting for the game to start…'},
  'none': {'fa': 'بازی‌ای در اطراف پیدا نشد.\\nمیزبان باید «ساخت بازی» را بزند و کنار هم باشید.', 'en': 'No game nearby.\\nThe host must tap “Host a game” and you must be close.'},
  'note': {'fa': 'بدون اینترنت. هر دو گوشی باید شبکهٔ آفلاین را روشن کنند و نزدیک هم باشند.', 'en': 'No internet needed. Both phones must turn on the offline network and stay close.'},
  'fail': {'fa': 'اتصال مستقیم برقرار نشد. دوباره تلاش کنید.', 'en': 'Could not connect directly. Please try again.'},
  'retry': {'fa': 'تلاش دوباره', 'en': 'Try again'},
  'rule': {
    'fa': 'مهره‌ها را به خانهٔ خود برسانید و بیرون ببرید. مهره‌ای را بزنید و روی خانهٔ خالی یا تک‌مهرهٔ حریف بروید؛ روی دو مهرهٔ حریف نمی‌شود رفت. اول کسی که ۱۵ مهره را بیرون ببرد می‌برد.',
    'en': 'Bring your checkers home and bear them off. Hit single opponent checkers; you can’t land on two or more. First to bear off all 15 wins.'
  },
};

String _bt(String key) {
  final m = _btx[key];
  if (m == null) return key;
  return m[GameT.fa ? 'fa' : 'en'] ?? m['en'] ?? key;
}

// ---------------------------------------------------------------- قوانین

class _Mv {
  const _Mv(this.from, this.to, this.die);

  /// -1 = از میله، ۰..۲۳ = خانه
  final int from;

  /// ۰..۲۳ = خانه، -2 = خروج
  final int to;
  final int die;
}

/// بازیکن ۰ (روشن) از خانهٔ ۲۳ به ۰ می‌رود؛ بازیکن ۱ (قرمز) از ۰ به ۲۳. عدد مثبت = مهرهٔ بازیکن ۰، منفی = بازیکن ۱.
class _BgState {
  _BgState({List<int>? pts, List<int>? bar, List<int>? off, this.turn = 0, List<int>? dice})
      : pts = pts ?? _initial(),
        bar = bar ?? <int>[0, 0],
        off = off ?? <int>[0, 0],
        dice = dice ?? <int>[];

  List<int> pts;
  List<int> bar;
  List<int> off;
  int turn;
  List<int> dice;

  static List<int> _initial() {
    final p = List<int>.filled(24, 0);
    p[23] = 2;
    p[12] = 5;
    p[7] = 3;
    p[5] = 5;
    p[0] = -2;
    p[11] = -5;
    p[16] = -3;
    p[18] = -5;
    return p;
  }

  _BgState clone() => _BgState(pts: List<int>.from(pts), bar: List<int>.from(bar), off: List<int>.from(off), turn: turn, dice: List<int>.from(dice));
}

class _Bg {
  _Bg._();

  static int dirOf(int p) => p == 0 ? -1 : 1;
  static int mine(_BgState s, int p, int i) => p == 0 ? s.pts[i] : -s.pts[i];
  static int entry(int p, int die) => p == 0 ? 24 - die : die - 1;
  static bool open(_BgState s, int p, int i) => mine(s, p, i) >= -1;

  static bool allHome(_BgState s, int p) {
    if (s.bar[p] > 0) return false;
    for (var i = 0; i < 24; i++) {
      final c = s.pts[i];
      if (p == 0 && c > 0 && i > 5) return false;
      if (p == 1 && c < 0 && i < 18) return false;
    }
    return true;
  }

  static List<_Mv> movesFor(_BgState s, int p, int die) {
    final out = <_Mv>[];
    if (s.bar[p] > 0) {
      final to = entry(p, die);
      if (open(s, p, to)) out.add(_Mv(-1, to, die));
      return out;
    }
    final d = dirOf(p);
    final home = allHome(s, p);
    for (var i = 0; i < 24; i++) {
      if (mine(s, p, i) <= 0) continue;
      final to = i + d * die;
      if (to < 0 || to > 23) {
        if (!home) continue;
        final dist = p == 0 ? i + 1 : 24 - i;
        if (die == dist) {
          out.add(_Mv(i, -2, die));
        } else if (die > dist) {
          var far = false;
          if (p == 0) {
            for (var j = i + 1; j <= 5; j++) {
              if (mine(s, p, j) > 0) far = true;
            }
          } else {
            for (var j = 18; j < i; j++) {
              if (mine(s, p, j) > 0) far = true;
            }
          }
          if (!far) out.add(_Mv(i, -2, die));
        }
        continue;
      }
      if (open(s, p, to)) out.add(_Mv(i, to, die));
    }
    return out;
  }

  /// true اگر این حرکت مهرهٔ حریف را می‌زند
  static bool hits(_BgState s, int p, _Mv m) {
    if (m.to < 0) return false;
    return mine(s, p, m.to) == -1;
  }

  static void apply(_BgState s, int p, _Mv m) {
    final sign = p == 0 ? 1 : -1;
    if (m.from == -1) {
      s.bar[p]--;
    } else {
      s.pts[m.from] -= sign;
    }
    if (m.to == -2) {
      s.off[p]++;
    } else {
      if (s.pts[m.to] == -sign) {
        s.pts[m.to] = 0;
        s.bar[1 - p]++;
      }
      s.pts[m.to] += sign;
    }
  }

  static int _best(_BgState s, int p, List<int> dice) {
    if (dice.isEmpty) return 0;
    var best = 0;
    final tried = <int>{};
    for (var k = 0; k < dice.length; k++) {
      final die = dice[k];
      if (!tried.add(die)) continue;
      final rest = List<int>.from(dice)..removeAt(k);
      for (final m in movesFor(s, p, die)) {
        final n = s.clone();
        apply(n, p, m);
        final r = 1 + _best(n, p, rest);
        if (r > best) best = r;
        if (best == dice.length) return best;
      }
    }
    return best;
  }

  /// حرکت‌های مجاز بعدی (با قانون: تا جای ممکن همهٔ تاس‌ها بازی شود؛ اگر فقط یکی شدنی بود، تاس بزرگ‌تر).
  static List<_Mv> legal(_BgState s) {
    final p = s.turn;
    final out = <_Mv>[];
    if (s.dice.isEmpty) return out;
    final total = _best(s, p, s.dice);
    if (total == 0) return out;
    final tried = <int>{};
    for (var k = 0; k < s.dice.length; k++) {
      final die = s.dice[k];
      if (!tried.add(die)) continue;
      final rest = List<int>.from(s.dice)..removeAt(k);
      for (final m in movesFor(s, p, die)) {
        final n = s.clone();
        apply(n, p, m);
        if (1 + _best(n, p, rest) == total) out.add(m);
      }
    }
    if (total == 1 && s.dice.length == 2 && s.dice[0] != s.dice[1]) {
      final hi = max(s.dice[0], s.dice[1]);
      if (out.any((m) => m.die == hi)) out.removeWhere((m) => m.die != hi);
    }
    return out;
  }

  static int pip(_BgState s, int p) {
    var t = s.bar[p] * 25;
    for (var i = 0; i < 24; i++) {
      final c = mine(s, p, i);
      if (c > 0) t += c * (p == 0 ? i + 1 : 24 - i);
    }
    return t;
  }

  static double _exposure(_BgState s, int p, int i) {
    final o = 1 - p;
    final od = dirOf(o);
    for (var j = 0; j < 24; j++) {
      if (mine(s, o, j) <= 0) continue;
      final d = (i - j) * od;
      if (d >= 1 && d <= 6) return 1;
    }
    if (s.bar[o] > 0) {
      final d = o == 0 ? 24 - i : i + 1;
      if (d >= 1 && d <= 6) return 1;
    }
    return 0;
  }

  static double _eval(_BgState s, int p, bool hard) {
    final o = 1 - p;
    var v = (pip(s, o) - pip(s, p)) * 0.5 + s.bar[o] * 9 - s.bar[p] * 10 + (s.off[p] - s.off[o]) * 7;
    for (var i = 0; i < 24; i++) {
      final c = mine(s, p, i);
      if (c >= 2) {
        v += 2.5;
      } else if (c == 1) {
        v -= _exposure(s, p, i) * (hard ? 7 : 3.5);
      }
    }
    return v;
  }

  static _Mv botPick(_BgState s, List<_Mv> legal, BotLevel level, Random rnd) {
    if (level == BotLevel.easy) return legal[rnd.nextInt(legal.length)];
    var best = legal.first;
    var bestV = -1e9;
    for (final m in legal) {
      final n = s.clone();
      apply(n, s.turn, m);
      n.dice.remove(m.die);
      final v = _eval(n, s.turn, level == BotLevel.hard) + rnd.nextDouble() * (level == BotLevel.hard ? 0.3 : 3.0);
      if (v > bestV) {
        bestV = v;
        best = m;
      }
    }
    return best;
  }
}

// ---------------------------------------------------------------- صفحهٔ بازی (رسم)

/// چیدمان عمودی: ستون چپ = خانه‌های ۱۱ تا ۰ (بالا به پایین)، ستون راست = خانه‌های ۱۲ تا ۲۳؛ میله وسط.
class _BgGeo {
  _BgGeo(Size size) {
    w = size.width;
    h = size.height;
    pad = w * 0.03;
    laneW = (w - 2 * pad) / 2;
    rh = (h - 2 * pad) / 12.9;
    barH = rh * 0.9;
    d = min(rh * 0.92, laneW / 5.4);
  }

  late final double w, h, pad, laneW, rh, barH, d;

  double rowTop(int r) => pad + r * rh + (r >= 6 ? barH : 0);

  Rect pointRect(int idx) {
    final left = idx < 12;
    final r = left ? 11 - idx : idx - 12;
    return Rect.fromLTWH(left ? pad : pad + laneW, rowTop(r), laneW, rh);
  }

  Rect get barRect => Rect.fromLTWH(pad, pad + 6 * rh, w - 2 * pad, barH);

  /// -1 = میله، ۰..۲۳ = خانه، null = بیرون
  int? hit(Offset p) {
    if (p.dx < pad || p.dx > w - pad || p.dy < pad || p.dy > h - pad) return null;
    if (barRect.contains(p)) return -1;
    final y = p.dy - pad;
    final r = y >= 6 * rh + barH ? ((y - barH) / rh).floor() : (y / rh).floor();
    if (r < 0 || r > 11) return null;
    return p.dx < w / 2 ? 11 - r : 12 + r;
  }
}

class _BgPainter extends CustomPainter {
  const _BgPainter({required this.s, required this.sel, required this.dests, required this.srcs});
  final _BgState s;
  final int? sel;
  final Set<int> dests;
  final Set<int> srcs;

  void _checker(Canvas canvas, Offset c, double r, int pl) {
    final base = pl == 0 ? _bgCheckerA : _bgCheckerB;
    canvas.drawCircle(c + Offset(0, r * 0.12), r, Paint()..color = const Color(0x55000000));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: <Color>[Color.lerp(base, Colors.white, 0.45) ?? base, base, Color.lerp(base, Colors.black, 0.25) ?? base],
          stops: const <double>[0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, r * 0.08)
        ..color = const Color(0x33000000),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, r * 0.07)
        ..color = pl == 0 ? const Color(0xffb89b5e) : const Color(0xff7a1d16),
    );
  }

  void _ring(Canvas canvas, Offset c, double r, bool strong) {
    canvas.drawCircle(
      c,
      r + 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strong ? 3.2 : 2
        ..color = strong ? Colors.white : gGold,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _BgGeo(size);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.045)), Paint()..color = _bgFrame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(g.pad * 0.55, g.pad * 0.55, size.width - g.pad * 1.1, size.height - g.pad * 1.1), Radius.circular(size.width * 0.03)),
      Paint()..color = _bgBoard,
    );

    // مثلث‌ها
    for (var i = 0; i < 24; i++) {
      final rect = g.pointRect(i);
      final left = i < 12;
      final row = left ? 11 - i : i - 12;
      final col = (row + (left ? 0 : 1)).isEven ? _bgPtA : _bgPtB;
      final cy = rect.center.dy;
      final path = Path();
      if (left) {
        path
          ..moveTo(rect.left, rect.top + 1.5)
          ..lineTo(rect.left, rect.bottom - 1.5)
          ..lineTo(rect.left + rect.width * 0.94, cy)
          ..close();
      } else {
        path
          ..moveTo(rect.right, rect.top + 1.5)
          ..lineTo(rect.right, rect.bottom - 1.5)
          ..lineTo(rect.right - rect.width * 0.94, cy)
          ..close();
      }
      canvas.drawPath(path, Paint()..color = col);
      if (dests.contains(i)) {
        canvas.drawPath(path, Paint()..color = const Color(0x66ffd23f));
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = gGold,
        );
      }
    }

    // میله
    canvas.drawRect(g.barRect, Paint()..color = _bgFrame);

    // مهره‌های روی خانه‌ها
    final r = g.d / 2;
    for (var i = 0; i < 24; i++) {
      final n = s.pts[i].abs();
      if (n == 0) continue;
      final pl = s.pts[i] > 0 ? 0 : 1;
      final rect = g.pointRect(i);
      final left = i < 12;
      final avail = g.laneW * 0.9 - g.d;
      final step = n <= 1 ? 0.0 : min(g.d, avail / (n - 1));
      Offset last = Offset.zero;
      for (var k = 0; k < n; k++) {
        final x = left ? rect.left + 2 + r + k * step : rect.right - 2 - r - k * step;
        last = Offset(x, rect.center.dy);
        _checker(canvas, last, r, pl);
      }
      if (n > 5) {
        final tp = TextPainter(
          text: TextSpan(text: '$n', style: TextStyle(color: pl == 0 ? Colors.black87 : Colors.white, fontSize: r * 0.95, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, last - Offset(tp.width / 2, tp.height / 2));
      }
      if (srcs.contains(i)) _ring(canvas, last, r, sel == i);
    }

    // مهره‌های روی میله
    final bc = g.barRect.center;
    for (var pl = 0; pl < 2; pl++) {
      final n = s.bar[pl];
      for (var k = 0; k < n; k++) {
        final dx = (pl == 0 ? -1 : 1) * (g.d * 0.7 + k * min(g.d * 0.9, (g.w * 0.4) / max(1, n)));
        final c = Offset(bc.dx + dx, bc.dy);
        _checker(canvas, c, min(r, g.barH * 0.48), pl);
        if (k == 0 && srcs.contains(-1) && pl == s.turn) _ring(canvas, c, min(r, g.barH * 0.48), sel == -1);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => true;
}

// ---------------------------------------------------------------- صفحه

class _BgRoom {
  _BgRoom(this.code, this.hostUid, this.hostName, this.ts);
  final String code;
  final String hostUid;
  final String hostName;
  int ts;
}

class BackgammonPage extends StatefulWidget {
  const BackgammonPage({super.key, required this.mode, this.level = BotLevel.normal});
  final BgMode mode;
  final BotLevel level;

  @override
  State<BackgammonPage> createState() => _BackgammonPageState();
}

class _BackgammonPageState extends State<BackgammonPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  final OfflineMeshService _mesh = OfflineMeshService.instance;

  BgMode get mode => widget.mode;

  _BgState s = _BgState();
  List<int> rolled = <int>[];
  String stage = 'play'; // play | menu | host | join | search | connect
  String ph = 'roll'; // roll | move | over
  int winner = -1;
  int? sel;
  List<_Mv> legal = <_Mv>[];
  String msgKey = '';
  bool busy = false;
  bool rolling = false;
  bool started = false;
  int seq = 0;
  int myIdx = 0;
  bool isHost = true;
  List<String> pnames = <String>['', ''];
  int gained = 0;
  bool reported = false;
  bool resultReady = false;
  bool lost = false;
  int _gen = 0;
  int _lastSnap = 0;

  // شبکه (نزدیک / آنلاین)
  String code = '';
  String peerUid = '';
  bool _starting = false;
  Timer? _tick;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final Map<String, _BgRoom> rooms = <String, _BgRoom>{};

  // آنلاین
  String roomId = '';
  int myMark = 1;
  int version = 0;
  String onlineErr = '';
  GameP2p? _p2p;
  Timer? _poll;
  Timer? _p2pTimeout;
  bool _polling = false;

  bool get _isAuth => mode == BgMode.bot || mode == BgMode.local || isHost;
  bool get _canAct => !lost && winner < 0 && (mode == BgMode.local || (mode == BgMode.bot ? s.turn == 0 : s.turn == myIdx));

  @override
  void initState() {
    super.initState();
    switch (mode) {
      case BgMode.bot:
        pnames = <String>[GameT.t('you'), GameT.t('robot')];
        _resetState();
        WidgetsBinding.instance.addPostFrameCallback((_) => _afterTurnStart());
        break;
      case BgMode.local:
        pnames = <String>[GameT.t('player1'), GameT.t('player2')];
        _resetState();
        break;
      case BgMode.nearby:
        stage = 'menu';
        NearbyGameLink.instance.attach();
        _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
        _mesh.addListener(_onMesh);
        _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
        break;
      case BgMode.online:
        stage = 'search';
        WidgetsBinding.instance.addPostFrameCallback((_) => _startOnline());
        break;
    }
  }

  @override
  void dispose() {
    _gen++;
    _tick?.cancel();
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _sub?.cancel();
    if (mode == BgMode.nearby) {
      _mesh.removeListener(_onMesh);
      NearbyGameLink.instance.detach();
    }
    _p2p?.close();
    if (mode == BgMode.online && roomId.isNotEmpty && !reported) {
      GameApi.post('/api/game/resign', <String, dynamic>{'room_id': roomId});
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- منطق (روی گوشی میزبان / تک‌گوشی)

  void _resetState() {
    _gen++;
    s = _BgState()..turn = _rnd.nextInt(2);
    rolled = <int>[];
    ph = 'roll';
    winner = -1;
    sel = null;
    legal = <_Mv>[];
    msgKey = '';
    busy = false;
    rolling = false;
    started = true;
    reported = false;
    resultReady = false;
    gained = 0;
    lost = false;
  }

  void _newGame() {
    _resetState();
    _sync();
    _afterTurnStart();
  }

  void _afterTurnStart() {
    if (!mounted || mode != BgMode.bot || s.turn != 1 || ph != 'roll' || winner >= 0) return;
    final gen = _gen;
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || gen != _gen) return;
      _doRoll();
    });
  }

  Map<String, dynamic> _snap() => <String, dynamic>{
        'g': 'bg_s',
        'pts': s.pts,
        'bar': s.bar,
        'off': s.off,
        'turn': s.turn,
        'dice': s.dice,
        'rolled': rolled,
        'ph': ph,
        'win': winner,
        'seq': seq,
        'msg': msgKey,
        'rolling': rolling,
        'busy': busy,
        'names': pnames,
      };

  void _sendNet(Map<String, dynamic> m) {
    if (mode == BgMode.nearby) {
      NearbyGameLink.instance.send(<String, dynamic>{...m, 'to': peerUid, 'code': code});
    } else if (mode == BgMode.online) {
      _p2p?.send(m);
    }
  }

  /// رسم دوباره؛ در حالت میزبان وضعیت را هم برای حریف می‌فرستد.
  void _sync() {
    if (!mounted) return;
    if ((mode == BgMode.nearby || mode == BgMode.online) && isHost && started) {
      seq++;
      _sendNet(_snap());
    }
    setState(() {});
  }

  void _autoSel() {
    final srcs = legal.map((m) => m.from).toSet();
    sel = srcs.length == 1 ? srcs.first : null;
  }

  Future<void> _doRoll() async {
    if (!_isAuth || busy || ph != 'roll' || winner >= 0) return;
    final gen = _gen;
    busy = true;
    rolling = true;
    msgKey = '';
    _sync();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    final a = _rnd.nextInt(6) + 1;
    final b = _rnd.nextInt(6) + 1;
    rolled = a == b ? <int>[a, a, a, a] : <int>[a, b];
    s.dice = List<int>.from(rolled);
    rolling = false;
    legal = _Bg.legal(s);
    if (legal.isEmpty) {
      msgKey = 'no_moves';
      _sync();
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted || gen != _gen) return;
      _endTurn();
      return;
    }
    ph = 'move';
    busy = false;
    sel = null;
    _autoSel();
    _sync();
    if (mode == BgMode.bot && s.turn == 1) _botPlay(gen);
  }

  void _endTurn() {
    s.dice = <int>[];
    s.turn = 1 - s.turn;
    ph = 'roll';
    legal = <_Mv>[];
    sel = null;
    busy = false;
    msgKey = '';
    _sync();
    _afterTurnStart();
  }

  void _applyMoveLocal(_Mv m) {
    final p = s.turn;
    final hit = _Bg.hits(s, p, m);
    _Bg.apply(s, p, m);
    s.dice.remove(m.die);
    sel = null;
    msgKey = hit ? 'hit' : '';
    if (s.off[p] == 15) {
      winner = p;
      ph = 'over';
      legal = <_Mv>[];
      busy = false;
      _sync();
      _finish();
      return;
    }
    legal = _Bg.legal(s);
    if (s.dice.isEmpty || legal.isEmpty) {
      busy = true;
      final gen = _gen;
      _sync();
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || gen != _gen) return;
        _endTurn();
      });
      return;
    }
    _autoSel();
    _sync();
  }

  Future<void> _botPlay(int gen) async {
    while (mounted && gen == _gen && ph == 'move' && mode == BgMode.bot && s.turn == 1 && winner < 0 && !busy) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || gen != _gen || legal.isEmpty) return;
      _applyMoveLocal(_Bg.botPick(s, legal, widget.level, _rnd));
    }
  }

  // ---------------------------------------------------------------- اقدام کاربر

  void _myRoll() {
    if (!_canAct || ph != 'roll' || busy) return;
    if (_isAuth) {
      _doRoll();
    } else {
      _sendNet(<String, dynamic>{'g': 'bg_roll'});
    }
  }

  void _humanMove(_Mv m) {
    if (_isAuth) {
      _applyMoveLocal(m);
    } else {
      sel = null;
      _sendNet(<String, dynamic>{'g': 'bg_mv', 'f': m.from, 't': m.to, 'd': m.die});
      setState(() {});
    }
  }

  void _onTapBoard(Offset p, _BgGeo g) {
    if (!_canAct || ph != 'move' || busy) return;
    final t = g.hit(p);
    if (t == null) {
      setState(() => sel = null);
      return;
    }
    final s0 = sel;
    if (s0 != null) {
      final cand = legal.where((m) => m.from == s0 && m.to == t).toList()..sort((a, b) => a.die.compareTo(b.die));
      if (cand.isNotEmpty) {
        _humanMove(cand.first);
        return;
      }
    }
    if (legal.any((m) => m.from == t)) {
      setState(() => sel = sel == t ? null : t);
      return;
    }
    setState(() => sel = null);
  }

  void _bearOff() {
    final s0 = sel;
    if (s0 == null || !_canAct || ph != 'move' || busy) return;
    final cand = legal.where((m) => m.from == s0 && m.to == -2).toList()..sort((a, b) => a.die.compareTo(b.die));
    if (cand.isNotEmpty) _humanMove(cand.first);
  }

  // ---------------------------------------------------------------- پایان بازی و سکه

  Future<void> _finish() async {
    if (reported) return;
    reported = true;
    if (mode == BgMode.online) {
      await _reportOnline(winner == myIdx ? 'win' : 'loss');
      return;
    }
    final String result;
    final String level;
    switch (mode) {
      case BgMode.bot:
        result = winner == 0 ? 'win' : 'loss';
        level = widget.level.name;
        break;
      case BgMode.local:
        result = 'win';
        level = 'local';
        break;
      default:
        result = winner == myIdx ? 'win' : 'loss';
        level = 'nearby';
    }
    final g = await _w.reportOffline(result, level);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  Future<void> _reportOnline(String result) async {
    for (var i = 0; i < 4; i++) {
      final j = await GameApi.post('/api/game/p2p_result', <String, dynamic>{'room_id': roomId, 'result': result});
      if (!mounted) return;
      if (j != null) {
        _w.applyWallet(j['wallet']);
        final settled = j['settled'] == true;
        setState(() {
          gained = settled ? ((j['gained'] as num?)?.toInt() ?? 0) : 0;
          resultReady = true;
        });
        if (settled || j['success'] != true) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
    }
    if (mounted) setState(() => resultReady = true);
  }

  // ---------------------------------------------------------------- پیام‌های شبکه

  /// پیام‌های بازی که از حریف می‌رسد (نزدیک یا آنلاین)
  void _onGameMsg(Map<String, dynamic> m) {
    switch ('${m['g']}') {
      case 'bg_s':
        if (!isHost) _applySnap(m);
        break;
      case 'bg_roll':
        if (isHost && s.turn == 1 && ph == 'roll') _doRoll();
        break;
      case 'bg_mv':
        if (isHost && s.turn == 1 && ph == 'move' && !busy) {
          final f = (m['f'] as num?)?.toInt();
          final t = (m['t'] as num?)?.toInt();
          final d = (m['d'] as num?)?.toInt();
          for (final mv in legal) {
            if (mv.from == f && mv.to == t && mv.die == d) {
              _applyMoveLocal(mv);
              break;
            }
          }
        }
        break;
    }
  }

  void _applySnap(Map<String, dynamic> m) {
    final sq = (m['seq'] as num?)?.toInt() ?? 0;
    _lastSnap = DateTime.now().millisecondsSinceEpoch;
    if (started && sq <= seq) return;
    List<int> ints(dynamic l) => (l as List<dynamic>).map((e) => (e as num).toInt()).toList();
    setState(() {
      seq = sq;
      started = true;
      stage = 'play';
      lost = false;
      s = _BgState(pts: ints(m['pts']), bar: ints(m['bar']), off: ints(m['off']), turn: (m['turn'] as num).toInt(), dice: ints(m['dice']));
      rolled = ints(m['rolled']);
      ph = '${m['ph']}';
      winner = (m['win'] as num).toInt();
      msgKey = '${m['msg']}';
      rolling = m['rolling'] == true;
      busy = m['busy'] == true;
      final nm = m['names'];
      if (nm is List && nm.length == 2) pnames = <String>['${nm[0]}', '${nm[1]}'];
      legal = ph == 'move' ? _Bg.legal(s) : <_Mv>[];
      if (!(sel != null && legal.any((x) => x.from == sel))) sel = null;
      if (sel == null && _canAct && ph == 'move') _autoSel();
    });
    if (winner >= 0) _finish();
  }

  // ---------------------------------------------------------------- گوشی‌های نزدیک

  void _onMesh() {
    if (mounted) setState(() {});
  }

  void _onTick() {
    if (!mounted || !_mesh.running) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (stage == 'host') {
      NearbyGameLink.instance.send(<String, dynamic>{'g': 'bg_open', 'code': code});
    } else if (stage == 'join') {
      rooms.removeWhere((k, v) => now - v.ts > 7000);
      if (code.isNotEmpty && !started) {
        NearbyGameLink.instance.send(<String, dynamic>{'g': 'bg_join', 'to': peerUid, 'code': code});
      }
      setState(() {});
    } else if (stage == 'play' && started) {
      if (isHost) {
        _sendNet(_snap());
        if (!lost && peerUid.isNotEmpty && !_mesh.peers.values.any((p) => p.uid == peerUid) && ph != 'over') {
          setState(() => lost = true);
        }
      } else if (!lost && now - _lastSnap > 20000 && ph != 'over') {
        setState(() => lost = true);
      }
    }
  }

  void _onEvent(Map<String, dynamic> m) {
    if (!mounted) return;
    final g = '${m['g']}';
    if (!g.startsWith('bg_')) return;
    final from = '${m['u']}';
    final toMe = '${m['to']}' == _mesh.myUid;
    switch (g) {
      case 'bg_open':
        if (stage == 'join') {
          final c = '${m['code']}';
          setState(() => rooms[c] = _BgRoom(c, from, '${m['n']}', DateTime.now().millisecondsSinceEpoch));
        }
        break;
      case 'bg_join':
        if (stage == 'host' && toMe && '${m['code']}' == code) {
          peerUid = from;
          pnames = <String>[_mesh.myName, '${m['n']}'];
          stage = 'play';
          _newGame();
        }
        break;
      default:
        if (toMe && '${m['code']}' == code && from == peerUid && stage != 'menu') _onGameMsg(m);
    }
  }

  Future<void> _toggleNet() async {
    if (_starting) return;
    if (_mesh.running) {
      await _mesh.stop();
      return;
    }
    setState(() => _starting = true);
    final ok = await _mesh.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (!ok) gToast(context, _mesh.lastError.isEmpty ? GameT.t('nearby_perm') : '${GameT.t('nearby_perm')}\n(${_mesh.lastError.length > 70 ? _mesh.lastError.substring(0, 70) : _mesh.lastError})');
  }

  void _createNearby() {
    if (!_mesh.running) return;
    code = '${1000 + _rnd.nextInt(9000)}';
    isHost = true;
    myIdx = 0;
    started = false;
    setState(() => stage = 'host');
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'bg_open', 'code': code});
  }

  void _openJoin() {
    isHost = false;
    myIdx = 1;
    started = false;
    code = '';
    setState(() => stage = 'join');
  }

  void _joinRoom(_BgRoom r) {
    setState(() {
      code = r.code;
      peerUid = r.hostUid;
    });
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'bg_join', 'to': peerUid, 'code': code});
  }

  // ---------------------------------------------------------------- آنلاین

  void _failOnline(String msg) {
    if (!mounted) return;
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _p2p?.close();
    _p2p = null;
    setState(() {
      onlineErr = msg;
      stage = 'search';
    });
  }

  Future<void> _startOnline() async {
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _p2p?.close();
    _p2p = null;
    started = false;
    roomId = '';
    setState(() {
      stage = 'search';
      onlineErr = '';
    });
    final j = await GameApi.post('/api/game/quick', <String, dynamic>{'game': 'bg'});
    if (!mounted) return;
    if (j == null) {
      _failOnline(GameT.t('net_err'));
      return;
    }
    if (j['success'] != true || j['room'] is! Map) {
      final e = j['error'];
      _failOnline(e == 'not_registered' || e == 'no_name' || e == 'auth_required'
          ? GameT.t('need_profile')
          : (e == 'disabled' ? '${j['message'] ?? GameT.t('disabled')}' : GameT.t('net_err')));
      return;
    }
    _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
    if (stage != 'connect') {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollTick());
    }
  }

  void _applyRoom(Map<String, dynamic> r) {
    roomId = '${r['id']}';
    myMark = (r['my_mark'] as num?)?.toInt() ?? 1;
    version = (r['version'] as num?)?.toInt() ?? 0;
    myIdx = myMark - 1;
    isHost = myMark == 1;
    final host = r['host'] is Map ? '${(r['host'] as Map)['name']}' : '';
    final guest = r['guest'] is Map ? '${(r['guest'] as Map)['name']}' : '';
    pnames = <String>[host, guest];
    final st = '${r['status']}';
    if (st == 'playing' && stage != 'connect' && stage != 'play') _connectP2p();
  }

  Future<void> _pollTick() async {
    if (!mounted || _polling || roomId.isEmpty || stage != 'search') return;
    _polling = true;
    try {
      final j = await GameApi.get('/api/game/state', <String, String>{'room_id': roomId, 'since': '$version'});
      if (!mounted || j == null) return;
      if (j['success'] != true) {
        if (j['error'] == 'room_gone') _failOnline(GameT.t('net_err'));
        return;
      }
      if (j['changed'] == true && j['room'] is Map) {
        _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
        if (stage == 'connect') _poll?.cancel();
      }
    } finally {
      _polling = false;
    }
  }

  void _connectP2p() {
    setState(() => stage = 'connect');
    _poll?.cancel();
    final p = GameP2p(
      roomId: roomId,
      isHost: myMark == 1,
      onConfirmed: _onP2pOk,
      onMessage: (m) {
        if (mounted && '${m['g']}'.startsWith('bg_')) _onGameMsg(m);
      },
      onClosed: () {
        if (mounted && stage == 'play' && ph != 'over') setState(() => lost = true);
      },
    );
    _p2p = p;
    p.start();
    _p2pTimeout?.cancel();
    _p2pTimeout = Timer(const Duration(seconds: 25), () {
      if (stage == 'connect') _failOnline(_bt('fail'));
    });
  }

  void _onP2pOk() {
    if (!mounted || stage == 'play') return;
    _p2pTimeout?.cancel();
    stage = 'play';
    _lastSnap = DateTime.now().millisecondsSinceEpoch;
    if (isHost) {
      _newGame();
    } else {
      started = false;
      setState(() {});
    }
  }

  // ---------------------------------------------------------------- رابط

  String _status() {
    if (winner >= 0) {
      if (mode == BgMode.local) return GameT.t('wins', <String, String>{'n': pnames[winner]});
      return (mode == BgMode.bot ? winner == 0 : winner == myIdx) ? GameT.t('you_win') : GameT.t('you_lose');
    }
    if (lost) return _bt('lost');
    if (mode == BgMode.bot) return s.turn == 0 ? GameT.t('your_turn') : GameT.t('opp_turn');
    if (mode == BgMode.local) return GameT.t('turn_of', <String, String>{'n': pnames[s.turn]});
    return s.turn == myIdx ? GameT.t('your_turn') : GameT.t('turn_of', <String, String>{'n': pnames[s.turn]});
  }

  String _hint() {
    if (msgKey.isNotEmpty) return _bt(msgKey);
    if (rolling) return _bt('rolling');
    if (ph == 'move' && _canAct) return sel == null ? _bt('pick') : _bt('dest');
    return '';
  }

  Widget _netCard() {
    final on = _mesh.running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: on ? gPanel : gGold, foregroundColor: on ? gGold : gBg, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _toggleNet,
        icon: _starting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
        label: Text(on ? '${GameT.t('nearby_stop')} · ${_mesh.peers.length}' : GameT.t('nearby_start'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _big(IconData icon, String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine, padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _center(List<Widget> children) => Padding(padding: const EdgeInsets.only(top: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  Widget _body(double w) {
    switch (stage) {
      case 'menu':
        return _center(<Widget>[
          _netCard(),
          if (_mesh.running) ...<Widget>[_big(Icons.add_circle_rounded, _bt('host'), _createNearby), _big(Icons.login_rounded, _bt('join'), _openJoin)],
          const SizedBox(height: 8),
          Text(_bt('note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12, height: 1.8)),
        ]);
      case 'host':
        return _center(<Widget>[
          _netCard(),
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: gGold)),
          const SizedBox(height: 16),
          Text(_bt('wait_join').replaceAll('\\n', '\n'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.9)),
        ]);
      case 'join':
        final list = rooms.values.toList();
        return _center(<Widget>[
          _netCard(),
          if (code.isNotEmpty) ...<Widget>[
            Text(_bt('wait_host'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.8)),
          ] else if (list.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(_bt('none').replaceAll('\\n', '\n'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)))
          else
            for (final r in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
                child: Row(children: [
                  const Icon(Icons.phone_android_rounded, color: gTeal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg), onPressed: () => _joinRoom(r), child: Text(_bt('join_short'), style: const TextStyle(fontWeight: FontWeight.w900))),
                ]),
              ),
        ]);
      case 'search':
      case 'connect':
        final failed = onlineErr.isNotEmpty;
        return _center(<Widget>[
          const SizedBox(height: 40),
          if (!failed) const Center(child: CircularProgressIndicator(color: gGold)),
          const SizedBox(height: 18),
          Text(failed ? onlineErr : (stage == 'connect' ? GameT.t('connecting') : GameT.t('searching')), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, fontSize: 15, height: 1.8)),
          const SizedBox(height: 18),
          if (failed) _big(Icons.refresh_rounded, _bt('retry'), _startOnline) else OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)), onPressed: () => Navigator.of(context).pop(), child: Text(GameT.t('cancel'))),
        ]);
      default:
        return _play(w);
    }
  }

  Widget _play(double w) {
    if (!started) {
      return _center(<Widget>[const SizedBox(height: 40), const Center(child: CircularProgressIndicator(color: gGold)), const SizedBox(height: 16), Text(GameT.t('connecting'), textAlign: TextAlign.center, style: const TextStyle(color: gGold))]);
    }
    final srcs = _canAct && ph == 'move' ? legal.map((m) => m.from).toSet() : <int>{};
    final dests = <int>{};
    var canOff = false;
    final s0 = sel;
    if (s0 != null && _canAct && ph == 'move') {
      for (final m in legal) {
        if (m.from != s0) continue;
        if (m.to == -2) {
          canOff = true;
        } else {
          dests.add(m.to);
        }
      }
    }
    final rem = List<int>.from(s.dice);
    final used = <bool>[for (final d in rolled) !rem.remove(d)];
    final geo = Size(w, w * 1.55);
    final names = pnames;
    return Column(
      children: [
        Row(children: [
          sharedDiceChip(names[0], _bgCheckerA, '${s.off[0]}/15', winner < 0 && s.turn == 0),
          const SizedBox(width: 10),
          sharedDiceChip(names[1], _bgCheckerB, '${s.off[1]}/15', winner < 0 && s.turn == 1),
        ]),
        const SizedBox(height: 10),
        Text(_status(), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
        SizedBox(height: 20, child: Text(_hint(), style: const TextStyle(color: gSky, fontSize: 12.5, fontWeight: FontWeight.w700))),
        const SizedBox(height: 4),
        SizedBox(
          width: geo.width,
          height: geo.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTapBoard(d.localPosition, _BgGeo(geo)),
            child: CustomPaint(painter: _BgPainter(s: s, sel: sel, dests: dests, srcs: srcs)),
          ),
        ),
        const SizedBox(height: 10),
        if (canOff)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: gTeal, foregroundColor: gBg, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
              onPressed: _bearOff,
              icon: const Icon(Icons.logout_rounded),
              label: Text(_bt('bear'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < rolled.length; i++)
              Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: sharedDie(rolled[i], size: rolled.length > 2 ? 36 : 46, dim: used[i])),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
              onPressed: _canAct && ph == 'roll' && !busy ? _myRoll : null,
              icon: const Icon(Icons.casino_rounded),
              label: Text(rolling ? _bt('rolling') : _bt('roll'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        if (winner >= 0 && resultReady)
          sharedResultCard(
            title: _status(),
            gained: gained,
            onAgain: () {
              if (mode == BgMode.bot || mode == BgMode.local) {
                _newGame();
              } else {
                Navigator.of(context).pop();
              }
            },
            onBack: () => Navigator.of(context).pop(),
          ),
        const SizedBox(height: 14),
        Text(_bt('rule'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GameT.t('backgammon'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 24, 460.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Center(child: SizedBox(width: w, child: _body(w))),
              );
            },
          ),
        ),
      ),
    );
  }
}
