import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/group_ui.dart';

/// امتیازدهی حرفه‌ای تخته‌نرد: گمون، بک‌گمون، شمارش پیپ، مسابقه تا چند امتیاز و آمار کلی.
///
/// قرارداد صفحه‌ی بازی: بازیکن ۰ از خانه‌ی ۲۳ به ۰ می‌رود (خانه‌ی خودش ۰ تا ۵)،
/// بازیکن ۱ از ۰ به ۲۳ (خانه‌ی خودش ۱۸ تا ۲۳). مهره‌ی مثبت = بازیکن ۰، منفی = بازیکن ۱.

enum BgWinKind { single, gammon, backgammon }

class BgGameResult {
  BgGameResult({required this.winner, required this.kind, required this.points, required this.loserPips, required this.cube});

  final int winner;
  final BgWinKind kind;

  /// امتیاز این بازی برای برنده (۱، ۲ یا ۳ برابر مکعب)
  final int points;

  /// پیپ باقی‌مانده‌ی بازنده در لحظه‌ی پایان
  final int loserPips;
  final int cube;

  String get kindLabel => kind == BgWinKind.single ? 'برد ساده' : (kind == BgWinKind.gammon ? 'گمون' : 'بک‌گمون');
}

class BgScoring {
  BgScoring._();

  /// شمارش پیپ (فاصله‌ی باقی‌مانده تا خروج همه‌ی مهره‌ها)
  static int pips(List<int> pts, List<int> bar, int p) {
    var sum = bar[p] * 25;
    for (var i = 0; i < 24; i++) {
      final c = pts[i];
      if (p == 0 && c > 0) sum += c * (i + 1);
      if (p == 1 && c < 0) sum += (-c) * (24 - i);
    }
    return sum;
  }

  /// نتیجه‌ی بازی: برد ساده ×۱، گمون ×۲ (بازنده هیچ مهره‌ای بیرون نبرده)،
  /// بک‌گمون ×۳ (گمون است و بازنده مهره‌ای روی میله یا در خانه‌ی برنده دارد).
  static BgGameResult score(List<int> pts, List<int> bar, List<int> off, int winner, {int cube = 1}) {
    final loser = 1 - winner;
    var kind = BgWinKind.single;
    if (off[loser] == 0) {
      kind = BgWinKind.gammon;
      var back = bar[loser] > 0;
      for (var i = 0; i < 24 && !back; i++) {
        // خانه‌ی برنده: بازیکن ۰ → ۰..۵ ؛ بازیکن ۱ → ۱۸..۲۳
        final inWinnerHome = winner == 0 ? i <= 5 : i >= 18;
        if (!inWinnerHome) continue;
        if (loser == 1 && pts[i] < 0) back = true;
        if (loser == 0 && pts[i] > 0) back = true;
      }
      if (back) kind = BgWinKind.backgammon;
    }
    final mult = kind == BgWinKind.single ? 1 : (kind == BgWinKind.gammon ? 2 : 3);
    return BgGameResult(winner: winner, kind: kind, points: mult * cube, loserPips: pips(pts, bar, loser), cube: cube);
  }
}

/// مسابقه‌ی چند بازی تا رسیدن به امتیاز هدف. [to] صفر یعنی بازی‌ها فقط جمع می‌شوند و پایانی ندارند.
class BgMatch {
  BgMatch({this.to = 0});

  int to;
  final List<int> scores = <int>[0, 0];
  final List<BgGameResult> games = <BgGameResult>[];

  void add(BgGameResult r) {
    games.add(r);
    scores[r.winner] += r.points;
  }

  bool get over => to > 0 && (scores[0] >= to || scores[1] >= to);
  int get winner => !over ? -1 : (scores[0] > scores[1] ? 0 : 1);

  /// قانون کرافورد: وقتی یک نفر یک امتیاز مانده تا هدف، بازی بعد مکعب ندارد (اینجا فقط نمایش داده می‌شود)
  bool get crawford {
    if (to < 3 || over) return false;
    final lead = scores[0] >= to - 1 ? 0 : (scores[1] >= to - 1 ? 1 : -1);
    if (lead < 0) return false;
    // فقط بازی‌ای که درست بعد از رسیدن به «یک امتیاز مانده» انجام می‌شود
    if (games.isEmpty) return false;
    final before = scores[lead] - (games.last.winner == lead ? games.last.points : 0);
    return before < to - 1;
  }

