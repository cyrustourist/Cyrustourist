import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show navigatorKey;
import '../pages/call_page.dart';
import 'badge_service.dart';
import 'call_session.dart';

/// هماهنگ‌کنندهٔ تماس صوتی: ثبت توکن FCM، دریافت تماس ورودی، باز کردن صفحهٔ تماس.
class CallService {
  CallService._();

  static final CallService instance = CallService._();

  static const String channelId = 'cyrus_calls';

  bool _inited = false;
  bool _pageOpen = false;
  String? _registeredToken;
  Timer? _watchTimer;
  int _watchRefs = 0;
  String? _lastShownCallId;

  bool get pageOpen => _pageOpen;
  void markPage(bool open) => _pageOpen = open;

  /// یک‌بار هنگام شروع برنامه (بعد از Firebase).
  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        channelId,
        'تماس ورودی',
        description: 'اعلان تماس صوتی ورودی',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));
    } catch (e) {
      debugPrint('call channel error: $e');
    }
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => registerToken(token: t));
    } catch (_) {}
    unawaited(registerToken());
  }

  /// ثبت توکن این گوشی روی ورکر. اگر کاربر هنوز پروفایل نساخته باشد ناموفق است
  /// و هنگام ورود به چت یا قبل از تماس دوباره تلاش می‌شود.
  Future<bool> registerToken({String? token}) async {
    try {
      final t = token ?? await FirebaseMessaging.instance.getToken();
      if (t == null || t.isEmpty) return false;
      if (t == _registeredToken) return true;
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/call/register-token', body: {
        'user_uid': uid,
        'fcm_token': t,
      });
      final ok = j?['success'] == true;
      if (ok) _registeredToken = t;
      return ok;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // تماس خروجی
  // ------------------------------------------------------------------
  Future<void> startOutgoing({required String toUid, required String name}) async {
    if (_pageOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    unawaited(registerToken());
    final session = CallSession.outgoing(peerUid: toUid, peerName: name);
    await nav.push(MaterialPageRoute(builder: (_) => CallPage(session: session)));
  }

  // ------------------------------------------------------------------
  // تماس ورودی
  // ------------------------------------------------------------------
  /// وقتی نوتیفیکیشن تماس رسید یا کاربر روی آن زد.
  Future<void> handlePush(Map<String, dynamic> data) async {
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
      _lastShownCallId = call.id;
      final nav = navigatorKey.currentState;
      if (nav == null || _pageOpen) return;
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
}
