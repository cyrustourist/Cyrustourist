import 'language_service.dart';

class AppText {
  static bool get rtl {
    return LanguageService.current != AppLanguage.english;
  }

  static String title() {
    switch (LanguageService.current) {
      case AppLanguage.persian:
        return 'سایروس توریست';

      case AppLanguage.english:
        return 'Cyrus Tourist';

      case AppLanguage.arabic:
        return 'سايروس توريست';
    }
  }

  static String languageName() {
    switch (LanguageService.current) {
      case AppLanguage.persian:
        return 'پارسی';

      case AppLanguage.english:
        return 'English';

      case AppLanguage.arabic:
        return 'العربية';
    }
  }

  static String map() {
    switch (LanguageService.current) {
      case AppLanguage.persian:
        return 'نقشه گردشگری';

      case AppLanguage.english:
        return 'Tourism Map';

      case AppLanguage.arabic:
        return 'خريطة السياحة';
    }
  }

  static String button(int number) {
    switch (LanguageService.current) {
      case AppLanguage.persian:
        const items = [
          '',
          'نقشه گردشگری',
          'گردشگری سلامت',
          'جاذبه‌های گردشگری',
          'فیلم‌های گردشگری',
          'اقامتگاه',
          'راهنمای سفر',
          'شبکه‌های اجتماعی',
          'درباره ما',
          'پشتیبانی و تماس',
          'علاقه‌مندی‌ها',
        ];

        return items[number];

      case AppLanguage.english:
        const items = [
          '',
          'Tourism Map',
          'Health Tourism',
          'Tourist Attractions',
          'Tourism Videos',
          'Accommodation',
          'Travel Guide',
          'Social Networks',
          'About Us',
          'Support & Contact',
          'Favorites',
        ];

        return items[number];

      case AppLanguage.arabic:
        const items = [
          '',
          'خريطة السياحة',
          'السياحة العلاجية',
          'المعالم السياحية',
          'أفلام سياحية',
          'الإقامة',
          'دليل السفر',
          'الشبكات الاجتماعية',
          'معلومات عنا',
          'الدعم والاتصال',
          'المفضلة',
        ];

        return items[number];
    }
  }
}
