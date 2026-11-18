import 'dart:math';

import 'hokm_engine.dart' show HCard;

/// موتور «حکم» چهارنفره با تصمیم‌گیری مرکزی (فقط روی گوشی میزبان اجرا می‌شود).
/// صندلی‌ها: ۰ شما، ۱ چپ، ۲ هم‌تیمی، ۳ راست. تیم ۰ = صندلی ۰ و ۲، تیم ۱ = صندلی ۱ و ۳.
/// خال‌ها مثل [HCard]: ۰ پیک، ۱ دل، ۲ خشت، ۳ گشنیز.

/// نوع حکم: خال (۰..۳) یا یکی از سه حالت بدون حکم.
enum HokmKind { suit, nars, sars, tak }

enum HokmPhase { idle, choose, play, full, sweep, handEnd, over }

class HokmPlayer {
  HokmPlayer({required this.name, required this.avatar, this.bot = false, this.uid = ''});
  String name;
  String avatar; // اندیس آواتار یا عکس base64
  bool bot;
  String uid; // شناسه‌ی گوشی برای بازی چندگوشی
  bool conn = true;

  Map<String, dynamic> toJson() => {'n': name, 'a': avatar, 'b': bot, 'c': conn || bot};
}

class HokmPlayed {
  HokmPlayed(this.seat, this.card);
  final int seat;
  final HCard card;
}

class HokmResult {
  HokmResult({required this.team, required this.pts, required this.kot, required this.hakemKot, required this.tak});
  final int team;
  final int pts;
  final bool kot;
  final bool hakemKot;
  final bool tak;
}

int hokmTeam(int seat) => seat % 2;

/// ترتیب خال‌ها در دست: پیک، دل، گشنیز، خشت
const List<int> _suitOrder = <int>[0, 1, 3, 2];

List<HCard> hokmSort(List<HCard> h) {
  final l = List<HCard>.of(h);
  l.sort((a, b) {
    final d = _suitOrder.indexOf(a.suit).compareTo(_suitOrder.indexOf(b.suit));
    return d != 0 ? d : b.rank.compareTo(a.rank);
  });
  return l;
}

/// قدرت کارت در یک خال (بیشتر = قوی‌تر):
/// - حکم عادی و سرس: آس بالاترین، بعد شاه … تا ۲.
/// - نرس: کارت کوچک برنده است؛ ۲ قوی‌ترین … آس ضعیف‌ترین.
/// - تک نرس: اول آس (قوی‌ترین)، بعد ۲، ۳ … تا شاه (ضعیف‌ترین).
int hokmRankValue(HCard c, HokmKind kind) {
  switch (kind) {
    case HokmKind.nars:
      return 15 - c.rank;
    case HokmKind.tak:
      return c.rank == 14 ? 20 : 15 - c.rank;
    default:
      return c.rank;
  }
}

class HokmMatch {
  HokmMatch({
    required this.players,
    this.target = 7,
    Random? rnd,
    this.onChange,
    this.onEvent,
    Map<String, dynamic>? saved,
  }) : _rnd = rnd ?? Random() {
    if (saved != null) _load(saved);
  }

  final List<HokmPlayer> players;
  int target;
  final Random _rnd;

  /// وقتی وضعیت عوض شد (برای ارسال به بقیه و رسم صفحه)
  void Function()? onChange;

  /// رویدادهای صوتی: deal, deal2, play, win, pick, pass, hand, over
  void Function(String ev, int seat)? onEvent;

  int ver = 0;
  HokmPhase phase = HokmPhase.idle;
  List<int> scores = <int>[0, 0];
  int hakem = 0;
  int chooser = 0;
  HokmKind kind = HokmKind.suit;
  int trump = -1; // فقط وقتی kind == suit
  bool decided = false; // حکم تعیین شده
  bool seven = false; // حکم با «۷ یار» تعیین شده
  List<List<HCard>> hands = List<List<HCard>>.generate(4, (_) => <HCard>[]);
  List<HCard> deck = <HCard>[];
  int turn = 0;
  final List<HokmPlayed> trick = <HokmPlayed>[];
  List<int> tricks = <int>[0, 0];
  List<HokmPlayed>? lastCards;
  int lastWinner = -1;
  int handNo = 0;
  HokmResult? result;
  int sweepWinner = -1;
  bool _dead = false;
  int speedPercent = 50; // ۱۰..۱۰۰؛ بیشتر = سریع‌تر

  // ------------------------------------------------------------ زمان‌بندی
  int _dl(int ms) => (ms * (1.55 - speedPercent / 100)).round();

