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

/// هاکی روی میز (نئونی)؛ ۱ نفر با ربات یا ۲ تا ۴ نفر با گوشی‌های اطراف.
/// فیزیک فقط روی گوشی میزبان حساب می‌شود و وضعیت ۲۰ بار در ثانیه برای بقیه می‌رود.
/// هر بازیکن یک ضلع را دفاع می‌کند؛ هر گل خورده یک جان کم می‌کند و آخرین بازیکنِ زنده برنده است.
class GgHockeyPage extends StatefulWidget {
  const GgHockeyPage({super.key, required this.cfg, this.net, this.me = 0});
  final GgConfig cfg;
  final GgNet? net;
  final int me;

  @override
  State<GgHockeyPage> createState() => _GgHockeyPageState();
}

class _Fx {
  _Fx(this.p, this.c);
  final Offset p;
  final Color c;
  double t = 0;
}

class _GgHockeyPageState extends State<GgHockeyPage> with SingleTickerProviderStateMixin {
  final GgPrefs pr = GgPrefs.instance;
  final Random _rnd = Random();
  late final Ticker _ticker;
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  GgConfig get cfg => widget.cfg;
  GgNet? get net => widget.net;
  int get n => cfg.players.length;
  bool get isHost => net == null || net!.isHost;
  int get me => widget.me < 0 ? 0 : widget.me;

  // ---- میز
  late final double W;
  late final double H;
  late final double gap;
  static const double puckR = 15;
  late final List<int> sides; // اندیس بازیکن → ضلع (0 پایین، 1 چپ، 2 بالا، 3 راست)
  final List<int> sideOwner = <int>[-1, -1, -1, -1];

  // ---- وضعیت
  double px = 0, py = 0, pvx = 0, pvy = 0;
  late List<double> mx, my, mtx, mty, mvx, mvy, mr, pw;
  late List<int> lives;
  late List<bool> alive;
  late List<bool> botCtl;
  String phase = 'start';
  double phaseT = 2.2;
  int winner = -1;
  int lastConceded = -1;
  final List<Offset> trail = <Offset>[];
  final List<_Fx> fx = <_Fx>[];
  Duration _prev = Duration.zero;
  double _sendT = 0;
  double _inT = 0;
  bool _overHandled = false;
  int _reward = 0;
  Size _size = const Size(360, 640);
  String _netMsg = '';

  double get _maxV => <double>[800, 1000, 1250][pr.hkSpeed];

