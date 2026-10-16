import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show navigatorKey;
import '../pages/call_page.dart';
import '../pages/calls_page.dart';
import 'badge_service.dart';
import 'call_session.dart';
import 'call_texts.dart';

/// هماهنگ‌کنندهٔ تماس صوتی: ثبت توکن FCM، دریافت تماس ورودی، باز کردن صفحهٔ تماس،
/// اعلان تمام‌صفحه روی قفل گوشی و سرویس پیش‌زمینه هنگام تماس.
class CallService with WidgetsBindingObserver {
  CallService._();

  static final CallService instance = CallService._();

  // v2: کانال جدید با آهنگ زنگ سیستم (تنظیمات کانال بعد از ساخته شدن قابل تغییر نیست)
  static const String channelId = 'cyrus_calls_v2';
  static const String _oldChannelId = 'cyrus_calls';
  static const String _activeChannelId = 'cyrus_call_active';
  static const String _msgChannelId = 'cyrus_call_msgs';

  static const int _incomingNotifId = 7001;
  static const int _fgNotifId = 7002;
  static const int _msgNotifId = 7003;

  static const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
    channelId,
    'تماس ورودی',
    description: 'اعلان تماس صوتی ورودی',
    importance: Importance.max,
    playSound: true,
    sound: UriAndroidNotificationSound('content://settings/system/ringtone'),
    audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    enableVibration: true,
  );

  bool _inited = false;
  bool _pageOpen = false;
  String? _registeredToken;
  DateTime? _registeredAt;
  Timer? _registerRetry;
  Timer? _watchTimer;
  int _watchRefs = 0;
  String? _lastShownCallId;

  bool get pageOpen => _pageOpen;

  void markPage(bool open) {
    _pageOpen = open;
    if (open) {
      // اعلان زنگ دیگر لازم نیست
      unawaited(FlutterLocalNotificationsPlugin().cancel(_incomingNotifId).catchError((Object _) {}));
    }
  }

  /// یک‌بار هنگام شروع برنامه (بعد از Firebase).
  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        await android?.deleteNotificationChannel(_oldChannelId);
      } catch (_) {}
      await android?.createNotificationChannel(_callChannel);
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _activeChannelId,
        'تماس در جریان',
        description: 'نمایش تماس صوتی در حال انجام',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _msgChannelId,
        'پیام رد تماس',
        description: 'پیام کوتاهی که طرف مقابل هنگام رد تماس می‌فرستد',
        importance: Importance.high,
      ));
    } catch (e) {
      debugPrint('call channel error: $e');
    }
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => registerToken(token: t));
    } catch (_) {}
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    // اگر اپ با اعلان تمام‌صفحهٔ تماس باز شده باشد، بعد از ثبت توکن تماس در حال زنگ را نشان می‌دهیم
    unawaited(registerToken().then((ok) {
      if (ok) {
        unawaited(CallSession.prefetchIce());
        Future<void>.delayed(const Duration(milliseconds: 1500), checkIncoming);
      } else {
        _startRegisterRetry();
      }
    }));
  }

  /// اگر ثبت توکن در شروع برنامه نشد (اینترنت قطع بود یا هنوز پروفایل ساخته نشده بود)،
  /// هر ۳۰ ثانیه تا ۲۰ بار دوباره تلاش می‌کند؛ بدون ثبت توکن، گوشی هرگز زنگ نمی‌خورد.
  void _startRegisterRetry() {
    _registerRetry?.cancel();
    var tries = 0;
    _registerRetry = Timer.periodic(const Duration(seconds: 30), (t) async {
      tries++;
      final ok = await registerToken();
      if (ok || tries >= 20) {
        t.cancel();
        _registerRetry = null;
        if (ok) unawaited(CallSession.prefetchIce());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // هر بار که برنامه باز می‌شود توکن دوباره (در صورت لزوم) ثبت می‌شود
      unawaited(registerToken().then((ok) {
        if (!ok && _registerRetry == null) _startRegisterRetry();
      }));
      if (_registeredToken != null) unawaited(checkIncoming());
    }
  }

  /// ثبت توکن این گوشی روی ورکر. اگر کاربر هنوز پروفایل نساخته باشد ناموفق است
  /// و هنگام ورود به چت یا قبل از تماس دوباره تلاش می‌شود.
  Future<bool> registerToken({String? token}) async {
    try {
      final t = token ?? await FirebaseMessaging.instance.getToken();
      if (t == null || t.isEmpty) return false;
      // اگر همین توکن کمتر از ۳۰ دقیقه پیش ثبت شده، دوباره نمی‌فرستیم
      final at = _registeredAt;
      if (t == _registeredToken && at != null && DateTime.now().difference(at) < const Duration(minutes: 30)) {
        return true;
      }
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/call/register-token', body: {
        'user_uid': uid,
        'fcm_token': t,
      });
      final ok = j?['success'] == true;
      if (ok) {
        _registeredToken = t;
        _registeredAt = DateTime.now();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // تماس خروجی
  // ------------------------------------------------------------------
  Future<void> startOutgoing({
    required String toUid,
    required String name,
    bool isFriend = false,
    bool hasPhoto = true,
  }) async {
    if (_pageOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    unawaited(registerToken());
    final session = CallSession.outgoing(peerUid: toUid, peerName: name, isFriend: isFriend, hasPhoto: hasPhoto);
    await nav.push(MaterialPageRoute(builder: (_) => CallPage(session: session)));
  }

  // ------------------------------------------------------------------
  // تماس ورودی
  // ------------------------------------------------------------------
  /// وقتی پیام FCM تماس رسید یا کاربر روی اعلان زد.
  Future<void> handlePush(Map<String, dynamic> data) async {
    if (data['type'] == 'call_msg') {
      // اعلان «پیام رد تماس» زده شد: صفحهٔ تماس‌ها را نشان بده
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const CallsPage()));
      return;
    }
    if (data['type'] != 'call') return;
    await checkIncoming();
  }

  Future<void> checkIncoming() async {
    if (_pageOpen) return;
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('GET', '/api/call/incoming', query: {'user_uid': uid});
      final call = IncomingCall.fromJson(j?['call']);
      if (call == null) return;
      if (_lastShownCallId == call.id) return;
      final nav = navigatorKey.currentState;
      if (nav == null || _pageOpen) return;
      _lastShownCallId = call.id;
      unawaited(CallSession.prefetchIce());
      final session = CallSession.incoming(call);
      await nav.push(MaterialPageRoute(builder: (_) => CallPage(session: session)));
    } catch (e) {
      debugPrint('incoming check error: $e');
    }
  }

  /// پایش تماس ورودی فقط وقتی صفحهٔ چت باز است (پشتیبان FCM؛ مصرف کم).
  void startWatch() {
    _watchRefs++;
    unawaited(registerToken());
    _watchTimer ??= Timer.periodic(const Duration(seconds: 5), (_) => checkIncoming());
  }

  void stopWatch() {
    if (_watchRefs > 0) _watchRefs--;
    if (_watchRefs == 0) {
      _watchTimer?.cancel();
      _watchTimer = null;
    }
  }

  // ------------------------------------------------------------------
  // پیام‌های data-only از ورکر
  // ------------------------------------------------------------------
  /// وقتی اپ در پس‌زمینه/بسته است (از main.dart فراخوانی می‌شود، داخل isolate پس‌زمینه).
  static Future<void> handleBackgroundData(Map<String, dynamic> data) async {
    final type = data['type'];
    if (type == 'call') {
      await _showIncomingNotification(data, initializePlugin: true);
    } else if (type == 'call_msg') {
      await _showMessageNotification(data, initializePlugin: true);
    }
  }

  /// وقتی اپ باز است (onMessage).
  static Future<void> handleForegroundData(Map<String, dynamic> data) async {
    final type = data['type'];
    if (type == 'call') {
      unawaited(instance.handlePush(data));
    } else if (type == 'call_msg') {
      // اگر همین الان روی صفحهٔ تماس هستیم، پیام از خود صفحه دیده می‌شود
      if (!instance.pageOpen) {
        await _showMessageNotification(data, initializePlugin: false);
      }
    }
  }

  static Future<FlutterLocalNotificationsPlugin> _plugin(bool initializePlugin) async {
    final plugin = FlutterLocalNotificationsPlugin();
    if (initializePlugin) {
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
      ));
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_callChannel);
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _msgChannelId,
        'پیام رد تماس',
        description: 'پیام کوتاهی که طرف مقابل هنگام رد تماس می‌فرستد',
        importance: Importance.high,
      ));
    }
    return plugin;
  }

  static Future<void> _showIncomingNotification(Map<String, dynamic> data, {required bool initializePlugin}) async {
    try {
      final plugin = await _plugin(initializePlugin);
      final title = '${data['title'] ?? ''}'.isNotEmpty ? '${data['title']}' : CT.t('incoming');
      final body = '${data['body'] ?? data['from_name'] ?? ''}';
      await plugin.show(
        _incomingNotifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'تماس ورودی',
            channelDescription: 'اعلان تماس صوتی ورودی',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: true,
            timeoutAfter: 45000,
            visibility: NotificationVisibility.public,
            icon: '@drawable/ic_stat_notify',
            playSound: true,
            sound: UriAndroidNotificationSound('content://settings/system/ringtone'),
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            enableVibration: true,
            // FLAG_INSISTENT (۴): زنگ تا جواب دادن/رد کردن/۴۵ ثانیه تکرار می‌شود (فقط یک‌بار پخش نشود)
            additionalFlags: Int32List.fromList(<int>[4]),
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('incoming call notification error: $e');
    }
  }

  static Future<void> _showMessageNotification(Map<String, dynamic> data, {required bool initializePlugin}) async {
    try {
      final plugin = await _plugin(initializePlugin);
      final name = '${data['from_name'] ?? ''}';
      final key = '${data['msg_key'] ?? ''}';
      final text = key.isNotEmpty ? CT.msg(key) : '${data['body'] ?? ''}';
      if (text.isEmpty) return;
      await plugin.show(
        _msgNotifId,
        CT.t('missed_msg_title', {'name': name}),
        text,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _msgChannelId,
            'پیام رد تماس',
            channelDescription: 'پیام کوتاهی که طرف مقابل هنگام رد تماس می‌فرستد',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('call message notification error: $e');
    }
  }

  // ------------------------------------------------------------------
  // سرویس پیش‌زمینه (میکروفن) هنگام تماس
  // ------------------------------------------------------------------
  static Future<void> startForegroundCall(String peerName) async {
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.startForegroundService(
        _fgNotifId,
        CT.t('ongoing_title'),
        peerName,
        notificationDetails: const AndroidNotificationDetails(
          _activeChannelId,
          'تماس در جریان',
          channelDescription: 'نمایش تماس صوتی در حال انجام',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          playSound: false,
          enableVibration: false,
          icon: '@drawable/ic_stat_notify',
          category: AndroidNotificationCategory.call,
        ),
        foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeMicrophone},
      );
    } catch (e) {
      debugPrint('foreground call start error: $e');
    }
  }

  static Future<void> stopForegroundCall() async {
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.stopForegroundService();
    } catch (e) {
      debugPrint('foreground call stop error: $e');
    }
  }
}
