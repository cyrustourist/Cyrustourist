import 'package:flutter/material.dart';

/// وضعیت لیدر — طبق دستور کار «لیدرهای گردشگری».
/// 🟢 فعال   🟡 دارای هشدار   🔴 غیرفعال   ⚪ در انتظار بررسی
enum LeaderStatus { active, warning, inactive, pending }

extension LeaderStatusX on LeaderStatus {
  Color get color {
    switch (this) {
      case LeaderStatus.active:
        return const Color(0xff2ecc71); // سبز
      case LeaderStatus.warning:
        return const Color(0xffffcc33); // زرد
      case LeaderStatus.inactive:
        return const Color(0xffe74c3c); // قرمز
      case LeaderStatus.pending:
        return const Color(0xffb0b8bf); // خاکستری
    }
  }

  String labelFa() {
    switch (this) {
      case LeaderStatus.active:
        return 'فعال';
      case LeaderStatus.warning:
        return 'دارای هشدار';
      case LeaderStatus.inactive:
        return 'غیرفعال';
      case LeaderStatus.pending:
        return 'در انتظار بررسی';
    }
  }

  String messageFa() {
    switch (this) {
      case LeaderStatus.active:
        return 'حساب شما فعال است و پروفایل شما در CYRUS TOURIST برای کاربران قابل نمایش است.';
      case LeaderStatus.warning:
        return 'یک مورد در حساب شما نیازمند توجه و پیگیری است. لطفاً توضیحات را بررسی کرده و در صورت نیاز با پشتیبانی CYRUS TOURIST هماهنگ کنید.';
      case LeaderStatus.inactive:
        return 'وضعیت حساب: غیرفعال\n\nدر حال حاضر نمایش عمومی پروفایل و امکانات تبلیغاتی شما غیرفعال شده است.\n\nبرای اطلاع از علت غیرفعال شدن حساب و بررسی وضعیت آن، لطفاً با پشتیبانی CYRUS TOURIST تماس بگیرید.\n\nاطلاعات و سوابق حساب شما در سامانه حذف نشده و تا زمان تعیین تکلیف نگهداری خواهد شد.';
      case LeaderStatus.pending:
        return 'درخواست شما در صف بررسی مدیریت CYRUS TOURIST قرار دارد.';
    }
  }
}

/// یک تور ارائه‌شده توسط لیدر (برای صفحه پروفایل).
class LeaderTour {
  const LeaderTour({required this.title, this.description = ''});

  final String title;
  final String description;
}

/// یک ردیف از «مشخصات کامل» لیدر: ایموجی + عنوان + مقدار.
class LeaderField {
  const LeaderField(this.emoji, this.label, this.value);

  final String emoji;
  final String label;
  final String value;
}

/// یک خدمت لیدر (تور شهری، ترانسفر، ...) و اینکه قابل ارائه است یا نه.
class LeaderService {
  const LeaderService(this.emoji, this.title, {this.available = true});

  final String emoji;
  final String title;
  final bool available;
}

class Leader {
  const Leader({
    required this.id,
    required this.name,
    required this.city,
    required this.specialty,
    this.photoAsset,
    this.rating = 0,
    this.reviewCount = 0,
    this.experienceText = '',
    this.isLocalLeader = false,
    this.isLicensed = false,
    this.bio = '',
    this.regions = const [],
    this.languages = const [],
    this.introVideoUrl,
    this.tours = const [],
    this.status = LeaderStatus.active,
    this.code = '',
    this.title = '',
    this.mobile,
    this.landline,
    this.email,
    this.website,
    this.instagram,
    this.aparatChannel,
    this.aparatHash,
    this.services = const [],
    this.fields = const [],
  });

  final String id;
  final String name;
  final String city;
  final String specialty;
  final String? photoAsset;
  final double rating;
  final int reviewCount;
  final String experienceText;
  final bool isLocalLeader;
  final bool isLicensed;
  final String bio;
  final List<String> regions;
  final List<String> languages;
  final String? introVideoUrl;
  final List<LeaderTour> tours;
  final LeaderStatus status;

  /// کد لیدر (مثلاً GUIDE-00001) و عنوان حرفه‌ای
  final String code;
  final String title;

  /// راه‌های ارتباطی — فقط مقدارهای واقعی؛ نمونه‌های ناقص (XXX) اینجا نیایند.
  final String? mobile;
  final String? landline;
  final String? email;
  final String? website;
  final String? instagram;
  final String? aparatChannel;

  /// هش ویدیوی آپارات برای پخش داخل صفحه‌ی پروفایل (مثلاً xvo5q9c)
  final String? aparatHash;

  final List<LeaderService> services;

  /// جدول «مشخصات کامل» (به ترتیب نمایش)
  final List<LeaderField> fields;
}