  void _later(void Function() f, int ms) {
    Future<void>.delayed(Duration(milliseconds: ms < 1 ? 1 : ms), () {
      if (!_dead) f();
    });
  }

  void destroy() => _dead = true;

  bool _auto(int s) => players[s].bot || !players[s].conn;

  void _bump() {
    ver++;
    if (_dead) return;
    onChange?.call();
    _schedule();
  }

  void _schedule() {
    final v = ver;
    if (phase == HokmPhase.choose && _auto(chooser)) {
      final s = chooser;
      _later(() {
        if (ver != v) return;
        act(s, <String, dynamic>{'k': 'choose', 'o': _botChoose(hands[s].sublist(0, 5), s == hakem)});
      }, _dl(1100));
    } else if (phase == HokmPhase.play && _auto(turn)) {
      final s = turn;
      _later(() {
        if (ver != v) return;
        act(s, <String, dynamic>{'k': 'play', 'c': _botPlay(s).id});
      }, _dl(900));
    }
  }

  // ------------------------------------------------------------ جریان بازی
  void start() {
    scores = <int>[0, 0];
    hakem = _rnd.nextInt(4);
    handNo = 0;
    _dealHand();
  }

  void resume() {
    _bump();
  }

  void _dealHand() {
    handNo++;
    final d = List<HCard>.generate(52, (i) => HCard(i ~/ 13, 2 + i % 13))..shuffle(_rnd);
    hands = List<List<HCard>>.generate(4, (i) => hokmSort(d.sublist(i * 5, i * 5 + 5)));
    deck = d.sublist(20);
    kind = HokmKind.suit;
    trump = -1;
    decided = false;
    seven = false;
    tricks = <int>[0, 0];
    trick.clear();
    lastCards = null;
    lastWinner = -1;
    result = null;
    sweepWinner = -1;
    phase = HokmPhase.choose;
    chooser = hakem;
    turn = hakem;
    onEvent?.call('deal', hakem);
    _bump();
  }

  void _finishDeal() {
    for (var i = 0; i < 4; i++) {
      hands[i] = hokmSort(<HCard>[...hands[i], ...deck.sublist(i * 8, i * 8 + 8)]);
    }
    deck = <HCard>[];
    phase = HokmPhase.play;
    turn = hakem;
    trick.clear();
    onEvent?.call('deal2', hakem);
    _bump();
  }

  List<HCard> legal(int seat) {
    final h = hands[seat];
    if (trick.isEmpty) return List<HCard>.of(h);
    final ls = trick.first.card.suit;
    final f = h.where((c) => c.suit == ls).toList();
    return f.isNotEmpty ? f : List<HCard>.of(h);
  }

  bool _beats(HCard b, HCard a) {
    if (b.suit == a.suit) return hokmRankValue(b, kind) > hokmRankValue(a, kind);
    return kind == HokmKind.suit && b.suit == trump && a.suit != trump;
  }

  HokmPlayed _winnerOf(List<HokmPlayed> t) {
    var best = t.first;
    for (var i = 1; i < t.length; i++) {
      if (_beats(t[i].card, best.card)) best = t[i];
    }
    return best;
  }

  int currentWinnerSeat() => _winnerOf(trick).seat;

  /// حرکت یک بازیکن. اگر نامعتبر بود false برمی‌گرداند.
  /// m: {'k':'choose','o':'0'..'3'|'nars'|'sars'|'tak'|'pass'} یا {'k':'play','c':id} یا {'k':'again'}
  bool act(int seat, Map<String, dynamic> m) {
    if (_dead) return false;
    final k = m['k'];
    if (k == 'choose' && phase == HokmPhase.choose && seat == chooser) {
      final o = '${m['o']}';
      if (o == 'pass') {
        if (seat != hakem) return false;
        chooser = (hakem + 2) % 4;
        turn = chooser;
        onEvent?.call('pass', seat);
        _bump();
        return true;
      }
      if (o == 'seven') {
        if (seat != hakem) return false;
        final pc = hands[(hakem + 2) % 4].where((c) => c.rank == 7).toList();
        kind = HokmKind.suit;
        if (pc.isNotEmpty) {
          trump = pc.first.suit;
        } else {
          final n = List<int>.filled(4, 0);
          for (final c in hands[seat]) {
            n[c.suit]++;
          }
          var b = 0;
          for (var s = 1; s < 4; s++) {
            if (n[s] > n[b]) b = s;
          }
          trump = b;
        }
        seven = true;
      } else if (o == 'nars') {
        kind = HokmKind.nars;
      } else if (o == 'sars') {
        kind = HokmKind.sars;
      } else if (o == 'tak') {
        kind = HokmKind.tak;
      } else {
        final s = int.tryParse(o);
        if (s == null || s < 0 || s > 3) return false;
        kind = HokmKind.suit;
        trump = s;
      }
      decided = true;
      onEvent?.call('pick', seat);
      _finishDeal();
      return true;
    }
    if (k == 'play' && phase == HokmPhase.play && seat == turn) {
      final id = (m['c'] as num?)?.toInt() ?? -1;
      final idx = hands[seat].indexWhere((c) => c.id == id);
      if (idx < 0) return false;
      final c = hands[seat][idx];
      if (!legal(seat).contains(c)) return false;
      hands[seat].removeAt(idx);
      trick.add(HokmPlayed(seat, c));
      onEvent?.call('play', seat);
      if (trick.length < 4) {
        turn = (seat + 1) % 4;
        _bump();
      } else {
        phase = HokmPhase.full;
        turn = -1;
        _bump();
        final v = ver;
        _later(() {
          if (ver == v) _resolve();
        }, _dl(950));
      }
      return true;
    }
    if (k == 'again' && phase == HokmPhase.over) {
      start();
      return true;
    }
    return false;
  }