  void reset() {
    games.clear();
    scores[0] = 0;
    scores[1] = 0;
  }
}

/// آمار کلی بازیکن (روی همان گوشی ذخیره می‌شود)
class BgStats extends ChangeNotifier {
  BgStats._();
  static final BgStats instance = BgStats._();
  static const String _k = 'bg_stats_v1';

  int games = 0;
  int wins = 0;
  int losses = 0;
  int gammonWins = 0;
  int backgammonWins = 0;
  int gammonLosses = 0;
  int backgammonLosses = 0;
  int points = 0; // مجموع امتیاز برنده‌شده
  int pointsLost = 0;
  int streak = 0;
  int bestStreak = 0;
  int matchesWon = 0;
  int matchesLost = 0;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      int g(String k) => (m[k] as num?)?.toInt() ?? 0;
      games = g('games');
      wins = g('wins');
      losses = g('losses');
      gammonWins = g('gw');
      backgammonWins = g('bw');
      gammonLosses = g('gl');
      backgammonLosses = g('bl');
      points = g('pts');
      pointsLost = g('ptl');
      streak = g('streak');
      bestStreak = g('best');
      matchesWon = g('mw');
      matchesLost = g('ml');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode(<String, dynamic>{'games': games, 'wins': wins, 'losses': losses, 'gw': gammonWins, 'bw': backgammonWins, 'gl': gammonLosses, 'bl': backgammonLosses, 'pts': points, 'ptl': pointsLost, 'streak': streak, 'best': bestStreak, 'mw': matchesWon, 'ml': matchesLost}),
      );
    } catch (_) {}
  }

  /// ثبت نتیجه‌ی یک بازی؛ [me] صندلی خود بازیکن (۰ یا ۱)
  void record(BgGameResult r, int me) {
    games++;
    if (r.winner == me) {
      wins++;
      points += r.points;
      streak++;
      if (streak > bestStreak) bestStreak = streak;
      if (r.kind == BgWinKind.gammon) gammonWins++;
      if (r.kind == BgWinKind.backgammon) backgammonWins++;
    } else {
      losses++;
      pointsLost += r.points;
      streak = 0;
      if (r.kind == BgWinKind.gammon) gammonLosses++;
      if (r.kind == BgWinKind.backgammon) backgammonLosses++;
    }
    _save();
  }

  void recordMatch(bool won) {
    if (won) {
      matchesWon++;
    } else {
      matchesLost++;
    }
    _save();
  }

  Future<void> clear() async {
    games = wins = losses = gammonWins = backgammonWins = gammonLosses = backgammonLosses = points = pointsLost = streak = bestStreak = matchesWon = matchesLost = 0;
    await _save();
  }

  double get winRate => games == 0 ? 0 : wins * 100 / games;
}

String bgFa(num n) => n.toString().replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

// ---------------------------------------------------------------------------
// ابزارک‌ها

/// نوار امتیاز مسابقه و پیپ‌ها بالای تخته
class BgScoreStrip extends StatelessWidget {
  const BgScoreStrip({super.key, required this.match, required this.names, required this.pipA, required this.pipB, required this.showPip, required this.turn});

  final BgMatch match;
  final List<String> names;
  final int pipA;
  final int pipB;
  final bool showPip;
  final int turn;

  Widget _side(int i, int pip) {
    final active = turn == i;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0x33ffd36a) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? gGold : gLine),
        ),
        child: Column(
          children: [
            Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? gGold : Colors.white70, fontWeight: FontWeight.w800, fontSize: 12)),
            Text(bgFa(match.scores[i]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, height: 1.15)),
            if (showPip) Text('پیپ ${bgFa(pip)}', style: const TextStyle(color: gMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _side(0, pipA),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(match.to == 0 ? 'جمع امتیاز' : 'تا ${bgFa(match.to)}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 12)),
                Text('بازی ${bgFa(match.games.length + 1)}', style: const TextStyle(color: gMuted, fontSize: 10.5)),
                if (match.crawford) const Text('کرافورد', style: TextStyle(color: gSky, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          _side(1, pipB),
        ],
      ),
    );
  }
}

