import 'package:geolocator/geolocator.dart';

import '../models/tourism_item.dart';

/// سرویس مرکزی فاصله و پایه مسیریابی سایروس توریست.
///
/// برای جاذبه‌ها، مراکز سلامت، اقامتگاه‌ها و سایر
/// مکان‌های دارای مختصات استفاده می‌شود.
///
/// این سرویس هیچ مختصات جعلی تولید نمی‌کند.
class RoutingService {
  /// محاسبه فاصله بر حسب متر
  double distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// محاسبه فاصله بر حسب کیلومتر
  double distanceInKilometers({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return distanceInMeters(
          startLatitude: startLatitude,
          startLongitude: startLongitude,
          endLatitude: endLatitude,
          endLongitude: endLongitude,
        ) /
        1000;
  }

  /// محاسبه فاصله کاربر تا یک مکان گردشگری
  double? distanceToItem({
    required double userLatitude,
    required double userLongitude,
    required TourismItem item,
  }) {
    if (!item.hasLocation) {
      return null;
    }

    return distanceInKilometers(
      startLatitude: userLatitude,
      startLongitude: userLongitude,
      endLatitude: item.latitude!,
      endLongitude: item.longitude!,
    );
  }

  /// مرتب‌سازی مکان‌ها از نزدیک‌ترین تا دورترین
  List<TourismItem> sortByDistance({
    required List<TourismItem> items,
    required double userLatitude,
    required double userLongitude,
  }) {
    final validItems = items
        .where((item) => item.hasLocation)
        .toList();

    validItems.sort((a, b) {
      final distanceA = distanceToItem(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        item: a,
      );

      final distanceB = distanceToItem(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        item: b,
      );

      if (distanceA == null && distanceB == null) {
        return 0;
      }

      if (distanceA == null) {
        return 1;
      }

      if (distanceB == null) {
        return -1;
      }

      return distanceA.compareTo(distanceB);
    });

    return validItems;
  }

  /// فیلتر مکان‌ها بر اساس شعاع انتخاب‌شده.
  ///
  /// نمونه فاصله‌ها:
  /// 5، 10، 15، 25، 50، 100 کیلومتر
  ///
  /// اگر مقدار null باشد، محدودیت فاصله اعمال نمی‌شود.
  List<TourismItem> filterByRadius({
    required List<TourismItem> items,
    required double userLatitude,
    required double userLongitude,
    double? radiusKm,
  }) {
    if (radiusKm == null) {
      return sortByDistance(
        items: items,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    }

    final result = <TourismItem>[];

    for (final item in items) {
      if (!item.hasLocation) {
        continue;
      }

      final distance = distanceToItem(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        item: item,
      );

      if (distance != null && distance <= radiusKm) {
        result.add(item);
      }
    }

    result.sort((a, b) {
      final distanceA = distanceToItem(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        item: a,
      );

      final distanceB = distanceToItem(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        item: b,
      );

      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    return result;
  }

  /// تبدیل فاصله به متن قابل نمایش
  String formatDistance(double kilometers) {
    if (kilometers < 1) {
      final meters = (kilometers * 1000).round();
      return '$meters متر';
    }

    if (kilometers < 10) {
      return '${kilometers.toStringAsFixed(1)} کیلومتر';
    }

    return '${kilometers.round()} کیلومتر';
  }

  /// لینک استاندارد Google Maps برای مختصات معتبر.
  ///
  /// در صورت نبود مختصات، null برمی‌گرداند.
  String? buildMapsUrl(TourismItem item) {
    if (!item.hasLocation) {
      return null;
    }

    return 'https://www.google.com/maps/search/?api=1'
        '&query=${item.latitude},${item.longitude}';
  }
}