/// شماره‌ی لیدر در فهرست تأییدشده‌ها (از ۱). اگر در فهرست نباشد (مثلاً
/// نمونه‌ی معرفی) صفر برمی‌گرداند. همین عدد کد آیتم «نمایش» و کلید
/// علاقه‌مندی است، پس قلب پروفایل و قلب گالری یکی می‌شوند.
int leaderCodeOf(Leader leader) {
  final i = approvedLeaders.indexWhere((l) => l.id == leader.id);
  return i < 0 ? 0 : i + 1;
}


/// -------------------------------------------------------------
/// لیدر آزمایشی (مقادیر نمونه) — برای دیدن قالب کامل پروفایل و تست
/// قلب علاقه‌مندی/ویدئو. وقتی لیدر واقعی تأیید شد، این آیتم را از
/// فهرست approvedLeaders بردارید.
/// -------------------------------------------------------------
const Leader sampleLeader = Leader(
  id: 'GUIDE-00001',
  code: 'GUIDE-00001',
  name: 'مهندس تیرانداز',
  title: 'لیدر و راهنمای گردشگری',
  city: 'مشهد',
  specialty: 'فرهنگی، تاریخی، زیارتی، طبیعت‌گردی',
  rating: 5.0,
  reviewCount: 0,
  experienceText: '۱۰ سال تجربه در ایران',
  isLocalLeader: true,
  isLicensed: true,
  bio: 'لیدر و راهنمای گردشگری با ۱۰ سال تجربه در ایران. '
      'محدوده فعالیت: مشهد و مقاصد گردشگری ایران.',
  regions: ['مشهد', 'مقاصد گردشگری ایران'],
  languages: ['فارسی', 'انگلیسی'],
  introVideoUrl: 'https://www.aparat.com/v/xvo5q9c',
  aparatHash: 'xvo5q9c',
  mobile: '09153448818',
  email: 'guide@example.com',
  website: 'https://www.cyrustourist.com',
  instagram: 'https://www.instagram.com/cyrustourist',
  aparatChannel: 'https://www.aparat.com/cyrustourist',
  status: LeaderStatus.active,
  tours: [
    LeaderTour(title: 'تور شهری'),
    LeaderTour(title: 'تور تاریخی'),
    LeaderTour(title: 'تور زیارتی'),
    LeaderTour(title: 'طبیعت‌گردی'),
  ],
  services: [
    LeaderService('🧭', 'تور شهری'),
    LeaderService('🏛️', 'تور تاریخی'),
    LeaderService('🕌', 'تور زیارتی'),
    LeaderService('🌳', 'طبیعت‌گردی'),
    LeaderService('👨‍👩‍👧‍👦', 'تور خانوادگی'),
    LeaderService('🌍', 'تور خارجی'),
    LeaderService('✈️', 'استقبال فرودگاهی'),
    LeaderService('🚗', 'ترانسفر'),
    LeaderService('🗓️', 'برنامه‌ریزی سفر'),
    LeaderService('🗣️', 'مترجم همراه'),
    LeaderService('👴', 'همراهی سالمندان'),
  ],
  fields: [
    LeaderField('👤', 'نام و نام خانوادگی', 'مهندس تیرانداز'),
    LeaderField('🪪', 'کد لیدر', 'GUIDE-00001'),
    LeaderField('🎯', 'عنوان', 'لیدر و راهنمای گردشگری'),
    LeaderField('⭐', 'سابقه فعالیت', '۱۰ سال تجربه در ایران'),
    LeaderField('🌍', 'کشور', 'ایران'),
    LeaderField('📍', 'شهر', 'مشهد'),
    LeaderField('🗺️', 'محدوده فعالیت', 'مشهد و مقاصد گردشگری ایران'),
    LeaderField('🗣️', 'زبان‌های مسلط', 'فارسی، انگلیسی'),
    LeaderField('🎓', 'تخصص', 'فرهنگی، تاریخی، زیارتی، طبیعت‌گردی'),
    LeaderField('🪪', 'نوع مجوز', 'راهنمای گردشگری'),
    LeaderField('🔢', 'شماره مجوز', 'قابل ثبت'),
    LeaderField('🟢', 'وضعیت فعالیت', 'فعال'),
    LeaderField('🛡️', 'وضعیت تأیید', 'تأیید شده'),
    LeaderField('🏠', 'تلفن ثابت', '051-XXXXXXX'),
    LeaderField('📱', 'تلفن همراه', '09153448818'),
    LeaderField('📞', 'شماره کمکی', '09XXXXXXXXX'),
    LeaderField('📧', 'ایمیل', 'guide@example.com'),
    LeaderField('🌐', 'وب‌سایت', 'https://www.cyrustourist.com'),
    LeaderField('📸', 'اینستاگرام', 'https://www.instagram.com/cyrustourist'),
    LeaderField('▶️', 'آپارات', 'https://www.aparat.com/cyrustourist'),
    LeaderField('🎥', 'ویدئوی معرفی', 'https://www.aparat.com/v/xvo5q9c'),
    LeaderField('📸', 'گالری تصاویر', 'قابل ثبت'),
    LeaderField('📍', 'موقعیت روی نقشه', 'مشهد، ایران'),
    LeaderField('👥', 'ظرفیت گروه', '۱ تا ۳۰ نفر'),
    LeaderField('📅', 'زمان فعالیت', 'طبق برنامه و هماهنگی'),
    LeaderField('💰', 'نوع قیمت‌گذاری', 'ساعتی / روزانه / تور کامل'),
    LeaderField('🧭', 'تور شهری', 'قابل ارائه'),
    LeaderField('🏛️', 'تور تاریخی', 'قابل ارائه'),
    LeaderField('🕌', 'تور زیارتی', 'قابل ارائه'),
    LeaderField('🌳', 'طبیعت‌گردی', 'قابل ارائه'),
    LeaderField('👨‍👩‍👧‍👦', 'تور خانوادگی', 'قابل ارائه'),
    LeaderField('🌍', 'تور خارجی', 'قابل ارائه'),
    LeaderField('✈️', 'استقبال فرودگاهی', 'قابل ارائه'),
    LeaderField('🚗', 'ترانسفر', 'قابل ارائه'),
    LeaderField('🗓️', 'برنامه‌ریزی سفر', 'قابل ارائه'),
    LeaderField('🗣️', 'مترجم همراه', 'قابل ارائه'),
    LeaderField('👴', 'همراهی سالمندان', 'قابل ارائه'),
    LeaderField('⭐', 'امتیاز', '5.0 از 5 - آزمایشی'),
    LeaderField('💬', 'نظرات مسافران', 'قابل ثبت'),
    LeaderField('❤️', 'برگزیده‌ها', 'افزودن به برگزیده‌ها'),
    LeaderField('📞', 'تماس با لیدر', 'تماس مستقیم'),
    LeaderField('🎥', 'ویدئوهای بیشتر', 'امکان ثبت چند ویدئو'),
    LeaderField('🏅', 'مدارک و گواهینامه‌ها', 'قابل ثبت'),
    LeaderField('📢', 'معرفی ویژه', 'بله / خیر'),
    LeaderField('📝', 'توضیحات تکمیلی', 'قابل ثبت'),
    LeaderField('🔐', 'وضعیت حساب', 'فعال'),
    LeaderField('📅', 'تاریخ عضویت', 'قابل ثبت'),
    LeaderField('🔄', 'آخرین بروزرسانی', 'قابل ثبت'),
  ],
);