/// کارت نتیجه‌ی بازی پس از پایان: نوع برد، امتیاز و وضعیت مسابقه
class BgResultCard extends StatelessWidget {
  const BgResultCard({super.key, required this.result, required this.match, required this.names});

  final BgGameResult result;
  final BgMatch match;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final color = r.kind == BgWinKind.single ? gTeal : (r.kind == BgWinKind.gammon ? gGold : const Color(0xffff8a65));
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: color, width: 1.5)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(.18), borderRadius: BorderRadius.circular(10)),
                child: Text(r.kindLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('${names[r.winner]} ${bgFa(r.points)} امتیاز گرفت', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('پیپ باقی‌مانده‌ی بازنده: ${bgFa(r.loserPips)}', style: const TextStyle(color: gMuted, fontSize: 12)),
          ),
          if (match.to > 0) ...<Widget>[
            const Divider(color: gLine, height: 16),
            Text(
              match.over ? '${names[match.winner]} مسابقه را برد (${bgFa(match.scores[match.winner])} به ${bgFa(match.scores[1 - match.winner])})' : 'وضعیت مسابقه: ${bgFa(match.scores[0])} به ${bgFa(match.scores[1])}، تا ${bgFa(match.to)}',
              style: TextStyle(color: match.over ? gGold : gSky, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
          if (match.games.length > 1) ...<Widget>[
            const SizedBox(height: 8),
            BgHistoryTable(match: match, names: names),
          ],
        ],
      ),
    );
  }
}

/// جدول بازی‌های این مسابقه
class BgHistoryTable extends StatelessWidget {
  const BgHistoryTable({super.key, required this.match, required this.names});
  final BgMatch match;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final run = <int>[0, 0];
    final rows = <TableRow>[
      TableRow(children: <Widget>[
        for (final h in <String>['بازی', 'برنده', 'نوع', names[0], names[1]]) Padding(padding: const EdgeInsets.all(4), child: Text(h, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontSize: 11, fontWeight: FontWeight.w900))),
      ]),
    ];
    for (var i = 0; i < match.games.length; i++) {
      final g = match.games[i];
      run[g.winner] += g.points;
      Widget c(String t, {bool bold = false}) => Padding(padding: const EdgeInsets.all(4), child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: bold ? FontWeight.w900 : FontWeight.w500)));
      rows.add(TableRow(children: <Widget>[c(bgFa(i + 1)), c(names[g.winner]), c(g.kindLabel), c(bgFa(run[0]), bold: g.winner == 0), c(bgFa(run[1]), bold: g.winner == 1)]));
    }
    return Table(border: TableBorder.all(color: gLine, borderRadius: BorderRadius.circular(8)), children: rows);
  }
}

/// آمار کلی بازیکن
class BgStatsView extends StatelessWidget {
  const BgStatsView({super.key, this.dark = true});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = BgStats.instance;
    final fg = dark ? Colors.white : Colors.black87;
    Widget cell(String t, String v) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: dark ? gPanel : Colors.white70, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? gLine : Colors.black12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(v, style: TextStyle(color: dark ? gGold : const Color(0xff7a4a00), fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 2),
              Text(t, textAlign: TextAlign.center, style: TextStyle(color: fg.withOpacity(.75), fontSize: 11.5)),
            ],
          ),
        );
    final items = <List<String>>[
      <String>['بازی', bgFa(s.games)],
      <String>['برد', bgFa(s.wins)],
      <String>['باخت', bgFa(s.losses)],
      <String>['درصد برد', '${bgFa(s.winRate.round())}٪'],
      <String>['گمون زده', bgFa(s.gammonWins)],
      <String>['بک‌گمون زده', bgFa(s.backgammonWins)],
      <String>['گمون خورده', bgFa(s.gammonLosses)],
      <String>['بک‌گمون خورده', bgFa(s.backgammonLosses)],
      <String>['امتیاز گرفته', bgFa(s.points)],
      <String>['امتیاز از دست رفته', bgFa(s.pointsLost)],
      <String>['برد پشت سر هم', bgFa(s.streak)],
      <String>['بهترین رشته‌ی برد', bgFa(s.bestStreak)],
      <String>['مسابقه‌ی برده', bgFa(s.matchesWon)],
      <String>['مسابقه‌ی باخته', bgFa(s.matchesLost)],
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.35,
      children: [for (final it in items) cell(it[0], it[1])],
    );
  }
}
