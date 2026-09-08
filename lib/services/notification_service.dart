import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show navigatorKey;
import '../core/language/menu_translations.dart';
import '../models/cyrus_announcement.dart';
import '../pages/announcements_page.dart';
import 'cache_service.dart';

/// سرویس مرکزی اعلان‌های سایروس توریست.
///
/// این سرویس چند مسئولیت دارد:
/// 1) دریافت لیست اعلان‌ها (Announcements) از API سرور و نگه‌داشتن
///    وضعیت «خوانده‌نشده» برای نمایش بج روی کلید ۸ (حساب کاربری).
/// 2) نمایش اعلان واقعی سیستم اندروید (نوار بالا، صدا، لرزش، آیکون)
///    از طریق flutter_local_notifications.
/// 3) اتصال به Firebase Cloud Messaging (FCM) برای دریافت پوش نوتیفیکیشن
///    حتی زمانی که اپ بسته یا در پس‌زمینه است، و باز کردن صفحه‌ی
///    مربوطه با لمس اعلان.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// آدرس API اعلان‌های سایروس توریست.
  static const String _endpoint =
      'https://cyrus-tourist-api.cyrustourist.workers.dev/notifications';

  /// کلید ذخیره‌سازی آخرین شناسه‌ی دیده‌شده (برای شمارش خوانده‌نشده‌ها).
  static const String _lastSeenIdKey = 'cyrus_last_seen_notification_id';

  /// کلید ذخیره‌سازی شناسه‌ی پیام‌هایی که کاربر حذف کرده است.
  static const String _dismissedIdsKey = 'cyrus_dismissed_notification_ids';

  /// کلید ذخیره‌سازی آخرین تعداد خوانده‌نشده‌ای که برایش افکت صدا
  /// پخش شده (برای جلوگیری از پخش تکراری صدا برای همان آگهی‌ها).
  static const String _lastNotifiedCountKey =
      'cyrus_last_notified_unread_count';

  /// کلید ذخیره‌سازی روشن/خاموش بودن افکت صدای آگهی جدید.
  static const String _soundEnabledKey =
      'cyrus_announcement_sound_enabled';

  // ==========================================================
  // تنظیمات کانال اعلان اندروید
  // ==========================================================

  static const String _channelId = 'cyrus_default_channel';
  static const String _channelName = 'Cyrus Tourist';
  static const String _channelDescription =
      'اعلان‌ها و پیام‌های سایروس توریست';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ==========================================================
  // بخش ۱: دریافت اعلان‌ها از سرور (بدون تغییر)
  // ==========================================================

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

  Future<int> getUnreadCount() async {
    final items = await fetchAnnouncements();

    if (items.isEmpty) {
      return 0;
    }

    final lastSeenId = await CacheService.instance.getInt(_lastSeenIdKey) ?? 0;

    return items.where((item) => item.id > lastSeenId).length;
  }

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

    await CacheService.instance.setInt(_lastNotifiedCountKey, 0);
  }

  // ==========================================================
  // افکت صدای آگهی جدید (بدون تغییر)
  // ==========================================================

  Future<bool> isAnnouncementSoundEnabled() async {
    final value = await CacheService.instance.getInt(_soundEnabledKey);
    return value == null || value == 1;
  }

  Future<void> setAnnouncementSoundEnabled(bool enabled) async {
    await CacheService.instance.setInt(_soundEnabledKey, enabled ? 1 : 0);
  }

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
  // حذف محلی یک پیام (بدون تغییر)
  // ==========================================================

  Future<void> dismiss(int id) async {
    final ids = await _getDismissedIds();

    if (ids.add(id)) {
      await _saveDismissedIds(ids);
    }
  }

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

  Future<void> _saveDismissedIds(Set<int> ids) async {
    await CacheService.instance.setJson(
      _dismissedIdsKey,
      ids.toList(),
    );
  }

  // ==========================================================
  // بخش ۲: نمایش اعلان واقعی سیستم + اتصال FCM
  // ==========================================================

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// آماده‌سازی سرویس اعلان‌ها: کانال اندروید را می‌سازد، مجوز
  /// نوتیفیکیشن را می‌گیرد و به پیام‌های FCM گوش می‌دهد.
  ///
  /// این متد باید بعد از Firebase.initializeApp() در main() صدا زده شود.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleTap(response.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();

    // مجوز اعلان از سمت FCM (روی iOS اجباری است؛ روی اندروید ۱۳+ هم
    // لازم است و از طریق پلاگین بالا هم گرفته شد، این خط بی‌ضرر است).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // پیامی که اپ را از حالت killed باز کرده (کاربر روی اعلان زده
    // در حالی که اپ کاملاً بسته بوده است).
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleTap(jsonEncode(initialMessage.data));
    }

    // پیامی که وقتی اپ در پس‌زمینه بوده (نه بسته) با لمس اعلان باز شده.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTap(jsonEncode(message.data));
    });

    // پیامی که وقتی اپ باز/فعال است می‌رسد. اندروید در این حالت
    // به‌صورت پیش‌فرض چیزی در نوار بالا نشان نمی‌دهد، پس خودمان با
    // flutter_local_notifications نمایشش می‌دهیم.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _initialized = true;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? 'Cyrus Tourist';
    final body = notification?.body ?? '';

    if (body.isEmpty) {
      return;
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// با لمس اعلان (چه در حالت پس‌زمینه چه killed چه foreground)،
  /// این متد صفحه‌ی مناسب را باز می‌کند.
  ///
  /// سرور باید در payload پوش، کلید "screen" را بفرستد. فعلاً فقط
  /// "announcements" پشتیبانی می‌شود (باز شدن صفحه‌ی لیست اعلان‌ها)؛
  /// اگر screen نامشخص/خالی باشد، فقط خودِ اپ باز می‌شود.
  void _handleTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final data = jsonDecode(payload);

      if (data is! Map<String, dynamic>) {
        return;
      }

      final screen = data['screen'];

      if (screen == 'announcements') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AnnouncementsPage(
              languageCode: MenuLanguage.current,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Cyrus Tourist Notification tap parse error: $error');
    }
  }

  /// نمایش یک اعلان محلی ساده (برای استفاده‌ی داخلی اپ، مثل
  /// showWelcome/showTourismUpdate پایین‌تر).
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: payload,
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

  /// پاک کردن وضعیت سرویس (برای تست).
  Future<void> reset() async {
    _initialized = false;
  }
}
