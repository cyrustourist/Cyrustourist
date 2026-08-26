import 'package:flutter/material.dart';

/// ============================================================
/// Cyrus Tourist
/// هسته مشترک تنظیمات کلیدهای ۲، ۳ و ۵
///
/// کلید ۲ = گردشگری سلامت
/// کلید ۳ = جاذبه های گردشگری
/// کلید ۵ = اقامتگاه
///
/// این فایل فعلاً مستقل از SmartMapPage است.
/// بنابراین به کلید ۱ هیچ آسیبی نمی‌زند.
/// ============================================================

enum TouristMapSection {
  health,
  attractions,
  accommodation,
}

/// ============================================================
/// شعاع های مجاز جستجو
/// ============================================================

class TouristSearchRadius {
  static const List<double> values = [
    5,
    10,
    15,
    25,
    50,
    100,
  ];

  static String label(
    double km, {
    String language = 'fa',
  }) {
    final value = km.toStringAsFixed(
      km.truncateToDouble() == km ? 0 : 1,
    );

    switch (language) {
      case 'en':
        return '$value km';

      case 'ar':
        return '$value كم';

      default:
        return '$value کیلومتر';
    }
  }
}

/// ============================================================
/// تنظیمات هر بخش
/// ============================================================

class TouristMapCategoryConfig {
  final TouristMapSection section;

  final String faTitle;
  final String enTitle;
  final String arTitle;

  final String faSearchHint;
  final String enSearchHint;
  final String arSearchHint;

  final IconData icon;

  final Color primaryColor;
  final Color secondaryColor;

  /// کلمات جستجوی مخصوص این بخش
  final List<String> searchTerms;

  const TouristMapCategoryConfig({
    required this.section,
    required this.faTitle,
    required this.enTitle,
    required this.arTitle,
    required this.faSearchHint,
    required this.enSearchHint,
    required this.arSearchHint,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.searchTerms,
  });

  String title(
    String language,
  ) {
    switch (language) {
      case 'en':
        return enTitle;

      case 'ar':
        return arTitle;

      default:
        return faTitle;
    }
  }

  String searchHint(
    String language,
  ) {
    switch (language) {
      case 'en':
        return enSearchHint;

      case 'ar':
        return arSearchHint;

      default:
        return faSearchHint;
    }
  }
}

/// ============================================================
/// تنظیمات سه کلید
/// ============================================================

class TouristMapCategories {
  TouristMapCategories._();

  /// ----------------------------------------------------------
  /// کلید ۲
  /// گردشگری سلامت
  /// ----------------------------------------------------------

  static const TouristMapCategoryConfig health =
      TouristMapCategoryConfig(
    section: TouristMapSection.health,

    faTitle: 'گردشگری سلامت',
    enTitle: 'Health Tourism',
    arTitle: 'السياحة العلاجية',

    faSearchHint:
        'جستجوی مرکز درمانی، بیمارستان، کلینیک...',
    enSearchHint:
        'Search hospital, clinic, medical center...',
    arSearchHint:
        'ابحث عن مستشفى أو عيادة أو مركز طبي...',

    icon: Icons.health_and_safety_rounded,

    primaryColor: Color(0xff16A085),
    secondaryColor: Color(0xff0B5960),

    searchTerms: [
      'hospital',
      'clinic',
      'medical',
      'health',
      'doctor',
      'dentist',
      'pharmacy',
      'hospital',
      'بیمارستان',
      'درمانگاه',
      'کلینیک',
      'پزشک',
      'داروخانه',
      'دندانپزشکی',
    ],
  );

  /// ----------------------------------------------------------
  /// کلید ۳
  /// جاذبه های گردشگری
  /// ----------------------------------------------------------

