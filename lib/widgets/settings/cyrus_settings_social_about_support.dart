import 'package:flutter/material.dart';

/// فایل مستقل گزینه‌های:
/// 1. شبکه‌های مجازی
/// 2. درباره ما
/// 3. پشتیبانی
///
/// نکته:
/// این فایل در مرحله فعلی هیچ اتصال مستقیمی به main.dart
/// یا کلیدهای قدیمی پروژه ندارد.
///
/// زبان‌های آماده:
/// فارسی، انگلیسی، عربی، ترکی، روسی،
/// فرانسوی، آلمانی، اسپانیایی، چینی، ژاپنی

class CyrusSettingsSocialAboutSupport {
  CyrusSettingsSocialAboutSupport._();

  /// ساخت سه گزینه اصلی تنظیمات.
  static List<CyrusSettingsFeatureItem> buildItems({
    required String languageCode,
    VoidCallback? onSocialNetworks,
    VoidCallback? onAboutUs,
    VoidCallback? onSupport,
  }) {
    return [
      CyrusSettingsFeatureItem(
        icon: Icons.public_rounded,
        title: _text(
          languageCode,
          'شبکه‌های مجازی',
          'Social Networks',
          'شبكات التواصل الاجتماعي',
          'Sosyal Ağlar',
          'Социальные сети',
          'Réseaux sociaux',
          'Soziale Netzwerke',
          'Redes sociales',
          '社交网络',
          'ソーシャルネットワーク',
        ),
        subtitle: _text(
          languageCode,
          'صفحات رسمی سایروس توریست',
          'CyrusTourist official pages',
          'الصفحات الرسمية لسایروس توریست',
          'CyrusTourist resmi sayfaları',
          'Официальные страницы CyrusTourist',
          'Pages officielles de CyrusTourist',
          'Offizielle Seiten von CyrusTourist',
          'Páginas oficiales de CyrusTourist',
          'CyrusTourist 官方页面',
          'CyrusTourist公式ページ',
        ),
        iconBackground: const Color(0xff1769aa),
        iconForeground: Colors.white,
        onTap: onSocialNetworks,
      ),
      CyrusSettingsFeatureItem(
        icon: Icons.info_outline_rounded,
        title: _text(
          languageCode,
          'درباره ما',
          'About Us',
          'من نحن',
          'Hakkımızda',
          'О нас',
          'À propos de nous',
          'Über uns',
          'Sobre nosotros',
          '关于我们',
          '私たちについて',
        ),
        subtitle: _text(
          languageCode,
          'آشنایی با سایروس توریست',
          'Learn more about CyrusTourist',
          'تعرّف على سايروس توريست',
          'CyrusTourist hakkında bilgi',
          'Узнайте больше о CyrusTourist',
          'En savoir plus sur CyrusTourist',
          'Mehr über CyrusTourist erfahren',
          'Conoce más sobre CyrusTourist',
          '了解 CyrusTourist',
          'CyrusTouristについて',
        ),
        iconBackground: const Color(0xffb8860b),
        iconForeground: Colors.white,
        onTap: onAboutUs,
      ),
      CyrusSettingsFeatureItem(
        icon: Icons.support_agent_rounded,
        title: _text(
          languageCode,
          'پشتیبانی',
          'Support',
          'الدعم',
          'Destek',
          'Поддержка',
          'Assistance',
          'Support',
          'Soporte',
          '支持',
          'サポート',
        ),
        subtitle: _text(
          languageCode,
          'ارتباط با پشتیبانی سایروس توریست',
          'Contact CyrusTourist support',
          'تواصل مع دعم سايروس توريست',
          'CyrusTourist desteği ile iletişim',
          'Связаться с поддержкой CyrusTourist',
          'Contacter le support CyrusTourist',
          'CyrusTourist-Support kontaktieren',
          'Contactar con el soporte de CyrusTourist',
          '联系 CyrusTourist 支持',
          'CyrusTouristサポートに連絡',
        ),
        iconBackground: const Color(0xff8e244d),
        iconForeground: Colors.white,
        onTap: onSupport,
      ),
    ];
  }

