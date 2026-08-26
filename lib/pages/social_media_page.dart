import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه‌ی کلید ۷ — شبکه‌های اجتماعی.
///
/// لیست آیکن‌های شبکه‌های اجتماعی سایروس توریست که با ضربه
/// روی هرکدام، لینک مربوطه در اپ خارجی باز می‌شود.
class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  static const List<_SocialLink> _links = [
    _SocialLink(
      title: 'اینستاگرام',
      url: 'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
      icon: Icons.camera_alt,
      color: Color(0xffE1306C),
    ),
    _SocialLink(
      title: 'آپارات',
      url: 'https://www.aparat.com/Cyrustourist',
      icon: Icons.play_circle_fill,
      color: Color(0xffFF5722),
    ),
    _SocialLink(
      title: 'یوتیوب',
      url: 'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i',
      icon: Icons.smart_display,
      color: Color(0xffFF0000),
    ),
    _SocialLink(
      title: 'تیک‌تاک',
      url: 'https://www.tiktok.com/@cyrustourist_app',
      icon: Icons.music_note,
      color: Color(0xff00F2EA),
    ),
    _SocialLink(
      title: 'تلگرام',
      url: 'https://t.me/Cyrustourist',
      icon: Icons.send,
      color: Color(0xff29B6F6),
    ),
  ];

  Future<void> _open(BuildContext context, _SocialLink link) async {
    final uri = Uri.parse(link.url);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('امکان باز کردن ${link.title} وجود ندارد.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در باز کردن ${link.title}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'دنبال کنید',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff0b506b),
                    border: Border.all(
                      color: const Color(0xffffd36a),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffffd36a).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Color(0xffffd36a),
                    size: 46,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'همراه سایروس توریست باشید',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                const Text(
                  'برای دیدن جدیدترین جاذبه‌های گردشگری، ویدیوهای'
                  ' اختصاصی و اخبار سفر به ایران، ما رو در شبکه‌های'
                  ' اجتماعی دنبال کنید.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                ..._links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _socialButton(context, link),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(BuildContext context, _SocialLink link) {
    return Material(
      color: const Color(0xff0e2532),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(context, link),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: link.color.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: link.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: link.color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(link.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  link.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLink {
  final String title;
  final String url;
  final IconData icon;
  final Color color;

  const _SocialLink({
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });
}
