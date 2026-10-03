import 'package:flutter/material.dart';

import '../map_place.dart';
import '../models/showcase_item.dart';
import '../services/showcase_service.dart';

/// بنر «فیلم VIP» زیر پنل شعاع جستجو، بالای لیست مکان‌ها.
///
/// هدف: هدایت کاربر به کلید «نمایش فیلم» همان بخش. هر بخش (اقامتگاه،
/// سلامت، جاذبه) عنوان، متن و رنگ مخصوص خودش را دارد.
/// [large] وقتی لیست در حال بارگذاری یا خالی است، بنر بزرگ‌تر نشان داده می‌شود.
class ShowcaseFilmBanner extends StatefulWidget {
  const ShowcaseFilmBanner({
    super.key,
    required this.category,
    required this.language,
    required this.onTap,
    this.large = false,
  });

  final PlaceCategory category;
  final String language; // fa / en / ar
  final VoidCallback onTap;
  final bool large;

  @override
  State<ShowcaseFilmBanner> createState() => _ShowcaseFilmBannerState();
}

class _BannerTheme {
  const _BannerTheme({
    required this.colors,
    required this.textColor,
    required this.pillBg,
    required this.pillText,
    required this.glow,
    required this.icon,
    required this.fa,
    required this.en,
    required this.ar,
  });

  final List<Color> colors;
  final Color textColor;
  final Color pillBg;
  final Color pillText;
  final Color glow;
  final IconData icon;
  final List<String> fa; // [title, subtitle]
  final List<String> en;
  final List<String> ar;
}

const Color _navy = Color(0xff071722);

// اقامتگاه: طلایی گرم / سلامت: سبز-فیروزه‌ای / جاذبه: بنفش-سرخابی
const _BannerTheme _stayTheme = _BannerTheme(
  colors: [Color(0xffffe08a), Color(0xffffb347), Color(0xffff8a3d)],
  textColor: _navy,
  pillBg: _navy,
  pillText: Color(0xffffd36a),
  glow: Color(0xffffa84a),
  icon: Icons.hotel_rounded,
  fa: ['فیلم اقامتگاه‌های ویژه را ببینید', 'قبل از رزرو، محل را با فیلم ببینید'],
  en: ['Watch featured stay videos', 'See the place on video before you book'],
  ar: ['شاهد فيديوهات الإقامات المميزة', 'شاهد المكان بالفيديو قبل الحجز'],
);

const _BannerTheme _healthTheme = _BannerTheme(
  colors: [Color(0xff7af0d0), Color(0xff1fd1b0), Color(0xff0ea5a0)],
  textColor: _navy,
  pillBg: _navy,
  pillText: Color(0xff7af0d0),
  glow: Color(0xff1fd1b0),
  icon: Icons.health_and_safety_rounded,
  fa: ['فیلم مراکز سلامت ویژه را ببینید', 'با اطمینان بیشتر مرکز درمانی را انتخاب کنید'],
  en: ['Watch featured health center videos', 'Choose your care with more confidence'],
  ar: ['شاهد فيديوهات المراكز الصحية المميزة', 'اختر مركزك العلاجي بثقة أكبر'],
);

const _BannerTheme _attractionTheme = _BannerTheme(
  colors: [Color(0xff8b6cff), Color(0xffb35cff), Color(0xffff5fb0)],
  textColor: Colors.white,
  pillBg: Colors.white,
  pillText: Color(0xff6a3df0),
  glow: Color(0xffb35cff),
  icon: Icons.auto_awesome_rounded,
  fa: ['فیلم جاذبه‌های ویژه را ببینید', 'پیش از سفر، جاذبه‌ها را با فیلم کشف کنید'],
  en: ['Watch featured attraction videos', 'Discover attractions on video before you go'],
  ar: ['شاهد فيديوهات المعالم المميزة', 'اكتشف المعالم بالفيديو قبل السفر'],
);

