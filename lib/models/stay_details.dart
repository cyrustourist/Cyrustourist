import 'dart:convert';

import 'package:flutter/material.dart';

/// ===============================================================
/// Cyrus Tourist — جزئیات اقامتگاه (هماهنگ با جدول accommodations)
/// ---------------------------------------------------------------
/// کلیدهای امکانات دقیقاً همان کلیدهایی‌اند که پنل مدیریت
/// (ACCOM_AMENITIES در worker.js) در ستون amenities ذخیره می‌کند.
/// اگر در پنل امکان جدیدی اضافه شد، فقط یک خط به [StayAmenities.all]
/// اضافه کنید؛ کلیدِ ناشناخته هم به‌صورت عمومی نمایش داده می‌شود.
/// ===============================================================

class StayAmenity {
  const StayAmenity(this.key, this.icon, this.fa, this.en, this.ar);

  final String key;
  final IconData icon;
  final String fa;
  final String en;
  final String ar;

  String label(String lang) {
    switch (lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }
}

class StayAmenities {
  StayAmenities._();

  static const List<StayAmenity> all = [
    StayAmenity('western_toilet', Icons.wc_rounded, 'سرویس فرنگی', 'Western-style toilet', 'مرحاض إفرنجي'),
    StayAmenity('iranian_toilet', Icons.wc_rounded, 'سرویس ایرانی', 'Iranian-style toilet', 'مرحاض إيراني'),
    StayAmenity('kitchen', Icons.kitchen_rounded, 'آشپزخانه', 'Kitchen', 'مطبخ'),
    StayAmenity('hot_water', Icons.water_drop_rounded, 'آب‌گرم', 'Hot water', 'ماء ساخن'),
    StayAmenity('wifi', Icons.wifi_rounded, 'اینترنت / وای‌فای', 'Internet / Wi‑Fi', 'إنترنت / واي فاي'),
    StayAmenity('parking', Icons.local_parking_rounded, 'پارکینگ', 'Parking', 'موقف سيارات'),
    StayAmenity('elevator', Icons.elevator_rounded, 'آسانسور', 'Elevator', 'مصعد'),
    StayAmenity('restaurant', Icons.restaurant_rounded, 'رستوران', 'Restaurant', 'مطعم'),
    StayAmenity('breakfast', Icons.free_breakfast_rounded, 'صبحانه', 'Breakfast', 'إفطار'),
    StayAmenity('room_service', Icons.room_service_rounded, 'روم‌سرویس', 'Room service', 'خدمة الغرف'),
    StayAmenity('pool', Icons.pool_rounded, 'استخر', 'Pool', 'مسبح'),
    StayAmenity('sauna', Icons.hot_tub_rounded, 'سونا', 'Sauna', 'ساونا'),
    StayAmenity('jacuzzi', Icons.bathtub_rounded, 'جکوزی', 'Jacuzzi', 'جاكوزي'),
    StayAmenity('gym', Icons.fitness_center_rounded, 'سالن ورزشی', 'Gym', 'صالة رياضية'),
    StayAmenity('spa', Icons.spa_rounded, 'اسپا', 'Spa', 'سبا'),
    StayAmenity('prayer_room', Icons.self_improvement_rounded, 'نمازخانه', 'Prayer room', 'مصلى'),
    StayAmenity('transfer', Icons.airport_shuttle_rounded, 'ترانسفر فرودگاهی', 'Airport transfer', 'نقل من المطار'),
    StayAmenity('laundry', Icons.local_laundry_service_rounded, 'خدمات لاندری', 'Laundry', 'مغسلة'),
    StayAmenity('safe_box', Icons.lock_rounded, 'صندوق امانات', 'Safe box', 'خزنة'),
    StayAmenity('24h_reception', Icons.schedule_rounded, 'پذیرش ۲۴ ساعته', '24h reception', 'استقبال ٢٤ ساعة'),
    StayAmenity('air_conditioning', Icons.ac_unit_rounded, 'کولر / تهویه', 'AC / Cooling', 'مكيف / تهوية'),
    StayAmenity('heating', Icons.local_fire_department_rounded, 'سیستم گرمایشی', 'Heating', 'نظام تدفئة'),
    StayAmenity('tv', Icons.tv_rounded, 'تلویزیون', 'TV', 'تلفزيون'),
    StayAmenity('minibar', Icons.local_bar_rounded, 'مینی‌بار', 'Minibar', 'ميني بار'),
    StayAmenity('hairdryer', Icons.air_rounded, 'سشوار', 'Hairdryer', 'مجفف شعر'),
    StayAmenity('kettle', Icons.coffee_rounded, 'چای‌ساز', 'Kettle', 'غلاية'),
    StayAmenity('bathtub', Icons.bathtub_rounded, 'وان حمام', 'Bathtub', 'حوض استحمام'),
    StayAmenity('shower', Icons.shower_rounded, 'دوش', 'Shower', 'دش'),
    StayAmenity('balcony', Icons.deck_rounded, 'بالکن', 'Balcony', 'شرفة'),
    StayAmenity('sea_view', Icons.waves_rounded, 'نمای دریا', 'Sea view', 'إطلالة بحرية'),
    StayAmenity('city_view', Icons.location_city_rounded, 'نمای شهر', 'City view', 'إطلالة على المدينة'),
    StayAmenity('garden', Icons.park_rounded, 'فضای سبز', 'Garden', 'حديقة'),
    StayAmenity('children_play', Icons.child_friendly_rounded, 'فضای بازی کودک', 'Kids play area', 'منطقة ألعاب الأطفال'),
    StayAmenity('conference', Icons.groups_rounded, 'سالن کنفرانس', 'Conference hall', 'قاعة مؤتمرات'),
    StayAmenity('business_center', Icons.business_center_rounded, 'مرکز تجاری', 'Business center', 'مركز أعمال'),
    StayAmenity('wheelchair', Icons.accessible_rounded, 'دسترسی ویلچر', 'Wheelchair access', 'وصول الكراسي المتحركة'),
    StayAmenity('accessible_room', Icons.meeting_room_rounded, 'اتاق مناسب معلولین', 'Accessible room', 'غرفة مهيأة'),
    StayAmenity('security', Icons.videocam_rounded, 'دوربین و امنیت', 'CCTV & security', 'كاميرات وأمن'),
    StayAmenity('fire_alarm', Icons.notification_important_rounded, 'سیستم اعلام حریق', 'Fire alarm', 'إنذار حريق'),
    StayAmenity('fire_extinguisher', Icons.health_and_safety_rounded, 'کپسول آتش‌نشانی', 'Fire extinguisher', 'طفاية حريق'),
    StayAmenity('generator', Icons.bolt_rounded, 'برق اضطراری', 'Backup power', 'كهرباء احتياطية'),
    StayAmenity('pet_friendly', Icons.pets_rounded, 'مجاز بودن حیوانات', 'Pet friendly', 'يسمح بالحيوانات'),
    StayAmenity('smoking_area', Icons.smoking_rooms_rounded, 'محل مجاز استعمال دخانیات', 'Smoking area', 'منطقة تدخين'),
    StayAmenity('non_smoking', Icons.smoke_free_rounded, 'محیط غیرسیگاری', 'Non-smoking', 'ممنوع التدخين'),
    StayAmenity('ev_charging', Icons.ev_station_rounded, 'شارژ خودرو برقی', 'EV charging', 'شحن السيارات الكهربائية'),
    StayAmenity('currency_exchange', Icons.payments_rounded, 'تبدیل ارز', 'Currency exchange', 'صرف العملات'),
    StayAmenity('luggage_storage', Icons.work_rounded, 'نگهداری چمدان', 'Luggage storage', 'حفظ الأمتعة'),
    StayAmenity('concierge', Icons.support_agent_rounded, 'خدمات کانسیرج', 'Concierge', 'خدمة الكونسيرج'),
    StayAmenity('wake_up', Icons.alarm_rounded, 'سرویس بیدارباش', 'Wake-up call', 'خدمة الإيقاظ'),
  ];

