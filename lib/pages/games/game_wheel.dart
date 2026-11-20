import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/group_ui.dart';
import 'bg_sfx.dart';
import 'game_texts.dart';

/// گردونه‌ی شانس: هر روز یک چرخش رایگان (با شمارنده‌ی معکوس تا ساعت ۰۰:۰۰ فردا)،
/// چرخش اضافه با سکه، ذخیره‌ی دائمی روی گوشی و جمع‌شدن جایزه‌ها با سکه و XP بازی‌ها.

String wFa(Object n) => '$n'.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

class WheelPrize {
  const WheelPrize(this.label, this.kind, this.value, this.weight, this.color);
  final String label;

  /// c = سکه ، x = امتیاز تجربه ، s = چرخش دوباره
  final String kind;
  final int value;
  final double weight;
  final Color color;
}

const List<WheelPrize> kWheelPrizes = <WheelPrize>[
  WheelPrize('۱۰', 'c', 10, 24, Color(0xff1f8a8a)),
  WheelPrize('۲۰', 'c', 20, 18, Color(0xff5b3fb0)),
  WheelPrize('⭐ ۳۰', 'x', 30, 14, Color(0xff2a6fd0)),
  WheelPrize('۵۰', 'c', 50, 9, Color(0xffc0392b)),
  WheelPrize('۱۵', 'c', 15, 20, Color(0xff2a9d5c)),
  WheelPrize('🔁', 's', 1, 6, Color(0xffc76a1a)),
  WheelPrize('۳۰', 'c', 30, 12, Color(0xff8a3fb0)),
  WheelPrize('۱۰۰ 👑', 'c', 100, 2.5, Color(0xffd4a017)),
];

const int kWheelExtraCost = 30;

/// ذخیره‌ی گردونه روی گوشی (SharedPreferences)
class WheelStore extends ChangeNotifier {
  WheelStore._();
  static final WheelStore instance = WheelStore._();
  static const String _k = 'cyrus_wheel_v1';

  bool loaded = false;
  String day = ''; // روزی که چرخش رایگان گرفته شد
  int lastMs = 0;
  int extra = 0; // چرخش‌های اضافه (جایزه‌ی «دوباره» یا خریده‌شده)
  int coins = 0; // سکه‌ی برده‌شده از گردونه (به جمع سکه‌ها اضافه می‌شود)
  int spent = 0; // سکه‌ای که برای چرخش اضافه خرج شده
  int xp = 0;
  int spins = 0;
  List<String> hist = <String>[];

  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// سکه‌ی خالص گردونه (برد منهای خرج چرخش اضافه)
  int get net => coins - spent;

  bool get freeReady {
    final now = DateTime.now();
    // اگر ساعت گوشی عقب برده شد، چرخش رایگان تازه نمی‌شود
    if (lastMs > 0 && now.millisecondsSinceEpoch < lastMs) return false;
    return day != dayKey(now);
  }

  bool get canSpin => freeReady || extra > 0;

  /// زمان باقی‌مانده تا ساعت ۰۰:۰۰ فردا
  Duration get untilMidnight {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    return next.difference(now);
  }

  Future<void> load() async {
    if (loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        int g(String k) => (m[k] as num?)?.toInt() ?? 0;
        day = (m['day'] as String?) ?? '';
        lastMs = g('lastMs');
        extra = g('extra');
        coins = g('coins');
        spent = g('spent');
        xp = g('xp');
        spins = g('spins');
        hist = ((m['hist'] as List?) ?? const <dynamic>[]).map((e) => '$e').toList();
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(<String, dynamic>{'day': day, 'lastMs': lastMs, 'extra': extra, 'coins': coins, 'spent': spent, 'xp': xp, 'spins': spins, 'hist': hist}));
    } catch (_) {}
  }

  /// مصرف یک چرخش: اول رایگان، بعد چرخش اضافه. false = ممکن نیست.
  Future<bool> consume({int walletCoins = 0}) async {
    final now = DateTime.now();
    if (freeReady) {
      day = dayKey(now);
      lastMs = now.millisecondsSinceEpoch;
    } else if (extra > 0) {
      extra--;
    } else {
      return false;
    }
    await _save();
    return true;
  }

  /// خرج کردن سکه‌ی محلی (کم شدن از موجودی کل)
  Future<void> spend(int n) async {
    spent += n;
    await _save();
  }

  /// سکه‌ی هدیه (مثلاً بعد از معرفی به دوستان)
  Future<void> addCoins(int n) async {
    coins += n;
    await _save();
  }

  /// چرخش اضافه‌ی هدیه (مثلاً بعد از معرفی به دوستان)
  Future<void> addExtra(int n) async {
    extra += n;
    await _save();
  }

  Future<void> buyExtra() async {
    spent += kWheelExtraCost;
    extra++;
    await _save();
  }

  Future<void> award(WheelPrize p) async {
    spins++;
    if (p.kind == 'c') coins += p.value;
    if (p.kind == 'x') xp += p.value;
    if (p.kind == 's') extra++;
    hist.insert(0, p.label);
    if (hist.length > 10) hist.removeLast();
    await _save();
  }
}

