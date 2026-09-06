import 'package:shared_preferences/shared_preferences.dart';

/// ==========================================================
/// Cyrus Tourist — سیستم زبان مستقل ۱۰ کلید صفحه اصلی
/// ==========================================================
///
/// این فایل عنوان هر ۱۰ کلید صفحه اصلی (و منوی کشویی قدیمی) را
/// برای هر ۱۰ زبان برنامه نگه می‌دارد و به CyrusLanguageButton
/// (کلید زبان هدر) وصل می‌شود.
///
/// نکته مهم:
/// این سیستم فقط عنوان کلیدهای صفحه اصلی را مدیریت می‌کند و
/// جایگزین LanguageManager (زبان کلی برنامه در app_language.dart)
/// نمی‌شود؛ هر دو با هم هماهنگ نگه داشته می‌شوند.
///
/// وضعیت کلیدها (نسخه فعلی):
/// 1  نقشه
/// 2  گردشگری سلامت
/// 3  جاذبه‌های گردشگری
/// 4  رسانه
/// 5  اقامتگاه‌ها
/// 6  تورها
/// 7  برنامه‌ریز سفر  (جعبه ابزار بسیار هوشمند)
/// 8  پروفایل        (حساب کاربری)
/// 9  جستجو          (جستجوی هوشمند)
/// 10 علاقه‌مندی‌ها
///
/// کلیدهای قدیمی ۷ (دنبال کنید)، ۸ (درباره ما) و ۹ (پشتیبانی)
/// دیگر در صفحه اصلی نیستند؛ این سه به تنظیمات (☰ هدر) منتقل
/// شدند و از همان صفحات قدیمی استفاده می‌کنند.
///
/// هر ۱۰ زبان زیر برای هر ۱۰ کلید تکمیل شده است:
/// fa, en, ar, tr, ru, fr, de, es, zh, it

class MenuLanguageOption {
  const MenuLanguageOption({
    required this.code,
    required this.nativeName,
    required this.isRtl,
  });

  final String code;
  final String nativeName;
  final bool isRtl;
}

const List<MenuLanguageOption> kMenuLanguages = [
  MenuLanguageOption(code: 'fa', nativeName: 'فارسی', isRtl: true),
  MenuLanguageOption(code: 'en', nativeName: 'English', isRtl: false),
  MenuLanguageOption(code: 'ar', nativeName: 'العربية', isRtl: true),
  MenuLanguageOption(code: 'tr', nativeName: 'Türkçe', isRtl: false),
  MenuLanguageOption(code: 'ru', nativeName: 'Русский', isRtl: false),
  MenuLanguageOption(code: 'fr', nativeName: 'Français', isRtl: false),
  MenuLanguageOption(code: 'de', nativeName: 'Deutsch', isRtl: false),
  MenuLanguageOption(code: 'es', nativeName: 'Español', isRtl: false),
  MenuLanguageOption(code: 'zh', nativeName: '中文', isRtl: false),
  MenuLanguageOption(code: 'it', nativeName: 'Italiano', isRtl: false),
];

class MenuLanguage {
  MenuLanguage._();

  static const String _prefsKey = 'cyrus_menu_language_code';

  static String current = 'fa';

  static bool get isRtl => current == 'fa' || current == 'ar';

  /// بارگذاری زبان ذخیره‌شده کلیدهای صفحه اصلی.
  static Future<void> load() async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getString(_prefsKey);

    if (saved != null && kMenuLanguages.any((l) => l.code == saved)) {
      current = saved;
    }
  }

  /// تغییر و ذخیره زبان کلیدهای صفحه اصلی.
  static Future<void> setLanguage(String code) async {
    final normalized = code.toLowerCase().trim();

    if (!kMenuLanguages.any((l) => l.code == normalized)) {
      return;
    }

    current = normalized;

    final pref = await SharedPreferences.getInstance();
    await pref.setString(_prefsKey, normalized);
  }
}

class MenuTranslations {
  MenuTranslations._();

  /// ترجمه‌ها ثابت (in-memory) هستند؛ این متد فقط برای سازگاری
  /// با فراخوانی موجود در main.dart نگه داشته شده است.
  static Future<void> preloadAll() async {}

  static String title(String languageCode, int number) {
    final table = _titles[number];

    if (table == null) return '';

    final code = languageCode.toLowerCase().trim();

    return table[code] ?? table['fa'] ?? '';
  }