  static final Map<String, StayAmenity> _byKey = {
    for (final a in all) a.key: a,
  };

  static StayAmenity? byKey(String key) => _byKey[key.trim().toLowerCase()];

  /// کلید ناشناخته (که در آینده در پنل اضافه شده) هم نمایش داده می‌شود.
  static StayAmenity resolve(String key) {
    final known = byKey(key);
    if (known != null) return known;
    final pretty = key.replaceAll('_', ' ').trim();
    return StayAmenity(key, Icons.check_circle_outline_rounded, pretty, pretty, pretty);
  }
}

/// نوع اقامتگاه: در پنل متن آزاد است (هتل، hotel، بوم‌گردی، ...)؛
/// اینجا به یک کلید و برچسب سه‌زبانه تبدیل می‌شود تا فیلتر چیپ‌ها کار کند.
class StayTypes {
  StayTypes._();

  // ترتیب مهم است: نوع‌های اختصاصی‌تر (مثل هتل آپارتمان) قبل از عمومی‌ترها (هتل، آپارتمان) می‌آیند.
  static const List<_StayType> _types = [
    _StayType('hotel_apartment', ['هتل آپارتمان', 'هتل‌آپارتمان', 'hotel_apartment', 'hotel apartment'], {'fa': 'هتل آپارتمان', 'en': 'Hotel apartment', 'ar': 'شقق فندقية'}),
    _StayType('hotel', ['هتل', 'hotel'], {'fa': 'هتل', 'en': 'Hotel', 'ar': 'فندق'}),
    _StayType('ecolodge', ['بوم گردی', 'بومگردی', 'بوم‌گردی', 'ecolodge', 'eco-lodge', 'eco lodge'], {'fa': 'بوم‌گردی', 'en': 'Eco-lodge', 'ar': 'نزل بيئي'}),
    _StayType('cottage', ['کلبه', 'cottage', 'cabin'], {'fa': 'کلبه', 'en': 'Cottage', 'ar': 'كوخ'}),
    _StayType('apartment', ['آپارتمان', 'apartment'], {'fa': 'آپارتمان', 'en': 'Apartment', 'ar': 'شقة'}),
    _StayType('villa', ['ویلا', 'ویلایی', 'villa'], {'fa': 'ویلایی', 'en': 'Villa', 'ar': 'فيلا'}),
    _StayType('suite', ['سوئیت', 'سوییت', 'suite'], {'fa': 'سوئیت', 'en': 'Suite', 'ar': 'جناح'}),
    _StayType('guesthouse', ['مهمان پذیر', 'مهمانپذیر', 'مهمان‌پذیر', 'guesthouse', 'guest house'], {'fa': 'مهمان‌پذیر', 'en': 'Guesthouse', 'ar': 'بيت ضيافة'}),
    _StayType('motel', ['متل', 'motel'], {'fa': 'متل', 'en': 'Motel', 'ar': 'موتيل'}),
    _StayType('pension', ['پانسیون', 'pension'], {'fa': 'پانسیون', 'en': 'Pension', 'ar': 'بنسيون'}),
    _StayType('hostel', ['هاستل', 'hostel'], {'fa': 'هاستل', 'en': 'Hostel', 'ar': 'نزل شبابي'}),
    _StayType('camp', ['کمپ', 'چادر', 'camp'], {'fa': 'کمپ و چادر', 'en': 'Camp', 'ar': 'مخيم'}),
    _StayType('traditional', ['سنتی', 'تاریخی', 'traditional'], {'fa': 'اقامتگاه سنتی', 'en': 'Traditional house', 'ar': 'بيت تقليدي'}),
    _StayType('resort', ['مجتمع', 'resort'], {'fa': 'مجتمع گردشگری', 'en': 'Resort', 'ar': 'منتجع'}),
    _StayType('other', ['other', 'سایر'], {'fa': 'سایر', 'en': 'Other', 'ar': 'أخرى'}),
  ];