  /// ترجمه مستقل برای ۱۰ زبان.
  ///
  /// ترتیب زبان‌ها:
  /// fa = فارسی
  /// en = English
  /// ar = العربية
  /// tr = Türkçe
  /// ru = Русский
  /// fr = Français
  /// de = Deutsch
  /// es = Español
  /// zh = 中文
  /// ja = 日本語
  static String _text(
    String languageCode,
    String fa,
    String en,
    String ar,
    String tr,
    String ru,
    String fr,
    String de,
    String es,
    String zh,
    String ja,
  ) {
    final code = languageCode.toLowerCase().split('-').first;

    switch (code) {
      case 'en':
        return en;

      case 'ar':
        return ar;

      case 'tr':
        return tr;

      case 'ru':
        return ru;

      case 'fr':
        return fr;

      case 'de':
        return de;

      case 'es':
        return es;

      case 'zh':
        return zh;

      case 'ja':
        return ja;

      case 'fa':
      default:
        return fa;
    }
  }
}

/// مدل مستقل هر گزینه تنظیمات.
class CyrusSettingsFeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBackground;
  final Color iconForeground;
  final VoidCallback? onTap;

  const CyrusSettingsFeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBackground,
    required this.iconForeground,
    this.onTap,
  });
}

/// ویجت دکمه سه‌بعدی تنظیمات سایروس توریست.
///
/// این ویجت فعلاً مستقل است و می‌تواند بعداً در
/// cyrus_settings_panel.dart یا cyrus_settings_screen.dart
/// مورد استفاده قرار بگیرد.
class CyrusSettingsFeatureButton extends StatefulWidget {
  final CyrusSettingsFeatureItem item;

  const CyrusSettingsFeatureButton({
    super.key,
    required this.item,
  });

  @override
  State<CyrusSettingsFeatureButton> createState() =>
      _CyrusSettingsFeatureButtonState();
}

class _CyrusSettingsFeatureButtonState
    extends State<CyrusSettingsFeatureButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  void _handleTap() {
    widget.item.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        _handleTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _pressed ? 3 : 0,
          0,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff243d4b),
                Color(0xff0b1c27),
              ],
            ),
            border: Border.all(
              color: const Color(0xffc9a227),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffc9a227).withOpacity(0.32),
                blurRadius: _pressed ? 5 : 12,
                spreadRadius: _pressed ? 0 : 1,
                offset: Offset(
                  0,
                  _pressed ? 2 : 6,
                ),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildIcon(item),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(CyrusSettingsFeatureItem item) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.iconBackground.withOpacity(0.95),
            item.iconBackground.withOpacity(0.62),
          ],
        ),
        border: Border.all(
          color: const Color(0xffffd966),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffc107).withOpacity(0.38),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        item.icon,
        color: item.iconForeground,
        size: 29,
      ),
    );
  }

  Widget _buildArrow() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xffc9a227).withOpacity(0.15),
        border: Border.all(
          color: const Color(0xffc9a227).withOpacity(0.65),
        ),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Color(0xffffd966),
        size: 15,
      ),
    );
  }
}

/// ساخت کامل سه دکمه برای استفاده در صفحه تنظیمات.
///
/// این تابع فقط UI را تولید می‌کند و هیچ اتصال اجباری
/// به ساختار اصلی پروژه ندارد.
class CyrusSettingsFeatureButtons extends StatelessWidget {
  final String languageCode;
  final VoidCallback? onSocialNetworks;
  final VoidCallback? onAboutUs;
  final VoidCallback? onSupport;

  const CyrusSettingsFeatureButtons({
    super.key,
    required this.languageCode,
    this.onSocialNetworks,
    this.onAboutUs,
    this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    final items = CyrusSettingsSocialAboutSupport.buildItems(
      languageCode: languageCode,
      onSocialNetworks: onSocialNetworks,
      onAboutUs: onAboutUs,
      onSupport: onSupport,
    );

    return Column(
      children: [
        for (final item in items)
          CyrusSettingsFeatureButton(
            item: item,
          ),
      ],
    );
  }
}
