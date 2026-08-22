import '../models/tourism_item.dart';

/// سرویس داده‌های صفحه اصلی سایروس توریست.
///
/// این سرویس داده‌های مورد نیاز صفحه Home را
/// از فهرست اصلی TourismItem دریافت و دسته‌بندی می‌کند.
class HomeDataService {
  /// دریافت تمام آیتم‌های معتبر.
  List<TourismItem> getAll({
    required List<TourismItem> items,
  }) {
    return items.where(_isValid).toList();
  }

  /// دریافت جاذبه‌های گردشگری.
  List<TourismItem> getAttractions({
    required List<TourismItem> items,
  }) {
    return _byTypes(
      items,
      const ['attraction'],
    );
  }

  /// دریافت اقامتگاه‌ها.
  List<TourismItem> getAccommodations({
    required List<TourismItem> items,
  }) {
    return _byTypes(
      items,
      const ['accommodation'],
    );
  }

  /// دریافت مراکز سلامت.
  List<TourismItem> getHealthCenters({
    required List<TourismItem> items,
  }) {
    return _byTypes(
      items,
      const ['health'],
    );
  }

  /// دریافت ویدئوهای گردشگری.
  List<TourismItem> getVideos({
    required List<TourismItem> items,
  }) {
    return items.where(
      (item) =>
          _isValid(item) &&
          item.type.trim().toLowerCase() == 'video' &&
          item.hasVideo,
    ).toList();
  }

  /// دریافت خدمات گردشگری.
  List<TourismItem> getServices({
    required List<TourismItem> items,
  }) {
    return _byTypes(
      items,
      const ['service'],
    );
  }

  /// دریافت راهنماهای سفر.
  List<TourismItem> getTravelGuides({
    required List<TourismItem> items,
  }) {
    return _byTypes(
      items,
      const [
        'travelguide',
        'travel_guide',
      ],
    );
  }

  /// دریافت آیتم‌های دارای موقعیت جغرافیایی.
  List<TourismItem> getMapItems({
    required List<TourismItem> items,
  }) {
    return items.where(
      (item) =>
          _isValid(item) &&
          item.hasLocation,
    ).toList();
  }

  /// دریافت آیتم‌های دارای تصویر.
  List<TourismItem> getItemsWithImages({
    required List<TourismItem> items,
  }) {
    return items.where(
      (item) =>
          _isValid(item) &&
          item.imageUrl != null &&
          item.imageUrl!.trim().isNotEmpty,
    ).toList();
  }

  /// دریافت آیتم‌های یک دسته‌بندی مشخص.
  List<TourismItem> getByCategory({
    required List<TourismItem> items,
    required String category,
  }) {
    final normalizedCategory =
        category.trim().toLowerCase();

    if (normalizedCategory.isEmpty) {
      return <TourismItem>[];
    }

    return items.where(
      (item) =>
          _isValid(item) &&
          (item.category ?? '')
              .trim()
              .toLowerCase() ==
          normalizedCategory,
    ).toList();
  }

  /// دریافت آیتم‌های پیشنهادی صفحه اصلی.
  ///
  /// ترتیب اولویت:
  /// جاذبه، اقامتگاه، سلامت، ویدئو،
  /// خدمات و راهنمای سفر.
  List<TourismItem> getFeatured({
    required List<TourismItem> items,
    int limit = 10,
  }) {
    if (limit <= 0) {
      return <TourismItem>[];
    }

    final result = <TourismItem>[];

    final groups = <List<TourismItem>>[
      getAttractions(items: items),
      getAccommodations(items: items),
      getHealthCenters(items: items),
      getVideos(items: items),
      getServices(items: items),
      getTravelGuides(items: items),
    ];

    for (final group in groups) {
      for (final item in group) {
        if (result.length >= limit) {
          return result;
        }

        if (!result.any(
          (existing) => existing.id == item.id,
        )) {
          result.add(item);
        }
      }
    }

    return result;
  }

  /// محدود کردن تعداد آیتم‌ها.
  List<TourismItem> limit(
    List<TourismItem> items,
    int count,
  ) {
    if (count <= 0) {
      return <TourismItem>[];
    }

    if (items.length <= count) {
      return List<TourismItem>.from(items);
    }

    return items.take(count).toList();
  }

  /// فیلتر بر اساس چند نوع محتوا.
  List<TourismItem> _byTypes(
    List<TourismItem> items,
    List<String> types,
  ) {
    final normalizedTypes = types
        .map(
          (type) => type.trim().toLowerCase(),
        )
        .toSet();

    return items.where(
      (item) =>
          _isValid(item) &&
          normalizedTypes.contains(
            item.type.trim().toLowerCase(),
          ),
    ).toList();
  }

  /// بررسی معتبر بودن آیتم.
  bool _isValid(TourismItem item) {
    return item.id.trim().isNotEmpty &&
        item.type.trim().isNotEmpty &&
        (
          item.titleFa.trim().isNotEmpty ||
          item.titleEn.trim().isNotEmpty ||
          item.titleAr.trim().isNotEmpty
        );
  }
}
