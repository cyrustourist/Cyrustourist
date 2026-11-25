import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../pages/games/game_wheel.dart' show wFa;
import '../pages/groups/group_ui.dart';
import 'gg_net.dart';
import 'gg_prefs.dart';
import 'gg_settings_sheet.dart';
import 'gg_types.dart';

/// مینی‌گلف؛ تک‌نفره با ربات یا ۲ تا ۴ نفر با گوشی‌های اطراف.
/// هر بازیکن توپ خودش را روی گوشی خودش می‌زند (هم‌زمان)؛ موقعیت توپ‌ها و تعداد ضربه‌ها
/// برای همه فرستاده می‌شود و میزبان بعد از تمام شدن همه، حفره‌ی بعد را شروع می‌کند.
class GgGolfPage extends StatefulWidget {
  const GgGolfPage({super.key, required this.cfg, this.net, this.me = 0});
  final GgConfig cfg;
  final GgNet? net;
  final int me;

  @override
  State<GgGolfPage> createState() => _GgGolfPageState();
}

class _Bar {
  const _Bar(this.pivot, this.len, this.speed);
  final Offset pivot;
  final double len;
  final double speed; // رادیان بر ثانیه
}

class _Hole {
  const _Hole({
    required this.name,
    required this.par,
    required this.tee,
    required this.cup,
    this.walls = const <Rect>[],
    this.sand = const <Rect>[],
    this.water = const <Rect>[],
    this.bars = const <_Bar>[],
  });
  final String name;
  final int par;
  final Offset tee;
  final Offset cup;
  final List<Rect> walls;
  final List<Rect> sand;
  final List<Rect> water;
  final List<_Bar> bars;
}

const double _W = 360;
const double _H = 600;
const double _br = 7; // شعاع توپ
const double _cupR = 12;
const int _maxStrokes = 7;

final List<_Hole> _allHoles = <_Hole>[
  const _Hole(name: 'مستقیم', par: 2, tee: Offset(180, 530), cup: Offset(180, 90)),
  _Hole(name: 'پیچ', par: 3, tee: const Offset(70, 540), cup: const Offset(290, 90), walls: <Rect>[Rect.fromLTWH(0, 300, 250, 34)]),
  _Hole(name: 'زیگزاگ', par: 3, tee: const Offset(60, 550), cup: const Offset(300, 80), walls: <Rect>[Rect.fromLTWH(0, 400, 250, 30), Rect.fromLTWH(110, 230, 250, 30)]),
  _Hole(name: 'شن‌زار', par: 3, tee: const Offset(180, 550), cup: const Offset(180, 80), sand: <Rect>[Rect.fromLTWH(50, 240, 260, 130)]),
  _Hole(name: 'برکه', par: 3, tee: const Offset(80, 550), cup: const Offset(110, 80), water: <Rect>[Rect.fromLTWH(0, 270, 240, 80)]),
  _Hole(
    name: 'آسیاب',
    par: 3,
    tee: const Offset(180, 550),
    cup: const Offset(180, 70),
    walls: <Rect>[Rect.fromLTWH(0, 230, 120, 150), Rect.fromLTWH(240, 230, 120, 150)],
    bars: const <_Bar>[_Bar(Offset(180, 305), 120, 1.8)],
  ),
  _Hole(
    name: 'دالان',
    par: 4,
    tee: const Offset(180, 550),
    cup: const Offset(180, 70),
    walls: <Rect>[Rect.fromLTWH(0, 180, 125, 300), Rect.fromLTWH(235, 180, 125, 300)],
    water: <Rect>[Rect.fromLTWH(125, 300, 38, 60), Rect.fromLTWH(197, 300, 38, 60)],
    sand: <Rect>[Rect.fromLTWH(125, 200, 110, 60)],
  ),
  _Hole(
    name: 'دو پره',
    par: 4,
    tee: const Offset(60, 550),
    cup: const Offset(300, 70),
    sand: <Rect>[Rect.fromLTWH(200, 380, 160, 80)],
    bars: const <_Bar>[_Bar(Offset(110, 380), 110, 1.6), _Bar(Offset(250, 200), 110, -2.0)],
  ),
  _Hole(
    name: 'فینال',
    par: 4,
    tee: const Offset(180, 555),
    cup: const Offset(300, 70),
    walls: <Rect>[Rect.fromLTWH(0, 420, 230, 28), Rect.fromLTWH(130, 260, 230, 28)],
    water: <Rect>[Rect.fromLTWH(0, 150, 200, 50)],
    bars: const <_Bar>[_Bar(Offset(180, 354), 100, 2.2)],
  ),
];

