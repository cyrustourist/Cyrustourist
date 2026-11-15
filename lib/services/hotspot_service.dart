import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart';

class HotspotInfo {
  const HotspotInfo(this.ssid, this.pass, this.sec);
  final String ssid;
  final String pass;
  final int sec; // 0 باز، 1 WPA2، 2 WPA2/WPA3، 3 فقط WPA3

  /// متن QR وای‌فای (دوربین آیفون و اندروید آن را می‌شناسد)
  String get wifiQr => WifiQr.build(ssid, pass, sec);
}

class WifiQr {
  static String _esc(String v) => v.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

  static String build(String ssid, String pass, [int sec = 1]) {
    if (pass.isEmpty || sec == 0) return 'WIFI:T:nopass;S:${_esc(ssid)};;';
    final t = sec == 3 ? 'SAE' : 'WPA';
    return 'WIFI:T:$t;S:${_esc(ssid)};P:${_esc(pass)};;';
  }
}

/// روشن‌کردن وای‌فای محلی (LocalOnlyHotspot) از طریق کد بومی HotspotBridge.kt
class HotspotService {
  HotspotService._();
  static final HotspotService instance = HotspotService._();
  static const MethodChannel _ch = MethodChannel('cyrus/hotspot');

  String lastError = '';

  Future<bool> askPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    for (final p in <Permission>[Permission.locationWhenInUse, Permission.nearbyWifiDevices]) {
      try {
        await p.request();
      } catch (e) {
        debugPrint('HotspotService permission $p: $e');
      }
    }
    try {
      final l = location.Location.instance;
      if (!await l.serviceEnabled()) await l.requestService();
    } catch (e) {
      debugPrint('HotspotService gps: $e');
    }
    return true;
  }

  Future<HotspotInfo?> start() async {
    lastError = '';
    if (!await askPermissions()) {
      lastError = 'perm';
      return null;
    }
    try {
      final r = await _ch.invokeMethod<Map<dynamic, dynamic>>('start');
      if (r == null) {
        lastError = 'failed';
        return null;
      }
      final ssid = '${r['ssid'] ?? ''}';
      if (ssid.isEmpty) {
        lastError = 'failed';
        return null;
      }
      return HotspotInfo(ssid, '${r['pass'] ?? ''}', (r['sec'] as num?)?.toInt() ?? 1);
    } on PlatformException catch (e) {
      lastError = e.code;
      return null;
    } catch (e) {
      lastError = 'failed';
      return null;
    }
  }

  Future<void> stop() async {
    try {
      await _ch.invokeMethod<bool>('stop');
    } catch (_) {}
  }

  /// آدرس IP همین گوشی روی شبکه‌ی وای‌فای اشتراکی (برای آدرس بازی).
  /// اول اینترفیس‌های هات‌اسپات (ap / swlan / wlan1) بررسی می‌شوند.
  static Future<String?> localIp() async {
    try {
      final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      String? pick(bool Function(String name) test) {
        for (final i in ifs) {
          if (!test(i.name.toLowerCase())) continue;
          for (final a in i.addresses) {
            final ip = a.address;
            if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) return ip;
          }
        }
        return null;
      }

      return pick((n) => n.startsWith('ap') || n.contains('swlan') || n.contains('softap') || n == 'wlan1') ??
          pick((n) => n.startsWith('wlan')) ??
          pick((n) => true);
    } catch (_) {
      return null;
    }
  }
}
