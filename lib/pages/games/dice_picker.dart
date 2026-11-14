import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'dice_games.dart' show sharedDieSkin;
import 'dice_skins.dart';
import 'game_api.dart';
import 'game_texts.dart';

/// برگهٔ انتخاب تاس (مثلاً داخل منچ). تاس‌های رایگان و خریداری‌شده با یک لمس فعال می‌شوند.
Future<void> showDicePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: gPanel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _DicePickerSheet(),
  );
}

class _DicePickerSheet extends StatefulWidget {
  const _DicePickerSheet();
  @override
  State<_DicePickerSheet> createState() => _DicePickerSheetState();
}

class _DicePickerSheetState extends State<_DicePickerSheet> {
  final GameWallet _w = GameWallet.instance;

  @override
  void initState() {
    super.initState();
    _w.addListener(_onChange);
    DiceSkins.current.addListener(_onChange);
  }

  @override
  void dispose() {
    _w.removeListener(_onChange);
    DiceSkins.current.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  bool _owned(DiceSkin sk) => sk.price == 0 || _w.owned.contains(sk.key);

  Future<void> _tap(DiceSkin sk) async {
    if (_owned(sk)) {
      await DiceSkins.select(sk.code);
    } else {
      gToast(context, GameT.fa ? 'این تاس را از «فروشگاه» بازی بخرید' : 'Buy this die in the game shop');
    }
  }

  Widget _tile(DiceSkin sk) {
    final owned = _owned(sk);
    final selected = DiceSkins.current.value == sk.code;
    final name = GameT.fa ? sk.faName : sk.enName;
    return GestureDetector(
      onTap: () => _tap(sk),
      child: Opacity(
        opacity: owned ? 1 : 0.55,
        child: Container(
          width: 98,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: gBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? gGold : gLine, width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sharedDieSkin(sk.code, size: 54, v: 5),
              const SizedBox(height: 6),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(
                selected ? (GameT.fa ? '✔ فعال' : '✔ In use') : (owned ? (GameT.fa ? 'رایگان' : 'Free') : '🔒 ${sk.price}'),
                style: TextStyle(color: selected ? gTeal : gMuted, fontWeight: FontWeight.w800, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = DiceSkins.skin;
    final list = <DiceSkin>[
      ...DiceSkins.all.where(_owned),
      ...DiceSkins.all.where((s) => !_owned(s)),
    ];
    return Directionality(
      textDirection: gDir,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(GameT.fa ? '🎲 انتخاب تاس' : '🎲 Choose your dice', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: gLine)),
              child: Column(
                children: [
                  Text(GameT.fa ? cur.faName : cur.enName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [for (var i = 1; i <= 6; i++) sharedDieSkin(cur.code, size: 44, v: i)],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [for (final sk in list) _tile(sk)],
            ),
            const SizedBox(height: 12),
            Text(
              GameT.fa ? 'تاس‌های قفل‌دار را از «فروشگاه» با سکه بخرید.' : 'Locked dice can be bought with coins in the shop.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: gMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