class _ShowcaseFilmBannerState extends State<ShowcaseFilmBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _loadCount();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  ShowcaseKind get _kind {
    switch (widget.category) {
      case PlaceCategory.accommodation:
        return ShowcaseKind.accommodation;
      case PlaceCategory.health:
        return ShowcaseKind.health;
      case PlaceCategory.attraction:
      default:
        return ShowcaseKind.video;
    }
  }

  // شمارش فوری و بدون شبکه: فقط فیلم‌های داخل برنامه. اگر صفر بود نمایش داده نمی‌شود.
  void _loadCount() {
    try {
      final items = ShowcaseService.localOnly(_kind).items;
      final n = items
          .where((e) => (e.videoUrl ?? '').trim().isNotEmpty)
          .length;
      if (n > 0) _count = n;
    } catch (_) {}
  }

  _BannerTheme get _theme {
    switch (widget.category) {
      case PlaceCategory.accommodation:
        return _stayTheme;
      case PlaceCategory.health:
        return _healthTheme;
      case PlaceCategory.attraction:
      default:
        return _attractionTheme;
    }
  }

  List<String> _texts(_BannerTheme t) {
    switch (widget.language) {
      case 'en':
        return t.en;
      case 'ar':
        return t.ar;
      default:
        return t.fa;
    }
  }

  String get _cta {
    switch (widget.language) {
      case 'en':
        return 'Watch videos';
      case 'ar':
        return 'شاهد الفيديوهات';
      default:
        return 'مشاهده فیلم‌ها';
    }
  }

  String get _countText {
    switch (widget.language) {
      case 'en':
        return '$_count videos';
      case 'ar':
        return '$_count فيديو';
      default:
        return '$_count فیلم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    final texts = _texts(t);
    final large = widget.large;
    final radius = BorderRadius.circular(large ? 24 : 20);

    return Padding(
      padding: EdgeInsets.fromLTRB(14, large ? 18 : 12, 14, large ? 6 : 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: t.glow.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: t.colors,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    // درخشش ملایم که هر چند ثانیه یک بار رد می‌شود
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) {
                            final v = _shine.value;
                            if (v > 0.45) return const SizedBox.shrink();
                            final x = -1.6 + (v / 0.45) * 3.2;
                            return Align(
                              alignment: Alignment(x, 0),
                              child: Transform.rotate(
                                angle: -0.35,
                                child: Container(
                                  width: 46,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.38),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // دایره‌ی تزئینی
                    PositionedDirectional(
                      end: -26,
                      top: -30,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: large ? 20 : 12,
                      ),
                      child: large
                          ? _largeContent(t, texts)
                          : _compactContent(t, texts),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playCircle(_BannerTheme t, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.pillBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: t.pillText,
        size: size * 0.62,
      ),
    );
  }

  Widget _vipPill(_BannerTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: t.pillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: t.pillText, size: 12),
          const SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              color: t.pillText,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countPill(_BannerTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: t.textColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _countText,
        style: TextStyle(
          color: t.textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _compactContent(_BannerTheme t, List<String> texts) {
    return Row(
      children: [
        _playCircle(t, 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _vipPill(t),
                  if (_count > 0) ...[
                    const SizedBox(width: 6),
                    _countPill(t),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                texts[0],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                texts[1],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textColor.withValues(alpha: 0.82),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          color: t.textColor,
          size: 28,
        ),
      ],
    );
  }

  Widget _largeContent(_BannerTheme t, List<String> texts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _vipPill(t),
            if (_count > 0) ...[
              const SizedBox(width: 6),
              _countPill(t),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _playCircle(t, 64),
        const SizedBox(height: 12),
        Text(
          texts[0],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.textColor,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texts[1],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.textColor.withValues(alpha: 0.85),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: t.pillBg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.icon, color: t.pillText, size: 16),
              const SizedBox(width: 7),
              Text(
                _cta,
                style: TextStyle(
                  color: t.pillText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
