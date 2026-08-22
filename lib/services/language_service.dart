/// سرویس مرکزی زبان اپلیکیشن سایروس توریست.
///
/// زبان‌های پشتیبانی‌شده:
/// fa = فارسی
/// en = English
/// ar = العربية
///
/// این سرویس مستقل از UI است تا تمام صفحات کلیدهای ۲ تا ۱۰
/// بتوانند از یک ساختار مشترک برای زبان استفاده کنند.
class LanguageService {
  /// زبان پیش‌فرض برنامه
  static const String defaultLanguage = 'fa';

  /// زبان‌های پشتیبانی‌شده
  static const List<String> supportedLanguages = [
    'fa',
    'en',
    'ar',
  ];

  /// بررسی معتبر بودن کد زبان
  static bool isSupported(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }

  /// تبدیل زبان نامعتبر به زبان پیش‌فرض
  static String normalizeLanguage(String? languageCode) {
    if (languageCode == null || languageCode.trim().isEmpty) {
      return defaultLanguage;
    }

    final code = languageCode.trim().toLowerCase();

    if (isSupported(code)) {
      return code;
    }

    return defaultLanguage;
  }

  /// بررسی راست‌به‌چپ بودن زبان
  static bool isRtl(String languageCode) {
    return normalizeLanguage(languageCode) == 'fa' ||
        normalizeLanguage(languageCode) == 'ar';
  }

  /// بررسی چپ‌به‌راست بودن زبان
  static bool isLtr(String languageCode) {
    return !isRtl(languageCode);
  }

  /// نام زبان برای نمایش به کاربر
  static String languageName(
    String languageCode,
  ) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'English';

      case 'ar':
        return 'العربية';

      case 'fa':
      default:
        return 'فارسی';
    }
  }

  /// پرچم یا نماد مناسب زبان
  static String languageSymbol(
    String languageCode,
  ) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return '🇬🇧';

      case 'ar':
        return '🇸🇦';

      case 'fa':
      default:
        return '🇮🇷';
    }
  }

  /// دریافت متن مناسب بر اساس زبان.
  ///
  /// اگر متن زبان انتخاب‌شده خالی باشد،
  /// ابتدا فارسی و سپس انگلیسی و عربی بررسی می‌شوند.
  static String text({
    required String languageCode,
    required String fa,
    String? en,
    String? ar,
  }) {
    final language = normalizeLanguage(languageCode);

    switch (language) {
      case 'en':
        if (en != null && en.trim().isNotEmpty) {
          return en.trim();
        }

        if (fa.trim().isNotEmpty) {
          return fa.trim();
        }

        return ar?.trim() ?? '';

      case 'ar':
        if (ar != null && ar.trim().isNotEmpty) {
          return ar.trim();
        }

        if (fa.trim().isNotEmpty) {
          return fa.trim();
        }

        return en?.trim() ?? '';

      case 'fa':
      default:
        if (fa.trim().isNotEmpty) {
          return fa.trim();
        }

        if (en != null && en.trim().isNotEmpty) {
          return en.trim();
        }

        return ar?.trim() ?? '';
    }
  }

  /// متن مناسب برای دکمه بازگشت به صفحه اصلی
  static String backToHome(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Back to Cyrus Tourist';

      case 'ar':
        return 'العودة إلى سايروس توريست';

      case 'fa':
      default:
        return 'بازگشت به سایروس توریست';
    }
  }

  /// متن جستجو
  static String search(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Search';

      case 'ar':
        return 'بحث';

      case 'fa':
      default:
        return 'جستجو';
    }
  }

  /// متن مسیریابی
  static String directions(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Directions';

      case 'ar':
        return 'الاتجاهات';

      case 'fa':
      default:
        return 'مسیریابی';
    }
  }

  /// متن علاقه‌مندی
  static String favorites(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Favorites';

      case 'ar':
        return 'المفضلة';

      case 'fa':
      default:
        return 'علاقه‌مندی‌ها';
    }
  }

  /// متن اشتراک‌گذاری
  static String share(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Share';

      case 'ar':
        return 'مشاركة';

      case 'fa':
      default:
        return 'اشتراک‌گذاری';
    }
  }

  /// متن خطا
  static String error(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'An error occurred';

      case 'ar':
        return 'حدث خطأ';

      case 'fa':
      default:
        return 'خطایی رخ داد';
    }
  }

  /// متن در حال بارگذاری
  static String loading(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'Loading...';

      case 'ar':
        return 'جارٍ التحميل...';

      case 'fa':
      default:
        return 'در حال بارگذاری...';
    }
  }

  /// متن حالت خالی
  static String empty(String languageCode) {
    switch (normalizeLanguage(languageCode)) {
      case 'en':
        return 'No information found';

      case 'ar':
        return 'لم يتم العثور على معلومات';

      case 'fa':
      default:
        return 'اطلاعاتی یافت نشد';
    }
  }
}
