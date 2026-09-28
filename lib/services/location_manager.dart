import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
      if (last == null) return null;
      return LatLng(last.latitude, last.longitude);
    } catch (_) {
      return null;
    }
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

        return LatLng(position.latitude, position.longitude);
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
