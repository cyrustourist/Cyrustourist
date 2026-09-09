/// مدل داده‌ی هر «فیلم» در بخش کلید ۴ (نمایش فیلم).
///
/// این کلاس فقط یک لایه‌ی سبک روی همان اطلاعاتی است که همین حالا در
/// video_page.dart وجود دارد (title/location/category به چند زبان،
/// عکس کاور، لینک آپارات) و دو چیز جدید به آن اضافه می‌کند:
///   - uniqueCode   : کد یکتای عددی هر فیلم (برای جست‌وجو و کدهای رند)
///   - isPinned     : آیا این کد به‌عنوان کد رند/ویژه پین شده یا نه
///
/// فیلدهای تماس (phoneNumbers/instagramUrl/websiteUrl) فعلاً مقدار
/// پیش‌فرض سایروس توریست را دارند تا هیچ فیلمی خالی نمانَد؛ وقتی صاحب
/// واقعی فیلم ثبت‌نام کند، همین مقادیر برای آن فیلم عوض می‌شوند.
class CyrusMovieEntry {
  final int uniqueCode;
  final bool isPinned;

  // متن‌های چندزبانه — همان الگوی موجود در video_page.dart
  // (کلید بر اساس کد زبان: fa, en, ar, de, es, fr, it, ru, tr, zh)
  final Map<String, String> titles;
  final Map<String, String> locations;
  final Map<String, String> categories;

  /// نام شهر/استان به‌صورت خام (بدون ترجمه) — فقط برای جست‌وجو،
  /// چون جست‌وجو باید مستقل از زبان انتخابی کاربر هم کار کند.
  final String citySearchKey;
  final String provinceSearchKey;

  final String coverImage;
  final String videoUrl;

  final List<String> phoneNumbers;
  final String instagramUrl;
  final String websiteUrl;

  const CyrusMovieEntry({
    required this.uniqueCode,
    required this.titles,
    required this.locations,
    required this.categories,
    required this.citySearchKey,
    required this.provinceSearchKey,
    required this.coverImage,
    required this.videoUrl,
    this.isPinned = false,
    this.phoneNumbers = const [_defaultPhone],
    this.instagramUrl = _defaultInstagram,
    this.websiteUrl = _defaultWebsite,
  });

  static const String _defaultPhone = '09153448818';
  static const String _defaultInstagram =
      'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
  static const String _defaultWebsite =
      'https://cyrustourist-maker.github.io/Cyrustourist/';

  String text(String field, String languageCode) {
    final map = switch (field) {
      'title' => titles,
      'location' => locations,
      'category' => categories,
      _ => const <String, String>{},
    };
    return map[languageCode] ?? map['fa'] ?? '';
  }

  CyrusMovieEntry copyWith({bool? isPinned}) {
    return CyrusMovieEntry(
      uniqueCode: uniqueCode,
      titles: titles,
      locations: locations,
      categories: categories,
      citySearchKey: citySearchKey,
      provinceSearchKey: provinceSearchKey,
      coverImage: coverImage,
      videoUrl: videoUrl,
      isPinned: isPinned ?? this.isPinned,
      phoneNumbers: phoneNumbers,
      instagramUrl: instagramUrl,
      websiteUrl: websiteUrl,
    );
  }
}

