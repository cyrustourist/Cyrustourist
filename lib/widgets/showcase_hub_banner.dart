import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/showcase_item.dart';

/// بنر تصویری بالای صفحه‌ی «نمایش فیلم»: عکس ثابت هاب (۴ کارت + نوار پایین)
/// را می‌گیرد و چهار ناحیه‌ی نامرئیِ قابل‌لمس روی آن می‌کشد که هرکدام با
/// یک سایه‌ی شیشه‌ای (glassmorphism) هنگام لمس روشن می‌شوند و به گالری
/// همان دسته هدایت می‌کنند.
///
/// ترتیب مطابق چیدمان تصویر «showcase-hub.jpg» است:
///   بالا‌راست   → اقامتگاه‌ها (accommodation)
///   بالا‌چپ     → جاذبه‌های گردشگری (attraction)
///   پایین‌راست  → گردشگری سلامت (health)
///   پایین‌چپ    → لیدر تور (leader)
/// (raster فارسی/RTL است پس در کد چپ/راست بر اساس درصد افقی مشخص می‌شود،
///  نه جهت متن؛ رجوع کنید به مستطیل‌های زیر.)
class ShowcaseHubBanner extends StatelessWidget {
  const ShowcaseHubBanner({
    super.key,
    required this.onSelect,
    this.highlight,
  });

  /// هنگام لمس هرکدام از ۴ ناحیه صدا زده می‌شود.
  final ValueChanged<ShowcaseKind> onSelect;

  /// اگر ست شود، ناحیه‌ی متناظر با یک قاب طلایی همیشه‌روشن مشخص می‌شود
  /// (مثلاً برای نشان دادن این‌که کاربر همین الان در همین بخش است).
  final ShowcaseKind? highlight;

  static const String _asset = 'assets/images/showcase-hub.jpg';
  static const double _aspect = 1280 / 853;

  // مستطیل‌های نسبی [left, top, width, height] برگرفته از تصویر مرجع.
  static const Rect _accommodation = Rect.fromLTWH(0.025, 0.035, 0.455, 0.42);
  static const Rect _attraction = Rect.fromLTWH(0.515, 0.035, 0.455, 0.42);
  static const Rect _health = Rect.fromLTWH(0.025, 0.455, 0.455, 0.325);
  static const Rect _leader = Rect.fromLTWH(0.515, 0.455, 0.455, 0.325);

  // نوار پایین تصویر «نمایش فیلم ویژه» → همان کلید ۶ صفحه‌ی اصلی (فیلم‌ها)
  static const Rect _showcaseStrip = Rect.fromLTWH(0.165, 0.795, 0.675, 0.16);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xff0b2636)),
                  ),
                  _quadrant(w, h, _accommodation, ShowcaseKind.accommodation),
                  _quadrant(w, h, _attraction, ShowcaseKind.attraction),
                  _quadrant(w, h, _health, ShowcaseKind.health),
                  _quadrant(w, h, _leader, ShowcaseKind.leader),
                  _quadrant(w, h, _showcaseStrip, ShowcaseKind.video, radius: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _quadrant(double w, double h, Rect r, ShowcaseKind kind, {double radius = 18}) {
    return Positioned(
      left: r.left * w,
      top: r.top * h,
      width: r.width * w,
      height: r.height * h,
      child: _GlassKey(
        selected: kind == highlight,
        radius: radius,
        onTap: () => onSelect(kind),
      ),
    );
  }
}

/// ناحیه‌ی تک: هنگام فشرده‌شدن یک لایه‌ی شیشه‌ایِ نیمه‌شفاف با بلور روی
/// خودش نشان می‌دهد (حس دکمه‌ی شیشه‌ای) و بعد onTap را صدا می‌زند.
class _GlassKey extends StatefulWidget {
  const _GlassKey({required this.onTap, required this.selected, this.radius = 18});

  final VoidCallback onTap;
  final bool selected;
  final double radius;

  @override
  State<_GlassKey> createState() => _GlassKeyState();
}

class _GlassKeyState extends State<_GlassKey> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: _pressed ? 1 : 0,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(
                  color: const Color(0xffffe39a).withValues(alpha: 0.9),
                  width: 1.6,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.32),
                    const Color(0xffffd36a).withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
