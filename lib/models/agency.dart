import 'package:flutter/material.dart';

/// وضعیت آژانس — همان الگوی وضعیت لیدرها.
/// 🟢 فعال   🟡 دارای هشدار   🔴 غیرفعال   ⚪ در انتظار بررسی
enum AgencyStatus { active, warning, inactive, pending }

extension AgencyStatusX on AgencyStatus {
  Color get color {
    switch (this) {
      case AgencyStatus.active:
        return const Color(0xff2ecc71); // سبز
      case AgencyStatus.warning:
        return const Color(0xffffcc33); // زرد
      case AgencyStatus.inactive:
        return const Color(0xffe74c3c); // قرمز
      case AgencyStatus.pending:
        return const Color(0xffb0b8bf); // خاکستری
    }
  }

  String labelFa() {
    switch (this) {
      case AgencyStatus.active:
        return 'فعال';
      case AgencyStatus.warning:
        return 'دارای هشدار';
      case AgencyStatus.inactive:
        return 'غیرفعال';
      case AgencyStatus.pending:
        return 'در انتظار بررسی';
    }
  }
}

/// یک تور ارائه‌شده توسط آژانس (برای صفحه پروفایل).
class AgencyTour {
  const AgencyTour({required this.title, this.description = ''});

  final String title;
  final String description;
}

class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.city,
    required this.services,
    this.logoAsset,
    this.rating = 0,
    this.reviewCount = 0,
    this.experienceText = '',
    this.isVerifiedPartner = false,
    this.isLicensed = false,
    this.bio = '',
    this.regions = const [],
    this.phone,
    this.website,
    this.introVideoUrl,
    this.tours = const [],
    this.status = AgencyStatus.active,
    this.code = '',
  });

  final String id;

  /// کد آژانس (مثلاً AGENCY-00007) — فقط نمایش؛ از سیستم مرکزی می‌آید
  final String code;
  final String name;
  final String city;
  final String services; // مثلاً: تور خارجی، بلیط، اقامتگاه
  final String? logoAsset;
  final double rating;
  final int reviewCount;
  final String experienceText;
  final bool isVerifiedPartner;
  final bool isLicensed;
  final String bio;
  final List<String> regions;
  final String? phone;
  final String? website;
  final String? introVideoUrl;
  final List<AgencyTour> tours;
  final AgencyStatus status;
}

/// -------------------------------------------------------------
/// آژانس‌های واقعی و تأییدشده — فقط آژانس‌هایی که توسط مدیریت
/// تأیید و فعال شده‌اند اینجا نمایش داده می‌شوند.
/// هنوز آژانس تأییدشده‌ای ثبت نشده؛ به‌محض تأیید هر آژانس، یک
/// آیتم Agency دیگر به همین لیست اضافه می‌شود.
/// -------------------------------------------------------------
const List<Agency> approvedAgencies = [sampleAgency];

/// شماره‌ی آژانس در فهرست تأییدشده‌ها (از ۱)؛ ۰ یعنی در فهرست نیست.
/// همین عدد در لینک عمومی (cyrustourist.ir/agency/<عدد>) و «نمایش» استفاده می‌شود.
int agencyCodeOf(Agency agency) {
  final i = approvedAgencies.indexWhere((a) => a.id == agency.id);
  return i < 0 ? 0 : i + 1;
}

/// آژانس آزمایشی (مقادیر نمونه) — تا وقتی آژانس واقعی تأیید نشده، کلید ۸
/// خالی نماند. با تأیید اولین آژانس واقعی، این آیتم را از فهرست بردارید.
const Agency sampleAgency = Agency(
  id: 'AGENCY-00007',
  code: 'AGENCY-00007',
  name: 'آژانس پارس سفر (نمونه)',
  city: 'مشهد',
  services: 'تور داخلی و خارجی، بلیط، اقامتگاه، ترانسفر',
  rating: 4.8,
  reviewCount: 0,
  experienceText: '۱۰ سال سابقه فعالیت',
  isVerifiedPartner: true,
  isLicensed: true,
  bio: 'آژانس نمونه برای نمایش قالب کامل پروفایل آژانس در سایروس توریست؛ '
      'برگزاری تورهای گروهی و اختصاصی، رزرو اقامت و بلیط.',
  regions: ['مشهد', 'خراسان رضوی', 'مقاصد گردشگری ایران'],
  phone: '09153448818',
  website: 'https://www.cyrustourist.com',
  introVideoUrl: 'https://www.aparat.com/v/w8lOg',
  tours: [
    AgencyTour(title: 'تور یک‌روزه قنات قصبه گناباد'),
    AgencyTour(title: 'چشمه گراب و طبیعت‌گردی خراسان رضوی'),
    AgencyTour(title: 'طبیعت‌گردی آبشار شیرآباد گلستان'),
  ],
  status: AgencyStatus.active,
);

/// نمونه‌ی نمایشی پروفایل آژانس — فقط برای صفحه معرفی امکانات پنل
/// (پیش از ثبت‌نام). این یک آژانس واقعی نیست.
const Agency demoAgency = Agency(
  id: 'demo',
  name: 'نمونه: آژانس مسافرتی پارسیان سفر',
  city: 'اصفهان',
  services: 'تور داخلی و خارجی، رزرو هتل، بلیط هواپیما',
  rating: 4.7,
  reviewCount: 84,
  experienceText: '۱۲ سال سابقه فعالیت',
  isVerifiedPartner: true,
  isLicensed: true,
  bio:
      'آژانس مسافرتی با مجوز رسمی از سازمان میراث فرهنگی و گردشگری؛ '
      'برگزاری تورهای گروهی و اختصاصی داخل و خارج از کشور.',
  regions: ['اصفهان', 'یزد', 'کاشان'],
  tours: [
    AgencyTour(title: 'تور سه‌روزه اصفهان و یزد'),
    AgencyTour(title: 'تور نوروزی کاشان و باغ فین'),
  ],
  status: AgencyStatus.active,
);
