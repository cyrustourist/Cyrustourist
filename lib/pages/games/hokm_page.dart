import 'dart:math';

import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'game_api.dart';
import 'game_engine.dart' show BotLevel;
import 'game_fx.dart';
import 'game_texts.dart';
import 'game_widgets.dart';
import 'hokm_engine.dart';

/// بازی «حکم» چهار نفره: شما + یک ربات هم‌تیمی در برابر دو ربات حریف.
/// بدون اینترنت کار می‌کند؛ پایان بازی با [GameWallet.reportOffline] سکه می‌دهد.

const int kHokmTarget = 7;

const Map<String, Map<String, String>> _htx = {
  'choose_trump': {'fa': 'حکم را انتخاب کنید', 'en': 'Choose the trump suit'},
  'first5': {'fa': 'این پنج کارت اول شماست؛ بعد از انتخاب حکم بقیه کارت‌ها پخش می‌شود', 'en': 'These are your first five cards; the rest are dealt after you pick'},
  'hakem_is': {'fa': '{n} حاکم است', 'en': '{n} is the Hakem'},
  'bot_picking': {'fa': '{n} حکم را انتخاب می‌کند…', 'en': '{n} is choosing trump…'},
  'trump': {'fa': 'حکم', 'en': 'Trump'},
  's0': {'fa': 'پیک', 'en': 'Spades'},
  's1': {'fa': 'دل', 'en': 'Hearts'},
  's2': {'fa': 'خشت', 'en': 'Diamonds'},
  's3': {'fa': 'گیشنیز', 'en': 'Clubs'},
  'us': {'fa': 'ما', 'en': 'Us'},
  'them': {'fa': 'حریف', 'en': 'Them'},
  'seat1': {'fa': 'حریف چپ', 'en': 'Left'},
  'seat2': {'fa': 'هم‌تیمی', 'en': 'Partner'},
  'seat3': {'fa': 'حریف راست', 'en': 'Right'},
  'trick_won': {'fa': '{n} این دست را برد', 'en': '{n} won the trick'},
  'tricks': {'fa': 'دست‌ها', 'en': 'Tricks'},
  'points': {'fa': 'امتیاز', 'en': 'Points'},
  'hand_won': {'fa': 'این دور را بردید! +{p} امتیاز', 'en': 'You won the round! +{p}'},
  'hand_lost': {'fa': 'حریف این دور را برد (+{p} امتیاز)', 'en': 'They won the round (+{p})'},
  'kot': {'fa': 'کُت!', 'en': 'Whitewash!'},
  'hakem_kot': {'fa': 'کُت حاکم!', 'en': 'Hakem whitewash!'},
  'next_hand': {'fa': 'دور بعد', 'en': 'Next round'},
  'target': {'fa': 'بازی تا {n} امتیاز', 'en': 'First to {n} points'},
  'follow': {'fa': 'باید هم‌خال زمین بازی کنید', 'en': 'You must follow suit'},
};