int pickWheelPrize(Random r) {
  final total = kWheelPrizes.fold<double>(0, (a, p) => a + p.weight);
  var x = r.nextDouble() * total;
  for (var i = 0; i < kWheelPrizes.length; i++) {
    x -= kWheelPrizes[i].weight;
    if (x <= 0) return i;
  }
  return 0;
}

String wheelCountdown(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  final t = '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  return GameT.fa ? wFa(t) : t;
}

// ---------------------------------------------------------------------------
// رسم گردونه

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.rot, this.labels);
  final double rot; // رادیان
  final bool labels;

  @override
  void paint(Canvas canvas, Size size) {
    final n = kWheelPrizes.length;
    final seg = 2 * pi / n;
    final R = size.width / 2;
    canvas.save();
    canvas.translate(R, R);
    canvas.drawCircle(Offset.zero, R - 1, Paint()..color = const Color(0xfff2c14e));
    canvas.drawCircle(Offset.zero, R - size.width * .035, Paint()..color = const Color(0xff3a2410));
    canvas.rotate(rot);
    final rr = R - size.width * .05;
    final rect = Rect.fromCircle(center: Offset.zero, radius: rr);
    for (var i = 0; i < n; i++) {
      final a0 = -pi / 2 + i * seg - seg / 2;
      final path = Path()
        ..moveTo(0, 0)
        ..arcTo(rect, a0, seg, false)
        ..close();
      final c = kWheelPrizes[i].color;
      canvas.drawPath(
        path,
        Paint()..shader = RadialGradient(colors: <Color>[Color.lerp(c, Colors.white, .35)!, c]).createShader(rect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white30,
      );
      if (labels) {
        canvas.save();
        canvas.rotate(i * seg);
        final p = kWheelPrizes[i];
        final tp = TextPainter(
          text: TextSpan(
            text: p.label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: p.label.length > 4 ? rr * .15 : rr * .22, shadows: const <Shadow>[Shadow(color: Colors.black54, blurRadius: 4)]),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -rr * .74 - tp.height / 2));
        if (p.kind == 'c' && p.label.length <= 4) {
          final coin = TextPainter(text: TextSpan(text: '🪙', style: TextStyle(fontSize: rr * .12)), textDirection: TextDirection.rtl)..layout();
          coin.paint(canvas, Offset(-coin.width / 2, -rr * .5 - coin.height / 2));
        }
        canvas.restore();
      }
    }
    for (var j = 0; j < n * 2; j++) {
      final an = -pi / 2 + j * seg / 2 - seg / 2;
      canvas.drawCircle(Offset(cos(an), sin(an)) * (R - size.width * .02), size.width * .011, Paint()..color = j.isEven ? const Color(0xffffe08a) : Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.rot != rot;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ---------------------------------------------------------------------------
// صفحه‌ی گردونه

class WheelPage extends StatefulWidget {
  const WheelPage({super.key, this.walletCoins = 0, this.onSpendNote});

  /// سکه‌ی کل کاربر (برای فعال بودن دکمه‌ی چرخش اضافه)
  final int walletCoins;
  final VoidCallback? onSpendNote;

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage> with SingleTickerProviderStateMixin {
  final WheelStore st = WheelStore.instance;
  final Random _rnd = Random();
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
  double _from = 0;
  double _to = 0;
  double _rot = 0; // رادیان
  bool _spinning = false;
  bool _kick = false;
  int _lastSeg = -1;
  String _msg = '';
  WheelPrize? _won;
  Timer? _timer;

  int get _canPay => widget.walletCoins + st.net;

  @override
  void initState() {
    super.initState();
    st.load().then((_) {
      if (mounted) setState(() {});
    });
    _ac.addListener(_onAnim);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_spinning) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  void _onAnim() {
    final t = Curves.easeOutQuart.transform(_ac.value);
    final r = _from + (_to - _from) * t;
    final n = kWheelPrizes.length;
    final seg = 2 * pi / n;
    final a = (2 * pi - (r % (2 * pi))) + seg / 2;
    final idx = ((a % (2 * pi)) / seg).floor() % n;
    if (idx != _lastSeg) {
      _lastSeg = idx;
      BgSfx.click();
      HapticFeedback.selectionClick();
      _kick = true;
      Future<void>.delayed(const Duration(milliseconds: 90), () {
        if (mounted) setState(() => _kick = false);
      });
    }
    setState(() => _rot = r);
  }

  Future<void> _spin() async {
    if (_spinning) return;
    if (!st.canSpin) return; // بعد از چرخش روزانه قفل است
    final ok = await st.consume();
    if (!ok || !mounted) return;
    final idx = pickWheelPrize(_rnd);
    final seg = 2 * pi / kWheelPrizes.length;
    final cur = _rot % (2 * pi);
    final need = (2 * pi - idx * seg - cur) % (2 * pi);
    _from = _rot;
    _to = _rot + 2 * pi * 6 + (need < 0 ? need + 2 * pi : need) + (_rnd.nextDouble() - .5) * seg * .7;
    setState(() {
      _spinning = true;
      _won = null;
      _msg = '';
    });
    await _ac.forward(from: 0);
    if (!mounted) return;
    final p = kWheelPrizes[idx];
    await st.award(p);
    if (!mounted) return;
    final big = p.kind == 'c' && p.value >= 50;
    if (big) {
      BgSfx.win();
      HapticFeedback.heavyImpact();
    } else {
      BgSfx.move();
    }
    final what = p.kind == 'c' ? '🪙 ${wFa(p.value)} سکه' : (p.kind == 'x' ? '⭐ ${wFa(p.value)} امتیاز تجربه (XP)' : '🔁 یک چرخش دوباره');
    setState(() {
      _spinning = false;
      _won = p;
      _msg = '🎉 $what برنده شدی!';
    });
    gToast(context, '$what به امتیازهایت اضافه شد');
  }

  Widget _btn() {
    final cd = st.untilMidnight;
    String text;
    bool on;
    if (_spinning) {
      text = 'در حال چرخش…';
      on = false;
    } else if (st.freeReady) {
      text = 'بچرخان (رایگان)';
      on = true;
    } else if (st.extra > 0) {
      text = 'چرخش اضافه (${wFa(st.extra)})';
      on = true;
    } else {
      text = '🔒 امروز چرخیدی؛ فردا دوباره';
      on = false;
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: on || _spinning ? 1 : .4,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gGold.withOpacity(.55), disabledForegroundColor: gBg, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: on ? _spin : null,
              child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ),
        if (!st.freeReady && !_spinning)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
            child: Column(
              children: [
                const Text('فردا دوباره امتیاز بگیر 🎁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(wheelCountdown(cd), textDirection: TextDirection.ltr, style: const TextStyle(color: gGold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const Text('تا چرخش رایگان بعدی', style: TextStyle(color: gMuted, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = min(MediaQuery.of(context).size.width - 56, 340.0);
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: const Text('🎡 گردونه شانس', style: TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Text(st.freeReady ? 'یک چرخش رایگان امروز داری' : (st.extra > 0 ? 'چرخش اضافه: ${wFa(st.extra)}' : 'چرخش رایگان امروز استفاده شد'), style: const TextStyle(color: gMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: w,
                      height: w + 16,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 16,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(boxShadow: <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))], shape: BoxShape.circle),
                              child: CustomPaint(size: Size(w, w), painter: _WheelPainter(_rot, true)),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            child: AnimatedRotation(
                              turns: _kick ? -.045 : 0,
                              duration: const Duration(milliseconds: 80),
                              alignment: Alignment.topCenter,
                              child: CustomPaint(size: const Size(30, 34), painter: _PointerPainter()),
                            ),
                          ),
                          Positioned(
                            top: 16 + w / 2 - 32,
                            child: GestureDetector(
                              onTap: st.canSpin && !_spinning ? _spin : null,
                              child: Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(center: Alignment(-.3, -.3), colors: <Color>[Color(0xfffff3b0), Color(0xfff2b63c), Color(0xffa8691a)]),
                                  border: Border.all(color: Colors.white38, width: 3),
                                  boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
                                ),
                                child: Text(_spinning ? '…' : (st.canSpin ? 'بچرخان' : '🔒'), style: const TextStyle(color: Color(0xff4a2a00), fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Container(
                        key: ValueKey<String>(_msg),
                        constraints: const BoxConstraints(minHeight: 46),
                        alignment: Alignment.center,
                        child: Text(_msg, textAlign: TextAlign.center, style: const TextStyle(color: gTeal, fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _btn(),
                    if (st.hist.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final h in st.hist.take(8))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: gLine)),
                              child: Text(h, style: const TextStyle(color: gMuted, fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    _table(),
                    const SizedBox(height: 10),
                    Text('مجموع برده‌ها: 🪙 ${wFa(st.coins)} · ⭐ ${wFa(st.xp)} XP · ${wFa(st.spins)} چرخش\nجایزه‌ها در جمع امتیازهای بازی‌ها نشان داده می‌شود.', textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12, height: 1.8)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _table() {
    final total = kWheelPrizes.fold<double>(0, (a, p) => a + p.weight);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جایزه‌ها و شانس', style: TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (final p in kWheelPrizes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.kind == 'c' ? '${p.label.replaceAll(' 👑', '')} سکه' : (p.kind == 'x' ? '${wFa(p.value)} امتیاز تجربه' : 'یک چرخش دوباره'), style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('${wFa((p.weight / total * 100).round())}٪', style: const TextStyle(color: gMuted, fontSize: 12.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// کارت ورودی در صفحه‌ی بازی‌ها (با شمارنده‌ی معکوس)

class WheelEntryCard extends StatefulWidget {
  const WheelEntryCard({super.key, required this.walletCoins});
  final int walletCoins;

  @override
  State<WheelEntryCard> createState() => _WheelEntryCardState();
}

class _WheelEntryCardState extends State<WheelEntryCard> {
  final WheelStore st = WheelStore.instance;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    st.addListener(_u);
    st.load();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _u());
  }

  void _u() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _t?.cancel();
    st.removeListener(_u);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = st.canSpin;
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WheelPage(walletCoins: widget.walletCoins)));
        _u();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gGold, width: 1.6),
          gradient: const LinearGradient(colors: <Color>[Color(0xff3a1d66), Color(0xff1b2a6b), Color(0xff0f4a6b)], begin: Alignment.topRight, end: Alignment.bottomLeft),
          boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            SizedBox(width: 70, height: 70, child: CustomPaint(painter: _WheelPainter(0, false))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(GameT.fa ? '🎡 گردونه شانس' : '🎡 Lucky Wheel', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(width: 8),
                      if (ready) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xffff6b6b), borderRadius: BorderRadius.circular(12)), child: Text(GameT.fa ? 'آماده!' : 'Ready!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ready
                        ? (GameT.fa ? 'چرخش رایگان امروز را بگیر؛ جایزه به جمع امتیازت اضافه می‌شود' : 'Take today\'s free spin; the prize is added to your total')
                        : (GameT.fa ? 'چرخش بعدی: ${wheelCountdown(st.untilMidnight)}' : 'Next spin: ${wheelCountdown(st.untilMidnight)}'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6),
                  ),
                ],
              ),
            ),
            Icon(gDir == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: gGold),
          ],
        ),
      ),
    );
  }
}
