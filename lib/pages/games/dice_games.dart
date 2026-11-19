import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'game_api.dart';
import 'game_engine.dart' show BotLevel;
import 'game_play_page.dart' show NearbyGameLink;
import 'dice_picker.dart' show showDicePicker;
import 'dice_skins.dart';
import 'game_fx.dart';
import 'game_widgets.dart';
import 'game_texts.dart';
import 'game_skins.dart';

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
  const _DiePainter(this.v, [this.skin]);
  final int v;
  final DiceSkin? skin;

  static List<Offset> _pips(int v, double w) {
    final a = w * 0.28;
    final b = w * 0.5;
    final c = w * 0.72;
    switch (v) {
      case 1:
        return <Offset>[Offset(b, b)];
      case 2:
        return <Offset>[Offset(a, a), Offset(c, c)];
      case 3:
        return <Offset>[Offset(a, a), Offset(b, b), Offset(c, c)];
      case 4:
        return <Offset>[Offset(a, a), Offset(c, a), Offset(a, c), Offset(c, c)];
      case 5:
        return <Offset>[Offset(a, a), Offset(c, a), Offset(b, b), Offset(a, c), Offset(c, c)];
      default:
        return <Offset>[Offset(a, a), Offset(c, a), Offset(a, b), Offset(c, b), Offset(a, c), Offset(c, c)];
    }
  }

  void _pip(Canvas canvas, Offset o, double r, DiceSkin sk) {
    final paint = Paint()..color = sk.pip;
    if (sk.glow) {
      canvas.drawCircle(o, r * 1.7, Paint()
        ..color = sk.pip.withAlpha(120)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9));
    }
    switch (sk.pipShape) {
      case PipShape.ring:
        canvas.drawCircle(
            o,
            r * 0.82,
            Paint()
              ..color = sk.pip
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.5);
        break;
      case PipShape.square:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: r * 1.8, height: r * 1.8), Radius.circular(r * 0.38)), paint);
        break;
      case PipShape.diamond:
        final path = Path()
          ..moveTo(o.dx, o.dy - r * 1.25)
          ..lineTo(o.dx + r * 1.05, o.dy)
          ..lineTo(o.dx, o.dy + r * 1.25)
          ..lineTo(o.dx - r * 1.05, o.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case PipShape.circle:
        canvas.drawCircle(o, r, paint);
        canvas.drawCircle(o - Offset(r * 0.25, r * 0.25), r * 0.3, Paint()..color = const Color(0x44ffffff));
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final sk = skin ?? DiceSkins.skin;
    final w = s.width;
    final rect = Offset.zero & s;
    final rr = RRect.fromRectAndRadius(rect.deflate(w * 0.04), Radius.circular(w * 0.22));
    canvas.drawRRect(rr.shift(Offset(0, w * 0.05)), Paint()..color = const Color(0x66000000));
    if (sk.glow) {
      canvas.drawRRect(
          rr.inflate(w * 0.02),
          Paint()
            ..color = sk.edge.withAlpha(150)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.1));
    }
    final isGlass = sk.style == DiceStyle.glass;
    final c1 = isGlass ? const Color(0xbbffffff) : (Color.lerp(sk.face, Colors.white, 0.28) ?? sk.face);
    final c2 = sk.face2 == null || isGlass ? sk.face : (Color.lerp(sk.face, sk.face2, 0.5) ?? sk.face);
    final c3 = isGlass ? sk.face.withAlpha(0x55) : (Color.lerp(sk.face2 ?? sk.face, Colors.black, 0.22) ?? sk.face);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[c1, c2, c3],
          stops: const <double>[0, 0.55, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(rr);
    switch (sk.style) {
      case DiceStyle.glossy:
      case DiceStyle.glass:
        final gl = Rect.fromLTWH(w * 0.10, w * 0.07, w * 0.62, w * 0.30);
        canvas.drawOval(
            gl,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x77ffffff), Color(0x00ffffff)],
              ).createShader(gl));
        break;
      case DiceStyle.wood:
        final g = Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018;
        for (var i = 1; i < 7; i++) {
          final y = w * i / 7;
          final path = Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(w * 0.5, y + (i.isEven ? w * 0.05 : -w * 0.05), w, y);
          canvas.drawPath(path, g);
        }
        break;
      case DiceStyle.gem:
        final lt = Paint()..color = const Color(0x2effffff);
        final dk = Paint()..color = const Color(0x28000000);
        final m = w / 2;
        canvas.drawPath(Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(m, m)..close(), lt);
        canvas.drawPath(Path()..moveTo(0, 0)..lineTo(0, w)..lineTo(m, m)..close(), lt);
        canvas.drawPath(Path()..moveTo(w, 0)..lineTo(w, w)..lineTo(m, m)..close(), dk);
        canvas.drawPath(Path()..moveTo(0, w)..lineTo(w, w)..lineTo(m, m)..close(), dk);
        break;
      case DiceStyle.neon:
        canvas.drawRRect(
            rr.deflate(w * 0.07),
            Paint()
              ..color = sk.edge.withAlpha(70)
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * 0.015);
        break;
      case DiceStyle.classic:
        break;
    }
    canvas.restore();
    if (sk.glow) {
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.06
            ..color = sk.edge.withAlpha(160)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04));
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..color = sk.edge,
    );
    for (final o in _pips(v, w)) {
      _pip(canvas, o, w * 0.088, sk);
    }
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) => true;
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
        scale: rolling ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[if (enabled) const BoxShadow(color: Color(0x88ffd23f), blurRadius: 18, spreadRadius: 1)],
          ),
          child: ValueListenableBuilder<String>(
            valueListenable: DiceSkins.current,
            builder: (_, __, ___) => CustomPaint(painter: _DiePainter(die)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Builder(
        builder: (ctx) => InkWell(
          onTap: () => showDicePicker(ctx),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: gPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gLine),
            ),
            child: const Icon(Icons.palette_rounded, color: gGold),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: gGold,
            foregroundColor: gBg,
            disabledBackgroundColor: gLine,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onPressed: enabled ? onRoll : null,
          icon: const Icon(Icons.casino_rounded),
          label: Text(
            rolling ? _dt('rolling') : _dt('roll'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    SkinStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

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
    GameFx.roll();
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
      GameFx.move();
      setState(() => pos[who] = target);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || gen != _gen) return;
      final j = _kJumps[target];
      if (j != null) {
        note = j > target ? _dt('ladder') : _dt('snake');
        if (j > target) {
          GameFx.move();
        } else {
          GameFx.hit();
        }
        setState(() {
          pos[who] = j;
          msg = note;
        });
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted || gen != _gen) return;
      }
      if (pos[who] == 100) {
        GameFx.win();
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
          actions: [skinAction(() => showSkinSheet(context, game: 'snakes', title: 'طرح صفحه مار و پله', names: <String>[for (final k in kSnakesSkins) k.name], prices: <int>[for (final k in kSnakesSkins) k.price], preview: snakesPreview, onChanged: () => setState(() {}))), gameFxAction(() => setState(() {}))],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 8, 600.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
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
                        if (isBot) BotChatBox(botName: GameT.t('robot')),
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
  _SnakesPainter(this.startLabel) : skin = kSnakesSkins[SkinStore.idx('snakes', kSnakesSkins.length)];
  final String startLabel;
  final SnakesSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 10;
    final bgRect = Offset.zero & Size(size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, Radius.circular(u * 0.25)), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[skin.frameA, skin.frameB]).createShader(bgRect));
    final cell = Paint();
    for (var n = 1; n <= 100; n++) {
      final c = _snakeCellCenter(n, u);
      final r = (n - 1) ~/ 10;
      final i = (n - 1) % 10;
      final col = r.isEven ? i : 9 - i;
      cell.color = n == 100 ? skin.finish : ((r + col).isEven ? skin.cellA : skin.cellB);
      final rect = Rect.fromCenter(center: c, width: u, height: u);
      canvas.drawRect(rect, cell);
      if (skin.motif == 1 && n != 100) {
        final d = Path()
          ..moveTo(c.dx, c.dy - u * 0.2)
          ..lineTo(c.dx + u * 0.14, c.dy)
          ..lineTo(c.dx, c.dy + u * 0.2)
          ..lineTo(c.dx - u * 0.14, c.dy)
          ..close();
        canvas.drawPath(d, Paint()..color = const Color(0x22ffffff));
      } else if (skin.motif == 2 && n != 100) {
        canvas.drawCircle(c + Offset(u * 0.18, u * 0.18), u * 0.07, Paint()..color = const Color(0x33ffffff));
      }
      final tp = TextPainter(
        text: TextSpan(text: n == 100 ? '🏁 100' : '$n', style: TextStyle(color: skin.num, fontSize: u * 0.26)),
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
    canvas.drawRRect(strip, Paint()..color = skin.frameA);
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
        _snake(canvas, a, b, u, skin.snakes[si % skin.snakes.length]);
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
      ..color = skin.rail
      ..strokeWidth = u * 0.07
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = skin.rung
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
  bool shouldRepaint(covariant _SnakesPainter old) => old.startLabel != startLabel || old.skin != skin;
}

// ================================================================= منچ

const Color _ludoRed = Color(0xffe8453c);
const Color _ludoGreen = Color(0xff3fae49);
const Color _ludoYellow = Color(0xfff6c445);
const Color _ludoBlue = Color(0xff2f8fe8);
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


/// مهرهٔ براق منچ
Widget _pawn(Color c, double d, {bool glow = false}) {
  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;
  return Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: <Color>[mix(c, Colors.white, 0.6), c, mix(c, Colors.black, 0.38)],
        stops: const <double>[0, 0.55, 1],
      ),
      border: Border.all(color: mix(c, Colors.black, 0.5), width: max(1.2, d * 0.07)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: glow ? gGold : const Color(0x99000000),
          blurRadius: glow ? d * 0.9 : d * 0.3,
          spreadRadius: glow ? d * 0.18 : 0,
          offset: glow ? Offset.zero : Offset(0, d * 0.13),
        ),
      ],
    ),
    child: Center(
      child: Container(width: d * 0.34, height: d * 0.34, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x40ffffff))),
    ),
  );
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
    Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _LudoPainter(activeSeat: seats[turn])))),
  ];
  for (var id = 0; id < count; id++) {
    final pl = id ~/ 4;
    final i = id % 4;
    final p = toks[pl][i];
    var c = _Ludo.unit(seats, pl, i, p);
    final grp = groups[keys[id]]!;
    if (grp.length > 1) {
      final a = 2 * pi * grp.indexOf(id) / grp.length;
      c = c + Offset(cos(a) * 0.24, sin(a) * 0.24);
    }
    final d = (p == 57 ? 0.5 : 0.88) * u;
    final hit = max(d, u * 1.15);
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
            child: Center(child: _pawn(_ludoSeatColors[seats[pl]], d, glow: canTap)),
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
  @override
  void initState() {
    super.initState();
    SkinStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

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
    GameFx.roll();
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
    if (cap > 0) {
      GameFx.hit();
    } else {
      GameFx.move();
    }
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    if (_home(who) == 4) {
      GameFx.win();
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
          actions: [skinAction(() => showSkinSheet(context, game: 'ludo', title: 'طرح صفحه منچ', names: <String>[for (final k in kLudoSkins) k.name], prices: <int>[for (final k in kLudoSkins) k.price], preview: ludoPreview, onChanged: () => setState(() {}))), gameFxAction(() => setState(() {}))],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 8, 640.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
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
                        if (isBot) BotChatBox(botName: GameT.t('robot')),
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
  _LudoPainter({required this.activeSeat}) : skin = kLudoSkins[SkinStore.idx('ludo', kLudoSkins.length)];
  final int activeSeat;
  final LudoSkin skin;

  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  /// یک «حفره» روی تخته (مثل تختهٔ چوبی کنده‌کاری‌شده)
  void _hole(Canvas canvas, Offset o, double r, {Color? ring, Color? tint, bool star = false}) {
    final tn = tint ?? skin.hole;
    canvas.drawCircle(o + Offset(0, r * 0.14), r * 1.05, Paint()..color = const Color(0x66ffffff));
    final rect = Rect.fromCircle(center: o, radius: r);
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.45),
          colors: <Color>[_mix(tn, Colors.white, 0.16), _mix(tn, Colors.black, 0.34)],
        ).createShader(rect),
    );
    if (ring != null) {
      canvas.drawCircle(
        o,
        r * 0.84,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.28
          ..color = ring,
      );
    }
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13
        ..color = const Color(0x77000000),
    );
    if (star) {
      final tp = TextPainter(
        text: TextSpan(text: '★', style: TextStyle(color: const Color(0xff7a3b22), fontSize: r * 1.25)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 15;
    final full = Offset.zero & size;

    // قاب چوبی
    canvas.drawRRect(
      RRect.fromRectAndRadius(full, Radius.circular(u * 0.6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[skin.frameA, skin.frameB],
        ).createShader(full),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(full.deflate(u * 0.18), Radius.circular(u * 0.45)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.07
        ..color = skin.rim.withAlpha(204),
    );

    // چهار خانهٔ رنگی گوشه‌ها
    for (var k = 0; k < 4; k++) {
      final c = _ludoSeatColors[k];
      final o = _yardOrigins[k];
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx * u + 0.45 * u, o.dy * u + 0.45 * u, 5.1 * u, 5.1 * u), Radius.circular(u * 0.9));
      if (k == activeSeat) {
        canvas.drawRRect(
          rr,
          Paint()
            ..color = c.withAlpha(190)
            ..maskFilter = MaskFilter.blur(BlurStyle.outer, u * 0.7),
        );
      }
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_mix(c, Colors.white, 0.18), _mix(c, Colors.black, 0.4)],
          ).createShader(rr.outerRect),
      );
      final mid = Offset((o.dx + 3) * u, (o.dy + 3) * u);
      canvas.drawCircle(mid, 2.15 * u, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(
        mid,
        2.15 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.08
          ..color = const Color(0x55ffffff),
      );
      for (final sl in _yardSlots) {
        _hole(canvas, Offset((o.dx + sl.dx) * u, (o.dy + sl.dy) * u), u * 0.62, ring: _mix(c, Colors.white, 0.25), tint: _mix(c, Colors.black, 0.55));
      }
    }

    // صلیب چوبی روشن
    final plate = Path.combine(
      PathOperation.union,
      Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0.35 * u, 6 * u, 14.3 * u, 3 * u), Radius.circular(u * 0.5))),
      Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6 * u, 0.35 * u, 3 * u, 14.3 * u), Radius.circular(u * 0.5))),
    );
    canvas.drawPath(
      plate.shift(Offset(0, u * 0.14)),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      plate,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[skin.plateA, skin.plateB],
        ).createShader(full),
    );

    // حفره‌های مسیر اصلی
    final hr = u * 0.4;
    for (var i = 0; i < _Ludo.track.length; i++) {
      final cell = _Ludo.track[i];
      final o = Offset((cell[1] + 0.5) * u, (cell[0] + 0.5) * u);
      final startOwner = i % 13 == 0 ? i ~/ 13 : -1;
      if (startOwner >= 0) {
        _hole(canvas, o, hr, ring: _ludoSeatColors[startOwner], tint: _mix(_ludoSeatColors[startOwner], skin.hole, 0.55));
      } else {
        _hole(canvas, o, hr, star: _Ludo.safe.contains(i));
      }
    }

    // ستون‌های پایانی رنگی
    for (var k = 0; k < 4; k++) {
      for (var n = 1; n <= 5; n++) {
        late final double cx;
        late final double cy;
        switch (k) {
          case 0:
            cx = n + 0.5;
            cy = 7.5;
            break;
          case 1:
            cx = 7.5;
            cy = n + 0.5;
            break;
          case 2:
            cx = 14 - n + 0.5;
            cy = 7.5;
            break;
          default:
            cx = 7.5;
            cy = 14 - n + 0.5;
        }
        _hole(canvas, Offset(cx * u, cy * u), hr, ring: _ludoSeatColors[k], tint: _mix(_ludoSeatColors[k], Colors.white, 0.35));
      }
    }

    // مرکز: چهار قطاع رنگی
    final c = Offset(7.5 * u, 7.5 * u);
    final hub = Rect.fromCircle(center: c, radius: 1.45 * u);
    canvas.drawCircle(c, 1.58 * u, Paint()..color = const Color(0x66000000));
    const starts = <double>[3 * pi / 4, -3 * pi / 4, -pi / 4, pi / 4];
    for (var k = 0; k < 4; k++) {
      canvas.drawArc(hub, starts[k], pi / 2, true, Paint()..color = _ludoSeatColors[k]);
    }
    canvas.drawCircle(
      c,
      1.45 * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.12
        ..color = const Color(0xfff0c36a),
    );
    canvas.drawCircle(c, 0.42 * u, Paint()..color = const Color(0xfffff3cf));
    canvas.drawCircle(
      c,
      0.42 * u,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.08
        ..color = const Color(0xffd9a441),
    );
  }

  @override
  bool shouldRepaint(covariant _LudoPainter old) => old.activeSeat != activeSeat || old.skin != skin;
}

