import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/group_ui.dart';
import 'fruit_engine.dart';
import 'game_api.dart';
import 'game_fx.dart';
import 'game_texts.dart';
import 'game_widgets.dart';
import 'game_skins.dart';

/// «میوه‌چین سایروس»: دو میوهٔ کنار هم را جابه‌جا کنید (بکشید یا دو بار لمس کنید)، ۳ تا ۵ میوهٔ هم‌شکل حذف می‌شوند.
/// میوهٔ ویژه (↔ ↕ بمب رنگی)، ترکیب ویژه‌ها، یخ، چکش و +۳ حرکت، راهنما و هدیهٔ روزانه.
/// بدون اینترنت کار می‌کند؛ مرحله و موجودی روی گوشی ذخیره می‌شود و اولین عبور از هر مرحله سکهٔ آفلاین می‌دهد.

const List<String> _fruits = <String>['🍎', '🍊', '🍌', '🍇', '🍓', '🍏'];

const Map<String, Map<String, String>> _ftx = {
  'title': {'fa': 'میوه‌چین سایروس', 'en': 'Cyrus Fruit Match'},
  'level': {'fa': 'مرحلهٔ {n}', 'en': 'Level {n}'},
  'moves': {'fa': 'حرکت: {n}', 'en': 'Moves: {n}'},
  'score': {'fa': 'امتیاز: {n}', 'en': 'Score: {n}'},
  'win': {'fa': 'مرحله تمام شد!', 'en': 'Level complete!'},
  'next': {'fa': 'مرحلهٔ بعد', 'en': 'Next level'},
  'lose': {'fa': 'حرکت‌ها تمام شد 😅', 'en': 'Out of moves 😅'},
  'retry': {'fa': 'تلاش دوباره', 'en': 'Try again'},
  'shuffle': {'fa': 'جابه‌جایی نمانده؛ میوه‌ها مخلوط شدند 🔀', 'en': 'No moves left; shuffled 🔀'},
  'hammer': {'fa': 'یک میوه را برای شکستن لمس کنید 🔨', 'en': 'Tap a fruit to smash it 🔨'},
  'extra': {'fa': '➕۳ حرکت', 'en': '+3 moves'},
  'combo': {'fa': 'ترکیب بزرگ! 💥', 'en': 'Big combo! 💥'},
  'p2': {'fa': 'عالی! 👏', 'en': 'Great! 👏'},
  'p3': {'fa': 'فوق‌العاده! 🔥', 'en': 'Amazing! 🔥'},
  'p4': {'fa': 'افسانه‌ای! 🌟', 'en': 'Legendary! 🌟'},
  'gift': {'fa': '🎁 هدیهٔ امروز: ۲ چکش و ۲ حرکت اضافه', 'en': '🎁 Daily gift: 2 hammers and 2 extra moves'},
  'help': {
    'fa': 'دو میوهٔ کنار هم را جابه‌جا کنید · ۳ تا هم‌میوه = حذف · ۴ تا = ↔ یا ↕ · ۵ تا = بمب رنگی · ویژه را دو بار لمس کنید تا فعال شود · دو ویژه را با هم جابه‌جا کنید · 🧊 با حذف میوهٔ زیر یخ، یخ می‌شکند',
    'en': 'Swap neighbours · 3 in a row clears · 4 makes ↔/↕ · 5 makes a colour bomb · double-tap a special to fire it · swap two specials for a big combo · clear a fruit under 🧊 to crack the ice'
  },
};

