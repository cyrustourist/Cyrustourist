import 'package:flutter/material.dart';

import '../core/network/api_service.dart';
import 'agency.dart';
import 'leader.dart';

/// ===============================================================
/// کلید ۸ — تور گردشگری: مدل‌ها، ۲۵ دسته در ۵ گروه، نمونه‌ی داخلی و
/// Repository (API ← نمونه).
///
/// اصل دستورکار: UI مستقیم به API وابسته نیست؛ همه‌چیز از
/// [TourRepository] می‌آید. اگر API جواب معتبر نداد، نمونه‌ی داخلی
/// نمایش داده می‌شود (فقط Fallback/Demo، نه جایگزین دیتابیس).
/// ===============================================================

class TourCategory {
  const TourCategory(this.id, this.emoji, this.title);

  final int id;
  final String emoji;
  final String title;
}

class TourGroup {
  const TourGroup(this.title, this.emoji, this.color, this.categories);

  final String title;
  final String emoji;
  final Color color;
  final List<TourCategory> categories;
}

/// ۲۵ دسته در ۵ گروه (ترتیب شماره‌ها مطابق دستورکار حفظ شده)
const List<TourGroup> kTourGroups = [
  TourGroup('مقصد و طبیعت', '🗺️', Color(0xff29e0ad), [
    TourCategory(1, '🏙️', 'تور شهری'),
    TourCategory(2, '🏛️', 'تور تاریخی و فرهنگی'),
    TourCategory(3, '🌿', 'تور طبیعت‌گردی'),
    TourCategory(5, '🏖️', 'تور ساحلی و دریایی'),
    TourCategory(6, '⛰️', 'تور کوهستانی'),
    TourCategory(7, '🏜️', 'تور کویر و صحرا'),
    TourCategory(8, '🌲', 'تور جنگلی'),
  ]),
  TourGroup('ماجراجویی و تفریح', '🎯', Color(0xffffb84d), [
    TourCategory(4, '🧗', 'تور ماجراجویانه'),
    TourCategory(17, '⚽', 'تور ورزشی'),
    TourCategory(18, '🎡', 'تور تفریحی'),
    TourCategory(19, '🌙', 'تور شبانه'),
    TourCategory(13, '📷', 'تور عکاسی'),
  ]),
  TourGroup('موضوعی', '🧭', Color(0xffa78bfa), [
    TourCategory(9, '🕌', 'تور زیارتی'),
    TourCategory(12, '🎓', 'تور آموزشی'),
    TourCategory(14, '🍽️', 'تور غذایی و شکم‌گردی'),
    TourCategory(15, '🛍️', 'تور خرید و بازارگردی'),
    TourCategory(16, '🏥', 'تور سلامت و پزشکی'),
  ]),
  TourGroup('مخاطب و نوع گروه', '👥', Color(0xff60a5fa), [
    TourCategory(10, '👨‍👩‍👧', 'تور خانوادگی'),
    TourCategory(11, '🧒', 'تور کودک و نوجوان'),
    TourCategory(22, '👥', 'تور گروهی'),
    TourCategory(23, '🔒', 'تور خصوصی'),
  ]),
  TourGroup('قیمت و مدت', '💎', Color(0xfff472b6), [
    TourCategory(20, '👑', 'تور ویژه و VIP'),
    TourCategory(21, '💰', 'تور اقتصادی'),
    TourCategory(24, '☀️', 'تور یک‌روزه'),
    TourCategory(25, '🗓️', 'تور چندروزه'),
  ]),
];

TourCategory? tourCategoryById(int id) {
  for (final g in kTourGroups) {
    for (final c in g.categories) {
      if (c.id == id) return c;
    }
  }
  return null;
}

/// رنگ گروهِ یک دسته (برای کارت‌ها)
Color tourGroupColorOf(int categoryId) {
  for (final g in kTourGroups) {
    for (final c in g.categories) {
      if (c.id == categoryId) return g.color;
    }
  }
  return const Color(0xffffd36a);
}

class Tour {
  const Tour({
    required this.id,
    required this.code,
    required this.title,
    required this.categoryIds,
    this.description = '',
    this.destination = '',
    this.city = '',
    this.startDate = '',
    this.endDate = '',
    this.duration = '',
    this.capacity = '',
    this.remaining = '',
    this.price = '',
    this.transport = '',
    this.accommodation = '',
    this.meals = '',
    this.rules = '',
    this.services = const [],
    this.aparatHash,
    this.leader,
    this.agency,
    this.agencyName,
    this.agencyCode,
    this.agencyCity,
    this.agencyRating,
    this.featured = false,
    this.vip = false,
    this.reservationEnabled = false,
    this.shareEnabled = true,
  });

