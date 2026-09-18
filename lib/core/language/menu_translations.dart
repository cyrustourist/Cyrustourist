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
/// وضعیت کلیدها (نسخه فعلی — ۸ کلید، ۲ ردیف ۴تایی):
/// 1  نقشه گردشگری
/// 2  گردشگری سلامت
/// 3  جاذبه‌های گردشگری
/// 4  اقامتگاه‌ها
/// 5  راهنمای سفر
/// 6  نمایش فیلم‌های ویژه
/// 7  جستجوی هوشمند
/// 8  تور گردشگری   (جایگزین «جعبه ابزار» قدیم — گزینه‌ها به‌تدریج
///                    و به ترتیب داخل این کلید اضافه می‌شوند)
///
/// کلیدهای قدیمیِ «حساب کاربری» و «علاقه‌مندی‌ها» دیگر به‌صورت
/// کلید مستقل در صفحه اصلی نیستند؛ دسترسی به آن‌ها از طریق آیکون
/// حساب کاربری در هدر صفحه انجام می‌شود.
///
/// هر ۱۰ زبان زیر برای هر ۸ کلید تکمیل شده است:
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
  MenuLanguageOption(code: 'fa', nativeName: 'پارسی', isRtl: true),
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

  /// عنوان آیکون‌های نوار پایین صفحه اصلی و متن نوار جستجو (۱۰ زبان).
  /// کلیدها: home, map, favorites, films, account
  static String tab(String languageCode, String key) {
    final table = _tabs[key];
    if (table == null) return '';
    final code = languageCode.toLowerCase().trim();
    return table[code] ?? table['fa'] ?? '';
  }

  static String searchHint(String languageCode) {
    final code = languageCode.toLowerCase().trim();
    return _searchHint[code] ?? _searchHint['fa']!;
  }

  /// راهنمای (tooltip) دکمه‌های هدر. کلیدها: menu, language, account
  static String tooltip(String languageCode, String key) {
    final table = _tooltips[key];
    if (table == null) return '';
    final code = languageCode.toLowerCase().trim();
    return table[code] ?? table['fa'] ?? '';
  }

  static const Map<String, Map<String, String>> _tabs = {
    'home': {
      'fa': 'خانه',
      'en': 'Home',
      'ar': 'الرئيسية',
      'tr': 'Ana Sayfa',
      'ru': 'Главная',
      'fr': 'Accueil',
      'de': 'Start',
      'es': 'Inicio',
      'zh': '首页',
      'it': 'Home',
    },
    'map': {
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
    'favorites': {
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
    'films': {
      'fa': 'فیلم‌های ویژه',
      'en': 'Featured Films',
      'ar': 'أفلام مميزة',
      'tr': 'Özel Filmler',
      'ru': 'Спецфильмы',
      'fr': 'Films à la une',
      'de': 'Top-Filme',
      'es': 'Películas',
      'zh': '精选影片',
      'it': 'Film',
    },
    'account': {
      'fa': 'حساب کاربری',
      'en': 'Account',
      'ar': 'الحساب',
      'tr': 'Hesap',
      'ru': 'Аккаунт',
      'fr': 'Compte',
      'de': 'Konto',
      'es': 'Cuenta',
      'zh': '账户',
      'it': 'Account',
    },
  };

  static const Map<String, String> _searchHint = {
    'fa': 'کجا می‌خواهید بروید؟',
    'en': 'Where do you want to go?',
    'ar': 'إلى أين تريد الذهاب؟',
    'tr': 'Nereye gitmek istersiniz?',
    'ru': 'Куда вы хотите поехать?',
    'fr': 'Où voulez-vous aller ?',
    'de': 'Wohin möchten Sie reisen?',
    'es': '¿A dónde quiere ir?',
    'zh': '您想去哪里？',
    'it': 'Dove vuoi andare?',
  };

  static const Map<String, Map<String, String>> _tooltips = {
    'menu': {
      'fa': 'منو',
      'en': 'Menu',
      'ar': 'القائمة',
      'tr': 'Menü',
      'ru': 'Меню',
      'fr': 'Menu',
      'de': 'Menü',
      'es': 'Menú',
      'zh': '菜单',
      'it': 'Menu',
    },
  };

  static const Map<int, Map<String, String>> _titles = {
    // ------------------------------------------------------
    // کلید ۱ — نقشه
    // ------------------------------------------------------
    1: {
      'fa': 'نقشه گردشگری',
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
    // کلید ۴ — اقامتگاه‌ها
    // ------------------------------------------------------
    4: {
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
    // کلید ۵ — راهنمای سفر
    // ------------------------------------------------------
    5: {
      'fa': 'راهنمای سفر',
      'en': 'Travel Guide',
      'ar': 'دليل السفر',
      'tr': 'Seyahat Rehberi',
      'ru': 'Путеводитель',
      'fr': 'Guide de voyage',
      'de': 'Reiseführer',
      'es': 'Guía de viaje',
      'zh': '旅行指南',
      'it': 'Guida di viaggio',
    },

    // ------------------------------------------------------
    // کلید ۶ — نمایش فیلم‌های ویژه
    // ------------------------------------------------------
    6: {
      'fa': 'نمایش فیلم‌های ویژه',
      'en': 'Featured Videos',
      'ar': 'عرض الأفلام المميزة',
      'tr': 'Öne Çıkan Videolar',
      'ru': 'Специальные видео',
      'fr': 'Vidéos à la une',
      'de': 'Ausgewählte Videos',
      'es': 'Vídeos destacados',
      'zh': '精选影片',
      'it': 'Video in evidenza',
    },

    // ------------------------------------------------------
    // کلید ۷ — جستجوی هوشمند
    // ------------------------------------------------------
    7: {
      'fa': 'جستجوی هوشمند',
      'en': 'Smart Search',
      'ar': 'البحث الذكي',
      'tr': 'Akıllı Arama',
      'ru': 'Умный поиск',
      'fr': 'Recherche intelligente',
      'de': 'Intelligente Suche',
      'es': 'Búsqueda inteligente',
      'zh': '智能搜索',
      'it': 'Ricerca intelligente',
    },

    // ------------------------------------------------------
    // کلید ۸ — تور گردشگری (جایگزین «جعبه ابزار» قدیم)
    // ------------------------------------------------------
    8: {
      'fa': 'تور گردشگری',
      'en': 'Tourism Tour',
      'ar': 'جولة سياحية',
      'tr': 'Turizm Turu',
      'ru': 'Туристический тур',
      'fr': 'Circuit touristique',
      'de': 'Touristische Tour',
      'es': 'Tour turístico',
      'zh': '旅游团',
      'it': 'Tour turistico',
    },
  };
}
