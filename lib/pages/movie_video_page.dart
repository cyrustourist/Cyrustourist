import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/app_language.dart';
import '../services/location_service.dart';
import 'movie_amenities_page.dart';
import '../services/public_link_service.dart';
import '../widgets/share_sheet.dart';

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

const List<Color> _instagramGradient = [
  Color(0xfffeda75),
  Color(0xffe1306c),
  Color(0xff833ab4),
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
//
// فیلدهای امکانات/موقعیت/توضیحات هم‌سنگ با ResidenceVideoData
// اضافه شده‌اند تا دکمه‌ی «امکانات اقامتگاه/هتل/کلبه» و توضیحات
// کامل هم برای فیلم‌ها در دسترس باشد. تا وقتی مقدار واقعی برای
// یک جایگاه وارد نشده، مقدار پیش‌فرض (خالی/false) نمایش داده
// می‌شود و بعداً به‌سادگی هر ردیف در kMovieSlots تکمیل می‌شود.

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
    this.description,
    this.descriptionEn,
    this.descriptionAr,
    this.aparatUrl,
    this.latitude,
    this.longitude,
    this.mobilePhone = '09153448818',
    this.landlinePhone = '09153448818',
    this.supportPhone = '09153448818',
    this.instagramUrl =
        'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
    this.websiteUrl = 'https://cyrustourist-maker.github.io/Cyrustourist/',
    this.hasParking = false,
    this.hasWesternToilet = false,
    this.hasIranianToilet = false,
    this.bedroomCount,
    this.hasInternet = false,
    this.hasKitchen = false,
    this.hasAc = false,
    this.hasHeating = false,
    this.hasHotWater = false,
    this.hasBreakfast = false,
    this.hasElevator = false,
    this.hasYardOrBalcony = false,
    this.isPetFriendly = false,
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

  final String? description;
  final String? descriptionEn;
  final String? descriptionAr;

  final String? aparatUrl;

  /// مختصات دستی محل فیلم — تا وقتی وارد نشده، دکمه‌ی مسیریابی
  /// به‌جای مسیر تا این محل، موقعیت فعلی کاربر را نمایش می‌دهد.
  final double? latitude;
  final double? longitude;

  final String mobilePhone;
  final String landlinePhone;
  final String supportPhone;

  final String instagramUrl;
  final String websiteUrl;

  // ---------------- امکانات محل (اقامتگاه/هتل/کلبه) ----------------
  final bool hasParking;
  final bool hasWesternToilet;
  final bool hasIranianToilet;
  final int? bedroomCount;
  final bool hasInternet;
  final bool hasKitchen;
  final bool hasAc;
  final bool hasHeating;
  final bool hasHotWater;
  final bool hasBreakfast;
  final bool hasElevator;
  final bool hasYardOrBalcony;
  final bool isPetFriendly;

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

  /// چکیده‌ی توضیحات — اگر توضیح دستی وارد نشده باشد، از دسته و شهر
  /// یک چکیده‌ی کوتاه خودکار ساخته می‌شود تا کارت/صفحه هرگز خالی نماند.
  String get displayDescription {
    final localized = t(
      description ?? '',
      descriptionEn ?? description ?? '',
      descriptionAr ?? description ?? '',
    );
    if (localized.trim().isNotEmpty) return localized;

    final city = displayCity;
    final cat = displayCategory;
    if (city.isEmpty && cat.isEmpty) return '';

    return t(
      'بخشی از مجموعه فیلم‌های گردشگری سایروس توریست'
      '${cat.isNotEmpty ? '، در دسته‌ی $cat' : ''}'
      '${city.isNotEmpty ? '، در $city' : ''}.',
      'Part of the Cyrus Tourist video collection'
      '${cat.isNotEmpty ? ', in the $cat category' : ''}'
      '${city.isNotEmpty ? ', in $city' : ''}.',
      'جزء من مجموعة فيديوهات سايروس توريست'
      '${cat.isNotEmpty ? '، في فئة $cat' : ''}'
      '${city.isNotEmpty ? '، في $city' : ''}.',
    );
  }

  /// هش ویدیوی آپارات، استخراج‌شده از aparatUrl (برای کاور و پخش امبد)
  String? get aparatHash {
    final url = aparatUrl;
    if (url == null || url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    if (segments.first == 'v' && segments.length >= 2) {
      return segments[1];
    }

    return segments.last;
  }

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
                          mainAxisExtent: 244,
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

  /// کارت جایگاه پر — کاور واقعی آپارات بالا، کد/آیکون پخش روی کاور،
  /// عنوان + شهر + یک خط چکیده‌ی توضیحات پایین کارت.
  Widget _assignedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MovieCoverThumb(hash: data.aparatHash),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _codeBadge(),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: _gold, size: 30),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                Text(
                  data.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _goldBright, size: 12),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        data.displayCity,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _goldBright, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// طراحی جدید جایگاه خالی — یک نشان دایره‌ای دور آیکون + یک قاب
  /// (پیل) دور متن‌ها، به‌جای متن ساده‌ی معلق.
  Widget _emptyContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
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
      ),
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
//
// ترتیب بخش‌ها دقیقاً طبق درخواست:
// کاور/پخش آپارات → آب‌وهوا (بر اساس موقعیت من) → فیلم‌های بیشتر
// (مثل صفحه‌ی کانال آپارات) → توضیحات (چکیده + ادامه در صفحه‌ی
// کامل) → مسیریابی (بر اساس موقعیت من) → امکانات اقامتگاه/هتل/کلبه
// → رزرو (سه شماره تماس) → اینستاگرام / وب‌سایت
// ============================================================

