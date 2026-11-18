import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cyrustourist_app3/pages/games/hokm_engine.dart' show HCard;
import 'package:cyrustourist_app3/pages/games/hokm_match.dart';

HokmMatch _mk() => HokmMatch(
      players: List<HokmPlayer>.generate(4, (i) => HokmPlayer(name: 'p$i', avatar: '0')),
      rnd: Random(3),
    );

void main() {
  test('پنج کارت اول و بعد سیزده کارت', () {
    final m = _mk()..start();
    expect(m.phase, HokmPhase.choose);
    for (final h in m.hands) {
      expect(h.length, 5);
    }
    expect(m.act(m.chooser, <String, dynamic>{'k': 'choose', 'o': '1'}), true);
    expect(m.phase, HokmPhase.play);
    expect(m.trump, 1);
    for (final h in m.hands) {
      expect(h.length, 13);
    }
    m.destroy();
  });

  test('۷ یار فقط برای حاکم و حکم همیشه یک خال معتبر است', () {
    final m = _mk()..start();
    expect(m.act((m.hakem + 1) % 4, <String, dynamic>{'k': 'choose', 'o': 'seven'}), false);
    expect(m.act(m.hakem, <String, dynamic>{'k': 'choose', 'o': 'seven'}), true);
    expect(m.seven, true);
    expect(m.trump >= 0 && m.trump <= 3, true);
    m.destroy();
  });

  test('هم‌خال بودن اجباری است', () {
    final m = _mk()..start();
    m.act(m.chooser, <String, dynamic>{'k': 'choose', 'o': '0'});
    final lead = m.turn;
    final c = m.hands[lead].first;
    expect(m.act(lead, <String, dynamic>{'k': 'play', 'c': c.id}), true);
    final next = m.turn;
    final legal = m.legal(next);
    final bad = m.hands[next].where((x) => !legal.contains(x)).toList();
    if (bad.isNotEmpty) {
      expect(m.act(next, <String, dynamic>{'k': 'play', 'c': bad.first.id}), false);
    }
    m.destroy();
  });

  test('ترتیب قدرت کارت‌ها در نرس، تک نرس و سرس', () {
    int v(int r, HokmKind k) => hokmRankValue(HCard(0, r), k);
    // نرس: ۲ قوی‌ترین، آس ضعیف‌ترین
    expect(v(2, HokmKind.nars) > v(5, HokmKind.nars), true);
    expect(v(5, HokmKind.nars) > v(14, HokmKind.nars), true);
    // تک نرس: آس از همه قوی‌تر، بعد ۲، و شاه ضعیف‌ترین
    expect(v(14, HokmKind.tak) > v(2, HokmKind.tak), true);
    expect(v(2, HokmKind.tak) > v(3, HokmKind.tak), true);
    expect(v(3, HokmKind.tak) > v(13, HokmKind.tak), true);
    // سرس: مثل حکم، آس بالاترین
    expect(v(14, HokmKind.sars) > v(13, HokmKind.sars), true);
    expect(v(3, HokmKind.sars) > v(2, HokmKind.sars), true);
  });
}