  void _resolve() {
    if (phase != HokmPhase.full) return;
    sweepWinner = _winnerOf(trick).seat;
    phase = HokmPhase.sweep;
    _bump();
    final v = ver;
    _later(() {
      if (ver == v) _finishTrick();
    }, _dl(450));
  }

  void _finishTrick() {
    if (phase != HokmPhase.sweep) return;
    final w = sweepWinner;
    tricks[hokmTeam(w)]++;
    lastCards = List<HokmPlayed>.of(trick);
    lastWinner = w;
    trick.clear();
    sweepWinner = -1;
    onEvent?.call('win', w);
    const need = 7;
    final hk = hokmTeam(hakem), ho = 1 - hk;
    final hw = tricks[hk] >= need;
    final ow = tricks[ho] >= 14 - need;
    if (hw || ow) {
      _endHand(hw, hk, ho);
      return;
    }
    turn = w;
    phase = HokmPhase.play;
    _bump();
  }

  void _endHand(bool hw, int hk, int ho) {
    int pts, wt;
    var kot = false, hkot = false;
    if (kind == HokmKind.tak) {
      pts = 3;
      wt = hw ? hk : ho;
    } else if (hw) {
      wt = hk;
      kot = tricks[ho] == 0;
      pts = kot ? 2 : 1;
    } else {
      wt = ho;
      hkot = tricks[hk] == 0;
      pts = hkot ? 3 : 2;
    }
    scores[wt] += pts;
    result = HokmResult(team: wt, pts: pts, kot: kot, hakemKot: hkot, tak: kind == HokmKind.tak);
    phase = HokmPhase.handEnd;
    turn = -1;
    onEvent?.call('hand', wt);
    _bump();
    final v = ver;
    _later(() {
      if (ver != v) return;
      if (scores[0] >= target || scores[1] >= target) {
        phase = HokmPhase.over;
        onEvent?.call('over', wt);
        _bump();
      } else {
        if (!hw) hakem = (hakem + 1) % 4;
        _dealHand();
      }
    }, _dl(3300));
  }

  void setConn(int seat, bool v) {
    if (players[seat].conn != v) {
      players[seat].conn = v;
      _bump();
    }
  }

  // ------------------------------------------------------------ نمای هر بازیکن
  /// وضعیتی که برای صندلی [seat] فرستاده می‌شود (فقط کارت‌های خودش).
  Map<String, dynamic> view(int seat) => <String, dynamic>{
        'ver': ver,
        'ph': phase.index,
        'seat': seat,
        'pl': players.map((p) => p.toJson()).toList(),
        'hand': hands[seat].map((c) => c.id).toList(),
        'cnt': hands.map((h) => h.length).toList(),
        'hakem': hakem,
        'chooser': chooser,
        'kind': kind.index,
        'trump': trump,
        'decided': decided,
        'seven': seven,
        'turn': turn,
        'trick': trick.map((p) => <int>[p.seat, p.card.id]).toList(),
        'tricks': tricks,
        'scores': scores,
        'target': target,
        'last': lastCards == null ? null : <String, dynamic>{'w': lastWinner, 'c': lastCards!.map((p) => <int>[p.seat, p.card.id]).toList()},
        'res': result == null ? null : <String, dynamic>{'t': result!.team, 'p': result!.pts, 'k': result!.kot, 'hk': result!.hakemKot, 'tak': result!.tak},
        'sweep': sweepWinner,
        'no': handNo,
      };

