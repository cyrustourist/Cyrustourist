import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// ===============================================================
/// Cyrus Tourist — سرویس ساعت جهانی / زمان محلی مقصد
/// ---------------------------------------------------------------
/// کاملاً آفلاین است و به هیچ سرویس آنلاینی نیاز ندارد.
/// از پایگاه داده رسمی IANA Timezone (از طریق پکیج timezone) استفاده
/// می‌کند تا تغییر ساعت تابستانی/زمستانی هر کشور هم درست لحاظ شود؛
/// یک افست ثابت ساعتی، در نیمی از سال برای شهرهایی مثل لندن یا
/// نیویورک نادرست می‌شد.
/// ===============================================================

class WorldCityInfo {
  final String city;
  final String country;
  final String flag;
  final String timezoneId;

  const WorldCityInfo({
    required this.city,
    required this.country,
    required this.flag,
    required this.timezoneId,
  });
}

class WorldClockService {
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  /// شهرهای پیش‌فرض پرکاربرد برای مسافران ایرانی
  static const List<WorldCityInfo> defaultCities = [
    WorldCityInfo(
      city: 'تهران',
      country: 'ایران',
      flag: '🇮🇷',
      timezoneId: 'Asia/Tehran',
    ),
    WorldCityInfo(
      city: 'دبی',
      country: 'امارات',
      flag: '🇦🇪',
      timezoneId: 'Asia/Dubai',
    ),
    WorldCityInfo(
      city: 'استانبول',
      country: 'ترکیه',
      flag: '🇹🇷',
      timezoneId: 'Europe/Istanbul',
    ),
    WorldCityInfo(
      city: 'لندن',
      country: 'انگلیس',
      flag: '🇬🇧',
      timezoneId: 'Europe/London',
    ),
    WorldCityInfo(
      city: 'پاریس',
      country: 'فرانسه',
      flag: '🇫🇷',
      timezoneId: 'Europe/Paris',
    ),
    WorldCityInfo(
      city: 'مسکو',
      country: 'روسیه',
      flag: '🇷🇺',
      timezoneId: 'Europe/Moscow',
    ),
    WorldCityInfo(
      city: 'نیویورک',
      country: 'آمریکا',
      flag: '🇺🇸',
      timezoneId: 'America/New_York',
    ),
    WorldCityInfo(
      city: 'توکیو',
      country: 'ژاپن',
      flag: '🇯🇵',
      timezoneId: 'Asia/Tokyo',
    ),
    WorldCityInfo(
      city: 'پکن',
      country: 'چین',
      flag: '🇨🇳',
      timezoneId: 'Asia/Shanghai',
    ),
    WorldCityInfo(
      city: 'دهلی‌نو',
      country: 'هند',
      flag: '🇮🇳',
      timezoneId: 'Asia/Kolkata',
    ),
    WorldCityInfo(
      city: 'سیدنی',
      country: 'استرالیا',
      flag: '🇦🇺',
      timezoneId: 'Australia/Sydney',
    ),
  ];

  /// همه‌ی شهرهای موجود در پایگاه داده IANA — برای جستجوی مقصد دلخواه
  static List<String> allTimezoneIds() {
    init();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  static DateTime nowIn(String timezoneId) {
    init();
    final location = tz.getLocation(timezoneId);
    return tz.TZDateTime.now(location);
  }

  /// اختلاف ساعت این شهر نسبت به ساعت دستگاه کاربر (به ساعت)
  static double offsetDiffHoursFromDevice(String timezoneId) {
    init();
    final location = tz.getLocation(timezoneId);
    final there = tz.TZDateTime.now(location);
    final here = DateTime.now();
    return there.timeZoneOffset.inMinutes / 60.0 -
        here.timeZoneOffset.inMinutes / 60.0;
  }
}
