import 'dart:convert';
import 'price_pack.dart';

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
    // ---- امکانات مخصوص گردشگری سلامت (کلیدها = کلیدهای پنل مدیریت) ----
    StayAmenity('hospital', Icons.local_hospital_rounded, 'بیمارستان / مرکز درمانی', 'Hospital / medical center', 'مستشفى / مركز طبي'),
    StayAmenity('specialist', Icons.medical_services_rounded, 'پزشک متخصص', 'Specialist doctor', 'طبيب مختص'),
    StayAmenity('surgery', Icons.healing_rounded, 'خدمات جراحی', 'Surgery services', 'خدمات جراحية'),
    StayAmenity('diagnosis', Icons.biotech_rounded, 'تشخیص و آزمایش', 'Diagnosis & tests', 'تشخيص وفحوصات'),
    StayAmenity('dental', Icons.health_and_safety_rounded, 'دندان‌پزشکی', 'Dentistry', 'طب الأسنان'),
    StayAmenity('beauty', Icons.face_retouching_natural_rounded, 'خدمات زیبایی', 'Beauty services', 'خدمات التجميل'),
    StayAmenity('rehabilitation', Icons.accessibility_new_rounded, 'توانبخشی', 'Rehabilitation', 'التأهيل'),
    StayAmenity('hotel', Icons.hotel_rounded, 'اقامت بیمار', 'Patient accommodation', 'إقامة المريض'),
    StayAmenity('interpreter', Icons.translate_rounded, 'مترجم', 'Interpreter', 'مترجم'),
    StayAmenity('visa_support', Icons.flight_takeoff_rounded, 'پشتیبانی ویزا', 'Visa support', 'دعم التأشيرة'),
    StayAmenity('24h_support', Icons.support_agent_rounded, 'پشتیبانی ۲۴ ساعته', '24h support', 'دعم على مدار الساعة'),
    StayAmenity('emergency', Icons.emergency_rounded, 'خدمات اورژانسی', 'Emergency services', 'خدمات الطوارئ'),
    StayAmenity('ambulance', Icons.airport_shuttle_rounded, 'آمبولانس', 'Ambulance', 'إسعاف'),
    StayAmenity('icu', Icons.monitor_heart_rounded, 'بخش مراقبت ویژه (ICU)', 'Intensive care (ICU)', 'العناية المركزة'),
    StayAmenity('laboratory', Icons.science_rounded, 'آزمایشگاه', 'Laboratory', 'مختبر'),
    StayAmenity('radiology', Icons.settings_overscan_rounded, 'رادیولوژی و تصویربرداری', 'Radiology & imaging', 'الأشعة والتصوير'),
    StayAmenity('pharmacy', Icons.medication_rounded, 'داروخانه', 'Pharmacy', 'صيدلية'),
    StayAmenity('telemedicine', Icons.video_call_rounded, 'ویزیت آنلاین', 'Online consultation', 'استشارة عن بعد'),
    StayAmenity('online_booking', Icons.event_available_rounded, 'نوبت‌دهی آنلاین', 'Online booking', 'حجز إلكتروني'),
    StayAmenity('insurance_accepted', Icons.verified_user_rounded, 'پذیرش بیمه', 'Insurance accepted', 'قبول التأمين'),
    StayAmenity('international_patients', Icons.public_rounded, 'پذیرش بیمار خارجی', 'International patients', 'استقبال المرضى الأجانب'),
    StayAmenity('female_doctor', Icons.female_rounded, 'پزشک خانم', 'Female doctor', 'طبيبة'),
    StayAmenity('children_ward', Icons.child_care_rounded, 'بخش کودکان', 'Children ward', 'قسم الأطفال'),
    StayAmenity('maternity', Icons.pregnant_woman_rounded, 'زایشگاه و زنان', 'Maternity & gynecology', 'الولادة والنساء'),
    StayAmenity('waiting_lounge', Icons.weekend_rounded, 'سالن انتظار', 'Waiting lounge', 'صالة انتظار'),
    StayAmenity('cafe', Icons.local_cafe_rounded, 'کافی‌شاپ و رستوران', 'Cafe & restaurant', 'مقهى ومطعم'),
    StayAmenity('atm', Icons.atm_rounded, 'خودپرداز', 'ATM', 'صراف آلي'),
    StayAmenity('hot_spring', Icons.hot_tub_rounded, 'آب معدنی / آبگرم', 'Mineral / hot spring', 'مياه معدنية / ينابيع حارة'),
    StayAmenity('massage_service', Icons.spa_rounded, 'ماساژ درمانی', 'Therapeutic massage', 'مساج علاجي'),
    StayAmenity('spa_service', Icons.hot_tub_rounded, 'اسپا و سونا', 'Spa & sauna', 'سبا وساونا'),
  ];

  static final Map<String, StayAmenity> _byKey = {
    for (final a in all) a.key: a,
  };

  static StayAmenity? byKey(String key) => _byKey[key.trim().toLowerCase()];

  /// کلید ناشناخته (که در آینده در پنل اضافه شده) هم نمایش داده می‌شود.
  ///
  /// [panelLabels]: برچسب‌هایی که خود پنل همراه رکورد می‌فرستد (ستون amenity_labels).
  /// اگر امکانی فقط در پنل اضافه شده باشد، با همان نام پنل در اپ دیده می‌شود
  /// و نیازی به به‌روزرسانی اپ نیست. برچسب پنل (فارسی) روی برچسب فارسی اپ می‌نشیند.
  static StayAmenity resolve(String key, {Map<String, String> panelLabels = const {}}) {
    final known = byKey(key);
    final panel = (panelLabels[key] ?? panelLabels[key.trim().toLowerCase()] ?? '').trim();
    if (known != null) {
      if (panel.isEmpty || panel == known.fa) return known;
      return StayAmenity(known.key, known.icon, panel, known.en, known.ar);
    }
    final pretty = panel.isNotEmpty ? panel : key.replaceAll('_', ' ').trim();
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

/// روزهای هفته (برای جدول «روزهای کاری» گردشگری سلامت).
/// کلیدها دقیقاً همان کلیدهایی‌اند که پنل مدیریت در ستون work_days ذخیره می‌کند.
class StayWeekday {
  const StayWeekday(this.key, this.fa, this.en, this.ar);

  final String key;
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

class StayWeekdays {
  StayWeekdays._();

  /// ترتیب هفته‌ی ایرانی: شنبه تا جمعه
  static const List<StayWeekday> all = [
    StayWeekday('sat', 'شنبه', 'Saturday', 'السبت'),
    StayWeekday('sun', 'یکشنبه', 'Sunday', 'الأحد'),
    StayWeekday('mon', 'دوشنبه', 'Monday', 'الاثنين'),
    StayWeekday('tue', 'سه‌شنبه', 'Tuesday', 'الثلاثاء'),
    StayWeekday('wed', 'چهارشنبه', 'Wednesday', 'الأربعاء'),
    StayWeekday('thu', 'پنجشنبه', 'Thursday', 'الخميس'),
    StayWeekday('fri', 'جمعه', 'Friday', 'الجمعة'),
  ];

  /// ورودی: آرایه‌ی JSON، لیست یا متن جداشده با ویرگول. خروجی: فقط کلیدهای معتبر، به ترتیب هفته.
  static List<String> parse(dynamic v) {
    if (v == null) return const [];
    var raw = <String>[];
    if (v is List) {
      raw = v.map((e) => e.toString().trim().toLowerCase()).toList();
    } else {
      final text = v.toString().trim();
      if (text.isEmpty) return const [];
      if (text.startsWith('[')) {
        try {
          final d = jsonDecode(text);
          if (d is List) {
            raw = d.map((e) => e.toString().trim().toLowerCase()).toList();
          }
        } catch (_) {}
      } else {
        raw = text
            .split(RegExp(r'[,،;|]'))
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [
      for (final d in all)
        if (raw.contains(d.key)) d.key,
    ];
  }
}

/// نوع مرکز در گردشگری سلامت.
/// کلیدها و ترتیب کلمات دقیقاً همان HEALTH_TYPES / HEALTH_TYPE_WORDS در پنل مدیریت (worker.js)
/// است؛ بنابراین کلید «نوع سلامت» در پنل و در نوار ابزار اپ یکی است.
class HealthType {
  const HealthType(this.key, this.keywords, this.labels);

  final String key;
  final List<String> keywords;
  final Map<String, String> labels;
}

class HealthTypes {
  HealthTypes._();

  /// ترتیب نمایش در نوار ابزار (کلید آسانسوری)
  static const List<HealthType> all = [
    HealthType('hospital', ['بیمارستان', 'hospital'], {'fa': 'بیمارستان', 'en': 'Hospital', 'ar': 'مستشفى'}),
    HealthType('clinic', ['کلینیک', 'درمانگاه', 'clinic'], {'fa': 'کلینیک و درمانگاه', 'en': 'Clinic', 'ar': 'عيادة'}),
    HealthType('dental', ['دندان', 'dental'], {'fa': 'دندان‌پزشکی', 'en': 'Dental', 'ar': 'أسنان'}),
    HealthType('beauty', ['زیبایی', 'پوست', 'beauty', 'cosmetic'], {'fa': 'زیبایی، پوست و مو', 'en': 'Beauty & skin', 'ar': 'تجميل وجلد'}),
    HealthType('spa', ['آبگرم', 'اسپا', 'spa', 'hot spring'], {'fa': 'آبگرم و اسپا', 'en': 'Hot spring & spa', 'ar': 'ينابيع حارة وسبا'}),
    HealthType('massage', ['ماساژ', 'massage'], {'fa': 'ماساژ و ریلکسیشن', 'en': 'Massage', 'ar': 'مساج واسترخاء'}),
    HealthType('specialist', ['متخصص', 'پزشک', 'specialist', 'doctor'], {'fa': 'پزشک متخصص', 'en': 'Specialist doctor', 'ar': 'طبيب مختص'}),
    HealthType('physio', ['فیزیو', 'توانبخشی', 'physio', 'rehab'], {'fa': 'فیزیوتراپی و توانبخشی', 'en': 'Physio & rehab', 'ar': 'علاج طبيعي وتأهيل'}),
    HealthType('lab', ['آزمایشگاه', 'رادیولوژی', 'سونوگرافی', 'lab', 'radiology'], {'fa': 'آزمایشگاه و تصویربرداری', 'en': 'Lab & imaging', 'ar': 'مختبر وتصوير'}),
    HealthType('eye', ['چشم', 'لیزیک', 'eye', 'lasik'], {'fa': 'چشم‌پزشکی و لیزیک', 'en': 'Eye care & LASIK', 'ar': 'طب العيون'}),
    HealthType('hair', ['کاشت مو', 'hair'], {'fa': 'کاشت مو', 'en': 'Hair transplant', 'ar': 'زراعة الشعر'}),
    HealthType('fertility', ['ناباروری', 'زنان', 'fertility', 'ivf'], {'fa': 'زنان و ناباروری', 'en': 'Women & fertility', 'ar': 'نساء وخصوبة'}),
    HealthType('traditional', ['طب سنتی', 'گیاهی', 'traditional'], {'fa': 'طب سنتی و گیاهی', 'en': 'Traditional medicine', 'ar': 'طب تقليدي'}),
    HealthType('nutrition', ['تغذیه', 'رژیم', 'nutrition', 'diet'], {'fa': 'تغذیه و رژیم‌درمانی', 'en': 'Nutrition & diet', 'ar': 'تغذية وحمية'}),
    HealthType('pharmacy', ['داروخانه', 'pharmacy'], {'fa': 'داروخانه', 'en': 'Pharmacy', 'ar': 'صيدلية'}),
    HealthType('wellness', ['تندرستی', 'wellness', 'yoga', 'یوگا'], {'fa': 'سلامت و تندرستی', 'en': 'Wellness', 'ar': 'عافية'}),
    HealthType('other', [], {'fa': 'سایر', 'en': 'Other', 'ar': 'أخرى'}),
  ];

  /// ورودی: مقدار ستون health_type (کلید دقیق یا متن آزاد) — در نبودش service_type / specialty.
  static ({String key, Map<String, String> labels}) resolve(List<String?> raws) {
    for (final raw in raws) {
      final text = (raw ?? '').trim();
      if (text.isEmpty) continue;
      final lower = text.toLowerCase();
      for (final t in all) {
        if (t.key == lower) return (key: t.key, labels: t.labels);
      }
      for (final t in all) {
        for (final k in t.keywords) {
          if (lower.contains(k.toLowerCase())) return (key: t.key, labels: t.labels);
        }
      }
      final other = all.last;
      return (key: other.key, labels: other.labels);
    }
    return (key: '', labels: const {});
  }
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
    this.amenityLabels = const {},
    this.isHealth = false,
    this.workDays = const [],
    this.pricePack,
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
  final PricePack? pricePack;

  /// تعداد اتاق‌خواب (در پنل داخل ستون امکانات به‌صورت bedrooms:N ذخیره می‌شود)
  final int bedrooms;
  final String? mapUrl;
  final String? managementCode;

  /// برچسب امکانات از پنل (کلید → نام فارسی) برای امکاناتی که اپ هنوز نمی‌شناسد
  final Map<String, String> amenityLabels;

  /// true = رکورد «گردشگری سلامت» (از همین مدل برای نمایش استفاده می‌شود)
  final bool isHealth;

  /// روزهای کاری هفته (کلیدهای StayWeekdays) — فقط برای گردشگری سلامت
  final List<String> workDays;

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

  static Map<String, String> parseAmenityLabels(dynamic v) {
    if (v == null) return const {};
    dynamic d = v;
    if (v is String) {
      final raw = v.trim();
      if (raw.isEmpty || !raw.startsWith('{')) return const {};
      try {
        d = jsonDecode(raw);
      } catch (_) {
        return const {};
      }
    }
    if (d is! Map) return const {};
    final out = <String, String>{};
    d.forEach((k, val) {
      final s = val?.toString().trim() ?? '';
      if (s.isNotEmpty) out[k.toString()] = s;
    });
    return out;
  }

  factory StayDetails.fromRow(Map<String, dynamic> j, {bool health = false}) {
    final type = health
        ? HealthTypes.resolve([_s(j['health_type']), _s(j['service_type']), _s(j['specialty'])])
        : StayTypes.resolve(_s(j['accommodation_type']));

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
      checkIn: _s(j['check_in']) ?? (health ? _s(j['opening_hours']) : null),
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
      amenityLabels: parseAmenityLabels(j['amenity_labels']),
      isHealth: health,
      workDays: StayWeekdays.parse(j['work_days']),
      pricePack: PricePack.tryParse(j['price_pack']),
    );
  }
}
