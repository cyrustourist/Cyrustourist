import 'package:flutter/services.dart';

/// درخواست مجوز میکروفن/دوربین به‌صورت بومی (اندروید).
/// نتیجهٔ هر مجوز: granted | denied | blocked
///   blocked = اندروید دیگر پنجرهٔ مجوز نشان نمی‌دهد (کاربر قبلاً «دیگر نپرس» زده)؛ فقط از تنظیمات گوشی فعال می‌شود.
class AppPermissions {
  AppPermissions._();

  static const MethodChannel _ch = MethodChannel('cyrus/perm');

  /// وضعیت فعلی بدون نمایش پنجره. null = کانال بومی در دسترس نیست.
  static Future<bool?> isGranted(List<String> perms) async {
    try {
      final r = await _ch.invokeMethod<Map<dynamic, dynamic>>('status', {'perms': perms});
      if (r == null) return null;
      return perms.every((p) => r[p] == 'granted');
    } catch (_) {
      return null;
    }
  }

  /// پنجرهٔ مجوز سیستم را نشان می‌دهد. null = کانال بومی در دسترس نیست.
  static Future<Map<String, String>?> request(List<String> perms) async {
    try {
      final r = await _ch.invokeMethod<Map<dynamic, dynamic>>('request', {'perms': perms});
      if (r == null) return null;
      return r.map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return null;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _ch.invokeMethod('openAppSettings');
    } catch (_) {}
  }
}
