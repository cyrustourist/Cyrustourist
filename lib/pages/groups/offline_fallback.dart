import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../services/offline_cache.dart';
import 'group_ui.dart';

/// متن دو زبانه‌ی ساده برای بخش آفلاین (فارسی / انگلیسی).
String offT(String fa, String en) => MenuLanguage.current == 'fa' ? fa : en;

/// وقتی اینترنت قطع است: پیام خطا + تلاش دوباره + لیست ذخیره‌شده برای گفتگو از راه شبکه‌ی آفلاین.
List<Widget> offlineFallback({
  required String message,
  required VoidCallback onRetry,
  required String retryLabel,
  required String heading,
  required String emptyText,
  required List<OfflineItem> items,
  required IconData icon,
  required void Function(OfflineItem item) onOpen,
  required VoidCallback onNetwork,
}) {
  return <Widget>[
    Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: gMuted))),
    const SizedBox(height: 10),
    Center(child: OutlinedButton(onPressed: onRetry, child: Text(retryLabel))),
    const SizedBox(height: 22),
    Text(heading, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
    const SizedBox(height: 4),
    Text(
      offT('با روشن‌کردن شبکه‌ی آفلاین با افراد نزدیک گفتگو کنید (بدون اینترنت).', 'Turn on the offline network to chat with people nearby (no internet).'),
      style: const TextStyle(color: gMuted, fontSize: 12, height: 1.7),
    ),
    const SizedBox(height: 10),
    if (items.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(emptyText, style: const TextStyle(color: gMuted, height: 1.7)),
      ),
    for (final it in items)
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
        child: ListTile(
          onTap: () => onOpen(it),
          leading: Icon(icon, color: gTeal),
          title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.wifi_tethering_rounded, color: gGold, size: 20),
        ),
      ),
    const SizedBox(height: 14),
    FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(46)),
      onPressed: onNetwork,
      icon: const Icon(Icons.wifi_tethering_rounded),
      label: Text(offT('شبکه‌ی آفلاین گردشگران', 'Offline Tourist Network'), style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  ];
}
