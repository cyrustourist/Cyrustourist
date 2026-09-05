import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class LanguageService {
  static AppLanguage current = AppLanguage.english;

  static const String _languageKey = 'language';

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

    final code = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();

    current = _languageFromCode(code) ?? AppLanguage.english;
  }

  static Future<void> setLanguage(AppLanguage lang) async {
    current = lang;

    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      _languageKey,
      languageCode(lang),
    );
  }

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

  static String languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.persian:
        return 'فارسی';

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

  static bool get isRTL {
    return current == AppLanguage.persian ||
        current == AppLanguage.arabic;
  }

  static bool get isLTR {
    return !isRTL;
  }

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
