import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cyrus_announcement.dart';
import 'cache_service.dart';

/// سرویس مرکزی اعلان‌های سایروس توریست.
///
/// این سرویس دو مسئولیت دارد:
/// 1) دریافت لیست اعلان‌ها (Announcements) از API سرور و نگه‌داشتن
///    وضعیت «خوانده‌نشده» برای نمایش بج روی کلید ۸ (حساب کاربری).
/// 2) لایه‌ی نمایش اعلان محلی ساده (show/showWelcome/...) که پیش‌تر
///    در پروژه وجود داشت و بدون تغییر باقی مانده تا چیزی نشکند.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// آدرس API اعلان‌های سایروس توریست.
  static const String _endpoint =
      'https://cyrus-tourist-api.cyrustourist.workers.dev/notifications';

  /// کلید ذخیره‌سازی آخرین شناسه‌ی دیده‌شده (برای شمارش خوانده‌نشده‌ها).
  static const String _lastSeenIdKey = 'cyrus_last_seen_notification_id';

  /// کلید ذخیره‌سازی شناسه‌ی پیام‌هایی که کاربر حذف کرده است.
  ///
  /// حذف فقط محلی (روی همان دستگاه) است؛ پیام از سرور پاک نمی‌شود،
  /// فقط دیگر برای این کاربر نمایش داده نمی‌شود.
  static const String _dismissedIdsKey = 'cyrus_dismissed_notification_ids';

  /// کلید ذخیره‌سازی آخرین تعداد خوانده‌نشده‌ای که برایش افکت صدا
  /// پخش شده (برای جلوگیری از پخش تکراری صدا برای همان آگهی‌ها).
  static const String _lastNotifiedCountKey =
      'cyrus_last_notified_unread_count';

  /// کلید ذخیره‌سازی روشن/خاموش بودن افکت صدای آگهی جدید.
  static const String _soundEnabledKey =
      'cyrus_announcement_sound_enabled';

  // ==========================================================
  // بخش ۱: دریافت اعلان‌ها از سرور
  // ==========================================================

  /// دریافت لیست اعلان‌های فعال از سرور، جدیدترین در ابتدا.
  ///
  /// پیام‌هایی که کاربر قبلاً حذف کرده (به‌صورت محلی) از نتیجه
  /// حذف می‌شوند. در صورت هرگونه خطای شبکه/پارس، لیست خالی
  /// برمی‌گرداند تا رابط کاربری هیچ‌گاه کرش نکند.
  Future<List<CyrusAnnouncement>> fetchAnnouncements() async {
    final client = HttpClient();

    try {
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(_endpoint);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();

      if (response.statusCode != 200) {
        return const [];
      }

      final body = await response.transform(const Utf8Decoder()).join();
      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        return const [];
      }

      final rawList = decoded['data'];

      if (rawList is! List) {
        return const [];
      }

      final dismissedIds = await _getDismissedIds();

      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(CyrusAnnouncement.fromJson)
          .where((item) => item.isActive)
          .where((item) => !dismissedIds.contains(item.id))
          .toList();

      items.sort((a, b) => b.id.compareTo(a.id));

      return items;
    } catch (error) {
      debugPrint('Cyrus Tourist Notification fetch error: $error');
      return const [];
    } finally {
      client.close();
    }
  }

  /// تعداد اعلان‌های خوانده‌نشده (نسبت به آخرین شناسه‌ی دیده‌شده).
  ///
  /// برای نمایش بج قرمز روی گزینه‌ی «اعلان‌ها» در کلید ۸ استفاده می‌شود.
  Future<int> getUnreadCount() async {
    final items = await fetchAnnouncements();

    if (items.isEmpty) {
      return 0;
    }

    final lastSeenId = await CacheService.instance.getInt(_lastSeenIdKey) ?? 0;

    return items.where((item) => item.id > lastSeenId).length;
  }

  /// علامت‌گذاری همه‌ی اعلان‌های فعلی به‌عنوان «خوانده‌شده».
  ///
  /// معمولاً هنگام باز شدن صفحه‌ی لیست اعلان‌ها فراخوانی می‌شود.
  Future<void> markAllAsRead(List<CyrusAnnouncement> items) async {
    if (items.isEmpty) {
      return;
    }

    final maxId = items.map((item) => item.id).reduce(
          (a, b) => a > b ? a : b,
        );

    final currentLastSeen =
        await CacheService.instance.getInt(_lastSeenIdKey) ?? 0;

    if (maxId > currentLastSeen) {
      await CacheService.instance.setInt(_lastSeenIdKey, maxId);
    }

    // چون همه چیز خوانده شد، شمارشگر صدا هم صفر می‌شود تا آگهی‌های
    // جدیدِ بعدی دوباره بتوانند افکت صدا پخش کنند.
    await CacheService.instance.setInt(_lastNotifiedCountKey, 0);
  }

  // ==========================================================
  // افکت صدای آگهی جدید
  // ==========================================================

  /// آیا افکت صدای آگهی جدید در تنظیمات فعال است؟ پیش‌فرض: فعال.
  Future<bool> isAnnouncementSoundEnabled() async {
    final value = await CacheService.instance.getInt(_soundEnabledKey);
    return value == null || value == 1;
  }

  /// روشن/خاموش کردن افکت صدای آگهی جدید.
  Future<void> setAnnouncementSoundEnabled(bool enabled) async {
    await CacheService.instance.setInt(_soundEnabledKey, enabled ? 1 : 0);
  }

  /// اگر از آخرین بار، تعداد آگهی‌های خوانده‌نشده افزایش یافته باشد
  /// (یعنی آگهی جدیدی رسیده) و افکت صدا در تنظیمات فعال باشد، یک
  /// افکت صدای کوتاه پخش می‌کند.
  ///
  /// نکته: چون فعلاً پکیج پخش صدای اختصاصی (مثل audioplayers) در
  /// پروژه نصب نیست، از افکت صدای سیستمی خودِ فلاتر استفاده می‌شود.
  /// برای صدای اختصاصی/برندشده، باید یک فایل صوتی به پروژه اضافه و
  /// پکیج مربوطه نصب شود.
  Future<void> maybePlayNewAnnouncementSound() async {
    final unread = await getUnreadCount();

    final lastNotified =
        await CacheService.instance.getInt(_lastNotifiedCountKey) ?? 0;

    if (unread > lastNotified) {
      await CacheService.instance.setInt(_lastNotifiedCountKey, unread);

      final soundOn = await isAnnouncementSoundEnabled();

      if (soundOn) {
        unawaited(SystemSound.play(SystemSoundType.alert));
      }
    } else if (unread < lastNotified) {
      await CacheService.instance.setInt(_lastNotifiedCountKey, unread);
    }
  }

  // ==========================================================
  // حذف محلی یک پیام (طبق درخواست: کاربر بتواند پیام را حذف کند)
  // ==========================================================

  /// حذف یک پیام به‌صورت محلی؛ از این پس در لیست نمایش داده نمی‌شود.
  Future<void> dismiss(int id) async {
    final ids = await _getDismissedIds();

    if (ids.add(id)) {
      await _saveDismissedIds(ids);
    }
  }

  /// خواندن شناسه‌ی پیام‌های حذف‌شده از حافظه‌ی محلی دستگاه.
  Future<Set<int>> _getDismissedIds() async {
    final raw = await CacheService.instance.getJson(_dismissedIdsKey);

    if (raw is! List) {
      return <int>{};
    }

    return raw.map((value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? -1;
    }).where((id) => id >= 0).toSet();
  }

  /// ذخیره‌ی شناسه‌ی پیام‌های حذف‌شده در حافظه‌ی محلی دستگاه.
  Future<void> _saveDismissedIds(Set<int> ids) async {
    await CacheService.instance.setJson(
      _dismissedIdsKey,
      ids.toList(),
    );
  }

  // ==========================================================
  // بخش ۲: لایه‌ی نمایش اعلان محلی (بدون تغییر نسبت به قبل)
  // ==========================================================

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