  @override
  void initState() {
    super.initState();
    pr.load();
    if (n == 2) {
      W = 360;
      H = 600;
      gap = 150;
      sides = <int>[0, 2];
    } else {
      W = 500;
      H = 500;
      gap = 170;
      sides = <int>[0, 1, 2, 3].sublist(0, n);
    }
    _initState();
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
        if (pi >= 0 && isHost) botCtl[pi] = !c || cfg.players[pi].bot;
      };
    }
    _ticker = createTicker(_onTick)..start();
  }

  void _initState() {
    mx = List<double>.filled(n, 0);
    my = List<double>.filled(n, 0);
    mtx = List<double>.filled(n, 0);
    mty = List<double>.filled(n, 0);
    mvx = List<double>.filled(n, 0);
    mvy = List<double>.filled(n, 0);
    mr = List<double>.filled(n, 28);
    pw = List<double>.filled(n, 1);
    lives = List<int>.filled(n, cfg.lives);
    alive = List<bool>.filled(n, true);
    botCtl = List<bool>.generate(n, (i) => cfg.players[i].bot);
    for (var i = 0; i < 4; i++) {
      sideOwner[i] = -1;
    }
    for (var i = 0; i < n; i++) {
      sideOwner[sides[i]] = i;
    }
    if (cfg.solo) {
      mr[me] = 28 * (1 + .06 * pr.lvl('hk_size'));
      pw[me] = 1 + .1 * pr.lvl('hk_power');
    }
    for (var i = 0; i < n; i++) {
      final h = _home(i);
      mx[i] = mtx[i] = h.dx;
      my[i] = mty[i] = h.dy;
    }
    px = W / 2;
    py = H / 2;
    pvx = pvy = 0;
    phase = 'start';
    phaseT = 2.2;
    winner = -1;
    _overHandled = false;
    _reward = 0;
    trail.clear();
  }

  @override
  void dispose() {
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

  // ------------------------------------------------------------------ هندسه
  Offset _home(int i) {
    final r = mr[i];
    switch (sides[i]) {
      case 0:
        return Offset(W / 2, H - r - 30);
      case 1:
        return Offset(r + 30, H / 2);
      case 2:
        return Offset(W / 2, r + 30);
      default:
        return Offset(W - r - 30, H / 2);
    }
  }

  Rect _zone(int i) {
    final r = mr[i];
    if (n == 2) {
      return sides[i] == 0 ? Rect.fromLTRB(r, H * .56, W - r, H - r) : Rect.fromLTRB(r, r, W - r, H * .44);
    }
    switch (sides[i]) {
      case 0:
        return Rect.fromLTRB(W * .2, H * .7, W * .8, H - r);
      case 1:
        return Rect.fromLTRB(r, H * .2, W * .3, H * .8);
      case 2:
        return Rect.fromLTRB(W * .2, r, W * .8, H * .3);
      default:
        return Rect.fromLTRB(W * .7, H * .2, W - r, H * .8);
    }
  }

  Offset _wallDir(int i) {
    switch (sides[i]) {
      case 0:
        return const Offset(0, 1);
      case 1:
        return const Offset(-1, 0);
      case 2:
        return const Offset(0, -1);
      default:
        return const Offset(1, 0);
    }
  }

  double get _sc => max(.1, min((_size.width - 20) / W, (_size.height - 160) / H));
  Offset get _ctr => Offset(_size.width / 2, _size.height / 2 + 24);
  double get _ang => -sides[me] * pi / 2;

  Offset toLogical(Offset s) {
    final v = (s - _ctr) / _sc;
    final a = -_ang;
    final c = cos(a), sn = sin(a);
    return Offset(v.dx * c - v.dy * sn, v.dx * sn + v.dy * c) + Offset(W / 2, H / 2);
  }

  // ------------------------------------------------------------------ حلقه‌ی بازی
  void _onTick(Duration el) {
    var dt = (el - _prev).inMicroseconds / 1e6;
    _prev = el;
    if (dt <= 0) return;
    if (dt > .033) dt = .033;
    for (final f in fx) {
      f.t += dt;
    }
    fx.removeWhere((f) => f.t > .6);
    if (isHost) {
      _hostStep(dt);
      _sendT += dt;
      if (net != null && _sendT >= .05) {
        _sendT = 0;
        _broadcast();
      }
    } else {
      _clientStep(dt);
    }
    trail.add(Offset(px, py));
    if (trail.length > 9) trail.removeAt(0);
    repaint.value++;
  }

  void _moveMallet(int i, double dt, double cap) {
    final z = _zone(i);
    final tx = mtx[i].clamp(z.left, z.right).toDouble();
    final ty = mty[i].clamp(z.top, z.bottom).toDouble();
    var dx = tx - mx[i], dy = ty - my[i];
    final d = sqrt(dx * dx + dy * dy);
    final lim = cap * dt;
    if (d > lim && d > 0) {
      dx = dx / d * lim;
      dy = dy / d * lim;
    }
    mvx[i] = dx / dt;
    mvy[i] = dy / dt;
    mx[i] += dx;
    my[i] += dy;
  }

  void _hostStep(double dt) {
    if (phase == 'over') return;
    if (phase == 'start' || phase == 'goal') {
      phaseT -= dt;
      for (var i = 0; i < n; i++) {
        if (alive[i]) _moveMallet(i, dt, 2400);
      }
      if (phaseT <= 0) {
        phase = 'play';
        _serve();
      }
      return;
    }
    for (var i = 0; i < n; i++) {
      if (!alive[i]) continue;
      if (botCtl[i]) _botThink(i);
      _moveMallet(i, dt, botCtl[i] ? <double>[420, 700, 1100][cfg.level.clamp(0, 2)] : 2400);
    }
    const sub = 3;
    final h = dt / sub;
    for (var k = 0; k < sub; k++) {
      _puckStep(h);
      if (phase != 'play') break;
    }
    final f = max(0.0, 1 - .22 * dt);
    pvx *= f;
    pvy *= f;
  }

  void _serve() {
    px = W / 2;
    py = H / 2;
    pvx = pvy = 0;
    if (lastConceded >= 0 && alive[lastConceded]) {
      final d = _wallDir(lastConceded);
      pvx = d.dx * 170;
      pvy = d.dy * 170;
    } else {
      final a = _rnd.nextDouble() * 2 * pi;
      pvx = cos(a) * 150;
      pvy = sin(a) * 150;
    }
  }

  void _puckStep(double h) {
    px += pvx * h;
    py += pvy * h;
    for (var s = 0; s < 4; s++) {
      if (_wall(s)) return;
    }
    for (var i = 0; i < n; i++) {
      if (!alive[i]) continue;
      final dx = px - mx[i], dy = py - my[i];
      final d = sqrt(dx * dx + dy * dy);
      final minD = puckR + mr[i];
      if (d < minD && d > .001) {
        final nx = dx / d, ny = dy / d;
        px = mx[i] + nx * minD;
        py = my[i] + ny * minD;
        final rvx = pvx - mvx[i] * pw[i], rvy = pvy - mvy[i] * pw[i];
        final vn = rvx * nx + rvy * ny;
        if (vn < 0) {
          final j = -(1 + .85) * vn;
          pvx += j * nx;
          pvy += j * ny;
          if (j > 120) {
            GgSfx.play('hit');
            GgSfx.buzz();
            if (pr.hkFx) fx.add(_Fx(Offset(px, py), GgPrefs.palette[cfg.players[i].col]));
          }
        }
        final sp = sqrt(pvx * pvx + pvy * pvy);
        if (sp > _maxV) {
          pvx = pvx / sp * _maxV;
          pvy = pvy / sp * _maxV;
        }
      }
    }
  }

  /// برخورد با یک ضلع؛ اگر گل شد true برمی‌گرداند.
  bool _wall(int s) {
    double a, d, va, vd, len;
    switch (s) {
      case 0:
        a = px;
        d = H - py;
        va = pvx;
        vd = -pvy;
        len = W;
        break;
      case 2:
        a = px;
        d = py;
        va = pvx;
        vd = pvy;
        len = W;
        break;
      case 1:
        a = py;
        d = px;
        va = pvy;
        vd = pvx;
        len = H;
        break;
      default:
        a = py;
        d = W - px;
        va = pvy;
        vd = -pvx;
        len = H;
    }
    final owner = sideOwner[s];
    final goal = owner >= 0 && alive[owner];
    final cen = len / 2;
    final inGap = goal && (a - cen).abs() < gap / 2;
    if (inGap && d < -puckR) {
      _scored(owner);
      return true;
    }
    if (goal) {
      for (final post in <double>[cen - gap / 2, cen + gap / 2]) {
        final da = a - post;
        final dist = sqrt(da * da + d * d);
        if (dist < puckR + 7 && dist > .001) {
          final nx = da / dist, ny = d / dist;
          a = post + nx * (puckR + 7);
          d = ny * (puckR + 7);
          final vn = va * nx + vd * ny;
          if (vn < 0) {
            va -= 1.9 * vn * nx;
            vd -= 1.9 * vn * ny;
          }
        }
      }
    }
    if (d < puckR && !inGap) {
      d = puckR;
      if (vd < 0) {
        vd = -vd * .92;
        GgSfx.play('wall');
      }
    }
    switch (s) {
      case 0:
        px = a;
        py = H - d;
        pvx = va;
        pvy = -vd;
        break;
      case 2:
        px = a;
        py = d;
        pvx = va;
        pvy = vd;
        break;
      case 1:
        py = a;
        px = d;
        pvy = va;
        pvx = vd;
        break;
      default:
        py = a;
        px = W - d;
        pvy = va;
        pvx = -vd;
    }
    return false;
  }

  void _scored(int owner) {
    lives[owner]--;
    lastConceded = owner;
    GgSfx.play('goal');
    GgSfx.buzz();
    if (pr.hkFx) fx.add(_Fx(Offset(px.clamp(0, W).toDouble(), py.clamp(0, H).toDouble()), GgPrefs.hkThemes[pr.hkTheme][sides[owner] + 1]));
    if (lives[owner] <= 0) alive[owner] = false;
    final left = <int>[for (var i = 0; i < n; i++) if (alive[i]) i];
    px = W / 2;
    py = H / 2;
    pvx = pvy = 0;
    if (left.length <= 1) {
      phase = 'over';
      winner = left.isEmpty ? -1 : left.first;
      _broadcast();
      _onOver();
    } else {
      phase = 'goal';
      phaseT = 1.4;
      _broadcast();
    }
  }

  void _botThink(int i) {
    final lv = cfg.level.clamp(0, 2);
    final z = _zone(i);
    final wd = _wallDir(i);
    final puck = Offset(px, py);
    final m = Offset(mx[i], my[i]);
    final zi = z.inflate(36);
    Offset t;
    if (zi.contains(puck)) {
      final behind = puck + wd * (puckR + mr[i] + 12);
      final back = (m - puck).dx * wd.dx + (m - puck).dy * wd.dy;
      final lateral = ((m - puck).dx * wd.dy - (m - puck).dy * wd.dx).abs();
      t = (back > (puckR + mr[i]) * .6 && lateral < mr[i] * .8) ? puck - wd * 14 : behind;
    } else {
      final h = _home(i);
      final off = wd.dx.abs() > 0 ? (py - H / 2) : (px - W / 2);
      final k = (off * .5).clamp(-gap * .45, gap * .45).toDouble();
      t = wd.dx.abs() > 0 ? Offset(h.dx, H / 2 + k) : Offset(W / 2 + k, h.dy);
    }
    final noise = (2 - lv) * 7.0;
    mtx[i] = t.dx + (_rnd.nextDouble() - .5) * noise;
    mty[i] = t.dy + (_rnd.nextDouble() - .5) * noise;
  }

  // ------------------------------------------------------------------ مهمان
  void _clientStep(double dt) {
    px += pvx * dt;
    py += pvy * dt;
    px = px.clamp(-40, W + 40).toDouble();
    py = py.clamp(-40, H + 40).toDouble();
    if (phase != 'over') {
      for (var i = 0; i < n; i++) {
        if (!alive[i]) continue;
        if (i == me) {
          _moveMallet(i, dt, 2400);
        } else {
          mx[i] += (mtx[i] - mx[i]) * .4;
          my[i] += (mty[i] - my[i]) * .4;
        }
      }
    }
  }

  double _r1(double v) => (v * 10).round() / 10;

  void _broadcast() {
    final nt = net;
    if (nt == null || !nt.isHost) return;
    nt.hostSend(<String, dynamic>{
      'k': 'st',
      'p': <double>[_r1(px), _r1(py), _r1(pvx), _r1(pvy)],
      'm': <double>[for (var i = 0; i < n; i++) ...<double>[_r1(mx[i]), _r1(my[i])]],
      'l': lives,
      'ph': phase,
      't': _r1(phaseT),
      'w': winner,
    });
  }

  void _onNetGame(int seat, Map<String, dynamic> m) {
    if (m['k'] == 'in' && isHost) {
      final pi = _playerOfSeat(seat);
      if (pi >= 0 && !botCtl[pi]) {
        mtx[pi] = (m['x'] as num).toDouble();
        mty[pi] = (m['y'] as num).toDouble();
      }
    } else if (m['k'] == 'st' && !isHost) {
      final p = m['p'] as List;
      final nx = (p[0] as num).toDouble(), ny = (p[1] as num).toDouble();
      if ((nx - px).abs() + (ny - py).abs() > 60) {
        px = nx;
        py = ny;
      } else {
        px += (nx - px) * .6;
        py += (ny - py) * .6;
      }
      pvx = (p[2] as num).toDouble();
      pvy = (p[3] as num).toDouble();
      final mm = m['m'] as List;
      for (var i = 0; i < n && i * 2 + 1 < mm.length; i++) {
        if (i == me) continue;
        mtx[i] = (mm[i * 2] as num).toDouble();
        mty[i] = (mm[i * 2 + 1] as num).toDouble();
      }
      final l = m['l'] as List;
      final oldPhase = phase;
      for (var i = 0; i < n && i < l.length; i++) {
        final nl = (l[i] as num).toInt();
        if (nl < lives[i]) {
          GgSfx.play('goal');
          fx.add(_Fx(Offset(px.clamp(0, W).toDouble(), py.clamp(0, H).toDouble()), GgPrefs.hkThemes[pr.hkTheme][sides[i] + 1]));
        }
        lives[i] = nl;
        alive[i] = nl > 0;
      }
      phase = '${m['ph']}';
      phaseT = (m['t'] as num).toDouble();
      winner = (m['w'] as num).toInt();
      if (phase == 'over' && oldPhase != 'over') _onOver();
      if (mounted && oldPhase != phase) setState(() {});
    }
  }

  Future<void> _onOver() async {
    if (_overHandled) return;
    _overHandled = true;
    final won = winner == me;
    GgSfx.play(won ? 'win' : 'lose');
    var base = 0;
    if (cfg.solo) {
      base = won ? <int>[20, 35, 50][cfg.level.clamp(0, 2)] : 0;
    } else {
      base = won ? 50 : 5;
    }
    if (base > 0) _reward = await pr.reward(base);
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------------ ورودی
  void _ptr(PointerEvent e) {
    if (phase == 'over') return;
    final l = toLogical(e.localPosition);
    mtx[me] = l.dx;
    mty[me] = l.dy;
    final nt = net;
    if (nt != null && !nt.isHost) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _inT.toInt() > 35) {
        _inT = now.toDouble();
        final z = _zone(me);
        nt.clientSend(<String, dynamic>{'k': 'in', 'x': _r1(l.dx.clamp(z.left, z.right).toDouble()), 'y': _r1(l.dy.clamp(z.top, z.bottom).toDouble())});
      }
    }
  }

  void _again() {
    setState(_initState);
  }

  // ------------------------------------------------------------------ رابط
  String get _banner {
    if (phase == 'start') return 'آماده باشید…';
    if (phase == 'goal') return 'گل!';
    return '';
  }

  Widget _hud() {
    final th = GgPrefs.hkThemes[pr.hkTheme];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < n; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: alive[i] ? th[sides[i] + 1] : Colors.white24, width: i == me ? 2 : 1),
                    ),
                    child: Text(
                      '${cfg.players[i].name}  ${'♥' * max(0, lives[i])}',
                      style: TextStyle(color: alive[i] ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.tune_rounded, color: gGold), onPressed: () async {
            await showGgSettings(context, 'hockey');
            if (mounted) setState(() {});
          }),
        ],
      ),
    );
  }

  Widget _overCard() {
    final won = winner == me;
    final wn = winner >= 0 ? cfg.players[winner].name : '—';
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(22), border: Border.all(color: gGold, width: 2)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(won ? '🏆 شما برنده شدید!' : 'برنده: $wn', textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (_reward > 0) Text('+${wFa(_reward)} 🪙 سکه', style: const TextStyle(color: gTeal, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            if (cfg.solo) SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg), onPressed: _again, child: const Text('بازی دوباره', style: TextStyle(fontWeight: FontWeight.w900)))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('خروج', style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = GgPrefs.hkThemes[pr.hkTheme];
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: th[0],
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _ptr,
                  onPointerMove: _ptr,
                  child: LayoutBuilder(builder: (c, cs) {
                    _size = Size(cs.maxWidth, cs.maxHeight);
                    return CustomPaint(painter: _HkPainter(this), size: Size.infinite);
                  }),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: _hud()),
              if (_banner.isNotEmpty)
                Center(child: IgnorePointer(child: Text(_banner, style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, shadows: <Shadow>[Shadow(color: th[1], blurRadius: 20)])))),
              if (_netMsg.isNotEmpty) Positioned(bottom: 10, left: 0, right: 0, child: Center(child: Text(_netMsg, style: const TextStyle(color: gGold)))),
              if (phase == 'over') _overCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HkPainter extends CustomPainter {
  _HkPainter(this.s) : super(repaint: s.repaint);
  final _GgHockeyPageState s;

  Paint _glow(Color c, double w, double blur) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

  void _seg(Canvas c, Offset a, Offset b, Color col, bool hq) {
    if (hq) c.drawLine(a, b, _glow(col.withOpacity(.55), 12, 7));
    c.drawLine(a, b, _glow(Colors.white, 4, 0));
    c.drawLine(a, b, _glow(col, 6, 0)..color = col.withOpacity(.9));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final th = GgPrefs.hkThemes[s.pr.hkTheme];
    final hq = s.pr.quality == 1;
    final W = s.W, H = s.H, gap = s.gap;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 24);
    canvas.rotate(s._ang);
    canvas.scale(s._sc);
    canvas.translate(-W / 2, -H / 2);

    // زمینه
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..color = Color.alphaBlend(Colors.white.withOpacity(.03), th[0]));
    // خط وسط و دایره‌ی وسط
    final line = Paint()
      ..color = Colors.white.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(W / 2, H / 2), min(W, H) * .12, line);
    if (s.n == 2) canvas.drawLine(Offset(0, H / 2), Offset(W, H / 2), line);
    // نیم‌دایره‌ی دروازه‌ها
    for (var side = 0; side < 4; side++) {
      final o = s.sideOwner[side];
      if (o < 0 || !s.alive[o]) continue;
      final c = switch (side) { 0 => Offset(W / 2, H), 1 => Offset(0, H / 2), 2 => Offset(W / 2, 0), _ => Offset(W, H / 2) };
      canvas.drawCircle(c, gap / 2 + 12, line);
    }
    // دیواره‌ها
    for (var side = 0; side < 4; side++) {
      final o = s.sideOwner[side];
      final goal = o >= 0 && s.alive[o];
      final col = (o >= 0 && !s.alive[o]) ? const Color(0xff667788) : th[side + 1];
      final horiz = side == 0 || side == 2;
      final len = horiz ? W : H;
      Offset pt(double a) => switch (side) { 0 => Offset(a, H), 2 => Offset(a, 0), 1 => Offset(0, a), _ => Offset(W, a) };
      if (goal) {
        _seg(canvas, pt(0), pt(len / 2 - gap / 2), col, hq);
        _seg(canvas, pt(len / 2 + gap / 2), pt(len), col, hq);
      } else {
        _seg(canvas, pt(0), pt(len), col, hq);
      }
    }
    // دنباله‌ی توپ
    final puckCol = GgPrefs.palette[s.pr.hkPuck];
    if (s.pr.hkTrail) {
      for (var i = 0; i < s.trail.length; i++) {
        final k = (i + 1) / s.trail.length;
        canvas.drawCircle(s.trail[i], GgHockeyRadius.puck * k * .8, Paint()..color = puckCol.withOpacity(.22 * k));
      }
    }
    // دسته‌ها
    for (var i = 0; i < s.n; i++) {
      if (!s.alive[i]) continue;
      final col = GgPrefs.palette[s.cfg.players[i].col];
      final c = Offset(s.mx[i], s.my[i]);
      final r = s.mr[i];
      if (hq) canvas.drawCircle(c, r + 4, Paint()..color = col.withOpacity(.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      canvas.drawCircle(c, r, Paint()..color = Colors.white);
      canvas.drawCircle(c, r * .62, Paint()..color = col);
      canvas.drawCircle(c, r * .3, Paint()..color = Colors.black.withOpacity(.35));
      if (i == s.me) canvas.drawCircle(c, r + 3, Paint()..color = Colors.white.withOpacity(.8)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    // توپ
    final pc = Offset(s.px, s.py);
    if (hq) canvas.drawCircle(pc, GgHockeyRadius.puck + 4, Paint()..color = puckCol.withOpacity(.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(pc, GgHockeyRadius.puck, Paint()..color = puckCol);
    canvas.drawCircle(pc, GgHockeyRadius.puck * .45, Paint()..color = Colors.white.withOpacity(.85));
    // افکت‌ها
    for (final f in s.fx) {
      final k = f.t / .6;
      canvas.drawCircle(f.p, 12 + 70 * k, Paint()..color = f.c.withOpacity((1 - k) * .8)..style = PaintingStyle.stroke..strokeWidth = 4);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HkPainter old) => true;
}

class GgHockeyRadius {
  static const double puck = 15;
}
