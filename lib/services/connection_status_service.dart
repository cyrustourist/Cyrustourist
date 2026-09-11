import 'dart:io';

/// ===============================================================
/// Cyrus Tourist — سرویس بررسی وضعیت اتصال اینترنت
/// ---------------------------------------------------------------
/// بررسی می‌کند که آیا دستگاه در حال حاضر به اینترنت متصل است یا نه،
/// با یک DNS lookup سبک به یک هاست معتبر و پایدار.
/// ===============================================================
class ConnectionStatusService {
  /// بررسی اتصال واقعی به اینترنت (نه فقط اتصال به Wi-Fi/شبکه محلی).
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
