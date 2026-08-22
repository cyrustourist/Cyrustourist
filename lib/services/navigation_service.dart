import 'package:flutter/services.dart';

import '../models/tourism_item.dart';
import 'map_service.dart';

/// سرویس مرکزی باز کردن مسیر و مقصد.
///
/// این سرویس برای تمام بخش‌های برنامه مشترک است:
/// سلامت، جاذبه‌ها، اقامتگاه‌ها و خدمات.
///
/// مختصات جعلی ایجاد نمی‌کند.
/// اگر مقصد مختصات معتبر نداشته باشد، مسیریابی انجام نمی‌شود.
class NavigationService {
  final MapService _mapService = MapService();

  /// ساخت لینک مسیریابی برای یک مقصد.
  String? buildDirectionsUrl({
    required double? userLatitude,
    required double? userLongitude,
    required TourismItem destination,
  }) {
    return _mapService.buildDirectionsUrl(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      destination: destination,
    );
  }

  /// ساخت لینک مشاهده مقصد روی نقشه.
  String? buildDestinationMapUrl(
    TourismItem destination,
  ) {
    return _mapService.buildMapUrl(destination);
  }

  /// کپی کردن لینک مسیریابی برای استفاده در UI.
  Future<void> copyNavigationUrl(String url) async {
    await Clipboard.setData(
      ClipboardData(text: url),
    );
  }

  /// بررسی امکان مسیریابی.
  bool canNavigateTo(TourismItem item) {
    return item.hasLocation;
  }

  /// بررسی امکان نمایش مقصد روی نقشه.
  bool canShowOnMap(TourismItem item) {
    return item.hasLocation;
  }
}