  /// ذخیره برای ادامه‌ی بازی آفلاین
  Map<String, dynamic> save() => <String, dynamic>{
        'scores': scores,
        'hakem': hakem,
        'chooser': chooser,
        'kind': kind.index,
        'trump': trump,
        'decided': decided,
        'hands': hands.map((h) => h.map((c) => c.id).toList()).toList(),
        'deck': deck.map((c) => c.id).toList(),
        'turn': turn,
        'trick': trick.map((p) => <int>[p.seat, p.card.id]).toList(),
        'tricks': tricks,
        'no': handNo,
        'ph': phase.index,
        'target': target,
        'pl': players.map((p) => <String, dynamic>{'n': p.name, 'a': p.avatar, 'b': p.bot}).toList(),
      };

  static HCard _cardOf(int id) => HCard(id ~/ 20, id % 20);

  void _load(Map<String, dynamic> s) {
    scores = (s['scores'] as List).map((e) => (e as num).toInt()).toList();
    hakem = (s['hakem'] as num).toInt();
    chooser = (s['chooser'] as num).toInt();
    kind = HokmKind.values[(s['kind'] as num).toInt()];
    trump = (s['trump'] as num).toInt();
    decided = s['decided'] == true;
    hands = (s['hands'] as List).map((h) => (h as List).map((e) => _cardOf((e as num).toInt())).toList()).toList();
    deck = (s['deck'] as List).map((e) => _cardOf((e as num).toInt())).toList();
    turn = (s['turn'] as num).toInt();
    trick
      ..clear()
      ..addAll((s['trick'] as List).map((e) => HokmPlayed((e[0] as num).toInt(), _cardOf((e[1] as num).toInt()))));
    tricks = (s['tricks'] as List).map((e) => (e as num).toInt()).toList();
    handNo = (s['no'] as num).toInt();
    final ph = (s['ph'] as num).toInt();
    // حالت‌های گذرا به «در حال بازی» برمی‌گردند
    phase = ph == HokmPhase.choose.index ? HokmPhase.choose : HokmPhase.play;
    if (phase == HokmPhase.play && trick.length >= 4) {
      trick.clear();
    }
    if (phase == HokmPhase.play && (turn < 0 || turn > 3)) turn = hakem;
    target = (s['target'] as num?)?.toInt() ?? target;
  }

  // ------------------------------------------------------------ ربات
  String _botChoose(List<HCard> five, bool canPass) {
    final cnt = List<int>.filled(4, 0), st = List<int>.filled(4, 0);
    var aces = 0;
    for (final c in five) {
      cnt[c.suit]++;
      if (c.rank >= 11) st[c.suit] += c.rank - 9;
      if (c.rank == 14) aces++;
    }
    if (aces >= 3 && _rnd.nextDouble() < .5) return 'nars';
    var b = 0;
    var bs = -1.0;
    for (var s = 0; s < 4; s++) {
      final v = cnt[s] * 2 + st[s] + _rnd.nextDouble();
      if (v > bs) {
        bs = v;
        b = s;
      }
    }
    if (canPass && bs < 5.5 && _rnd.nextDouble() < .5) return 'pass';
    return '$b';
  }

  int _low(HCard c) => (kind == HokmKind.suit && c.suit == trump ? 100 : 0) + hokmRankValue(c, kind);

  HCard _lowest(List<HCard> a) {
    var b = a.first;
    for (final c in a.skip(1)) {
      if (_low(c) < _low(b)) b = c;
    }
    return b;
  }

  HCard _botPlay(int seat) {
    final l = legal(seat);
    if (l.length == 1) return l.first;
    if (trick.isEmpty) {
      if (kind != HokmKind.suit) {
        final so = List<HCard>.of(l)..sort((a, b) => hokmRankValue(b, kind).compareTo(hokmRankValue(a, kind)));
        return _rnd.nextBool() ? so.first : _lowest(l);
      }
      final aces = l.where((c) => c.rank == 14 && !(kind == HokmKind.suit && c.suit == trump)).toList();
      if (aces.isNotEmpty) return aces.first;
      final nt = l.where((c) => !(kind == HokmKind.suit && c.suit == trump)).toList();
      if (nt.isNotEmpty) {
        final k = nt.where((c) => hokmRankValue(c, kind) >= 13).toList();
        return k.isNotEmpty && _rnd.nextBool() ? k.first : _lowest(nt);
      }
      return _lowest(l);
    }
    final best = _winnerOf(trick);
    final partnerWins = hokmTeam(best.seat) == hokmTeam(seat);
    final win = l.where((c) => _beats(c, best.card)).toList();
    if (partnerWins && trick.length >= 2) return _lowest(l);
    if (win.isNotEmpty) return _lowest(win);
    return _lowest(l);
  }
}
