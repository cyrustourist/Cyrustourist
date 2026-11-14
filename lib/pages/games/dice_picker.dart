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

  String _status = '';
  bool _warn = false;

  Future<void> _tap(DiceSkin sk) async {
    if (_owned(sk)) {
      await DiceSkins.select(sk.code);
      if (!mounted) return;
      setState(() {
        _warn = false;
        _status = GameT.fa ? '✔ «${sk.faName}» انتخاب و ذخیره شد' : '✔ "${sk.enName}" selected & saved';
      });
    } else {
      setState(() {
        _warn = true;
        _status = GameT.fa ? '🔒 این تاس را از «فروشگاه» بخرید' : '🔒 Buy this die in the shop';
      });
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
            border: Border.all(color: selected ? gTeal : gLine, width: selected ? 2.2 : 1),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sharedDieSkin(sk.code, size: 54, v: 5),
                  const SizedBox(height: 6),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(
                    selected ? (GameT.fa ? 'فعال' : 'In use') : (owned ? (GameT.fa ? 'رایگان' : 'Free') : '🔒 ${sk.price}'),
                    style: TextStyle(color: selected ? gTeal : gMuted, fontWeight: FontWeight.w800, fontSize: 11.5),
                  ),
                ],
              ),
              if (selected)
                PositionedDirectional(
                  top: -6,
                  start: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: gTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: gBg, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded, size: 16, color: gBg),
                  ),
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
    final chipColor = _warn ? gGold : gTeal;
    final chipText = _status.isEmpty ? (GameT.fa ? '✔ تاس انتخابی شما ذخیره است' : '✔ Your dice choice is saved') : _status;
    return Directionality(
      textDirection: gDir,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scroll) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      key: ValueKey<String>('$_warn$chipText'),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: chipColor.withAlpha(36),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: chipColor),
                      ),
                      child: Text(chipText, textAlign: TextAlign.center, style: TextStyle(color: chipColor, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 14,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: gTeal,
                    foregroundColor: gBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(GameT.fa ? 'تأیید و بازگشت به بازی' : 'Confirm & back to game', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
