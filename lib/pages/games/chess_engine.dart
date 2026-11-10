import 'dart:math';

/// موتور شطرنج کامل (بدون وابستگی به فلاتر؛ قابل تست و قابل اجرا در Isolate).
/// قوانین: رخ‌دادن/کیش و مات، پات، قلعه‌رفتن، آنپاسان، ارتقای پیاده، مساوی با تکرار سه‌باره، قانون ۵۰ حرکت و کمبود مهره.
///
/// خانه‌ها: شمارهٔ ۰ تا ۶۳ ؛ خانهٔ ۰ = a8 (بالا-چپ) و ۶۳ = h1 (پایین-راست).
/// مهره‌ها: ۱ پیاده، ۲ اسب، ۳ فیل، ۴ رخ، ۵ وزیر، ۶ شاه ؛ مثبت = سفید، منفی = سیاه.

const int kPawn = 1, kKnight = 2, kBishop = 3, kRook = 4, kQueen = 5, kKing = 6;

const List<String> _promoLetter = <String>['', '', 'n', 'b', 'r', 'q'];
const List<String> _sanLetter = <String>['', '', 'N', 'B', 'R', 'Q', 'K'];

String chSqName(int i) => '${'abcdefgh'[i % 8]}${8 - i ~/ 8}';

int chParseSq(String s) => (8 - int.parse(s[1])) * 8 + (s.codeUnitAt(0) - 97);

class CMove {
  const CMove(this.from, this.to, {this.promo = 0, this.ep = false, this.castle = false});
  final int from;
  final int to;
  final int promo; // ۰ یا کد مهره (۲ تا ۵)
  final bool ep;
  final bool castle;

  String get uci => '${chSqName(from)}${chSqName(to)}${_promoLetter[promo]}';
}

class ChessPos {
  const ChessPos(this.b, this.white, this.castle, this.ep, this.half, this.full);

  final List<int> b;
  final bool white; // نوبت سفید؟
  final int castle; // ۱ سفید-شاه ۲ سفید-وزیر ۴ سیاه-شاه ۸ سیاه-وزیر
  final int ep; // خانهٔ هدف آنپاسان یا -۱
  final int half; // شمارندهٔ قانون ۵۰ حرکت (نیم‌حرکت)
  final int full;

  factory ChessPos.start() {
    final b = List<int>.filled(64, 0);
    const back = <int>[kRook, kKnight, kBishop, kQueen, kKing, kBishop, kKnight, kRook];
    for (var f = 0; f < 8; f++) {
      b[f] = -back[f];
      b[8 + f] = -kPawn;
      b[48 + f] = kPawn;
      b[56 + f] = back[f];
    }
    return ChessPos(b, true, 15, -1, 0, 1);
  }

  /// کلید یکتا برای تشخیص تکرار وضعیت
  String get key => '${b.join(',')}|$white|$castle|$ep';
}

const List<List<int>> _knightD = <List<int>>[
  [1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2]
];
const List<List<int>> _diagD = <List<int>>[
  [1, 1], [1, -1], [-1, 1], [-1, -1]
];
const List<List<int>> _orthoD = <List<int>>[
  [1, 0], [-1, 0], [0, 1], [0, -1]
];

bool _in(int f, int r) => f >= 0 && f < 8 && r >= 0 && r < 8;

bool chAttacked(List<int> b, int sq, bool byWhite) {
  final f = sq % 8, r = sq ~/ 8;
  final pr = byWhite ? r + 1 : r - 1;
  final pawn = byWhite ? kPawn : -kPawn;
  for (final df in const <int>[-1, 1]) {
    final pf = f + df;
    if (_in(pf, pr) && b[pr * 8 + pf] == pawn) return true;
  }
  final knight = byWhite ? kKnight : -kKnight;
  for (final d in _knightD) {
    final nf = f + d[0], nr = r + d[1];
    if (_in(nf, nr) && b[nr * 8 + nf] == knight) return true;
  }
  final king = byWhite ? kKing : -kKing;
  for (var df = -1; df <= 1; df++) {
    for (var dr = -1; dr <= 1; dr++) {
      if (df == 0 && dr == 0) continue;
      final nf = f + df, nr = r + dr;
      if (_in(nf, nr) && b[nr * 8 + nf] == king) return true;
    }
  }
  final bishop = byWhite ? kBishop : -kBishop;
  final rook = byWhite ? kRook : -kRook;
  final queen = byWhite ? kQueen : -kQueen;
  for (final d in _diagD) {
    var nf = f + d[0], nr = r + d[1];
    while (_in(nf, nr)) {
      final p = b[nr * 8 + nf];
      if (p != 0) {
        if (p == bishop || p == queen) return true;
        break;
      }
      nf += d[0];
      nr += d[1];
    }
  }
  for (final d in _orthoD) {
    var nf = f + d[0], nr = r + d[1];
    while (_in(nf, nr)) {
      final p = b[nr * 8 + nf];
      if (p != 0) {
        if (p == rook || p == queen) return true;
        break;
      }
      nf += d[0];
      nr += d[1];
    }
  }
  return false;
}

