import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as location;
import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile_service.dart';

/// پیام شبکه‌ی آفلاین
class OfflineMsg {
  OfflineMsg({required this.id, required this.uid, required this.name, required this.text, required this.ts, required this.mine, this.room = '', this.imagePath});
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
}

class OfflinePeer {
  OfflinePeer(this.endpointId, this.uid, this.name);
  final String endpointId;
  final String uid;
  final String name;
}

/// شبکه‌ی آفلاین گردشگران (بدون اینترنت) با Nearby Connections.
/// استراتژی P2P_CLUSTER: هر گوشی هم تبلیغ می‌کند هم جستجو؛ پیام‌ها بین گوشی‌ها
/// پاس داده می‌شوند (relay) تا گروه بزرگ‌تر از اتصال مستقیم هم پیام را بگیرد.
class OfflineMeshService extends ChangeNotifier {
  OfflineMeshService._();
  static final OfflineMeshService instance = OfflineMeshService._();

  static const String _serviceId = 'ir.cyrustourist.offline';
  static const int _maxTtl = 4;
  static const int _maxHistory = 300;

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
  final Set<int> _fileDone = <int>{};
  final Set<String> _seen = {};
  final Set<String> _pending = {}; // اتصال‌های در حال برقراری
  final Map<String, String> _names = {}; // endpointId → "نام|uid"

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

      // مجوز مکان برای سازگاری با نسخه‌های قدیمی اندروید و رفتار Nearby.
      final locationPermission =
          await Permission.locationWhenInUse.request();
      if (!locationPermission.isGranted) return false;

      // مجوزهای Bluetooth؛ در اندرویدهای قدیمی مجوزهای جدیدتر
      // توسط permission_handler به‌عنوان غیرقابل‌اعمال مدیریت می‌شوند.
      final bluetoothStatuses = await <Permission>[
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      final bluetoothPermissions = <Permission>[
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ];
      for (final permission in bluetoothPermissions) {
        if (!(bluetoothStatuses[permission]?.isGranted ?? false)) {
          return false;
        }
      }

      // از Android 13 برای اسکن دستگاه‌های نزدیک لازم است.
      final nearbyWifiPermission =
          await Permission.nearbyWifiDevices.request();
      if (!nearbyWifiPermission.isGranted) return false;

      // GPS باید روشن باشد؛ در صورت خاموش بودن، پنجره فعال‌سازی سیستم نمایش داده می‌شود.
      final locationService = location.Location.instance;
      var serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
      }
      return serviceEnabled;
    } catch (e) {
      debugPrint('OfflineMeshService.askPermissions failed: $e');
      return false;
    }
  }

  Future<bool> start() async {
    if (running) return true;
    await _loadIdentity();
    if (!await askPermissions()) {
      status = 'perm';
      notifyListeners();
      return false;
    }
    final label = '$myName|$myUid';
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
        onEndpointFound: (id, name, serviceId) {
          _names[id] = name;
          // برای جلوگیری از درخواست هم‌زمان دوطرفه، فقط uid کوچک‌تر درخواست می‌دهد
          final other = name.contains('|') ? name.split('|').last : name;
          if (peers.containsKey(id) || _pending.contains(id)) return;
          if (myUid.compareTo(other) < 0) _request(id);
        },
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
      return true;
    } catch (_) {
      running = false;
      status = 'error';
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
    notifyListeners();
  }

  void _request(String id) {
    _pending.add(id);
    Nearby().requestConnection(
      '$myName|$myUid',
      id,
      onConnectionInitiated: _onInit,
      onConnectionResult: _onResult,
      onDisconnected: _onDisc,
    ).catchError((_) {
      _pending.remove(id);
      return false;
    });
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
      peers[id] = OfflinePeer(id, uid, name);
    } else {
      peers.remove(id);
    }
    notifyListeners();
  }

  void _onDisc(String id) {
    peers.remove(id);
    _pending.remove(id);
    notifyListeners();
  }

  void _onPayload(String fromEndpoint, Payload p) {
    if (p.type == PayloadType.FILE) {
      // برای سازگاری با نسخه‌های مختلف پلاگین، فیلدها به‌صورت پویا خوانده می‌شوند
      try {
        final dynamic d = p;
        final int pid = d.id as int;
        final dynamic uri = d.uri ?? d.filePath;
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
          _fileMeta[pid] = m;
          _tryFinishImage(pid);
        }
        return;
      }
      if (m['g'] != null) {
        final h = gameHandler;
        if (h != null) h(m);
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
      }
    } catch (_) {}
  }

  /// وقتی فایل کامل شد و پیام توصیفی هم رسید، عکس را در پوشه‌ی برنامه ذخیره و به چت اضافه می‌کند.
  Future<void> _tryFinishImage(int pid) async {
    final meta = _fileMeta[pid];
    final uri = _fileUris[pid];
    if (meta == null || uri == null || !_fileDone.contains(pid)) return;
    _fileMeta.remove(pid);
    _fileUris.remove(pid);
    _fileDone.remove(pid);
    final id = '${meta['id']}';
    if (!_markSeen(id)) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/offline_photos');
      await folder.create(recursive: true);
      final dest = '${folder.path}/${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.jpg';
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
        imagePath: dest,
      ));
    } catch (_) {}
  }

  /// ارسال عکس با کیفیت به همه‌ی گوشی‌های وصل‌شده (مستقیم، بدون عبور از گوشی‌های دیگر).
  /// خروجی false یعنی هیچ گوشی‌ای وصل نیست.
  Future<bool> sendImage(String path, {String room = '', String caption = ''}) async {
    if (!running || peers.isEmpty) return false;
    final id = '$myUid-${DateTime.now().microsecondsSinceEpoch}';
    _markSeen(id);
    final ts = DateTime.now().millisecondsSinceEpoch;
    _add(OfflineMsg(id: id, uid: myUid, name: myName, text: caption, ts: ts, mine: true, room: room, imagePath: path));
    final dynamic nearby = Nearby();
    for (final ep in peers.keys.toList()) {
      try {
        final pid = await nearby.sendFilePayload(ep, path) as int;
        final meta = <String, dynamic>{'img': 1, 'pid': pid, 'id': id, 'u': myUid, 'n': myName, 't': caption, 'ts': ts};
        if (room.isNotEmpty) meta['r'] = room;
        await Nearby().sendBytesPayload(ep, Uint8List.fromList(utf8.encode(jsonEncode(meta))));
      } catch (_) {}
    }
    return true;
  }

  void _add(OfflineMsg m) {
    messages.add(m);
    if (messages.length > _maxHistory) messages.removeRange(0, messages.length - _maxHistory);
    notifyListeners();
  }

  void _broadcast(Uint8List bytes, {String? except}) {
    for (final id in peers.keys) {
      if (id == except) continue;
      Nearby().sendBytesPayload(id, bytes).catchError((_) {});
    }
  }

  /// ارسال پیام بازی به همه‌ی گوشی‌های وصل‌شده (گیرنده با فیلد 'to' خودش را تشخیص می‌دهد).
  void sendGame(Map<String, dynamic> m) {
    if (!running) return;
    final out = <String, dynamic>{...m, 'u': myUid, 'n': myName};
    _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(out))));
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
    _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))));
  }
}
