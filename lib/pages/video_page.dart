import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/app_language.dart';
import '../services/video_favorites_service.dart';
import 'leaders/leaders_list_page.dart';
import 'movie_video_page.dart';
import 'residence_register_page.dart';
import 'residence_video_page.dart';

const Color appBackgroundColor = Color(0xff06121d);
const Color appCardColor = Color(0xff0b2636);
const Color appGoldColor = Color(0xffffd36a);
const Color appGoldBright = Color(0xffffe39a);
const Color appTealColor = Color(0xff29e0ad);
const Color appTealBright = Color(0xff6bf0c8);

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool _showSelectedVideos = true;
  final Map<String, String> _resolvedAparatTitles = {};

  final VideoFavoritesService _favoritesService = VideoFavoritesService();
  Set<String> _favoriteVideoIds = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  String _videoId(Map<String, String> video) =>
      video['url'] ?? video['title_fa'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadFavoriteVideos();
  }

  Future<void> _loadFavoriteVideos() async {
    final ids = await _favoritesService.loadFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteVideoIds = ids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavoriteVideo(Map<String, String> video) async {
    final added = await _favoritesService.toggleFavorite(video);
    if (!mounted) return;
    setState(() {
      final id = _videoId(video);
      if (added) {
        _favoriteVideoIds.add(id);
      } else {
        _favoriteVideoIds.remove(id);
      }
    });
  }

  static const String aparatChannel =
      'https://www.aparat.com/Cyrustourist';

  static const String instagramUrl =
      'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
  static const String youtubeUrl =
      'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i';
  static const String tiktokUrl =
      'https://www.tiktok.com/@cyrustourist_app';

  final List<Map<String, String>> selectedVideos = const [
    {
      'title_fa': 'قنات قصبه گناباد؛ شگفتی تاریخ تمدن بشر',
      'title_en': 'Qasabeh Gonabad Qanat; A Wonder of Human Civilization',
      'title_ar': 'قناة قصبة گناباد؛ أعجوبة من تاريخ الحضارة البشرية',
      'location_fa': 'گناباد، خراسان رضوی',
      'location_en': 'Gonabad, Razavi Khorasan',
      'location_ar': 'غناباد، خراسان الرضوية',
      'category_fa': 'میراث تاریخی',
      'category_en': 'Historical Heritage',
      'category_ar': 'تراث تاريخي',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/t346o2k',

    },
    {
      'title_fa': 'رقص محلی فاروق خراسانی با آهنگ لیلا',
      'title_en': 'Farouq Khorasani Folk Dance with the Song Leila',
      'title_ar': 'رقصة فاروق الخراسانية الشعبية على أنغام ليلى',
      'location_fa': 'خراسان',
      'location_en': 'Khorasan',
      'location_ar': 'خراسان',
      'category_fa': 'فرهنگ و هنر',
      'category_en': 'Culture and Art',
      'category_ar': 'الثقافة والفنون',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/w17sz69',

    },
    {
      'title_fa': 'چشمه گراب؛ جادوی طبیعت ایران',
      'title_en': 'Gorab Spring; The Magic of Iranian Nature',
      'title_ar': 'نبع غراب؛ سحر الطبيعة الإيرانية',
      'location_fa': 'خراسان رضوی',
      'location_en': 'Razavi Khorasan',
      'location_ar': 'خراسان الرضوية',
      'category_fa': 'طبیعت ایران',
      'category_en': 'Nature of Iran',
      'category_ar': 'طبيعة إيران',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/xvo5q9c',

    },
    {
      'title_fa': 'جنگل کوه‌پارک مشهد و قله زو',
      'title_en': 'Mashhad Kuh Park Forest and Zoo Peak',
      'title_ar': 'غابة كوه بارك في مشهد وقمة زو',
      'location_fa': 'مشهد، خراسان رضوی',
      'location_en': 'Mashhad, Razavi Khorasan',
      'location_ar': 'مشهد، خراسان الرضوية',
      'category_fa': 'کوهنوردی',
      'category_en': 'Mountaineering',
      'category_ar': 'تسلق الجبال',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/hzlol4k',

    },
    {
      'title_fa': 'کاشت بلوط؛ راه نجات جنگل‌های هیرکانی',
      'title_en': 'Planting Oak Trees; A Way to Save the Hyrcanian Forests',
      'title_ar': 'زراعة أشجار البلوط؛ طريق لإنقاذ غابات هيركان',
      'location_fa': 'جنگل‌های هیرکانی',
      'location_en': 'Hyrcanian Forests',
      'location_ar': 'غابات هيركان',
      'category_fa': 'محیط زیست',
      'category_en': 'Environment',
      'category_ar': 'البيئة',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/guqcsg5',

    },
    {
      'title_fa': 'آبشار شیرآباد؛ یکی از دیدنی‌های گلستان',
      'title_en': 'Shirabad Waterfall; One of Golestan’s Natural Attractions',
      'title_ar': 'شلال شيرآباد؛ أحد المعالم الطبيعية في غلستان',
      'location_fa': 'استان گلستان',
      'location_en': 'Golestan Province',
      'location_ar': 'محافظة غلستان',
      'category_fa': 'آبشار',
      'category_en': 'Waterfall',
      'category_ar': 'شلال',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/w8lOg',

    },
    {
      'title_fa': 'آبگوشت دیزی سنگی در طبیعت',
      'title_en': 'Traditional Dizi Stone-Pot Stew in Nature',
      'title_ar': 'أبغوشت ديزي التقليدي في الطبيعة',
      'location_fa': 'ایران',
      'location_en': 'Iran',
      'location_ar': 'إيران',
      'category_fa': 'گردشگری خوراک',
      'category_en': 'Food Tourism',
      'category_ar': 'سياحة الطعام',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/uK3y5',

    },
    {
      'title_fa': '۲۵ اردیبهشت؛ روز بزرگداشت فردوسی',
      'title_en': 'May 15; Ferdowsi Commemoration Day',
      'title_ar': '15 مايو؛ يوم تكريم الفردوسي',
      'location_fa': 'مشهد، خراسان رضوی',
      'location_en': 'Mashhad, Razavi Khorasan',
      'location_ar': 'مشهد، خراسان الرضوية',
      'category_fa': 'فرهنگ و ادب',
      'category_en': 'Culture and Literature',
      'category_ar': 'الثقافة والأدب',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/nuXAC',

    },
    {
      'title_fa': 'چشمه سبز گلمکان؛ دریاچه زیبای مشهد',
      'title_en': 'Golmakan Green Spring; A Beautiful Lake near Mashhad',
      'title_ar': 'نبع سبز غلمكان؛ البحيرة الجميلة قرب مشهد',
      'location_fa': 'گلمکان، خراسان رضوی',
      'location_en': 'Golmakan, Razavi Khorasan',
      'location_ar': 'غلمكان، خراسان الرضوية',
      'category_fa': 'طبیعت ایران',
      'category_en': 'Nature of Iran',
      'category_ar': 'طبيعة إيران',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/x707h19',

    },
    {
      'title_fa': 'آموزش پخت سیب‌زمینی آتشی در طبیعت',
      'title_en': 'How to Cook Campfire Potatoes in Nature',
      'title_ar': 'طريقة إعداد البطاطا المشوية على النار في الطبيعة',
      'location_fa': 'طبیعت ایران',
      'location_en': 'Iranian Nature',
      'location_ar': 'الطبيعة الإيرانية',
      'category_fa': 'طبیعت‌گردی',
      'category_en': 'Nature Tourism',
      'category_ar': 'السياحة الطبيعية',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/4Z0hQ',

    },
    {
      'title_fa': 'جشن نوروز باستانی و سفره هفت‌سین',
      'title_en': 'Ancient Nowruz Celebration and Haft-Seen Table',
      'title_ar': 'احتفال نوروز القديم ومائدة هفت سين',
      'location_fa': 'ایران',
      'location_en': 'Iran',
      'location_ar': 'إيران',
      'category_fa': 'نوروز',
      'category_en': 'Nowruz',
      'category_ar': 'نوروز',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/s78jcie',

    },
    {
      'title_fa': 'چایخانه حمام وکیل کرمان',
      'title_en': 'Vakil Bathhouse Teahouse in Kerman',
      'title_ar': 'مقهى حمام وكيل في كرمان',
      'location_fa': 'کرمان',
      'location_en': 'Kerman',
      'location_ar': 'كرمان',
      'category_fa': 'دیدنی‌های کرمان',
      'category_en': 'Kerman Attractions',
      'category_ar': 'معالم كرمان',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/R1p3U',

    },
    {
      'title_fa': 'بجستان، آسبادهای نشتیفان و برج علی‌آباد کشمر',
      'title_en': 'Bajestan, Nashtifan Windmills and Aliabad Kashmar Tower',
      'title_ar': 'بجستان وطواحين نشتيـفان الهوائية وبرج علي آباد كاشمر',
      'location_fa': 'خراسان رضوی',
      'location_en': 'Razavi Khorasan',
      'location_ar': 'خراسان الرضوية',
      'category_fa': 'میراث تاریخی',
      'category_en': 'Historical Heritage',
      'category_ar': 'تراث تاريخي',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/g40wppg',

    },
    {
      'title_fa': 'شاه نعمت‌الله ولی؛ ماهان کرمان',
      'title_en': 'Shah Nematollah Vali; Mahan, Kerman',
      'title_ar': 'شاه نعمة الله ولي؛ ماهان، كرمان',
      'location_fa': 'ماهان، کرمان',
      'location_en': 'Mahan, Kerman',
      'location_ar': 'ماهان، كرمان',
      'category_fa': 'فرهنگ و تاریخ',
      'category_en': 'Culture and History',
      'category_ar': 'الثقافة والتاريخ',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/xsBFX',

    },
    {
      'title_fa': 'باغ شاهزاده ماهان؛ شاهکار باغ ایرانی',
      'title_en': 'Shazdeh Garden in Mahan; A Masterpiece of Persian Gardens',
      'title_ar': 'حديقة شازده ماهان؛ تحفة الحدائق الفارسية',
      'location_fa': 'ماهان، کرمان',
      'location_en': 'Mahan, Kerman',
      'location_ar': 'ماهان، كرمان',
      'category_fa': 'باغ تاریخی',
      'category_en': 'Historic Garden',
      'category_ar': 'حديقة تاريخية',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/3ZCGs',

    },
    {
      'title_fa': 'موزه بانو حیاتی؛ گنجینه‌ای در بازار کرمان',
      'title_en': 'Banoo Hayati Museum; A Treasure in Kerman Bazaar',
      'title_ar': 'متحف بانو حياتي؛ كنز في بازار كرمان',
      'location_fa': 'کرمان',
      'location_en': 'Kerman',
      'location_ar': 'كرمان',
      'category_fa': 'موزه',
      'category_en': 'Museum',
      'category_ar': 'متحف',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/z72q215',

    },
    {
      'title_fa': 'قلعه سریزد؛ نخستین بانک جهان',
      'title_en': 'Saryazd Castle; The World’s First Bank',
      'title_ar': 'قلعة سريزد؛ أول بنك في العالم',
      'location_fa': 'سریزد، یزد',
      'location_en': 'Saryazd, Yazd',
      'location_ar': 'سريزد، يزد',
      'category_fa': 'میراث تاریخی',
      'category_en': 'Historical Heritage',
      'category_ar': 'تراث تاريخي',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/c4744bv',

    },
    {
      'title_fa': 'جنگل‌های حرا و بندر تاریخی لافت',
      'title_en': 'Mangrove Forests and the Historic Port of Laft',
      'title_ar': 'غابات القرم وميناء لافت التاريخي',
      'location_fa': 'جزیره قشم',
      'location_en': 'Qeshm Island',
      'location_ar': 'جزيرة قشم',
      'category_fa': 'سواحل و جزایر',
      'category_en': 'Coasts and Islands',
      'category_ar': 'السواحل والجزر',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/kGS8o',

    },
    {
      'title_fa': 'باغ فین کاشان با موسیقی سنتی',
      'title_en': 'Fin Garden in Kashan with Traditional Music',
      'title_ar': 'حديقة فين في كاشان مع الموسيقى التقليدية',
      'location_fa': 'کاشان',
      'location_en': 'Kashan',
      'location_ar': 'كاشان',
      'category_fa': 'باغ تاریخی',
      'category_en': 'Historic Garden',
      'category_ar': 'حديقة تاريخية',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/mPh2q',

    },
    {
      'title_fa': 'غار علی‌صدر؛ غار تالابی شگفت‌انگیز ایران',
      'title_en': 'Ali Sadr Cave; Iran’s Amazing Water Cave',
      'title_ar': 'كهف علي صدر؛ الكهف المائي المذهل في إيران',
      'location_fa': 'همدان',
      'location_en': 'Hamadan',
      'location_ar': 'همدان',
      'category_fa': 'غار و طبیعت',
      'category_en': 'Cave and Nature',
      'category_ar': 'الكهوف والطبيعة',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/k2RDX',

    },
    {
      'title_fa': 'آبشار اخلمد چناران؛ طبیعت زیبای خراسان',
      'title_en': 'Akhlamad Waterfall in Chenaran; The Beautiful Nature of Khorasan',
      'title_ar': 'شلال أخلمد في چناران؛ طبيعة خراسان الجميلة',
      'location_fa': 'چناران، خراسان رضوی',
      'location_en': 'Chenaran, Razavi Khorasan',
      'location_ar': 'چناران، خراسان الرضوية',
      'category_fa': 'آبشار',
      'category_en': 'Waterfall',
      'category_ar': 'شلال',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/f91418q',

    },
    {
      'title_fa': 'جشن نوروز تخت جمشید؛ شهر پارس و پاسارگاد',
      'title_en': 'Nowruz Celebration at Persepolis; The Land of Pars and Pasargadae',
      'title_ar': 'احتفال نوروز في تخت جمشيد؛ أرض فارس وباسارغاد',
      'location_fa': 'فارس',
      'location_en': 'Fars',
      'location_ar': 'فارس',
      'category_fa': 'میراث ایران',
      'category_en': 'Iranian Heritage',
      'category_ar': 'التراث الإيراني',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/v/f5212r6',

    },
  ];

  String get _languageCode {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.italian:
        return 'it';
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.chinese:
        return 'zh';
    }
  }

  String _text(
    Map<String, String> video,
    String key,
  ) {
    return video['${key}_$_languageCode'] ??
        video['${key}_fa'] ??
        '';
  }

  // -----------------------------------------------------------
  // جست‌وجوی پیشرفته + فیلتر دسته‌بندی
  // -----------------------------------------------------------

  List<String> get _categories {
    final seen = <String>{};
    final list = <String>[];
    for (final video in selectedVideos) {
      final cat = _text(video, 'category');
      if (cat.isNotEmpty && seen.add(cat)) {
        list.add(cat);
      }
    }
    return list;
  }

  List<Map<String, String>> get _filteredVideos {
    final query = _searchQuery.trim().toLowerCase();

    return selectedVideos.where((video) {
      final matchesCategory =
          _selectedCategory == 'all' || _text(video, 'category') == _selectedCategory;

      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      final haystack = [
        _text(video, 'title'),
        _text(video, 'location'),
        _text(video, 'category'),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  String get _searchHint {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'جست‌وجو با نام فیلم، شهر یا استان...';
      case AppLanguage.arabic:
        return 'ابحث بالاسم أو المدينة أو المحافظة...';
      case AppLanguage.english:
      default:
        return 'Search by title, city or province...';
    }
  }

  String get _allChipLabel {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'همه';
      case AppLanguage.arabic:
        return 'الكل';
      case AppLanguage.english:
      default:
        return 'All';
    }
  }

  String get _leaderTourChipLabel {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'لیدر تور 🧭';
      case AppLanguage.arabic:
        return 'قائد الجولة 🧭';
      case AppLanguage.english:
      default:
        return 'Tour Leader 🧭';
    }
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _searchHint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search_rounded, color: appGoldColor.withValues(alpha: 0.8)),
              filled: true,
              fillColor: appCardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: appGoldColor.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: appGoldColor.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: appGoldColor, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(label: _allChipLabel, value: 'all'),
                const SizedBox(width: 8),
                for (final cat in _categories) ...[
                  _filterChip(label: cat, value: cat),
                  const SizedBox(width: 8),
                ],
                // «لیدر تور» — کلید ثابت و همیشه‌حاضر، در همه نوارهای
                // فیلتر اپ نمایش داده می‌شود (مطابق سایت).
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeadersListPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: appGoldColor.withValues(alpha: 0.7),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Text(
                      _leaderTourChipLabel,
                      style: TextStyle(
                        color: appGoldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final selected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(colors: [Color(0xff29e0ad), Color(0xff3ff0a8)])
              : null,
          color: selected ? null : appCardColor,
          border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xff06121d) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  String get _pageTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'فیلم‌های گردشگری';
      case AppLanguage.arabic:
        return 'فيديوهات سياحية';
      case AppLanguage.english:
        return 'Tourism Videos';
      case AppLanguage.german:
        return 'Tourismus-Videos';
      case AppLanguage.spanish:
        return 'Vídeos turísticos';
      case AppLanguage.french:
        return 'Vidéos touristiques';
      case AppLanguage.italian:
        return 'Video turistici';
      case AppLanguage.russian:
        return 'Туристические видео';
      case AppLanguage.turkish:
        return 'Turizm Videoları';
      case AppLanguage.chinese:
        return '旅游视频';
    }
  }

  String get _selectedTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'فیلم‌های منتخب گردشگری';
      case AppLanguage.arabic:
        return 'فيديوهات سياحية مختارة';
      case AppLanguage.english:
        return 'Selected Tourism Videos';
      case AppLanguage.german:
        return 'Ausgewählte Tourismus-Videos';
      case AppLanguage.spanish:
        return 'Vídeos turísticos seleccionados';
      case AppLanguage.french:
        return 'Vidéos touristiques sélectionnées';
      case AppLanguage.italian:
        return 'Video turistici selezionati';
      case AppLanguage.russian:
        return 'Избранные туристические видео';
      case AppLanguage.turkish:
        return 'Seçilmiş Turizm Videoları';
      case AppLanguage.chinese:
        return '精选旅游视频';
    }
  }

  String get _slogan {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'ایران را زیبا ببینید.';
      case AppLanguage.arabic:
        return 'اكتشفوا جمال إيران.';
      case AppLanguage.english:
        return 'Discover the beauty of Iran.';
      case AppLanguage.german:
        return 'Entdecken Sie die Schönheit des Iran.';
      case AppLanguage.spanish:
        return 'Descubre la belleza de Irán.';
      case AppLanguage.french:
        return "Découvrez la beauté de l'Iran.";
      case AppLanguage.italian:
        return "Scopri la bellezza dell'Iran.";
      case AppLanguage.russian:
        return 'Откройте для себя красоту Ирана.';
      case AppLanguage.turkish:
        return 'İran\'ın güzelliğini keşfedin.';
      case AppLanguage.chinese:
        return '探索伊朗之美。';
    }
  }

  String get _visitText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'بازدید';
      case AppLanguage.arabic:
        return 'زيارة';
      case AppLanguage.english:
        return 'Visit';
      case AppLanguage.german:
        return 'Ansehen';
      case AppLanguage.spanish:
        return 'Ver';
      case AppLanguage.french:
        return 'Voir';
      case AppLanguage.italian:
        return 'Guarda';
      case AppLanguage.russian:
        return 'Смотреть';
      case AppLanguage.turkish:
        return 'İzle';
      case AppLanguage.chinese:
        return '观看';
    }
  }

  String get _leftHeaderText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'گالری فیلم‌ها';
      case AppLanguage.arabic:
        return 'معرض الفيديوهات';
      case AppLanguage.english:
        return 'Video Gallery';
      case AppLanguage.german:
        return 'Videogalerie';
      case AppLanguage.spanish:
        return 'Galería de vídeos';
      case AppLanguage.french:
        return 'Galerie de vidéos';
      case AppLanguage.italian:
        return 'Galleria video';
      case AppLanguage.russian:
        return 'Видеогалерея';
      case AppLanguage.turkish:
        return 'Video Galerisi';
      case AppLanguage.chinese:
        return '视频画廊';
    }
  }

  String get _rightHeaderText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'جاذبه‌های گردشگری';
      case AppLanguage.arabic:
        return 'المعالم السياحية';
      case AppLanguage.english:
        return 'Tourist Attractions';
      case AppLanguage.german:
        return 'Sehenswürdigkeiten';
      case AppLanguage.spanish:
        return 'Atracciones turísticas';
      case AppLanguage.french:
        return 'Attractions touristiques';
      case AppLanguage.italian:
        return 'Attrazioni turistiche';
      case AppLanguage.russian:
        return 'Туристические достопримечательности';
      case AppLanguage.turkish:
        return 'Turistik Yerler';
      case AppLanguage.chinese:
        return '旅游景点';
    }
  }


  String get _backText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'بازگشت';
      case AppLanguage.arabic:
        return 'رجوع';
      case AppLanguage.english:
        return 'Back';
      case AppLanguage.german:
        return 'Zurück';
      case AppLanguage.spanish:
        return 'Atrás';
      case AppLanguage.french:
        return 'Retour';
      case AppLanguage.italian:
        return 'Indietro';
      case AppLanguage.russian:
        return 'Назад';
      case AppLanguage.turkish:
        return 'Geri';
      case AppLanguage.chinese:
        return '返回';
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageCode == 'fa'
                  ? 'امکان باز کردن لینک آپارات وجود ندارد.'
                  : _languageCode == 'ar'
                      ? 'تعذر فتح رابط آپارات.'
                      : 'Unable to open the Aparat link.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageCode == 'fa'
                ? 'خطا در باز کردن آپارات.'
                : _languageCode == 'ar'
                    ? 'حدث خطأ أثناء فتح آپارات.'
                    : 'Error opening Aparat.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        LanguageManager.current == AppLanguage.arabic;
    final bool isPersian =
        LanguageManager.current == AppLanguage.persian;

    return Directionality(
      textDirection:
          isPersian || isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: appBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBackgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            _pageTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Column(
                    children: [
                      _buildHeaderImage(),
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(() {
                            _showSelectedVideos = !_showSelectedVideos;
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff0b2a3c),
                              Color(0xff09202e),
                            ],
                          ),
                          border: Border.all(
                            color:
                                appGoldColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    appGoldColor.withValues(alpha: 0.13),
                                border: Border.all(
                                  color: appGoldColor.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.ondemand_video_rounded,
                                color: appGoldColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTitle,
                                    style: const TextStyle(
                                      color: appGoldBright,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _slogan,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _showSelectedVideos ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: appGoldColor,
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ResidenceRegisterPage(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [appTealColor, appTealBright],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: appTealColor.withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.home_work_rounded,
                                color: Color(0xff03202a),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  'ثبت‌نام اقامتگاه / گردشگری سلامت',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xff03202a),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSelectedVideos)
                SliverToBoxAdapter(child: _buildSearchAndFilters()),
              if (_showSelectedVideos)
                SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildVideoCard(
                      _filteredVideos[index],
                      index,
                    );
                  },
                  childCount: _filteredVideos.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(
                        _backText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appGoldBright,
                        side: BorderSide(
                          color: appGoldColor.withValues(alpha: 0.60),
                        ),
                        backgroundColor: appGoldColor.withValues(alpha: 0.06),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        shadowColor: appGoldColor,
                        elevation: 5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 1536 / 1024,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/video_menu_header.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: _HeaderHalfButton(
                text: _leftHeaderText,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MovieSlotGalleryPage(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: _HeaderHalfButton(
                text: _rightHeaderText,
                onTap: () => _openUrl(aparatChannel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(
    Map<String, String> video,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: appCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: appGoldColor.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _VideoCoverPlayer(
              url: video['url']!,
              fallbackAsset: 'assets/images/video_menu_header.png',
              onOpenExternal: () => _openUrl(video['url']!),
              onTitleResolved: (title) {
                if (title == null || title.trim().isEmpty) return;
                if (_resolvedAparatTitles[video['url']!] == title) return;
                if (mounted) {
                  setState(() {
                    _resolvedAparatTitles[video['url']!] = title;
                  });
                }
              },
              language: _languageCode,
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appGoldColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: appGoldColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: appGoldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _text(video, 'title'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _toggleFavoriteVideo(video),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appCardColor,
                      border: Border.all(
                        color: appGoldColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      _favoriteVideoIds.contains(_videoId(video))
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _favoriteVideoIds.contains(_videoId(video))
                          ? const Color(0xffff6b81)
                          : appGoldColor,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: appGoldColor,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _text(video, 'location'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: appGoldColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: appGoldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _text(video, 'category'),
                    style: const TextStyle(
                      color: appGoldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(video['url']!),
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  _visitText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGoldColor,
                  foregroundColor: appBackgroundColor,
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SocialWideButton extends StatefulWidget {
  const _SocialWideButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SocialWideButton> createState() => _SocialWideButtonState();
}

class _SocialWideButtonState extends State<_SocialWideButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              const Color(0xff0c3042),
              appGoldColor.withValues(alpha: _pressed ? 0.18 : 0.07),
            ],
          ),
          border: Border.all(
            color: _pressed
                ? appGoldBright
                : appGoldColor.withValues(alpha: 0.35),
            width: _pressed ? 1.7 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: appGoldColor.withValues(alpha: _pressed ? 0.42 : 0.08),
              blurRadius: _pressed ? 18 : 8,
              spreadRadius: _pressed ? 1 : 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appGoldColor.withValues(alpha: 0.10),
                border: Border.all(color: appGoldColor.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: appGoldColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: appGoldBright, size: 27),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                widget.label,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: appGoldColor, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HeaderHalfButton extends StatefulWidget {
  const _HeaderHalfButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  State<_HeaderHalfButton> createState() => _HeaderHalfButtonState();
}

class _HeaderHalfButtonState extends State<_HeaderHalfButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed
              ? appGoldColor.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: _pressed
                ? appGoldBright
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: appGoldColor.withValues(alpha: 0.8),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _pressed ? 1 : 0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: appBackgroundColor.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: appGoldColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appGoldColor.withValues(alpha: 0.55),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: appGoldBright,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AparatPlayer extends StatefulWidget {
  const _AparatPlayer({
    required this.url,
    required this.onTap,
  });

  final String url;
  final VoidCallback onTap;

  @override
  State<_AparatPlayer> createState() => _AparatPlayerState();
}

class _AparatPlayerState extends State<_AparatPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  String _extractAparatId(String url) {
    final uri = Uri.tryParse(url);

    if (uri == null) return '';

    final segments =
        uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (segments.isEmpty) return '';

    if (segments.first == 'v' && segments.length >= 2) {
      return segments[1];
    }

    return segments.last;
  }

  @override
  void initState() {
    super.initState();

    final String videoId = _extractAparatId(widget.url);

    final String embedUrl =
        'https://www.aparat.com/video/video/embed/videohash/'
        '$videoId/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(appBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _loading = true; _failed = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() { _loading = false; _failed = true; });
          },
          onNavigationRequest: (request) {
            if (request.url.contains('aparat.com')) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(
              controller: _controller,
            ),
            if (_loading)
              Container(
                color: appBackgroundColor,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: appGoldColor,
                ),
              ),
            if (_failed)
              Container(
                color: appBackgroundColor,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: appGoldColor, size: 34),
                    const SizedBox(height: 8),
                    const Text(
                      'پخش مستقیم آپارات بارگذاری نشد',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() { _failed = false; _loading = true; });
                        _controller.reload();
                      },
                      child: const Text('تلاش دوباره'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// APARAT COVER — دریافت کاور واقعی، مدت‌زمان و تعداد بازدید
// از API رسمی آپارات (بدون هیچ داده یا لینک جعلی)
// ============================================================

class _AparatVideoInfo {
  final String? title;
  final String? coverUrl;
  final String? duration;
  final String? visitCount;

  const _AparatVideoInfo({
    this.title,
    this.coverUrl,
    this.duration,
    this.visitCount,
  });
}

class _AparatCoverLoader {
  static final Map<String, _AparatVideoInfo?> _cache = {};

  static Future<_AparatVideoInfo?> fetchInfo(
    String videoHash,
  ) async {
    if (_cache.containsKey(videoHash)) {
      return _cache[videoHash];
    }

    HttpClient? client;

    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(
        Uri.parse(
          'https://www.aparat.com/etc/api/video/videohash/$videoHash',
        ),
      );

      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Android; CyrusTourist App)',
      );

      final response = await request.close();

      if (response.statusCode != 200) {
        _cache[videoHash] = null;
        return null;
      }

      final body = await response
          .transform(utf8.decoder)
          .join();

      final decoded = jsonDecode(body);
      final video = decoded is Map
          ? decoded['video'] as Map<String, dynamic>?
          : null;

      if (video == null) {
        _cache[videoHash] = null;
        return null;
      }

      final info = _AparatVideoInfo(
        title: video['title']?.toString(),
        coverUrl: video['big_poster'] as String? ??
            video['small_poster'] as String?,
        duration: video['duration']?.toString(),
        visitCount: video['visit_cnt']?.toString(),
      );

      _cache[videoHash] = info;
      return info;
    } catch (_) {
      _cache[videoHash] = null;
      return null;
    } finally {
      client?.close();
    }
  }
}

String _formatDuration(String? rawSeconds) {
  final seconds = int.tryParse(rawSeconds ?? '');

  if (seconds == null || seconds <= 0) return '';

  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;

  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

// ============================================================
// VIDEO COVER PLAYER
//
// حالت اول: کاور واقعی آپارات (سبک و سریع).
// با لمس کاور → پخش‌کننده واقعی آپارات (همان embed سایت) باز می‌شود.
// ============================================================

class _VideoCoverPlayer extends StatefulWidget {
  const _VideoCoverPlayer({
    required this.url,
    required this.fallbackAsset,
    required this.onOpenExternal,
    required this.onTitleResolved,
    required this.language,
  });

  final String url;
  final String fallbackAsset;
  final VoidCallback onOpenExternal;
  final ValueChanged<String?> onTitleResolved;
  final String language;

  @override
  State<_VideoCoverPlayer> createState() =>
      _VideoCoverPlayerState();
}

class _VideoCoverPlayerState extends State<_VideoCoverPlayer> {
  _AparatVideoInfo? _info;
  bool _playing = false;

  String get _videoHash {
    final uri = Uri.tryParse(widget.url);

    if (uri == null) return '';

    final segments =
        uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (segments.isEmpty) return '';

    if (segments.first == 'v' && segments.length >= 2) {
      return segments[1];
    }

    return segments.last;
  }

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final hash = _videoHash;

    if (hash.isEmpty) return;

    final info = await _AparatCoverLoader.fetchInfo(hash);

    if (!mounted || info == null) return;

    setState(() {
      _info = info;
    });

    widget.onTitleResolved(info.title);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _playing
            ? _AparatPlayer(
                url: widget.url,
                onTap: widget.onOpenExternal,
              )
            : _buildCover(),
      ),
    );
  }

  Widget _buildCover() {
    final duration = _formatDuration(_info?.duration);

    return GestureDetector(
      onTap: () {
        setState(() {
          _playing = true;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _info?.coverUrl != null
              ? Image.network(
                  _info!.coverUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return Image.asset(
                      widget.fallbackAsset,
                      fit: BoxFit.cover,
                    );
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    widget.fallbackAsset,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  widget.fallbackAsset,
                  fit: BoxFit.cover,
                ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appGoldColor.withValues(alpha: 0.94),
                boxShadow: [
                  BoxShadow(
                    color: appGoldColor.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: appBackgroundColor,
                size: 36,
              ),
            ),
          ),

          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ondemand_video_rounded,
                    color: appGoldColor,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Aparat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_info?.visitCount != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      color: appGoldColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _info!.visitCount!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
