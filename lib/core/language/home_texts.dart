/// ==========================================================
/// Cyrus Tourist — متن‌های ۱۰ زبانه‌ی بخش‌های جدید صفحه اصلی
/// (تبلیغات ویژه، کادر معرفی کسب‌وکار، شبکه‌های اجتماعی، تنظیمات)
/// ==========================================================
///
/// زبان‌ها: fa, en, ar, tr, ru, fr, de, es, zh, it
/// عنوان ۸ کلید اصلی همچنان از MenuTranslations.title می‌آید.
class HomeTexts {
  HomeTexts._();

  static String get(String lang, String key) {
    final byKey = _t[key];
    if (byKey == null) return key;
    return byKey[lang] ?? byKey['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _t = {
    'adTitle': {
      'fa': 'تبلیغات ویژه',
      'en': 'Featured Ads',
      'ar': 'إعلانات مميزة',
      'tr': 'Öne Çıkan İlanlar',
      'ru': 'Специальные объявления',
      'fr': 'Annonces à la une',
      'de': 'Top-Anzeigen',
      'es': 'Anuncios destacados',
      'zh': '精选广告',
      'it': 'Annunci in evidenza',
    },
    'noteTitle': {
      'fa': 'دیده شوید؛ انتخاب شوید!',
      'en': 'Be seen. Be chosen!',
      'ar': 'كن مرئيًا، وكن الخيار!',
      'tr': 'Görünün, tercih edilin!',
      'ru': 'Будьте на виду — станьте выбором!',
      'fr': 'Soyez vu, soyez choisi !',
      'de': 'Werden Sie gesehen, werden Sie gewählt!',
      'es': '¡Sé visto, sé elegido!',
      'zh': '被看见，被选择！',
      'it': 'Fatevi vedere, fatevi scegliere!',
    },
    'noteBody': {
      'fa': 'معرفی کسب‌وکار شما در Cyrus Tourist',
      'en': 'Promote your business on Cyrus Tourist',
      'ar': 'عرّف بنشاطك التجاري على Cyrus Tourist',
      'tr': 'İşletmenizi Cyrus Tourist’te tanıtın',
      'ru': 'Расскажите о своём бизнесе в Cyrus Tourist',
      'fr': 'Présentez votre activité sur Cyrus Tourist',
      'de': 'Präsentieren Sie Ihr Unternehmen auf Cyrus Tourist',
      'es': 'Presenta tu negocio en Cyrus Tourist',
      'zh': '在 Cyrus Tourist 展示您的业务',
      'it': 'Presenta la tua attività su Cyrus Tourist',
    },
    'socialTitle': {
      'fa': 'با جهان دیده شوید',
      'en': 'Be seen worldwide',
      'ar': 'كن مرئيًا للعالم',
      'tr': 'Dünyayla görünün',
      'ru': 'Будьте на виду у всего мира',
      'fr': 'Soyez vu dans le monde entier',
      'de': 'Werden Sie weltweit gesehen',
      'es': 'Sé visto en todo el mundo',
      'zh': '让世界看见您',
      'it': 'Fatevi vedere nel mondo',
    },
    'instagram': {
      'fa': 'اینستاگرام',
      'ar': 'إنستغرام',
      'en': 'Instagram',
    },
    'aparat': {
      'fa': 'آپارات',
      'ar': 'آپارات',
      'en': 'Aparat',
    },
    'youtube': {
      'fa': 'یوتیوب',
      'ar': 'يوتيوب',
      'en': 'YouTube',
    },
    'telegram': {
      'fa': 'تلگرام',
      'ar': 'تيليجرام',
      'en': 'Telegram',
    },
    'eitaa': {
      'fa': 'ایتا',
      'ar': 'إيتا',
      'en': 'Eitaa',
    },
    'tiktok': {
      'fa': 'تیک‌تاک',
      'ar': 'تيك توك',
      'zh': '抖音国际版',
      'en': 'TikTok',
    },
    'whatsapp': {
      'fa': 'واتساپ',
      'ar': 'واتساب',
      'en': 'WhatsApp',
    },
    'links': {
      'fa': 'لینک‌ها',
      'en': 'Links',
      'ar': 'الروابط',
      'tr': 'Bağlantılar',
      'ru': 'Ссылки',
      'fr': 'Liens',
      'de': 'Links',
      'es': 'Enlaces',
      'zh': '链接',
      'it': 'Link',
    },
    'sound': {
      'fa': 'صدا',
      'en': 'Sound',
      'ar': 'الصوت',
      'tr': 'Ses',
      'ru': 'Звук',
      'fr': 'Son',
      'de': 'Ton',
      'es': 'Sonido',
      'zh': '声音',
      'it': 'Suono',
    },
    'color': {
      'fa': 'رنگ',
      'en': 'Color',
      'ar': 'اللون',
      'tr': 'Renk',
      'ru': 'Цвет',
      'fr': 'Couleur',
      'de': 'Farbe',
      'es': 'Color',
      'zh': '颜色',
      'it': 'Colore',
    },
    'mode': {
      'fa': 'حالت',
      'en': 'Mode',
      'ar': 'الوضع',
      'tr': 'Mod',
      'ru': 'Режим',
      'fr': 'Mode',
      'de': 'Modus',
      'es': 'Modo',
      'zh': '模式',
      'it': 'Modalità',
    },
    'animation': {
      'fa': 'انیمیشن',
      'en': 'Animation',
      'ar': 'الحركة',
      'tr': 'Animasyon',
      'ru': 'Анимация',
      'fr': 'Animation',
      'de': 'Animation',
      'es': 'Animación',
      'zh': '动画',
      'it': 'Animazione',
    },
    'soundTitle': {
      'fa': 'تنظیمات افکت لمس',
      'en': 'Touch sound effect',
      'ar': 'مؤثر اللمس الصوتي',
      'tr': 'Dokunma ses efekti',
      'ru': 'Звук касания',
      'fr': 'Son au toucher',
      'de': 'Berührungston',
      'es': 'Sonido al tocar',
      'zh': '触摸音效',
      'it': 'Suono al tocco',
    },
    'colorTitle': {
      'fa': 'انتخاب رنگ برنامه',
      'en': 'App color',
      'ar': 'لون التطبيق',
      'tr': 'Uygulama rengi',
      'ru': 'Цвет приложения',
      'fr': 'Couleur de l’application',
      'de': 'App-Farbe',
      'es': 'Color de la app',
      'zh': '应用颜色',
      'it': 'Colore dell’app',
    },
    'modeTitle': {
      'fa': 'حالت شب و روز',
      'en': 'Day / Night mode',
      'ar': 'وضع النهار / الليل',
      'tr': 'Gündüz / Gece modu',
      'ru': 'День / Ночь',
      'fr': 'Mode jour / nuit',
      'de': 'Tag-/Nachtmodus',
      'es': 'Modo día / noche',
      'zh': '日间 / 夜间模式',
      'it': 'Modalità giorno / notte',
    },
    'animationTitle': {
      'fa': 'کنترل انیمیشن',
      'en': 'Animation control',
      'ar': 'التحكم بالحركة',
      'tr': 'Animasyon kontrolü',
      'ru': 'Управление анимацией',
      'fr': 'Contrôle des animations',
      'de': 'Animationssteuerung',
      'es': 'Control de animación',
      'zh': '动画控制',
      'it': 'Controllo animazioni',
    },
    'gold': {
      'fa': 'طلایی', 'en': 'Gold', 'ar': 'ذهبي', 'tr': 'Altın', 'ru': 'Золотой',
      'fr': 'Or', 'de': 'Gold', 'es': 'Dorado', 'zh': '金色', 'it': 'Oro',
    },
    'blue': {
      'fa': 'آبی', 'en': 'Blue', 'ar': 'أزرق', 'tr': 'Mavi', 'ru': 'Синий',
      'fr': 'Bleu', 'de': 'Blau', 'es': 'Azul', 'zh': '蓝色', 'it': 'Blu',
    },
    'emerald': {
      'fa': 'زمردی', 'en': 'Emerald', 'ar': 'زمردي', 'tr': 'Zümrüt', 'ru': 'Изумрудный',
      'fr': 'Émeraude', 'de': 'Smaragd', 'es': 'Esmeralda', 'zh': '翡翠绿', 'it': 'Smeraldo',
    },
    'purple': {
      'fa': 'بنفش', 'en': 'Purple', 'ar': 'بنفسجي', 'tr': 'Mor', 'ru': 'Фиолетовый',
      'fr': 'Violet', 'de': 'Lila', 'es': 'Púrpura', 'zh': '紫色', 'it': 'Viola',
    },
    'red': {
      'fa': 'قرمز', 'en': 'Red', 'ar': 'أحمر', 'tr': 'Kırmızı', 'ru': 'Красный',
      'fr': 'Rouge', 'de': 'Rot', 'es': 'Rojo', 'zh': '红色', 'it': 'Rosso',
    },
    'cyan': {
      'fa': 'فیروزه‌ای', 'en': 'Turquoise', 'ar': 'فيروزي', 'tr': 'Turkuaz', 'ru': 'Бирюзовый',
      'fr': 'Turquoise', 'de': 'Türkis', 'es': 'Turquesa', 'zh': '青绿色', 'it': 'Turchese',
    },
    'night': {
      'fa': 'شب', 'en': 'Night', 'ar': 'ليل', 'tr': 'Gece', 'ru': 'Ночь',
      'fr': 'Nuit', 'de': 'Nacht', 'es': 'Noche', 'zh': '夜间', 'it': 'Notte',
    },
    'day': {
      'fa': 'روز', 'en': 'Day', 'ar': 'نهار', 'tr': 'Gündüz', 'ru': 'День',
      'fr': 'Jour', 'de': 'Tag', 'es': 'Día', 'zh': '日间', 'it': 'Giorno',
    },
    'animSmooth': {
      'fa': 'روان', 'en': 'Smooth', 'ar': 'سلس', 'tr': 'Akıcı', 'ru': 'Плавно',
      'fr': 'Fluide', 'de': 'Flüssig', 'es': 'Fluida', 'zh': '流畅', 'it': 'Fluida',
    },
    'animLow': {
      'fa': 'کم', 'en': 'Low', 'ar': 'قليل', 'tr': 'Az', 'ru': 'Мало',
      'fr': 'Faible', 'de': 'Gering', 'es': 'Baja', 'zh': '低', 'it': 'Bassa',
    },
    'animOff': {
      'fa': 'خاموش', 'en': 'Off', 'ar': 'إيقاف', 'tr': 'Kapalı', 'ru': 'Выкл.',
      'fr': 'Désactivée', 'de': 'Aus', 'es': 'Apagada', 'zh': '关闭', 'it': 'Spenta',
    },
    'soundClassic': {
      'fa': 'کلاسیک', 'en': 'Classic', 'ar': 'كلاسيكي', 'tr': 'Klasik', 'ru': 'Классика',
      'fr': 'Classique', 'de': 'Klassisch', 'es': 'Clásico', 'zh': '经典', 'it': 'Classico',
    },
    'soundSoft': {
      'fa': 'نرم', 'en': 'Soft', 'ar': 'ناعم', 'tr': 'Yumuşak', 'ru': 'Мягкий',
      'fr': 'Doux', 'de': 'Sanft', 'es': 'Suave', 'zh': '柔和', 'it': 'Morbido',
    },
    'soundGold': {
      'fa': 'طلایی', 'en': 'Gold', 'ar': 'ذهبي', 'tr': 'Altın', 'ru': 'Золотой',
      'fr': 'Or', 'de': 'Gold', 'es': 'Dorado', 'zh': '金色', 'it': 'Oro',
    },
    'soundSilent': {
      'fa': 'سکوت', 'en': 'Silent', 'ar': 'صامت', 'tr': 'Sessiz', 'ru': 'Без звука',
      'fr': 'Silence', 'de': 'Stumm', 'es': 'Silencio', 'zh': '静音', 'it': 'Silenzio',
    },
    'close': {
      'fa': 'بستن', 'en': 'Close', 'ar': 'إغلاق', 'tr': 'Kapat', 'ru': 'Закрыть',
      'fr': 'Fermer', 'de': 'Schließen', 'es': 'Cerrar', 'zh': '关闭', 'it': 'Chiudi',
    },
  };
}
