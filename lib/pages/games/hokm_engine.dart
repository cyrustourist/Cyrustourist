import 'dart:math';

import 'game_engine.dart' show BotLevel;

/// موتور بازی «حکم» (چهار نفره، دو تیم): بدون وابستگی به فلاتر و قابل تست.
/// صندلی‌ها: ۰ = شما، ۱ = حریف سمت چپ، ۲ = هم‌تیمی، ۳ = حریف سمت راست.
/// تیم ۰ = صندلی ۰ و ۲ ؛ تیم ۱ = صندلی ۱ و ۳.

/// خال‌ها: ۰ پیک ♠، ۱ دل ♥، ۲ خشت ♦، ۳ گیشنیز ♣
const List<String> kSuitChar = <String>['♠', '♥', '♦', '♣'];

class HCard {
  const HCard(this.suit, this.rank);
  final int suit; // 0..3
  final int rank; // 2..14 (۱۱ سرباز، ۱۲ بی‌بی، ۱۳ شاه، ۱۴ آس)

  bool get red => suit == 1 || suit == 2;

  String get rankLabel {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return '$rank';
    }
  }

  int get id => suit * 20 + rank;

  @override
  bool operator ==(Object other) => other is HCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => id;

  @override
  String toString() => '$rankLabel${kSuitChar[suit]}';
}

List<HCard> hokmFullDeck() => <HCard>[
      for (var s = 0; s < 4; s++)
        for (var r = 2; r <= 14; r++) HCard(s, r),
    ];

int hokmTeamOf(int seat) => seat % 2;

class HokmPlay {
  const HokmPlay(this.seat, this.card);
  final int seat;
  final HCard card;
}

/// وضعیت یک دست (۱۳ حرکت)
class HokmHand {
  HokmHand({required this.hakem, Random? rnd}) {
    final r = rnd ?? Random();
    final deck = hokmFullDeck()..shuffle(r);
    for (var s = 0; s < 4; s++) {
      hands[s] = deck.sublist(s * 13, s * 13 + 13);
    }
    turn = hakem;
    leader = hakem;
  }

  final int hakem;
  final List<List<HCard>> hands = List<List<HCard>>.generate(4, (_) => <HCard>[]);

  /// خال حکم؛ تا وقتی حاکم انتخاب نکرده -1
  int trump = -1;
  int turn = 0;
  int leader = 0;
  final List<HokmPlay> trick = <HokmPlay>[];
  final List<int> tricksWon = <int>[0, 0]; // برای هر تیم
  final Set<int> played = <int>{}; // شناسه‌ی کارت‌های بازی‌شده
  int tricksPlayed = 0;

  /// پنج کارت اول حاکم (برای انتخاب حکم)
  List<HCard> hakemFirstFive() => hands[hakem].sublist(0, 5);

  bool get finished => tricksWon[0] >= 7 || tricksWon[1] >= 7;
  int get winnerTeam => tricksWon[0] >= 7 ? 0 : (tricksWon[1] >= 7 ? 1 : -1);
  bool get trickFull => trick.length == 4;

  int get leadSuit => trick.isEmpty ? -1 : trick.first.card.suit;

  /// کارت‌های مجاز برای یک صندلی
  List<HCard> legal(int seat) {
    final h = hands[seat];
    if (trick.isEmpty) return List<HCard>.of(h);
    final follow = h.where((c) => c.suit == leadSuit).toList();
    return follow.isNotEmpty ? follow : List<HCard>.of(h);
  }

  /// برنده‌ی میز فعلی (بر اساس کارت‌های روی میز)
  int currentWinnerSeat() {
    var best = trick.first;
    for (final p in trick.skip(1)) {
      if (_beats(p.card, best.card)) best = p;
    }
    return best.seat;
  }

  bool _beats(HCard a, HCard b) {
    if (a.suit == b.suit) return a.rank > b.rank;
    if (a.suit == trump) return true;
    return false; // خال دیگر نمی‌تواند خال اول یا حکم را ببرد
  }

