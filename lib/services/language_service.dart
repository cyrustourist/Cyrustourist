import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  persian,
  english,
  arabic,
}

class LanguageService {
  static AppLanguage current = AppLanguage.english;

  static Future<void> load() async {
    final pref = await SharedPreferences.getInstance();

    final saved = pref.getString('language');

    if (saved == 'fa') {
      current = AppLanguage.persian;
    } else if (saved == 'ar') {
      current = AppLanguage.arabic;
    } else if (saved == 'en') {
      current = AppLanguage.english;
    } else {
      final code = WidgetsBinding
          .instance
          .platformDispatcher
          .locale
          .languageCode
          .toLowerCase();

      if (code == 'fa') {
        current = AppLanguage.persian;
      } else if (code == 'ar') {
        current = AppLanguage.arabic;
      } else {
        current = AppLanguage.english;
      }
    }
  }

  static Future<void> setLanguage(AppLanguage lang) async {
    current = lang;

    final pref = await SharedPreferences.getInstance();

    switch (lang) {
      case AppLanguage.persian:
        await pref.setString('language', 'fa');
        break;

      case AppLanguage.english:
        await pref.setString('language', 'en');
        break;

      case AppLanguage.arabic:
        await pref.setString('language', 'ar');
        break;
    }
  }

  static bool get isRTL {
    return current != AppLanguage.english;
  }
}
