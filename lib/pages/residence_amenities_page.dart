import 'package:flutter/material.dart';

import '../core/language/app_language.dart';
import 'residence_video_page.dart' show ResidenceVideoData;

// رنگ‌ها — مطابق residence_video_page.dart (فایلی جدا، نمی‌تواند
// ثابت‌های private آن فایل را import کند، پس همان مقادیر را کپی می‌کند)
const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);

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

String _t(String fa, String en, String ar) {
  switch (_lang) {
    case 'en':
      return en;
    case 'ar':
      return ar;
    default:
      return fa;
  }
}

/// یک ردیف امکانات ثابت — یا بولی (دارد/ندارد) یا با یک مقدار متنی
/// کوتاه (مثلاً تعداد اتاق‌خواب).
class _AmenityRow {
  final IconData icon;
  final String label;
  final bool available;

  /// اگر غیر-null باشد، به‌جای آیکون تیک/ضربدر همین متن نشان داده می‌شود
  /// (مثلاً "۳ اتاق")
  final String? valueText;

  const _AmenityRow({
    required this.icon,
    required this.label,
    required this.available,
    this.valueText,
  });
}

/// صفحه‌ی «امکانات اقامتگاه» — فهرست ثابتی از امکانات که هنگام
/// ثبت‌نام تیک زده می‌شوند و اینجا برای گردشگر نمایش داده می‌شوند.
class ResidenceAmenitiesPage extends StatelessWidget {
  const ResidenceAmenitiesPage({super.key, required this.data});

  final ResidenceVideoData data;

  List<_AmenityRow> get _rows => [
        _AmenityRow(
          icon: Icons.local_parking_rounded,
          label: _t('پارکینگ', 'Parking', 'موقف سيارات'),
          available: data.hasParking,
        ),
        _AmenityRow(
          icon: Icons.wc_rounded,
          label: _t('سرویس فرنگی', 'Western-style toilet', 'مرحاض إفرنجي'),
          available: data.hasWesternToilet,
        ),
        _AmenityRow(
          icon: Icons.wc_rounded,
          label: _t('سرویس ایرانی', 'Iranian-style toilet', 'مرحاض إيراني'),
          available: data.hasIranianToilet,
        ),
        _AmenityRow(
          icon: Icons.bed_rounded,
          label: _t('تعداد اتاق‌خواب', 'Bedrooms', 'غرف النوم'),
          available: data.bedroomCount != null && data.bedroomCount! > 0,
          valueText: data.bedroomCount != null
              ? _t('${data.bedroomCount} اتاق', '${data.bedroomCount} rooms',
                  '${data.bedroomCount} غرف')
              : null,
        ),
        _AmenityRow(
          icon: Icons.wifi_rounded,
          label: _t('اینترنت / وای‌فای', 'Internet / Wi-Fi', 'إنترنت / واي فاي'),
          available: data.hasInternet,
        ),
        _AmenityRow(
          icon: Icons.kitchen_rounded,
          label: _t('آشپزخانه', 'Kitchen', 'مطبخ'),
          available: data.hasKitchen,
        ),
        _AmenityRow(
          icon: Icons.ac_unit_rounded,
          label: _t('کولر / تهویه', 'AC / Cooling', 'مكيف / تهوية'),
          available: data.hasAc,
        ),
        _AmenityRow(
          icon: Icons.thermostat_rounded,
          label: _t('سیستم گرمایشی', 'Heating', 'نظام تدفئة'),
          available: data.hasHeating,
        ),
        _AmenityRow(
          icon: Icons.shower_rounded,
          label: _t('آب‌گرم', 'Hot water', 'ماء ساخن'),
          available: data.hasHotWater,
        ),
        _AmenityRow(
          icon: Icons.free_breakfast_rounded,
          label: _t('صبحانه', 'Breakfast', 'وجبة إفطار'),
          available: data.hasBreakfast,
        ),
        _AmenityRow(
          icon: Icons.elevator_rounded,
          label: _t('آسانسور', 'Elevator', 'مصعد'),
          available: data.hasElevator,
        ),
        _AmenityRow(
          icon: Icons.deck_rounded,
          label: _t('حیاط / بالکن', 'Yard / Balcony', 'حديقة / شرفة'),
          available: data.hasYardOrBalcony,
        ),
        _AmenityRow(
          icon: Icons.pets_rounded,
          label: _t('مناسب حیوان خانگی', 'Pet-friendly', 'يسمح بالحيوانات الأليفة'),
          available: data.isPetFriendly,
        ),
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
            _t('امکانات اقامتگاه', 'Residence Amenities', 'مرافق الإقامة'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
            children: [
              Text(
                data.displayName,
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t(
                  'این فهرست، امکانات ثابتی است که هنگام ثبت‌نام تیک زده می‌شوند.',
                  'This is the fixed list of amenities ticked at registration time.',
                  'هذه قائمة المرافق الثابتة التي يتم تحديدها عند التسجيل.',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              ..._rows.map(_amenityTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amenityTile(_AmenityRow row) {
    final bool on = row.available;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? _goldA(0.35) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (on ? _teal : Colors.white24).withValues(alpha: 0.12),
            ),
            child: Icon(
              row.icon,
              size: 18,
              color: on ? _teal : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                color: on ? Colors.white : Colors.white.withValues(alpha: 0.45),
                fontSize: 13.5,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (row.valueText != null && on)
            Text(
              row.valueText!,
              style: const TextStyle(
                color: _goldBright,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          else
            Icon(
              on ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 20,
              color: on ? _teal : Colors.white.withValues(alpha: 0.25),
            ),
        ],
      ),
    );
  }
}