  /// آیا کارت [c] روی میز فعلی برنده می‌شود؟
  bool wouldWin(HCard c) {
    if (trick.isEmpty) return true;
    final cur = trick.reduce((a, b) => _beats(b.card, a.card) ? b : a).card;
    return _beats(c, cur);
  }

  /// بازی یک کارت. اگر میز چهارتایی شد، [resolveTrick] را صدا بزنید.
  bool play(int seat, HCard c) {
    if (seat != turn || trickFull) return false;
    if (!legal(seat).contains(c)) return false;
    hands[seat].remove(c);
    trick.add(HokmPlay(seat, c));
    played.add(c.id);
    if (!trickFull) turn = (seat + 1) % 4;
    return true;
  }

  /// پایان یک میز: برنده را برمی‌گرداند و میز بعدی را آماده می‌کند.
  int resolveTrick() {
    final w = currentWinnerSeat();
    tricksWon[hokmTeamOf(w)]++;
    tricksPlayed++;
    trick.clear();
    leader = w;
    turn = w;
    return w;
  }
}

/// امتیاز بازی (هر تیم): برد عادی ۱ ؛ کُت (حریف صفر دست) ۲ ؛ کُت حاکم (تیم حاکم کُت شود) ۳
int hokmHandPoints({required int winnerTeam, required int loserTricks, required int hakem}) {
  if (loserTricks > 0) return 1;
  return hokmTeamOf(hakem) == winnerTeam ? 2 : 3;
}

/// حاکم دست بعد: اگر تیم حاکم ببرد همان می‌ماند، وگرنه نوبت به نفر بعدی می‌رسد.
int hokmNextHakem(int hakem, int winnerTeam) => hokmTeamOf(hakem) == winnerTeam ? hakem : (hakem + 1) % 4;

// ------------------------------------------------------------------ ربات

class HokmBot {
  HokmBot(this.level, [Random? rnd]) : _rnd = rnd ?? Random();
  final BotLevel level;
  final Random _rnd;

  /// انتخاب حکم از روی پنج کارت اول
  int pickTrump(List<HCard> five) {
    if (level == BotLevel.easy) {
      // آسان: خالِ بیشترین کارت
      return _longestSuit(five);
    }
    var bestSuit = 0;
    var bestScore = -1.0;
    for (var s = 0; s < 4; s++) {
      final cs = five.where((c) => c.suit == s).toList();
      var sc = cs.length * 3.0;
      for (final c in cs) {
        if (c.rank >= 12) sc += (c.rank - 10) * 0.9;
        if (c.rank == 14) sc += 2;
      }
      sc += _rnd.nextDouble() * 0.3;
      if (sc > bestScore) {
        bestScore = sc;
        bestSuit = s;
      }
    }
    return bestSuit;
  }

  int _longestSuit(List<HCard> cs) {
    final cnt = List<int>.filled(4, 0);
    for (final c in cs) {
      cnt[c.suit]++;
    }
    var b = 0;
    for (var s = 1; s < 4; s++) {
      if (cnt[s] > cnt[b]) b = s;
    }
    return b;
  }

  HCard choose(HokmHand h, int seat) {
    final legal = h.legal(seat);
    if (legal.length == 1) return legal.first;
    if (level == BotLevel.easy) {
      // آسان: بیشتر تصادفی، گاهی کارت برنده را می‌زند
      if (h.trick.isNotEmpty && _rnd.nextDouble() < 0.4) {
        final win = legal.where(h.wouldWin).toList();
        if (win.isNotEmpty) return _lowest(win, h.trump);
      }
      return legal[_rnd.nextInt(legal.length)];
    }
    return h.trick.isEmpty ? _lead(h, seat, legal) : _follow(h, seat, legal);
  }

  /// ارزش برای «کم‌ارزش‌ترین»: حکم‌ها گران‌ترند
  int _cost(HCard c, int trump) => (c.suit == trump ? 100 : 0) + c.rank;

