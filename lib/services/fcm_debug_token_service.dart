import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ⚠️ فایل موقت — فقط برای تست دستی نوتیفیکیشن.
///
/// این فایل کاملاً مستقل است و به notification_service.dart وابسته
/// نیست، تا وقتی تست نوتیفیکیشن تمام شد، بتوان با حذف همین یک فایل
/// و یک خط فراخوانی در main.dart، کل قابلیت را پاک کرد بدون این‌که
/// چیزی در بقیه‌ی پروژه (از جمله notification_service.dart) دست
/// بخورد.
///
/// نحوه‌ی استفاده: در main.dart، داخل initState صفحه‌ی اصلی، این
/// خط را صدا بزنید:
///
///   FcmDebugTokenService.showTokenDialog(context);
///
/// یک پنجره باز می‌شود که توکن FCM دستگاه را نشان می‌دهد؛ آن را کپی
/// کنید و در Firebase Console → Cloud Messaging → Send test message
/// وارد کنید تا پوش نوتیفیکیشن آزمایشی را روی همین دستگاه تست کنید.
class FcmDebugTokenService {
  FcmDebugTokenService._();

  static Future<void> showTokenDialog(BuildContext context) async {
    String? token;

    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('FCM token error: $error');
      token = null;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('FCM Token (تست نوتیفیکیشن)'),
        content: SingleChildScrollView(
          child: SelectableText(
            token ??
                'توکن دریافت نشد (اتصال اینترنت/Google Play Services را چک کنید)',
          ),
        ),
        actions: [
          if (token != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token!));
                Navigator.pop(context);
              },
              child: const Text('کپی و بستن'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}
