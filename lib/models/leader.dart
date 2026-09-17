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
}

/// -------------------------------------------------------------
/// لیدرهای واقعی و تأییدشده — طبق دستور کار، فقط لیدرهایی که توسط
/// مدیریت تأیید و فعال شده‌اند اینجا نمایش داده می‌شوند.
/// هنوز لیدر تأییدشده‌ای ثبت نشده؛ به‌محض تأیید هر لیدر، یک آیتم
/// Leader دیگر به همین لیست اضافه می‌شود (دقیقاً مثل لیست گزینه‌های
/// «تور گردشگری»).
/// -------------------------------------------------------------
const List<Leader> approvedLeaders = [];

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