String _ft(String key, [Map<String, String>? p]) {
  final m = _ftx[key];
  var s = m == null ? key : (m[GameT.fa ? 'fa' : 'en'] ?? m['en'] ?? key);
  if (p != null) {
    p.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

String _num(int v) {
  if (!GameT.fa) return '$v';
  const d = '۰۱۲۳۴۵۶۷۸۹';
  return '$v'.split('').map((c) => (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ? d[c.codeUnitAt(0) - 48] : c).join();
}

class FruitPage extends StatefulWidget {
  const FruitPage({super.key});

  @override
  State<FruitPage> createState() => _FruitPageState();
}

class _FruitPageState extends State<FruitPage> {
  final GameWallet _w = GameWallet.instance;
  final FruitEngine e = FruitEngine();

  int level = 1;
  int maxLv = 1;
  int moves = 0;
  List<FruitGoal> goals = <FruitGoal>[];
  int score = 0;
  int sel = -1;
  bool busy = false;
  bool over = false;
  bool won = false;
  String msg = '';
  int gained = 0;
  int hammers = 3;
  int extras = 3;
  bool hammerMode = false;
  Set<int> pop = <int>{};
  Set<int> shake = <int>{};
  List<int> drops = List<int>.filled(kFruitN * kFruitN, 0);
  int dropVer = 0;
  List<int>? hint;
  Timer? _hintT;
  int _gen = 0;
  bool _ready = false;
  int _downIdx = -1;
  Offset _downPos = Offset.zero;
  bool _swiped = false;

  @override
  void initState() {
    super.initState();
    GameFx.load().then((_) {
      if (mounted) setState(() {});
    });
    SkinStore.load().then((_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _gen++;
    _hintT?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    var gift = false;
    try {
      final p = await SharedPreferences.getInstance();
      maxLv = p.getInt('fruit_lv') ?? 1;
      hammers = p.getInt('fruit_h') ?? 3;
      extras = p.getInt('fruit_m') ?? 3;
      final d = DateTime.now();
      final day = '${d.year}-${d.month}-${d.day}';
      if (p.getString('fruit_day') != day) {
        await p.setString('fruit_day', day);
        hammers += 2;
        extras += 2;
        gift = true;
        await _save();
      }
    } catch (_) {}
    if (!mounted) return;
    _setup(maxLv);
    if (gift) msg = _ft('gift');
    setState(() => _ready = true);
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('fruit_lv', maxLv);
      await p.setInt('fruit_h', hammers);
      await p.setInt('fruit_m', extras);
    } catch (_) {}
  }

  void _setup(int lv) {
    _gen++;
    level = lv;
    final l = e.setup(lv);
    moves = l.moves;
    goals = l.goals;
    score = 0;
    sel = -1;
    busy = false;
    over = false;
    won = false;
    msg = '';
    gained = 0;
    hammerMode = false;
    pop = <int>{};
    shake = <int>{};
    drops = List<int>.filled(kFruitN * kFruitN, 0);
    hint = null;
    _armHint();
    if (mounted) setState(() {});
  }

  void _armHint() {
    _hintT?.cancel();
    hint = null;
    _hintT = Timer(const Duration(seconds: 6), () {
      if (!mounted || busy || over) return;
      setState(() => hint = e.findHint());
    });
  }

  void _stopHint() {
    hint = null;
    _hintT?.cancel();
  }

  // ---------------------------------------------------------------- منطق

  Future<void> _clear(Set<int> set, List<List<int>> marks, int chain, int gen) async {
    var mk = marks.where((m) => set.contains(m[0])).toList();
    for (final m in mk) {
      set.remove(m[0]);
    }
    e.expand(set);
    mk = mk.where((m) => !set.contains(m[0])).toList();
    pop = Set<int>.of(set);
    GameFx.move();
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || gen != _gen) return;
    var cnt = 0;
    for (final i in set) {
      cnt++;
      for (final g in goals) {
        if (g.f == e.t[i] && g.n > 0) g.n--;
      }
      if (e.ice[i] > 0) {
        e.ice[i]--;
        if (e.ice[i] == 0) {
          for (final g in goals) {
            if (g.f < 0 && g.n > 0) g.n--;
          }
        }
      }
      e.t[i] = -1;
      e.sp[i] = 0;
    }
    for (final m in mk) {
      e.sp[m[0]] = m[1];
    }
    score += cnt * 10 * chain;
    pop = <int>{};
    drops = e.gravity();
    dropVer++;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 340));
    if (!mounted || gen != _gen) return;
    await _step(chain + 1, gen);
  }

  Future<void> _step(int chain, int gen) async {
    final m = e.find(const <int>[]);
    if (!m.isEmpty) {
      if (chain >= 2) msg = _ft('p${min(chain, 4)}');
      await _clear(m.cells, m.marks, chain, gen);
      return;
    }
    _finish();
  }

  void _finish() {
    drops = List<int>.filled(kFruitN * kFruitN, 0);
    if (goals.every((g) => g.n <= 0)) {
      over = true;
      won = true;
      msg = '';
      GameFx.win();
      if (level >= maxLv) {
        maxLv = level + 1;
        _reward();
      }
      if (Random().nextBool()) {
        hammers++;
      } else {
        extras++;
      }
      _save();
    } else if (moves <= 0) {
      over = true;
      msg = _ft('lose');
    } else if (!e.hasMove()) {
      msg = _ft('shuffle');
      e.reshuffle();
    }
    busy = false;
    if (!over) _armHint();
    if (mounted) setState(() {});
  }

  Future<void> _reward() async {
    final g = await _w.reportOffline('win', level < 6 ? 'easy' : 'normal');
    if (!mounted) return;
    setState(() => gained = g);
  }

  Future<void> _trySwap(int a, int b) async {
    if (busy || over || !e.adj(a, b)) return;
    sel = -1;
    busy = true;
    msg = '';
    _stopHint();
    final gen = _gen;
    if (e.sp[a] != 0 && e.sp[b] != 0 && e.sp[a] < 3 && e.sp[b] < 3) {
      // دو ویژهٔ خطی: انفجار صلیبی
      final s = <int>{a, b};
      final r0 = b ~/ kFruitN, c0 = b % kFruitN;
      e.sp[a] = 0;
      e.sp[b] = 0;
      for (var x = 0; x < kFruitN; x++) {
        s.add(r0 * kFruitN + x);
        s.add(x * kFruitN + c0);
      }
      moves--;
      msg = _ft('combo');
      await _clear(s, <List<int>>[], 2, gen);
      return;
    }
    e.swapCells(a, b);
    if (e.sp[a] == 3 || e.sp[b] == 3) {
      final bi = e.sp[a] == 3 ? a : b;
      final oi = bi == a ? b : a;
      final s = <int>{};
      if (e.sp[oi] == 3) {
        for (var k = 0; k < kFruitN * kFruitN; k++) {
          s.add(k);
        }
      } else {
        e.sp[bi] = 0;
        s.add(bi);
        for (var j = 0; j < kFruitN * kFruitN; j++) {
          if (e.t[j] == e.t[oi]) {
            s.add(j);
            if (e.sp[oi] != 0 && j != oi) e.sp[j] = 1 + (j % 2);
          }
        }
      }
      moves--;
      await _clear(s, <List<int>>[], 1, gen);
      return;
    }
    final m = e.find(<int>[a, b]);
    if (m.isEmpty) {
      shake = <int>{a, b};
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted || gen != _gen) return;
      e.swapCells(a, b);
      shake = <int>{};
      busy = false;
      _armHint();
      setState(() {});
      return;
    }
    moves--;
    await _clear(m.cells, m.marks, 1, gen);
  }

  Future<void> _activate(int i) async {
    busy = true;
    sel = -1;
    moves--;
    _stopHint();
    await _clear(<int>{i}, <List<int>>[], 1, _gen);
  }

  Future<void> _hammer(int i) async {
    if (hammers <= 0) {
      setState(() => hammerMode = false);
      return;
    }
    hammers--;
    hammerMode = false;
    busy = true;
    msg = '';
    _stopHint();
    _save();
    await _clear(<int>{i}, <List<int>>[], 1, _gen);
  }

  void _tap(int i) {
    if (busy || over) return;
    if (hammerMode) {
      _hammer(i);
      return;
    }
    if (sel < 0) {
      setState(() => sel = i);
    } else if (sel == i) {
      if (e.sp[i] != 0) {
        _activate(i);
        return;
      }
      setState(() => sel = -1);
    } else if (e.adj(sel, i)) {
      _trySwap(sel, i);
    } else {
      setState(() => sel = i);
    }
  }

  // ---------------------------------------------------------------- لمس

  int _cellAt(Offset p, double sz) {
    final c = (p.dx / sz).floor(), r = (p.dy / sz).floor();
    if (c < 0 || c >= kFruitN || r < 0 || r >= kFruitN) return -1;
    return r * kFruitN + c;
  }

  void _onPanStart(DragStartDetails d, double sz) {
    _downIdx = _cellAt(d.localPosition, sz);
    _downPos = d.localPosition;
    _swiped = false;
  }

  void _onPanUpdate(DragUpdateDetails d, double sz) {
    if (_downIdx < 0 || _swiped) return;
    final dx = d.localPosition.dx - _downPos.dx, dy = d.localPosition.dy - _downPos.dy;
    if (max(dx.abs(), dy.abs()) < sz * 0.3) return;
    _swiped = true;
    final r = _downIdx ~/ kFruitN, c = _downIdx % kFruitN;
    var to = -1;
    if (dx.abs() > dy.abs()) {
      final nc = c + (dx > 0 ? 1 : -1);
      if (nc >= 0 && nc < kFruitN) to = r * kFruitN + nc;
    } else {
      final nr = r + (dy > 0 ? 1 : -1);
      if (nr >= 0 && nr < kFruitN) to = nr * kFruitN + c;
    }
    if (to >= 0 && !hammerMode) _trySwap(_downIdx, to);
  }

  // ---------------------------------------------------------------- رابط

  Widget _tile(int i, double sz) {
    final r = i ~/ kFruitN, c = i % kFruitN;
    final fs = kFruitSkins[SkinStore.idx('fruit', kFruitSkins.length)];
    final base = (r + c) % 2 == 0 ? fs.a : fs.b;
    final v = e.t[i];
    final sp = e.sp[i];
    final isPop = pop.contains(i);
    final isHint = hint != null && (hint![0] == i || hint![1] == i);
    final d = drops[i];
    Widget fruit = Text(
      v >= 0 ? _fruits[v] : '',
      style: TextStyle(fontSize: sz * 0.66, height: 1, shadows: const <Shadow>[Shadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2))]),
    );
    if (isHint) {
      fruit = TweenAnimationBuilder<double>(
        key: ValueKey<String>('h$i${hint![0]}'),
        tween: Tween<double>(begin: 1, end: 1.25),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (ctx, s, child) => Transform.scale(scale: s, child: child),
        child: fruit,
      );
    }
    if (d > 0) {
      fruit = TweenAnimationBuilder<double>(
        key: ValueKey<String>('d$i$dropVer'),
        tween: Tween<double>(begin: -d.toDouble(), end: 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        builder: (ctx, y, child) => Transform.translate(offset: Offset(0, y * sz), child: child),
        child: fruit,
      );
    }
    if (shake.contains(i)) {
      fruit = TweenAnimationBuilder<double>(
        key: ValueKey<String>('s$i'),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (ctx, t, child) => Transform.translate(offset: Offset(sin(t * pi * 4) * 6, 0), child: child),
        child: fruit,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tap(i),
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: base,
          border: i == sel ? Border.all(color: gGold, width: 3) : null,
          boxShadow: sp == 3 ? const <BoxShadow>[BoxShadow(color: Colors.white, blurRadius: 12, spreadRadius: -2)] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedScale(scale: isPop ? 1.6 : 1, duration: const Duration(milliseconds: 260), child: AnimatedOpacity(opacity: isPop ? 0 : 1, duration: const Duration(milliseconds: 260), child: fruit)),
            if (sp == 1 || sp == 2)
              Positioned(
                bottom: 1,
                right: 3,
                child: Text(sp == 1 ? '↔' : '↕', style: TextStyle(fontSize: sz * 0.3, fontWeight: FontWeight.w900, color: Colors.white, shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 4)])),
              ),
            if (sp == 3) Positioned(top: 1, left: 3, child: Text('✨', style: TextStyle(fontSize: sz * 0.28))),
            if (e.ice[i] > 0)
              Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: Color(e.ice[i] == 2 ? 0x997cc4ff : 0x88bfe6ff),
                  border: Border.all(color: Colors.white, width: e.ice[i] == 2 ? 3 : 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, {bool ok = false, VoidCallback? onTap, bool on = false}) {
    final c = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: on ? gGold : gPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: ok ? gTeal : gLine, width: 1.5)),
      child: Text(text, style: TextStyle(color: on ? gBg : (ok ? gTeal : Colors.white), fontWeight: FontWeight.w900, fontSize: 14)),
    );
    return onTap == null ? c : GestureDetector(onTap: onTap, child: c);
  }

  Widget _board(double w) {
    final sz = w / kFruitN;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onPanStart: (d) => _onPanStart(d, sz),
        onPanUpdate: (d) => _onPanUpdate(d, sz),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: kFruitSkins[SkinStore.idx('fruit', kFruitSkins.length)].border, width: 3), borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < kFruitN; r++) Row(mainAxisSize: MainAxisSize.min, children: [for (var c = 0; c < kFruitN; c++) _tile(r * kFruitN + c, sz)]),
              ],
            ),
          ),
        ),
      ),
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
          title: Text(_ft('title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          actions: [
            skinAction(() => showSkinSheet(context, game: 'fruit', title: 'طرح صفحه میوه‌چین', names: <String>[for (final k in kFruitSkins) k.name], prices: <int>[for (final k in kFruitSkins) k.price], preview: fruitPreview, onChanged: () => setState(() {}))),
            gameFxAction(() => setState(() {})),
          ],
        ),
        body: SafeArea(
          child: !_ready
              ? const Center(child: CircularProgressIndicator(color: gGold))
              : LayoutBuilder(
                  builder: (ctx, cons) {
                    final avail = min(cons.maxWidth - 24, 420.0);
                    final w = ((avail - 8) / kFruitN).floorToDouble() * kFruitN;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      child: Center(
                        child: SizedBox(
                          width: avail,
                          child: Column(
                            children: [
                              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                                _chip(_ft('level', <String, String>{'n': _num(level)})),
                                _chip(_ft('moves', <String, String>{'n': _num(moves)})),
                                _chip(_ft('score', <String, String>{'n': _num(score)})),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
                                for (final g in goals) _chip('${g.f < 0 ? '🧊' : _fruits[g.f]} ${g.n <= 0 ? '✓' : _num(g.n)}', ok: g.n <= 0),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                                _chip('🔨 ${_num(hammers)}', on: hammerMode, onTap: () {
                                  if (busy || over || hammers <= 0) return;
                                  setState(() {
                                    hammerMode = !hammerMode;
                                    msg = hammerMode ? _ft('hammer') : '';
                                  });
                                }),
                                _chip('${_ft('extra')} · ${_num(extras)}', onTap: () {
                                  if (busy || over || extras <= 0) return;
                                  setState(() {
                                    extras--;
                                    moves += 3;
                                  });
                                  _save();
                                }),
                              ]),
                              const SizedBox(height: 10),
                              Center(child: _board(w)),
                              SizedBox(
                                height: 88,
                                child: Center(
                                  child: over
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(won ? '🎉 ${_ft('win')}${gained > 0 ? '  🪙 +${_num(gained)}' : ''}' : msg, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
                                            FilledButton(
                                              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                                              onPressed: () => _setup(won ? level + 1 : level),
                                              child: Text(won ? _ft('next') : _ft('retry'), style: const TextStyle(fontWeight: FontWeight.w900)),
                                            ),
                                          ],
                                        )
                                      : Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_ft('help'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.8)),
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
