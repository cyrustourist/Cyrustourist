import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'game_fx.dart';

/// برگهٔ تنظیم صدا: صدای تاس، حرکت مهره و برد. هر گزینه با لمس پیش‌نمایش می‌شود
/// و با «تأیید و ذخیره» روی گوشی ذخیره می‌شود.
Future<void> showGameSoundSheet(BuildContext context, {VoidCallback? onChanged}) async {
  await GameFx.load();
  if (!context.mounted) return;
  var enabled = GameFx.on;
  var dice = GameFx.dice;
  var move = GameFx.moveSound;
  var win = GameFx.winSound;
  var vol = GameFx.vol.toDouble();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setS) {
        Widget group(String title, String kind, List<List<String>> opts, String cur, void Function(String) pick) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(2, 14, 2, 8), child: Text(title, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15))),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in opts)
                    GestureDetector(
                      onTap: () {
                        pick(o[0]);
                        GameFx.vol = vol.round();
                        GameFx.preview(kind, o[0]);
                        setS(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cur == o[0] ? gGold : gPanel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cur == o[0] ? gGold : gLine),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(o[0] == 'off' ? Icons.volume_off_rounded : Icons.play_arrow_rounded, size: 18, color: cur == o[0] ? gBg : gGold),
                            const SizedBox(width: 6),
                            Text(o[1], style: TextStyle(color: cur == o[0] ? gBg : Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        }

        return Directionality(
          textDirection: gDir,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .86),
            decoration: const BoxDecoration(color: gBg, borderRadius: BorderRadius.vertical(top: Radius.circular(26)), boxShadow: <BoxShadow>[BoxShadow(color: Colors.black87, blurRadius: 24)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 44, height: 5, decoration: BoxDecoration(color: gLine, borderRadius: BorderRadius.circular(3))),
                Padding(padding: const EdgeInsets.only(top: 10), child: const Text('تنظیم صدا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: gGold,
                        title: const Text('صدا و لرزش', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        value: enabled,
                        onChanged: (v) => setS(() => enabled = v),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.volume_down_rounded, color: gMuted),
                          Expanded(child: Slider(value: vol, min: 10, max: 100, divisions: 9, activeColor: gGold, onChanged: (v) => setS(() => vol = v))),
                          const Icon(Icons.volume_up_rounded, color: gMuted),
                        ],
                      ),
                      group('صدای تاس', 'dice', GameFx.diceOptions, dice, (c) => dice = c),
                      group('صدای حرکت مهره', 'move', GameFx.moveOptions, move, (c) => move = c),
                      group('صدای شادی برنده', 'win', GameFx.winOptions, win, (c) => win = c),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () async {
                        await GameFx.saveSounds(enabled: enabled, diceCode: dice, moveCode: move, winCode: win, volume: vol.round());
                        onChanged?.call();
                        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                      },
                      child: const Text('تأیید و ذخیره', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  // اگر بدون ذخیره بسته شد، مقدارهای ذخیره‌شده برگردند
  await GameFx.load();
}
