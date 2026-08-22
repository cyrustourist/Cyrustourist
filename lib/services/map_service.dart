import 'dart:math' as math;

import '../models/tourism_item.dart';

/// سرویس مرکزی نقشه سایروس توریست.
///
/// وظایف این سرویس:
/// - آماده‌سازی آیتم‌ها برای نمایش روی نقشه
/// - تشخیص آیتم‌های دارای مختصات معتبر
/// - فیلتر بر اساس نوع محتوا
/// - محاسبه محدوده مناسب نقشه
/// - تعیین رنگ منطقی Marker بر اساس نوع محتوا
///
/// این سرویس هیچ مختصات ساختگی تولید نمی‌کند.
class MapService {
  /// فقط آیتم‌هایی که مختصات معتبر دارند.
  List<TourismItem> itemsWithLocation(
    List<TourismItem> items,
  ) {
    return items
        .where((item) => item.hasLocation)
        .toList();
  }

  /// فیلتر آیتم‌های نقشه بر اساس نوع محتوا.
  ///
  /// نمونه:
  /// health
  /// attraction
  /// accommodation
  /// service
  List<TourismItem> filterByType(
    List<TourismItem> items,
    String type,
  ) {
    return items
        .where(
          (item) =>
              item.hasLocation &&
              item.type.toLowerCase() == type.toLowerCase(),
        )
        .toList();
  }

  /// فیلتر چند نوع محتوا به صورت هم‌زمان.
  List<TourismItem> filterByTypes(
    List<TourismItem> items,
    List<String> types,
  ) {
    final normalizedTypes = types
        .map((type) => type.toLowerCase())
        .toSet();

    return items.where((item) {
      return item.hasLocation &&
          normalizedTypes.contains(item.type.toLowerCase());
    }).toList();
  }

  /// تعیین رنگ منطقی Marker بر اساس نوع محتوا.
  ///
  /// رنگ‌ها در UI نهایی استفاده می‌شوند:
  /// سلامت = قرمز
  /// جاذبه = آبی
  /// اقامتگاه = سبز
  /// خدمات = نارنجی
  /// سایر = بنفش
  String markerColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'health':
        return 'red';

      case 'attraction':
        return 'blue';

      case 'accommodation':
        return 'green';

      case 'service':
        return 'orange';

      case 'video':
        return 'purple';

      case 'travelguide':
      case 'travel_guide':
        return 'teal';

      default:
        return 'purple';
    }
  }

  /// نام آیکن منطقی Marker برای استفاده در UI.
  String markerIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'health':
        return 'medical_services';

      case 'attraction':
        return 'place';

      case 'accommodation':
        return 'hotel';

      case 'service':
        return 'build';

      case 'video':
        return 'play_circle';

      case 'travelguide':
      case 'travel_guide':
        return 'map';

      default:
        return 'location_on';
    }
  }

  /// بررسی اینکه مختصات در محدوده معتبر کره زمین هستند یا خیر.
  bool isValidCoordinate(
    double? latitude,
    double? longitude,
  ) {
    if (latitude == null || longitude == null) {
      return false;
    }

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// ساخت محدوده جغرافیایی از چند آیتم.
  ///
  /// خروجی:
  /// [minLatitude, minLongitude, maxLatitude, maxLongitude]
  ///
  /// اگر هیچ مختصات معتبری وجود نداشته باشد، null برمی‌گرداند.
  List<double>? calculateBounds(
    List<TourismItem> items,
  ) {
    final validItems = itemsWithLocation(items);

    if (validItems.isEmpty) {
      return null;
    }

    var minLatitude = validItems.first.latitude!;
    var maxLatitude = validItems.first.latitude!;
    var minLongitude = validItems.first.longitude!;
    var maxLongitude = validItems.first.longitude!;

    for (final item in validItems.skip(1)) {
      final latitude = item.latitude!;
      final longitude = item.longitude!;

      minLatitude = math.min(minLatitude, latitude);
      maxLatitude = math.max(maxLatitude, latitude);
      minLongitude = math.min(minLongitude, longitude);
      maxLongitude = math.max(maxLongitude, longitude);
    }

    return [
      minLatitude,
      minLongitude,
      maxLatitude,
      maxLongitude,
    ];
  }

  /// ساخت لینک Google Maps برای یک آیتم دارای مختصات.
  ///
  /// در صورت نبود مختصات معتبر، null برمی‌گرداند.
  String? buildMapUrl(TourismItem item) {
    if (!item.hasLocation) {
      return null;
    }

    return 'https://www.google.com/maps/search/?api=1'
        '&query=${item.latitude},${item.longitude}';
  }

  /// ساخت لینک مسیریابی Google Maps برای یک مقصد.
  ///
  /// مختصات کاربر و مقصد باید واقعی باشند.
  String? buildDirectionsUrl({
    required double? userLatitude,
    required double? userLongitude,
    required TourismItem destination,
  }) {
    if (!destination.hasLocation) {
      return null;
    }

    if (!isValidCoordinate(
      userLatitude,
      userLongitude,
    )) {
      return null;
    }

    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=$userLatitude,$userLongitude'
        '&destination=${destination.latitude},'
        '${destination.longitude}'
        '&travelmode=driving';
  }
}
