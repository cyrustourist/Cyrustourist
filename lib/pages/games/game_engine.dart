import 'dart:math';

/// موتور بازی‌ها (کاملاً مستقل از رابط کاربری و بدون اینترنت).
/// همین قوانین سمت سرور (worker) هم پیاده شده تا بازی آنلاین ضدتقلب باشد.
enum GameKind { ttt, c4 }

extension GameKindX on GameKind {
  String get code => this == GameKind.ttt ? 'ttt' : 'c4';
  int get cols => this == GameKind.ttt ? 3 : 7;
  int get rows => this == GameKind.ttt ? 3 : 6;
  int get cells => cols * rows;

  static GameKind? parse(String? s) {
    if (s == 'ttt') return GameKind.ttt;
    if (s == 'c4') return GameKind.c4;
    return null;
  }
}

enum BotLevel { easy, normal, hard }

class MoveResult {
  const MoveResult(this.board, this.winner, this.draw, this.line);
  final List<int> board;
  final int winner; // 0 = ادامه
  final bool draw;
  final List<int> line;
  bool get finished => winner != 0 || draw;
}

class GameEngine {
  GameEngine._();

  static const List<List<int>> _tttLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  static final Random _rnd = Random();

  static List<int> emptyBoard(GameKind k) => List<int>.filled(k.cells, 0);

  /// حرکت‌های مجاز: برای دوز شمارهٔ خانه، برای چهار در ردیف شمارهٔ ستون.
  static List<int> legalMoves(GameKind k, List<int> b) {
    final out = <int>[];
    if (k == GameKind.ttt) {
      for (var i = 0; i < 9; i++) {
        if (b[i] == 0) out.add(i);
      }
    } else {
      for (var c = 0; c < 7; c++) {
        if (b[c] == 0) out.add(c);
      }
    }
    return out;
  }

  static int _dropRow(List<int> b, int c) {
    for (var r = 5; r >= 0; r--) {
      if (b[r * 7 + c] == 0) return r;
    }
    return -1;
  }

  /// null = حرکت نامعتبر.
  static MoveResult? apply(GameKind k, List<int> board, int mark, int move) {
    final b = List<int>.from(board);
    if (k == GameKind.ttt) {
      if (move < 0 || move > 8 || b[move] != 0) return null;
      b[move] = mark;
      for (final l in _tttLines) {
        if (b[l[0]] == mark && b[l[1]] == mark && b[l[2]] == mark) {
          return MoveResult(b, mark, false, l);
        }
      }
      return MoveResult(b, 0, !b.contains(0), const <int>[]);
    }
    if (move < 0 || move > 6) return null;
    final r = _dropRow(b, move);
    if (r < 0) return null;
    b[r * 7 + move] = mark;
    final line = _c4Line(b, r, move, mark);
    if (line.isNotEmpty) return MoveResult(b, mark, false, line);
    return MoveResult(b, 0, !b.contains(0), const <int>[]);
  }

  static List<int> _c4Line(List<int> b, int r, int c, int mark) {
    const dirs = [
      [0, 1], [1, 0], [1, 1], [1, -1],
    ];
    for (final d in dirs) {
      final line = <int>[r * 7 + c];
      for (final s in const [1, -1]) {
        var rr = r + d[0] * s;
        var cc = c + d[1] * s;
        while (rr >= 0 && rr < 6 && cc >= 0 && cc < 7 && b[rr * 7 + cc] == mark) {
          line.add(rr * 7 + cc);
          rr += d[0] * s;
          cc += d[1] * s;
        }
      }
      if (line.length >= 4) return line;
    }
    return const <int>[];
  }

  // ------------------------------------------------------------------ ربات

  /// انتخاب حرکت ربات؛ -1 یعنی حرکتی نیست.
  static int bot(GameKind k, List<int> board, int mark, BotLevel level) {
    final legal = legalMoves(k, board);
    if (legal.isEmpty) return -1;
    final opp = mark == 1 ? 2 : 1;
    final smart = level != BotLevel.easy || _rnd.nextInt(100) < 50;
    if (!smart) return legal[_rnd.nextInt(legal.length)];
    for (final m in legal) {
      final r = apply(k, board, mark, m);
      if (r != null && r.winner == mark) return m;
    }
    for (final m in legal) {
      final r = apply(k, board, opp, m);
      if (r != null && r.winner == opp) return m;
    }
    if (k == GameKind.ttt) {
      if (level == BotLevel.easy) return legal[_rnd.nextInt(legal.length)];
      if (level == BotLevel.normal && _rnd.nextInt(100) < 25) {
        return legal[_rnd.nextInt(legal.length)];
      }
      return _tttBest(board, mark);
    }
    final depth = level == BotLevel.easy ? 2 : (level == BotLevel.normal ? 4 : 5);
    return _c4Best(board, mark, depth);
  }