  static const Map<int, Map<String, String>> _titles = {
    // ------------------------------------------------------
    // کلید ۱ — نقشه
    // ------------------------------------------------------
    1: {
      'fa': 'نقشه',
      'en': 'Map',
      'ar': 'الخريطة',
      'tr': 'Harita',
      'ru': 'Карта',
      'fr': 'Carte',
      'de': 'Karte',
      'es': 'Mapa',
      'zh': '地图',
      'it': 'Mappa',
    },

    // ------------------------------------------------------
    // کلید ۲ — گردشگری سلامت
    // ------------------------------------------------------
    2: {
      'fa': 'گردشگری سلامت',
      'en': 'Health Tourism',
      'ar': 'السياحة الصحية',
      'tr': 'Sağlık Turizmi',
      'ru': 'Медицинский туризм',
      'fr': 'Tourisme de santé',
      'de': 'Gesundheitstourismus',
      'es': 'Turismo de salud',
      'zh': '健康旅游',
      'it': 'Turismo sanitario',
    },

    // ------------------------------------------------------
    // کلید ۳ — جاذبه‌های گردشگری
    // ------------------------------------------------------
    3: {
      'fa': 'جاذبه‌های گردشگری',
      'en': 'Attractions',
      'ar': 'المعالم السياحية',
      'tr': 'Turistik Yerler',
      'ru': 'Достопримечательности',
      'fr': 'Attractions touristiques',
      'de': 'Sehenswürdigkeiten',
      'es': 'Atracciones turísticas',
      'zh': '旅游景点',
      'it': 'Attrazioni turistiche',
    },

    // ------------------------------------------------------
    // کلید ۴ — رسانه
    // ------------------------------------------------------
    4: {
      'fa': 'رسانه',
      'en': 'Media',
      'ar': 'الوسائط',
      'tr': 'Medya',
      'ru': 'Медиа',
      'fr': 'Médias',
      'de': 'Medien',
      'es': 'Medios',
      'zh': '媒体',
      'it': 'Media',
    },

    // ------------------------------------------------------
    // کلید ۵ — اقامتگاه‌ها
    // ------------------------------------------------------
    5: {
      'fa': 'اقامتگاه‌ها',
      'en': 'Accommodation',
      'ar': 'أماكن الإقامة',
      'tr': 'Konaklama',
      'ru': 'Проживание',
      'fr': 'Hébergement',
      'de': 'Unterkunft',
      'es': 'Alojamiento',
      'zh': '住宿',
      'it': 'Alloggio',
    },

    // ------------------------------------------------------
    // کلید ۶ — تورها
    // ------------------------------------------------------
    6: {
      'fa': 'تورها',
      'en': 'Tours',
      'ar': 'الجولات',
      'tr': 'Turlar',
      'ru': 'Туры',
      'fr': 'Circuits',
      'de': 'Touren',
      'es': 'Tours',
      'zh': '旅游团',
      'it': 'Tour',
    },

    // ------------------------------------------------------
    // کلید ۷ — برنامه‌ریز سفر (جعبه ابزار بسیار هوشمند)
    // ------------------------------------------------------
    7: {
      'fa': 'برنامه‌ریز سفر',
      'en': 'Trip Planner',
      'ar': 'مخطط الرحلة',
      'tr': 'Seyahat Planlayıcı',
      'ru': 'Планировщик поездок',
      'fr': 'Planificateur de voyage',
      'de': 'Reiseplaner',
      'es': 'Planificador de viajes',
      'zh': '行程规划',
      'it': 'Pianificatore di viaggio',
    },

    // ------------------------------------------------------
    // کلید ۸ — پروفایل (حساب کاربری)
    // ------------------------------------------------------
    8: {
      'fa': 'پروفایل',
      'en': 'Profile',
      'ar': 'الملف الشخصي',
      'tr': 'Profil',
      'ru': 'Профиль',
      'fr': 'Profil',
      'de': 'Profil',
      'es': 'Perfil',
      'zh': '个人资料',
      'it': 'Profilo',
    },

    // ------------------------------------------------------
    // کلید ۹ — جستجو (جستجوی هوشمند)
    // ------------------------------------------------------
    9: {
      'fa': 'جستجو',
      'en': 'Search',
      'ar': 'بحث',
      'tr': 'Ara',
      'ru': 'Поиск',
      'fr': 'Recherche',
      'de': 'Suche',
      'es': 'Buscar',
      'zh': '搜索',
      'it': 'Cerca',
    },

    // ------------------------------------------------------
    // کلید ۱۰ — علاقه‌مندی‌ها
    // ------------------------------------------------------
    10: {
      'fa': 'علاقه‌مندی‌ها',
      'en': 'Favorites',
      'ar': 'المفضلة',
      'tr': 'Favoriler',
      'ru': 'Избранное',
      'fr': 'Favoris',
      'de': 'Favoriten',
      'es': 'Favoritos',
      'zh': '收藏',
      'it': 'Preferiti',
    },
  };
}