int chKingSq(List<int> b, bool white) {
  final k = white ? kKing : -kKing;
  for (var i = 0; i < 64; i++) {
    if (b[i] == k) return i;
  }
  return -1;
}

bool chInCheck(ChessPos p) {
  final k = chKingSq(p.b, p.white);
  return k >= 0 && chAttacked(p.b, k, !p.white);
}

List<CMove> _pseudo(ChessPos p) {
  final out = <CMove>[];
  final b = p.b;
  final side = p.white ? 1 : -1;

  void addPawn(int from, int to, int promoRank) {
    if (to ~/ 8 == promoRank) {
      for (final pc in const <int>[kQueen, kRook, kBishop, kKnight]) {
        out.add(CMove(from, to, promo: pc));
      }
    } else {
      out.add(CMove(from, to));
    }
  }

  for (var sq = 0; sq < 64; sq++) {
    final piece = b[sq] * side;
    if (piece <= 0) continue;
    final f = sq % 8, r = sq ~/ 8;
    if (piece == kPawn) {
      final dir = p.white ? -1 : 1;
      final startRank = p.white ? 6 : 1;
      final promoRank = p.white ? 0 : 7;
      final nr = r + dir;
      if (nr >= 0 && nr < 8) {
        final one = nr * 8 + f;
        if (b[one] == 0) {
          addPawn(sq, one, promoRank);
          if (r == startRank) {
            final two = (r + 2 * dir) * 8 + f;
            if (b[two] == 0) out.add(CMove(sq, two));
          }
        }
        for (final df in const <int>[-1, 1]) {
          final nf = f + df;
          if (nf < 0 || nf > 7) continue;
          final t = nr * 8 + nf;
          if (b[t] * side < 0) {
            addPawn(sq, t, promoRank);
          } else if (t == p.ep && p.ep >= 0) {
            out.add(CMove(sq, t, ep: true));
          }
        }
      }
    } else if (piece == kKnight) {
      for (final d in _knightD) {
        final nf = f + d[0], nr = r + d[1];
        if (!_in(nf, nr)) continue;
        final t = nr * 8 + nf;
        if (b[t] * side <= 0) out.add(CMove(sq, t));
      }
    } else if (piece == kKing) {
      for (var df = -1; df <= 1; df++) {
        for (var dr = -1; dr <= 1; dr++) {
          if (df == 0 && dr == 0) continue;
          final nf = f + df, nr = r + dr;
          if (!_in(nf, nr)) continue;
          final t = nr * 8 + nf;
          if (b[t] * side <= 0) out.add(CMove(sq, t));
        }
      }
      // قلعه‌رفتن
      if (p.white && sq == 60) {
        if ((p.castle & 1) != 0 && b[61] == 0 && b[62] == 0 && b[63] == kRook && !chAttacked(b, 60, false) && !chAttacked(b, 61, false) && !chAttacked(b, 62, false)) {
          out.add(const CMove(60, 62, castle: true));
        }
        if ((p.castle & 2) != 0 && b[59] == 0 && b[58] == 0 && b[57] == 0 && b[56] == kRook && !chAttacked(b, 60, false) && !chAttacked(b, 59, false) && !chAttacked(b, 58, false)) {
          out.add(const CMove(60, 58, castle: true));
        }
      } else if (!p.white && sq == 4) {
        if ((p.castle & 4) != 0 && b[5] == 0 && b[6] == 0 && b[7] == -kRook && !chAttacked(b, 4, true) && !chAttacked(b, 5, true) && !chAttacked(b, 6, true)) {
          out.add(const CMove(4, 6, castle: true));
        }
        if ((p.castle & 8) != 0 && b[3] == 0 && b[2] == 0 && b[1] == 0 && b[0] == -kRook && !chAttacked(b, 4, true) && !chAttacked(b, 3, true) && !chAttacked(b, 2, true)) {
          out.add(const CMove(4, 2, castle: true));
        }
      }
    } else {
      final dirs = piece == kBishop ? _diagD : (piece == kRook ? _orthoD : <List<int>>[..._diagD, ..._orthoD]);
      for (final d in dirs) {
        var nf = f + d[0], nr = r + d[1];
        while (_in(nf, nr)) {
          final t = nr * 8 + nf;
          final v = b[t] * side;
          if (v > 0) break;
          out.add(CMove(sq, t));
          if (v < 0) break;
          nf += d[0];
          nr += d[1];
        }
      }
    }
  }
  return out;
}

