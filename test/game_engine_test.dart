import 'package:cyrustourist_app3/pages/games/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tic-tac-toe: win line and illegal move', () {
    var b = GameEngine.emptyBoard(GameKind.ttt);
    for (final step in const [
      [1, 0], [2, 3], [1, 1], [2, 4],
    ]) {
      b = GameEngine.apply(GameKind.ttt, b, step[0], step[1])!.board;
    }
    expect(GameEngine.apply(GameKind.ttt, b, 1, 0), isNull);
    final r = GameEngine.apply(GameKind.ttt, b, 1, 2)!;
    expect(r.winner, 1);
    expect(r.line, [0, 1, 2]);
  });

  test('connect four: vertical win and full column', () {
    var b = GameEngine.emptyBoard(GameKind.c4);
    for (var i = 0; i < 3; i++) {
      b = GameEngine.apply(GameKind.c4, b, 1, 0)!.board;
      b = GameEngine.apply(GameKind.c4, b, 2, 1)!.board;
    }
    expect(GameEngine.apply(GameKind.c4, b, 1, 0)!.winner, 1);
    var full = GameEngine.emptyBoard(GameKind.c4);
    for (var i = 0; i < 6; i++) {
      full = GameEngine.apply(GameKind.c4, full, i.isEven ? 1 : 2, 6)!.board;
    }
    expect(GameEngine.apply(GameKind.c4, full, 1, 6), isNull);
  });

  test('hard tic-tac-toe bot never loses to random play', () {
    for (var g = 0; g < 40; g++) {
      var b = GameEngine.emptyBoard(GameKind.ttt);
      var turn = 1;
      var winner = 0;
      while (winner == 0 && GameEngine.legalMoves(GameKind.ttt, b).isNotEmpty) {
        final legal = GameEngine.legalMoves(GameKind.ttt, b);
        final mv = turn == 1
            ? GameEngine.bot(GameKind.ttt, b, 1, BotLevel.hard)
            : legal[(g + b.where((e) => e != 0).length) % legal.length];
        final r = GameEngine.apply(GameKind.ttt, b, turn, mv)!;
        b = r.board;
        winner = r.winner;
        turn = turn == 1 ? 2 : 1;
      }
      expect(winner == 2, isFalse);
    }
  });
}