  /// خروجی: کلید نوع (یا خالی) و برچسب‌های سه‌زبانه
  static ({String key, Map<String, String> labels}) resolve(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return (key: '', labels: const {});
    final lower = text.toLowerCase();
    for (final t in _types) {
      for (final k in t.keywords) {
        if (lower.contains(k.toLowerCase())) {
          return (key: t.key, labels: t.labels);
        }
      }
    }
    return (key: lower, labels: {'fa': text, 'en': text, 'ar': text});
  }
}

class _StayType {
  const _StayType(this.key, this.keywords, this.labels);

  final String key;
  final List<String> keywords;
  final Map<String, String> labels;
}

/// همه‌ی فیلدهای «اقامتگاه» که از جدول accommodations می‌آید و در
/// صفحه‌ی جزئیات نمایش داده می‌شود.
class StayDetails {
  const StayDetails({
    this.typeKey = '',
    this.typeLabels = const {},
    this.stars = 0,
    this.address,
    this.amenityKeys = const [],
    this.hasElevator = false,
    this.checkIn,
    this.checkOut,
    this.rules,
    this.mobile,
    this.phone,
    this.phone2,
    this.email,
    this.website2,
    this.bookingUrl,
    this.whatsapp,
    this.telegram,
    this.eitaa,
    this.youtube,
    this.aparat,
    this.tiktok,
    this.ownerPhoto,
    this.bedrooms = 0,
    this.mapUrl,
    this.managementCode,
  });

