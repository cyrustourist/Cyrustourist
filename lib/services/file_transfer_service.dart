import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';

import 'offline_mesh_service.dart';
import 'user_profile_service.dart';

const MethodChannel _filesChannel = MethodChannel('cyrus/files');

/// یک ردیف در فهرست انتقال (ارسالی یا دریافتی)
class TransferItem {
  TransferItem({required this.pid, required this.mine});
  final int pid;
  final bool mine;
  String name = '';
  int size = 0;
  int done = 0;

  /// run | saving | done | failed
  String state = 'run';

  /// gallery | downloads (بعد از ذخیرهٔ فایل دریافتی)
  String saved = '';

  bool get isApk => name.toLowerCase().endsWith('.apk');

  double get progress => size <= 0 ? 0 : (done / size).clamp(0.0, 1.0).toDouble();
}

/// درخواست اتصال در انتظار تأیید کاربر (کد تأیید باید در دو گوشی یکی باشد)
class PendingConn {
  PendingConn(this.id, this.name, this.token);
  final String id;
  final String name;
  final String token;
}

String ftMime(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  const m = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    '3gp': 'video/3gpp',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'ogg': 'audio/ogg',
    'wav': 'audio/wav',
    'pdf': 'application/pdf',
    'zip': 'application/zip',
    'apk': 'application/vnd.android.package-archive',
    'txt': 'text/plain',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };
  return m[ext] ?? 'application/octet-stream';
}

/// جابه‌جایی عکس، فیلم و فایل بین دو گوشی بدون اینترنت (Nearby Connections، اتصال دو نفره).
/// فایل‌ها بدون فشرده‌سازی و با کیفیت اصلی منتقل می‌شوند و فایل دریافتی خودکار در گالری
/// (عکس و ویدیو) یا پوشهٔ Download (بقیه) ذخیره می‌شود. این سرویس از شبکهٔ چت آفلاین جداست؛
/// با شروع آن شبکهٔ چت خاموش می‌شود.
class FileTransferService extends ChangeNotifier {
  FileTransferService._();
  static final FileTransferService instance = FileTransferService._();

  static const String _serviceId = 'ir.cyrustourist.files';

  /// idle | wait (دیده می‌شوم) | search (جستجو) | connecting | linked | lost
  String stage = 'idle';

  /// '' | perm | start | rejected | failed
  String error = '';
  String myName = '';
  String peerName = '';
  PendingConn? pending;
  final Map<String, String> found = <String, String>{};
  final List<TransferItem> items = <TransferItem>[];

  String _mode = '';
  String _peerId = '';
  final Map<String, String> _names = <String, String>{};
  final Map<int, TransferItem> _byPid = <int, TransferItem>{};
  final Map<int, String> _uris = <int, String>{};
  final Map<int, Map<String, dynamic>> _meta = <int, Map<String, dynamic>>{};
  final Set<int> _done = <int>{};
  final Set<int> _finishing = <int>{};

  Future<void> _ident() async {
    if (myName.isNotEmpty) return;
    var n = '';
    try {
      final prof = await UserProfileService.load();
      n = prof.displayName.trim().isNotEmpty ? prof.displayName.trim() : prof.username.trim();
    } catch (_) {}
    myName = n.isEmpty ? 'Traveler' : n;
  }

