import 'package:flutter/services.dart';

/// پل ارتباطی با کد بومی اندروید (MainActivity.kt):
/// چراغ قوه و حسگر قطب‌نما.
class CyrusNativeTools {
  CyrusNativeTools._();

  static const MethodChannel _torch = MethodChannel('cyrus/torch');
  static const EventChannel _compass = EventChannel('cyrus/compass');

  static Future<bool> torchAvailable() async {
    try {
      return (await _torch.invokeMethod<bool>('isAvailable')) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setTorch(bool on) async {
    try {
      await _torch.invokeMethod<bool>('setTorch', {'on': on});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// زاویه‌ی جهت گوشی (۰ تا ۳۶۰، ۰ = شمال مغناطیسی).
  static Stream<double> compassStream() {
    return _compass
        .receiveBroadcastStream()
        .map((event) => (event as num).toDouble());
  }
}