  /// شناسه‌ی داخلی پایدار (مبنای لینک عمومی) — نه کد مدیریتی
  final int id;

  /// کد مدیریتی (مثلاً TOUR-000076) — فقط نمایش؛ Android آن را نمی‌سازد
  final String code;
  final String title;
  final List<int> categoryIds;
  final String description;
  final String destination;
  final String city;
  final String startDate;
  final String endDate;
  final String duration;
  final String capacity;
  final String remaining;
  final String price;
  final String transport;
  final String accommodation;
  final String meals;
  final String rules;
  final List<String> services;

  /// هش ویدیوی آپارات (Embed). فایل ویدئو داخل APK نیست.
  final String? aparatHash;

  /// ارائه‌دهندگان: اول لیدر، بعد آژانس
  final Leader? leader;

  /// آژانس کامل (نمونه‌ی داخلی)؛ برای تورهای API فقط نام/کد/شهر می‌آید
  final Agency? agency;
  final String? agencyName;
  final String? agencyCode;
  final String? agencyCity;
  final double? agencyRating;

  /// وضعیت‌ها فقط از API/نمونه می‌آیند؛ Android خودش تصمیم نمی‌گیرد.
  final bool featured;
  final bool vip;
  final bool reservationEnabled;
  final bool shareEnabled;

  bool get hasVideo => aparatHash != null && aparatHash!.isNotEmpty;

  String get categoryLabel {
    if (categoryIds.isEmpty) return '';
    return tourCategoryById(categoryIds.first)?.title ?? '';
  }

  /// پارس ایمن از JSON سرور (فیلدهای ناموجود = مقدار خالی، بدون خطا)
  factory Tour.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => v == null ? '' : '$v'.trim();
    final cats = <int>[];
    final rawCats = j['category_ids'] ?? j['categories'];
    if (rawCats is List) {
      for (final c in rawCats) {
        final n = int.tryParse('$c');
        if (n != null) cats.add(n);
      }
    }
    final hash = s(j['aparat_hash'] ?? j['video_hash']);
    return Tour(
      id: int.tryParse(s(j['id'])) ?? 0,
      code: s(j['code']),
      title: s(j['title'] ?? j['name']),
      categoryIds: cats,
      description: s(j['description']),
      destination: s(j['destination']),
      city: s(j['city']),
      startDate: s(j['start_date']),
      endDate: s(j['end_date']),
      duration: s(j['duration']),
      capacity: s(j['capacity']),
      remaining: s(j['remaining']),
      price: s(j['price']),
      transport: s(j['transport']),
      accommodation: s(j['accommodation']),
      meals: s(j['meals']),
      rules: s(j['rules']),
      services: [
        if (j['services'] is List)
          for (final x in (j['services'] as List))
            if (s(x).isNotEmpty) s(x),
      ],
      aparatHash: hash.isEmpty ? null : hash,
      agencyName: s(j['agency_name']).isEmpty ? null : s(j['agency_name']),
      agencyCode: s(j['agency_code']).isEmpty ? null : s(j['agency_code']),
      agencyCity: s(j['agency_city']).isEmpty ? null : s(j['agency_city']),
      featured: j['featured'] == true,
      vip: j['vip'] == true,
      reservationEnabled: j['reservation_enabled'] == true,
      shareEnabled: j['share_enabled'] != false,
    );
  }
}

// ===============================================================
// نمونه‌ی داخلی (Fallback / Demo) — فیلم‌ها همان فیلم‌های موجود برنامه‌اند
// ===============================================================