String _ht(String key, [Map<String, String>? p]) {
  final m = _htx[key];
  var s = m == null ? key : (m[GameT.fa ? 'fa' : 'en'] ?? m['en'] ?? key);
  if (p != null) {
    p.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

enum _Phase { choose, play, trickEnd, handEnd, gameEnd }

class HokmPage extends StatefulWidget {
  const HokmPage({super.key, required this.level});
  final BotLevel level;

  @override
  State<HokmPage> createState() => _HokmPageState();
}

class _HokmPageState extends State<HokmPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  late final HokmBot _bot = HokmBot(widget.level, _rnd);

  late HokmHand h;
  List<HCard> _five = <HCard>[];
  final List<int> score = <int>[0, 0];
  int hakem = 0;
  _Phase phase = _Phase.choose;
  int _gen = 0;
  String msg = '';
  int _lastPoints = 0;
  int _lastWinnerTeam = 0;
  bool _lastKot = false;
  bool _lastHakemKot = false;
  int gained = 0;
  bool resultReady = false;

  String _seatName(int s) {
    switch (s) {
      case 0:
        return GameT.t('you');
      default:
        return _ht('seat$s');
    }
  }

  @override
  void initState() {
    super.initState();
    GameFx.load().then((_) {
      if (mounted) setState(() {});
    });
    hakem = _rnd.nextInt(4);
    _newHand();
  }

  @override
  void dispose() {
    _gen++;
    super.dispose();
  }

  void _later(int ms, VoidCallback f) {
    final g = _gen;
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (!mounted || g != _gen) return;
      f();
    });
  }

  void _sortMine() {
    final t = h.trump;
    h.hands[0].sort((a, b) {
      if (a.suit != b.suit) {
        if (a.suit == t) return -1;
        if (b.suit == t) return 1;
        return a.suit.compareTo(b.suit);
      }
      return b.rank.compareTo(a.rank);
    });
  }

  void _newHand() {
    _gen++;
    h = HokmHand(hakem: hakem, rnd: _rnd);
    _five = h.hakemFirstFive();
    phase = _Phase.choose;
    msg = _ht('hakem_is', <String, String>{'n': _seatName(hakem)});
    if (hakem == 0) {
      setState(() {});
      return;
    }
    // حاکم ربات است
    _sortMineAfterTrumpUnknown();
    setState(() => msg = _ht('bot_picking', <String, String>{'n': _seatName(hakem)}));
    _later(1100, () => _setTrump(_bot.pickTrump(_five)));
  }

  void _sortMineAfterTrumpUnknown() {
    // پیش از انتخاب حکم، دست شما فقط بر اساس خال و ارزش مرتب می‌شود
    _sortMine();
  }

  void _setTrump(int suit) {
    h.trump = suit;
    _sortMine();
    phase = _Phase.play;
    msg = '${_ht('trump')}: ${kSuitChar[suit]} ${_ht('s$suit')}';
    setState(() {});
    _afterTurnChange();
  }

  void _afterTurnChange() {
    if (phase != _Phase.play) return;
    if (h.trickFull) return;
    if (h.turn == 0) {
      setState(() {});
      return;
    }
    final g = _gen;
    _later(750, () {
      if (g != _gen || phase != _Phase.play || h.trickFull || h.turn == 0) return;
      final seat = h.turn;
      final c = _bot.choose(h, seat);
      _doPlay(seat, c);
    });
  }

  void _doPlay(int seat, HCard c) {
    final cutting = h.trick.isNotEmpty && c.suit == h.trump && h.leadSuit != h.trump;
    if (!h.play(seat, c)) return;
    if (cutting) {
      GameFx.hit();
    } else {
      GameFx.move();
    }
    setState(() {});
    if (h.trickFull) {
      phase = _Phase.trickEnd;
      final w = h.currentWinnerSeat();
      setState(() => msg = _ht('trick_won', <String, String>{'n': _seatName(w)}));
      _later(1300, _endTrick);
    } else {
      _afterTurnChange();
    }
  }

  void _endTrick() {
    h.resolveTrick();
    if (h.finished) {
      _endHand();
      return;
    }
    phase = _Phase.play;
    msg = '';
    setState(() {});
    _afterTurnChange();
  }

  void _endHand() {
    final wt = h.winnerTeam;
    final loserTricks = h.tricksWon[1 - wt];
    final pts = hokmHandPoints(winnerTeam: wt, loserTricks: loserTricks, hakem: h.hakem);
    score[wt] += pts;
    _lastPoints = pts;
    _lastWinnerTeam = wt;
    _lastKot = loserTricks == 0;
    _lastHakemKot = _lastKot && hokmTeamOf(h.hakem) != wt;
    hakem = hokmNextHakem(h.hakem, wt);
    if (wt == 0) {
      GameFx.win();
    } else {
      GameFx.hit();
    }
    if (score[0] >= kHokmTarget || score[1] >= kHokmTarget) {
      phase = _Phase.gameEnd;
      setState(() {});
      _finishGame();
    } else {
      phase = _Phase.handEnd;
      setState(() {});
    }
  }

  Future<void> _finishGame() async {
    final win = score[0] >= kHokmTarget;
    final g = await _w.reportOffline(win ? 'win' : 'loss', widget.level.name);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  void _restartGame() {
    _gen++;
    score[0] = 0;
    score[1] = 0;
    gained = 0;
    resultReady = false;
    hakem = _rnd.nextInt(4);
    _newHand();
  }

  void _tapCard(HCard c) {
    if (phase != _Phase.play || h.turn != 0 || h.trickFull) return;
    if (!h.legal(0).contains(c)) {
      setState(() => msg = _ht('follow'));
      return;
    }
    msg = '';
    _doPlay(0, c);
  }

  // ------------------------------------------------------------ ظاهر

  Widget _face(HCard c, double w, {bool dim = false, bool glow = false, VoidCallback? onTap}) {
    final col = c.red ? const Color(0xffd62839) : const Color(0xff1b1f2a);
    final card = Container(
      width: w,
      height: w * 1.42,
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: dim ? const Color(0xffbfc6cc) : Colors.white,
        borderRadius: BorderRadius.circular(w * 0.14),
        border: Border.all(color: glow ? gGold : const Color(0xff9aa5ad), width: glow ? 2 : 1),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(c.rankLabel, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * 0.34, height: 1)),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(kSuitChar[c.suit], style: TextStyle(color: col, fontSize: w * 0.62, height: 1)),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _back(double w) {
    return Container(
      width: w,
      height: w * 1.42,
      decoration: BoxDecoration(
        color: const Color(0xff12506b),
        borderRadius: BorderRadius.circular(w * 0.14),
        border: Border.all(color: gGold, width: 1),
      ),
      child: Center(child: Text('♠', style: TextStyle(color: gGold, fontSize: w * 0.5))),
    );
  }

  Widget _scoreBar() {
    Widget chip(String label, int pts, int tr, bool us) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          decoration: BoxDecoration(
            color: gPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: us ? gTeal : gLine),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: us ? gTeal : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13)),
              Text('${_ht('points')} $pts · ${_ht('tricks')} $tr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_ht('us'), score[0], h.tricksWon[0], true),
        const SizedBox(width: 8),
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: gGold)),
          child: Column(
            children: [
              Text(h.trump < 0 ? '?' : kSuitChar[h.trump], style: TextStyle(color: h.trump == 1 || h.trump == 2 ? const Color(0xffff6b6b) : Colors.white, fontSize: 22, height: 1.1)),
              Text(_ht('trump'), style: const TextStyle(color: gMuted, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        chip(_ht('them'), score[1], h.tricksWon[1], false),
      ],
    );
  }

  Widget _opponentBadge(int seat, double cw) {
    final n = h.hands[seat].length;
    final active = phase == _Phase.play && h.turn == seat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: gPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? gGold : gLine, width: active ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_seatName(seat)}${seat == h.hakem ? ' 👑' : ''}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          _back(cw),
          const SizedBox(height: 2),
          Text('×$n', style: const TextStyle(color: gMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _trickArea(double w) {
    final cw = min(46.0, w * 0.18);
    final boxH = cw * 1.42 * 2 + 40;
    HCard? cardOf(int seat) {
      for (final p in h.trick) {
        if (p.seat == seat) return p.card;
      }
      return null;
    }

    Widget slot(int seat, Alignment al) {
      final c = cardOf(seat);
      return Align(
        alignment: al,
        child: c == null ? SizedBox(width: cw, height: cw * 1.42) : _face(c, cw, glow: phase == _Phase.trickEnd && h.currentWinnerSeat() == seat),
      );
    }

    return SizedBox(
      height: boxH,
      child: Stack(
        children: [
          slot(2, Alignment.topCenter),
          slot(1, const Alignment(-0.75, 0)),
          slot(3, const Alignment(0.75, 0)),
          slot(0, Alignment.bottomCenter),
        ],
      ),
    );
  }

  Widget _myHand(double w) {
    // تا حاکم حکم را انتخاب نکرده کارت‌ها پخش نشده‌اند
    if (h.trump < 0) return const SizedBox(height: 120);
    final cw = ((w - 6 * 4 - 1) / 7).floorToDouble().clamp(30.0, 58.0).toDouble();
    final legal = (phase == _Phase.play && h.turn == 0 && !h.trickFull) ? h.legal(0) : <HCard>[];
    final myTurn = legal.isNotEmpty;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: [
        for (final c in h.hands[0])
          _face(
            c,
            cw,
            dim: myTurn && !legal.contains(c),
            glow: myTurn && legal.contains(c) && h.trick.isEmpty,
            onTap: () => _tapCard(c),
          ),
      ],
    );
  }

  Widget _trumpPicker(double w) {
    final cw = ((w - 4 * 4 - 1) / 5).floorToDouble().clamp(34.0, 62.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: gGold)),
      child: Column(
        children: [
          Text(_ht('choose_trump'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text(_ht('first5'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12, height: 1.6)),
          const SizedBox(height: 10),
          Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 6, children: [for (final c in _five) _face(c, cw)]),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var s = 0; s < 4; s++) ...[
                if (s > 0) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: gBg,
                      foregroundColor: (s == 1 || s == 2) ? const Color(0xffff6b6b) : Colors.white,
                      side: const BorderSide(color: gLine),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _setTrump(s),
                    child: Column(
                      children: [
                        Text(kSuitChar[s], style: const TextStyle(fontSize: 26, height: 1.1)),
                        Text(_ht('s$s'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: gGold)),
        child: child,
      );

  Widget _handEndCard() {
    final us = _lastWinnerTeam == 0;
    final title = us ? _ht('hand_won', <String, String>{'p': '$_lastPoints'}) : _ht('hand_lost', <String, String>{'p': '$_lastPoints'});
    return _card(
      Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: us ? gTeal : const Color(0xffff6b6b), fontWeight: FontWeight.w900, fontSize: 16)),
          if (_lastKot)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_lastHakemKot ? _ht('hakem_kot') : _ht('kot'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
            ),
          const SizedBox(height: 4),
          Text('${_ht('us')} ${score[0]} - ${score[1]} ${_ht('them')}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
              onPressed: _newHand,
              child: Text(_ht('next_hand'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameEndCard() {
    final win = score[0] >= kHokmTarget;
    return _card(
      Column(
        children: [
          Text(win ? GameT.t('you_win') : GameT.t('you_lose'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 19)),
          const SizedBox(height: 2),
          Text('${_ht('us')} ${score[0]} - ${score[1]} ${_ht('them')}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            !resultReady ? '…' : (gained > 0 ? '🪙 ${GameT.t('gained', <String, String>{'n': '$gained'})}' : GameT.t('no_reward')),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                  onPressed: _restartGame,
                  child: Text(GameT.t('play_again'), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(GameT.t('back')),
                ),
              ),
            ],
          ),
        ],
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
          title: Text(GameT.t('hokm'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          actions: [gameFxAction(() => setState(() {}))],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final w = min(cons.maxWidth - 24, 520.0);
              final bc = min(34.0, w * 0.09);
              final choosing = phase == _Phase.choose && hakem == 0;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Center(
                  child: SizedBox(
                    width: w,
                    child: Column(
                      children: [
                        _scoreBar(),
                        const SizedBox(height: 4),
                        Text(_ht('target', <String, String>{'n': '$kHokmTarget'}), style: const TextStyle(color: gMuted, fontSize: 11)),
                        const SizedBox(height: 8),
                        if (choosing)
                          _trumpPicker(w)
                        else ...[
                          Center(child: _opponentBadge(2, bc)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _opponentBadge(1, bc),
                              Expanded(child: _trickArea(w - 2 * (bc + 24))),
                              _opponentBadge(3, bc),
                            ],
                          ),
                          SizedBox(
                            height: 26,
                            child: Center(
                              child: Text(
                                phase == _Phase.play && h.turn == 0 && msg.isEmpty ? GameT.t('your_turn') : msg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _myHand(w),
                          if (phase == _Phase.handEnd) _handEndCard(),
                          if (phase == _Phase.gameEnd) _gameEndCard(),
                        ],
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
