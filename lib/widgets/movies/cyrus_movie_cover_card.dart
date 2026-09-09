import 'package:flutter/material.dart';

import '../../models/cyrus_movie_entry.dart';

/// رنگ‌های محلی همین ویجت — عمداً از رنگ‌های موجود در video_page.dart
/// کپی شده تا اگر این فایل و video_page.dart با هم import شوند، تداخل نام
/// پیش نیاید (این‌ها private هستند، خارج از فایل دیده نمی‌شوند).
const Color _cardBg = Color(0xff0b2636);
const Color _goldColor = Color(0xffffd36a);
const Color _tealColor = Color(0xff29e0ad);

/// یک کارت کاور برای یک فیلم: عکس کاور + گرادیان تیره + عنوان/موقعیت +
/// نشان کد یکتا (بالا-راست) + ستاره‌ی پین اگر کد رند/ویژه باشد.
/// با تپ‌کردن روی کارت، [onTap] صدا زده می‌شود (مثلاً برای بازکردن
/// صفحه‌ی کامل امکانات آن فیلم).
class CyrusMovieCoverCard extends StatelessWidget {
  final CyrusMovieEntry entry;
  final String languageCode;
  final VoidCallback onTap;

  const CyrusMovieCoverCard({
    super.key,
    required this.entry,
    required this.languageCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = entry.text('title', languageCode);
    final String location = entry.text('location', languageCode);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _goldColor.withValues(alpha: 0.25)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                entry.coverImage,
                fit: BoxFit.cover,
              ),
              // گرادیان تیره پایین کارت برای خوانا بودن متن روی عکس
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xcc06121d),
                    ],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              // نشان کد یکتا — بالا سمت راست
              Positioned(
                top: 8,
                right: 8,
                child: _Badge(
                  color: _goldColor,
                  icon: entry.isPinned ? Icons.push_pin_rounded : null,
                  text: '#${entry.uniqueCode}',
                ),
              ),
              // ستاره‌ی پین (اگر کد رند/ویژه پین شده) — بالا سمت چپ
              if (entry.isPinned)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: _Badge(
                    color: _tealColor,
                    icon: Icons.star_rounded,
                    text: null,
                  ),
                ),
              // عنوان و موقعیت — پایین کارت
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? text;

  const _Badge({required this.color, this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xcc06121d),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12, color: color),
          if (icon != null && text != null) const SizedBox(width: 3),
          if (text != null)
            Text(
              text!,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// یک SliverGrid آماده برای نمایش لیستی از فیلم‌ها به‌صورت کارت کاور
/// (۲ ستونه). برای استفاده در CustomScrollView موجود در video_page.dart:
///
///   CyrusMovieCoverGrid(
///     entries: kDefaultMovieEntries,
///     languageCode: _languageCode,
///     onTapEntry: (entry) { /* بازکردن صفحه‌ی کامل امکانات */ },
///   )
class CyrusMovieCoverGrid extends StatelessWidget {
  final List<CyrusMovieEntry> entries;
  final String languageCode;
  final void Function(CyrusMovieEntry entry) onTapEntry;

  const CyrusMovieCoverGrid({
    super.key,
    required this.entries,
    required this.languageCode,
    required this.onTapEntry,
  });

  @override
  Widget build(BuildContext context) {
    // اگر جستجو نتیجه‌ای نداشت، خودِ صفحه‌ی صداکننده مسئول نشان‌دادن
    // پیام «به‌زودی» است؛ این ویجت فقط وقتی entries خالی نیست رندر شود.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return CyrusMovieCoverCard(
          entry: entry,
          languageCode: languageCode,
          onTap: () => onTapEntry(entry),
        );
      },
    );
  }
}
