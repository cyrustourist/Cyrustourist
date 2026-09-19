import 'dart:async';
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

  static Timer? _watchTimer;
  static bool _lastKnown = true;

  /// شروع پایش دوره‌ای اتصال؛ هر بار که از قطع به وصل برمی‌گردد،
  /// [onReconnected] صدا زده می‌شود (برای Sync خودکار Cache/صف آفلاین).
  /// چند بار صدا زدن این متد بی‌خطر است (تایمر قبلی جایگزین می‌شود).
  static void startWatching({
    Duration interval = const Duration(seconds: 20),
    required void Function() onReconnected,
  }) {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(interval, (_) async {
      final now = await hasInternet();
      if (now && !_lastKnown) onReconnected();
      _lastKnown = now;
    });
  }

  static void stopWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }
}
