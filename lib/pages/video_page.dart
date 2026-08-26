import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/app_language.dart';

const Color appBackgroundColor = Color(0xff06121d);
const Color appCardColor = Color(0xff0b2636);
const Color appGoldColor = Color(0xffffd36a);
const Color appGoldBright = Color(0xffffe39a);

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  static const String aparatChannel =
      'https://www.aparat.com/Cyrustourist';

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
      'url': 'https://www.aparat.com/v/w17sz69',
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
      'url': 'https://www.aparat.com/v/xvo5q9c',
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
      'url': 'https://www.aparat.com/v/hzlol4k',
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
      'url': 'https://www.aparat.com/v/guqcsg5',
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
      'url': 'https://www.aparat.com/v/w8lOg',
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
      'url': 'https://www.aparat.com/v/uK3y5',
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
      'url': 'https://www.aparat.com/v/nuXAC',
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
      'url': 'https://www.aparat.com/v/x707h19',
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
      'url': 'https://www.aparat.com/v/4Z0hQ',
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
      'url': 'https://www.aparat.com/v/s78jcie',
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
      'url': 'https://www.aparat.com/v/R1p3U',
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
      'url': 'https://www.aparat.com/v/g40wppg',
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
      'url': 'https://www.aparat.com/v/xsBFX',
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
      'url': 'https://www.aparat.com/v/3ZCGs',
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
      'url': 'https://www.aparat.com/v/z72q215',
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
      'url': 'https://www.aparat.com/v/c4744bv',
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
      'url': 'https://www.aparat.com/v/kGS8o',
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
      'url': 'https://www.aparat.com/v/mPh2q',
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
      'url': 'https://www.aparat.com/v/h86ieq2',
    },
    {
      'title_fa': 'زیباترین اقامتگاه بوم‌گردی در جنگل ابر',
      'title_en': 'A Beautiful Eco-Lodge in Abr Forest',
      'title_ar': 'أحد أجمل النزل البيئية في غابة أبر',
      'location_fa': 'جنگل ابر',
      'location_en': 'Abr Forest',
      'location_ar': 'غابة أبر',
      'category_fa': 'اقامتگاه',
      'category_en': 'Accommodation',
      'category_ar': 'إقامة',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/w43c127',
    },
    {
      'title_fa': 'زیباترین اقامتگاه‌های بوم‌گردی ایران',
      'title_en': 'The Most Beautiful Eco-Lodges in Iran',
      'title_ar': 'أجمل النزل البيئية في إيران',
      'location_fa': 'ایران',
      'location_en': 'Iran',
      'location_ar': 'إيران',
      'category_fa': 'اقامتگاه',
      'category_en': 'Accommodation',
      'category_ar': 'إقامة',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/k2RDX',
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
      'url': 'https://www.aparat.com/v/f91418q',
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
      'url': 'https://www.aparat.com/v/f5212r6',
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
      'url': 'https://www.aparat.com/v/f38s8gz',
    },
    {
      'title_fa': 'اقامتگاه‌ها و دیدنی‌های ایران',
      'title_en': 'Accommodation and Attractions in Iran',
      'title_ar': 'أماكن الإقامة والمعالم السياحية في إيران',
      'location_fa': 'ایران',
      'location_en': 'Iran',
      'location_ar': 'إيران',
      'category_fa': 'اقامتگاه',
      'category_en': 'Accommodation',
      'category_ar': 'إقامة',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/m37fn2a',
    },
    {
      'title_fa': 'اقامتگاه بوم‌گردی قوامیه گناباد',
      'title_en': 'Qavamieh Eco-Lodge in Gonabad',
      'title_ar': 'النزل البيئي قوامية في غناباد',
      'location_fa': 'گناباد، خراسان رضوی',
      'location_en': 'Gonabad, Razavi Khorasan',
      'location_ar': 'غناباد، خراسان الرضوية',
      'category_fa': 'بوم‌گردی',
      'category_en': 'Eco-Tourism',
      'category_ar': 'السياحة البيئية',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/a528058',
    },
    {
      'title_fa': 'اقامتگاه بوم‌گردی ناخدا علی در لافت',
      'title_en': 'Nakhoda Ali Eco-Lodge in Laft',
      'title_ar': 'النزل البيئي ناخدا علي في لافت',
      'location_fa': 'جزیره قشم، بندر لافت',
      'location_en': 'Qeshm Island, Laft Port',
      'location_ar': 'جزيرة قشم، ميناء لافت',
      'category_fa': 'بوم‌گردی',
      'category_en': 'Eco-Tourism',
      'category_ar': 'السياحة البيئية',
      'image': 'assets/images/video_accommodation.jpg',
      'url': 'https://www.aparat.com/v/hLg1q',
    },
    {
      'title_fa': 'موزه جانورشناسی؛ مجموعه‌ای کم‌نظیر از جانوران ایران',
      'title_en': 'Zoology Museum; A Remarkable Collection of Iranian Animals',
      'title_ar': 'متحف علم الحيوان؛ مجموعة مميزة من حيوانات إيران',
      'location_fa': 'ایران',
      'location_en': 'Iran',
      'location_ar': 'إيران',
      'category_fa': 'موزه و طبیعت',
      'category_en': 'Museum and Nature',
      'category_ar': 'المتحف والطبيعة',
      'image': 'assets/images/video_attraction.jpg',
      'url': 'https://www.aparat.com/Cyrustourist',
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

  String get _pageTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'فیلم‌های گردشگری';
      case AppLanguage.english:
        return 'Tourism Videos';
      case AppLanguage.arabic:
        return 'فيديوهات سياحية';
    }
  }

  String get _selectedTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'فیلم‌های منتخب گردشگری';
      case AppLanguage.english:
        return 'Selected Tourism Videos';
      case AppLanguage.arabic:
        return 'فيديوهات سياحية مختارة';
    }
  }

  String get _slogan {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'ایران را زیبا ببینید.';
      case AppLanguage.english:
        return 'Discover the beauty of Iran.';
      case AppLanguage.arabic:
        return 'اكتشفوا جمال إيران.';
    }
  }

  String get _visitText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'بازدید';
      case AppLanguage.english:
        return 'Visit';
      case AppLanguage.arabic:
        return 'زيارة';
    }
  }

  String get _leftHeaderText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'فیلم‌های اقامتی';
      case AppLanguage.english:
        return 'Accommodation Videos';
      case AppLanguage.arabic:
        return 'فيديوهات الإقامة';
    }
  }

  String get _rightHeaderText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'جاذبه‌های گردشگری';
      case AppLanguage.english:
        return 'Tourist Attractions';
      case AppLanguage.arabic:
        return 'المعالم السياحية';
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
                      Container(
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
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: appGoldColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildVideoCard(
                      selectedVideos[index],
                      index,
                    );
                  },
                  childCount: selectedVideos.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 18),
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
                onTap: () => _openUrl(aparatChannel),
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
            _AparatPlayer(
              url: video['url']!,
              onTap: () => _openUrl(video['url']!),
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
        'https://www.aparat.com/embed/$videoId'
        '?data[responsive]=yes';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(appBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
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
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onTap,
                child: const SizedBox(
                  width: 45,
                  height: 45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
