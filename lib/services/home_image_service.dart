import '../services/language_service.dart';

class HomeImageService {
  static String get imagePath {
    switch (LanguageService.current) {
      case AppLanguage.persian:
        return 'assets/images/home_fa.jpg';

      case AppLanguage.english:
        return 'assets/images/home_en.jpg';

      case AppLanguage.arabic:
        return 'assets/images/home_ar.jpg';
    }
  }
}