/// همان ۲۴ فیلم فعلی، فقط با کد یکتای اضافه‌شده — ترتیب و محتوا
/// دقیقاً همان چیزی است که در video_page.dart وجود دارد و تغییر نکرده.
/// کدها از ۱۰۰۱ شروع می‌شوند تا محدوده‌ی ۱ تا ۱۰۰۰ برای کدهای رند/ویژه
/// (که بعداً قابل فروش/پین‌شدن هستند) آزاد بماند.
const List<CyrusMovieEntry> kDefaultMovieEntries = [
  CyrusMovieEntry(
    uniqueCode: 1001,
    titles: {
      'fa': 'قنات قصبه گناباد؛ شگفتی تاریخ تمدن بشر',
      'en': 'Qasabeh Gonabad Qanat; A Wonder of Human Civilization',
      'ar': 'قناة قصبة گناباد؛ أعجوبة من تاريخ الحضارة البشرية',
    },
    locations: {
      'fa': 'گناباد، خراسان رضوی',
      'en': 'Gonabad, Razavi Khorasan',
      'ar': 'غناباد، خراسان الرضوية',
    },
    categories: {
      'fa': 'میراث تاریخی',
      'en': 'Historical Heritage',
      'ar': 'تراث تاريخي',
    },
    citySearchKey: 'گناباد',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/t346o2k',
  ),
  CyrusMovieEntry(
    uniqueCode: 1002,
    titles: {
      'fa': 'رقص محلی فاروق خراسانی با آهنگ لیلا',
      'en': 'Farouq Khorasani Folk Dance with the Song Leila',
      'ar': 'رقصة فاروق الخراسانية الشعبية على أنغام ليلى',
    },
    locations: {'fa': 'خراسان', 'en': 'Khorasan', 'ar': 'خراسان'},
    categories: {
      'fa': 'فرهنگ و هنر',
      'en': 'Culture and Art',
      'ar': 'الثقافة والفنون',
    },
    citySearchKey: '',
    provinceSearchKey: 'خراسان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/w17sz69',
  ),
  CyrusMovieEntry(
    uniqueCode: 1003,
    titles: {
      'fa': 'چشمه گراب؛ جادوی طبیعت ایران',
      'en': 'Gorab Spring; The Magic of Iranian Nature',
      'ar': 'نبع غراب؛ سحر الطبيعة الإيرانية',
    },
    locations: {
      'fa': 'خراسان رضوی',
      'en': 'Razavi Khorasan',
      'ar': 'خراسان الرضوية',
    },
    categories: {
      'fa': 'طبیعت ایران',
      'en': 'Nature of Iran',
      'ar': 'طبيعة إيران',
    },
    citySearchKey: '',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/xvo5q9c',
  ),
  CyrusMovieEntry(
    uniqueCode: 1004,
    titles: {
      'fa': 'جنگل کوه‌پارک مشهد و قله زو',
      'en': 'Mashhad Kuh Park Forest and Zoo Peak',
      'ar': 'غابة كوه بارك في مشهد وقمة زو',
    },
    locations: {
      'fa': 'مشهد، خراسان رضوی',
      'en': 'Mashhad, Razavi Khorasan',
      'ar': 'مشهد، خراسان الرضوية',
    },
    categories: {
      'fa': 'کوهنوردی',
      'en': 'Mountaineering',
      'ar': 'تسلق الجبال',
    },
    citySearchKey: 'مشهد',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/hzlol4k',
  ),
  CyrusMovieEntry(
    uniqueCode: 1005,
    titles: {
      'fa': 'کاشت بلوط؛ راه نجات جنگل‌های هیرکانی',
      'en': 'Planting Oak Trees; A Way to Save the Hyrcanian Forests',
      'ar': 'زراعة أشجار البلوط؛ طريق لإنقاذ غابات هيركان',
    },
    locations: {
      'fa': 'جنگل‌های هیرکانی',
      'en': 'Hyrcanian Forests',
      'ar': 'غابات هيركان',
    },
    categories: {
      'fa': 'محیط زیست',
      'en': 'Environment',
      'ar': 'البيئة',
    },
    citySearchKey: '',
    provinceSearchKey: '',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/guqcsg5',
  ),
  CyrusMovieEntry(
    uniqueCode: 1006,
    titles: {
      'fa': 'آبشار شیرآباد؛ یکی از دیدنی‌های گلستان',
      'en': 'Shirabad Waterfall; One of Golestan’s Natural Attractions',
      'ar': 'شلال شيرآباد؛ أحد المعالم الطبيعية في غلستان',
    },
    locations: {
      'fa': 'استان گلستان',
      'en': 'Golestan Province',
      'ar': 'محافظة غلستان',
    },
    categories: {'fa': 'آبشار', 'en': 'Waterfall', 'ar': 'شلال'},
    citySearchKey: '',
    provinceSearchKey: 'گلستان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/w8lOg',
  ),
  CyrusMovieEntry(
    uniqueCode: 1007,
    titles: {
      'fa': 'آبگوشت دیزی سنگی در طبیعت',
      'en': 'Traditional Dizi Stone-Pot Stew in Nature',
      'ar': 'أبغوشت ديزي التقليدي في الطبيعة',
    },
    locations: {'fa': 'ایران', 'en': 'Iran', 'ar': 'إيران'},
    categories: {
      'fa': 'گردشگری خوراک',
      'en': 'Food Tourism',
      'ar': 'سياحة الطعام',
    },
    citySearchKey: '',
    provinceSearchKey: '',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/uK3y5',
  ),
  CyrusMovieEntry(
    uniqueCode: 1008,
    titles: {
      'fa': '۲۵ اردیبهشت؛ روز بزرگداشت فردوسی',
      'en': 'May 15; Ferdowsi Commemoration Day',
      'ar': '15 مايو؛ يوم تكريم الفردوسي',
    },
    locations: {
      'fa': 'مشهد، خراسان رضوی',
      'en': 'Mashhad, Razavi Khorasan',
      'ar': 'مشهد، خراسان الرضوية',
    },
    categories: {
      'fa': 'فرهنگ و ادب',
      'en': 'Culture and Literature',
      'ar': 'الثقافة والأدب',
    },
    citySearchKey: 'مشهد',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/nuXAC',
  ),
  CyrusMovieEntry(
    uniqueCode: 1009,
    titles: {
      'fa': 'چشمه سبز گلمکان؛ دریاچه زیبای مشهد',
      'en': 'Golmakan Green Spring; A Beautiful Lake near Mashhad',
      'ar': 'نبع سبز غلمكان؛ البحيرة الجميلة قرب مشهد',
    },
    locations: {
      'fa': 'گلمکان، خراسان رضوی',
      'en': 'Golmakan, Razavi Khorasan',
      'ar': 'غلمكان، خراسان الرضوية',
    },
    categories: {
      'fa': 'طبیعت ایران',
      'en': 'Nature of Iran',
      'ar': 'طبيعة إيران',
    },
    citySearchKey: 'گلمکان',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/x707h19',
  ),
  CyrusMovieEntry(
    uniqueCode: 1010,
    titles: {
      'fa': 'آموزش پخت سیب‌زمینی آتشی در طبیعت',
      'en': 'How to Cook Campfire Potatoes in Nature',
      'ar': 'طريقة إعداد البطاطا المشوية على النار في الطبيعة',
    },
    locations: {
      'fa': 'طبیعت ایران',
      'en': 'Iranian Nature',
      'ar': 'الطبيعة الإيرانية',
    },
    categories: {
      'fa': 'طبیعت‌گردی',
      'en': 'Nature Tourism',
      'ar': 'السياحة الطبيعية',
    },
    citySearchKey: '',
    provinceSearchKey: '',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/4Z0hQ',
  ),
  CyrusMovieEntry(
    uniqueCode: 1011,
    titles: {
      'fa': 'جشن نوروز باستانی و سفره هفت‌سین',
      'en': 'Ancient Nowruz Celebration and Haft-Seen Table',
      'ar': 'احتفال نوروز القديم ومائدة هفت سين',
    },
    locations: {'fa': 'ایران', 'en': 'Iran', 'ar': 'إيران'},
    categories: {'fa': 'نوروز', 'en': 'Nowruz', 'ar': 'نوروز'},
    citySearchKey: '',
    provinceSearchKey: '',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/s78jcie',
  ),
  CyrusMovieEntry(
    uniqueCode: 1012,
    titles: {
      'fa': 'چایخانه حمام وکیل کرمان',
      'en': 'Vakil Bathhouse Teahouse in Kerman',
      'ar': 'مقهى حمام وكيل في كرمان',
    },
    locations: {'fa': 'کرمان', 'en': 'Kerman', 'ar': 'كرمان'},
    categories: {
      'fa': 'دیدنی‌های کرمان',
      'en': 'Kerman Attractions',
      'ar': 'معالم كرمان',
    },
    citySearchKey: 'کرمان',
    provinceSearchKey: 'کرمان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/R1p3U',
  ),
  CyrusMovieEntry(
    uniqueCode: 1013,
    titles: {
      'fa': 'بجستان، آسبادهای نشتیفان و برج علی‌آباد کشمر',
      'en': 'Bajestan, Nashtifan Windmills and Aliabad Kashmar Tower',
      'ar': 'بجستان وطواحين نشتيـفان الهوائية وبرج علي آباد كاشمر',
    },
    locations: {
      'fa': 'خراسان رضوی',
      'en': 'Razavi Khorasan',
      'ar': 'خراسان الرضوية',
    },
    categories: {
      'fa': 'میراث تاریخی',
      'en': 'Historical Heritage',
      'ar': 'تراث تاريخي',
    },
    citySearchKey: 'بجستان',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/g40wppg',
  ),
  CyrusMovieEntry(
    uniqueCode: 1014,
    titles: {
      'fa': 'شاه نعمت‌الله ولی؛ ماهان کرمان',
      'en': 'Shah Nematollah Vali; Mahan, Kerman',
      'ar': 'شاه نعمة الله ولي؛ ماهان، كرمان',
    },
    locations: {
      'fa': 'ماهان، کرمان',
      'en': 'Mahan, Kerman',
      'ar': 'ماهان، كرمان',
    },
    categories: {
      'fa': 'فرهنگ و تاریخ',
      'en': 'Culture and History',
      'ar': 'الثقافة والتاريخ',
    },
    citySearchKey: 'ماهان',
    provinceSearchKey: 'کرمان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/xsBFX',
  ),
  CyrusMovieEntry(
    uniqueCode: 1015,
    titles: {
      'fa': 'باغ شاهزاده ماهان؛ شاهکار باغ ایرانی',
      'en': 'Shazdeh Garden in Mahan; A Masterpiece of Persian Gardens',
      'ar': 'حديقة شازده ماهان؛ تحفة الحدائق الفارسية',
    },
    locations: {
      'fa': 'ماهان، کرمان',
      'en': 'Mahan, Kerman',
      'ar': 'ماهان، كرمان',
    },
    categories: {
      'fa': 'باغ تاریخی',
      'en': 'Historic Garden',
      'ar': 'حديقة تاريخية',
    },
    citySearchKey: 'ماهان',
    provinceSearchKey: 'کرمان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/3ZCGs',
  ),
  CyrusMovieEntry(
    uniqueCode: 1016,
    titles: {
      'fa': 'موزه بانو حیاتی؛ گنجینه‌ای در بازار کرمان',
      'en': 'Banoo Hayati Museum; A Treasure in Kerman Bazaar',
      'ar': 'متحف بانو حياتي؛ كنز في بازار كرمان',
    },
    locations: {'fa': 'کرمان', 'en': 'Kerman', 'ar': 'كرمان'},
    categories: {'fa': 'موزه', 'en': 'Museum', 'ar': 'متحف'},
    citySearchKey: 'کرمان',
    provinceSearchKey: 'کرمان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/z72q215',
  ),
  CyrusMovieEntry(
    uniqueCode: 1017,
    titles: {
      'fa': 'قلعه سریزد؛ نخستین بانک جهان',
      'en': 'Saryazd Castle; The World’s First Bank',
      'ar': 'قلعة سريزد؛ أول بنك في العالم',
    },
    locations: {
      'fa': 'سریزد، یزد',
      'en': 'Saryazd, Yazd',
      'ar': 'سريزد، يزد',
    },
    categories: {
      'fa': 'میراث تاریخی',
      'en': 'Historical Heritage',
      'ar': 'تراث تاريخي',
    },
    citySearchKey: 'سریزد',
    provinceSearchKey: 'یزد',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/c4744bv',
  ),
  CyrusMovieEntry(
    uniqueCode: 1018,
    titles: {
      'fa': 'جنگل‌های حرا و بندر تاریخی لافت',
      'en': 'Mangrove Forests and the Historic Port of Laft',
      'ar': 'غابات القرم وميناء لافت التاريخي',
    },
    locations: {
      'fa': 'جزیره قشم',
      'en': 'Qeshm Island',
      'ar': 'جزيرة قشم',
    },
    categories: {
      'fa': 'سواحل و جزایر',
      'en': 'Coasts and Islands',
      'ar': 'السواحل والجزر',
    },
    citySearchKey: 'قشم',
    provinceSearchKey: 'هرمزگان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/kGS8o',
  ),
  CyrusMovieEntry(
    uniqueCode: 1019,
    titles: {
      'fa': 'باغ فین کاشان با موسیقی سنتی',
      'en': 'Fin Garden in Kashan with Traditional Music',
      'ar': 'حديقة فين في كاشان مع الموسيقى التقليدية',
    },
    locations: {'fa': 'کاشان', 'en': 'Kashan', 'ar': 'كاشان'},
    categories: {
      'fa': 'باغ تاریخی',
      'en': 'Historic Garden',
      'ar': 'حديقة تاريخية',
    },
    citySearchKey: 'کاشان',
    provinceSearchKey: 'اصفهان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/mPh2q',
  ),
  CyrusMovieEntry(
    uniqueCode: 1020,
    titles: {
      'fa': 'غار علی‌صدر؛ غار تالابی شگفت‌انگیز ایران',
      'en': 'Ali Sadr Cave; Iran’s Amazing Water Cave',
      'ar': 'كهف علي صدر؛ الكهف المائي المذهل في إيران',
    },
    locations: {'fa': 'همدان', 'en': 'Hamadan', 'ar': 'همدان'},
    categories: {
      'fa': 'غار و طبیعت',
      'en': 'Cave and Nature',
      'ar': 'الكهوف والطبيعة',
    },
    citySearchKey: '',
    provinceSearchKey: 'همدان',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/k2RDX',
  ),
  CyrusMovieEntry(
    uniqueCode: 1021,
    titles: {
      'fa': 'آبشار اخلمد چناران؛ طبیعت زیبای خراسان',
      'en': 'Akhlamad Waterfall in Chenaran; The Beautiful Nature of Khorasan',
      'ar': 'شلال أخلمد في چناران؛ طبيعة خراسان الجميلة',
    },
    locations: {
      'fa': 'چناران، خراسان رضوی',
      'en': 'Chenaran, Razavi Khorasan',
      'ar': 'چناران، خراسان الرضوية',
    },
    categories: {'fa': 'آبشار', 'en': 'Waterfall', 'ar': 'شلال'},
    citySearchKey: 'چناران',
    provinceSearchKey: 'خراسان رضوی',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/f91418q',
  ),
  CyrusMovieEntry(
    uniqueCode: 1022,
    titles: {
      'fa': 'جشن نوروز تخت جمشید؛ شهر پارس و پاسارگاد',
      'en':
          'Nowruz Celebration at Persepolis; The Land of Pars and Pasargadae',
      'ar': 'احتفال نوروز في تخت جمشيد؛ أرض فارس وباسارغاد',
    },
    locations: {'fa': 'فارس', 'en': 'Fars', 'ar': 'فارس'},
    categories: {
      'fa': 'میراث ایران',
      'en': 'Iranian Heritage',
      'ar': 'التراث الإيراني',
    },
    citySearchKey: '',
    provinceSearchKey: 'فارس',
    coverImage: 'assets/images/video_attraction.jpg',
    videoUrl: 'https://www.aparat.com/v/f5212r6',
  ),
];
