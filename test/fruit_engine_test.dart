import 'dart:math';

import 'package:cyrustourist_app3/pages/games/fruit_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new levels start with no matches and at least one move', () {
    final e = FruitEngine(Random(3));
    for (var lv = 1; lv <= 12; lv++) {
      final l = e.setup(lv);
      expect(e.find(const <int>[]).isEmpty, true, reason: 'level $lv');
      expect(e.hasMove(), true);
      expect(l.goals.length, lv >= 4 ? 3 : 2);
      expect(l.moves >= 14, true);
    }
  });

  test('a 4-run makes a striped fruit at the swapped cell', () {
    final e = FruitEngine(Random(1));
    e.types = 6;
    for (var i = 0; i < 49; i++) {
      e.t[i] = (i * 2 + i ~/ 7) % 6;
      e.sp[i] = 0;
    }
    for (var c = 0; c < 4; c++) {
      e.t[3 * 7 + c] = 5;
    }
    e.t[3 * 7 + 4] = 0; // جلوی ردیف ۵تایی تصادفی را می‌گیرد
    final m = e.find(<int>[3 * 7 + 1]);
    expect(m.cells.length >= 4, true);
    expect(m.marks.any((x) => x[0] == 3 * 7 + 1 && x[1] == 1), true);
  });

  test('gravity fills the board and reports drops', () {
    final e = FruitEngine(Random(2));
    e.setup(1);
    e.t[48] = -1;
    e.t[41] = -1;
    final d = e.gravity();
    expect(e.t.every((v) => v >= 0), true);
    expect(d[48] >= 0, true);
  });

  test('expand: row special clears its row, bomb clears its colour', () {
    final e = FruitEngine(Random(4));
    e.setup(1);
    e.sp[10] = 1;
    final s = <int>{10};
    e.expand(s);
    for (var c = 0; c < 7; c++) {
      expect(s.contains(7 + c), true);
    }
    final e2 = FruitEngine(Random(5));
    e2.setup(1);
    e2.sp[0] = 3;
    final s2 = <int>{0};
    e2.expand(s2);
    expect(s2.length, e2.t.where((v) => v == e2.t[0]).length);
  });

  test('random play keeps the board valid', () {
    final rnd = Random(9);
    final e = FruitEngine(rnd);
    e.setup(5);
    for (var it = 0; it < 400; it++) {
      final a = rnd.nextInt(49);
      final b = rnd.nextBool() ? a + 1 : a + 7;
      if (b >= 49 || !e.adj(a, b)) continue;
      e.swapCells(a, b);
      var m = e.find(<int>[a, b]);
      if (m.isEmpty) {
        e.swapCells(a, b);
        continue;
      }
      var guard = 0;
      while (!m.isEmpty && guard++ < 50) {
        for (final x in m.marks) {
          m.cells.remove(x[0]);
        }
        e.expand(m.cells);
        for (final i in m.cells) {
          e.t[i] = -1;
          e.sp[i] = 0;
        }
        for (final x in m.marks) {
          e.sp[x[0]] = x[1];
        }
        e.gravity();
        m = e.find(const <int>[]);
      }
      expect(e.t.every((v) => v >= 0 && v < e.types), true);
      if (!e.hasMove()) e.reshuffle();
    }
  });
}