/// -------------------------------------------------------------
/// لیدرهای واقعی و تأییدشده — طبق دستور کار، فقط لیدرهایی که توسط
/// مدیریت تأیید و فعال شده‌اند اینجا نمایش داده می‌شوند.
/// هنوز لیدر تأییدشده‌ای ثبت نشده؛ به‌محض تأیید هر لیدر، یک آیتم
/// Leader دیگر به همین لیست اضافه می‌شود (دقیقاً مثل لیست گزینه‌های
/// «تور گردشگری»).
/// -------------------------------------------------------------
const List<Leader> approvedLeaders = [sampleLeader];

/// نمونه‌ی نمایشی پروفایل لیدر — فقط برای صفحه معرفی امکانات پنل
/// (پیش از ثبت‌نام)، مطابق بند ۶ دستور کار. این یک لیدر واقعی نیست.
const Leader demoLeader = Leader(
  id: 'demo',
  name: 'نمونه: سارا احمدی',
  city: 'شیراز',
  specialty: 'میراث تاریخی و فرهنگی',
  rating: 4.8,
  reviewCount: 126,
  experienceText: '۶ سال سابقه راهنمایی گردشگران',
  isLocalLeader: true,
  isLicensed: true,
  bio:
      'راهنمای محلی شیراز با تمرکز بر تخت‌جمشید، حافظیه و بازارهای سنتی؛ '
      'همراهی گروه‌های کوچک و خانوادگی به فارسی و انگلیسی.',
  regions: ['شیراز', 'مرودشت', 'تخت‌جمشید'],
  languages: ['فارسی', 'انگلیسی'],
  tours: [
    LeaderTour(title: 'یک‌روزه تخت‌جمشید و نقش رستم'),
    LeaderTour(title: 'گشت شبانه بازار وکیل و حافظیه'),
  ],
  status: LeaderStatus.active,
);
