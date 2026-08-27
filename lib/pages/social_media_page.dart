import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه‌ی کلید ۷ — دنبال کنید.
/// لینک‌ها همان لینک‌های فعال نسخه قبلی هستند؛ فقط ظاهر صفحه مدرن شده است.
class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  static const List<_SocialLink> _links = [
    _SocialLink(
      title: 'اینستاگرام',
      subtitle: 'Cyrus Tourist',
      url: 'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
      icon: Icons.camera_alt_rounded,
      color: Color(0xffe1306c),
    ),
    _SocialLink(
      title: 'آپارات',
      subtitle: 'کانال رسمی Cyrus Tourist',
      url: 'https://www.aparat.com/Cyrustourist',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xffff7043),
    ),
    _SocialLink(
      title: 'یوتیوب',
      subtitle: 'Cyrus Tourist',
      url: 'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i',
      icon: Icons.smart_display_rounded,
      color: Color(0xffff0000),
    ),
    _SocialLink(
      title: 'تیک‌تاک',
      subtitle: '@cyrustourist_app',
      url: 'https://www.tiktok.com/@cyrustourist_app',
      icon: Icons.music_note_rounded,
      color: Color(0xff25f4ee),
    ),
  ];

  Future<void> _open(BuildContext context, _SocialLink link) async {
    final uri = Uri.parse(link.url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('امکان باز کردن ${link.title} وجود ندارد.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در باز کردن ${link.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff06121d),
        appBar: AppBar(
          backgroundColor: const Color(0xff06121d),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'دنبال کنید',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xff103b50), Color(0xff092331)],
                    ),
                    border: Border.all(
                      color: const Color(0xffffd36a).withValues(alpha: 0.42),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff071722),
                          border: Border.all(
                            color: const Color(0xffffd36a),
                            width: 1.6,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo-new.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'همراه سایروس توریست باشید',
                              style: TextStyle(
                                color: Color(0xffffe39a),
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'جدیدترین فیلم‌ها و جاذبه‌های ایران را دنبال کنید.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ..._links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _socialButton(context, link),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(
                      'بازگشت',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffffd36a),
                      side: BorderSide(
                        color: const Color(0xffffd36a).withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xffffd36a).withValues(alpha: 0.16),
        highlightColor: const Color(0xffffd36a).withValues(alpha: 0.08),
        onTap: () => _open(context, link),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                const Color(0xff0e2e3e),
                link.color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: const Color(0xffffd36a).withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [link.color, link.color.withValues(alpha: 0.62)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: link.color.withValues(alpha: 0.34),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(link.icon, color: Colors.white, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      link.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffffd36a), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLink {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color color;

  const _SocialLink({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.color,
  });
}