  final String typeKey;
  final Map<String, String> typeLabels;
  final int stars;
  final String? address;
  final List<String> amenityKeys;
  final bool hasElevator;
  final String? checkIn;
  final String? checkOut;
  final String? rules;

  final String? mobile;
  final String? phone;
  final String? phone2;
  final String? email;
  final String? website2;
  final String? bookingUrl;
  final String? whatsapp;
  final String? telegram;
  final String? eitaa;
  final String? youtube;
  final String? aparat;
  final String? tiktok;
  final String? ownerPhoto;

  /// تعداد اتاق‌خواب (در پنل داخل ستون امکانات به‌صورت bedrooms:N ذخیره می‌شود)
  final int bedrooms;
  final String? mapUrl;
  final String? managementCode;

  /// همه‌ی شماره‌های تماس بدون تکرار (به ترتیب: همراه، ثابت، کمکی)
  List<String> get phones {
    final out = <String>[];
    for (final p in [mobile, phone, phone2]) {
      final v = (p ?? '').trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }

  bool get hasAnyContactLink =>
      (email ?? '').isNotEmpty ||
      (website2 ?? '').isNotEmpty ||
      (telegram ?? '').isNotEmpty ||
      (eitaa ?? '').isNotEmpty ||
      (youtube ?? '').isNotEmpty ||
      (aparat ?? '').isNotEmpty ||
      (tiktok ?? '').isNotEmpty ||
      (whatsapp ?? '').isNotEmpty;

  static String? _s(dynamic v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }

  static bool _b(dynamic v) {
    if (v == true || v == 1) return true;
    final t = (v?.toString() ?? '').trim().toLowerCase();
    return t == '1' || t == 'true' || t == 'yes' || t == 'on';
  }

  static List<String> parseAmenities(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final raw = v.toString().trim();
    if (raw.isEmpty) return const [];
    if (raw.startsWith('[')) {
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          return d.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return raw
        .split(RegExp(r'[,،;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory StayDetails.fromRow(Map<String, dynamic> j) {
    final type = StayTypes.resolve(_s(j['accommodation_type']));

    var amenities = parseAmenities(j['amenities_list'] ?? j['amenities']);
    var bedrooms = int.tryParse((j['bedrooms'] ?? 0).toString()) ?? 0;
    for (final a in amenities) {
      if (a.startsWith('bedrooms:')) {
        bedrooms = int.tryParse(a.substring(9)) ?? bedrooms;
      }
    }
    amenities = amenities.where((a) => !a.startsWith('bedrooms:')).toList();
    final elevator = _b(j['has_elevator']) || amenities.contains('elevator');
    if (elevator && !amenities.contains('elevator')) {
      amenities = [...amenities, 'elevator'];
    }

    final starsRaw = int.tryParse((j['stars'] ?? 0).toString()) ?? 0;

    return StayDetails(
      typeKey: type.key,
      typeLabels: type.labels,
      stars: starsRaw < 0 ? 0 : (starsRaw > 5 ? 5 : starsRaw),
      address: _s(j['address']),
      amenityKeys: amenities,
      hasElevator: elevator,
      checkIn: _s(j['check_in']),
      checkOut: _s(j['check_out']),
      rules: _s(j['rules']),
      mobile: _s(j['mobile'] ?? j['phone_mobile']),
      phone: _s(j['phone']),
      phone2: _s(j['phone2']),
      email: _s(j['email']),
      website2: _s(j['website2']),
      bookingUrl: _s(j['direct_booking_link']),
      whatsapp: _s(j['whatsapp_url']),
      telegram: _s(j['telegram_url']),
      eitaa: _s(j['eitaa_url']),
      youtube: _s(j['youtube_url'] ?? j['social_youtube']),
      aparat: _s(j['aparat_url'] ?? j['social_aparat']),
      tiktok: _s(j['tiktok_url']),
      ownerPhoto: _s(j['owner_profile_photo']),
      bedrooms: bedrooms < 0 ? 0 : bedrooms,
      mapUrl: _s(j['map_url'] ?? j['map_link']),
      managementCode: _s(j['management_code']),
    );
  }
}
