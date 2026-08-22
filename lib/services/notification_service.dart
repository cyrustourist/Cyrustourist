import 'package:flutter/foundation.dart';

/// سرویس مرکزی اعلان‌های سایروس توریست.
///
/// این سرویس فعلاً یک لایه مستقل برای مدیریت اعلان‌هاست
/// تا در ادامه بتوانیم اعلان‌های محلی، اطلاع‌رسانی گردشگری
/// و پیام‌های برنامه را بدون تغییر گسترده در صفحات اضافه کنیم.
class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  /// وضعیت آماده بودن سرویس
  bool _initialized = false;

  /// بررسی آماده بودن سرویس
  bool get isInitialized => _initialized;

  /// آماده‌سازی سرویس اعلان‌ها.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // محل آماده‌سازی سیستم اعلان در نسخه‌های بعدی.
    _initialized = true;
  }

  /// نمایش یک اعلان ساده.
  ///
  /// در حال حاضر پیام را از طریق debugPrint ثبت می‌کند.
  /// بعداً می‌توان سیستم اعلان واقعی را به این متد متصل کرد.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    debugPrint(
      'Cyrus Tourist Notification: '
      '$title - $body'
      '${payload != null ? ' [$payload]' : ''}',
    );
  }

  /// ارسال اعلان خوش‌آمدگویی.
  Future<void> showWelcome({
    String languageCode = 'fa',
  }) async {
    switch (languageCode) {
      case 'en':
        await show(
          title: 'Cyrus Tourist',
          body: 'Welcome to Cyrus Tourist.',
        );
        break;

      case 'ar':
        await show(
          title: 'Cyrus Tourist',
          body: 'مرحباً بكم في سايروس توريست.',
        );
        break;

      case 'fa':
      default:
        await show(
          title: 'سایروس توریست',
          body: 'به سایروس توریست خوش آمدید.',
        );
        break;
    }
  }

  /// اعلان مربوط به یک جاذبه یا محتوای گردشگری.
  Future<void> showTourismUpdate({
    required String title,
    required String body,
    String? itemId,
  }) async {
    await show(
      title: title,
      body: body,
      payload: itemId,
    );
  }

  /// پاک کردن وضعیت سرویس.
  ///
  /// برای تست و راه‌اندازی مجدد سرویس استفاده می‌شود.
  Future<void> reset() async {
    _initialized = false;
  }
}
