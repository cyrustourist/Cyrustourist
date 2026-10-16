import 'package:flutter/material.dart';

import '../services/call_texts.dart';
import '../services/story_service.dart';

/// عکس پروفایل کاربر (از سرور)؛ اگر نبود حرف اول نام.
class CallAvatar extends StatelessWidget {
  const CallAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.radius = 24,
    this.hasPhoto = true,
    this.background = const Color(0xff1f3a32),
    this.foreground = const Color(0xffffd36a),
  });

  final String uid;
  final String name;
  final double radius;
  final bool hasPhoto;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '؟' : trimmed.characters.first;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: background,
      child: Text(
        initial,
        style: TextStyle(color: foreground, fontSize: radius * 0.9, fontWeight: FontWeight.w700),
      ),
    );
    if (!hasPhoto || uid.isEmpty) return ClipOval(child: fallback);
    return ClipOval(
      child: Image.network(
        StoryService.photoUrl(uid),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

/// انتخاب مدت بلاک تماس. خروجی: ساعت (۱، ۲۴، ۱۶۸) یا ۰ = تا وقتی خودم بردارم؛ لغو = null.
Future<int?> showBlockDurationSheet(BuildContext context, String name) {
  Widget option(BuildContext ctx, IconData icon, String label, int hours) => ListTile(
        leading: Icon(icon, color: const Color(0xffffd36a)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () => Navigator.of(ctx).pop(hours),
      );

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: const Color(0xff0e2433),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => Directionality(
      textDirection: CT.fa ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                CT.t('block_title', {'name': name}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.6),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                CT.t('block_note'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.6),
              ),
            ),
            const SizedBox(height: 8),
            option(ctx, Icons.timer_outlined, CT.t('block_1h'), 1),
            option(ctx, Icons.today_rounded, CT.t('block_24h'), 24),
            option(ctx, Icons.date_range_rounded, CT.t('block_7d'), 168),
            option(ctx, Icons.block_rounded, CT.t('block_forever'), 0),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );
}
