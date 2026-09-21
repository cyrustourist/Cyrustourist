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
      'fa': 'جاذبه‌ها',
      'en': 'Attractions',
      'ar': 'المعالم',
      'tr': 'Turistik Yerler',
      'ru': 'Достопримечательности',
      'fr': 'Attractions',
      'de': 'Sehenswürdigkeiten',
      'es': 'Atracciones',
      'zh': '景点',
      'it': 'Attrazioni',
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
      'fa': 'فیلم‌های ویژه',
      'en': 'Featured Videos',
      'ar': 'أفلام مميزة',
      'tr': 'Özel Videolar',
      'ru': 'Спецвидео',
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

  // ==========================================================
  // کلید ۸ — گزینه‌های داخل صفحه «تور گردشگری» (۱۰ زبان)
  // ==========================================================
  //
  // عنوان و توضیح هر گزینه‌ی لیست TourismTourPage. قبلاً این متن‌ها
  // فقط فارسی/انگلیسی بودند (تابع _tr داخل خود صفحه)؛ اکنون از همین
  // جدول مرکزی و هر ۱۰ زبان برنامه خوانده می‌شوند.

  static String tourOptionTitle(String languageCode, int index) {
    final table = _tourOptionTitles[index];
    if (table == null) return '';
    final code = languageCode.toLowerCase().trim();
    return table[code] ?? table['fa'] ?? '';
  }

  static String tourOptionSubtitle(String languageCode, int index) {
    final table = _tourOptionSubtitles[index];
    if (table == null) return '';
    final code = languageCode.toLowerCase().trim();
    return table[code] ?? table['fa'] ?? '';
  }

  static String tourEmptyState(String languageCode) {
    final code = languageCode.toLowerCase().trim();
    return _tourEmptyState[code] ?? _tourEmptyState['fa']!;
  }

  static const Map<int, Map<String, String>> _tourOptionTitles = {
    1: {
      'fa': 'تورهای گردشگری',
      'en': 'Tourism Tours',
      'ar': 'جولات سياحية',
      'tr': 'Turizm Turları',
      'ru': 'Туристические туры',
      'fr': 'Circuits touristiques',
      'de': 'Touristische Touren',
      'es': 'Tours turísticos',
      'zh': '旅游团',
      'it': 'Tour turistici',
    },
    2: {
      'fa': 'لیدرها',
      'en': 'Tour Leaders',
      'ar': 'المرشدون',
      'tr': 'Tur Liderleri',
      'ru': 'Лидеры туров',
      'fr': 'Guides touristiques',
      'de': 'Tourleiter',
      'es': 'Guías turísticos',
      'zh': '领队',
      'it': 'Guide turistiche',
    },
    3: {
      'fa': 'جعبه ابزار',
      'en': 'Toolbox',
      'ar': 'صندوق الأدوات',
      'tr': 'Araç Kutusu',
      'ru': 'Набор инструментов',
      'fr': 'Boîte à outils',
      'de': 'Werkzeugkasten',
      'es': 'Caja de herramientas',
      'zh': '工具箱',
      'it': 'Cassetta degli attrezzi',
    },
    4: {
      'fa': 'آژانس‌های مسافرتی و گردشگری',
      'en': 'Travel Agencies',
      'ar': 'وكالات السفر والسياحة',
      'tr': 'Seyahat ve Turizm Acenteleri',
      'ru': 'Туристические агентства',
      'fr': 'Agences de voyage et de tourisme',
      'de': 'Reise- und Touristikagenturen',
      'es': 'Agencias de viajes y turismo',
      'zh': '旅行社与旅游代理',
      'it': 'Agenzie di viaggio e turismo',
    },
    5: {
      'fa': 'ثبت‌نام لیدرها',
      'en': 'Leader Registration',
      'ar': 'تسجيل المرشدين',
      'tr': 'Lider Kaydı',
      'ru': 'Регистрация гидов',
      'fr': 'Inscription des guides',
      'de': 'Leiterregistrierung',
      'es': 'Registro de guías',
      'zh': '领队注册',
      'it': 'Registrazione guide',
    },
    6: {
      'fa': 'ثبت‌نام آژانس مسافرتی',
      'en': 'Travel Agency Registration',
      'ar': 'تسجيل وكالة سفر',
      'tr': 'Seyahat Acentesi Kaydı',
      'ru': 'Регистрация турагентства',
      'fr': "Inscription d'agence de voyage",
      'de': 'Reisebüro-Registrierung',
      'es': 'Registro de agencia de viajes',
      'zh': '旅行社注册',
      'it': 'Registrazione agenzia di viaggi',
    },
  };

  static const Map<int, Map<String, String>> _tourOptionSubtitles = {
    1: {
      'fa': '۲۵ دسته‌ی تور در ۵ گروه — جست‌وجو، مشاهده‌ی فیلم، اشتراک‌گذاری و رزرو',
      'en': '25 tour categories in 5 groups — search, watch videos, share and book',
      'ar': '25 فئة جولات في 5 مجموعات — بحث، مشاهدة الفيديو، مشاركة وحجز',
      'tr': '5 grupta 25 tur kategorisi — arama, video izleme, paylaşma ve rezervasyon',
      'ru': '25 категорий туров в 5 группах — поиск, просмотр видео, обмен и бронирование',
      'fr': '25 catégories de circuits en 5 groupes — recherche, visionnage de vidéos, partage et réservation',
      'de': '25 Tourkategorien in 5 Gruppen — suchen, Videos ansehen, teilen und buchen',
      'es': '25 categorías de tours en 5 grupos: buscar, ver vídeos, compartir y reservar',
      'zh': '5个分组共25个旅游分类——搜索、观看视频、分享和预订',
      'it': '25 categorie di tour in 5 gruppi: cerca, guarda video, condividi e prenota',
    },
    2: {
      'fa': 'راهنماهای گردشگری تأییدشده — جست‌وجو، مشاهده پروفایل یا ثبت‌نام',
      'en': 'Verified tour leaders — search, view profiles or register',
      'ar': 'مرشدون سياحيون معتمدون — بحث، عرض الملفات الشخصية أو التسجيل',
      'tr': 'Onaylı tur liderleri — arama, profil görüntüleme veya kayıt',
      'ru': 'Проверенные гиды — поиск, просмотр профилей или регистрация',
      'fr': 'Guides touristiques vérifiés — recherche, consultation des profils ou inscription',
      'de': 'Verifizierte Reiseleiter — suchen, Profile ansehen oder registrieren',
      'es': 'Guías turísticos verificados: buscar, ver perfiles o registrarse',
      'zh': '认证旅游领队——搜索、查看资料或注册',
      'it': 'Guide turistiche verificate: cerca, visualizza i profili o registrati',
    },
    3: {
      'fa': 'ابزارهای سفر — آب‌وهوا، تبدیل ارز، ساعت جهانی و موارد اضطراری',
      'en': 'Travel tools — weather, currency, world clock and emergency info',
      'ar': 'أدوات السفر — الطقس، تحويل العملات، الساعة العالمية ومعلومات الطوارئ',
      'tr': 'Seyahat araçları — hava durumu, döviz çevirici, dünya saati ve acil durum bilgileri',
      'ru': 'Инструменты для путешествий — погода, конвертер валют, мировое время и экстренная информация',
      'fr': "Outils de voyage — météo, convertisseur de devises, horloge mondiale et infos d'urgence",
      'de': 'Reisewerkzeuge — Wetter, Währungsrechner, Weltuhr und Notfallinformationen',
      'es': 'Herramientas de viaje: clima, conversor de moneda, reloj mundial e información de emergencia',
      'zh': '旅行工具——天气、货币换算、世界时钟和紧急信息',
      'it': 'Strumenti di viaggio: meteo, convertitore di valuta, orologio mondiale e informazioni di emergenza',
    },
    4: {
      'fa': 'آژانس‌های تأییدشده — جست‌وجو، مشاهده پروفایل یا ثبت‌نام',
      'en': 'Verified travel agencies — search, view profiles or register',
      'ar': 'وكالات معتمدة — بحث، عرض الملفات الشخصية أو التسجيل',
      'tr': 'Onaylı acenteler — arama, profil görüntüleme veya kayıt',
      'ru': 'Проверенные агентства — поиск, просмотр профилей или регистрация',
      'fr': 'Agences vérifiées — recherche, consultation des profils ou inscription',
      'de': 'Verifizierte Agenturen — suchen, Profile ansehen oder registrieren',
      'es': 'Agencias verificadas: buscar, ver perfiles o registrarse',
      'zh': '认证旅行社——搜索、查看资料或注册',
      'it': 'Agenzie verificate: cerca, visualizza i profili o registrati',
    },
    5: {
      'fa': 'ثبت‌نام به‌عنوان لیدر — همراه با تماس مستقیم با پشتیبانی',
      'en': 'Register as a tour leader — with direct contact to support',
      'ar': 'التسجيل كمرشد سياحي — مع تواصل مباشر مع الدعم',
      'tr': 'Tur lideri olarak kayıt olun — destek ile doğrudan iletişim',
      'ru': 'Регистрация в качестве гида — с прямой связью со службой поддержки',
      'fr': 'Inscrivez-vous en tant que guide — avec contact direct avec le support',
      'de': 'Als Reiseleiter registrieren — mit direktem Kontakt zum Support',
      'es': 'Regístrate como guía turístico: con contacto directo con soporte',
      'zh': '注册成为领队——可直接联系客服',
      'it': "Registrati come guida turistica: con contatto diretto con l'assistenza",
    },
    6: {
      'fa': 'ثبت‌نام آژانس مسافرتی — همراه با تماس مستقیم با پشتیبانی',
      'en': 'Register your travel agency — with direct contact to support',
      'ar': 'سجّل وكالة السفر الخاصة بك — مع تواصل مباشر مع الدعم',
      'tr': 'Seyahat acentenizi kaydedin — destek ile doğrudan iletişim',
      'ru': 'Зарегистрируйте туристическое агентство — с прямой связью со службой поддержки',
      'fr': 'Inscrivez votre agence de voyage — avec contact direct avec le support',
      'de': 'Registrieren Sie Ihr Reisebüro — mit direktem Kontakt zum Support',
      'es': 'Registra tu agencia de viajes: con contacto directo con soporte',
      'zh': '注册您的旅行社——可直接联系客服',
      'it': "Registra la tua agenzia di viaggi: con contatto diretto con l'assistenza",
    },
  };

  static const Map<String, String> _tourEmptyState = {
    'fa': 'گزینه‌های تور گردشگری به‌زودی اضافه می‌شوند.',
    'en': 'Tourism tour options coming soon.',
    'ar': 'ستُضاف خيارات الجولة السياحية قريبًا.',
    'tr': 'Turizm turu seçenekleri yakında eklenecek.',
    'ru': 'Варианты туристических туров скоро появятся.',
    'fr': 'Les options de circuits touristiques seront bientôt ajoutées.',
    'de': 'Optionen für touristische Touren werden bald hinzugefügt.',
    'es': 'Las opciones de tours turísticos se agregarán pronto.',
    'zh': '旅游团选项即将推出。',
    'it': 'Le opzioni per i tour turistici saranno aggiunte a breve.',
  };
}
