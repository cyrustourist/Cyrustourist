import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show navigatorKey;
import '../pages/call_page.dart';
import '../pages/calls_page.dart';
import 'app_permissions.dart';
import 'badge_service.dart';
import 'call_session.dart';
import 'call_texts.dart';

/// دکمهٔ «رد» اعلان تماس وقتی اپ بسته/پس‌زمینه است (بدون باز کردن اپ).
@pragma('vm:entry-point')
void callNotificationBackgroundTap(NotificationResponse response) {
  if (response.actionId == CallService.actionDecline) {
    unawaited(CallService.declineFromPayload(response.payload));
  }
}

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

  static const String actionAnswer = 'call_answer';
  static const String actionDecline = 'call_decline';
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
  Timer? _fgWatch;
  bool _checking = false;
  int _pollFails = 0;
  int _pollSkip = 0;
  int _watchRefs = 0;
  String? _lastShownCallId;
  String? _lastNotifiedCallId;
  String? _autoAnswerId;
  DateTime? _autoAnswerAt;
  AppLifecycleState? _lifecycle;

  bool get _inForeground => (_lifecycle ?? WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) == AppLifecycleState.resumed;

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
    if (_inForeground) _startFgWatch();
    // اگر اپ بسته بود و کاربر روی دکمهٔ «پاسخ» اعلان زد، بعد از بالا آمدن اپ خودکار پاسخ داده شود
    try {
      final d = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
      final r = d?.notificationResponse;
      if (d != null && d.didNotificationLaunchApp && r?.actionId == actionAnswer) {
        _markAutoAnswer(r?.payload);
      }
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
    _lifecycle = state;
    // وقتی اپ جلوی صفحه است، تماس ورودی را هر ۳ ثانیه هم از ورکر می‌پرسیم (پشتیبان FCM که در ایران دیر می‌رسد)؛
    // در پس‌زمینه متوقف می‌شود تا باتری مصرف نشود.
    if (state == AppLifecycleState.resumed) {
      _startFgWatch();
    } else {
      _stopFgWatch();
    }
    if (state == AppLifecycleState.resumed) {
      // هر بار که برنامه باز می‌شود توکن دوباره (در صورت لزوم) ثبت می‌شود
      unawaited(registerToken().then((ok) {
        if (!ok && _registerRetry == null) _startRegisterRetry();
      }));
      if (_registeredToken != null) unawaited(checkIncoming());
    }
  }

  void _startFgWatch() {
    _fgWatch ??= Timer.periodic(const Duration(seconds: 3), (_) {
      if (_registeredToken == null) return;
      // اگر چند بار پشت‌سرهم ارتباط با سرور جواب نداد، فاصلهٔ پایش بیشتر می‌شود (حداکثر ~۳۰ ثانیه)
      if (_pollSkip > 0) {
        _pollSkip--;
        return;
      }
      unawaited(checkIncoming());
    });
  }

  void _stopFgWatch() {
    _fgWatch?.cancel();
    _fgWatch = null;
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
  // دکمه‌های اعلان تماس (پاسخ / رد)
  // ------------------------------------------------------------------
  static String? _callIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final m = jsonDecode(payload);
      if (m is Map && '${m['call_id'] ?? ''}'.isNotEmpty) return '${m['call_id']}';
    } catch (_) {}
    return null;
  }

  void _markAutoAnswer(String? payload) {
    final id = _callIdFromPayload(payload);
    if (id == null) return;
    _autoAnswerId = id;
    _autoAnswerAt = DateTime.now();
  }

  /// از onDidReceiveNotificationResponse صدا زده می‌شود؛ true یعنی اعلان از آنِ تماس بود و رسیدگی شد.
  static bool handleNotificationAction(NotificationResponse r) {
    if (r.actionId == actionAnswer) {
      instance._markAutoAnswer(r.payload);
      instance._lastShownCallId = null;
      unawaited(instance.checkIncoming());
      return true;
    }
    if (r.actionId == actionDecline) {
      unawaited(declineFromPayload(r.payload));
      return true;
    }
    return false;
  }

  static Future<void> declineFromPayload(String? payload) async {
    final id = _callIdFromPayload(payload);
    if (id == null) return;
    try {
      final uid = await BadgeService.userUid();
      await BadgeService.call('POST', '/api/call/action', body: {'user_uid': uid, 'call_id': id, 'action': 'decline'});
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // مجوز میکروفن (از قبل، تا وسط تماس پنجرهٔ سیستم معطل نکند)
  // ------------------------------------------------------------------
  static const String _micGrantedKey = 'call_mic_granted_v1';
  static const String _micAskedKey = 'call_mic_asked_v1';

  /// پنجرهٔ سیستم مجوز میکروفن را باز می‌کند. true = مجوز داده شد.
  /// دلیل آخرین شکست مجوز: '' | denied | blocked | error
  String _permIssue = '';
  String _mediaErr = '';

  /// مجوز را با پنجرهٔ بومی اندروید می‌گیرد و سپس میکروفن را واقعاً امتحان می‌کند.
  Future<bool> requestMicNow() async {
    _permIssue = '';
    _mediaErr = '';
    final perm = await AppPermissions.request(['mic']);
    if (perm != null && perm['mic'] != 'granted') {
      _permIssue = perm['mic'] == 'blocked' ? 'blocked' : 'denied';
      return false;
    }
    try {
      final stream = await rtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      for (final t in stream.getTracks()) {
        await t.stop();
      }
      await stream.dispose();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_micGrantedKey, true);
      return true;
    } catch (e) {
      _permIssue = 'error';
      _mediaErr = '$e'.replaceAll('\n', ' ');
      if (_mediaErr.length > 120) _mediaErr = _mediaErr.substring(0, 120);
      return false;
    }
  }

  Future<bool> _micKnownGranted() async {
    // وضعیت واقعی مجوز از اندروید خوانده می‌شود (کاربر ممکن است بعداً از تنظیمات گرفته باشد)
    final real = await AppPermissions.isGranted(['mic']);
    if (real != null) return real;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_micGrantedKey) == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _micExplain(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(CT.t('mic_title')),
        content: Text(CT.t('mic_body'), style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(CT.t('cancel'))),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text(CT.t('mic_allow'))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _micDeniedDialog(BuildContext ctx, {bool video = false}) async {
    final String text;
    switch (_permIssue) {
      case 'blocked':
        text = CT.t('perm_blocked');
        break;
      case 'error':
        text = CT.t('media_error', {'e': _mediaErr});
        break;
      default:
        text = CT.t('perm_denied_now');
    }
    await showDialog<void>(
      context: ctx,
      builder: (c) => AlertDialog(
        content: Text(text, style: const TextStyle(height: 1.7)),
        actions: [
          if (_permIssue == 'blocked')
            TextButton(
              onPressed: () {
                Navigator.of(c).pop();
                AppPermissions.openSettings();
              },
              child: Text(CT.t('open_settings')),
            ),
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  static const String _camGrantedKey = 'call_cam_granted_v1';

  /// قبل از تماس تصویری: مجوز دوربین و میکروفن را با توضیح می‌گیرد. false = کاربر مجوز نداد.
  Future<bool> ensureCamForCall(BuildContext ctx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final real = await AppPermissions.isGranted(['mic', 'camera']);
      if (real == true) return true;
      if (real == null && prefs.getBool(_camGrantedKey) == true) return true;
      if (!ctx.mounted) return false;
      final ok = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: Text(CT.t('cam_title')),
          content: Text(CT.t('cam_body'), style: const TextStyle(height: 1.7)),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(CT.t('cancel'))),
            TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text(CT.t('mic_allow'))),
          ],
        ),
      );
      if (ok != true) return false;
      _permIssue = '';
      _mediaErr = '';
      final perm = await AppPermissions.request(['mic', 'camera']);
      if (perm != null && (perm['mic'] != 'granted' || perm['camera'] != 'granted')) {
        _permIssue = (perm['mic'] == 'blocked' || perm['camera'] == 'blocked') ? 'blocked' : 'denied';
        if (ctx.mounted) await _micDeniedDialog(ctx, video: true);
        return false;
      }
      try {
        final stream = await rtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
        for (final t in stream.getTracks()) {
          await t.stop();
        }
        await stream.dispose();
        await prefs.setBool(_camGrantedKey, true);
        await prefs.setBool(_micGrantedKey, true);
        return true;
      } catch (e) {
        _permIssue = 'error';
        _mediaErr = '$e'.replaceAll('\n', ' ');
        if (_mediaErr.length > 120) _mediaErr = _mediaErr.substring(0, 120);
        if (ctx.mounted) await _micDeniedDialog(ctx, video: true);
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// قبل از تماس خروجی: اگر مجوز هنوز نیست توضیح بده و بگیر. false = کاربر مجوز نداد (تماس شروع نشود).
  Future<bool> ensureMicForCall(BuildContext ctx) async {
    if (await _micKnownGranted()) return true;
    if (!ctx.mounted) return false;
    if (!await _micExplain(ctx)) return false;
    final ok = await requestMicNow();
    if (!ok && ctx.mounted) await _micDeniedDialog(ctx);
    return ok;
  }

  /// هنگام اولین ورود به صفحهٔ «تماس‌ها»: فقط یک‌بار توضیح بده و مجوز را بگیر (تا اولین تماس معطل نشود).
  Future<void> promptMicOnce(BuildContext ctx) async {
    try {
      if (await _micKnownGranted()) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_micAskedKey) == true) return;
      await prefs.setBool(_micAskedKey, true);
      if (!ctx.mounted) return;
      if (!await _micExplain(ctx)) return;
      final ok = await requestMicNow();
      if (!ok && ctx.mounted) await _micDeniedDialog(ctx);
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // تماس خروجی
  // ------------------------------------------------------------------
  Future<void> startOutgoing({
    required String toUid,
    required String name,
    bool isFriend = false,
    bool hasPhoto = true,
    bool video = false,
  }) async {
    if (_pageOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    // اگر تماس صوتی از پنل مدیریت خاموش است، همین‌جا (قبل از باز شدن صفحهٔ تماس و درخواست میکروفن) پیام را نشان بده
    final off = await _disabledMessage(video: video);
    if (off != null) {
      final ctx = navigatorKey.currentState?.overlay?.context;
      if (ctx != null && ctx.mounted) {
        await showDialog<void>(
          context: ctx,
          builder: (c) => AlertDialog(
            content: Text(off, style: const TextStyle(height: 1.7)),
            actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
          ),
        );
      }
      return;
    }
    final mctx = navigatorKey.currentState?.overlay?.context;
    if (mctx != null && mctx.mounted) {
      if (video ? !await ensureCamForCall(mctx) : !await ensureMicForCall(mctx)) return;
    }
    unawaited(registerToken());
    final session = CallSession.outgoing(peerUid: toUid, peerName: name, isFriend: isFriend, hasPhoto: hasPhoto, isVideo: video);
    await nav.push(MaterialPageRoute(builder: (_) => CallPage(session: session)));
  }

  /// پیام قبل از شروع تماس:
  ///  - ورکر جواب داد و تماس (صوتی/تصویری) روشن است ← null (تماس شروع می‌شود، هیچ پیامی نشان داده نمی‌شود)
  ///  - ورکر جواب داد و از پنل خاموش شده ← همان پیامی که ورکر فرستاده
  ///  - ورکر جواب نداد (قطع/در دسترس نیست) ← متن زیبای «کارگران در حال کارند»
  Future<String?> _disabledMessage({bool video = false}) async {
    Map<String, dynamic>? j;
    try {
      final uid = await BadgeService.userUid();
      j = await BadgeService.call('GET', '/api/call/config', query: {'user_uid': uid}, timeout: const Duration(seconds: 6));
    } catch (_) {
      j = null;
    }
    if (j == null) return CT.t('server_down');
    final f = j['features'];
    if (f is! Map) {
      // ورکر جواب داد ولی بدون تنظیمات (ورکر قدیمی) ← تماس را امتحان کن
      return j['success'] == false && '${j['error'] ?? ''}' == 'calls_disabled'
          ? ('${j['message'] ?? ''}'.trim().isNotEmpty ? '${j['message']}'.trim() : CT.t('server_down'))
          : null;
    }
    if (video) {
      if (f['video_enabled'] == false) {
        final m = '${f['video_message'] ?? ''}'.trim();
        return m.isNotEmpty ? m : CT.t('video_soon');
      }
    } else if (f['voice_enabled'] == false) {
      final m = '${f['message'] ?? ''}'.trim();
      return m.isNotEmpty ? m : CT.t('updating');
    }
    return null;
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
    if (_pageOpen || _checking) return;
    _checking = true;
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('GET', '/api/call/incoming', query: {'user_uid': uid}, timeout: const Duration(seconds: 5));
      if (j == null) {
        _pollFails++;
        _pollSkip = _pollFails > 9 ? 9 : _pollFails;
      } else {
        _pollFails = 0;
        _pollSkip = 0;
      }
      final call = IncomingCall.fromJson(j?['call']);
      if (call == null) return;
      if (_lastShownCallId == call.id) return;
      // اپ در پس‌زمینه است (مثلاً پایش ۵ثانیه‌ای چت): صفحهٔ تماس پشت صحنه باز می‌شد و فقط صدای زنگ می‌آمد.
      // به‌جای آن اعلان تمام‌صفحه نشان بده؛ با زدن اعلان یا برگشتن به اپ، صفحهٔ تماس جلو می‌آید.
      final autoAt = _autoAnswerAt;
      final autoAnswer = _autoAnswerId == call.id && autoAt != null && DateTime.now().difference(autoAt) < const Duration(seconds: 60);
      if (!_inForeground && !autoAnswer) {
        if (_lastNotifiedCallId != call.id) {
          _lastNotifiedCallId = call.id;
          await _showIncomingNotification({
            'type': 'call',
            'call_id': call.id,
            'from_name': call.fromName,
            'title': CT.t('incoming'),
            'body': call.fromName,
          }, initializePlugin: false);
        }
        return;
      }
      final nav = navigatorKey.currentState;
      if (nav == null || _pageOpen) return;
      _lastShownCallId = call.id;
      unawaited(CallSession.prefetchIce());
      final session = CallSession.incoming(call);
      if (autoAnswer) {
        _autoAnswerId = null;
        _autoAnswerAt = null;
      }
      await nav.push(MaterialPageRoute(builder: (_) => CallPage(session: session, autoAccept: autoAnswer)));
    } catch (e) {
      debugPrint('incoming check error: $e');
    } finally {
      _checking = false;
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
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
        ),
        onDidReceiveBackgroundNotificationResponse: callNotificationBackgroundTap,
      );
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
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                actionDecline,
                CT.t('decline_btn'),
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                actionAnswer,
                CT.t('accept'),
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
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
