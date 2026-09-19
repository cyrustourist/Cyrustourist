/// ===============================================================
/// Cyrus Tourist — خطاهای شبکه‌ی تایپ‌شده
/// ---------------------------------------------------------------
/// هیچ‌کدام از این‌ها نباید باعث Crash برنامه شوند؛ فقط برای این
/// تعریف شده‌اند که ApiService/Repository بفهمند رفتار بعدی
/// (Cache یا Fallback) چه باشد.
/// ===============================================================
sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// اینترنت قطع است یا اصلاً به سرور نرسیدیم.
class ApiNetworkException extends ApiException {
  const ApiNetworkException([super.message = 'network error']);
}

/// درخواست بیش از حد مجاز طول کشید.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([super.message = 'timeout']);
}

/// سرور پاسخ داد ولی با کد خطا (۴xx / ۵xx).
class ApiServerException extends ApiException {
  const ApiServerException(this.statusCode, [String message = 'server error'])
      : super(message);
  final int statusCode;

  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}

/// بدنه‌ی پاسخ JSON معتبر نبود.
class ApiParseException extends ApiException {
  const ApiParseException([super.message = 'invalid response']);
}