  static const TouristMapCategoryConfig attractions =
      TouristMapCategoryConfig(
    section: TouristMapSection.attractions,

    faTitle: 'جاذبه‌های گردشگری',
    enTitle: 'Tourist Attractions',
    arTitle: 'المعالم السياحية',

    faSearchHint:
        'جستجوی شهر یا جاذبه گردشگری...',
    enSearchHint:
        'Search city or tourist attraction...',
    arSearchHint:
        'ابحث عن مدينة أو معلم سياحي...',

    icon: Icons.account_balance_rounded,

    primaryColor: Color(0xffD89B27),
    secondaryColor: Color(0xff7A4B12),

    searchTerms: [
      'tourism',
      'tourist attraction',
      'attraction',
      'museum',
      'castle',
      'palace',
      'historical',
      'monument',
      'nature',
      'waterfall',
      'park',
      'جاذبه',
      'گردشگری',
      'موزه',
      'قلعه',
      'کاخ',
      'تاریخی',
      'طبیعت',
      'آبشار',
      'پارک',
    ],
  );

  /// ----------------------------------------------------------
  /// کلید ۵
  /// اقامتگاه
  /// ----------------------------------------------------------

  static const TouristMapCategoryConfig accommodation =
      TouristMapCategoryConfig(
    section: TouristMapSection.accommodation,

    faTitle: 'اقامتگاه',
    enTitle: 'Accommodation',
    arTitle: 'أماكن الإقامة',

    faSearchHint:
        'جستجوی هتل، اقامتگاه، کلبه، مهمان‌خانه...',
    enSearchHint:
        'Search hotel, lodge, cabin, guesthouse...',
    arSearchHint:
        'ابحث عن فندق أو كوخ أو بيت ضيافة...',

    icon: Icons.hotel_rounded,

    primaryColor: Color(0xff7B61FF),
    secondaryColor: Color(0xff392A72),

    searchTerms: [
      'hotel',
      'hostel',
      'guest house',
      'guesthouse',
      'lodge',
      'cabin',
      'resort',
      'motel',
      'camp',
      'homestay',
      'هتل',
      'اقامتگاه',
      'کلبه',
      'مهمانخانه',
      'مسافرخانه',
      'بوم گردی',
      'بوم‌گردی',
      'کمپ',
      'سوئیت',
      'متل',
    ],
  );

  /// ----------------------------------------------------------
  /// دریافت تنظیمات بر اساس بخش
  /// ----------------------------------------------------------

  static TouristMapCategoryConfig forSection(
    TouristMapSection section,
  ) {
    switch (section) {
      case TouristMapSection.health:
        return health;

      case TouristMapSection.attractions:
        return attractions;

      case TouristMapSection.accommodation:
        return accommodation;
    }
  }
}

/// ============================================================
/// ابزارهای مشترک صفحه
/// ============================================================

class TouristMapUi {
  TouristMapUi._();

  /// رنگ پس زمینه اصلی
  static const Color background =
      Color(0xff071722);

  /// طلایی Cyrus Tourist
  static const Color gold =
      Color(0xffffd36a);

  /// طلایی روشن
  static const Color goldBright =
      Color(0xffffe39a);

  /// رنگ متن اصلی
  static const Color text =
      Color(0xff18343F);

  /// سایه استاندارد همه کلیدها
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black38,
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  /// سایه قوی برای کلید انتخاب شده
  static const List<BoxShadow> selectedShadow = [
    BoxShadow(
      color: Colors.black45,
      blurRadius: 14,
      offset: Offset(0, 7),
    ),
  ];
}

/// ============================================================
/// اطلاعات مرتب سازی
/// ============================================================

enum TouristSortMode {
  nearest,
  farthest,
  alphabetical,
}

/// ============================================================
/// عنوان مرتب سازی
/// ============================================================

class TouristSortLabels {
  TouristSortLabels._();

  static String title(
    TouristSortMode mode,
    String language,
  ) {
    switch (mode) {
      case TouristSortMode.nearest:
        switch (language) {
          case 'en':
            return 'Nearest';

          case 'ar':
            return 'الأقرب';

          default:
            return 'نزدیک‌ترین';
        }

      case TouristSortMode.farthest:
        switch (language) {
          case 'en':
            return 'Farthest';

          case 'ar':
            return 'الأبعد';

          default:
            return 'دورترین';
        }

      case TouristSortMode.alphabetical:
        switch (language) {
          case 'en':
            return 'A–Z';

          case 'ar':
            return 'أبجدي';

          default:
            return 'الفبایی';
        }
    }
  }
}