  HCard _lowest(List<HCard> cs, int trump) {
    var b = cs.first;
    for (final c in cs.skip(1)) {
      if (_cost(c, trump) < _cost(b, trump)) b = c;
    }
    return b;
  }

  /// آیا [c] بالاترین کارت باقی‌مانده‌ی خالش است؟ (فقط سطح سخت شمارش کارت دارد)
  bool _isMaster(HokmHand h, HCard c) {
    for (var r = c.rank + 1; r <= 14; r++) {
      final id = c.suit * 20 + r;
      if (h.played.contains(id)) continue;
      if (h.hands[_seatOf(h, c)].any((x) => x.id == id)) continue;
      return false;
    }
    return true;
  }

  int _seatOf(HokmHand h, HCard c) {
    for (var s = 0; s < 4; s++) {
      if (h.hands[s].contains(c)) return s;
    }
    return 0;
  }

  HCard _lead(HokmHand h, int seat, List<HCard> legal) {
    final trump = h.trump;
    final hard = level == BotLevel.hard;
    final nonTrump = legal.where((c) => c.suit != trump).toList();

    // آس یا کارت مسلط خال غیرحکم
    for (final c in nonTrump) {
      if (c.rank == 14) return c;
    }
    if (hard) {
      final masters = nonTrump.where((c) => _isMaster(h, c)).toList();
      if (masters.isNotEmpty) return masters.first;
    }
    // اگر تیم ما حاکم است و حکم زیاد داریم، حکم بالا بزن تا حکم حریف تمام شود
    final myTrumps = legal.where((c) => c.suit == trump).toList()..sort((a, b) => b.rank.compareTo(a.rank));
    if (hokmTeamOf(seat) == hokmTeamOf(h.hakem) && myTrumps.length >= 4) return myTrumps.first;
    if (nonTrump.isNotEmpty) {
      // کوچک‌ترین کارت از کوتاه‌ترین خال (برای بریدن زودتر)
      final cnt = List<int>.filled(4, 0);
      for (final c in nonTrump) {
        cnt[c.suit]++;
      }
      nonTrump.sort((a, b) {
        final d = cnt[a.suit].compareTo(cnt[b.suit]);
        return d != 0 ? d : a.rank.compareTo(b.rank);
      });
      return nonTrump.first;
    }
    return _lowest(legal, trump);
  }

  HCard _follow(HokmHand h, int seat, List<HCard> legal) {
    final trump = h.trump;
    final winnerSeat = h.currentWinnerSeat();
    final partnerWinning = hokmTeamOf(winnerSeat) == hokmTeamOf(seat);
    final last = h.trick.length == 3;
    final winners = legal.where(h.wouldWin).toList();

    if (partnerWinning) {
      // هم‌تیمی می‌برد؛ فقط اگر هنوز خطر هست و خالی نیستیم کمک نکن
      if (!last && winners.isNotEmpty && h.trick.length == 2) {
        // نفر آخر (حریف) هنوز نیامده: اگر هم‌تیمی با کارت کوچک می‌برد، بالاتر بزن
        final cur = h.trick.firstWhere((p) => p.seat == winnerSeat).card;
        if (cur.rank <= 9 && cur.suit != trump) {
          final cheap = winners.where((c) => c.suit == cur.suit).toList();
          if (cheap.isNotEmpty) return _lowest(cheap, trump);
        }
      }
      return _discard(h, legal);
    }
    if (winners.isNotEmpty) return _lowest(winners, trump); // ارزان‌ترین کارت برنده
    return _discard(h, legal);
  }

  /// ریختن کارت کم‌ارزش (از خال کوتاه غیرحکم)
  HCard _discard(HokmHand h, List<HCard> legal) {
    final trump = h.trump;
    final nonTrump = legal.where((c) => c.suit != trump).toList();
    final pool = nonTrump.isNotEmpty ? nonTrump : legal;
    return _lowest(pool, trump);
  }
}
