import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as location;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/language/menu_translations.dart';
import 'user_profile_service.dart';

/// پیام شبکه‌ی آفلاین
class OfflineMsg {
  OfflineMsg({required this.id, required this.uid, required this.name, required this.text, required this.ts, required this.mine, this.room = '', this.imagePath, this.audioPath, this.audioSecs = 0});
  final String id;
  final String uid;
  final String name;
  final String text;
  final int ts;
  final bool mine;

  /// اتاق پیام: '' = شبکه‌ی عمومی، 'g<id>' = گروه، 'd<uidA>_<uidB>' = گفتگوی شخصی.
  final String room;

  /// مسیر فایل عکس روی همین گوشی (اگر پیام عکس باشد)
  final String? imagePath;

  /// مسیر فایل صدا و طول آن به ثانیه (اگر پیام صوتی باشد)
  final String? audioPath;
  final int audioSecs;
}

/// کوچک‌کردن عکس برای شبکه (حداکثر ۱۲۸۰ پیکسل) تا رله‌ی چندپرشی سنگین نشود؛ در isolate جدا اجرا می‌شود.
bool _shrinkJob(List<String> a) {
  try {
    final im = img.decodeImage(File(a[0]).readAsBytesSync());
    if (im == null) return false;
    var r = img.bakeOrientation(im);
    if (r.width > 1280 || r.height > 1280) {
      r = r.width >= r.height ? img.copyResize(r, width: 1280) : img.copyResize(r, height: 1280);
    }
    File(a[1]).writeAsBytesSync(img.encodeJpg(r, quality: 80));
    return true;
  } catch (_) {
    return false;
  }
}

class OfflinePeer {
  OfflinePeer(this.endpointId, this.uid, this.name);
  final String endpointId;
  final String uid;
  final String name;
}

/// یک نفر در شبکه (وصل مستقیم یا از راه گوشی‌های واسط). hops = تعداد اتصال‌ها تا او؛ ۱ یعنی مستقیم.
class OfflinePerson {
  OfflinePerson({required this.uid, required this.name, required this.hops});
  final String uid;
  final String name;
  final int hops;
  bool get direct => hops <= 1;
}

class _Known {
  _Known(this.uid, this.name, this.ts, this.hops, this.seenAt, this.raw);
  final String uid;
  final String name;
  final int ts;
  final int hops;
  final int seenAt;
  final Map<String, dynamic> raw;
}

/// شبکه‌ی آفلاین گردشگران (بدون اینترنت) با Nearby Connections.
/// استراتژی P2P_CLUSTER: هر گوشی هم تبلیغ می‌کند هم جستجو؛ پیام‌ها بین گوشی‌ها
/// پاس داده می‌شوند (relay) تا گروه بزرگ‌تر از اتصال مستقیم هم پیام را بگیرد.
const MethodChannel _netChannel = MethodChannel('cyrus/net');

Future<void> _netLock(bool on) async {
  try {
    await _netChannel.invokeMethod<bool>('lock', <String, dynamic>{'on': on});
  } catch (_) {}
}

class OfflineMeshService extends ChangeNotifier {
  OfflineMeshService._();
  static final OfflineMeshService instance = OfflineMeshService._();

  static const String _serviceId = 'ir.cyrustourist.offline';
  static const int _maxTtl = 6;
  static const int _maxHistory = 300;

  // ذخیره‌وارسال: پیام‌های متنی اخیر نگه داشته می‌شوند و به هر گوشی تازه‌وصل‌شده داده می‌شوند.
  static const int _outboxMax = 150;
  static const Duration _outboxAge = Duration(hours: 6);

  // سرویس پیش‌زمینه: برنامه با خاموش‌شدن صفحه یا رفتن به پس‌زمینه شبکه را از دست نمی‌دهد.
  static const String _fgChannelId = 'cyrus_mesh_fg';
  static const int _fgNotifId = 7741;
  bool _fgOn = false;

  /// call_service هنگام تماس اینترنتی این را true می‌کند؛ در این مدت سرویس پیش‌زمینه
  /// دست‌نخورده می‌ماند تا نوع «میکروفن» تماس از بین نرود.
  bool callForegroundActive = false;

