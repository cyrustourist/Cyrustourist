import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'game_api.dart';
import 'game_engine.dart' show BotLevel;
import 'game_play_page.dart' show NearbyGameLink;
import 'game_texts.dart';

/// بازی‌های تاسی: «مار و پله» و «منچ» (با ربات یا دو نفره روی یک گوشی).
/// بدون اینترنت کار می‌کنند و نتیجه مثل بازی‌های آفلاین دیگر با [GameWallet.reportOffline] سکه می‌دهد.

enum DiceKind { snakes, ludo }

enum DiceMode { bot, local }

const Map<String, Map<String, String>> _dtx = {
  'roll': {'fa': 'تاس بینداز', 'en': 'Roll the dice'},
  'rolling': {'fa': 'در حال انداختن…', 'en': 'Rolling…'},
  'exact': {'fa': 'برای رسیدن به ۱۰۰ باید عدد دقیق بیاید', 'en': 'You need the exact number to reach 100'},
  'ladder': {'fa': 'نردبان! بالا رفتید', 'en': 'Ladder! Climb up'},
  'snake': {'fa': 'مار! پایین افتادید', 'en': 'Snake! Slide down'},
  'extra': {'fa': 'شش آمد؛ یک بار دیگر', 'en': 'A six — roll again'},
  'pick': {'fa': 'یک مهره را انتخاب کنید', 'en': 'Tap a piece to move'},
  'need_six': {'fa': 'برای بیرون آوردن مهره ۶ لازم است', 'en': 'You need a six to leave home'},
  'no_move': {'fa': 'حرکتی ممکن نیست', 'en': 'No move possible'},
  'captured': {'fa': 'مهره زده شد!', 'en': 'Captured!'},
  'start': {'fa': 'شروع', 'en': 'START'},
  'player_n': {'fa': 'بازیکن {n}', 'en': 'Player {n}'},
  'lu_host': {'fa': 'ساخت بازی (میزبان)', 'en': 'Host a game'},
  'lu_join': {'fa': 'پیوستن به بازی', 'en': 'Join a game'},
  'lu_join_short': {'fa': 'پیوستن · {n} نفر', 'en': 'Join · {n}'},
  'lu_players': {'fa': 'بازیکنان: {n} از ۴', 'en': 'Players: {n} of 4'},
  'lu_code': {'fa': 'کد بازی: {c}', 'en': 'Game code: {c}'},
  'lu_start': {'fa': 'شروع بازی', 'en': 'Start game'},
  'lu_needmin': {'fa': 'حداقل ۲ بازیکن لازم است', 'en': 'At least 2 players needed'},
  'lu_wait_host': {'fa': 'پیوستید. منتظر شروع بازی توسط میزبان…', 'en': 'Joined. Waiting for the host to start…'},
  'lu_none': {'fa': 'بازی‌ای در اطراف پیدا نشد.\nمیزبان باید «ساخت بازی» را بزند و همه نزدیک هم باشند.', 'en': 'No game found nearby.\nThe host must tap “Host a game”, and everyone must be close.'},
  'lu_lost': {'fa': 'ارتباط با میزبان قطع شد', 'en': 'Lost connection to the host'},
  'lu_note': {'fa': 'بدون اینترنت و بدون ورکر. همهٔ گوشی‌ها باید شبکهٔ آفلاین را روشن کنند و نزدیک هم باشند. تا ۴ نفر.', 'en': 'No internet needed. Everyone must turn on the offline network and stay close. Up to 4 players.'},
  'cell': {'fa': 'خانه {n}', 'en': 'Square {n}'},
  'snakes_rule': {
    'fa': 'تاس بریزید و به خانهٔ ۱۰۰ برسید. نردبان بالا می‌برد و مار پایین می‌آورد. برای رسیدن به ۱۰۰ عدد دقیق لازم است و ۶ یک بار دیگر تاس می‌دهد.',
    'en': 'Roll and reach square 100. Ladders lift you up, snakes slide you down. You need the exact number to finish, and a six gives another roll.'
  },
  'ludo_rule': {
    'fa': 'با ۶ مهره از خانه بیرون می‌آید. مهرهٔ حریف را بزنید تا به خانه برگردد (خانه‌های ستاره‌دار و شروع امن‌اند). هر ۴ مهره را زودتر به مرکز برسانید. ۶، زدن مهره و رسیدن به مرکز یک بار دیگر تاس می‌دهد.',
    'en': 'A six brings a piece out. Capture opponent pieces to send them home (star and start squares are safe). Be first to bring all 4 pieces to the centre. A six, a capture or reaching the centre gives another roll.'
  },
};

