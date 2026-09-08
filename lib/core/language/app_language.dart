import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// زبان‌های پشتیبانی‌شده در برنامه سایروس توریست.
///
/// ترتیب و نام این enum را در صورت استفاده در فایل‌های دیگر تغییر ندهید.
enum AppLanguage {
  persian,
  english,
  arabic,
  german,
  spanish,
  french,
  italian,
  russian,
  turkish,
  chinese,
}

class LanguageManager {
  /// زبان پیش‌فرض برنامه
  static AppLanguage current = AppLanguage.english;

  /// کد ذخیره‌شده زبان
  static const String _languageKey = 'language';

  /// بارگذاری زبان ذخیره‌شده.
  ///
  /// اگر قبلاً زبان توسط کاربر انتخاب شده باشد،
  /// همان زبان استفاده می‌شود.
  ///
  /// اگر زبان ذخیره نشده باشد، زبان دستگاه بررسی می‌شود.
  /// در صورت پشتیبانی نبودن زبان دستگاه، انگلیسی انتخاب می‌شود.
  static Future<void> load() async {
    final pref = await SharedPreferences.getInstance();

    final saved = pref.getString(_languageKey);

    if (saved != null) {
      final savedLanguage = _languageFromCode(saved);

      if (savedLanguage != null) {
        current = savedLanguage;
        return;
      }
    }

    // اگر زبان قبلاً ذخیره نشده باشد،
    // زبان سیستم عامل دستگاه بررسی می‌شود.
    final code = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();

    current = _languageFromCode(code) ?? AppLanguage.english;
  }

  /// تغییر زبان برنامه و ذخیره آن برای دفعات بعد.
  static Future<void> setLanguage(
    AppLanguage language,
  ) async {
    current = language;

    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      _languageKey,
      languageCode(language),
    );
  }

  /// تبدیل AppLanguage به کد استاندارد زبان.
  static String languageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.persian:
        return 'fa';

      case AppLanguage.english:
        return 'en';

      case AppLanguage.arabic:
        return 'ar';

      case AppLanguage.german:
        return 'de';

      case AppLanguage.spanish:
        return 'es';

      case AppLanguage.french:
        return 'fr';

      case AppLanguage.italian:
        return 'it';

      case AppLanguage.russian:
        return 'ru';

      case AppLanguage.turkish:
        return 'tr';

      case AppLanguage.chinese:
        return 'zh';
    }
  }

  /// تبدیل کد زبان به AppLanguage.
  ///
  /// در صورت ناشناخته بودن کد، null برمی‌گرداند.
  static AppLanguage? _languageFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'fa':
        return AppLanguage.persian;

      case 'en':
        return AppLanguage.english;

      case 'ar':
        return AppLanguage.arabic;

      case 'de':
        return AppLanguage.german;

      case 'es':
        return AppLanguage.spanish;

      case 'fr':
        return AppLanguage.french;

      case 'it':
        return AppLanguage.italian;

      case 'ru':
        return AppLanguage.russian;

      case 'tr':
        return AppLanguage.turkish;

      case 'zh':
        return AppLanguage.chinese;

      default:
        return null;
    }
  }

  /// نام زبان برای نمایش در منوی انتخاب زبان.
  static String languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.persian:
        return 'پارسی';

      case AppLanguage.english:
        return 'English';

      case AppLanguage.arabic:
        return 'العربية';

      case AppLanguage.german:
        return 'Deutsch';

      case AppLanguage.spanish:
        return 'Español';

      case AppLanguage.french:
        return 'Français';

      case AppLanguage.italian:
        return 'Italiano';

      case AppLanguage.russian:
        return 'Русский';

      case AppLanguage.turkish:
        return 'Türkçe';

      case AppLanguage.chinese:
        return '中文';
    }
  }

  /// نام کوتاه زبان برای استفاده در رابط کاربری.
  static String languageNativeName(AppLanguage language) {
    return languageName(language);
  }

  /// مشخص می‌کند زبان راست‌به‌چپ است یا چپ‌به‌راست.
  static bool get isRTL {
    return current == AppLanguage.persian ||
        current == AppLanguage.arabic;
  }

  /// مشخص می‌کند زبان چپ‌به‌راست است.
  static bool get isLTR {
    return !isRTL;
  }

  /// دریافت Locale مناسب برای Flutter.
  static Locale get locale {
    switch (current) {
      case AppLanguage.persian:
        return const Locale('fa');

      case AppLanguage.english:
        return const Locale('en');

      case AppLanguage.arabic:
        return const Locale('ar');

      case AppLanguage.german:
        return const Locale('de');

      case AppLanguage.spanish:
        return const Locale('es');

      case AppLanguage.french:
        return const Locale('fr');

      case AppLanguage.italian:
        return const Locale('it');

      case AppLanguage.russian:
        return const Locale('ru');

      case AppLanguage.turkish:
        return const Locale('tr');

      case AppLanguage.chinese:
        return const Locale('zh');
    }
  }

  /// فهرست تمام زبان‌های قابل انتخاب در برنامه.
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage.persian,
    AppLanguage.english,
    AppLanguage.arabic,
    AppLanguage.german,
    AppLanguage.spanish,
    AppLanguage.french,
    AppLanguage.italian,
    AppLanguage.russian,
    AppLanguage.turkish,
    AppLanguage.chinese,
  ];
}