// ================================================================= منچ جمعی (گوشی‌های نزدیک، بدون اینترنت)

class _ChatMsg {
  const _ChatMsg(this.name, this.text, this.mine);
  final String name;
  final String text;
  final bool mine;
}

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

  // چت بین بازیکنان
  bool chatOn = true;
  final List<_ChatMsg> chat = <_ChatMsg>[];
  int _lastChatMs = 0;

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

  // زمان نوبت (روی میزبان اجرا می‌شود؛ به بقیه «ثانیه‌ی باقی‌مانده» فرستاده می‌شود)
  int dlMs = 0;
  String _dlKey = '';
  int tl = 0;
  int tlAt = 0;
  Timer? _clock;
  final Map<int, int> _timeouts = <int, int>{};

  // بازی دوباره
  final Set<String> rmVotes = <String>{};
  bool rmSent = false;

  int get me => ids.indexOf(_mesh.myUid);

  @override
  void initState() {
    super.initState();
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
    _mesh.addListener(_onMesh);
    _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
  }

  @override
  void dispose() {
    _gen++;
    _clock?.cancel();
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

  // ---------------------------------------------------------------- زمان نوبت

  void _updateDeadline() {
    final waiting = winner < 0 && !busy && (ph == 'roll' || ph == 'pick');
    final key = waiting ? '$ph|$turn' : '';
    if (key.isEmpty) {
      dlMs = 0;
      _dlKey = '';
      return;
    }
    if (key != _dlKey) {
      _dlKey = key;
      dlMs = DateTime.now().millisecondsSinceEpoch + (ph == 'pick' ? 30 : 25) * 1000;
    }
  }

  int _tlNow() => dlMs == 0 ? 0 : max(0, ((dlMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil());

  int _secsLeft() {
    if (isHost) return _tlNow();
    if (tl <= 0) return 0;
    return max(0, tl - ((DateTime.now().millisecondsSinceEpoch - tlAt) / 1000).floor());
  }

  void _clockTick() {
    if (!mounted || stage != 'play') return;
    if (isHost && winner < 0 && dlMs > 0 && DateTime.now().millisecondsSinceEpoch > dlMs && !busy) {
      _autoPlay();
      return;
    }
    setState(() {});
  }

  /// پایان مهلت: میزبان به‌جای بازیکن تاس می‌اندازد یا یک مهره را انتخاب می‌کند.
  void _autoPlay() {
    final pl = turn;
    if (pl >= ids.length) return;
    _timeouts[pl] = (_timeouts[pl] ?? 0) + 1;
    dlMs = 0;
    _dlKey = '';
    if (ph == 'roll') {
      _hostRoll(pl);
    } else if (ph == 'pick') {
      _hostPick(_Ludo.botPick(toks, seats, turn, die, BotLevel.normal, _rnd));
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
      case 'lu_rm':
        if (isHost && stage == 'play' && toMe && '${m['code']}' == code && ids.contains(from) && winner >= 0) {
          setState(() => rmVotes.add(from));
        }
        break;
      case 'lu_chat':
        if (chatOn && '${m['code']}' == code && ids.contains(from) && from != _mesh.myUid) {
          final t = '${m['t']}';
          if (t.isNotEmpty && t.length <= 80) {
            setState(() {
              chat.add(_ChatMsg(fromName, t, false));
              if (chat.length > 30) chat.removeAt(0);
            });
          }
        }
        break;
      case 'lu_roll':
        if (isHost && stage == 'play' && toMe && '${m['code']}' == code && turn < ids.length && ids[turn] == from) {
          _timeouts[turn] = 0;
          _hostRoll(turn);
        }
        break;
      case 'lu_pick':
        if (isHost && stage == 'play' && toMe && '${m['code']}' == code && turn < ids.length && ids[turn] == from) {
          _timeouts[turn] = 0;
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
        'tl': _tlNow(),
      };

  void _push() {
    seq++;
    _updateDeadline();
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
    final prevMsg = msgKey;
    final prevSeq = seq;
    setState(() {
      seq = sq;
      stage = 'play';
      lost = false;
      tl = (m['tl'] as num?)?.toInt() ?? 0;
      tlAt = DateTime.now().millisecondsSinceEpoch;
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
      if (winner < 0) {
        reported = false;
        resultReady = false;
        gained = 0;
        rmSent = false;
      }
    });
    if (sq != prevSeq) {
      if (msgKey == 'captured' && prevMsg != 'captured') {
        GameFx.hit();
      } else if (ph == 'roll' || ph == 'pick') {
        GameFx.move();
      }
    }
    if (winner >= 0) {
      GameFx.win();
      _report();
    }
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
    gained = 0;
    rmVotes.clear();
    _timeouts.clear();
    dlMs = 0;
    _dlKey = '';
    stage = 'play';
    _lastSnap = DateTime.now().millisecondsSinceEpoch;
    _push();
    _maybeAuto();
  }

  bool _gone(int pl) => (pl != 0 && !_mesh.peers.values.any((p) => p.uid == ids[pl])) || (_timeouts[pl] ?? 0) >= 2;

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
    GameFx.roll();
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
    if (cap > 0) {
      GameFx.hit();
    } else {
      GameFx.move();
    }
    ph = 'shown';
    _push();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    if (toks[who].every((p) => p == 57)) {
      winner = who;
      ph = 'over';
      busy = false;
      GameFx.win();
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
    _timeouts[me] = 0;
    if (isHost) {
      _hostRoll(me);
    } else {
      _send(<String, dynamic>{'g': 'lu_roll', 'to': hostUid, 'code': code});
    }
  }

  /// «بازی دوباره» با همان بازیکنان (فقط روی اتصال مستقیم؛ بدون ورکر)
  void _rematch() {
    if (isHost) {
      _hostStart();
    } else if (!rmSent) {
      _send(<String, dynamic>{'g': 'lu_rm', 'to': hostUid, 'code': code});
      setState(() => rmSent = true);
    }
  }

  void _myPick(int pl, int i) {
    if (ph != 'pick' || turn != me || pl != me || !movable.contains(i)) return;
    _timeouts[me] = 0;
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

  void _sendChat(String raw) {
    final t = raw.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!chatOn || t.isEmpty || t.length > 60 || now - _lastChatMs < 1000) return;
    _lastChatMs = now;
    _send(<String, dynamic>{'g': 'lu_chat', 'code': code, 't': t});
    setState(() {
      chat.add(_ChatMsg(_mesh.myName, t, true));
      if (chat.length > 30) chat.removeAt(0);
    });
  }

  Widget _chatBox() {
    if (!chatOn) return const SizedBox.shrink();
    return GameChatPanel(lines: <ChatLine>[for (final m in chat) ChatLine(m.name, m.text, m.mine)], onSend: _sendChat);
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
        if (winner < 0 && (ph == 'roll' || ph == 'pick') && _secsLeft() > 0) GameTimerBar(left: _secsLeft(), total: ph == 'pick' ? 30 : 25),
        const SizedBox(height: 8),
        _diceControls(die: shownDie, rolling: ph == 'rolling', enabled: canRoll, onRoll: _myRoll),
        _chatBox(),
        if (winner >= 0 && resultReady) ...<Widget>[
          _diceResultCard(
            title: _status(),
            gained: gained,
            onAgain: _rematch,
            onBack: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              isHost
                  ? (rmVotes.isEmpty ? '' : (GameT.fa ? '${rmVotes.length} نفر بازی دوباره می‌خواهند' : '${rmVotes.length} want a rematch'))
                  : (rmSent ? (GameT.fa ? 'درخواست بازی دوباره ارسال شد؛ منتظر میزبان…' : 'Rematch requested; waiting for the host…') : ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: gSky, fontSize: 12.5),
            ),
          ),
        ],
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
          actions: [
            gameFxAction(() => setState(() {})),
            IconButton(
              tooltip: GameT.fa ? 'چت بازیکنان' : 'Player chat',
              onPressed: () => setState(() => chatOn = !chatOn),
              icon: Icon(chatOn ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded, color: chatOn ? gGold : gMuted),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 8, 640.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
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

// ================================================================= ابزارهای مشترک برای بازی‌های دیگر (تخته‌نرد)

/// کارت بازیکن (باید داخل Row باشد)
Widget sharedDiceChip(String name, Color color, String sub, bool active) => _diceChip(name, color, sub, active);

/// تاس با نقطه‌ها؛ [dim] یعنی این تاس مصرف شده است.
Widget sharedDie(int v, {double size = 44, bool dim = false}) {
  return Opacity(
    opacity: dim ? 0.3 : 1,
    child: SizedBox(
      width: size,
      height: size,
      child: ValueListenableBuilder<String>(
        valueListenable: DiceSkins.current,
        builder: (_, __, ___) => CustomPaint(painter: _DiePainter(v)),
      ),
    ),
  );
}

/// کارت نتیجهٔ بازی (برنده/بازنده، سکه، دکمه‌ها)
Widget sharedResultCard({
  required String title,
  required int gained,
  required VoidCallback onAgain,
  required VoidCallback onBack,
}) =>
    _diceResultCard(title: title, gained: gained, onAgain: onAgain, onBack: onBack);

/// پیش‌نمایش یک تاس با ظاهر مشخص (فروشگاه)
Widget sharedDieSkin(String code, {double size = 40, int v = 5}) {
  return SizedBox(width: size, height: size, child: CustomPaint(painter: _DiePainter(v, DiceSkins.byCode(code))));
}

// ================================================================= مار و پله با گوشی‌های نزدیک (۲ نفره، بدون اینترنت)

class _SnRoom {
  _SnRoom(this.code, this.hostUid, this.hostName, this.ts);
  final String code;
  final String hostUid;
  final String hostName;
  int ts;
}

/// گوشی میزبان تاس و قوانین را اجرا می‌کند و وضعیت را برای حریف می‌فرستد (مثل تخته‌نرد نزدیک).
class SnakesNearbyPage extends StatefulWidget {
  const SnakesNearbyPage({super.key});

  @override
  State<SnakesNearbyPage> createState() => _SnakesNearbyPageState();
}

class _SnakesNearbyPageState extends State<SnakesNearbyPage> {
  final GameWallet _w = GameWallet.instance;
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final Random _rnd = Random();
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _tick;

  String stage = 'menu'; // menu | host | join | play
  String code = '';
  String peerUid = '';
  bool isHost = true;
  bool started = false;
  bool lost = false;
  bool _starting = false;
  final Map<String, _SnRoom> rooms = <String, _SnRoom>{};
  List<String> pnames = <String>['', ''];

  final List<int> pos = <int>[0, 0];
  int turn = 0;
  int die = 1;
  bool rolling = false;
  bool busy = false;
  int winner = -1;
  String msg = '';
  int gained = 0;
  bool resultReady = false;
  bool reported = false;
  int _gen = 0;
  int _lastSnap = 0;
  int seq = 0;
  bool rmMine = false;
  bool rmPeer = false;
  bool chatOn = true;
  final List<ChatLine> chat = <ChatLine>[];
  int _lastChat = 0;

  int get myIdx => isHost ? 0 : 1;
  bool get myTurn => started && !lost && winner < 0 && turn == myIdx && !busy;

  @override
  void initState() {
    super.initState();
    SkinStore.load().then((_) {
      if (mounted) setState(() {});
    });
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
    _mesh.addListener(_onMesh);
    _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
  }

  @override
  void dispose() {
    _gen++;
    _tick?.cancel();
    _sub?.cancel();
    _mesh.removeListener(_onMesh);
    NearbyGameLink.instance.detach();
    super.dispose();
  }

  void _onMesh() {
    if (mounted) setState(() {});
  }

  void _send(Map<String, dynamic> m) => NearbyGameLink.instance.send(<String, dynamic>{...m, 'to': peerUid, 'code': code});

  Map<String, dynamic> _snap() => <String, dynamic>{'g': 'sn_s', 'pos': pos, 'turn': turn, 'die': die, 'rolling': rolling, 'busy': busy, 'win': winner, 'msg': msg, 'seq': seq, 'names': pnames};

  void _sync() {
    if (!mounted) return;
    if (isHost && started) {
      seq++;
      _send(_snap());
    }
    setState(() {});
  }

  // ---------------------------------------------------------------- منطق (روی گوشی میزبان)

  void _newGame() {
    _gen++;
    pos[0] = 0;
    pos[1] = 0;
    turn = _rnd.nextInt(2);
    die = 1;
    rolling = false;
    busy = false;
    winner = -1;
    msg = '';
    gained = 0;
    resultReady = false;
    reported = false;
    rmMine = false;
    rmPeer = false;
    started = true;
    lost = false;
    _sync();
  }

  Future<void> _hostRoll(int who) async {
    if (!isHost || busy || winner >= 0 || turn != who || !started) return;
    final gen = _gen;
    busy = true;
    rolling = true;
    msg = '';
    _sync();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || gen != _gen) return;
    final r = _rnd.nextInt(6) + 1;
    die = r;
    rolling = false;
    GameFx.roll();
    _sync();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || gen != _gen) return;
    await _hostMove(who, r, gen);
  }

  Future<void> _hostMove(int who, int r, int gen) async {
    var note = '';
    final target = pos[who] + r;
    if (target > 100) {
      note = _dt('exact');
    } else {
      GameFx.move();
      pos[who] = target;
      _sync();
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || gen != _gen) return;
      final j = _kJumps[target];
      if (j != null) {
        note = j > target ? _dt('ladder') : _dt('snake');
        if (j > target) {
          GameFx.move();
        } else {
          GameFx.hit();
        }
        pos[who] = j;
        msg = note;
        _sync();
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted || gen != _gen) return;
      }
      if (pos[who] == 100) {
        GameFx.win();
        winner = who;
        busy = false;
        _sync();
        _finish();
        return;
      }
    }
    final again = r == 6;
    if (again) note = note.isEmpty ? _dt('extra') : '$note · ${_dt('extra')}';
    msg = note;
    if (!again) turn = 1 - turn;
    busy = false;
    _sync();
  }

  Future<void> _finish() async {
    if (reported) return;
    reported = true;
    final g = await _w.reportOffline(winner == myIdx ? 'win' : 'loss', 'nearby');
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  void _myRoll() {
    if (!myTurn) return;
    if (isHost) {
      _hostRoll(0);
    } else {
      _send(<String, dynamic>{'g': 'sn_roll'});
    }
  }

  // ---------------------------------------------------------------- شبکه

  void _onTick() {
    if (!mounted || !_mesh.running) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (stage == 'host') {
      NearbyGameLink.instance.send(<String, dynamic>{'g': 'sn_open', 'code': code});
    } else if (stage == 'join') {
      rooms.removeWhere((k, v) => now - v.ts > 7000);
      if (code.isNotEmpty && !started) NearbyGameLink.instance.send(<String, dynamic>{'g': 'sn_join', 'to': peerUid, 'code': code});
      setState(() {});
    } else if (stage == 'play' && started) {
      if (isHost) {
        _send(_snap());
        if (!lost && peerUid.isNotEmpty && !_mesh.peers.values.any((p) => p.uid == peerUid) && winner < 0) setState(() => lost = true);
      } else if (!lost && now - _lastSnap > 20000 && winner < 0) {
        setState(() => lost = true);
      }
    }
  }

  void _onEvent(Map<String, dynamic> m) {
    if (!mounted) return;
    final g = '${m['g']}';
    if (!g.startsWith('sn_')) return;
    final from = '${m['u']}';
    final toMe = '${m['to']}' == _mesh.myUid;
    switch (g) {
      case 'sn_open':
        if (stage == 'join') {
          final c = '${m['code']}';
          setState(() => rooms[c] = _SnRoom(c, from, '${m['n']}', DateTime.now().millisecondsSinceEpoch));
        }
        break;
      case 'sn_join':
        if (stage == 'host' && toMe && '${m['code']}' == code) {
          peerUid = from;
          pnames = <String>[_mesh.myName, '${m['n']}'];
          stage = 'play';
          _newGame();
        }
        break;
      default:
        if (!(toMe && '${m['code']}' == code && from == peerUid && stage != 'menu')) return;
        switch (g) {
          case 'sn_s':
            if (isHost) return;
            final sq = (m['seq'] as num?)?.toInt() ?? 0;
            if (started && sq <= seq) return;
            final p = m['pos'];
            if (p is! List || p.length != 2) return;
            final prevRolling = rolling;
            setState(() {
              seq = sq;
              started = true;
              stage = 'play';
              lost = false;
              _lastSnap = DateTime.now().millisecondsSinceEpoch;
              pos[0] = (p[0] as num).toInt();
              pos[1] = (p[1] as num).toInt();
              turn = (m['turn'] as num).toInt();
              die = (m['die'] as num).toInt();
              rolling = m['rolling'] == true;
              busy = m['busy'] == true;
              winner = (m['win'] as num).toInt();
              msg = '${m['msg']}';
              final nm = m['names'];
              if (nm is List && nm.length == 2) pnames = <String>['${nm[0]}', '${nm[1]}'];
              if (winner < 0) {
                reported = false;
                resultReady = false;
                gained = 0;
                rmMine = false;
                rmPeer = false;
              }
            });
            if (rolling && !prevRolling) GameFx.roll();
            if (winner >= 0) {
              GameFx.win();
              _finish();
            }
            break;
          case 'sn_roll':
            if (isHost && turn == 1) _hostRoll(1);
            break;
          case 'sn_chat':
            final t = '${m['t']}';
            if (chatOn && t.isNotEmpty && t.length <= 80) {
              setState(() {
                chat.add(ChatLine(pnames[1 - myIdx], t, false));
                if (chat.length > 30) chat.removeAt(0);
              });
            }
            break;
          case 'sn_rm':
            rmPeer = true;
            if (isHost && rmMine && winner >= 0) {
              _newGame();
            } else {
              setState(() {});
            }
            break;
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
    if (!ok) gToast(context, _mesh.lastError.isEmpty ? GameT.t('nearby_perm') : '${GameT.t('nearby_perm')}\n(${_mesh.lastError.length > 70 ? _mesh.lastError.substring(0, 70) : _mesh.lastError})');
  }

  void _createRoom() {
    if (!_mesh.running) return;
    code = '${1000 + _rnd.nextInt(9000)}';
    isHost = true;
    started = false;
    setState(() => stage = 'host');
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'sn_open', 'code': code});
  }

  void _openJoin() {
    isHost = false;
    started = false;
    code = '';
    setState(() => stage = 'join');
  }

  void _joinRoom(_SnRoom r) {
    setState(() {
      code = r.code;
      peerUid = r.hostUid;
    });
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'sn_join', 'to': peerUid, 'code': code});
  }

  void _sendChat(String raw) {
    final t = raw.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!chatOn || t.isEmpty || t.length > 60 || now - _lastChat < 1000) return;
    _lastChat = now;
    _send(<String, dynamic>{'g': 'sn_chat', 't': t});
    setState(() {
      chat.add(ChatLine(pnames[myIdx], t, true));
      if (chat.length > 30) chat.removeAt(0);
    });
  }

  void _rematch() {
    if (rmMine) return;
    rmMine = true;
    _send(<String, dynamic>{'g': 'sn_rm'});
    if (isHost && rmPeer) {
      _newGame();
      return;
    }
    setState(() {});
  }

  // ---------------------------------------------------------------- رابط

  String _status() {
    if (winner >= 0) return winner == myIdx ? GameT.t('you_win') : GameT.t('you_lose');
    if (lost) return _dt('lu_lost');
    return turn == myIdx ? GameT.t('your_turn') : GameT.t('turn_of', <String, String>{'n': pnames[turn]});
  }

  Widget _netCard() {
    final on = _mesh.running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: on ? gPanel : gGold, foregroundColor: on ? gGold : gBg, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _toggleNet,
        icon: _starting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
        label: Text(on ? '${GameT.t('nearby_stop')} · ${_mesh.peers.length}' : GameT.t('nearby_start'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _big(IconData icon, String text, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      );

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
      child: _tokenDot(_snakePlayerColors[p], d, glow: winner < 0 && turn == p),
    );
  }

  Widget _board(double w) {
    final u = w / 10;
    return SizedBox(
      width: w,
      height: w + u * 0.9,
      child: Stack(children: [Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _SnakesPainter(_dt('start'))))), _token(0, u), _token(1, u)]),
    );
  }

  Widget _playBody(double w) {
    if (!started) return Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [const CircularProgressIndicator(color: gGold), const SizedBox(height: 16), Text(GameT.t('connecting'), style: const TextStyle(color: gGold))]));
    return Column(
      children: [
        Row(children: [
          _diceChip(pnames[0], _snakePlayerColors[0], pos[0] == 0 ? '' : _dt('cell', <String, String>{'n': '${pos[0]}'}), winner < 0 && turn == 0),
          const SizedBox(width: 10),
          _diceChip(pnames[1], _snakePlayerColors[1], pos[1] == 0 ? '' : _dt('cell', <String, String>{'n': '${pos[1]}'}), winner < 0 && turn == 1),
        ]),
        const SizedBox(height: 10),
        Text(_status(), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
        SizedBox(height: 20, child: Text(msg, style: const TextStyle(color: gSky, fontSize: 12.5, fontWeight: FontWeight.w700))),
        const SizedBox(height: 4),
        _board(w),
        const SizedBox(height: 14),
        _diceControls(die: die, rolling: rolling, enabled: myTurn, onRoll: _myRoll),
        if (chatOn) GameChatPanel(lines: chat, onSend: _sendChat),
        if (winner >= 0 && resultReady) ...<Widget>[
          _diceResultCard(title: _status(), gained: gained, onAgain: _rematch, onBack: () => Navigator.of(context).pop()),
          if (rmPeer || rmMine)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(rmMine ? 'درخواست بازی دوباره ارسال شد؛ منتظر حریف…' : 'حریف بازی دوباره می‌خواهد', textAlign: TextAlign.center, style: const TextStyle(color: gSky, fontSize: 12.5)),
            ),
        ],
        const SizedBox(height: 14),
        Text(_dt('snakes_rule'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
      ],
    );
  }

  Widget _menuBody() {
    switch (stage) {
      case 'host':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _netCard(),
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: gGold)),
          const SizedBox(height: 16),
          const Text('منتظر پیوستن حریف…\nحریف باید «پیوستن به بازی» را بزند.', textAlign: TextAlign.center, style: TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.9)),
        ]);
      case 'join':
        final list = rooms.values.toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _netCard(),
          if (code.isNotEmpty)
            const Text('پیوستید. منتظر شروع بازی…', textAlign: TextAlign.center, style: TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.8))
          else if (list.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('بازی‌ای در اطراف پیدا نشد.\nمیزبان باید «ساخت بازی» را بزند و کنار هم باشید.', textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)))
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
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg), onPressed: () => _joinRoom(r), child: const Text('پیوستن', style: TextStyle(fontWeight: FontWeight.w900))),
                ]),
              ),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _netCard(),
          if (_mesh.running) ...<Widget>[_big(Icons.add_circle_rounded, 'ساخت بازی (میزبان)', _createRoom), _big(Icons.login_rounded, 'پیوستن به بازی', _openJoin)],
          const SizedBox(height: 8),
          const Text('بدون اینترنت. هر دو گوشی باید شبکهٔ آفلاین را روشن کنند و نزدیک هم باشند.', textAlign: TextAlign.center, style: TextStyle(color: gMuted, fontSize: 12, height: 1.8)),
        ]);
    }
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
          title: Text('${GameT.t('snakes')} · ${GameT.t('nearby_title')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
          actions: [
            skinAction(() => showSkinSheet(context, game: 'snakes', title: 'طرح صفحه مار و پله', names: <String>[for (final s in kSnakesSkins) s.name], prices: <int>[for (final s in kSnakesSkins) s.price], preview: snakesPreview, onChanged: () => setState(() {}))),
            gameFxAction(() => setState(() {})),
            IconButton(
              tooltip: 'چت',
              onPressed: () => setState(() => chatOn = !chatOn),
              icon: Icon(chatOn ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded, color: chatOn ? gGold : gMuted),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 8, 600.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
                child: Center(child: SizedBox(width: w, child: stage == 'play' ? _playBody(w) : _menuBody())),
              );
            },
          ),
        ),
      ),
    );
  }
}
