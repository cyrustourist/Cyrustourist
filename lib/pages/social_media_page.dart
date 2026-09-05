import 'package:flutter/material.dart';
import '../core/language/app_language.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه‌ی کلید ۷ — دنبال کنید.
/// لینک‌ها همان لینک‌های فعال نسخه قبلی هستند؛ فقط ظاهر صفحه مدرن شده است.
class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  String _title() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'دنبال کنید';
      case AppLanguage.arabic:
        return 'تابعنا';
      case AppLanguage.english:
        return 'Follow Us';
      case AppLanguage.german:
        return 'Folgen Sie uns';
      case AppLanguage.spanish:
        return 'Síguenos';
      case AppLanguage.french:
        return 'Suivez-nous';
      case AppLanguage.italian:
        return 'Seguici';
      case AppLanguage.russian:
        return 'Подписывайтесь на нас';
      case AppLanguage.turkish:
        return 'Bizi Takip Edin';
      case AppLanguage.chinese:
        return '关注我们';
    }
  }

  String _headline() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'با سایروس توریست همراه باشید';
      case AppLanguage.arabic:
        return 'كن مع سايروس توريست';
      case AppLanguage.english:
        return 'Stay with Cyrus Tourist';
      case AppLanguage.german:
        return 'Bleiben Sie bei Cyrus Tourist';
      case AppLanguage.spanish:
        return 'Mantente con Cyrus Tourist';
      case AppLanguage.french:
        return 'Restez avec Cyrus Tourist';
      case AppLanguage.italian:
        return 'Resta con Cyrus Tourist';
      case AppLanguage.russian:
        return 'Оставайтесь с Cyrus Tourist';
      case AppLanguage.turkish:
        return 'Cyrus Tourist ile Kalın';
      case AppLanguage.chinese:
        return '与Cyrus Tourist同行';
    }
  }

  String _description() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'جدیدترین فیلم‌ها و جاذبه‌های گردشگری ایران را دنبال کنید.';
      case AppLanguage.arabic:
        return 'تابع أحدث الأفلام والمعالم السياحية في إيران.';
      case AppLanguage.english:
        return 'Follow the latest videos and attractions of Iran.';
      case AppLanguage.german:
        return 'Folgen Sie den neuesten Videos und Attraktionen des Iran.';
      case AppLanguage.spanish:
        return 'Sigue los últimos vídeos y atracciones de Irán.';
      case AppLanguage.french:
        return "Suivez les dernières vidéos et attractions de l'Iran.";
      case AppLanguage.italian:
        return "Segui gli ultimi video e le attrazioni dell'Iran.";
      case AppLanguage.russian:
        return 'Следите за последними видео и достопримечательностями Ирана.';
      case AppLanguage.turkish:
        return "İran'ın en yeni videolarını ve gezilecek yerlerini takip edin.";
      case AppLanguage.chinese:
        return '关注伊朗最新的视频和景点。';
    }
  }

  String _socialTitle(String key) {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return {'instagram':'اینستاگرام','aparat':'آپارات','youtube':'یوتیوب','tiktok':'تیک‌تاک'}[key]!;
      case AppLanguage.arabic:
        return {'instagram':'إنستغرام','aparat':'أبارات','youtube':'يوتيوب','tiktok':'تيك توك'}[key]!;
      case AppLanguage.english:
      case AppLanguage.german:
      case AppLanguage.spanish:
      case AppLanguage.french:
      case AppLanguage.italian:
      case AppLanguage.russian:
      case AppLanguage.turkish:
      case AppLanguage.chinese:
        return {'instagram':'Instagram','aparat':'Aparat','youtube':'YouTube','tiktok':'TikTok'}[key]!;
    }
  }

  String _back() {
    switch (LanguageManager.current) {
      case AppLanguage.persian: return 'بازگشت';
      case AppLanguage.arabic: return 'رجوع';
      case AppLanguage.english: return 'Back';
      case AppLanguage.german: return 'Zurück';
      case AppLanguage.spanish: return 'Atrás';
      case AppLanguage.french: return 'Retour';
      case AppLanguage.italian: return 'Indietro';
      case AppLanguage.russian: return 'Назад';
      case AppLanguage.turkish: return 'Geri';
      case AppLanguage.chinese: return '返回';
    }
  }

  static const List<_SocialLink> _links = [
    _SocialLink(
      title: 'Instagram',
      subtitle: 'Cyrus Tourist',
      key: 'instagram',
      url: 'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
      icon: Icons.camera_alt_rounded,
      color: Color(0xffe1306c),
    ),
    _SocialLink(
      title: 'Aparat',
      subtitle: 'Cyrus Tourist',
      key: 'aparat',
      url: 'https://www.aparat.com/Cyrustourist',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xffff7043),
    ),
    _SocialLink(
      title: 'YouTube',
      subtitle: 'Cyrus Tourist',
      key: 'youtube',
      url: 'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i',
      icon: Icons.smart_display_rounded,
      color: Color(0xffff0000),
    ),
    _SocialLink(
      title: 'TikTok',
      subtitle: '@cyrustourist_app',
      key: 'tiktok',
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
          SnackBar(content: Text('Unable to open ${link.title}.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening ${link.title}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LanguageManager.current == AppLanguage.english
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff06121d),
        appBar: AppBar(
          backgroundColor: const Color(0xff06121d),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            _title(),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _headline(),
                              style: TextStyle(
                                color: Color(0xffffe39a),
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              _description(),
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
                    label: Text(
                      _back(),
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
                      _socialTitle(link.key),
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
  final String key;
  final String url;
  final IconData icon;
  final Color color;

  const _SocialLink({
    required this.title,
    required this.subtitle,
    required this.key,
    required this.url,
    required this.icon,
    required this.color,
  });
}
