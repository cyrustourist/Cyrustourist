import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// صداهای تماس و مسیر صدا (کانال بومی cyrus/callaudio در MainActivity).
///
/// سه مرحله با سه صدای متفاوت (مثل تلگرام):
///  - [ringback]  : بوق انتظار (۱ ثانیه بوق، ۳ ثانیه سکوت) = آن طرف در حال زنگ خوردن است
///  - [connected] : دو بیپ کوتاه صعودی، یک‌بار = تماس وصل شد
///  - [ended]     : دو بیپ کوتاه نزولی، یک‌بار = تماس تمام شد
///  - [startRing] : زنگ تماس ورودی داخل برنامه (رینگتون گوشی + لرزش)
/// همهٔ فراخوانی‌ها بی‌خطر هستند؛ اگر کانال بومی نبود (مثلاً وب) فقط نادیده گرفته می‌شوند.
class CallAudio {
  CallAudio._();

  static const MethodChannel _ch = MethodChannel('cyrus/callaudio');

  static Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _ch.invokeMethod<T>(method, args);
    } catch (e) {
      debugPrint('callaudio $method: $e');
      return null;
    }
  }

  /// حالت «تماس» سیستم صدا (مسیر صدا به گوشی می‌رود).
  static Future<void> enterCall() => _invoke<bool>('enterCall');

  /// پایان حالت تماس و برگرداندن حالت عادی صدای گوشی.
  static Future<void> leaveCall() => _invoke<bool>('leaveCall');

  /// true = بلندگو، false = گوشی (یا هدست/بلوتوث اگر وصل باشد). نتیجه: آیا اعمال شد.
  static Future<bool> setSpeaker(bool on) async => (await _invoke<bool>('setSpeaker', {'on': on})) ?? false;

  static Future<void> ringback() => _invoke<bool>('tone', {'kind': 'ringback'});
  static Future<void> connected() => _invoke<bool>('tone', {'kind': 'connected'});
  static Future<void> ended() => _invoke<bool>('tone', {'kind': 'ended'});
  static Future<void> stopTone() => _invoke<bool>('stopTone');

  static Future<void> startRing() => _invoke<bool>('startRing');
  static Future<void> stopRing() => _invoke<bool>('stopRing');

  static Future<void> stopAll() => _invoke<bool>('stopAll');

  /// اندروید ۱۴ به بالا: آیا اعلان تمام‌صفحهٔ تماس (روی قفل گوشی) مجاز است؟
  static Future<bool> canFullScreen() async => (await _invoke<bool>('canFullScreen')) ?? true;

  static Future<bool> openFullScreenSettings() async => (await _invoke<bool>('openFullScreenSettings')) ?? false;
}
