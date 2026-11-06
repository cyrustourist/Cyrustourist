import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile_service.dart';

/// پیام شبکه‌ی آفلاین
class OfflineMsg {
  OfflineMsg({required this.id, required this.uid, required this.name, required this.text, required this.ts, required this.mine});
  final String id;
  final String uid;
  final String name;
  final String text;
  final int ts;
  final bool mine;
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

  final List<OfflineMsg> messages = [];
  final Map<String, OfflinePeer> peers = {}; // endpointId → همتای وصل‌شده
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

  /// مجوزهای لازم (مکان، بلوتوث، وای‌فای نزدیک). true = همه داده شد.
  Future<bool> askPermissions() async {
    try {
      final n = Nearby();
      final loc = await n.askLocationPermission();
      final bt = await n.askBluetoothPermission();
      try {
        // فقط در نسخه‌های جدید پکیج / اندروید ۱۳+
        await (n as dynamic).askNearbyWifiDevicesPermission();
      } catch (_) {}
      try {
        await n.enableLocationServices();
      } catch (_) {}
      return loc && bt;
    } catch (_) {
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
    try {
      await Nearby().startAdvertising(
        label,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
        serviceId: _serviceId,
      );
      await Nearby().startDiscovery(
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
      running = true;
      status = 'on';
      notifyListeners();
      return true;
    } catch (_) {
      running = false;
      status = 'error';
      try {
        await Nearby().stopAdvertising();
        await Nearby().stopDiscovery();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
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
      onPayloadTransferUpdate: (id, u) {},
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
    if (p.type != PayloadType.BYTES || p.bytes == null) return;
    try {
      final m = jsonDecode(utf8.decode(p.bytes!)) as Map<String, dynamic>;
      final id = '${m['id']}';
      if (_seen.contains(id)) return;
      _seen.add(id);
      final msg = OfflineMsg(
        id: id,
        uid: '${m['u']}',
        name: '${m['n']}',
        text: '${m['t']}',
        ts: (m['ts'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        mine: '${m['u']}' == myUid,
      );
      _add(msg);
      final ttl = (m['ttl'] as num?)?.toInt() ?? 0;
      if (ttl > 1) {
        m['ttl'] = ttl - 1;
        _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))), except: fromEndpoint);
      }
    } catch (_) {}
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

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || !running) return;
    final id = '$myUid-${DateTime.now().microsecondsSinceEpoch}';
    _seen.add(id);
    final ts = DateTime.now().millisecondsSinceEpoch;
    _add(OfflineMsg(id: id, uid: myUid, name: myName, text: t, ts: ts, mine: true));
    final m = {'id': id, 'u': myUid, 'n': myName, 't': t, 'ts': ts, 'ttl': _maxTtl};
    _broadcast(Uint8List.fromList(utf8.encode(jsonEncode(m))));
  }
}
