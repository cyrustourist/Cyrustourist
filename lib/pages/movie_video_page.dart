import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/app_language.dart';

// ===================== رنگ‌ها — هماهنگ با residence_video_page.dart =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _cardAlt = Color(0xff0a1c28);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);
const Color _tealBright = Color(0xff6df5cf);

const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];

Color _goldA(double a) => _gold.withValues(alpha: a);

String get _lang {
  switch (LanguageManager.current) {
    case AppLanguage.persian:
      return 'fa';
    case AppLanguage.english:
      return 'en';
    case AppLanguage.arabic:
      return 'ar';
    default:
      return 'en';
  }
}

bool get _isRtl => _lang == 'fa' || _lang == 'ar';

String t(String fa, String en, String ar) {
  switch (_lang) {
    case 'en':
      return en;
    case 'ar':
      return ar;
    default:
      return fa;
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('امکان باز کردن لینک وجود ندارد.',
              'Unable to open this link.', 'تعذر فتح هذا الرابط.')),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('خطا در باز کردن لینک.', 'Error opening the link.',
              'خطأ في فتح الرابط.')),
        ),
      );
    }
  }
}

// ============================================================
// مدل داده‌ی هر «جایگاه فیلم» — با کد یکتا
// ============================================================
//
// ۲۲ فیلم فعلی = جایگاه‌های «پر» (assigned:true). جایگاه‌های بعدی
// خالی هستند و برای ثبت‌نام‌های آینده رزرو شده‌اند — دقیقاً همان
// منطق kResidenceSlots در residence_video_page.dart.

class MovieSlotData {
  const MovieSlotData({
    required this.code,
    this.assigned = false,
    this.name,
    this.nameEn,
    this.nameAr,
    this.city,
    this.cityEn,
    this.cityAr,
    this.category,
    this.categoryEn,
    this.categoryAr,
    this.aparatUrl,
    this.mobilePhone = '09153448818',
    this.instagramUrl =
        'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
    this.websiteUrl = 'https://cyrustourist-maker.github.io/Cyrustourist/',
  });

  final int code;
  final bool assigned;

  final String? name;
  final String? nameEn;
  final String? nameAr;

  final String? city;
  final String? cityEn;
  final String? cityAr;

  final String? category;
  final String? categoryEn;
  final String? categoryAr;

  final String? aparatUrl;

  final String mobilePhone;
  final String instagramUrl;
  final String websiteUrl;

  String get displayName {
    final localized =
        t(name ?? '', nameEn ?? name ?? '', nameAr ?? name ?? '');
    return localized.isNotEmpty
        ? localized
        : t('فیلم شماره $code', 'Video #$code', 'فيديو رقم $code');
  }

  String get displayCity =>
      t(city ?? '', cityEn ?? city ?? '', cityAr ?? city ?? '');

  String get displayCategory =>
      t(category ?? '', categoryEn ?? category ?? '', categoryAr ?? category ?? '');

  /// برای جست‌وجو — کد + همه‌ی زبان‌های نام/شهر/دسته با هم، مستقل از زبان فعلی
  String get searchHaystack => [
        code.toString(),
        name,
        nameEn,
        nameAr,
        city,
        cityEn,
        cityAr,
        category,
        categoryEn,
        categoryAr,
      ].whereType<String>().join(' ').toLowerCase();
}

// ============================================================
// ۲۲ فیلم فعلی (بدون تغییر در ترکیب/ترتیب) + جایگاه‌های خالی آینده
// ============================================================

