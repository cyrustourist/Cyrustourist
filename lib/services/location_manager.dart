import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationManager {
  static Future<bool> checkService() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// آخرین موقعیت ثبت‌شده‌ی دستگاه (فوری، بدون انتظار برای GPS).
  static Future<LatLng?> getLastKnownLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);
    } catch (_) {}
    // اگر دستگاه آخرین موقعیت را نداشت، آخرین موقعیت ذخیره‌شدهٔ خود اپ (فوری)
    try {
      final p = await SharedPreferences.getInstance();
      final la = p.getDouble('last_lat');
      final lo = p.getDouble('last_lng');
      if (la != null && lo != null) return LatLng(la, lo);
    } catch (_) {}
    return null;
  }

  static Future<void> _remember(LatLng point) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble('last_lat', point.latitude);
      await p.setDouble('last_lng', point.longitude);
    } catch (_) {}
  }

  /// موقعیت فعلی — سریع:
  /// ۱) اگر آخرین موقعیت دستگاه تازه است (کمتر از ۱۰ دقیقه) همان فوراً برمی‌گردد.
  /// ۲) وگرنه موقعیت جدید با دقت متوسط و حداکثر ۸ ثانیه انتظار گرفته می‌شود.
  /// ۳) اگر دریافت جدید نشد، آخرین موقعیت قدیمی (در صورت وجود) استفاده می‌شود.
  static Future<LatLng?> getCurrentLocation() async {
    try {
      final enabled = await checkService();

      if (!enabled) {
        return null;
      }

      final permission = await requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? last;
      try {
        last = await Geolocator.getLastKnownPosition();
      } catch (_) {
        last = null;
      }

      if (last != null) {
        final DateTime? stamp = last.timestamp;
        if (stamp != null &&
            DateTime.now().difference(stamp).inMinutes < 10) {
          return LatLng(last.latitude, last.longitude);
        }
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );

        final fresh = LatLng(position.latitude, position.longitude);
        await _remember(fresh);
        return fresh;
      } catch (_) {
        if (last != null) {
          return LatLng(last.latitude, last.longitude);
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
