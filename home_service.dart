import '../models/tourism_item.dart';

/// سرویس مدیریت محتوای صفحه اصلی سایروس توریست.
///
/// این سرویس محتوای مناسب برای نمایش در Home را
/// از میان اطلاعات گردشگری انتخاب و آماده می‌کند.
class HomeService {
  /// دریافت محتوای صفحه اصلی.
  ///
  /// ابتدا آیتم‌های معتبر را نگه می‌دارد و سپس
  /// بر اساس اولویت نوع محتوا مرتب می‌کند.
  List<TourismItem> getHomeItems({
    required List<TourismItem> items,
    int limit = 10,
  }) {
    if (items.isEmpty || limit <= 0) {
      return <TourismItem>[];
    }

    final validItems = items.where(_isValidItem).toList();

    validItems.sort(
      (a, b) => _typePriority(a.type)
          .compareTo(_typePriority(b.type)),
    );

    if (validItems.length <= limit) {
      return validItems;
    }

    return validItems.take(limit).toList();
  }

  /// دریافت جاذبه‌های پیشنهادی صفحه اصلی.
  List<TourismItem> getFeaturedAttractions({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    return _filterByTypes(
      items: items,
      types: const ['attraction'],
      limit: limit,
    );
  }

  /// دریافت اقامتگاه‌های پیشنهادی.
  List<TourismItem> getFeaturedAccommodations({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    return _filterByTypes(
      items: items,
      types: const ['accommodation'],
      limit: limit,
    );
  }

  /// دریافت مراکز سلامت.
  List<TourismItem> getHealthItems({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    return _filterByTypes(
      items: items,
      types: const ['health'],
      limit: limit,
    );
  }

  /// دریافت ویدئوهای گردشگری.
  List<TourismItem> getVideos({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    final videos = items.where(
      (item) =>
          item.type.toLowerCase() == 'video' &&
          item.hasVideo,
    );

    final result = videos.toList();

    if (result.length <= limit) {
      return result;
    }

    return result.take(limit).toList();
  }

  /// دریافت راهنماهای سفر.
  List<TourismItem> getTravelGuides({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    return _filterByTypes(
      items: items,
      types: const ['travelguide', 'travel_guide'],
      limit: limit,
    );
  }

  /// دریافت خدمات گردشگری.
  List<TourismItem> getServices({
    required List<TourismItem> items,
    int limit = 6,
  }) {
    return _filterByTypes(
      items: items,
      types: const ['service'],
      limit: limit,
    );
  }

  /// دریافت آیتم‌هایی که موقعیت جغرافیایی دارند.
  List<TourismItem> getMapItems({
    required List<TourismItem> items,
    int limit = 100,
  }) {
    final result = items
        .where(
          (item) => _isValidItem(item) && item.hasLocation,
        )
        .toList();

    if (result.length <= limit) {
      return result;
    }

    return result.take(limit).toList();
  }

  /// دریافت آیتم‌های دارای تصویر.
  List<TourismItem> getItemsWithImages({
    required List<TourismItem> items,
    int limit = 10,
  }) {
    final result = items.where(
      (item) =>
          _isValidItem(item) &&
          item.imageUrl != null &&
          item.imageUrl!.trim().isNotEmpty,
    ).toList();

    if (result.length <= limit) {
      return result;
    }

    return result.take(limit).toList();
  }

  /// دریافت آیتم‌های یک دسته‌بندی.
  List<TourismItem> getByCategory({
    required List<TourismItem> items,
    required String category,
    int limit = 10,
  }) {
    final normalizedCategory = category.trim().toLowerCase();

    if (normalizedCategory.isEmpty || limit <= 0) {
      return <TourismItem>[];
    }

    final result = items.where(
      (item) =>
          _isValidItem(item) &&
          (item.category ?? '').trim().toLowerCase() ==
              normalizedCategory,
    ).toList();

    if (result.length <= limit) {
      return result;
    }

    return result.take(limit).toList();
  }

  /// بررسی معتبر بودن آیتم برای Home.
  bool _isValidItem(TourismItem item) {
    return item.id.trim().isNotEmpty &&
        item.type.trim().isNotEmpty &&
        (item.titleFa.trim().isNotEmpty ||
            item.titleEn.trim().isNotEmpty ||
            item.titleAr.trim().isNotEmpty);
  }

  /// فیلتر کردن چند نوع محتوا.
  List<TourismItem> _filterByTypes({
    required List<TourismItem> items,
    required List<String> types,
    required int limit,
  }) {
    if (limit <= 0) {
      return <TourismItem>[];
    }

    final normalizedTypes = types
        .map((type) => type.toLowerCase())
        .toSet();

    final result = items.where(
      (item) =>
          _isValidItem(item) &&
          normalizedTypes.contains(
            item.type.trim().toLowerCase(),
          ),
    ).toList();

    if (result.length <= limit) {
      return result;
    }

    return result.take(limit).toList();
  }

  /// اولویت نمایش انواع محتوا در صفحه اصلی.
  int _typePriority(String type) {
    switch (type.trim().toLowerCase()) {
      case 'attraction':
        return 1;

      case 'accommodation':
        return 2;

      case 'health':
        return 3;

      case 'video':
        return 4;

      case 'service':
        return 5;

      case 'travelguide':
      case 'travel_guide':
        return 6;

      default:
        return 99;
    }
  }
}