const List<Tour> sampleTours = [
  Tour(
    id: 76,
    code: 'TOUR-000076',
    title: 'بازدید یک‌روزه از قنات قصبه گناباد',
    categoryIds: [24, 2],
    description: 'بازدید از قنات قصبه گناباد، یکی از شگفتی‌های تاریخ تمدن بشر، '
        'همراه با توضیحات لیدر و زمان کافی برای عکاسی.',
    destination: 'گناباد',
    city: 'گناباد، خراسان رضوی',
    startDate: '۱۲ مهر ۱۴۰۵',
    endDate: '۱۲ مهر ۱۴۰۵',
    duration: '۱ روز',
    capacity: '۳۰ نفر',
    remaining: '۱۸ نفر',
    price: '۱٬۲۰۰٬۰۰۰ تومان',
    transport: 'ون ۱۸ نفره — رفت و برگشت',
    accommodation: 'ندارد (تور یک‌روزه)',
    meals: 'ناهار',
    rules: 'لغو تا ۴۸ ساعت قبل بدون جریمه',
    services: ['حمل‌ونقل', 'لیدر', 'ناهار', 'بیمه'],
    aparatHash: 't346o2k',
    leader: sampleLeader,
    agency: sampleAgency,
    featured: true,
    vip: true,
    reservationEnabled: true,
  ),
  Tour(
    id: 77,
    code: 'TOUR-000077',
    title: 'چشمه گراب و طبیعت‌گردی خراسان رضوی',
    categoryIds: [3, 24],
    description: 'طبیعت‌گردی در چشمه گراب و اطراف آن؛ مناسب خانواده و دوستان.',
    destination: 'چشمه گراب',
    city: 'خراسان رضوی',
    startDate: '۲۰ مهر ۱۴۰۵',
    endDate: '۲۰ مهر ۱۴۰۵',
    duration: '۱ روز',
    capacity: '۱۵ نفر',
    remaining: '۹ نفر',
    price: '۹۵۰٬۰۰۰ تومان',
    transport: 'مینی‌بوس — رفت و برگشت',
    accommodation: 'ندارد (تور یک‌روزه)',
    meals: 'ناهار در طبیعت',
    rules: 'همراه داشتن کفش مناسب پیاده‌روی',
    services: ['حمل‌ونقل', 'لیدر', 'ناهار'],
    aparatHash: 'xvo5q9c',
    leader: sampleLeader,
    agency: sampleAgency,
    featured: true,
    reservationEnabled: true,
  ),
  Tour(
    id: 78,
    code: 'TOUR-000078',
    title: 'بازدید از نمایشگاه سایروس توریست',
    categoryIds: [18, 1],
    description: 'بازدید از نمایشگاه سایروس توریست و آشنایی با خدمات و '
        'مقصدهای گردشگری ایران.',
    destination: 'نمایشگاه سایروس توریست',
    city: 'مشهد',
    startDate: 'طبق برنامه و هماهنگی',
    duration: 'نیم‌روز',
    capacity: '۵۰ نفر',
    price: 'رایگان',
    services: ['راهنما'],
    // ویدیوی نمایشگاه: هش آپارات را بعداً بگذارید (aparatHash)
    leader: sampleLeader,
    reservationEnabled: false,
  ),
  Tour(
    id: 79,
    code: 'TOUR-000079',
    title: 'طبیعت‌گردی آبشار شیرآباد گلستان',
    categoryIds: [3, 8, 25],
    description: 'سه روز طبیعت‌گردی در جنگل‌های گلستان و آبشار شیرآباد.',
    destination: 'آبشار شیرآباد',
    city: 'گلستان',
    startDate: '۵ آبان ۱۴۰۵',
    endDate: '۷ آبان ۱۴۰۵',
    duration: '۳ روز',
    capacity: '۲۵ نفر',
    remaining: '۳ نفر',
    price: '۵٬۱۰۰٬۰۰۰ تومان',
    transport: 'اتوبوس VIP',
    accommodation: 'اقامتگاه بوم‌گردی — ۲ شب',
    meals: 'صبحانه و شام',
    rules: 'لغو تا ۷۲ ساعت قبل بدون جریمه',
    services: ['حمل‌ونقل', 'اقامت', 'صبحانه و شام', 'لیدر'],
    aparatHash: 'w8lOg',
    agency: sampleAgency,
    reservationEnabled: true,
  ),
];

// ===============================================================
// Repository: API ← نمونه
// ===============================================================

class TourLoadResult {
  const TourLoadResult({required this.tours, required this.online});

  final List<Tour> tours;

  /// true = اطلاعات واقعی API (🟢) ، false = نمونه/آفلاین (🟡)
  final bool online;
}

class TourRepository {
  TourRepository._();

  static const String _endpoint = '/api/v1/tours';

  /// حداکثر ۲ ثانیه برای پاسخ API صبر می‌کند؛ اگر پاسخ معتبر نبود
  /// نمونه‌ی داخلی برمی‌گردد. هیچ‌وقت خطا به UI نمی‌رسد.
  static Future<TourLoadResult> load() async {
    try {
      final json = await ApiService.getJson(_endpoint, retry: 0)
          .timeout(const Duration(seconds: 2));
      final raw = json is Map ? json['items'] : json;
      if (raw is List) {
        final list = <Tour>[];
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            final t = Tour.fromJson(e);
            // فقط مواردی که اطلاعات معتبر دارند (بدون صفحه‌ی خالی)
            if (t.id > 0 && t.title.isNotEmpty) list.add(t);
          }
        }
        if (list.isNotEmpty) {
          return TourLoadResult(tours: list, online: true);
        }
      }
    } catch (_) {
      // قطع API / Timeout / JSON نامعتبر → نمونه
    }
    return const TourLoadResult(tours: sampleTours, online: false);
  }
}
