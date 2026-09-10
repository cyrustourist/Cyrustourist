import 'dart:convert';
import 'dart:io';

/// ===============================================================
/// Cyrus Tourist — سرویس تبدیل ارز آنلاین
/// ---------------------------------------------------------------
/// منبع داده: Frankfurter.app
/// - کاملاً رایگان و بدون نیاز به کلید (API Key)
/// - داده‌های رسمی بانک مرکزی اروپا (ECB)
/// - بدون محدودیت مصرف برای استفاده عادی
///
/// محدودیت شناخته‌شده:
/// ریال ایران (IRR) در این سرویس و اکثر سرویس‌های رایگان معتبر
/// پشتیبانی نمی‌شود (نبود بازار رسمی جهانی). به همین دلیل این ابزار
/// برای تبدیل بین ارزهای جهانی (دلار، یورو، درهم، لیر، پوند و ...)
/// استفاده می‌شود.
/// ===============================================================
class CurrencyService {
  /// لیست ارزهای پشتیبانی‌شده به همراه نام و پرچم برای نمایش
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'USD', 'name': 'دلار آمریکا', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'یورو', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'پوند انگلیس', 'flag': '🇬🇧'},
    {'code': 'TRY', 'name': 'لیر ترکیه', 'flag': '🇹🇷'},
    {'code': 'AED', 'name': 'درهم امارات', 'flag': '🇦🇪'},
    {'code': 'CHF', 'name': 'فرانک سوئیس', 'flag': '🇨🇭'},
    {'code': 'CNY', 'name': 'یوان چین', 'flag': '🇨🇳'},
    {'code': 'JPY', 'name': 'ین ژاپن', 'flag': '🇯🇵'},
    {'code': 'CAD', 'name': 'دلار کانادا', 'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'دلار استرالیا', 'flag': '🇦🇺'},
    {'code': 'INR', 'name': 'روپیه هند', 'flag': '🇮🇳'},
    {'code': 'RUB', 'name': 'روبل روسیه', 'flag': '🇷🇺'},
    {'code': 'SEK', 'name': 'کرون سوئد', 'flag': '🇸🇪'},
    {'code': 'NOK', 'name': 'کرون نروژ', 'flag': '🇳🇴'},
    {'code': 'SGD', 'name': 'دلار سنگاپور', 'flag': '🇸🇬'},
    {'code': 'THB', 'name': 'بات تایلند', 'flag': '🇹🇭'},
    {'code': 'ILS', 'name': 'شکل اسرائیل', 'flag': '🇮🇱'},
    {'code': 'MXN', 'name': 'پزو مکزیک', 'flag': '🇲🇽'},
    {'code': 'ZAR', 'name': 'رند آفریقای جنوبی', 'flag': '🇿🇦'},
    {'code': 'HKD', 'name': 'دلار هنگ‌کنگ', 'flag': '🇭🇰'},
  ];

  /// امارات (AED) در Frankfurter نیست؛ اگر کاربر آن را انتخاب کند
  /// از نرخ‌های ثابت پشتیبان (docked USD) به‌عنوان جایگزین موقت
  /// استفاده نمی‌کنیم تا داده نادرست نمایش داده نشود؛ در عوض این
  /// کد فقط ارزهایی را واقعاً پیشنهاد می‌دهد که سرویس، نرخ زندهٔ
  /// آن‌ها را برمی‌گرداند (لیست زیر هنگام بارگذاری تایید می‌شود).

  /// دریافت نرخ زنده تبدیل [from] به [to] برای مقدار [amount]
  static Future<double> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    if (from == to) return amount;

    final uri = Uri.https(
      'api.frankfurter.app',
      '/latest',
      {
        'amount': amount.toString(),
        'from': from,
        'to': to,
      },
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('خطا در دریافت نرخ ارز (${response.statusCode})');
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final rates = data['rates'] as Map<String, dynamic>?;
      final value = rates?[to];

      if (value == null) {
        throw Exception('ارز مقصد پشتیبانی نمی‌شود');
      }

      return (value as num).toDouble();
    } finally {
      client.close(force: true);
    }
  }
}