ChessPos chApply(ChessPos p, CMove m) {
  final nb = List<int>.of(p.b);
  final piece = nb[m.from];
  final captured = nb[m.to];
  nb[m.to] = m.promo != 0 ? (p.white ? m.promo : -m.promo) : piece;
  nb[m.from] = 0;
  if (m.ep) nb[p.white ? m.to + 8 : m.to - 8] = 0;
  if (m.castle) {
    if (m.to == 62) {
      nb[61] = nb[63];
      nb[63] = 0;
    } else if (m.to == 58) {
      nb[59] = nb[56];
      nb[56] = 0;
    } else if (m.to == 6) {
      nb[5] = nb[7];
      nb[7] = 0;
    } else if (m.to == 2) {
      nb[3] = nb[0];
      nb[0] = 0;
    }
  }
  var c = p.castle;
  if (m.from == 60) c &= ~3;
  if (m.from == 4) c &= ~12;
  if (m.from == 63 || m.to == 63) c &= ~1;
  if (m.from == 56 || m.to == 56) c &= ~2;
  if (m.from == 7 || m.to == 7) c &= ~4;
  if (m.from == 0 || m.to == 0) c &= ~8;
  final isPawn = piece.abs() == kPawn;
  final ep = (isPawn && (m.to - m.from).abs() == 16) ? (m.from + m.to) ~/ 2 : -1;
  final half = (isPawn || captured != 0 || m.ep) ? 0 : p.half + 1;
  return ChessPos(nb, !p.white, c, ep, half, p.full + (p.white ? 0 : 1));
}

List<CMove> chLegal(ChessPos p) {
  final out = <CMove>[];
  for (final m in _pseudo(p)) {
    final np = chApply(p, m);
    final k = chKingSq(np.b, p.white);
    if (k >= 0 && !chAttacked(np.b, k, !p.white)) out.add(m);
  }
  return out;
}

/// کمبود مهره: شاه تنها، یا شاه + یک اسب/فیل در برابر شاه تنها، یا دو فیل هم‌رنگ
bool chInsufficient(ChessPos p) {
  final minors = <int>[]; // خانهٔ مهره‌های سبک
  for (var i = 0; i < 64; i++) {
    final v = p.b[i].abs();
    if (v == 0 || v == kKing) continue;
    if (v == kPawn || v == kRook || v == kQueen) return false;
    minors.add(i);
  }
  if (minors.length <= 1) return true;
  if (minors.length == 2) {
    final a = p.b[minors[0]], c = p.b[minors[1]];
    if (a.abs() == kBishop && c.abs() == kBishop && (a > 0) != (c > 0)) {
      final colA = ((minors[0] % 8) + (minors[0] ~/ 8)) % 2;
      final colC = ((minors[1] % 8) + (minors[1] ~/ 8)) % 2;
      return colA == colC;
    }
  }
  return false;
}

/// بازسازی وضعیت از فهرست حرکت‌ها (uci). اگر حرکتی غیرمجاز بود null برمی‌گرداند.
ChessPos? chReplay(List<String> mvs, {List<String>? keys}) {
  var p = ChessPos.start();
  keys?.add(p.key);
  for (final s in mvs) {
    final m = chFind(p, s);
    if (m == null) return null;
    p = chApply(p, m);
    keys?.add(p.key);
  }
  return p;
}

CMove? chFind(ChessPos p, String uci) {
  for (final m in chLegal(p)) {
    if (m.uci == uci) return m;
  }
  return null;
}