class MovieVideoPage extends StatefulWidget {
  const MovieVideoPage({
    super.key,
    required this.data,
    this.shareType = PublicLinkService.video,
  });

  final MovieSlotData data;

  /// نوع موجودیت برای لینک اشتراک (video / attraction / health ...)
  final String shareType;

  @override
  State<MovieVideoPage> createState() => _MovieVideoPageState();
}

class _MovieVideoPageState extends State<MovieVideoPage> {
  MovieSlotData get _d => widget.data;

  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            ShareIconButton(
              entityType: widget.shareType,
              entityId: '${_d.code}',
              title: _d.displayName,
              color: Colors.white,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _MovieCoverEmbedPlayer(
                  aparatUrl: _d.aparatUrl,
                  aparatHash: _d.aparatHash,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleBlock(),
                    const SizedBox(height: 16),


                    // آب‌وهوا — بر اساس موقعیت فعلی کاربر
                    const _MovieWeatherButton(),
                    const SizedBox(height: 18),

                    // فیلم‌های بیشتر — مثل قسمت فیلم‌های آپارات
                    _MoreVideosStrip(currentCode: _d.code),
                    const SizedBox(height: 22),

                    if (_d.displayDescription.trim().isNotEmpty) ...[
                      _descriptionBlock(),
                      const SizedBox(height: 22),
                    ] else ...[
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _shareButton(),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // مسیریابی — بر اساس موقعیت فعلی کاربر (مثل آب‌وهوا)
                    SizedBox(
                      width: double.infinity,
                      child: _gradientButton(
                        icon: Icons.map_rounded,
                        label: t('مسیریابی سریع', 'Fast route',
                            'المسار السريع'),
                        colors: const [_teal, _tealBright],
                        textColor: const Color(0xff03202a),
                        onTap: _openRoute,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // امکانات اقامتگاه/هتل/کلبه
                    SizedBox(
                      width: double.infinity,
                      child: _outlinedIconButton(
                        icon: Icons.checklist_rounded,
                        label: t('امکانات اقامتگاه/هتل/کلبه',
                            'Residence / Hotel / Cabin Amenities',
                            'مرافق الإقامة / الفندق / الكوخ'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MovieAmenitiesPage(data: _d),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // رزرو — مثل فایل نمونه، سه شماره تماس
                    SizedBox(
                      width: double.infinity,
                      child: _gradientButton(
                        icon: Icons.event_available_rounded,
                        label: t('رزرو', 'Book Now', 'الحجز'),
                        colors: const [_gold, _goldBright],
                        textColor: const Color(0xff06121d),
                        onTap: _openBookingSheet,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // اینستاگرام / وب‌سایت
                    Row(
                      children: [
                        Expanded(
                          child: _circleLinkButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Instagram',
                            gradient: _instagramGradient,
                            onTap: () => _openUrl(context, _d.instagramUrl),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _circleLinkButton(
                            icon: Icons.public_rounded,
                            label: t('وب‌سایت', 'Website', 'الموقع الإلكتروني'),
                            gradient: const [_teal, _tealBright],
                            onTap: () => _openUrl(context, _d.websiteUrl),
                          ),
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

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _d.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _brandGradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('#${_d.code}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            if (_d.displayCity.isNotEmpty)
              _chip(Icons.location_on_rounded, _d.displayCity),
            if (_d.displayCategory.isNotEmpty)
              _chip(Icons.local_offer_rounded, _d.displayCategory),
          ],
        ),
      ],
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

  Widget _shareButton() {
    return ShareButton(
      entityType: widget.shareType,
      entityId: '${_d.code}',
      title: _d.displayName,
      label: t('اشتراک‌گذاری', 'Share', 'مشاركة'),
    );
  }

  Widget _descriptionBlock() {
    final full = _d.displayDescription;
    final isLong = full.length > 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t('چکیده', 'Summary', 'ملخص'),
              style: const TextStyle(
                  color: _goldBright, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            _shareButton(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          full,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.9,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _FullDescriptionPage(
                    title: _d.displayName,
                    description: full,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.expand_more_rounded,
                      color: _gold, size: 17),
                  const SizedBox(width: 4),
                  Text(
                    t('ادامه', 'Continue', 'المزيد'),
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openRoute() async {
    HapticFeedback.selectionClick();

    // اگر برای این فیلم مختصات دستی وارد شده باشد، مسیر تا همان‌جا
    // باز می‌شود؛ در غیر این صورت — دقیقاً مثل آب‌وهوا — موقعیت
    // فعلی کاربر (هرجای ایران) روی نقشه نمایش داده می‌شود.
    if (_d.latitude != null && _d.longitude != null) {
      final url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${_d.latitude},${_d.longitude}';
      if (!mounted) return;
      await _openUrl(context, url);
      return;
    }

    final position = await LocationService.getCurrentLocation();

    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            'دسترسی به موقعیت مکانی ممکن نشد. لطفاً GPS و دسترسی موقعیت را فعال کنید.',
            'Could not access your location. Please enable GPS and location permission.',
            'تعذر الوصول إلى موقعك. يرجى تفعيل GPS وإذن الموقع.',
          )),
        ),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1'
        '&query=${position.latitude},${position.longitude}';
    if (!mounted) return;
    await _openUrl(context, url);
  }

  void _openBookingSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
              Text(
                t('📅 رزرو — یک شماره را برای تماس انتخاب کنید',
                    '📅 Booking — choose a number to call',
                    '📅 الحجز — اختر رقماً للاتصال'),
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              _contactOption(
                icon: Icons.smartphone_rounded,
                label: t('تلفن همراه', 'Mobile', 'الجوال'),
                phone: _d.mobilePhone,
              ),
              _contactOption(
                icon: Icons.phone_rounded,
                label: t('تلفن ثابت', 'Landline', 'الهاتف الأرضي'),
                phone: _d.landlinePhone,
              ),
              _contactOption(
                icon: Icons.support_agent_rounded,
                label: t('تلفن پشتیبان', 'Support line', 'خط الدعم'),
                phone: _d.supportPhone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactOption({
    required IconData icon,
    required String label,
    required String phone,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        // فقط برنامه‌ی تلفن گوشی را با شماره باز می‌کند — تماس
        // خودکار برقرار نمی‌شود. در صورت خطا همان پیام هشدار
        // استاندارد (_openUrl) نمایش داده می‌شود.
        _openUrl(context, 'tel:$phone');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff103b50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _brandGradient),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5)),
                  Text(phone,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: _goldA(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _circleLinkButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _goldA(0.22)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// صفحه‌ی توضیحات کامل — با کلید بازگشت به حالت قبل
// ============================================================

class _FullDescriptionPage extends StatelessWidget {
  const _FullDescriptionPage({required this.title, required this.description});

  final String title;
  final String description;

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
            t('توضیحات کامل', 'Full Description', 'الوصف الكامل'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 2.0,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    t('بازگشت', 'Back', 'رجوع'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldBright,
                    side: BorderSide(color: _goldA(0.6)),
                    backgroundColor: _goldA(0.06),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// دکمه/آب‌وهوا — بر اساس موقعیت فعلی کاربر (GPS)، نه شهر فیلم.
// فعلاً تا وقتی مختصات دستی هر فیلم وارد نشده، همین روش استفاده
// می‌شود؛ ساختار کاملاً مثل _ResidenceWeatherButton است.
// ============================================================

class _MovieWeatherButton extends StatefulWidget {
  const _MovieWeatherButton();

  @override
  State<_MovieWeatherButton> createState() => _MovieWeatherButtonState();
}

class _MovieWeatherButtonState extends State<_MovieWeatherButton> {
  bool _expanded = false;
  bool _loading = false;
  bool _failed = false;
  bool _loaded = false;
  bool _permissionDenied = false;

  double? _temperature;
  int? _weatherCode;
  int? _humidity;
  double? _windSpeed;

  void _toggle() {
    HapticFeedback.selectionClick();

    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _expanded = true);

    if (!_loaded) _loadWeather();
  }

  void _retry() {
    setState(() {
      _loaded = false;
      _failed = false;
      _permissionDenied = false;
    });
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
          _permissionDenied = true;
          _loaded = true;
        });
        return;
      }

      final weather =
          await _fetchWeather(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loaded = true;
        _failed = weather == null;
        _temperature = (weather?['temperature'] as num?)?.toDouble();
        _weatherCode = (weather?['weathercode'] as num?)?.toInt();
        _humidity = (weather?['humidity'] as num?)?.toInt();
        _windSpeed = (weather?['windspeed'] as num?)?.toDouble();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _loaded = true;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchWeather(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;

      if (current == null) return null;

      return {
        'temperature': current['temperature_2m'],
        'weathercode': current['weather_code'],
        'humidity': current['relative_humidity_2m'],
        'windspeed': current['wind_speed_10m'],
      };
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _weatherEmoji(int? code) {
    if (code == null) return '🌡️';
    if (code == 0) return '☀️';
    if (code == 1 || code == 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 57) return '🌦️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '🌨️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code == 85 || code == 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }

  String _weatherLabel(int? code) {
    if (code == null) return t('نامشخص', 'Unknown', 'غير معروف');
    if (code == 0) return t('صاف', 'Clear', 'صافٍ');
    if (code == 1) return t('کمی ابری', 'Mostly clear', 'صافٍ جزئياً');
    if (code == 2) return t('نیمه‌ابری', 'Partly cloudy', 'غائم جزئياً');
    if (code == 3) return t('ابری', 'Cloudy', 'غائم');
    if (code == 45 || code == 48) return t('مه‌آلود', 'Foggy', 'ضبابي');
    if (code >= 51 && code <= 57) return t('نم‌نم باران', 'Drizzle', 'رذاذ');
    if (code >= 61 && code <= 67) return t('بارانی', 'Rainy', 'ممطر');
    if (code >= 71 && code <= 77) return t('برفی', 'Snowy', 'مثلج');
    if (code >= 80 && code <= 82) return t('رگبار', 'Showers', 'زخات');
    if (code == 85 || code == 86) {
      return t('رگبار برف', 'Snow showers', 'زخات ثلجية');
    }
    if (code >= 95) return t('رعدوبرق', 'Thunderstorm', 'عاصفة رعدية');
    return t('نامشخص', 'Unknown', 'غير معروف');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff103b50), Color(0xff0d2432)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldA(0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: _goldBright, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('آب‌وهوای موقعیت من', 'Weather at my location',
                          'طقس موقعي'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (_loaded && !_failed && _temperature != null) ...[
                    Text(_weatherEmoji(_weatherCode),
                        style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 4),
                    Text(
                      '${_temperature!.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _gold),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _weatherBody(),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _weatherBody() {
    if (_loading) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _gold),
          ),
          const SizedBox(width: 10),
          Text(
            t('در حال دریافت موقعیت و آب‌وهوا…', 'Fetching location and weather…',
                'جارٍ جلب الموقع وحالة الطقس…'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    if (_failed) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _permissionDenied
                  ? t('دسترسی به موقعیت مکانی فعال نیست.',
                      'Location access is not enabled.',
                      'الوصول إلى الموقع غير مفعل.')
                  : t('دریافت آب‌وهوا ممکن نشد.', 'Could not fetch weather.',
                      'تعذر جلب حالة الطقس.'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _retry,
            child: Text(t('تلاش دوباره', 'Retry', 'إعادة المحاولة'),
                style: const TextStyle(color: _gold)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _weatherLabel(_weatherCode),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        if (_humidity != null)
          Text('💧 $_humidity٪',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        if (_windSpeed != null) ...[
          const SizedBox(width: 10),
          Text('🌬️ ${_windSpeed!.round()} km/h',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        ],
      ],
    );
  }
}

// ============================================================
// نوار «فیلم‌های بیشتر» — قالب افقی مثل قسمت فیلم‌های کانال آپارات
// ============================================================

class _MoreVideosStrip extends StatelessWidget {
  const _MoreVideosStrip({required this.currentCode});

  final int currentCode;

  @override
  Widget build(BuildContext context) {
    final others = kMovieSlots
        .where((s) => s.assigned && s.code != currentCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.video_library_rounded,
                color: _goldBright, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('فیلم‌های بیشتر از آپارات', 'More videos from Aparat',
                    'المزيد من فيديوهات آپارات'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _goldA(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _goldA(0.3)),
              ),
              child: Text(
                t('${others.length} فیلم', '${others.length} videos',
                    '${others.length} فيديو'),
                style: const TextStyle(
                  color: _goldBright,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final movie = others[index];
              return _MoreVideoTile(data: movie);
            },
          ),
        ),
      ],
    );
  }
}

class _MoreVideoTile extends StatelessWidget {
  const _MoreVideoTile({required this.data});

  final MovieSlotData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MovieVideoPage(data: data)),
        );
      },
      child: Container(
        width: 118,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldA(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MovieCoverThumb(hash: data.aparatHash),
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: _gold, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                data.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
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

  static Future<_AparatVideoInfo?> fetchInfo(String videoHash) async {
    if (_cache.containsKey(videoHash)) {
      return _cache[videoHash];
    }

    HttpClient? client;

    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(
        Uri.parse('https://www.aparat.com/etc/api/video/videohash/$videoHash'),
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

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final video =
          decoded is Map ? decoded['video'] as Map<String, dynamic>? : null;

      if (video == null) {
        _cache[videoHash] = null;
        return null;
      }

      final info = _AparatVideoInfo(
        title: video['title']?.toString(),
        coverUrl:
            video['big_poster'] as String? ?? video['small_poster'] as String?,
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

/// تصویر کوچک کاور — برای کارت‌های گالری و نوار «فیلم‌های بیشتر»
class _MovieCoverThumb extends StatefulWidget {
  const _MovieCoverThumb({required this.hash});

  final String? hash;

  @override
  State<_MovieCoverThumb> createState() => _MovieCoverThumbState();
}

class _MovieCoverThumbState extends State<_MovieCoverThumb> {
  _AparatVideoInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MovieCoverThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hash != widget.hash) _load();
  }

  Future<void> _load() async {
    final hash = widget.hash;
    if (hash == null || hash.isEmpty) return;

    final info = await _AparatCoverLoader.fetchInfo(hash);
    if (!mounted || info == null) return;
    setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _info?.coverUrl;

    if (coverUrl == null) {
      return Image.asset(
        'assets/images/showcase-hub.jpg',
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Image.asset(
          'assets/images/showcase-hub.jpg',
          fit: BoxFit.cover,
        );
      },
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/showcase-hub.jpg',
        fit: BoxFit.cover,
      ),
    );
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
// پخش‌کننده‌ی بالای صفحه‌ی فیلم — حالت اول کاور واقعی آپارات با
// مدت‌زمان/بازدید، با لمس کاور → پخش‌کننده‌ی امبد واقعی آپارات
// (دقیقاً هم‌خانواده‌ی _VideoCoverPlayer در video_page.dart)
// ============================================================

class _MovieCoverEmbedPlayer extends StatefulWidget {
  const _MovieCoverEmbedPlayer({
    required this.aparatUrl,
    required this.aparatHash,
  });

  final String? aparatUrl;
  final String? aparatHash;

  @override
  State<_MovieCoverEmbedPlayer> createState() =>
      _MovieCoverEmbedPlayerState();
}

class _MovieCoverEmbedPlayerState extends State<_MovieCoverEmbedPlayer> {
  _AparatVideoInfo? _info;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final hash = widget.aparatHash;
    if (hash == null || hash.isEmpty) return;

    final info = await _AparatCoverLoader.fetchInfo(hash);
    if (!mounted || info == null) return;
    setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aparatHash == null || widget.aparatHash!.isEmpty) {
      return Container(
        color: _bg,
        alignment: Alignment.center,
        child: Icon(Icons.movie_filter_rounded,
            color: _goldA(0.5), size: 40),
      );
    }

    return _playing
        ? _MovieAparatWebPlayer(aparatHash: widget.aparatHash!)
        : _buildCover();
  }

  Widget _buildCover() {
    final duration = _formatDuration(_info?.duration);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _playing = true);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _MovieCoverThumb(hash: widget.aparatHash),
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
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.94),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: _bg, size: 38),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ondemand_video_rounded,
                      color: _gold, size: 13),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded,
                        color: _gold, size: 13),
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

class _MovieAparatWebPlayer extends StatefulWidget {
  const _MovieAparatWebPlayer({required this.aparatHash});

  final String aparatHash;

  @override
  State<_MovieAparatWebPlayer> createState() => _MovieAparatWebPlayerState();
}

class _MovieAparatWebPlayerState extends State<_MovieAparatWebPlayer> {
  late WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.aparatHash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
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
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: _gold),
          ),
        if (_failed)
          Container(
            color: _bg,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _gold, size: 30),
                const SizedBox(height: 8),
                Text(
                  t('پخش ویدیو بارگذاری نشد', 'Video failed to load',
                      'تعذر تحميل الفيديو'),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() { _failed = false; _loading = true; });
                    _controller.reload();
                  },
                  child: Text(t('تلاش دوباره', 'Retry', 'إعادة المحاولة')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