class _GgGolfPageState extends State<GgGolfPage> with SingleTickerProviderStateMixin {
  final GgPrefs pr = GgPrefs.instance;
  final Random _rnd = Random();
  late final Ticker _ticker;
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);
  final List<Timer> _timers = <Timer>[];

  GgConfig get cfg => widget.cfg;
  GgNet? get net => widget.net;
  int get n => cfg.players.length;
  bool get isHost => net == null || net!.isHost;
  int get me => widget.me < 0 ? 0 : widget.me;

  late final List<_Hole> holes;
  late final List<List<int>> sc; // امتیاز: [بازیکن][حفره] (۰ یعنی هنوز تمام نشده)
  late final List<bool> conn;

  int hole = 0;
  double bx = 0, by = 0, bvx = 0, bvy = 0;
  double lastX = 0, lastY = 0;
  bool moving = false;
  bool sunk = false;
  bool done = false;
  int strokes = 0;
  String phase = 'play'; // play | over
  double _t = 0;
  Duration _prev = Duration.zero;
  double _posT = 0;
  bool _advancing = false;
  bool _overHandled = false;
  int _reward = 0;
  bool _showBoard = false;
  String _toast = '';
  double _toastT = 0;
  String _netMsg = '';
  Size _size = const Size(360, 640);

  // هدف‌گیری
  bool aiming = false;
  Offset finger = Offset.zero;

  // توپ‌های بقیه (روح)
  late List<double> ox, oy, otx, oty;

  double get _sc => max(.1, min((_size.width - 20) / _W, (_size.height - 170) / _H));
  Offset get _ctr => Offset(_size.width / 2, _size.height / 2 + 22);
  Offset toLogical(Offset s) => (s - _ctr) / _sc + const Offset(_W / 2, _H / 2);

  double get _powerMul => cfg.solo ? 1 + .08 * pr.lvl('gf_power') : 1;
  double get _aimMul => cfg.solo ? 1 + .35 * pr.lvl('gf_aim') : 1;

  @override
  void initState() {
    super.initState();
    pr.load();
    final order = cfg.holes <= 3 ? <int>[0, 3, 5] : (cfg.holes <= 6 ? <int>[0, 1, 3, 4, 5, 8] : List<int>.generate(9, (i) => i));
    holes = <_Hole>[for (final i in order) _allHoles[i]];
    sc = List<List<int>>.generate(n, (_) => List<int>.filled(holes.length, 0));
    conn = List<bool>.filled(n, true);
    ox = List<double>.filled(n, 0);
    oy = List<double>.filled(n, 0);
    otx = List<double>.filled(n, 0);
    oty = List<double>.filled(n, 0);
    final nt = net;
    if (nt != null) {
      nt.onGame = _onNetGame;
      nt.onError = (e) {
        if (mounted && _netMsg != e) setState(() => _netMsg = e);
      };
      nt.onClosed = (r) {
        if (!mounted) return;
        gToast(context, r);
        Navigator.of(context).maybePop();
      };
      nt.onConn = (seat, c) {
        final pi = _playerOfSeat(seat);
        if (pi >= 0 && isHost) {
          conn[pi] = c;
          _check();
        }
      };
    }
    _startHole(0);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _ticker.dispose();
    repaint.dispose();
    net?.close();
    super.dispose();
  }

  int _playerOfSeat(int seat) {
    final s = net?.seats[seat];
    if (s == null) return -1;
    return cfg.players.indexWhere((p) => p.uid.isNotEmpty && p.uid == s['uid']);
  }

  // ------------------------------------------------------------------ حفره‌ها
  void _startHole(int h) {
    if (h >= holes.length) {
      _end();
      return;
    }
    hole = h;
    final hl = holes[h];
    bx = lastX = hl.tee.dx;
    by = lastY = hl.tee.dy;
    bvx = bvy = 0;
    moving = false;
    sunk = false;
    done = false;
    strokes = 0;
    aiming = false;
    _advancing = false;
    for (var i = 0; i < n; i++) {
      ox[i] = otx[i] = hl.tee.dx;
      oy[i] = oty[i] = hl.tee.dy;
    }
    if (isHost) {
      for (var i = 0; i < n; i++) {
        if (cfg.players[i].bot) {
          final hh = h;
          final pi = i;
          _timers.add(Timer(Duration(milliseconds: 3500 + _rnd.nextInt(8000)), () {
            if (mounted && hole == hh && sc[pi][hh] == 0) _announce(pi, hh, _botStrokes(hl.par));
          }));
        }
      }
    }
    if (mounted) setState(() {});
  }

  int _botStrokes(int par) {
    final r = _rnd.nextDouble();
    int d;
    switch (cfg.level.clamp(0, 2)) {
      case 0:
        d = r < .3 ? 0 : (r < .7 ? 1 : 2);
        break;
      case 1:
        d = r < .15 ? -1 : (r < .55 ? 0 : (r < .85 ? 1 : 2));
        break;
      default:
        d = r < .3 ? -1 : (r < .75 ? 0 : 1);
    }
    return (par + d).clamp(1, _maxStrokes + 1);
  }

  void _announce(int pi, int h, int s) {
    if (sc[pi][h] != 0) return;
    sc[pi][h] = s;
    final nt = net;
    if (nt != null) {
      final m = <String, dynamic>{'k': 'done', 'pi': pi, 'h': h, 's': s};
      if (nt.isHost) {
        nt.hostSend(m);
      } else if (pi == me) {
        nt.clientSend(m, relay: true);
      }
    }
    if (mounted) setState(() {});
    _check();
  }

  /// فقط میزبان: وقتی همه حفره را تمام کردند (یا قطع شدند) حفره‌ی بعد شروع می‌شود.
  void _check() {
    if (!isHost || _advancing || phase != 'play') return;
    for (var i = 0; i < n; i++) {
      if (sc[i][hole] == 0) {
        if (!conn[i] && !cfg.players[i].bot) {
          sc[i][hole] = _maxStrokes + 1;
        } else {
          return;
        }
      }
    }
    _advancing = true;
    _timers.add(Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final nh = hole + 1;
      net?.hostSend(<String, dynamic>{'k': 'next', 'h': nh});
      _startHole(nh);
    }));
  }

  void _onNetGame(int seat, Map<String, dynamic> m) {
    switch (m['k']) {
      case 'pos':
        final pi = (m['pi'] as num).toInt();
        if (pi == me || pi < 0 || pi >= n || (m['h'] as num).toInt() != hole) return;
        otx[pi] = (m['x'] as num).toDouble();
        oty[pi] = (m['y'] as num).toDouble();
        break;
      case 'done':
        final pi = (m['pi'] as num).toInt();
        final h = (m['h'] as num).toInt();
        if (pi == me || pi < 0 || pi >= n || h < 0 || h >= holes.length) return;
        if (sc[pi][h] == 0) sc[pi][h] = (m['s'] as num).toInt();
        if (mounted) setState(() {});
        _check();
        break;
      case 'next':
        if (!isHost) {
          final nh = (m['h'] as num).toInt();
          if (nh > hole) _startHole(nh);
        }
        break;
    }
  }

  void _sendPos() {
    final nt = net;
    if (nt == null) return;
    nt.clientSend(<String, dynamic>{'k': 'pos', 'pi': me, 'h': hole, 'x': (bx * 10).round() / 10, 'y': (by * 10).round() / 10}, relay: true);
  }

  // ------------------------------------------------------------------ فیزیک
  void _onTick(Duration el) {
    var dt = (el - _prev).inMicroseconds / 1e6;
    _prev = el;
    if (dt <= 0) return;
    if (dt > .033) dt = .033;
    _t += dt;
    if (_toastT > 0) {
      _toastT -= dt;
      if (_toastT <= 0 && mounted) setState(() => _toast = '');
    }
    for (var i = 0; i < n; i++) {
      if (i == me) continue;
      ox[i] += (otx[i] - ox[i]) * .3;
      oy[i] += (oty[i] - oy[i]) * .3;
    }
    if (phase == 'play' && !done) {
      final hl = holes[hole];
      if (moving || hl.bars.isNotEmpty) _stepBall(dt, hl);
      if (moving) {
        _posT += dt;
        if (_posT > .1) {
          _posT = 0;
          _sendPos();
        }
      }
    }
    repaint.value++;
  }

  Offset _barPoint(_Bar b, double sign) {
    final a = b.speed * _t;
    return b.pivot + Offset(cos(a), sin(a)) * (b.len / 2 * sign);
  }

  void _stepBall(double dt, _Hole hl) {
    const sub = 3;
    final h = dt / sub;
    for (var k = 0; k < sub; k++) {
      if (moving) {
        bx += bvx * h;
        by += bvy * h;
        if (bx < _br) {
          bx = _br;
          _bounce(-1, 0);
        } else if (bx > _W - _br) {
          bx = _W - _br;
          _bounce(1, 0);
        }
        if (by < _br) {
          by = _br;
          _bounce(0, -1);
        } else if (by > _H - _br) {
          by = _H - _br;
          _bounce(0, 1);
        }
        for (final r in hl.walls) {
          _circRect(r);
        }
      }
      for (final b in hl.bars) {
        _circBar(b);
      }
      if (!moving && (bvx != 0 || bvy != 0)) moving = true;
      if (!moving) continue;
      for (final w in hl.water) {
        if (w.contains(Offset(bx, by))) {
          _splash();
          return;
        }
      }
      final dx = hl.cup.dx - bx, dy = hl.cup.dy - by;
      final d = sqrt(dx * dx + dy * dy);
      final sp = sqrt(bvx * bvx + bvy * bvy);
      if (d < _cupR && sp < 400) {
        bx = hl.cup.dx;
        by = hl.cup.dy;
        bvx = bvy = 0;
        moving = false;
        sunk = true;
        GgSfx.play('sink');
        GgSfx.buzz();
        _sendPos();
        _finish(strokes);
        return;
      }
      if (d < _cupR * 1.9 && sp < 230 && d > .5) {
        bvx += dx / d * 420 * h;
        bvy += dy / d * 420 * h;
      }
    }
    if (!moving) return;
    final sandy = hl.sand.any((r) => r.contains(Offset(bx, by)));
    final spd = sqrt(bvx * bvx + bvy * bvy);
    final dec = (sandy ? 5.0 : .9) * spd + (sandy ? 75.0 : 28.0);
    final ns = spd - dec * dt;
    if (ns < 14) {
      bvx = bvy = 0;
      moving = false;
      _sendPos();
      if (strokes >= _maxStrokes && !sunk) {
        _toastMsg('حداکثر ضربه؛ حفره تمام شد');
        _finish(_maxStrokes + 1);
      }
    } else {
      bvx *= ns / spd;
      bvy *= ns / spd;
    }
  }

  void _bounce(double nx, double ny) {
    final vn = bvx * nx + bvy * ny;
    if (vn > 0) {
      bvx -= 1.78 * vn * nx;
      bvy -= 1.78 * vn * ny;
      if (vn > 60) GgSfx.play('wall');
    }
  }

  void _circRect(Rect r) {
    final cx = bx.clamp(r.left, r.right).toDouble();
    final cy = by.clamp(r.top, r.bottom).toDouble();
    var dx = bx - cx, dy = by - cy;
    final d2 = dx * dx + dy * dy;
    if (d2 >= _br * _br) return;
    double nx, ny;
    if (d2 > .0001) {
      final d = sqrt(d2);
      nx = dx / d;
      ny = dy / d;
      bx = cx + nx * _br;
      by = cy + ny * _br;
    } else {
      final l = bx - r.left, rr = r.right - bx, t = by - r.top, b = r.bottom - by;
      final m = min(min(l, rr), min(t, b));
      if (m == l) {
        nx = -1;
        ny = 0;
        bx = r.left - _br;
      } else if (m == rr) {
        nx = 1;
        ny = 0;
        bx = r.right + _br;
      } else if (m == t) {
        nx = 0;
        ny = -1;
        by = r.top - _br;
      } else {
        nx = 0;
        ny = 1;
        by = r.bottom + _br;
      }
    }
    final vn = bvx * nx + bvy * ny;
    if (vn < 0) {
      bvx -= 1.78 * vn * nx;
      bvy -= 1.78 * vn * ny;
      if (-vn > 60) GgSfx.play('wall');
    }
  }

  void _circBar(_Bar b) {
    final a = _barPoint(b, -1), c = _barPoint(b, 1);
    final ab = c - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    var t = ((bx - a.dx) * ab.dx + (by - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0).toDouble();
    final cp = a + ab * t;
    var dx = bx - cp.dx, dy = by - cp.dy;
    final d = sqrt(dx * dx + dy * dy);
    const th = 5.0;
    if (d >= _br + th) return;
    double nx, ny;
    if (d > .001) {
      nx = dx / d;
      ny = dy / d;
    } else {
      nx = 0;
      ny = -1;
    }
    bx = cp.dx + nx * (_br + th);
    by = cp.dy + ny * (_br + th);
    final vbx = -b.speed * (cp.dy - b.pivot.dy);
    final vby = b.speed * (cp.dx - b.pivot.dx);
    final rvx = bvx - vbx, rvy = bvy - vby;
    final vn = rvx * nx + rvy * ny;
    if (vn < 0) {
      bvx -= 1.8 * vn * nx;
      bvy -= 1.8 * vn * ny;
      GgSfx.play('wall');
    }
  }

  void _splash() {
    GgSfx.play('splash');
    GgSfx.buzz();
    bx = lastX;
    by = lastY;
    bvx = bvy = 0;
    moving = false;
    strokes++;
    _toastMsg('توپ افتاد توی آب! یک ضربه جریمه');
    _sendPos();
    if (strokes >= _maxStrokes) _finish(_maxStrokes + 1);
  }

  void _toastMsg(String t) {
    _toast = t;
    _toastT = 2.2;
    if (mounted) setState(() {});
  }

  void _finish(int s) {
    if (done) return;
    done = true;
    _announce(me, hole, s);
  }

  // ------------------------------------------------------------------ ورودی
  void _down(PointerEvent e) {
    if (phase != 'play' || done || moving) return;
    final l = toLogical(e.localPosition);
    if ((l - Offset(bx, by)).distance < 70) {
      aiming = true;
      finger = l;
    }
  }

  void _move(PointerEvent e) {
    if (aiming) finger = toLogical(e.localPosition);
  }

  void _up(PointerEvent e) {
    if (!aiming) return;
    aiming = false;
    final pull = _pull();
    if (pull.distance < 10) return;
    final k = min(pull.distance, 110.0) / 110;
    final dir = pull / pull.distance;
    final speed = k * 640 * _powerMul;
    lastX = bx;
    lastY = by;
    bvx = dir.dx * speed;
    bvy = dir.dy * speed;
    moving = true;
    strokes++;
    GgSfx.play('putt');
    GgSfx.buzz();
    setState(() {});
  }

  /// بردار ضربه: از انگشت به سمت توپ (مثل کمان)
  Offset _pull() {
    final v = (Offset(bx, by) - finger) * (pr.gfSens / 100);
    final d = v.distance;
    if (d > 110) return v / d * 110;
    return v;
  }

  // ------------------------------------------------------------------ پایان
  int _total(int pi) {
    var s = 0;
    for (final v in sc[pi]) {
      s += v == 0 ? _maxStrokes + 1 : v;
    }
    return s;
  }

  List<int> get _ranking {
    final idx = List<int>.generate(n, (i) => i);
    idx.sort((a, b) => _total(a).compareTo(_total(b)));
    return idx;
  }

  Future<void> _end() async {
    if (_overHandled) return;
    _overHandled = true;
    phase = 'over';
    final rank = _ranking.indexOf(me);
    final won = rank == 0;
    GgSfx.play(won ? 'win' : 'lose');
    var base = 0;
    if (cfg.solo) {
      base = won ? <int>[20, 35, 50][cfg.level.clamp(0, 2)] : 0;
    } else {
      base = rank == 0 ? 60 : (rank == 1 ? 25 : 10);
    }
    if (base > 0) _reward = await pr.reward(base);
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------------ رابط
  Widget _board() {
    final rk = _ranking;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 56, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: gPanel.withOpacity(.96), borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final i in rk)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(radius: 7, backgroundColor: GgPrefs.palette[cfg.players[i].col]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cfg.players[i].name, style: TextStyle(color: i == me ? gGold : Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  Text(sc[i].map((v) => v == 0 ? '·' : wFa(v)).join(' '), style: const TextStyle(color: gMuted, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text(wFa(sc[i].fold<int>(0, (a, b) => a + b)), style: const TextStyle(color: gTeal, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _overCard() {
    final rk = _ranking;
    final won = rk.first == me;
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(22), border: Border.all(color: gGold, width: 2)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(won ? '🏆 شما برنده شدید!' : 'نتیجه‌ی نهایی', style: const TextStyle(color: gGold, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (var r = 0; r < rk.length; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${wFa(r + 1)}.', style: const TextStyle(color: gMuted)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(cfg.players[rk[r]].name, style: TextStyle(color: rk[r] == me ? gGold : Colors.white, fontWeight: FontWeight.w800))),
                    Text('${wFa(_total(rk[r]))} ضربه', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
            if (_reward > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('+${wFa(_reward)} 🪙 سکه', style: const TextStyle(color: gTeal, fontSize: 16, fontWeight: FontWeight.w900))),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('خروج', style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = GgPrefs.gfThemes[pr.gfTheme];
    final hl = holes[min(hole, holes.length - 1)];
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: Color.lerp(th[2], Colors.black, .65),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: _up,
                  child: LayoutBuilder(builder: (c, cs) {
                    _size = Size(cs.maxWidth, cs.maxHeight);
                    return CustomPaint(painter: _GfPainter(this), size: Size.infinite);
                  }),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.of(context).maybePop()),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          'حفره ${wFa(hole + 1)} از ${wFa(holes.length)} · ${hl.name} · پار ${wFa(hl.par)} · ضربه ${wFa(strokes)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.leaderboard_rounded, color: _showBoard ? gGold : Colors.white70), onPressed: () => setState(() => _showBoard = !_showBoard)),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: gGold),
                      onPressed: () async {
                        await showGgSettings(context, 'golf');
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              if (_showBoard) Positioned(top: 0, left: 0, right: 0, child: _board()),
              if (_toast.isNotEmpty) Positioned(bottom: 60, left: 20, right: 20, child: IgnorePointer(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)), child: Text(_toast, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))))),
              if (done && phase == 'play')
                Positioned(bottom: 18, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)), child: Text(sunk ? '🎉 ${wFa(strokes)} ضربه — منتظر بقیه…' : 'منتظر بقیه…', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900))))),
              if (_netMsg.isNotEmpty) Positioned(bottom: 4, left: 0, right: 0, child: Center(child: Text(_netMsg, style: const TextStyle(color: gGold, fontSize: 12)))),
              if (phase == 'over') _overCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GfPainter extends CustomPainter {
  _GfPainter(this.s) : super(repaint: s.repaint);
  final _GgGolfPageState s;

  void _text(Canvas c, String t, Offset at, {double size = 11, Color col = Colors.white}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: col, fontSize: size, fontWeight: FontWeight.w900, shadows: const <Shadow>[Shadow(color: Colors.black87, blurRadius: 3)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final th = GgPrefs.gfThemes[s.pr.gfTheme];
    final hl = s.holes[min(s.hole, s.holes.length - 1)];
    final hq = s.pr.quality == 1;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 22);
    canvas.scale(s._sc);
    canvas.translate(-_W / 2, -_H / 2);

    final field = Rect.fromLTWH(0, 0, _W, _H);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(field, const Radius.circular(10)));
    // چمن شطرنجی
    const q = 40.0;
    final p1 = Paint()..color = th[0];
    final p2 = Paint()..color = th[1];
    for (var y = 0; y < (_H / q).ceil(); y++) {
      for (var x = 0; x < (_W / q).ceil(); x++) {
        canvas.drawRect(Rect.fromLTWH(x * q, y * q, q, q), (x + y) % 2 == 0 ? p1 : p2);
      }
    }
    // شن
    for (final r in hl.sand) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)), Paint()..color = const Color(0xffe8d08a));
      if (hq) {
        final dp = Paint()..color = const Color(0xffc9ae62);
        for (var i = 0; i < 26; i++) {
          canvas.drawCircle(Offset(r.left + ((i * 37) % 100) / 100 * r.width, r.top + ((i * 53) % 100) / 100 * r.height), 1.6, dp);
        }
      }
    }
    // آب
    for (final r in hl.water) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()..color = const Color(0xff2f9fe0));
      final wp = Paint()
        ..color = Colors.white.withOpacity(.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var k = 1; k < 4; k++) {
        final y = r.top + r.height * k / 4;
        final off = sin(s._t * 2 + k) * 6;
        canvas.drawLine(Offset(r.left + 10 + off, y), Offset(r.right - 10 + off, y), wp);
      }
    }
    // نقطه‌ی شروع
    canvas.drawCircle(hl.tee, 11, Paint()..color = Colors.white.withOpacity(.25));
    // حفره
    canvas.drawCircle(hl.cup + const Offset(0, 2), _cupR + 1, Paint()..color = Colors.black.withOpacity(.35));
    canvas.drawCircle(hl.cup, _cupR, Paint()..color = const Color(0xff111111));
    canvas.restore();

    // دیواره‌ها (سه‌بعدی‌نما: سایه، کناره، رویه)
    final wall = th[2];
    final wallDark = Color.lerp(wall, Colors.black, .35)!;
    final wallLight = Color.lerp(wall, Colors.white, .18)!;
    for (final r in hl.walls) {
      canvas.drawRect(r.shift(const Offset(5, 9)), Paint()..color = Colors.black.withOpacity(.28));
      canvas.drawRect(r.shift(const Offset(0, 8)), Paint()..color = wallDark);
      canvas.drawRect(r, Paint()..color = wallLight);
      canvas.drawRect(r.deflate(3), Paint()..color = wall);
    }
    // قاب بیرونی زمین
    canvas.drawRRect(RRect.fromRectAndRadius(field.inflate(5), const Radius.circular(14)), Paint()
      ..color = wallLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);
    // پره‌های چرخان
    for (final b in hl.bars) {
      final a = s._barPoint(b, -1), c = s._barPoint(b, 1);
      canvas.drawLine(a + const Offset(3, 6), c + const Offset(3, 6), Paint()..color = Colors.black.withOpacity(.3)..strokeWidth = 11..strokeCap = StrokeCap.round);
      canvas.drawLine(a, c, Paint()..color = wallDark..strokeWidth = 11..strokeCap = StrokeCap.round);
      canvas.drawLine(a, c, Paint()..color = wallLight..strokeWidth = 7..strokeCap = StrokeCap.round);
      canvas.drawCircle(b.pivot, 7, Paint()..color = wallDark);
    }
    // پرچم
    canvas.drawLine(hl.cup, hl.cup + const Offset(0, -46), Paint()..color = Colors.white..strokeWidth = 2.4);
    final flag = Path()
      ..moveTo(hl.cup.dx, hl.cup.dy - 46)
      ..lineTo(hl.cup.dx + 22, hl.cup.dy - 39)
      ..lineTo(hl.cup.dx, hl.cup.dy - 31)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xffe53b3b));

    // توپ‌های بقیه (روح)
    for (var i = 0; i < s.n; i++) {
      if (i == s.me) continue;
      final col = GgPrefs.palette[s.cfg.players[i].col];
      final c = Offset(s.ox[i], s.oy[i]);
      if (s.cfg.players[i].bot) continue;
      canvas.drawCircle(c, _br, Paint()..color = col.withOpacity(.6));
      canvas.drawCircle(c, _br, Paint()..color = Colors.white.withOpacity(.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      if (s.pr.gfNames) _text(canvas, s.cfg.players[i].name, c + const Offset(0, -10));
    }
    // خط هدف‌گیری
    if (s.aiming && s.pr.gfAim) {
      final pull = s._pull();
      if (pull.distance > 2) {
        final dir = pull / pull.distance;
        final len = (pull.distance / 110 * 150 * s._aimMul).clamp(0.0, 330.0).toDouble();
        final pp = Paint()..color = Colors.white.withOpacity(.9);
        for (var d = 14.0; d < len; d += 14) {
          canvas.drawCircle(Offset(s.bx, s.by) + dir * d, 2.6 - d / 330 * 1.3, pp);
        }
      }
      canvas.drawLine(Offset(s.bx, s.by), s.finger, Paint()..color = Colors.white.withOpacity(.35)..strokeWidth = 2);
    }
    if (s.aiming) {
      final k = min(s._pull().distance, 110.0) / 110;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(_W / 2 - 60, _H - 22, 120, 8), const Radius.circular(4)), Paint()..color = Colors.black54);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(_W / 2 - 60, _H - 22, 120 * k, 8), const Radius.circular(4)), Paint()..color = Color.lerp(const Color(0xff7dff4f), const Color(0xffff5d73), k)!);
    }
    // توپ من
    if (!s.sunk) {
      final bc = Offset(s.bx, s.by);
      final col = GgPrefs.palette[s.pr.gfBall];
      canvas.drawOval(Rect.fromCenter(center: bc + const Offset(2, 5), width: 16, height: 8), Paint()..color = Colors.black.withOpacity(.3));
      canvas.drawCircle(bc, _br, Paint()..color = col);
      canvas.drawCircle(bc + const Offset(-2, -2.5), 2.4, Paint()..color = Colors.white.withOpacity(.8));
      if (s.pr.gfNames) _text(canvas, s.cfg.players[s.me].name, bc + const Offset(0, -11), col: col);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GfPainter old) => true;
}
