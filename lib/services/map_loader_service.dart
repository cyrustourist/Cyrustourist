import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> checkServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> requestPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    return permission;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // دریافت اول: بالاترین دقت ممکن (GPS ماهواره‌ای، نه شبکه)
      Position best = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 12),
        ),
      );

      // اگر خطای دریافت اول هنوز زیاد بود (بیش از ۲۵ متر)،
      // چند ثانیه دیگر نمونه‌برداری می‌کنیم تا گیرنده‌ی GPS
      // قفل بهتری بگیرد، و دقیق‌ترین نمونه را برمی‌گردانیم.
      if (best.accuracy > 25) {
        try {
          final stream = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
            ),
          ).timeout(const Duration(seconds: 6));

          await for (final position in stream) {
            if (position.accuracy < best.accuracy) {
              best = position;
            }

            if (best.accuracy <= 15) break;
          }
        } catch (_) {
          // پایان مهلت طبیعی است؛ بهترین نمونه‌ی قبلی استفاده می‌شود
        }
      }

      return best;
    } catch (_) {
      return null;
    }
  }

  static Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> locationStream() {
    return Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.best,
        distanceFilter:
            10,
      ),
    );
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
