import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cyrustourist_app3/pages/games/game_engine.dart' show BotLevel;
import 'package:cyrustourist_app3/pages/games/hokm_engine.dart';

void main() {
  test('deal: 52 distinct cards, 13 each', () {
    final h = HokmHand(hakem: 0, rnd: Random(1));
    final all = <int>{};
    for (final s in h.hands) {
      expect(s.length, 13);
      all.addAll(s.map((c) => c.id));
    }
    expect(all.length, 52);
  });

  test('must follow suit and trump beats lead suit', () {
    final h = HokmHand(hakem: 0, rnd: Random(2));
    h.trump = 1;
    h.hands[0] = <HCard>[const HCard(0, 5)];
    h.hands[1] = <HCard>[const HCard(0, 9), const HCard(1, 3)];
    h.hands[2] = <HCard>[const HCard(2, 4), const HCard(0, 14)];
    h.hands[3] = <HCard>[const HCard(0, 13)];
    expect(h.play(0, const HCard(0, 5)), true);
    expect(h.legal(1), <HCard>[const HCard(0, 9)]);
    expect(h.play(1, const HCard(1, 3)), false);
    expect(h.play(1, const HCard(0, 9)), true);
    expect(h.play(2, const HCard(2, 4)), false); // دارای پیک است
    expect(h.play(2, const HCard(0, 14)), true);
    expect(h.play(3, const HCard(0, 13)), true);
    expect(h.currentWinnerSeat(), 2);
  });

  test('points: normal / kot / hakem kot', () {
    expect(hokmHandPoints(winnerTeam: 0, loserTricks: 3, hakem: 0), 1);
    expect(hokmHandPoints(winnerTeam: 0, loserTricks: 0, hakem: 0), 2);
    expect(hokmHandPoints(winnerTeam: 1, loserTricks: 0, hakem: 0), 3);
    expect(hokmNextHakem(0, 0), 0);
    expect(hokmNextHakem(0, 1), 1);
  });

  test('bots finish full hands without illegal moves', () {
    for (final lvl in BotLevel.values) {
      for (var seed = 0; seed < 40; seed++) {
        final r = Random(seed);
        final bot = HokmBot(lvl, r);
        final h = HokmHand(hakem: seed % 4, rnd: r);
        h.trump = bot.pickTrump(h.hakemFirstFive());
        var guard = 0;
        while (!h.finished && guard++ < 60) {
          while (!h.trickFull) {
            final c = bot.choose(h, h.turn);
            expect(h.play(h.turn, c), true, reason: '$lvl seed $seed');
          }
          h.resolveTrick();
        }
        expect(h.finished, true);
        expect(h.tricksWon[0] + h.tricksWon[1], h.tricksPlayed);
      }
    }
  });
}
