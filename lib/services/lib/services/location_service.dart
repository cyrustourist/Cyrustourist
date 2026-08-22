import 'package:geolocator/geolocator.dart';

/// سرویس مرکزی موقعیت مکانی سایروس توریست.
///
/// وظایف:
/// - بررسی فعال بودن GPS
/// - بررسی مجوز موقعیت
/// - درخواست مجوز در صورت نیاز
/// - دریافت موقعیت فعلی
/// - ارائه Stream برای به‌روزرسانی موقعیت
///
/// این سرویس هیچ مختصات جعلی تولید نمی‌کند.
class LocationService {
  /// بررسی فعال بودن سرویس موقعیت مکانی دستگاه
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// دریافت وضعیت مجوز موقعیت
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// درخواست مجوز موقعیت از کاربر
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// بررسی اینکه برنامه مجوز معتبر برای GPS دارد یا خیر
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// آماده بودن GPS و مجوز
  Future<bool> isReady() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    return hasPermission();
  }

  /// درخواست مجوز و آماده‌سازی GPS
  ///
  /// اگر GPS خاموش باشد یا کاربر مجوز ندهد،
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

  /// دریافت موقعیت فعلی کاربر
  ///
  /// در صورت خطا یا نبود GPS مقدار null برگردانده می‌شود.
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

  /// دریافت موقعیت با دقت کمتر برای مواردی که سرعت اهمیت بیشتری دارد
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Stream مرکزی تغییرات موقعیت کاربر
  ///
  /// distanceFilter باعث می‌شود با هر تغییر بسیار کوچک
  /// درخواست جدید ایجاد نشود.
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// باز کردن تنظیمات موقعیت دستگاه
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// باز کردن تنظیمات مجوز برنامه
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}
