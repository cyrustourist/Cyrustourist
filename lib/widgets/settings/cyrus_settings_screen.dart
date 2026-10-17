import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../pages/about_page.dart' as about_page;
import '../../pages/support_page.dart';
import '../account/cyrus_account_screen.dart';
import '../../services/notification_service.dart';
import 'cyrus_settings_social_about_support.dart';
import 'cyrus_settings_theme.dart';
import '../home/cyrus_home_style.dart';
import 'cyrus_settings_notifications.dart';

/// صفحه تنظیمات سایروس توریست — مقصد کلید ☰ در هدر صفحه اصلی.
///
/// این صفحه چیز جدیدی نمی‌سازد؛ فقط سه ویجت مستقلی که قبلاً در
/// پوشه lib/widgets/settings/ آماده و کاملاً ۱۰‌زبانه ساخته شده
/// بودند را کنار هم قرار می‌دهد:
///   - CyrusSettingsFeatureButtons  → حساب کاربری / درباره ما / پشتیبانی
///     (به همان صفحات قدیمی و آماده وصل می‌شود: SocialMediaPage،
///     AboutPage، SupportPage — بدون ساخت صفحه تکراری)
///   - CyrusThemeSelector           → انتخاب ظاهر برنامه
///   - CyrusNotificationsSelector   → تنظیمات اعلان‌ها
///
/// انتخاب ظاهر و وضعیت اعلان‌ها با SharedPreferences ذخیره
/// می‌شوند تا بین اجراهای برنامه حفظ شوند.
class CyrusSettingsScreen extends StatefulWidget {
  const CyrusSettingsScreen({super.key});

  @override
  State<CyrusSettingsScreen> createState() => _CyrusSettingsScreenState();
}

class _CyrusSettingsScreenState extends State<CyrusSettingsScreen> {
  final CyrusHomeStyle _style = CyrusHomeStyle.instance;

  bool _notificationsEnabled = true;
  bool _soundEffectEnabled = true;

  bool _loaded = false;

  String get _languageCode => MenuLanguage.current;

  bool get _isRtl => MenuLanguage.isRtl;

  /// حالت نمایش فعلی صفحه‌ی اصلی → گزینه‌ی تم:
  /// روشن = روز | تاریک = شب | طلایی سایروس = شب + رنگ طلایی.
  CyrusThemeMode get _themeMode {
    if (_style.display == CyrusDisplayMode.day) {
      return CyrusThemeMode.light;
    }
    return _style.color == CyrusColorMode.gold
        ? CyrusThemeMode.cyrusGold
        : CyrusThemeMode.dark;
  }

  @override
  void initState() {
    super.initState();
    _style.addListener(_onStyleChanged);
    _loadPreferences();
  }

  @override
  void dispose() {
    _style.removeListener(_onStyleChanged);
    super.dispose();
  }

  void _onStyleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPreferences() async {
    // هر خطا یا گیر کردن در خواندن تنظیمات نباید مانع باز شدن صفحه شود.
    var pushEnabled = true;
    var soundEnabled = true;

    try {
      await _style.load().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Settings style load error: $e');
    }

    try {
      pushEnabled = await NotificationService.instance
          .isPushEnabled()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Settings push flag error: $e');
    }

    try {
      soundEnabled = await NotificationService.instance
          .isAnnouncementSoundEnabled()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Settings sound flag error: $e');
    }

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = pushEnabled;
      _soundEffectEnabled = soundEnabled;
      _loaded = true;
    });
  }

  /// انتخاب تم مستقیم روی ظاهر صفحه‌ی اصلی اعمال و ذخیره می‌شود.
  void _saveTheme(CyrusThemeMode mode) {
    switch (mode) {
      case CyrusThemeMode.light:
        _style.setDisplay(CyrusDisplayMode.day);
        break;
      case CyrusThemeMode.dark:
        _style.setDisplay(CyrusDisplayMode.night);
        if (_style.color == CyrusColorMode.gold) {
          _style.setColor(CyrusColorMode.blue);
        }
        break;
      case CyrusThemeMode.cyrusGold:
        _style.setDisplay(CyrusDisplayMode.night);
        _style.setColor(CyrusColorMode.gold);
        break;
    }
  }

  String _sectionTitle({
    required String fa,
    required String en,
    required String ar,
    required String tr,
    required String ru,
    required String fr,
    required String de,
    required String es,
    required String zh,
    required String it,
  }) {
    switch (_languageCode) {
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
      case 'it':
        return it;
      case 'fa':
      default:
        return fa;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xff071722),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xffffd36a),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    CyrusSettingsFeatureButtons(
                      languageCode: _languageCode,
                      onAccount: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CyrusAccountScreen(
                              languageCode: _languageCode,
                            ),
                          ),
                        );
                      },
                      onAboutUs: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => about_page.AboutPage(),
                          ),
                        );
                      },
                      onSupport: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    _buildSectionLabel(
                      _sectionTitle(
                        fa: 'انتخاب تم',
                        en: 'Theme',
                        ar: 'المظهر',
                        tr: 'Tema',
                        ru: 'Тема',
                        fr: 'Thème',
                        de: 'Design',
                        es: 'Tema',
                        zh: '主题',
                        it: 'Tema',
                      ),
                    ),
                    const SizedBox(height: 10),
                    CyrusThemeSelector(
                      selectedMode: _themeMode,
                      languageCode: _languageCode,
                      onChanged: _saveTheme,
                    ),
                    const SizedBox(height: 26),
                    _buildSectionLabel(
                      _sectionTitle(
                        fa: 'اعلان‌ها',
                        en: 'Notifications',
                        ar: 'الإشعارات',
                        tr: 'Bildirimler',
                        ru: 'Уведомления',
                        fr: 'Notifications',
                        de: 'Benachrichtigungen',
                        es: 'Notificaciones',
                        zh: '通知',
                        it: 'Notifiche',
                      ),
                    ),
                    const SizedBox(height: 10),
                    CyrusNotificationsSelector(
                      languageCode: _languageCode,
                      notificationsEnabled: _notificationsEnabled,
                      soundEffectEnabled: _soundEffectEnabled,
                      onNotificationsChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        NotificationService.instance.setPushEnabled(value);
                      },
                      onSoundEffectChanged: (value) {
                        setState(() => _soundEffectEnabled = value);
                        NotificationService.instance
                            .setAnnouncementSoundEnabled(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xff071722),
        border: Border(
          bottom: BorderSide(
            color: Color(0xff9b6a19),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: const Color(0xff9b6a19),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xffffd36a),
                  size: 23,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _sectionTitle(
                fa: 'تنظیمات',
                en: 'Settings',
                ar: 'الإعدادات',
                tr: 'Ayarlar',
                ru: 'Настройки',
                fr: 'Paramètres',
                de: 'Einstellungen',
                es: 'Ajustes',
                zh: '设置',
                it: 'Impostazioni',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xffffd36a),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.settings_outlined,
            color: Color(0xffffd36a),
            size: 27,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xffffd36a),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
