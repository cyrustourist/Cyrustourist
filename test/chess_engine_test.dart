import 'package:cyrustourist_app3/pages/games/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ChessPos fen(String s) {
  final parts = s.split(' ');
  final b = List<int>.filled(64, 0);
  var i = 0;
  const m = <String, int>{'p': 1, 'n': 2, 'b': 3, 'r': 4, 'q': 5, 'k': 6};
  for (final ch in parts[0].split('')) {
    if (ch == '/') continue;
    final d = int.tryParse(ch);
    if (d != null) {
      i += d;
    } else {
      b[i++] = m[ch.toLowerCase()]! * (ch == ch.toUpperCase() ? 1 : -1);
    }
  }
  var c = 0;
  for (final ch in parts[2].split('')) {
    c |= <String, int>{'K': 1, 'Q': 2, 'k': 4, 'q': 8}[ch] ?? 0;
  }
  final ep = parts[3] == '-' ? -1 : chParseSq(parts[3]);
  return ChessPos(b, parts[1] == 'w', c, ep, 0, 1);
}

int perft(ChessPos p, int d) {
  if (d == 0) return 1;
  var n = 0;
  for (final m in chLegal(p)) {
    n += perft(chApply(p, m), d - 1);
  }
  return n;
}

void main() {
  test('perft: start position', () {
    expect(perft(ChessPos.start(), 1), 20);
    expect(perft(ChessPos.start(), 2), 400);
    expect(perft(ChessPos.start(), 3), 8902);
  });

  test('perft: kiwipete (castling, en passant, pins)', () {
    final p = fen('r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -');
    expect(perft(p, 1), 48);
    expect(perft(p, 2), 2039);
  });

  test('perft: promotion position', () {
    final p = fen('r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq -');
    expect(perft(p, 2), 264);
    expect(perft(p, 3), 9467);
  });

  test("fool's mate is checkmate", () {
    final p = chReplay(<String>['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    expect(p, isNotNull);
    expect(chLegal(p!), isEmpty);
    expect(chInCheck(p), true);
  });

  test('stalemate has no moves and no check', () {
    final p = fen('7k/5Q2/6K1/8/8/8/8/8 b - -');
    expect(chLegal(p), isEmpty);
    expect(chInCheck(p), false);
  });

  test('uci round trip, SAN and illegal moves', () {
    final p = ChessPos.start();
    expect(chFind(p, 'e2e4'), isNotNull);
    expect(chFind(p, 'e2e5'), isNull);
    final m = chFind(p, 'g1f3')!;
    expect(chSan(p, m, chLegal(p)), 'Nf3');
    expect(chReplay(<String>['e2e4', 'e2e4']), isNull);
  });

  test('insufficient material', () {
    expect(chInsufficient(fen('8/8/8/4k3/8/3K4/8/8 w - -')), true);
    expect(chInsufficient(fen('8/8/8/4k3/8/3K4/3N4/8 w - -')), true);
    expect(chInsufficient(fen('8/8/8/4k3/8/3K4/3P4/8 w - -')), false);
  });

  test('bot returns a legal move at every level', () {
    for (var lvl = 0; lvl < 3; lvl++) {
      final u = chessBotPick(<String>['e2e4', 'e7e5'], lvl, 7);
      expect(u, isNotNull);
      expect(chReplay(<String>['e2e4', 'e7e5', u!]), isNotNull);
    }
  });

  test('bot plays full random-ish games without illegal moves', () {
    final mvs = <String>[];
    for (var i = 0; i < 60; i++) {
      final u = chessBotPick(mvs, i % 2 == 0 ? 1 : 0, i);
      if (u == null) break;
      mvs.add(u);
    }
    expect(chReplay(mvs), isNotNull);
  });
}