  Future<bool> _prepare() async {
    error = '';
    await _stopNearby();
    final mesh = OfflineMeshService.instance;
    if (mesh.running) await mesh.stop();
    await _ident();
    if (!await mesh.askPermissions()) {
      error = 'perm';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _stopNearby() async {
    final n = Nearby();
    try {
      await n.stopAdvertising();
    } catch (_) {}
    try {
      await n.stopDiscovery();
    } catch (_) {}
    try {
      await n.stopAllEndpoints();
    } catch (_) {}
    _peerId = '';
    pending = null;
    found.clear();
    _names.clear();
  }

  /// «دیده شدن»: این گوشی برای گوشی مقابل قابل مشاهده می‌شود (برای دریافت).
  Future<bool> startWaiting() async {
    if (!await _prepare()) return false;
    _mode = 'wait';
    try {
      final ok = await Nearby().startAdvertising(
        myName,
        Strategy.P2P_POINT_TO_POINT,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
        serviceId: _serviceId,
      );
      if (!ok) throw StateError('advertising failed');
      stage = 'wait';
      notifyListeners();
      return true;
    } catch (e) {
      await _fail('start', '$e');
      return false;
    }
  }

  /// «پیدا کردن گوشی»: گوشی‌های در حال دیده‌شدن را فهرست می‌کند (برای ارسال).
  Future<bool> startSearch() async {
    if (!await _prepare()) return false;
    _mode = 'search';
    try {
      final ok = await Nearby().startDiscovery(
        myName,
        Strategy.P2P_POINT_TO_POINT,
        onEndpointFound: (id, name, serviceId) {
          found[id] = name;
          notifyListeners();
        },
        onEndpointLost: (id) {
          found.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
      if (!ok) throw StateError('discovery failed');
      stage = 'search';
      notifyListeners();
      return true;
    } catch (e) {
      await _fail('start', '$e');
      return false;
    }
  }

  Future<void> connectTo(String id) async {
    if (stage != 'search') return;
    stage = 'connecting';
    notifyListeners();
    try {
      await Nearby().requestConnection(
        myName,
        id,
        onConnectionInitiated: _onInit,
        onConnectionResult: _onResult,
        onDisconnected: _onDisc,
      );
    } catch (e) {
      stage = 'search';
      error = 'failed';
      notifyListeners();
    }
  }

  Future<void> _fail(String code, String detail) async {
    debugPrint('FileTransfer $code: $detail');
    await _stopNearby();
    stage = 'idle';
    error = code;
    notifyListeners();
  }

  void _onInit(String id, ConnectionInfo info) {
    _names[id] = info.endpointName;
    pending = PendingConn(id, info.endpointName, '${info.authenticationToken}');
    notifyListeners();
  }

  Future<void> accept() async {
    final p = pending;
    if (p == null) return;
    pending = null;
    notifyListeners();
    try {
      await Nearby().acceptConnection(
        p.id,
        onPayLoadRecieved: _onPayload,
        onPayloadTransferUpdate: (id, u) => _onTransfer(u),
      );
    } catch (e) {
      await _fail('failed', '$e');
    }
  }

  Future<void> reject() async {
    final p = pending;
    if (p == null) return;
    pending = null;
    try {
      await Nearby().rejectConnection(p.id);
    } catch (_) {}
    if (stage == 'connecting') stage = _mode == 'search' ? 'search' : 'wait';
    notifyListeners();
  }

  void _onResult(String id, Status s) {
    if (s == Status.CONNECTED) {
      _peerId = id;
      peerName = _names[id] ?? '';
      stage = 'linked';
      error = '';
      notifyListeners();
      _afterLinked();
    } else {
      pending = null;
      stage = _mode == 'search' ? 'search' : 'wait';
      error = 'rejected';
      notifyListeners();
    }
  }

  /// بعد از وصل شدن، تبلیغ و جستجو خاموش می‌شود تا پهنای باند برای انتقال آزاد بماند.
  Future<void> _afterLinked() async {
    try {
      await Nearby().stopAdvertising();
    } catch (_) {}
    try {
      await Nearby().stopDiscovery();
    } catch (_) {}
  }

  void _onDisc(String id) {
    if (id != _peerId) return;
    _peerId = '';
    for (final it in items) {
      if (it.state == 'run') it.state = 'failed';
    }
    stage = 'lost';
    notifyListeners();
  }

  TransferItem _ensure(int pid, bool mine) {
    final old = _byPid[pid];
    if (old != null) return old;
    final it = TransferItem(pid: pid, mine: mine);
    _byPid[pid] = it;
    items.insert(0, it);
    if (mine && _done.contains(pid)) it.state = 'done';
    return it;
  }

  void _onPayload(String fromEndpoint, Payload p) {
    if (p.type == PayloadType.BYTES) {
      final b = p.bytes;
      if (b == null) return;
      try {
        final m = jsonDecode(utf8.decode(b));
        if (m is Map && m['k'] == 'file') {
          final pid = (m['pid'] as num).toInt();
          final it = _ensure(pid, false);
          it.name = '${m['name']}';
          it.size = (m['size'] as num?)?.toInt() ?? it.size;
          _meta[pid] = Map<String, dynamic>.from(m);
          notifyListeners();
          _tryFinish(pid);
        }
      } catch (_) {}
      return;
    }
    if (p.type == PayloadType.FILE) {
      try {
        final dynamic d = p;
        final int pid = d.id as int;
        final dynamic uri = d.uri ?? d.filePath;
        if (uri != null) _uris[pid] = '$uri';
        _ensure(pid, false);
        notifyListeners();
        _tryFinish(pid);
      } catch (_) {}
    }
  }

  void _onTransfer(dynamic u) {
    try {
      final int pid = u.id as int;
      final st = '${u.status}';
      final it = _byPid[pid];
      if (it != null) {
        final int sent = (u.bytesTransferred as num).toInt();
        final int total = (u.totalBytes as num).toInt();
        if (sent > it.done) it.done = sent;
        if (total > it.size) it.size = total;
      }
      if (st.contains('SUCCESS')) {
        if (_done.length > 400) _done.clear();
        _done.add(pid);
        if (it != null) {
          if (it.mine) {
            it.done = it.size;
            it.state = 'done';
          } else {
            _tryFinish(pid);
          }
        }
      } else if (st.contains('FAILURE') || st.contains('CANCELED')) {
        if (it != null && it.state == 'run') it.state = 'failed';
        _uris.remove(pid);
        _meta.remove(pid);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// فایل دریافتی کامل شد و نام آن هم رسید → ذخیره در گالری یا Download
  void _tryFinish(int pid) {
    if (_meta.containsKey(pid) && _uris.containsKey(pid) && _done.contains(pid)) _finish(pid);
  }

  Future<void> _finish(int pid) async {
    if (!_finishing.add(pid)) return;
    final it = _byPid[pid];
    final uri = _uris.remove(pid);
    _meta.remove(pid);
    _done.remove(pid);
    if (it == null || uri == null) return;
    it.state = 'saving';
    notifyListeners();
    String? tmpPath;
    try {
      final tmp = await getTemporaryDirectory();
      tmpPath = '${tmp.path}/ft_$pid.bin';
      await (Nearby() as dynamic).copyFileAndDeleteOriginal(uri, tmpPath);
      if (!await File(tmpPath).exists()) throw StateError('copy failed');
      final name = it.name.isEmpty ? 'file_$pid' : it.name;
      final kind = await _filesChannel.invokeMethod<String>('saveFile', <String, dynamic>{
        'path': tmpPath,
        'name': name,
        'mime': ftMime(name),
      });
      if (kind == null || kind.isEmpty) {
        it.state = 'failed';
      } else {
        it.state = 'done';
        it.saved = kind;
        it.done = it.size;
      }
    } catch (e) {
      debugPrint('FileTransfer save: ${e.runtimeType}');
      it.state = 'failed';
    }
    if (tmpPath != null) {
      try {
        await File(tmpPath).delete();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// ارسال یک فایل به گوشی مقابل (بدون فشرده‌سازی)
  Future<bool> sendFile(String path, String name, int size) async {
    if (stage != 'linked' || _peerId.isEmpty) return false;
    try {
      final int pid = await Nearby().sendFilePayload(_peerId, path) as int;
      final it = _ensure(pid, true);
      it.name = name;
      it.size = size;
      final meta = jsonEncode(<String, dynamic>{'k': 'file', 'pid': pid, 'name': name, 'size': size});
      await Nearby().sendBytesPayload(_peerId, Uint8List.fromList(utf8.encode(meta)));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FileTransfer send: ${e.runtimeType}');
      return false;
    }
  }

  /// ارسال خود برنامه (APK نسخهٔ نصب‌شدهٔ همین گوشی) به گوشی مقابل.
  /// خروجی: null = موفق، یا کد خطا: link | split | fail
  Future<String?> sendAppApk() async {
    if (stage != 'linked' || _peerId.isEmpty) return 'link';
    try {
      final r = await _filesChannel.invokeMethod<Map<dynamic, dynamic>>('appApk');
      if (r == null) return 'fail';
      final err = r['error'];
      if (err != null) return '$err';
      final ok = await sendFile('${r['path']}', '${r['name']}', (r['size'] as num).toInt());
      return ok ? null : 'fail';
    } catch (e) {
      debugPrint('FileTransfer sendApp: ${e.runtimeType}');
      return 'fail';
    }
  }

  /// بازگشت به صفحهٔ انتخاب (فهرست انتقال‌ها می‌ماند)
  Future<void> reset() async {
    await _stopNearby();
    stage = 'idle';
    error = '';
    peerName = '';
    notifyListeners();
  }

  /// خروج از صفحه: همه‌چیز بسته و فهرست پاک می‌شود.
  Future<void> close() async {
    await _stopNearby();
    stage = 'idle';
    error = '';
    peerName = '';
    items.clear();
    _byPid.clear();
    _uris.clear();
    _meta.clear();
    _done.clear();
    _finishing.clear();
    notifyListeners();
  }
}