const List<MovieSlotData> kMovieSlots = [
  MovieSlotData(
    code: 1,
    assigned: true,
    name: 'قنات قصبه گناباد؛ شگفتی تاریخ تمدن بشر',
    nameEn: 'Qasabeh Gonabad Qanat; A Wonder of Human Civilization',
    nameAr: 'قناة قصبة گناباد؛ أعجوبة من تاريخ الحضارة البشرية',
    city: 'گناباد، خراسان رضوی',
    cityEn: 'Gonabad, Razavi Khorasan',
    cityAr: 'غناباد، خراسان الرضوية',
    category: 'میراث تاریخی',
    categoryEn: 'Historical Heritage',
    categoryAr: 'تراث تاريخي',
    aparatUrl: 'https://www.aparat.com/v/t346o2k',
  ),
  MovieSlotData(
    code: 2,
    assigned: true,
    name: 'رقص محلی فاروق خراسانی با آهنگ لیلا',
    nameEn: 'Farouq Khorasani Folk Dance with the Song Leila',
    nameAr: 'رقصة فاروق الخراسانية الشعبية على أنغام ليلى',
    city: 'خراسان',
    cityEn: 'Khorasan',
    cityAr: 'خراسان',
    category: 'فرهنگ و هنر',
    categoryEn: 'Culture and Art',
    categoryAr: 'الثقافة والفنون',
    aparatUrl: 'https://www.aparat.com/v/w17sz69',
  ),
  MovieSlotData(
    code: 3,
    assigned: true,
    name: 'چشمه گراب؛ جادوی طبیعت ایران',
    nameEn: 'Gorab Spring; The Magic of Iranian Nature',
    nameAr: 'نبع غراب؛ سحر الطبيعة الإيرانية',
    city: 'خراسان رضوی',
    cityEn: 'Razavi Khorasan',
    cityAr: 'خراسان الرضوية',
    category: 'طبیعت ایران',
    categoryEn: 'Nature of Iran',
    categoryAr: 'طبيعة إيران',
    aparatUrl: 'https://www.aparat.com/v/xvo5q9c',
  ),
  MovieSlotData(
    code: 4,
    assigned: true,
    name: 'جنگل کوه‌پارک مشهد و قله زو',
    nameEn: 'Mashhad Kuh Park Forest and Zoo Peak',
    nameAr: 'غابة كوه بارك في مشهد وقمة زو',
    city: 'مشهد، خراسان رضوی',
    cityEn: 'Mashhad, Razavi Khorasan',
    cityAr: 'مشهد، خراسان الرضوية',
    category: 'کوهنوردی',
    categoryEn: 'Mountaineering',
    categoryAr: 'تسلق الجبال',
    aparatUrl: 'https://www.aparat.com/v/hzlol4k',
  ),
  MovieSlotData(
    code: 5,
    assigned: true,
    name: 'کاشت بلوط؛ راه نجات جنگل‌های هیرکانی',
    nameEn: 'Planting Oak Trees; A Way to Save the Hyrcanian Forests',
    nameAr: 'زراعة أشجار البلوط؛ طريق لإنقاذ غابات هيركان',
    city: 'جنگل‌های هیرکانی',
    cityEn: 'Hyrcanian Forests',
    cityAr: 'غابات هيركان',
    category: 'محیط زیست',
    categoryEn: 'Environment',
    categoryAr: 'البيئة',
    aparatUrl: 'https://www.aparat.com/v/guqcsg5',
  ),
  MovieSlotData(
    code: 6,
    assigned: true,
    name: 'آبشار شیرآباد؛ یکی از دیدنی‌های گلستان',
    nameEn: 'Shirabad Waterfall; One of Golestan’s Natural Attractions',
    nameAr: 'شلال شيرآباد؛ أحد المعالم الطبيعية في غلستان',
    city: 'استان گلستان',
    cityEn: 'Golestan Province',
    cityAr: 'محافظة غلستان',
    category: 'آبشار',
    categoryEn: 'Waterfall',
    categoryAr: 'شلال',
    aparatUrl: 'https://www.aparat.com/v/w8lOg',
  ),
  MovieSlotData(
    code: 7,
    assigned: true,
    name: 'آبگوشت دیزی سنگی در طبیعت',
    nameEn: 'Traditional Dizi Stone-Pot Stew in Nature',
    nameAr: 'أبغوشت ديزي التقليدي في الطبيعة',
    city: 'ایران',
    cityEn: 'Iran',
    cityAr: 'إيران',
    category: 'گردشگری خوراک',
    categoryEn: 'Food Tourism',
    categoryAr: 'سياحة الطعام',
    aparatUrl: 'https://www.aparat.com/v/uK3y5',
  ),
  MovieSlotData(
    code: 8,
    assigned: true,
    name: '۲۵ اردیبهشت؛ روز بزرگداشت فردوسی',
    nameEn: 'May 15; Ferdowsi Commemoration Day',
    nameAr: '15 مايو؛ يوم تكريم الفردوسي',
    city: 'مشهد، خراسان رضوی',
    cityEn: 'Mashhad, Razavi Khorasan',
    cityAr: 'مشهد، خراسان الرضوية',
    category: 'فرهنگ و ادب',
    categoryEn: 'Culture and Literature',
    categoryAr: 'الثقافة والأدب',
    aparatUrl: 'https://www.aparat.com/v/nuXAC',
  ),
  MovieSlotData(
    code: 9,
    assigned: true,
    name: 'چشمه سبز گلمکان؛ دریاچه زیبای مشهد',
    nameEn: 'Golmakan Green Spring; A Beautiful Lake near Mashhad',
    nameAr: 'نبع سبز غلمكان؛ البحيرة الجميلة قرب مشهد',
    city: 'گلمکان، خراسان رضوی',
    cityEn: 'Golmakan, Razavi Khorasan',
    cityAr: 'غلمكان، خراسان الرضوية',
    category: 'طبیعت ایران',
    categoryEn: 'Nature of Iran',
    categoryAr: 'طبيعة إيران',
    aparatUrl: 'https://www.aparat.com/v/x707h19',
  ),
  MovieSlotData(
    code: 10,
    assigned: true,
    name: 'آموزش پخت سیب‌زمینی آتشی در طبیعت',
    nameEn: 'How to Cook Campfire Potatoes in Nature',
    nameAr: 'طريقة إعداد البطاطا المشوية على النار في الطبيعة',
    city: 'طبیعت ایران',
    cityEn: 'Iranian Nature',
    cityAr: 'الطبيعة الإيرانية',
    category: 'طبیعت‌گردی',
    categoryEn: 'Nature Tourism',
    categoryAr: 'السياحة الطبيعية',
    aparatUrl: 'https://www.aparat.com/v/4Z0hQ',
  ),
  MovieSlotData(
    code: 11,
    assigned: true,
    name: 'جشن نوروز باستانی و سفره هفت‌سین',
    nameEn: 'Ancient Nowruz Celebration and Haft-Seen Table',
    nameAr: 'احتفال نوروز القديم ومائدة هفت سين',
    city: 'ایران',
    cityEn: 'Iran',
    cityAr: 'إيران',
    category: 'نوروز',
    categoryEn: 'Nowruz',
    categoryAr: 'نوروز',
    aparatUrl: 'https://www.aparat.com/v/s78jcie',
  ),
  MovieSlotData(
    code: 12,
    assigned: true,
    name: 'چایخانه حمام وکیل کرمان',
    nameEn: 'Vakil Bathhouse Teahouse in Kerman',
    nameAr: 'مقهى حمام وكيل في كرمان',
    city: 'کرمان',
    cityEn: 'Kerman',
    cityAr: 'كرمان',
    category: 'دیدنی‌های کرمان',
    categoryEn: 'Kerman Attractions',
    categoryAr: 'معالم كرمان',
    aparatUrl: 'https://www.aparat.com/v/R1p3U',
  ),
  MovieSlotData(
    code: 13,
    assigned: true,
    name: 'بجستان، آسبادهای نشتیفان و برج علی‌آباد کشمر',
    nameEn: 'Bajestan, Nashtifan Windmills and Aliabad Kashmar Tower',
    nameAr: 'بجستان وطواحين نشتيـفان الهوائية وبرج علي آباد كاشمر',
    city: 'خراسان رضوی',
    cityEn: 'Razavi Khorasan',
    cityAr: 'خراسان الرضوية',
    category: 'میراث تاریخی',
    categoryEn: 'Historical Heritage',
    categoryAr: 'تراث تاريخي',
    aparatUrl: 'https://www.aparat.com/v/g40wppg',
  ),
  MovieSlotData(
    code: 14,
    assigned: true,
    name: 'شاه نعمت‌الله ولی؛ ماهان کرمان',
    nameEn: 'Shah Nematollah Vali; Mahan, Kerman',
    nameAr: 'شاه نعمة الله ولي؛ ماهان، كرمان',
    city: 'ماهان، کرمان',
    cityEn: 'Mahan, Kerman',
    cityAr: 'ماهان، كرمان',
    category: 'فرهنگ و تاریخ',
    categoryEn: 'Culture and History',
    categoryAr: 'الثقافة والتاريخ',
    aparatUrl: 'https://www.aparat.com/v/xsBFX',
  ),
  MovieSlotData(
    code: 15,
    assigned: true,
    name: 'باغ شاهزاده ماهان؛ شاهکار باغ ایرانی',
    nameEn: 'Shazdeh Garden in Mahan; A Masterpiece of Persian Gardens',
    nameAr: 'حديقة شازده ماهان؛ تحفة الحدائق الفارسية',
    city: 'ماهان، کرمان',
    cityEn: 'Mahan, Kerman',
    cityAr: 'ماهان، كرمان',
    category: 'باغ تاریخی',
    categoryEn: 'Historic Garden',
    categoryAr: 'حديقة تاريخية',
    aparatUrl: 'https://www.aparat.com/v/3ZCGs',
  ),
  MovieSlotData(
    code: 16,
    assigned: true,
    name: 'موزه بانو حیاتی؛ گنجینه‌ای در بازار کرمان',
    nameEn: 'Banoo Hayati Museum; A Treasure in Kerman Bazaar',
    nameAr: 'متحف بانو حياتي؛ كنز في بازار كرمان',
    city: 'کرمان',
    cityEn: 'Kerman',
    cityAr: 'كرمان',
    category: 'موزه',
    categoryEn: 'Museum',
    categoryAr: 'متحف',
    aparatUrl: 'https://www.aparat.com/v/z72q215',
  ),
  MovieSlotData(
    code: 17,
    assigned: true,
    name: 'قلعه سریزد؛ نخستین بانک جهان',
    nameEn: 'Saryazd Castle; The World’s First Bank',
    nameAr: 'قلعة سريزد؛ أول بنك في العالم',
    city: 'سریزد، یزد',
    cityEn: 'Saryazd, Yazd',
    cityAr: 'سريزد، يزد',
    category: 'میراث تاریخی',
    categoryEn: 'Historical Heritage',
    categoryAr: 'تراث تاريخي',
    aparatUrl: 'https://www.aparat.com/v/c4744bv',
  ),
  MovieSlotData(
    code: 18,
    assigned: true,
    name: 'جنگل‌های حرا و بندر تاریخی لافت',
    nameEn: 'Mangrove Forests and the Historic Port of Laft',
    nameAr: 'غابات القرم وميناء لافت التاريخي',
    city: 'جزیره قشم',
    cityEn: 'Qeshm Island',
    cityAr: 'جزيرة قشم',
    category: 'سواحل و جزایر',
    categoryEn: 'Coasts and Islands',
    categoryAr: 'السواحل والجزر',
    aparatUrl: 'https://www.aparat.com/v/kGS8o',
  ),
  MovieSlotData(
    code: 19,
    assigned: true,
    name: 'باغ فین کاشان با موسیقی سنتی',
    nameEn: 'Fin Garden in Kashan with Traditional Music',
    nameAr: 'حديقة فين في كاشان مع الموسيقى التقليدية',
    city: 'کاشان',
    cityEn: 'Kashan',
    cityAr: 'كاشان',
    category: 'باغ تاریخی',
    categoryEn: 'Historic Garden',
    categoryAr: 'حديقة تاريخية',
    aparatUrl: 'https://www.aparat.com/v/mPh2q',
  ),
  MovieSlotData(
    code: 20,
    assigned: true,
    name: 'غار علی‌صدر؛ غار تالابی شگفت‌انگیز ایران',
    nameEn: 'Ali Sadr Cave; Iran’s Amazing Water Cave',
    nameAr: 'كهف علي صدر؛ الكهف المائي المذهل في إيران',
    city: 'همدان',
    cityEn: 'Hamadan',
    cityAr: 'همدان',
    category: 'غار و طبیعت',
    categoryEn: 'Cave and Nature',
    categoryAr: 'الكهوف والطبيعة',
    aparatUrl: 'https://www.aparat.com/v/k2RDX',
  ),
  MovieSlotData(
    code: 21,
    assigned: true,
    name: 'آبشار اخلمد چناران؛ طبیعت زیبای خراسان',
    nameEn: 'Akhlamad Waterfall in Chenaran; The Beautiful Nature of Khorasan',
    nameAr: 'شلال أخلمد في چناران؛ طبيعة خراسان الجميلة',
    city: 'چناران، خراسان رضوی',
    cityEn: 'Chenaran, Razavi Khorasan',
    cityAr: 'چناران، خراسان الرضوية',
    category: 'آبشار',
    categoryEn: 'Waterfall',
    categoryAr: 'شلال',
    aparatUrl: 'https://www.aparat.com/v/f91418q',
  ),
  MovieSlotData(
    code: 22,
    assigned: true,
    name: 'جشن نوروز تخت جمشید؛ شهر پارس و پاسارگاد',
    nameEn:
        'Nowruz Celebration at Persepolis; The Land of Pars and Pasargadae',
    nameAr: 'احتفال نوروز في تخت جمشيد؛ أرض فارس وباسارغاد',
    city: 'فارس',
    cityEn: 'Fars',
    cityAr: 'فارس',
    category: 'میراث ایران',
    categoryEn: 'Iranian Heritage',
    categoryAr: 'التراث الإيراني',
    aparatUrl: 'https://www.aparat.com/v/f5212r6',
  ),
  // جایگاه‌های خالی — برای ثبت‌نام‌های آینده (کد یکتای هرکدام آماده است)
  MovieSlotData(code: 23),
  MovieSlotData(code: 24),
  MovieSlotData(code: 25),
  MovieSlotData(code: 26),
  MovieSlotData(code: 27),
  MovieSlotData(code: 28),
  MovieSlotData(code: 29),
  MovieSlotData(code: 30),
];

