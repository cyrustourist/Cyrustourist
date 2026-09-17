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
  });

  final String id;
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
const List<Agency> approvedAgencies = [];

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
