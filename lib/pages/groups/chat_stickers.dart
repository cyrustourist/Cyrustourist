import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'group_ui.dart';

/// استیکرها ایموجی یونیکد هستند (بدون فایل تصویری): حجم صفر، ارسال فوری و سازگار با همهٔ گوشی‌ها.
/// فقط ایموجی‌های قدیمی‌تر از یونیکد ۱۴ انتخاب شده‌اند تا روی اندرویدهای قدیمی مربع خالی نشان داده نشود.
const List<(String, List<String>)> kStickerPacks = [
  ('😀', ['😀', '😁', '😂', '🤣', '😊', '😍', '🥰', '😘', '😎', '🤩', '🥳', '😇', '🤗', '🤔', '😴', '😭', '😡', '🥺', '😱', '🤯', '😅', '😉', '🙃', '😋', '😜', '🤤', '😬', '🙄', '😏', '🥵']),
  ('👍', ['👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '✌️', '🤞', '👌', '👋', '🤙', '👀', '🤟', '☝️', '👊', '🤲', '✍️', '🖐️', '🤷']),
  ('❤️', ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💔', '💕', '💖', '💯', '🔥', '✨', '🎉', '🎁', '🎂', '🌹', '🌸', '💐', '😻']),
  ('✈️', ['✈️', '🏖️', '🏝️', '🏔️', '🌴', '🌅', '🗺️', '🧳', '🚗', '🚕', '🚌', '🚢', '🏨', '⛺', '🏛️', '🕌', '🍽️', '☕', '🍕', '🍢', '🍉', '🌊', '📸', '🎒', '🧭', '🏄', '🤿', '🎡']),
  ('🐱', ['🐱', '🐶', '🦁', '🐯', '🐼', '🐨', '🦊', '🐵', '🐧', '🦋', '🐢', '🐬', '🐎', '🦅', '🐪', '🐑']),
  ('⚽', ['⚽', '🏆', '🎶', '🎤', '🎮', '🎈', '🌞', '🌙', '⭐', '☔', '⛄', '🍀', '💡', '📌', '✅', '❌']),
];

const String _kRecentKey = 'chat_recent_stickers';

/// آیا متن فقط ۱ تا ۳ ایموجی است؟ (نمایش بزرگ به‌صورت استیکر)
bool isStickerText(String text) {
  final t = text.replaceAll(RegExp(r'\s+'), '');
  if (t.isEmpty || t.length > 24) return false;
  var units = 0;
  for (final r in t.runes) {
    if (r == 0xFE0F || r == 0x200D || (r >= 0x1F3FB && r <= 0x1F3FF)) continue;
    final emoji = r >= 0x1F000 || (r >= 0x2190 && r <= 0x2BFF) || r == 0x3030 || r == 0x303D || r == 0x3297 || r == 0x3299;
    if (!emoji) return false;
    if (r >= 0x1F1E6 && r <= 0x1F1FF) {
      units++; // پرچم = دو نشانه
      continue;
    }
    units++;
  }
  return units >= 1 && units <= 6 && !_hasLongSequence(t);
}

bool _hasLongSequence(String t) => t.runes.where((r) => r != 0xFE0F && r != 0x200D).length > 6;

Future<List<String>> _loadRecent() async {
  try {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_kRecentKey) ?? <String>[];
  } catch (_) {
    return <String>[];
  }
}

Future<void> _pushRecent(String s) async {
  try {
    final p = await SharedPreferences.getInstance();
    final l = p.getStringList(_kRecentKey) ?? <String>[];
    l.remove(s);
    l.insert(0, s);
    await p.setStringList(_kRecentKey, l.take(18).toList());
  } catch (_) {}
}

/// برگه انتخاب استیکر؛ نتیجه = ایموجی انتخاب‌شده (برای ارسال فوری) یا null.
Future<String?> showStickerPicker(BuildContext context) async {
  final recent = await _loadRecent();
  if (!context.mounted) return null;
  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: gPanel,
    builder: (ctx) {
      final packs = <(String, List<String>)>[
        if (recent.isNotEmpty) ('🕘', recent),
        ...kStickerPacks,
      ];
      return Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: SizedBox(
            height: 330,
            child: DefaultTabController(
              length: packs.length,
              child: Column(children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: gGold,
                  dividerColor: gLine,
                  tabs: [for (final p in packs) Tab(child: Text(p.$1, style: const TextStyle(fontSize: 22)))],
                ),
                Expanded(
                  child: TabBarView(children: [
                    for (final p in packs)
                      GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 64, mainAxisSpacing: 6, crossAxisSpacing: 6),
                        itemCount: p.$2.length,
                        itemBuilder: (_, i) => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(ctx).pop(p.$2[i]),
                          child: Center(child: Text(p.$2[i], style: const TextStyle(fontSize: 34))),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    },
  );
  if (picked != null) await _pushRecent(picked);
  return picked;
}