/// نماد جبری (SAN) برای نمایش فهرست حرکت‌ها
String chSan(ChessPos p, CMove m, List<CMove> legal) {
  final piece = p.b[m.from].abs();
  String s;
  if (m.castle) {
    s = m.to > m.from ? 'O-O' : 'O-O-O';
  } else {
    final cap = p.b[m.to] != 0 || m.ep;
    if (piece == kPawn) {
      s = cap ? '${'abcdefgh'[m.from % 8]}x${chSqName(m.to)}' : chSqName(m.to);
      if (m.promo != 0) s += '=${_sanLetter[m.promo]}';
    } else {
      final others = legal.where((o) => o.to == m.to && o.from != m.from && p.b[o.from].abs() == piece).toList();
      var dis = '';
      if (others.isNotEmpty) {
        final sameFile = others.any((o) => o.from % 8 == m.from % 8);
        final sameRank = others.any((o) => o.from ~/ 8 == m.from ~/ 8);
        if (!sameFile) {
          dis = 'abcdefgh'[m.from % 8];
        } else if (!sameRank) {
          dis = '${8 - m.from ~/ 8}';
        } else {
          dis = chSqName(m.from);
        }
      }
      s = '${_sanLetter[piece]}$dis${cap ? 'x' : ''}${chSqName(m.to)}';
    }
  }
  final np = chApply(p, m);
  if (chInCheck(np)) s += chLegal(np).isEmpty ? '#' : '+';
  return s;
}

// ------------------------------------------------------------------ ربات

const List<int> _val = <int>[0, 100, 320, 330, 500, 900, 0];

int _eval(ChessPos p) {
  var s = 0;
  for (var i = 0; i < 64; i++) {
    final v = p.b[i];
    if (v == 0) continue;
    final t = v.abs();
    final f = i % 8, r = i ~/ 8;
    final white = v > 0;
    var x = _val[t];
    final dist = max((f * 2 - 7).abs(), (r * 2 - 7).abs()) / 2; // ۰٫۵ تا ۳٫۵
    if (t == kKnight || t == kBishop) {
      x += ((3.5 - dist) * 8).round();
    } else if (t == kPawn) {
      final adv = white ? 6 - r : r - 1; // ۰ تا ۵
      x += adv * 6 + ((3.5 - dist) * 2).round();
    } else if (t == kQueen) {
      x += ((3.5 - dist) * 2).round();
    } else if (t == kKing) {
      // پناه‌گرفتن شاه در میانهٔ بازی: ردیف آخر بهتر از مرکز
      final home = white ? r : 7 - r; // ۷ = ردیف خودی
      x += (home - 3) * 4;
    }
    s += white ? x : -x;
  }
  return s;
}

int _order(ChessPos p, CMove m) {
  final cap = p.b[m.to].abs();
  var sc = 0;
  if (cap != 0 || m.ep) sc += 10 * _val[cap == 0 ? kPawn : cap] - _val[p.b[m.from].abs()] ~/ 10 + 1000;
  if (m.promo != 0) sc += 800;
  return sc;
}

int _negamax(ChessPos p, int depth, int alpha, int beta, int ply) {
  if (p.half >= 100) return 0;
  final moves = chLegal(p);
  if (moves.isEmpty) return chInCheck(p) ? -30000 + ply : 0;
  if (depth == 0) return _eval(p) * (p.white ? 1 : -1);
  moves.sort((a, b) => _order(p, b).compareTo(_order(p, a)));
  var best = -100000;
  for (final m in moves) {
    final v = -_negamax(chApply(p, m), depth - 1, -beta, -alpha, ply + 1);
    if (v > best) best = v;
    if (best > alpha) alpha = best;
    if (alpha >= beta) break;
  }
  return best;
}

/// انتخاب حرکت ربات؛ level: ۰ آسان، ۱ معمولی، ۲ سخت. برای اجرا در Isolate مناسب است.
String? chessBotPick(List<String> mvs, int level, int seed) {
  final p = chReplay(mvs);
  if (p == null) return null;
  final moves = chLegal(p);
  if (moves.isEmpty) return null;
  final rnd = Random(seed);
  if (level == 0 && rnd.nextInt(100) < 25) return moves[rnd.nextInt(moves.length)].uci;
  final depth = level == 0 ? 1 : (level == 1 ? 2 : 3);
  final noise = level == 0 ? 40 : (level == 1 ? 8 : 2);
  moves.sort((a, b) => _order(p, b).compareTo(_order(p, a)));
  CMove? best;
  var bestV = -1000000;
  for (final m in moves) {
    final v = -_negamax(chApply(p, m), depth - 1, -100000, 100000, 1) + rnd.nextInt(noise + 1);
    if (v > bestV) {
      bestV = v;
      best = m;
    }
  }
  return best?.uci;
}
