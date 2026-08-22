import 'package:geolocator/geolocator.dart';

/// سرویس مرکزی موقعیت مکانی سایروس توریست.
///
/// برای نقشه، جاذبه‌ها، سلامت، اقامتگاه‌ها و مسیریابی
/// به‌صورت مشترک استفاده می‌شود.
///
/// این سرویس هیچ مختصات جعلی تولید نمی‌کند.
class LocationService {
  /// بررسی فعال بودن GPS دستگاه
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// بررسی وضعیت مجوز موقعیت
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// درخواست مجوز موقعیت از کاربر
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// بررسی داشتن مجوز معتبر
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// بررسی آماده بودن GPS و مجوز
  Future<bool> isReady() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    return hasPermission();
  }

  /// آماده‌سازی GPS
  ///
  /// اگر GPS خاموش باشد یا مجوز داده نشود،
  /// مقدار false برگردانده می‌شود.
  Future<bool> prepare() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// دریافت آخرین موقعیت شناخته‌شده دستگاه
  ///
  /// برای نمایش سریع اولیه روی نقشه استفاده می‌شود.
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// دریافت موقعیت فعلی
  ///
  /// مختصات واقعی GPS دستگاه استفاده می‌شود.
  Future<Position?> getCurrentPosition() async {
    final ready = await prepare();

    if (!ready) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// جریان به‌روزرسانی موقعیت کاربر
  ///
  /// distanceFilter از درخواست‌های بیش از حد جلوگیری می‌کند.
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// باز کردن تنظیمات GPS دستگاه
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// باز کردن تنظیمات مجوز برنامه
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}