  static int _tttWinner(List<int> b) {
    for (final l in _tttLines) {
      if (b[l[0]] != 0 && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) return b[l[0]];
    }
    return 0;
  }

  static int _mm(List<int> b, int turn, int me, int depth) {
    final w = _tttWinner(b);
    if (w == me) return 10 - depth;
    if (w != 0) return depth - 10;
    if (!b.contains(0)) return 0;
    var best = turn == me ? -100 : 100;
    for (var i = 0; i < 9; i++) {
      if (b[i] != 0) continue;
      b[i] = turn;
      final s = _mm(b, turn == 1 ? 2 : 1, me, depth + 1);
      b[i] = 0;
      if (turn == me) {
        if (s > best) best = s;
      } else {
        if (s < best) best = s;
      }
    }
    return best;
  }

  static int _tttBest(List<int> board, int me) {
    final b = List<int>.from(board);
    var bestS = -100;
    final cands = <int>[];
    for (var i = 0; i < 9; i++) {
      if (b[i] != 0) continue;
      b[i] = me;
      final s = _mm(b, me == 1 ? 2 : 1, me, 1);
      b[i] = 0;
      if (s > bestS) {
        bestS = s;
        cands
          ..clear()
          ..add(i);
      } else if (s == bestS) {
        cands.add(i);
      }
    }
    return cands[_rnd.nextInt(cands.length)];
  }

  static int _c4Best(List<int> board, int me, int depth) {
    final b = List<int>.from(board);
    final opp = me == 1 ? 2 : 1;
    var bestS = -1000000;
    final cands = <int>[];
    for (final c in const [3, 2, 4, 1, 5, 0, 6]) {
      final r = _dropRow(b, c);
      if (r < 0) continue;
      b[r * 7 + c] = me;
      final int s;
      if (_c4Line(b, r, c, me).isNotEmpty) {
        s = 100000 + depth;
      } else {
        s = -_nega(b, opp, depth - 1, -1000000, 1000000);
      }
      b[r * 7 + c] = 0;
      if (s > bestS) {
        bestS = s;
        cands
          ..clear()
          ..add(c);
      } else if (s == bestS) {
        cands.add(c);
      }
    }
    return cands[_rnd.nextInt(cands.length)];
  }

  /// negamax با هرس آلفا-بتا؛ امتیاز از دید بازیکنی که نوبتش است.
  static int _nega(List<int> b, int turn, int depth, int alpha, int beta) {
    if (!b.contains(0)) return 0;
    if (depth <= 0) return _eval(b, turn);
    final opp = turn == 1 ? 2 : 1;
    var best = -1000000;
    for (final c in const [3, 2, 4, 1, 5, 0, 6]) {
      final r = _dropRow(b, c);
      if (r < 0) continue;
      b[r * 7 + c] = turn;
      final int s;
      if (_c4Line(b, r, c, turn).isNotEmpty) {
        s = 100000 + depth;
      } else {
        s = -_nega(b, opp, depth - 1, -beta, -alpha);
      }
      b[r * 7 + c] = 0;
      if (s > best) best = s;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  static int _eval(List<int> b, int me) {
    final opp = me == 1 ? 2 : 1;
    var s = 0;
    for (var r = 0; r < 6; r++) {
      final v = b[r * 7 + 3];
      if (v == me) {
        s += 3;
      } else if (v == opp) {
        s -= 3;
      }
    }
    const dirs = [
      [0, 1], [1, 0], [1, 1], [1, -1],
    ];
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 7; c++) {
        for (final d in dirs) {
          final er = r + 3 * d[0];
          final ec = c + 3 * d[1];
          if (er < 0 || er > 5 || ec < 0 || ec > 6) continue;
          var mine = 0;
          var theirs = 0;
          for (var i = 0; i < 4; i++) {
            final v = b[(r + i * d[0]) * 7 + (c + i * d[1])];
            if (v == me) {
              mine++;
            } else if (v == opp) {
              theirs++;
            }
          }
          if (mine > 0 && theirs == 0) {
            s += mine == 3 ? 12 : (mine == 2 ? 4 : 1);
          } else if (theirs > 0 && mine == 0) {
            s -= theirs == 3 ? 14 : (theirs == 2 ? 4 : 1);
          }
        }
      }
    }
    return s;
  }
}