String _dt(String key, [Map<String, String>? p]) {
  final m = _dtx[key];
  var s = m == null ? key : (m[GameT.fa ? 'fa' : 'en'] ?? m['en'] ?? key);
  if (p != null) {
    p.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

// ---------------------------------------------------------------- ابزارهای مشترک

Widget _diceChip(String name, Color color, String sub, bool active) {
  return Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: gPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? gGold : gLine, width: active ? 2.2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: gMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _diceResultCard({
  required String title,
  required int gained,
  required VoidCallback onAgain,
  required VoidCallback onBack,
}) {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: gGold)),
    child: Column(
      children: [
        Text(title, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          gained > 0 ? '🪙 ${GameT.t('gained', <String, String>{'n': '$gained'})}' : GameT.t('no_reward'),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                onPressed: onAgain,
                child: Text(GameT.t('play_again'), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)),
                onPressed: onBack,
                child: Text(GameT.t('back')),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DiePainter extends CustomPainter {
  const _DiePainter(this.v);
  final int v;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.2));
    canvas.drawRRect(r, Paint()..color = Colors.white);
    final dot = Paint()..color = const Color(0xff111111);
    final a = s.width * 0.27;
    final b = s.width * 0.5;
    final c = s.width * 0.73;
    List<Offset> p;
    switch (v) {
      case 1:
        p = <Offset>[Offset(b, b)];
        break;
      case 2:
        p = <Offset>[Offset(a, a), Offset(c, c)];
        break;
      case 3:
        p = <Offset>[Offset(a, a), Offset(b, b), Offset(c, c)];
        break;
      case 4:
        p = <Offset>[Offset(a, a), Offset(c, a), Offset(a, c), Offset(c, c)];
        break;
      case 5:
        p = <Offset>[Offset(a, a), Offset(c, a), Offset(b, b), Offset(a, c), Offset(c, c)];
        break;
      default:
        p = <Offset>[Offset(a, a), Offset(c, a), Offset(a, b), Offset(c, b), Offset(a, c), Offset(c, c)];
    }
    for (final o in p) {
      canvas.drawCircle(o, s.width * 0.085, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) => old.v != v;
}

Widget _diceControls({
  required int die,
  required bool rolling,
  required bool enabled,
  required VoidCallback onRoll,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedScale(
        scale: rolling ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(width: 62, height: 62, child: CustomPaint(painter: _DiePainter(die))),
      ),
      const SizedBox(width: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: gGold,
          foregroundColor: gBg,
          disabledBackgroundColor: gLine,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
        onPressed: enabled ? onRoll : null,
        icon: const Icon(Icons.casino_rounded),
        label: Text(rolling ? _dt('rolling') : _dt('roll'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    ],
  );
}

Widget _tokenDot(Color color, double d, {bool glow = false}) {
  return Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: max(1.5, d * 0.09)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: glow ? gGold : Colors.black54,
          blurRadius: glow ? d * 0.7 : d * 0.25,
          spreadRadius: glow ? d * 0.12 : 0,
          offset: glow ? Offset.zero : Offset(0, d * 0.08),
        ),
      ],
    ),
  );
}

// ================================================================= مار و پله

const Map<int, int> _kJumps = <int, int>{
  1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100, // نردبان
  16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78, // مار
};

const List<Color> _snakePlayerColors = <Color>[Color(0xffff5a5f), Color(0xff4dabf7)];

/// مرکز خانهٔ n (۱ تا ۱۰۰) روی صفحهٔ ۱۰×۱۰ با واحد u.
Offset _snakeCellCenter(int n, double u) {
  final r = (n - 1) ~/ 10;
  final i = (n - 1) % 10;
  final col = r.isEven ? i : 9 - i;
  return Offset((col + 0.5) * u, (9 - r + 0.5) * u);
}

class SnakesPage extends StatefulWidget {
  const SnakesPage({super.key, required this.mode});
  final DiceMode mode;

  @override
  State<SnakesPage> createState() => _SnakesPageState();
}

class _SnakesPageState extends State<SnakesPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  final List<int> pos = <int>[0, 0];
  int turn = 0;
  int die = 1;
  bool rolling = false;
  bool busy = false;
  int winner = -1;
  String msg = '';
  int gained = 0;
  bool resultReady = false;
  int _gen = 0;

  bool get isBot => widget.mode == DiceMode.bot;
  bool get finished => winner >= 0;
  bool get humanTurn => !finished && !(isBot && turn == 1);

  List<String> get names => isBot
      ? <String>[GameT.t('you'), GameT.t('robot')]
      : <String>[GameT.t('player1'), GameT.t('player2')];

  void _restart() {
    _gen++;
    setState(() {
      pos[0] = 0;
      pos[1] = 0;
      turn = 0;
      die = 1;
      rolling = false;
      busy = false;
      winner = -1;
      msg = '';
      gained = 0;
      resultReady = false;
    });
  }

  Future<void> _roll() async {
    if (busy || finished) return;
    final gen = _gen;
    setState(() {
      busy = true;
      rolling = true;
      msg = '';
    });
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted || gen != _gen) return;
      setState(() => die = _rnd.nextInt(6) + 1);
    }
    final r = _rnd.nextInt(6) + 1;
    setState(() {
      die = r;
      rolling = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || gen != _gen) return;
    await _move(r, gen);
  }

  Future<void> _move(int r, int gen) async {
    final who = turn;
    var note = '';
    final target = pos[who] + r;
    if (target > 100) {
      note = _dt('exact');
    } else {
      setState(() => pos[who] = target);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || gen != _gen) return;
      final j = _kJumps[target];
      if (j != null) {
        note = j > target ? _dt('ladder') : _dt('snake');
        setState(() {
          pos[who] = j;
          msg = note;
        });
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted || gen != _gen) return;
      }
      if (pos[who] == 100) {
        setState(() {
          winner = who;
          busy = false;
        });
        _finish();
        return;
      }
    }
    final again = r == 6;
    if (again) note = note.isEmpty ? _dt('extra') : '$note · ${_dt('extra')}';
    setState(() {
      msg = note;
      if (!again) turn = 1 - turn;
      busy = false;
    });
    _maybeBot(gen);
  }

  void _maybeBot(int gen) {
    if (!isBot || turn != 1 || finished) return;
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || gen != _gen || finished || turn != 1 || busy) return;
      _roll();
    });
  }

  Future<void> _finish() async {
    final String result;
    final String level;
    if (isBot) {
      // مار و پله شانسی است؛ پاداش سطح «آسان» ثبت می‌شود
      result = winner == 0 ? 'win' : 'loss';
      level = 'easy';
    } else {
      result = 'win';
      level = 'local';
    }
    final g = await _w.reportOffline(result, level);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  String _statusText() {
    final n = names;
    if (finished) {
      if (isBot) return winner == 0 ? GameT.t('you_win') : GameT.t('you_lose');
      return GameT.t('wins', <String, String>{'n': n[winner]});
    }
    if (isBot) return turn == 0 ? GameT.t('your_turn') : GameT.t('opp_turn');
    return GameT.t('turn_of', <String, String>{'n': n[turn]});
  }

  Widget _token(int p, double u) {
    final n = pos[p];
    final dx = (p == 0 ? -0.17 : 0.17) * u;
    final Offset c;
    if (n <= 0) {
      c = Offset((0.7 + p * 0.7) * u, 10 * u + 0.45 * u);
    } else {
      final base = _snakeCellCenter(n, u);
      c = Offset(base.dx + dx, base.dy);
    }
    final d = u * 0.46;
    return AnimatedPositioned(
      key: ValueKey<int>(p),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      left: c.dx - d / 2,
      top: c.dy - d / 2,
      width: d,
      height: d,
      child: _tokenDot(_snakePlayerColors[p], d, glow: !finished && turn == p),
    );
  }

  Widget _board(double w) {
    final u = w / 10;
    return SizedBox(
      width: w,
      height: w + u * 0.9,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _SnakesPainter(_dt('start')))),
          ),
          _token(0, u),
          _token(1, u),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = names;
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GameT.t('snakes'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 24, 520.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Center(
                  child: SizedBox(
                    width: w,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _diceChip(n[0], _snakePlayerColors[0], pos[0] == 0 ? '' : _dt('cell', <String, String>{'n': '${pos[0]}'}), !finished && turn == 0),
                            const SizedBox(width: 10),
                            _diceChip(n[1], _snakePlayerColors[1], pos[1] == 0 ? '' : _dt('cell', <String, String>{'n': '${pos[1]}'}), !finished && turn == 1),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_statusText(), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(
                          height: 20,
                          child: Text(msg, style: const TextStyle(color: gSky, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 4),
                        _board(w),
                        const SizedBox(height: 14),
                        _diceControls(die: die, rolling: rolling, enabled: humanTurn && !busy, onRoll: _roll),
                        if (finished && resultReady)
                          _diceResultCard(
                            title: _statusText(),
                            gained: gained,
                            onAgain: _restart,
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        const SizedBox(height: 14),
                        Text(_dt('snakes_rule'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SnakesPainter extends CustomPainter {
  const _SnakesPainter(this.startLabel);
  final String startLabel;

  static const List<Color> _snakeColors = <Color>[
    Color(0xff2ecc71),
    Color(0xffe74c3c),
    Color(0xffb36bdc),
    Color(0xfff39c12),
    Color(0xff1abc9c),
    Color(0xffff6fa5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 10;
    final cell = Paint();
    for (var n = 1; n <= 100; n++) {
      final c = _snakeCellCenter(n, u);
      final r = (n - 1) ~/ 10;
      final i = (n - 1) % 10;
      final col = r.isEven ? i : 9 - i;
      cell.color = n == 100
          ? const Color(0xff8a6d1a)
          : ((r + col).isEven ? const Color(0xff12394f) : const Color(0xff0d2a3b));
      final rect = Rect.fromCenter(center: c, width: u, height: u);
      canvas.drawRect(rect, cell);
      final tp = TextPainter(
        text: TextSpan(text: n == 100 ? '🏁 100' : '$n', style: TextStyle(color: const Color(0x88ffffff), fontSize: u * 0.26)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.topLeft + Offset(u * 0.08, u * 0.04));
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, u * 10, u * 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = gLine
        ..strokeWidth = 2,
    );

    // نوار شروع
    final strip = RRect.fromRectAndRadius(Rect.fromLTWH(0, u * 10 + u * 0.08, u * 10, u * 0.8), Radius.circular(u * 0.25));
    canvas.drawRRect(strip, Paint()..color = const Color(0xff0f2f42));
    final st = TextPainter(
      text: TextSpan(text: startLabel, style: TextStyle(color: gMuted, fontSize: u * 0.3, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    st.paint(canvas, Offset(u * 3.0, u * 10 + u * 0.48 - st.height / 2));

    // نردبان‌ها و مارها
    var si = 0;
    _kJumps.forEach((from, to) {
      final a = _snakeCellCenter(from, u);
      final b = _snakeCellCenter(to, u);
      if (to > from) {
        _ladder(canvas, a, b, u);
      } else {
        _snake(canvas, a, b, u, _snakeColors[si % _snakeColors.length]);
        si++;
      }
    });
  }

  void _ladder(Canvas canvas, Offset a, Offset b, double u) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = -dy / len;
    final ny = dx / len;
    final w = u * 0.13;
    final rail = Paint()
      ..color = const Color(0xffd9a441)
      ..strokeWidth = u * 0.07
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = const Color(0xffb8842c)
      ..strokeWidth = u * 0.055
      ..strokeCap = StrokeCap.round;
    final off = Offset(nx * w, ny * w);
    canvas.drawLine(a + off, b + off, rail);
    canvas.drawLine(a - off, b - off, rail);
    final n = max(2, (len / (u * 0.38)).floor());
    for (var i = 1; i < n; i++) {
      final t = i / n;
      final p = Offset(a.dx + dx * t, a.dy + dy * t);
      canvas.drawLine(p + off, p - off, rung);
    }
  }

  void _snake(Canvas canvas, Offset a, Offset b, double u, Color color) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = -dy / len;
    final ny = dx / len;
    final waves = max(2, (len / (u * 1.6)).round()).toDouble();
    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final off = sin(t * pi * waves) * u * 0.2;
      final p = Offset(a.dx + dx * t + nx * off, a.dy + dy * t + ny * off);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = u * 0.2
        ..color = color,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = u * 0.07
        ..color = const Color(0x55ffffff),
    );
    canvas.drawCircle(a, u * 0.17, Paint()..color = color);
    final eye = Offset(nx * u * 0.07, ny * u * 0.07);
    canvas.drawCircle(a + eye, u * 0.045, Paint()..color = Colors.white);
    canvas.drawCircle(a - eye, u * 0.045, Paint()..color = Colors.white);
    canvas.drawCircle(a + eye, u * 0.02, Paint()..color = Colors.black);
    canvas.drawCircle(a - eye, u * 0.02, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _SnakesPainter old) => old.startLabel != startLabel;
}

// ================================================================= منچ

const Color _ludoRed = Color(0xffe53935);
const Color _ludoGreen = Color(0xff43a047);
const Color _ludoYellow = Color(0xfffdd835);
const Color _ludoBlue = Color(0xff1e88e5);
const List<Offset> _yardSlots = <Offset>[Offset(2, 2), Offset(4, 2), Offset(2, 4), Offset(4, 4)];
const List<Color> _ludoSeatColors = <Color>[_ludoRed, _ludoGreen, _ludoYellow, _ludoBlue];
const List<Offset> _yardOrigins = <Offset>[Offset(0, 0), Offset(9, 0), Offset(9, 9), Offset(0, 9)];

/// منطق منچ ۲ تا ۴ نفره. هر بازیکن یک «صندلی» رنگی دارد: ۰ قرمز، ۱ سبز، ۲ زرد، ۳ آبی (ساعتگرد).
/// پیشروی p: ۰ = در خانه، ۱..۵۱ = مسیر اصلی، ۵۲..۵۶ = ستون پایانی، ۵۷ = رسیده به مرکز.
class _Ludo {
  _Ludo._();

  static const Set<int> safe = <int>{0, 8, 13, 21, 26, 34, 39, 47};
  static final List<List<int>> track = _build();

  static List<List<int>> _build() {
    final t = <List<int>>[];
    for (var c = 1; c <= 5; c++) {
      t.add(<int>[6, c]);
    }
    for (var r = 5; r >= 0; r--) {
      t.add(<int>[r, 6]);
    }
    t.add(<int>[0, 7]);
    t.add(<int>[0, 8]);
    for (var r = 1; r <= 5; r++) {
      t.add(<int>[r, 8]);
    }
    for (var c = 9; c <= 14; c++) {
      t.add(<int>[6, c]);
    }
    t.add(<int>[7, 14]);
    t.add(<int>[8, 14]);
    for (var c = 13; c >= 9; c--) {
      t.add(<int>[8, c]);
    }
    for (var r = 9; r <= 14; r++) {
      t.add(<int>[r, 8]);
    }
    t.add(<int>[14, 7]);
    t.add(<int>[14, 6]);
    for (var r = 13; r >= 9; r--) {
      t.add(<int>[r, 6]);
    }
    for (var c = 5; c >= 0; c--) {
      t.add(<int>[8, c]);
    }
    t.add(<int>[7, 0]);
    t.add(<int>[6, 0]);
    return t;
  }

  /// خانهٔ مسیر اصلی برای مهره‌ای با پیشروی p از صندلی seat.
  static int trackIndex(int seat, int p) => (seat * 13 + p - 1) % 52;

  static List<int> legal(List<List<int>> t, int pl, int roll) {
    final out = <int>[];
    for (var i = 0; i < 4; i++) {
      final p = t[pl][i];
      if (p == 0) {
        if (roll == 6) out.add(i);
      } else if (p + roll <= 57) {
        out.add(i);
      }
    }
    return out;
  }

  /// مهره را حرکت می‌دهد (t تغییر می‌کند) و تعداد مهره‌های زده‌شده را برمی‌گرداند.
  static int move(List<List<int>> t, List<int> seats, int pl, int i, int roll) {
    final p = t[pl][i];
    final np = p == 0 ? 1 : p + roll;
    t[pl][i] = np;
    var captured = 0;
    if (np >= 1 && np <= 51) {
      final idx = trackIndex(seats[pl], np);
      if (!safe.contains(idx)) {
        for (var o = 0; o < t.length; o++) {
          if (o == pl) continue;
          for (var j = 0; j < 4; j++) {
            final q = t[o][j];
            if (q >= 1 && q <= 51 && trackIndex(seats[o], q) == idx) {
              t[o][j] = 0;
              captured++;
            }
          }
        }
      }
    }
    return captured;
  }

  static bool danger(List<List<int>> t, List<int> seats, int pl, int idx) {
    for (var o = 0; o < t.length; o++) {
      if (o == pl) continue;
      for (var j = 0; j < 4; j++) {
        final q = t[o][j];
        if (q < 1 || q > 51) continue;
        final d = (idx - trackIndex(seats[o], q) + 52) % 52;
        if (d >= 1 && d <= 6) return true;
      }
    }
    return false;
  }

  static int botPick(List<List<int>> t, List<int> seats, int pl, int roll, BotLevel level, Random rnd) {
    final opts = legal(t, pl, roll);
    if (opts.isEmpty) return -1;
    if (level == BotLevel.easy || opts.length == 1) return opts[rnd.nextInt(opts.length)];
    if (level == BotLevel.normal && rnd.nextInt(100) < 25) return opts[rnd.nextInt(opts.length)];
    var best = -1e9;
    var bestI = opts.first;
    for (final i in opts) {
      final p = t[pl][i];
      final copy = <List<int>>[for (final row in t) List<int>.from(row)];
      final cap = move(copy, seats, pl, i, roll);
      final np = copy[pl][i];
      var s = cap * 100.0 + roll + np * 0.1;
      if (np == 57) s += 80;
      if (p == 0) s += 45;
      if (p < 52 && np >= 52) s += 30;
      if (np >= 1 && np <= 51) {
        final idx = trackIndex(seats[pl], np);
        if (safe.contains(idx)) {
          s += 18;
        } else if (level == BotLevel.hard && danger(copy, seats, pl, idx)) {
          s -= 25;
        }
      }
      if (level == BotLevel.hard && p >= 1 && p <= 51) {
        final cur = trackIndex(seats[pl], p);
        if (!safe.contains(cur) && danger(t, seats, pl, cur)) s += 20;
      }
      s += rnd.nextDouble();
      if (s > best) {
        best = s;
        bestI = i;
      }
    }
    return bestI;
  }

  /// مرکز مهره روی صفحهٔ ۱۵×۱۵ (واحد خانه).
  static Offset unit(List<int> seats, int pl, int i, int p) {
    final c = seats[pl];
    if (p == 0) {
      final o = _yardOrigins[c];
      return Offset(o.dx + _yardSlots[i].dx, o.dy + _yardSlots[i].dy);
    }
    if (p <= 51) {
      final cell = track[trackIndex(c, p)];
      return Offset(cell[1] + 0.5, cell[0] + 0.5);
    }
    if (p <= 56) {
      final k = p - 51;
      switch (c) {
        case 0:
          return Offset(k + 0.5, 7.5);
        case 1:
          return Offset(7.5, k + 0.5);
        case 2:
          return Offset(14 - k + 0.5, 7.5);
        default:
          return Offset(7.5, 14 - k + 0.5);
      }
    }
    final f = (i - 1.5) * 0.3;
    switch (c) {
      case 0:
        return Offset(6.8, 7.5 + f);
      case 1:
        return Offset(7.5 + f, 6.8);
      case 2:
        return Offset(8.2, 7.5 + f);
      default:
        return Offset(7.5 + f, 8.2);
    }
  }
}


/// صندلی‌های رنگی برای ۲ تا ۴ بازیکن: ۲ نفره قرمز و زرد، بقیه ساعتگرد.
List<int> _ludoSeats(int n) {
  if (n >= 4) return <int>[0, 1, 2, 3];
  if (n == 3) return <int>[0, 1, 2];
  return <int>[0, 2];
}

Widget _ludoChips({
  required List<int> seats,
  required List<String> names,
  required List<int> home,
  required int turn,
  required bool over,
}) {
  Widget chip(int k) => _diceChip(names[k], _ludoSeatColors[seats[k]], '${home[k]}/4', !over && turn == k);
  const gap = SizedBox(width: 10);
  if (seats.length == 2) {
    return Row(children: <Widget>[chip(0), gap, chip(1)]);
  }
  if (seats.length == 3) {
    return Column(
      children: <Widget>[
        Row(children: <Widget>[chip(0), gap, chip(1)]),
        const SizedBox(height: 8),
        Row(children: <Widget>[chip(2), gap, const Expanded(child: SizedBox())]),
      ],
    );
  }
  return Column(
    children: <Widget>[
      Row(children: <Widget>[chip(0), gap, chip(1)]),
      const SizedBox(height: 8),
      Row(children: <Widget>[chip(3), gap, chip(2)]),
    ],
  );
}

/// صفحهٔ منچ با مهره‌ها. [movable] مهره‌های قابل انتخابِ بازیکنِ نوبت است (خالی = لمس غیرفعال).
Widget _buildLudoBoard({
  required double w,
  required List<int> seats,
  required List<List<int>> toks,
  required int turn,
  required List<int> movable,
  required void Function(int pl, int i) onTap,
}) {
  final u = w / 15;
  final count = seats.length * 4;
  final groups = <String, List<int>>{};
  final keys = List<String>.filled(count, '');
  for (var pl = 0; pl < seats.length; pl++) {
    for (var i = 0; i < 4; i++) {
      final p = toks[pl][i];
      String key;
      if (p >= 1 && p <= 51) {
        key = 't${_Ludo.trackIndex(seats[pl], p)}';
      } else if (p >= 52 && p <= 56) {
        key = 'h$pl-$p';
      } else {
        key = 'u$pl-$i';
      }
      keys[pl * 4 + i] = key;
      groups.putIfAbsent(key, () => <int>[]).add(pl * 4 + i);
    }
  }
  final children = <Widget>[
    Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: const _LudoPainter()))),
  ];
  for (var id = 0; id < count; id++) {
    final pl = id ~/ 4;
    final i = id % 4;
    final p = toks[pl][i];
    var c = _Ludo.unit(seats, pl, i, p);
    final grp = groups[keys[id]]!;
    if (grp.length > 1) {
      final a = 2 * pi * grp.indexOf(id) / grp.length;
      c = c + Offset(cos(a) * 0.2, sin(a) * 0.2);
    }
    final d = (p == 57 ? 0.42 : 0.62) * u;
    final hit = max(d, u * 1.1);
    final canTap = pl == turn && movable.contains(i);
    children.add(
      AnimatedPositioned(
        key: ValueKey<int>(id),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        left: c.dx * u - hit / 2,
        top: c.dy * u - hit / 2,
        width: hit,
        height: hit,
        child: IgnorePointer(
          ignoring: !canTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(pl, i),
            child: Center(child: _tokenDot(_ludoSeatColors[seats[pl]], d, glow: canTap)),
          ),
        ),
      ),
    );
  }
  return SizedBox(width: w, height: w, child: Stack(children: children));
}

class LudoPage extends StatefulWidget {
  const LudoPage({super.key, required this.mode, this.level = BotLevel.normal, this.players = 2});
  final DiceMode mode;
  final BotLevel level;

  /// ۲ (قرمز و زرد) یا ۴ بازیکن
  final int players;

  @override
  State<LudoPage> createState() => _LudoPageState();
}

class _LudoPageState extends State<LudoPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  late final List<int> seats = _ludoSeats(widget.players);
  late final List<List<int>> toks = <List<int>>[for (var i = 0; i < seats.length; i++) <int>[0, 0, 0, 0]];
  int turn = 0;
  int die = 1;
  bool rolling = false;
  bool busy = false;
  bool awaiting = false;
  int pendingRoll = 0;
  List<int> movable = <int>[];
  int yardTries = 0;
  int winner = -1;
  String msg = '';
  int gained = 0;
  bool resultReady = false;
  int _gen = 0;

  bool get isBot => widget.mode == DiceMode.bot;
  bool get finished => winner >= 0;
  bool isBotSeat(int pl) => isBot && pl != 0;
  bool get humanTurn => !finished && !isBotSeat(turn);

  List<String> get names {
    final n = seats.length;
    if (isBot) {
      return <String>[GameT.t('you'), for (var k = 1; k < n; k++) n == 2 ? GameT.t('robot') : '${GameT.t('robot')} $k'];
    }
    return <String>[for (var k = 1; k <= n; k++) _dt('player_n', <String, String>{'n': '$k'})];
  }

  int _home(int pl) => toks[pl].where((p) => p == 57).length;

  void _restart() {
    _gen++;
    setState(() {
      for (final row in toks) {
        for (var i = 0; i < 4; i++) {
          row[i] = 0;
        }
      }
      turn = 0;
      die = 1;
      rolling = false;
      busy = false;
      awaiting = false;
      pendingRoll = 0;
      movable = <int>[];
      yardTries = 0;
      winner = -1;
      msg = '';
      gained = 0;
      resultReady = false;
    });
  }

  Future<void> _roll() async {
    if (busy || awaiting || finished) return;
    final gen = _gen;
    setState(() {
      busy = true;
      rolling = true;
      msg = '';
    });
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted || gen != _gen) return;
      setState(() => die = _rnd.nextInt(6) + 1);
    }
    final r = _rnd.nextInt(6) + 1;
    setState(() {
      die = r;
      rolling = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || gen != _gen) return;
    await _afterRoll(r, gen);
  }

  Future<void> _afterRoll(int r, int gen) async {
    final opts = _Ludo.legal(toks, turn, r);
    if (opts.isEmpty) {
      final allYard = toks[turn].every((p) => p == 0);
      final again = allYard && yardTries < 2;
      setState(() => msg = allYard ? _dt('need_six') : _dt('no_move'));
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || gen != _gen) return;
      setState(() {
        if (again) {
          yardTries++;
        } else {
          yardTries = 0;
          turn = (turn + 1) % seats.length;
        }
        busy = false;
        msg = '';
      });
      _maybeBot(gen);
      return;
    }
    if (isBotSeat(turn)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || gen != _gen) return;
      final i = _Ludo.botPick(toks, seats, turn, r, widget.level, _rnd);
      await _doMove(i, r, gen);
      return;
    }
    if (opts.length == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || gen != _gen) return;
      await _doMove(opts.first, r, gen);
      return;
    }
    setState(() {
      awaiting = true;
      pendingRoll = r;
      movable = opts;
      msg = _dt('pick');
    });
  }

  void _onTokenTap(int pl, int i) {
    if (!awaiting || pl != turn || !movable.contains(i) || finished) return;
    final r = pendingRoll;
    final gen = _gen;
    setState(() {
      awaiting = false;
      movable = <int>[];
      msg = '';
    });
    _doMove(i, r, gen);
  }

  Future<void> _doMove(int i, int r, int gen) async {
    final who = turn;
    var cap = 0;
    setState(() {
      cap = _Ludo.move(toks, seats, who, i, r);
      msg = cap > 0 ? _dt('captured') : '';
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    if (_home(who) == 4) {
      setState(() {
        winner = who;
        busy = false;
      });
      _finish();
      return;
    }
    final extra = r == 6 || cap > 0 || toks[who][i] == 57;
    setState(() {
      if (!extra) turn = (turn + 1) % seats.length;
      yardTries = 0;
      busy = false;
      if (extra) msg = _dt('extra');
    });
    _maybeBot(gen);
  }

  void _maybeBot(int gen) {
    if (!isBotSeat(turn) || finished) return;
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || gen != _gen || finished || !isBotSeat(turn) || busy || awaiting) return;
      _roll();
    });
  }

  Future<void> _finish() async {
    final String result;
    final String level;
    if (isBot) {
      result = winner == 0 ? 'win' : 'loss';
      level = widget.level.name;
    } else {
      result = 'win';
      level = 'local';
    }
    final g = await _w.reportOffline(result, level);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  String _statusText() {
    final n = names;
    if (finished) {
      if (isBot) return winner == 0 ? GameT.t('you_win') : GameT.t('you_lose');
      return GameT.t('wins', <String, String>{'n': n[winner]});
    }
    if (isBot && turn == 0) return GameT.t('your_turn');
    if (isBot && seats.length == 2) return GameT.t('opp_turn');
    return GameT.t('turn_of', <String, String>{'n': n[turn]});
  }

  @override
  Widget build(BuildContext context) {
    final n = names;
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GameT.t('ludo'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 24, 520.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Center(
                  child: SizedBox(
                    width: w,
                    child: Column(
                      children: [
                        _ludoChips(seats: seats, names: n, home: <int>[for (var k = 0; k < seats.length; k++) _home(k)], turn: turn, over: finished),
                        const SizedBox(height: 10),
                        Text(_statusText(), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(
                          height: 20,
                          child: Text(msg, style: const TextStyle(color: gSky, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 4),
                        _buildLudoBoard(w: w, seats: seats, toks: toks, turn: turn, movable: awaiting ? movable : const <int>[], onTap: _onTokenTap),
                        const SizedBox(height: 14),
                        _diceControls(die: die, rolling: rolling, enabled: humanTurn && !busy && !awaiting, onRoll: _roll),
                        if (finished && resultReady)
                          _diceResultCard(
                            title: _statusText(),
                            gained: gained,
                            onAgain: _restart,
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        const SizedBox(height: 14),
                        Text(_dt('ludo_rule'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LudoPainter extends CustomPainter {
  const _LudoPainter();

  Color _light(Color c) => Color.lerp(c, Colors.white, 0.45) ?? c;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 15;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(u * 0.4)),
      Paint()..color = const Color(0xfff6efe2),
    );

    // چهار گوشه (خانه‌ها): بالا-چپ قرمز، بالا-راست سبز، پایین-راست زرد، پایین-چپ آبی
    const colors = <Color>[_ludoRed, _ludoGreen, _ludoYellow, _ludoBlue];
    const origins = <Offset>[Offset(0, 0), Offset(9, 0), Offset(9, 9), Offset(0, 9)];
    for (var k = 0; k < 4; k++) {
      final o = origins[k];
      canvas.drawRect(Rect.fromLTWH(o.dx * u, o.dy * u, 6 * u, 6 * u), Paint()..color = colors[k]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH((o.dx + 1) * u, (o.dy + 1) * u, 4 * u, 4 * u), Radius.circular(u * 0.5)),
        Paint()..color = const Color(0xfffffbf2),
      );
      for (final s in _yardSlots) {
        canvas.drawCircle(
          Offset((o.dx + s.dx) * u, (o.dy + s.dy) * u),
          u * 0.52,
          Paint()..color = _light(colors[k]),
        );
      }
    }

    // مسیر اصلی
    final fill = Paint()..color = const Color(0xfffffbf2);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (final cell in _Ludo.track) {
      final rect = Rect.fromLTWH(cell[1] * u, cell[0] * u, u, u);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }

    // ستون‌های پایانی
    final homeCols = <Color, List<List<int>>>{
      _ludoRed: <List<int>>[for (var c = 1; c <= 5; c++) <int>[7, c]],
      _ludoGreen: <List<int>>[for (var r = 1; r <= 5; r++) <int>[r, 7]],
      _ludoYellow: <List<int>>[for (var c = 9; c <= 13; c++) <int>[7, c]],
      _ludoBlue: <List<int>>[for (var r = 9; r <= 13; r++) <int>[r, 7]],
    };
    homeCols.forEach((color, cells) {
      for (final cell in cells) {
        final rect = Rect.fromLTWH(cell[1] * u, cell[0] * u, u, u);
        canvas.drawRect(rect, Paint()..color = color);
        canvas.drawRect(rect, border);
      }
    });

    // خانه‌های شروع (رنگی) و خانه‌های امن (ستاره)
    const starts = <int, Color>{0: _ludoRed, 13: _ludoGreen, 26: _ludoYellow, 39: _ludoBlue};
    starts.forEach((idx, color) {
      final cell = _Ludo.track[idx];
      final rect = Rect.fromLTWH(cell[1] * u, cell[0] * u, u, u);
      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(rect, border);
    });
    for (final idx in _Ludo.safe) {
      if (starts.containsKey(idx)) continue;
      final cell = _Ludo.track[idx];
      final tp = TextPainter(
        text: TextSpan(text: '★', style: TextStyle(color: const Color(0xff9a8f7a), fontSize: u * 0.75)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((cell[1] + 0.5) * u - tp.width / 2, (cell[0] + 0.5) * u - tp.height / 2));
    }

    // مرکز: چهار مثلث رنگی
    final mid = Offset(7.5 * u, 7.5 * u);
    void tri(Offset a, Offset b, Color c) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(mid.dx, mid.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    tri(Offset(6 * u, 6 * u), Offset(6 * u, 9 * u), _ludoRed);
    tri(Offset(6 * u, 6 * u), Offset(9 * u, 6 * u), _ludoGreen);
    tri(Offset(9 * u, 6 * u), Offset(9 * u, 9 * u), _ludoYellow);
    tri(Offset(6 * u, 9 * u), Offset(9 * u, 9 * u), _ludoBlue);
  }

  @override
  bool shouldRepaint(covariant _LudoPainter old) => false;
}

// ================================================================= منچ جمعی (گوشی‌های نزدیک، بدون اینترنت)

class _OpenRoom {
  _OpenRoom(this.code, this.hostUid, this.hostName, this.count, this.ts);
  final String code;
  final String hostUid;
  final String hostName;
  int count;
  int ts;
}

/// منچ ۲ تا ۴ نفره بین چند گوشی نزدیک (Nearby، بدون اینترنت). یک گوشی «میزبان» است؛
/// قوانین و تاس فقط روی میزبان اجرا می‌شود و وضعیت بازی به بقیه فرستاده می‌شود.
/// اگر بازیکنی از برد خارج شود، میزبان نوبت او را خودکار بازی می‌کند.
class LudoNearbyPage extends StatefulWidget {
  const LudoNearbyPage({super.key});

  @override
  State<LudoNearbyPage> createState() => _LudoNearbyPageState();
}

class _LudoNearbyPageState extends State<LudoNearbyPage> {
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _tick;
  bool _starting = false;

  // لابی
  String stage = 'menu'; // menu | host | join | play
  bool isHost = false;
  bool joined = false;
  String code = '';
  String hostUid = '';
  final List<String> ids = <String>[];
  final List<String> pnames = <String>[];
  final Map<String, _OpenRoom> rooms = <String, _OpenRoom>{};

  // بازی
  List<int> seats = <int>[0, 2];
  List<List<int>> toks = <List<int>>[];
  int turn = 0;
  int die = 1;
  String ph = 'roll'; // roll | rolling | shown | pick | over
  List<int> movable = <int>[];
  String msgKey = '';
  int winner = -1;
  int seq = 0;
  int yardTries = 0;
  bool busy = false;
  int gained = 0;
  bool reported = false;
  bool resultReady = false;
  bool lost = false;
  int _gen = 0;
  int _lastSnap = 0;

  int get me => ids.indexOf(_mesh.myUid);

  @override
  void initState() {
    super.initState();
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
    _mesh.addListener(_onMesh);
    _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
  }

  @override
  void dispose() {
    _gen++;
    if (stage == 'join' && joined && code.isNotEmpty) {
      _send(<String, dynamic>{'g': 'lu_leave', 'to': hostUid, 'code': code});
    }
    _tick?.cancel();
    _sub?.cancel();
    _mesh.removeListener(_onMesh);
    NearbyGameLink.instance.detach();
    super.dispose();
  }

  void _send(Map<String, dynamic> m) => NearbyGameLink.instance.send(m);

  void _onMesh() {
    if (!mounted) return;
    setState(() {});
    if (stage == 'play' && isHost) _maybeAuto();
  }

  void _onTick() {
    if (!mounted || !_mesh.running) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (stage == 'host') {
      _send(<String, dynamic>{'g': 'lu_open', 'code': code, 'cnt': ids.length});
    } else if (stage == 'join') {
      rooms.removeWhere((k, v) => now - v.ts > 7000);
      if (code.isNotEmpty && !joined) {
        _send(<String, dynamic>{'g': 'lu_join', 'to': hostUid, 'code': code});
      }
      setState(() {});
    } else if (stage == 'play') {
      if (isHost) {
        _send(_snap());
      } else if (!lost && now - _lastSnap > 15000 && ph != 'over') {
        setState(() => lost = true);
      }
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
    if (!ok) gToast(context, GameT.t('nearby_perm'));
  }

  // ---------------------------------------------------------------- پیام‌ها

  void _onEvent(Map<String, dynamic> m) {
    if (!mounted) return;
    final g = '${m['g']}';
    if (!g.startsWith('lu_')) return;
    final from = '${m['u']}';
    final fromName = '${m['n']}';
    final toMe = '${m['to']}' == _mesh.myUid;
    switch (g) {
      case 'lu_open':
        if (stage == 'join') {
          final c = '${m['code']}';
          setState(() {
            rooms[c] = _OpenRoom(c, from, fromName, (m['cnt'] as num?)?.toInt() ?? 1, DateTime.now().millisecondsSinceEpoch);
          });
        }
        break;
      case 'lu_join':
        if (stage == 'host' && toMe && '${m['code']}' == code && !ids.contains(from) && ids.length < 4) {
          setState(() {
            ids.add(from);
            pnames.add(fromName);
          });
          _sendRoster();
        } else if (stage == 'host' && toMe && ids.contains(from)) {
          _sendRoster();
        }
        break;
      case 'lu_leave':
        if (stage == 'host' && toMe && '${m['code']}' == code && ids.contains(from) && from != _mesh.myUid) {
          final k = ids.indexOf(from);
          setState(() {
            ids.removeAt(k);
            pnames.removeAt(k);
          });
          _sendRoster();
        }
        break;
      case 'lu_ros':
        if (stage == 'join' && '${m['code']}' == code) {
          final l = (m['ids'] as List<dynamic>).map((e) => '$e').toList();
          final n = (m['names'] as List<dynamic>).map((e) => '$e').toList();
          if (l.contains(_mesh.myUid)) {
            setState(() {
              ids
                ..clear()
                ..addAll(l);
              pnames
                ..clear()
                ..addAll(n);
              joined = true;
            });
          }
        }
        break;
      case 'lu_s':
        if (!isHost && '${m['code']}' == code && (stage == 'join' || stage == 'play')) _applySnap(m);
        break;
      case 'lu_roll':
        if (isHost && stage == 'play' && toMe && '${m['code']}' == code && turn < ids.length && ids[turn] == from) {
          _hostRoll(turn);
        }
        break;
      case 'lu_pick':
        if (isHost && stage == 'play' && toMe && '${m['code']}' == code && turn < ids.length && ids[turn] == from) {
          _hostPick((m['i'] as num?)?.toInt() ?? -1);
        }
        break;
    }
  }

  void _sendRoster() {
    _send(<String, dynamic>{'g': 'lu_ros', 'code': code, 'ids': ids, 'names': pnames});
  }

  Map<String, dynamic> _snap() => <String, dynamic>{
        'g': 'lu_s',
        'code': code,
        'ids': ids,
        'names': pnames,
        'seats': seats,
        'toks': toks,
        'turn': turn,
        'die': die,
        'ph': ph,
        'mov': movable,
        'msg': msgKey,
        'win': winner,
        'seq': seq,
      };

  void _push() {
    seq++;
    _send(_snap());
    if (mounted) setState(() {});
  }

  void _applySnap(Map<String, dynamic> m) {
    final sq = (m['seq'] as num?)?.toInt() ?? 0;
    if (stage == 'play' && sq <= seq) {
      _lastSnap = DateTime.now().millisecondsSinceEpoch;
      return;
    }
    final l = (m['ids'] as List<dynamic>).map((e) => '$e').toList();
    if (!l.contains(_mesh.myUid)) return;
    setState(() {
      seq = sq;
      stage = 'play';
      lost = false;
      _lastSnap = DateTime.now().millisecondsSinceEpoch;
      ids
        ..clear()
        ..addAll(l);
      pnames
        ..clear()
        ..addAll((m['names'] as List<dynamic>).map((e) => '$e'));
      seats = (m['seats'] as List<dynamic>).map((e) => (e as num).toInt()).toList();
      toks = <List<int>>[
        for (final r in (m['toks'] as List<dynamic>)) <int>[for (final x in (r as List<dynamic>)) (x as num).toInt()],
      ];
      turn = (m['turn'] as num).toInt();
      die = (m['die'] as num).toInt();
      ph = '${m['ph']}';
      movable = (m['mov'] as List<dynamic>).map((e) => (e as num).toInt()).toList();
      msgKey = '${m['msg']}';
      winner = (m['win'] as num).toInt();
    });
    if (winner >= 0) _report();
  }

  // ---------------------------------------------------------------- میزبان

  void _createGame() {
    if (!_mesh.running) return;
    code = '${1000 + _rnd.nextInt(9000)}';
    isHost = true;
    joined = true;
    ids
      ..clear()
      ..add(_mesh.myUid);
    pnames
      ..clear()
      ..add(_mesh.myName);
    setState(() => stage = 'host');
    _send(<String, dynamic>{'g': 'lu_open', 'code': code, 'cnt': 1});
  }

  void _openJoin() {
    isHost = false;
    joined = false;
    code = '';
    ids.clear();
    pnames.clear();
    setState(() => stage = 'join');
  }

  void _joinRoom(_OpenRoom r) {
    setState(() {
      code = r.code;
      hostUid = r.hostUid;
      joined = false;
    });
    _send(<String, dynamic>{'g': 'lu_join', 'to': hostUid, 'code': code});
  }

  void _hostStart() {
    if (ids.length < 2) return;
    _gen++;
    seats = _ludoSeats(ids.length);
    toks = <List<int>>[for (var i = 0; i < seats.length; i++) <int>[0, 0, 0, 0]];
    turn = 0;
    die = 1;
    ph = 'roll';
    movable = <int>[];
    msgKey = '';
    winner = -1;
    yardTries = 0;
    busy = false;
    reported = false;
    resultReady = false;
    stage = 'play';
    _lastSnap = DateTime.now().millisecondsSinceEpoch;
    _push();
    _maybeAuto();
  }

  bool _gone(int pl) => pl != 0 && !_mesh.peers.values.any((p) => p.uid == ids[pl]);

  void _maybeAuto() {
    if (!isHost || stage != 'play' || winner >= 0 || busy || ph != 'roll' || turn >= ids.length) return;
    if (!_gone(turn)) return;
    final gen = _gen;
    final pl = turn;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || gen != _gen) return;
      _hostRoll(pl);
    });
  }

  Future<void> _hostRoll(int pl) async {
    if (!isHost || busy || ph != 'roll' || turn != pl || winner >= 0) return;
    final gen = _gen;
    busy = true;
    ph = 'rolling';
    msgKey = '';
    _push();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || gen != _gen) return;
    final r = _rnd.nextInt(6) + 1;
    die = r;
    final opts = _Ludo.legal(toks, turn, r);
    if (opts.isEmpty) {
      final allYard = toks[turn].every((p) => p == 0);
      final again = allYard && yardTries < 2;
      msgKey = allYard ? 'need_six' : 'no_move';
      ph = 'shown';
      _push();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || gen != _gen) return;
      if (again) {
        yardTries++;
      } else {
        yardTries = 0;
        turn = (turn + 1) % seats.length;
      }
      ph = 'roll';
      msgKey = '';
      busy = false;
      _push();
      _maybeAuto();
      return;
    }
    if (_gone(turn)) {
      ph = 'shown';
      _push();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted || gen != _gen) return;
      final i = _Ludo.botPick(toks, seats, turn, r, BotLevel.normal, _rnd);
      await _hostMove(i, r, gen);
      return;
    }
    if (opts.length == 1) {
      ph = 'shown';
      _push();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || gen != _gen) return;
      await _hostMove(opts.first, r, gen);
      return;
    }
    ph = 'pick';
    movable = opts;
    msgKey = 'pick';
    busy = false;
    _push();
  }

  void _hostPick(int i) {
    if (!isHost || ph != 'pick' || !movable.contains(i)) return;
    final gen = _gen;
    ph = 'shown';
    movable = <int>[];
    msgKey = '';
    busy = true;
    _hostMove(i, die, gen);
  }

  Future<void> _hostMove(int i, int r, int gen) async {
    final who = turn;
    final cap = _Ludo.move(toks, seats, who, i, r);
    msgKey = cap > 0 ? 'captured' : '';
    ph = 'shown';
    _push();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    if (toks[who].every((p) => p == 57)) {
      winner = who;
      ph = 'over';
      busy = false;
      _push();
      _report();
      return;
    }
    final extra = r == 6 || cap > 0 || toks[who][i] == 57;
    if (!extra) turn = (turn + 1) % seats.length;
    yardTries = 0;
    ph = 'roll';
    msgKey = extra ? 'extra' : '';
    busy = false;
    _push();
    _maybeAuto();
  }

  // ---------------------------------------------------------------- بازیکن

  void _myRoll() {
    if (ph != 'roll' || turn != me) return;
    if (isHost) {
      _hostRoll(me);
    } else {
      _send(<String, dynamic>{'g': 'lu_roll', 'to': hostUid, 'code': code});
    }
  }

  void _myPick(int pl, int i) {
    if (ph != 'pick' || turn != me || pl != me || !movable.contains(i)) return;
    if (isHost) {
      _hostPick(i);
    } else {
      _send(<String, dynamic>{'g': 'lu_pick', 'to': hostUid, 'code': code, 'i': i});
    }
  }

  Future<void> _report() async {
    if (reported) return;
    reported = true;
    final g = await _w.reportOffline(winner == me ? 'win' : 'loss', 'nearby');
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  // ---------------------------------------------------------------- رابط

  String _status() {
    if (winner >= 0) return winner == me ? GameT.t('you_win') : GameT.t('wins', <String, String>{'n': pnames[winner]});
    if (turn == me) return GameT.t('your_turn');
    return GameT.t('turn_of', <String, String>{'n': pnames[turn]});
  }

  Widget _netCard() {
    final on = _mesh.running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: on ? gPanel : gGold,
          foregroundColor: on ? gGold : gBg,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _toggleNet,
        icon: _starting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
        label: Text(
          on ? '${GameT.t('nearby_stop')} · ${_mesh.peers.length}' : GameT.t('nearby_start'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _bigButton(IconData icon, String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: gGold,
          foregroundColor: gBg,
          disabledBackgroundColor: gLine,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _row(String name, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
      child: Row(
        children: [
          const Icon(Icons.phone_android_rounded, color: gTeal),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _menuBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        if (_mesh.running) ...[
          _bigButton(Icons.add_circle_rounded, _dt('lu_host'), _createGame),
          _bigButton(Icons.login_rounded, _dt('lu_join'), _openJoin),
        ],
        const SizedBox(height: 10),
        Text(_dt('lu_note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12, height: 1.8)),
      ],
    );
  }

  Widget _hostBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        Text(_dt('lu_players', <String, String>{'n': '${ids.length}'}), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 8),
        for (final n in pnames) _row(n),
        const SizedBox(height: 6),
        Text(_dt('lu_code', <String, String>{'c': code}), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _bigButton(Icons.play_arrow_rounded, ids.length < 2 ? _dt('lu_needmin') : _dt('lu_start'), ids.length < 2 ? null : _hostStart),
      ],
    );
  }

  Widget _joinBody() {
    final list = rooms.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        if (code.isNotEmpty && joined) ...[
          Text(_dt('lu_wait_host'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.8)),
          const SizedBox(height: 10),
          for (final n in pnames) _row(n),
        ] else ...[
          if (list.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(_dt('lu_none'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9))),
          for (final r in list)
            _row(
              r.hostName,
              trailing: code == r.code
                  ? Text(GameT.t('nearby_wait'), style: const TextStyle(color: gMuted, fontSize: 12))
                  : FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                      onPressed: () => _joinRoom(r),
                      child: Text(_dt('lu_join_short', <String, String>{'n': '${r.count}'}), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
            ),
        ],
      ],
    );
  }

  Widget _playBody(double w) {
    final canRoll = ph == 'roll' && turn == me && winner < 0 && !lost;
    final pickable = ph == 'pick' && turn == me && !lost ? movable : const <int>[];
    final shownDie = ph == 'rolling' ? 1 + (DateTime.now().millisecond ~/ 170) % 6 : die;
    return Column(
      children: [
        _ludoChips(
          seats: seats,
          names: pnames,
          home: <int>[for (var k = 0; k < seats.length; k++) toks[k].where((p) => p == 57).length],
          turn: turn,
          over: winner >= 0,
        ),
        const SizedBox(height: 10),
        Text(_status(), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
        SizedBox(
          height: 20,
          child: Text(lost ? _dt('lu_lost') : (msgKey.isEmpty ? '' : _dt(msgKey)), style: const TextStyle(color: gSky, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        _buildLudoBoard(w: w, seats: seats, toks: toks, turn: turn, movable: pickable, onTap: _myPick),
        const SizedBox(height: 14),
        _diceControls(die: shownDie, rolling: ph == 'rolling', enabled: canRoll, onRoll: _myRoll),
        if (winner >= 0 && resultReady)
          _diceResultCard(
            title: _status(),
            gained: gained,
            onAgain: () => Navigator.of(context).pop(),
            onBack: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (stage) {
      case 'host':
        body = _hostBody();
        break;
      case 'join':
        body = _joinBody();
        break;
      case 'play':
        body = const SizedBox.shrink();
        break;
      default:
        body = _menuBody();
    }
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text('${GameT.t('ludo')} · ${GameT.t('nearby_title')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 24, 520.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: Center(
                  child: SizedBox(
                    width: w,
                    child: stage == 'play' ? _playBody(w) : body,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
