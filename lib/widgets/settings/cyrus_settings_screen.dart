import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/language/menu_translations.dart';
import '../../pages/about_page.dart' as about_page;
import '../../pages/support_page.dart';
import '../../pages/social_media_page.dart';
import 'cyrus_settings_social_about_support.dart';
import 'cyrus_settings_theme.dart';
import 'cyrus_settings_notifications.dart';

/// صفحه تنظیمات سایروس توریست — مقصد کلید ☰ در هدر صفحه اصلی.
///
/// این صفحه چیز جدیدی نمی‌سازد؛ فقط سه ویجت مستقلی که قبلاً در
/// پوشه lib/widgets/settings/ آماده و کاملاً ۱۰‌زبانه ساخته شده
/// بودند را کنار هم قرار می‌دهد:
///   - CyrusSettingsFeatureButtons  → شبکه‌های مجازی / درباره ما / پشتیبانی
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
  static const _keyTheme = 'cyrus_settings_theme_mode';
  static const _keyNotifGeneral = 'cyrus_settings_notif_general';
  static const _keyNotifTourism = 'cyrus_settings_notif_tourism';
  static const _keyNotifTravelSuggestions =
      'cyrus_settings_notif_travel_suggestions';
  static const _keyNotifSupport = 'cyrus_settings_notif_support';

  CyrusThemeMode _themeMode = CyrusThemeMode.cyrusGold;

  bool _notificationsEnabled = true;
  bool _tourismNotificationsEnabled = true;
  bool _travelSuggestionsEnabled = true;
  bool _supportNotificationsEnabled = true;

  bool _loaded = false;

  String get _languageCode => MenuLanguage.current;

  bool get _isRtl => MenuLanguage.isRtl;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final pref = await SharedPreferences.getInstance();

    final savedTheme = pref.getString(_keyTheme);

    setState(() {
      _themeMode = _themeFromCode(savedTheme) ?? CyrusThemeMode.cyrusGold;
      _notificationsEnabled = pref.getBool(_keyNotifGeneral) ?? true;
      _tourismNotificationsEnabled =
          pref.getBool(_keyNotifTourism) ?? true;
      _travelSuggestionsEnabled =
          pref.getBool(_keyNotifTravelSuggestions) ?? true;
      _supportNotificationsEnabled =
          pref.getBool(_keyNotifSupport) ?? true;
      _loaded = true;
    });
  }

  CyrusThemeMode? _themeFromCode(String? code) {
    switch (code) {
      case 'light':
        return CyrusThemeMode.light;
      case 'dark':
        return CyrusThemeMode.dark;
      case 'cyrusGold':
        return CyrusThemeMode.cyrusGold;
      default:
        return null;
    }
  }

  String _themeToCode(CyrusThemeMode mode) {
    switch (mode) {
      case CyrusThemeMode.light:
        return 'light';
      case CyrusThemeMode.dark:
        return 'dark';
      case CyrusThemeMode.cyrusGold:
        return 'cyrusGold';
    }
  }

  Future<void> _saveTheme(CyrusThemeMode mode) async {
    setState(() => _themeMode = mode);
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_keyTheme, _themeToCode(mode));
    // نکته: اعمال واقعی تم روی کل برنامه (ThemeData) مرحله بعدی
    // است و باید همراه با بررسی رنگ‌های فعلی برنامه انجام شود؛
    // فعلاً فقط انتخاب کاربر ذخیره و در همین صفحه نمایش داده می‌شود.
  }

  Future<void> _saveBool(String key, bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(key, value);
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
                      onSocialNetworks: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SocialMediaPage(),
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
                      tourismNotificationsEnabled:
                          _tourismNotificationsEnabled,
                      travelSuggestionsEnabled: _travelSuggestionsEnabled,
                      supportNotificationsEnabled:
                          _supportNotificationsEnabled,
                      onNotificationsChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveBool(_keyNotifGeneral, value);
                      },
                      onTourismNotificationsChanged: (value) {
                        setState(
                          () => _tourismNotificationsEnabled = value,
                        );
                        _saveBool(_keyNotifTourism, value);
                      },
                      onTravelSuggestionsChanged: (value) {
                        setState(
                          () => _travelSuggestionsEnabled = value,
                        );
                        _saveBool(_keyNotifTravelSuggestions, value);
                      },
                      onSupportNotificationsChanged: (value) {
                        setState(
                          () => _supportNotificationsEnabled = value,
                        );
                        _saveBool(_keyNotifSupport, value);
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