// ============================================================
// صفحه‌ی گالری فیلم‌ها — با جست‌وجوی هوشمند
// ============================================================

class MovieSlotGalleryPage extends StatefulWidget {
  const MovieSlotGalleryPage({super.key, this.slots = kMovieSlots});

  final List<MovieSlotData> slots;

  @override
  State<MovieSlotGalleryPage> createState() => _MovieSlotGalleryPageState();
}

class _MovieSlotGalleryPageState extends State<MovieSlotGalleryPage> {
  String _query = '';

  String get _hint => t(
        'جست‌وجو با کد، نام فیلم، شهر یا استان...',
        'Search by code, title, city or province...',
        'البحث بالرمز، اسم الفيديو، المدينة أو المحافظة...',
      );

  String get _emptyMessage => t(
        'نتیجه‌ای پیدا نشد؛ به‌زودی این بخش تکمیل می‌شود — سپاس از همراهی‌تان با سایروس توریست 🌿',
        'No results found — coming soon. Thank you for being with Cyrus Tourist 🌿',
        'لم يتم العثور على نتائج — سيتم استكمال هذا القسم قريبًا. شكرًا لمرافقتكم سايروس توريست 🌿',
      );

  List<MovieSlotData> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.slots;
    return widget.slots.where((s) => s.searchHaystack.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            t('گالری فیلم‌های گردشگری', 'Tourism Video Gallery',
                'معرض فيديوهات السياحة'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _goldA(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: _goldA(0.8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: _hint,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        InkWell(
                          onTap: () => setState(() => _query = ''),
                          child: Icon(Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.movie_filter_rounded,
                                  size: 40, color: _goldA(0.6)),
                              const SizedBox(height: 14),
                              Text(
                                _emptyMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13.5,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 168,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) =>
                            _MovieSlotCard(data: filtered[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieSlotCard extends StatelessWidget {
  const _MovieSlotCard({required this.data});

  final MovieSlotData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        if (data.assigned) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MovieVideoPage(data: data)),
          );
        } else {
          _showAvailableSheet(context, data.code);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: data.assigned
              ? const LinearGradient(
                  colors: [_cardAlt, _card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: data.assigned ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: data.assigned ? _goldA(0.28) : _goldA(0.18),
          ),
        ),
        child: data.assigned ? _assignedContent() : _emptyContent(),
      ),
    );
  }

  Widget _codeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _brandGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#${data.code}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _assignedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _codeBadge(),
            const Icon(Icons.play_circle_fill_rounded, color: _gold, size: 20),
          ],
        ),
        const Spacer(),
        Text(
          data.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _goldBright, size: 12),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                data.displayCity,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _goldBright, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// طراحی جدید جایگاه خالی — یک نشان دایره‌ای دور آیکون + یک قاب
  /// (پیل) دور متن‌ها، به‌جای متن ساده‌ی معلق.
  Widget _emptyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(alignment: Alignment.topRight, child: _codeBadge()),
        const Spacer(),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: _goldA(0.35), width: 1.4),
          ),
          child: const Icon(Icons.add_rounded, color: _goldBright, size: 24),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                t('جای خالی', 'Available slot', 'مكان متاح'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('عضویت یک‌ساله', '1-year membership', 'عضوية لمدة سنة'),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

void _showAvailableSheet(BuildContext context, int code) {
  showModalBottomSheet(
    context: context,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _brandGradient),
                  ),
                  child: const Icon(Icons.movie_creation_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('جایگاه #$code — هنوز خالی است',
                        'Slot #$code — still available',
                        'المكان رقم $code — لا يزال متاحاً'),
                    style: const TextStyle(
                      color: _goldBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t(
                'این جایگاه هنوز به هیچ فیلمی اختصاص نیافته است. با ثبت‌نام و عضویت یک‌ساله، فیلم گردشگری شما همین‌جا با کد یکتای خودش به گردشگران معرفی می‌شود.',
                'This slot has not been assigned to any video yet. With a one-year membership, your tourism video will be introduced right here with its own unique code.',
                'لم يتم تخصيص هذا المكان بعد لأي فيديو. مع عضوية لمدة سنة، سيتم عرض فيديو السياحة الخاص بك هنا برمزه الفريد.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.9,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sheetActionButton(
                    icon: Icons.call_rounded,
                    label: t('تماس', 'Call', 'اتصال'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _openUrl(context, 'tel:09153448818');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _sheetActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Instagram',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _openUrl(
                        context,
                        'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sheetActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_teal, _tealBright]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_reg_rounded, color: Color(0xff03202a)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff03202a),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// صفحه‌ی نمایش کامل یک فیلم (جایگاه اختصاص‌یافته)
// ============================================================

class MovieVideoPage extends StatelessWidget {
  const MovieVideoPage({super.key, required this.data});

  final MovieSlotData data;

  List<String> get _benefits => [
        t('نمایش این فیلم در گالری فیلم‌های سایروس توریست',
            'Shown in the Cyrus Tourist video gallery',
            'يُعرض في معرض فيديوهات سايروس توريست'),
        t('کد یکتای اختصاصی برای جست‌وجوی سریع',
            'A dedicated unique code for quick search',
            'رمز فريد مخصص للبحث السريع'),
        t('لینک مستقیم به اینستاگرام و وب‌سایت',
            'Direct link to Instagram and website',
            'رابط مباشر لإنستغرام والموقع الإلكتروني'),
      ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            data.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _brandGradient),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#${data.code}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (data.displayCity.isNotEmpty)
                    _chip(Icons.location_on_rounded, data.displayCity),
                  if (data.displayCategory.isNotEmpty)
                    _chip(Icons.local_offer_rounded, data.displayCategory),
                ],
              ),
              const SizedBox(height: 18),
              if (data.aparatUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openUrl(context, data.aparatUrl!),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: Text(
                        t('پخش در آپارات', 'Watch on Aparat', 'مشاهدة على آپارات')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xff06121d),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text(
                t('امکانات این بخش', 'What this listing offers',
                    'مزايا هذا القسم'),
                style: const TextStyle(
                    color: _goldBright,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const SizedBox(height: 10),
              ..._benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _teal, size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(b,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _goldA(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('تماس با پشتیبانی', 'Contact support', 'التواصل مع الدعم'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _contactButton(
                          icon: Icons.call_rounded,
                          label: data.mobilePhone,
                          onTap: () =>
                              _openUrl(context, 'tel:${data.mobilePhone}'),
                        ),
                        _contactButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Instagram',
                          onTap: () => _openUrl(context, data.instagramUrl),
                        ),
                        _contactButton(
                          icon: Icons.public_rounded,
                          label: 'Website',
                          onTap: () => _openUrl(context, data.websiteUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _gold),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_teal, _tealBright]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: const Color(0xff03202a)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xff03202a),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
