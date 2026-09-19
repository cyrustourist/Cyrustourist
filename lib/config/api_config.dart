/// ===============================================================
/// Cyrus Tourist — تنظیمات مرکزی API
/// ---------------------------------------------------------------
/// طبق «دستور کار فنی Android»: Base URL فقط اینجا تعریف می‌شود و
/// هیچ فایل دیگری آدرس سرور را مستقیم نمی‌نویسد. برای عوض کردن
/// Backend، فقط همین یک خط کافی است.
///
/// Android هرگز مستقیماً به Cloudflare D1 وصل نمی‌شود؛ فقط از طریق
/// همین API (که پشت آن Cloudflare Worker است) صحبت می‌کند.
/// ===============================================================
class ApiConfig {
  ApiConfig._();

  /// آدرس اصلی Cloudflare Worker API.
  static const String baseUrl = 'https://cyrus-tourist-api.cyrustourist.workers.dev';

  /// مسیر بررسی سلامت سرور (اگر بک‌اند مسیر دیگری داشت، فقط همین را عوض کنید).
  static const String healthPath = '/';

  /// کلید عمومی اختیاری (هدر X-Api-Key) — هرگز Secret واقعی/حساس اینجا نگذارید.
  static const String apiKey = '';

  /// سقف زمان انتظار هر درخواست؛ برنامه هرگز نامحدود منتظر سرور نمی‌ماند.
  static const Duration timeout = Duration(seconds: 8);

  /// حداکثر تعداد تلاش مجدد برای یک درخواست ناموفق (Retry محدود، نه بی‌نهایت).
  static const int maxRetry = 2;

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$clean').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }
}
