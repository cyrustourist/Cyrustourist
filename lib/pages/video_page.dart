import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with TickerProviderStateMixin {
  static const Color backgroundColor = Color(0xff06121d);
  static const Color cardColor = Color(0xff0b2636);
  static const Color goldColor = Color(0xffffd36a);
  static const Color goldBright = Color(0xffffe39a);

  static const String aparatChannel =
      'https://www.aparat.com/Cyrustourist';

  final List<Map<String, String>> selectedVideos = const [
    {
      'title': 'قنات قصبه گناباد؛ شگفتی تاریخ تمدن بشر',
      'location': 'گناباد، خراسان رضوی',
      'category': 'میراث تاریخی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/w17sz69',
    },
    {
      'title': 'رقص محلی فاروق خراسانی با آهنگ لیلا',
      'location': 'خراسان',
      'category': 'فرهنگ و هنر',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/xvo5q9c',
    },
    {
      'title': 'چشمه گراب؛ جادوی طبیعت ایران',
      'location': 'خراسان رضوی',
      'category': 'طبیعت ایران',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/hzlol4k',
    },
    {
      'title': 'جنگل کوه‌پارک مشهد و قله زو',
      'location': 'مشهد، خراسان رضوی',
      'category': 'کوهنوردی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/guqcsg5',
    },
    {
      'title': 'کاشت بلوط؛ راه نجات جنگل‌های هیرکانی',
      'location': 'جنگل‌های هیرکانی',
      'category': 'محیط زیست',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/w8lOg',
    },
    {
      'title': 'آبشار شیرآباد؛ یکی از دیدنی‌های گلستان',
      'location': 'استان گلستان',
      'category': 'آبشار',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/uK3y5',
    },
    {
      'title': 'آبگوشت دیزی سنگی در طبیعت',
      'location': 'ایران',
      'category': 'گردشگری خوراک',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/nuXAC',
    },
    {
      'title': '۲۵ اردیبهشت؛ روز بزرگداشت فردوسی',
      'location': 'مشهد، خراسان رضوی',
      'category': 'فرهنگ و ادب',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/x707h19',
    },
    {
      'title': 'چشمه سبز گلمکان؛ دریاچه زیبای مشهد',
      'location': 'گلمکان، خراسان رضوی',
      'category': 'طبیعت ایران',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/4Z0hQ',
    },
    {
      'title': 'آموزش پخت سیب‌زمینی آتشی در طبیعت',
      'location': 'طبیعت ایران',
      'category': 'طبیعت‌گردی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/s78jcie',
    },
    {
      'title': 'جشن نوروز باستانی و سفره هفت‌سین',
      'location': 'ایران',
      'category': 'نوروز',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/R1p3U',
    },
    {
      'title': 'چایخانه حمام وکیل کرمان',
      'location': 'کرمان',
      'category': 'دیدنی‌های کرمان',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/g40wppg',
    },
    {
      'title': 'بجستان، آسبادهای نشتیفان و برج علی‌آباد کشمر',
      'location': 'خراسان رضوی',
      'category': 'میراث تاریخی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/xsBFX',
    },
    {
      'title': 'شاه نعمت‌الله ولی؛ ماهان کرمان',
      'location': 'ماهان، کرمان',
      'category': 'فرهنگ و تاریخ',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/3ZCGs',
    },
    {
      'title': 'باغ شاهزاده ماهان؛ شاهکار باغ ایرانی',
      'location': 'ماهان، کرمان',
      'category': 'باغ تاریخی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/z72q215',
    },
    {
      'title': 'موزه بانو حیاتی؛ گنجینه‌ای در بازار کرمان',
      'location': 'کرمان',
      'category': 'موزه',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/c4744bv',
    },
    {
      'title': 'قلعه سریزد؛ نخستین بانک جهان',
      'location': 'سریزد، یزد',
      'category': 'میراث تاریخی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/kGS8o',
    },
    {
      'title': 'جنگل‌های حرا و بندر تاریخی لافت',
      'location': 'جزیره قشم',
      'category': 'سواحل و جزایر',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/mPh2q',
    },
    {
      'title': 'باغ فین کاشان با موسیقی سنتی',
      'location': 'کاشان',
      'category': 'باغ تاریخی',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/h86ieq2',
    },
    {
      'title': 'زیباترین اقامتگاه بوم‌گردی در جنگل ابر',
      'location': 'جنگل ابر',
      'category': 'اقامتگاه',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/w43c127',
    },
    {
      'title': 'زیباترین اقامتگاه‌های بوم‌گردی ایران',
      'location': 'ایران',
      'category': 'اقامتگاه',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/k2RDX',
    },
    {
      'title': 'غار علی‌صدر؛ غار تالابی شگفت‌انگیز ایران',
      'location': 'همدان',
      'category': 'غار و طبیعت',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/f91418q',
    },
    {
      'title': 'آبشار اخلمد چناران؛ طبیعت زیبای خراسان',
      'location': 'چناران، خراسان رضوی',
      'category': 'آبشار',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/f5212r6',
    },
    {
      'title': 'جشن نوروز تخت جمشید؛ شهر پارس و پاسارگاد',
      'location': 'فارس',
      'category': 'میراث ایران',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/f38s8gz',
    },
    {
      'title': 'اقامتگاه‌ها و دیدنی‌های ایران',
      'location': 'ایران',
      'category': 'اقامتگاه',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/m37fn2a',
    },
    {
      'title': 'اقامتگاه بوم‌گردی قوامیه گناباد',
      'location': 'گناباد، خراسان رضوی',
      'category': 'بوم‌گردی',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/a528058',
    },
    {
      'title': 'اقامتگاه بوم‌گردی ناخدا علی در لافت',
      'location': 'جزیره قشم، بندر لافت',
      'category': 'بوم‌گردی',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/hLg1q',
    },
    {
      'title': 'موزه جانورشناسی؛ مجموعه‌ای کم‌نظیر از جانوران ایران',
      'location': 'ایران',
      'category': 'موزه و طبیعت',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/Cyrustourist',
    },
  ];

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'امکان باز کردن لینک آپارات وجود ندارد.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطا در باز کردن آپارات.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildAnimatedCategoryCard({
    required String image,
    required String title,
    required IconData icon,
  }) {
    return Expanded(
      child: _CategoryCard(
        image: image,
        title: title,
        icon: icon,
        onTap: () => _openUrl(aparatChannel),
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    Map<String, String> video,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: goldColor.withValues(alpha: 0.06),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: AspectRatio(
                aspectRatio: 16 / 8.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      video['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: const Color(0xff102c3b),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: goldColor,
                            size: 42,
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.68),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: goldColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          video['category']!,
                          style: const TextStyle(
                            color: goldBright,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: goldColor,
                        size: 58,
                      ),
                    ),
                    Positioned(
                      bottom: 9,
                      right: 12,
                      left: 12,
                      child: Text(
                        video['location']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goldColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    video['title']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openUrl(video['url']!),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'مشاهده',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: backgroundColor,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'نمایش فیلم‌های گردشگری',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    8,
                    10,
                    0,
                  ),
                  child: Column(
                    children: [
                      // تصویر ترکیبی جدید بالای صفحه.
                      // خود تصویر بدون فیلتر یا پوشش گرافیکی نمایش داده می‌شود
                      // تا کیفیت و جزئیات آن حفظ شود. دو ناحیه شفاف روی تصویر
                      // مانند دو کلید عمل می‌کنند.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AspectRatio(
                          aspectRatio: 1536 / 1024,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/video_menu_header.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return Container(
                                    color: backgroundColor,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: goldColor,
                                      size: 45,
                                    ),
                                  );
                                },
                              ),

                              // کلید شفاف سمت چپ: فیلم‌های اقامتی
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: MediaQuery.sizeOf(context).width * 0.5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _openUrl(aparatChannel),
                                ),
                              ),

                              // کلید شفاف سمت راست: جاذبه‌های گردشگری
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: MediaQuery.sizeOf(context).width * 0.5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _openUrl(aparatChannel),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff0b2a3c),
                              Color(0xff09202e),
                            ],
                          ),
                          border: Border.all(
                            color: goldColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    goldColor.withValues(alpha: 0.13),
                                border: Border.all(
                                  color:
                                      goldColor.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Icon(
                                Icons.ondemand_video_rounded,
                                color: goldColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'فیلم‌های منتخب گردشگری',
                                    style: TextStyle(
                                      color: goldBright,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ایران را زیبا ببینید.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: goldColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildVideoCard(
                      context,
                      selectedVideos[index],
                      index,
                    );
                  },
                  childCount: selectedVideos.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.image,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String image;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 230),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.955,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.20,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();

    if (!mounted) return;

    await _controller.reverse();

    if (!mounted) return;

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xffffd36a)
                        .withValues(alpha: 0.35),
                    const Color(0xffffd36a),
                    _glowAnimation.value,
                  )!,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffffd36a).withValues(
                      alpha: _glowAnimation.value * 0.45,
                    ),
                    blurRadius:
                        10 + (_glowAnimation.value * 17),
                    spreadRadius:
                        _glowAnimation.value * 1.8,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color: const Color(0xff102c3b),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xffffd36a),
                          size: 45,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff071722)
                            .withValues(alpha: 0.72),
                        border: Border.all(
                          color: const Color(0xffffd36a)
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color(0xffffd36a),
                        size: 23,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff071722)
                            .withValues(alpha: 0.74),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xffffd36a)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xffffd36a),
                            size: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