  /// بعد از پایان تماس اینترنتی، سرویس پیش‌زمینه‌ی شبکه‌ی آفلاین را دوباره برقرار می‌کند.
  Future<void> restoreForeground() async {
    callForegroundActive = false;
    if (!running) return;
    // کمی صبر تا توقف سرویس تماس کامل شود و بعد دوباره شروع شود (جلوگیری از رقابت start/stop)
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!running || callForegroundActive) return;
    _fgOn = false;
    await _startForeground();
  }

  bool running = false;
  String status = '';
  String myName = '';
  String myUid = '';

  /// پیام‌های بازی (کلید 'g') به‌جای چت به این تابع می‌رسند؛ فقط همسایه‌ی مستقیم، بدون relay.
  void Function(Map<String, dynamic> m)? gameHandler;

  final List<OfflineMsg> messages = [];
  final Map<String, OfflinePeer> peers = {}; // endpointId → همتای وصل‌شده

  // انتقال عکس: فایل (payload) و پیام توصیفی (متادیتا) جدا می‌رسند و با شناسه‌ی payload به هم وصل می‌شوند
  final Map<int, String> _fileUris = <int, String>{};
  final Map<int, Map<String, dynamic>> _fileMeta = <int, Map<String, dynamic>>{};
  final Map<int, String> _fileFrom = <int, String>{}; // شناسه‌ی payload → همسایه‌ای که فایل را فرستاده

  // ذخیره‌وارسال فایل‌ها (عکس و پیام صوتی): چند فایل اخیر برای گوشی‌های تازه‌وصل‌شده
  static const int _fileBoxMax = 8;
  static const Duration _fileBoxAge = Duration(hours: 2);
  final List<_StoredFile> _fileBox = [];
  final Set<int> _fileDone = <int>{};
  final Set<String> _seen = {};
  final Set<String> _pending = {}; // اتصال‌های در حال برقراری
  final Map<String, String> _names = {}; // endpointId → "نام|uid"
  final List<_Stored> _outbox = [];
  final Map<String, Set<String>> _delivered = {}; // uid همتا → شناسه‌ی پیام‌هایی که به او داده‌ایم

  // حضور در شبکه: هر گوشی روشن‌شده خودش را هر چند ثانیه پخش می‌کند تا همه (حتی چند پرش دورتر) او را ببینند.
  static const Duration _presenceEvery = Duration(seconds: 25);
  static const Duration _presenceTtl = Duration(seconds: 80);
  Timer? _presenceTimer;
  final Map<String, _Known> _known = {};

  /// اتاقی که کاربر الان بازش کرده (برای نشمردن پیام‌های خوانده‌شده)
  String? activeRoom;

  /// تعداد پیام‌های نخوانده‌ی گفتگوهای شخصی: اتاق → تعداد
  final Map<String, int> unread = {};

  Future<void> _loadIdentity() async {
    final p = await SharedPreferences.getInstance();
    var uid = p.getString('cyrus_offline_uid');
    if (uid == null || uid.length < 6) {
      final r = Random.secure();
      uid = List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
      await p.setString('cyrus_offline_uid', uid);
    }
    myUid = uid;
    var n = '';
    try {
      final prof = await UserProfileService.load();
      n = prof.displayName.trim().isNotEmpty ? prof.displayName.trim() : prof.username.trim();
    } catch (_) {}
    myName = n.isEmpty ? 'Traveler' : n;
  }

  // جلوگیری از رشد نامحدود حافظه در نشست‌های طولانی.
  bool _markSeen(String id) {
    if (_seen.contains(id)) return false;
    _seen.add(id);
    if (_seen.length > 1000) {
      _seen.remove(_seen.first);
    }
    return true;
  }

  /// مجوزهای لازم برای Nearby Connections.
  /// مجوزها با permission_handler و روشن‌کردن GPS با location انجام می‌شود؛
  /// متدهای قدیمی Nearby از نسخه 4.0.0 به بعد وجود ندارند.
  Future<bool> askPermissions() async {
    try {
      // Nearby Connections برای این سرویس فقط روی Android پشتیبانی می‌شود.
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }

      // همه‌ی مجوزهای لازم درخواست می‌شوند. مجوزهایی که روی این نسخه‌ی اندروید وجود ندارند
      // (مثلاً bluetoothScan قبل از اندروید ۱۲ یا nearbyWifiDevices قبل از ۱۳) در permission_handler
      // «رد‌شده» برمی‌گردند؛ پس نتیجه‌ی تک‌تک آن‌ها شرط نیست و خود Nearby هنگام شروع، کمبود مجوز را اعلام می‌کند.
      try {
        await <Permission>[
          Permission.locationWhenInUse,
          Permission.bluetooth,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.nearbyWifiDevices,
        ].request();
      } catch (e) {
        debugPrint('OfflineMeshService permissions: $e');
      }

      // GPS: در اندروید ۱۱ و پایین‌تر برای پیدا کردن گوشی‌های نزدیک لازم است. اگر کاربر
      // روشن نکرد، شروع شبکه تلاش می‌کند و در صورت خطا پیام درست نشان داده می‌شود.
      try {
        final locationService = location.Location.instance;
        if (!await locationService.serviceEnabled()) {
          await locationService.requestService();
        }
      } catch (e) {
        debugPrint('OfflineMeshService gps: $e');
      }
      return true;
    } catch (e) {
      debugPrint('OfflineMeshService.askPermissions failed: $e');
      return false;
    }
  }

  /// همه‌ی افراد شبکه: گوشی‌های وصل مستقیم + کسانی که از راه گوشی‌های واسط دیده می‌شوند.
  List<OfflinePerson> get people {
    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <String, OfflinePerson>{};
    for (final p in peers.values) {
      out[p.uid] = OfflinePerson(uid: p.uid, name: p.name, hops: 1);
    }
    for (final k in _known.values) {
      if (k.uid == myUid || out.containsKey(k.uid)) continue;
      if (now - k.seenAt > _presenceTtl.inMilliseconds) continue;
      // اگر مستقیم وصل نیست (مثلاً تازه قطع شده)، دست‌کم ۲ اتصال حساب می‌شود
      out[k.uid] = OfflinePerson(uid: k.uid, name: k.name, hops: max(k.hops, 2));
    }
    final list = out.values.toList();
    list.sort((a, b) => a.hops != b.hops ? a.hops.compareTo(b.hops) : a.name.compareTo(b.name));
    return list;
  }

  /// نام اتاق گفتگوی شخصی با یک نفر (برای هر دو گوشی یکی است).
  String dmRoomWith(String uid) {
    final ids = <String>[myUid, uid]..sort();
    return 'n${ids.join('_')}';
  }

  bool _isMyDm(String room) => room.startsWith('n') && room.substring(1).split('_').contains(myUid);

  void _announce() {
    if (!running) return;
    final m = <String, dynamic>{'pr': 1, 'u': myUid, 'n': myName, 'ts': DateTime.now().millisecondsSinceEpoch, 'ttl': _maxTtl, 'h': 0};
    _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))));
  }

  void _startPresence() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(_presenceEvery, (_) {
      if (!running) return;
      _announce();
      final limit = DateTime.now().millisecondsSinceEpoch - _presenceTtl.inMilliseconds;
      final before = _known.length;
      _known.removeWhere((_, k) => k.seenAt < limit);
      if (_known.length != before) notifyListeners();
    });
    _announce();
  }

  void _onPresence(String from, Map<String, dynamic> m) {
    final uid = '${m['u']}';
    if (uid.isEmpty || uid == myUid) return;
    final ts = (m['ts'] as num?)?.toInt() ?? 0;
    final old = _known[uid];
    if (old != null && ts <= old.ts) return; // تکراری یا قدیمی‌تر
    final h = (m['h'] as num?)?.toInt() ?? 0;
    final name = '${m['n']}'.trim();
    _known[uid] = _Known(uid, name.isEmpty ? 'Traveler' : name, ts, h + 1, DateTime.now().millisecondsSinceEpoch, Map<String, dynamic>.of(m));
    notifyListeners();
    final ttl = (m['ttl'] as num?)?.toInt() ?? 0;
    if (ttl > 1) {
      final out = Map<String, dynamic>.of(m);
      out['ttl'] = ttl - 1;
      out['h'] = h + 1;
      _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(out))), except: from);
    }
  }

  Future<void> _startForeground() async {
    if (_fgOn || callForegroundActive || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      final fa = MenuLanguage.current == 'fa';
      await android.createNotificationChannel(AndroidNotificationChannel(
        _fgChannelId,
        fa ? 'شبکه‌ی آفلاین' : 'Offline network',
        description: fa ? 'فعال ماندن شبکه‌ی نزدیک در پس‌زمینه' : 'Keeps the nearby network alive in the background',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ));
      await android.startForegroundService(
        _fgNotifId,
        fa ? 'شبکه‌ی آفلاین گردشگران' : 'Offline tourist network',
        fa ? 'گوشی شما در شبکه‌ی نزدیک فعال است' : 'Your phone is active in the nearby network',
        notificationDetails: AndroidNotificationDetails(
          _fgChannelId,
          fa ? 'شبکه‌ی آفلاین' : 'Offline network',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          playSound: false,
          enableVibration: false,
          icon: '@drawable/ic_stat_notify',
        ),
        foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeConnectedDevice},
      );
      _fgOn = true;
    } catch (e) {
      debugPrint('OfflineMeshService foreground start: $e');
    }
  }

  Future<void> _stopForeground() async {
    if (!_fgOn || callForegroundActive) {
      _fgOn = false;
      return;
    }
    _fgOn = false;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.stopForegroundService();
    } catch (e) {
      debugPrint('OfflineMeshService foreground stop: $e');
    }
  }

  void _pruneOutbox() {
    final limit = DateTime.now().subtract(_outboxAge).millisecondsSinceEpoch;
    _outbox.removeWhere((s) => s.at < limit);
    if (_outbox.length > _outboxMax) _outbox.removeRange(0, _outbox.length - _outboxMax);
  }

  /// پیام متنی را برای تحویل به گوشی‌هایی که بعداً نزدیک می‌شوند نگه می‌دارد.
  void _remember(Map<String, dynamic> m) {
    _outbox.add(_Stored(Map<String, dynamic>.of(m), DateTime.now().millisecondsSinceEpoch));
    _pruneOutbox();
  }

  /// بعد از وصل‌شدن یک گوشی تازه، پیام‌های اخیری که هنوز نگرفته را برایش می‌فرستد.
  /// ttl=1 یعنی خودش فقط دریافت می‌کند؛ آن گوشی هم پیام‌ها را نگه می‌دارد و به همسایه‌های بعدی‌اش می‌رساند.
  Future<void> _syncTo(String endpointId, String peerUid) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!running || !peers.containsKey(endpointId)) return;
    // خودمان را اعلام می‌کنیم و فهرست افرادی که می‌شناسیم را به همسایه‌ی تازه می‌دهیم
    _announce();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final k in List<_Known>.of(_known.values)) {
      if (!running || !peers.containsKey(endpointId)) return;
      if (k.uid == peerUid || nowMs - k.seenAt > _presenceTtl.inMilliseconds) continue;
      final out = <String, dynamic>{...k.raw, 'ttl': 1, 'h': k.hops};
      try {
        await Nearby().sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(jsonEncode(out))));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    final sent = _delivered.putIfAbsent(peerUid, () => <String>{});
    if (sent.length > 600) sent.clear();
    _pruneOutbox();
    for (final s in List<_Stored>.of(_outbox)) {
      if (!running || !peers.containsKey(endpointId)) return;
      if ('${s.data['u']}' == peerUid) continue;
      final id = '${s.data['id']}';
      if (!sent.add(id)) continue;
      final out = <String, dynamic>{...s.data, 'ttl': 1};
      try {
        await Nearby().sendBytesPayload(endpointId, Uint8List.fromList(utf8.encode(jsonEncode(out))));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    // فایل‌های اخیر (عکس و صدا) که این گوشی هنوز ندارد؛ ttl=1 یعنی خودش فقط دریافت می‌کند
    final limit = DateTime.now().subtract(_fileBoxAge).millisecondsSinceEpoch;
    for (final f in List<_StoredFile>.of(_fileBox)) {
      if (!running || !peers.containsKey(endpointId)) return;
      if (f.at < limit || '${f.meta['u']}' == peerUid) continue;
      final id = '${f.meta['id']}';
      if (sent.contains(id) || !await File(f.path).exists()) continue;
      try {
        await _pushFile(endpointId, f.path, <String, dynamic>{...f.meta, 'ttl': 1});
      } catch (_) {}
    }
  }

  /// آخرین خطای شروع شبکه (برای نمایش راهنمای دقیق‌تر به کاربر)
  String lastError = '';

  /// نام تبلیغ‌شده در Nearby حداکثر ~۱۳۱ بایت است؛ نام فارسی/بلند باعث شکست تبلیغ می‌شد.
  String _label() {
    var n = myName.replaceAll('|', ' ');
    while (utf8.encode(n).length > 60 && n.isNotEmpty) {
      n = n.substring(0, n.length - 1);
    }
    if (n.isEmpty) n = 'Traveler';
    return '$n|$myUid';
  }

  Future<bool> start() async {
    if (running) return true;
    await _loadIdentity();
    lastError = '';
    if (!await askPermissions()) {
      status = 'perm';
      notifyListeners();
      return false;
    }
    final label = _label();
    final nearby = Nearby();
    try {
      final advertisingStarted = await nearby.startAdvertising(
        label,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
        serviceId: _serviceId,
      );
      if (!advertisingStarted) {
        throw StateError('Nearby advertising could not be started');
      }

      final discoveryStarted = await nearby.startDiscovery(
        label,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onFound,
        onEndpointLost: (id) {
          _names.remove(id);
        },
        serviceId: _serviceId,
      );
      if (!discoveryStarted) {
        throw StateError('Nearby discovery could not be started');
      }

      running = true;
      status = 'on';
      notifyListeners();
      unawaited(_startForeground());
      unawaited(_netLock(true));
      _startPresence();
      _startWatchdog();
      return true;
    } catch (e) {
      running = false;
      status = 'error';
      lastError = '$e';
      try {
        await nearby.stopAdvertising();
        await nearby.stopDiscovery();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    final nearby = Nearby();
    // هر مرحله جداگانه متوقف می‌شود تا شکست یک مرحله مانع بقیه نشود.
    try {
      await nearby.stopAdvertising();
    } catch (e) {
      debugPrint('OfflineMeshService.stopAdvertising: $e');
    }
    try {
      await nearby.stopDiscovery();
    } catch (e) {
      debugPrint('OfflineMeshService.stopDiscovery: $e');
    }
    try {
      await nearby.stopAllEndpoints();
    } catch (e) {
      debugPrint('OfflineMeshService.stopAllEndpoints: $e');
    }
    running = false;
    status = '';
    peers.clear();
    _pending.clear();
    _names.clear();
    _delivered.clear();
    _fileFrom.clear();
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _watchTimer?.cancel();
    _watchTimer = null;
    _fails.clear();
    _known.clear();
    await _stopForeground();
    unawaited(_netLock(false));
    notifyListeners();
  }

  final Map<String, int> _fails = {};

  /// بعد از قطع یا شکست اتصال، اگر گوشی هنوز در دسترس است دوباره درخواست می‌دهیم
  /// (onEndpointFound فقط یک‌بار صدا زده می‌شود و بعد از قطع دوباره نمی‌آید).
  /// فاصله‌ی تلاش‌ها کوتاه شروع می‌شود (۱٫۵ ثانیه) و تا ۸ ثانیه بیشتر می‌شود.
  /// هر دو طرف می‌توانند تلاش کنند؛ طرف با uid بزرگ‌تر کمی دیرتر.
  void _retryLater(String id) {
    final n = (_fails[id] ?? 0) + 1;
    _fails[id] = n;
    final base = min(8000, 1500 * n);
    final other0 = (_names[id] ?? '').split('|').last;
    final delay = Duration(milliseconds: myUid.compareTo(other0) < 0 ? base : base + 2500);
    Future<void>.delayed(delay, () {
      if (!running || peers.containsKey(id) || _pending.contains(id)) return;
      if (_names[id] == null) return; // دیگر پیدا نمی‌شود
      _request(id);
    });
  }

  /// اگر گوشی مقابل (uid کوچک‌تر) ما را پیدا نکرد، خودمان بعد از چند ثانیه درخواست می‌دهیم.
  /// قبلاً فقط uid کوچک‌تر درخواست می‌داد و اگر او آگهی ما را نمی‌دید، اتصال هرگز برقرار نمی‌شد.
  void _fallbackRequest(String id) {
    Future<void>.delayed(const Duration(milliseconds: 3500), () {
      if (!running || peers.containsKey(id) || _pending.contains(id)) return;
      if (_names[id] == null) return;
      _request(id);
    });
  }

  void _request(String id) {
    if (_pending.contains(id) || peers.containsKey(id)) return;
    _pending.add(id);
    // اگر نتیجه‌ی اتصال هرگز نرسید، id تا ابد «در حال اتصال» نماند
    Future<void>.delayed(const Duration(seconds: 15), () {
      if (_pending.remove(id) && running && !peers.containsKey(id)) _retryLater(id);
    });
    Nearby().requestConnection(
      _label(),
      id,
      onConnectionInitiated: _onInit,
      onConnectionResult: _onResult,
      onDisconnected: _onDisc,
    ).catchError((_) {
      _pending.remove(id);
      if (running && !peers.containsKey(id)) _retryLater(id);
      return false;
    });
  }

  // ---------------------------------------------------------------- نگهبان اتصال
  Timer? _watchTimer;
  int _lonelySince = 0;

  /// جستجوی Nearby در اندروید بعد از مدتی کند می‌شود یا گوشی‌های تازه را نمی‌بیند؛
  /// اگر بیش از ۲۰ ثانیه هیچ گوشی وصل نیست، تبلیغ و جستجو دوباره راه‌اندازی می‌شوند.
  void _startWatchdog() {
    _watchTimer?.cancel();
    _lonelySince = DateTime.now().millisecondsSinceEpoch;
    _watchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!running) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (peers.isNotEmpty || _pending.isNotEmpty) {
        _lonelySince = now;
        return;
      }
      if (now - _lonelySince > 20000) {
        _lonelySince = now;
        unawaited(_restartRadio());
      }
    });
  }

  bool _restarting = false;
  Future<void> _restartRadio() async {
    if (_restarting || !running) return;
    _restarting = true;
    try {
      final nearby = Nearby();
      try {
        await nearby.stopDiscovery();
      } catch (_) {}
      try {
        await nearby.stopAdvertising();
      } catch (_) {}
      if (!running) return;
      final label = _label();
      try {
        await nearby.startAdvertising(
          label,
          Strategy.P2P_CLUSTER,
          onConnectionInitiated: _onInit,
          onConnectionResult: _onResult,
          onDisconnected: _onDisc,
          serviceId: _serviceId,
        );
      } catch (_) {}
      try {
        await nearby.startDiscovery(
          label,
          Strategy.P2P_CLUSTER,
          onEndpointFound: _onFound,
          onEndpointLost: (id) => _names.remove(id),
          serviceId: _serviceId,
        );
      } catch (_) {}
    } finally {
      _restarting = false;
    }
  }

  void _onFound(String id, String name, String serviceId) {
    _names[id] = name;
    final other = name.contains('|') ? name.split('|').last : name;
    if (peers.containsKey(id) || _pending.contains(id)) return;
    if (myUid.compareTo(other) < 0) {
      _request(id);
    } else {
      _fallbackRequest(id);
    }
  }

  void _onInit(String id, ConnectionInfo info) {
    _names[id] = info.endpointName;
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayload,
      onPayloadTransferUpdate: (id, u) => _onTransfer(u),
    );
  }

  void _onResult(String id, Status s) {
    _pending.remove(id);
    if (s == Status.CONNECTED) {
      final raw = _names[id] ?? '';
      final parts = raw.split('|');
      final name = parts.first.isEmpty ? 'Traveler' : parts.first;
      final uid = parts.length > 1 ? parts.last : id;
      _fails.remove(id);
      peers[id] = OfflinePeer(id, uid, name);
      unawaited(_syncTo(id, uid));
    } else {
      peers.remove(id);
      if (running) _retryLater(id);
    }
    notifyListeners();
  }

  void _onDisc(String id) {
    peers.remove(id);
    _pending.remove(id);
    notifyListeners();
    if (running) _retryLater(id);
  }

  void _onPayload(String fromEndpoint, Payload p) {
    if (p.type == PayloadType.FILE) {
      // برای سازگاری با نسخه‌های مختلف پلاگین، فیلدها به‌صورت پویا خوانده می‌شوند
      try {
        final dynamic d = p;
        final int pid = d.id as int;
        final dynamic uri = d.uri ?? d.filePath;
        _fileFrom[pid] = fromEndpoint;
        if (uri != null) _fileUris[pid] = '$uri';
        _tryFinishImage(pid);
      } catch (_) {}
      return;
    }
    if (p.type != PayloadType.BYTES || p.bytes == null) return;
    try {
      final m = jsonDecode(utf8.decode(p.bytes!)) as Map<String, dynamic>;
      if (m['img'] != null) {
        final pid = (m['pid'] as num?)?.toInt();
        if (pid != null) {
          // اگر این پیام را قبلاً (از مسیر دیگری) گرفته‌ایم، دریافت فایل را لغو می‌کنیم تا پهنای باند هدر نرود
          if (_seen.contains('${m['id']}')) {
            try {
              Nearby().cancelPayload(pid);
            } catch (_) {}
            return;
          }
          _fileFrom[pid] = fromEndpoint;
          _fileMeta[pid] = m;
          _tryFinishImage(pid);
        }
        return;
      }
      if (m['g'] != null) {
        _onGamePayload(fromEndpoint, m);
        return;
      }
      // کلید 'pr' (حضور) عمداً یکتاست؛ پیام‌های بازی کلیدهایی مثل 'p' دارند
      if (m['pr'] != null) {
        _onPresence(fromEndpoint, m);
        return;
      }
      final id = '${m['id']}';
      if (!_markSeen(id)) return;
      final msg = OfflineMsg(
        id: id,
        uid: '${m['u']}',
        name: '${m['n']}',
        text: '${m['t']}',
        ts: (m['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        mine: '${m['u']}' == myUid,
        room: '${m['r'] ?? ''}',
      );
      _add(msg);
      _remember(m);
      final ttl = (m['ttl'] as num?)?.toInt() ?? 0;
      if (ttl > 1) {
        m['ttl'] = ttl - 1;
        _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))), except: fromEndpoint);
      }
    } catch (_) {}
  }

  void _onTransfer(dynamic u) {
    try {
      final int pid = u.id as int;
      final st = '${u.status}';
      if (st.contains('SUCCESS')) {
        _fileDone.add(pid);
        _tryFinishImage(pid);
      } else if (st.contains('FAILURE') || st.contains('CANCELED')) {
        _fileUris.remove(pid);
        _fileMeta.remove(pid);
        _fileDone.remove(pid);
        _fileFrom.remove(pid);
      }
    } catch (_) {}
  }

  /// وقتی فایل کامل شد و پیام توصیفی هم رسید، آن را در پوشه‌ی برنامه ذخیره، به چت اضافه و
  /// (اگر ttl باقی مانده) برای بقیه‌ی همسایه‌ها رله می‌کند. نوع فایل: 'i' عکس، 'a' پیام صوتی.
  Future<void> _tryFinishImage(int pid) async {
    final meta = _fileMeta[pid];
    final uri = _fileUris[pid];
    if (meta == null || uri == null || !_fileDone.contains(pid)) return;
    final from = _fileFrom[pid];
    _fileMeta.remove(pid);
    _fileUris.remove(pid);
    _fileDone.remove(pid);
    _fileFrom.remove(pid);
    final id = '${meta['id']}';
    if (!_markSeen(id)) return;
    try {
      final isAudio = '${meta['k'] ?? 'i'}' == 'a';
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/${isAudio ? 'offline_audio' : 'offline_photos'}');
      await folder.create(recursive: true);
      final dest = '${folder.path}/${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.${isAudio ? 'm4a' : 'jpg'}';
      await (Nearby() as dynamic).copyFileAndDeleteOriginal(uri, dest);
      if (!await File(dest).exists()) return;
      _add(OfflineMsg(
        id: id,
        uid: '${meta['u']}',
        name: '${meta['n']}',
        text: '${meta['t'] ?? ''}',
        ts: (meta['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        mine: '${meta['u']}' == myUid,
        room: '${meta['r'] ?? ''}',
        imagePath: isAudio ? null : dest,
        audioPath: isAudio ? dest : null,
        audioSecs: (meta['d'] as num?)?.toInt() ?? 0,
      ));
      _rememberFile(meta, dest);
      // رله: فقط اگر فرستنده ttl گذاشته باشد (نسخه‌های قدیمی ttl ندارند و رله نمی‌شوند)
      final ttl = (meta['ttl'] as num?)?.toInt() ?? 0;
      if (ttl > 1) {
        final out = <String, dynamic>{...meta, 'ttl': ttl - 1};
        out.remove('pid');
        unawaited(_relayFile(dest, out, except: from));
      }
    } catch (_) {}
  }

  void _rememberFile(Map<String, dynamic> meta, String path) {
    final m = Map<String, dynamic>.of(meta)..remove('pid');
    _fileBox.add(_StoredFile(m, path, DateTime.now().millisecondsSinceEpoch));
    final limit = DateTime.now().subtract(_fileBoxAge).millisecondsSinceEpoch;
    _fileBox.removeWhere((f) => f.at < limit);
    if (_fileBox.length > _fileBoxMax) _fileBox.removeRange(0, _fileBox.length - _fileBoxMax);
  }

  /// یک فایل را با شناسه‌ی payload خودش و پیام توصیفی برای یک همسایه می‌فرستد.
  Future<void> _pushFile(String ep, String path, Map<String, dynamic> meta) async {
    final dynamic nearby = Nearby();
    final pid = await nearby.sendFilePayload(ep, path) as int;
    final m = <String, dynamic>{...meta, 'pid': pid};
    await Nearby().sendBytesPayload(ep, Uint8List.fromList(utf8.encode(jsonEncode(m))));
    final uid = peers[ep]?.uid;
    if (uid != null) _delivered.putIfAbsent(uid, () => <String>{}).add('${meta['id']}');
  }

  Future<void> _relayFile(String path, Map<String, dynamic> meta, {String? except}) async {
    for (final ep in peers.keys.toList()) {
      if (ep == except || !running) continue;
      try {
        await _pushFile(ep, path, meta);
      } catch (_) {}
    }
  }

  /// نسخه‌ی کوچک‌شده‌ی عکس برای ارسال روی شبکه (اگر کوچک‌کردن نشد، خود فایل).
  Future<String> _shrinkForMesh(String path) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/offline_out');
      await folder.create(recursive: true);
      final out = '${folder.path}/m_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final ok = await compute(_shrinkJob, <String>[path, out]);
      return ok ? out : path;
    } catch (_) {
      return path;
    }
  }

  /// ارسال عکس به شبکه: عکس تا ۱۲۸۰ پیکسل کوچک می‌شود و از راه گوشی‌های واسط تا [_maxTtl] پرش می‌رود.
  /// اگر الان گوشی‌ای وصل نیست، نگه داشته می‌شود و به گوشی‌هایی که نزدیک شوند می‌رسد.
  /// خروجی false یعنی شبکه روشن نیست.
  Future<bool> sendImage(String path, {String room = '', String caption = ''}) async {
    if (!running) return false;
    final id = '$myUid-${DateTime.now().microsecondsSinceEpoch}';
    _markSeen(id);
    final ts = DateTime.now().millisecondsSinceEpoch;
    _add(OfflineMsg(id: id, uid: myUid, name: myName, text: caption, ts: ts, mine: true, room: room, imagePath: path));
    final small = await _shrinkForMesh(path);
    final meta = <String, dynamic>{'img': 1, 'k': 'i', 'id': id, 'u': myUid, 'n': myName, 't': caption, 'ts': ts, 'ttl': _maxTtl};
    if (room.isNotEmpty) meta['r'] = room;
    _rememberFile(meta, small);
    await _relayFile(small, meta);
    return true;
  }

  /// ارسال پیام صوتی کوتاه (فایل m4a) با همان مسیر رله و ذخیره‌وارسال عکس.
  Future<bool> sendAudio(String path, int secs, {String room = ''}) async {
    if (!running) return false;
    final id = '$myUid-${DateTime.now().microsecondsSinceEpoch}';
    _markSeen(id);
    final ts = DateTime.now().millisecondsSinceEpoch;
    var local = path;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/offline_audio');
      await folder.create(recursive: true);
      local = '${folder.path}/${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.m4a';
      await File(path).copy(local);
    } catch (_) {
      local = path;
    }
    _add(OfflineMsg(id: id, uid: myUid, name: myName, text: '', ts: ts, mine: true, room: room, audioPath: local, audioSecs: secs));
    final meta = <String, dynamic>{'img': 1, 'k': 'a', 'id': id, 'u': myUid, 'n': myName, 'ts': ts, 'd': secs, 'ttl': _maxTtl};
    if (room.isNotEmpty) meta['r'] = room;
    _rememberFile(meta, local);
    await _relayFile(local, meta);
    return true;
  }

  void _add(OfflineMsg m) {
    messages.add(m);
    if (messages.length > _maxHistory) messages.removeRange(0, messages.length - _maxHistory);
    if (!m.mine && _isMyDm(m.room) && activeRoom != m.room) unread[m.room] = (unread[m.room] ?? 0) + 1;
    notifyListeners();
  }

  void _broadcast(Uint8List bytes, {String? except}) {
    for (final id in peers.keys) {
      if (id == except) continue;
      Nearby().sendBytesPayload(id, bytes).catchError((_) {});
    }
  }

  // پیام‌های بازی: هر پیام شناسه‌ی یکتا (gid) و ttl دارد و مثل چت رله می‌شود؛ پس میزبان بازی
  // لازم نیست مستقیم به هر سه گوشی دیگر وصل باشد (قبلاً بدون رله بود و «اتاق پیدا نشد» می‌داد).
  static const int _gameTtl = 3;
  final Set<String> _gameSeen = {};
  int _gameSeq = 0;

  bool _markGameSeen(String id) {
    if (!_gameSeen.add(id)) return false;
    if (_gameSeen.length > 600) _gameSeen.remove(_gameSeen.first);
    return true;
  }

  String? _endpointOfUid(String uid) {
    for (final e in peers.entries) {
      if (e.value.uid == uid) return e.key;
    }
    return null;
  }

  void _onGamePayload(String from, Map<String, dynamic> m) {
    final gid = m['gid'];
    if (gid != null && !_markGameSeen('$gid')) return; // تکراری (از مسیر دیگر رسیده)
    final to = m['to'];
    final forMe = to == null || '$to' == myUid;
    if (forMe) {
      final h = gameHandler;
      if (h != null) h(m);
    }
    // رله: فقط پیام‌هایی که ttl دارند (نسخه‌های قدیمی ttl ندارند)
    final ttl = (m['ttl'] as num?)?.toInt() ?? 0;
    if (ttl <= 1 || (to != null && '$to' == myUid)) return;
    final out = <String, dynamic>{...m, 'ttl': ttl - 1};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(out)));
    if (to != null) {
      final ep = _endpointOfUid('$to');
      if (ep != null) {
        Nearby().sendBytesPayload(ep, bytes).catchError((_) {});
        return;
      }
    }
    _broadcast(bytes, except: from);
  }

  /// ارسال پیام بازی؛ اگر گیرنده ('to') همسایه‌ی مستقیم باشد فقط به خودش می‌رود، وگرنه رله می‌شود.
  void sendGame(Map<String, dynamic> m) {
    if (!running) return;
    final gid = '$myUid-${DateTime.now().microsecondsSinceEpoch}-${_gameSeq++}';
    _markGameSeen(gid);
    final out = <String, dynamic>{...m, 'u': myUid, 'n': myName, 'gid': gid, 'ttl': _gameTtl};
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(out)));
    final to = m['to'];
    if (to != null) {
      final ep = _endpointOfUid('$to');
      if (ep != null) {
        Nearby().sendBytesPayload(ep, bytes).catchError((_) {});
        return;
      }
    }
    _broadcast(bytes);
  }

  /// پیام‌های یک اتاق (گروه یا گفتگوی شخصی)؛ اتاق خالی = شبکه‌ی عمومی.
  List<OfflineMsg> messagesFor(String room) => messages.where((m) => m.room == room).toList();

  Future<void> send(String text, {String room = ''}) async {
    final t = text.trim();
    if (t.isEmpty || !running) return;
    final id = '$myUid-${DateTime.now().microsecondsSinceEpoch}';
    _markSeen(id);
    final ts = DateTime.now().millisecondsSinceEpoch;
    _add(OfflineMsg(id: id, uid: myUid, name: myName, text: t, ts: ts, mine: true, room: room));
    final m = <String, dynamic>{'id': id, 'u': myUid, 'n': myName, 't': t, 'ts': ts, 'ttl': _maxTtl};
    if (room.isNotEmpty) m['r'] = room;
    _remember(m);
    _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))));
  }
}

class _StoredFile {
  _StoredFile(this.meta, this.path, this.at);
  final Map<String, dynamic> meta;
  final String path;
  final int at;
}

class _Stored {
  _Stored(this.data, this.at);
  final Map<String, dynamic> data;
  final int at;
}
