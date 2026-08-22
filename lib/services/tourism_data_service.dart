import '../models/tourism_item.dart';

/// منبع مرکزی داده‌های گردشگری سایروس توریست.
///
/// این سرویس محل واحد نگهداری و دسترسی به داده‌های:
/// جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت، فیلم‌ها،
/// راهنماهای سفر و خدمات است.
///
/// در این مرحله هیچ اطلاعات، لینک یا مختصات ساختگی
/// تولید نمی‌شود.
class TourismDataService {
  TourismDataService._();

  static final TourismDataService instance =
      TourismDataService._();

  // ------------------------------------------------------------
  // فهرست مرکزی
  // ------------------------------------------------------------

  final List<TourismItem> _items = [];

  /// تمام آیتم‌های ثبت‌شده
  List<TourismItem> get items {
    return List.unmodifiable(_items);
  }

  /// تعداد کل آیتم‌ها
  int get count => _items.length;

  // ------------------------------------------------------------
  // افزودن یک آیتم
  // ------------------------------------------------------------

  void add(TourismItem item) {
    if (item.id.trim().isEmpty) {
      return;
    }

    final existingIndex = _items.indexWhere(
      (element) => element.id == item.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = item;
      return;
    }

    _items.add(item);
  }

  // ------------------------------------------------------------
  // افزودن چند آیتم
  // ------------------------------------------------------------

  void addAll(Iterable<TourismItem> items) {
    for (final item in items) {
      add(item);
    }
  }

  // ------------------------------------------------------------
  // حذف آیتم
  // ------------------------------------------------------------

  bool remove(String id) {
    final before = _items.length;

    _items.removeWhere(
      (item) => item.id == id,
    );

    return _items.length != before;
  }

  // ------------------------------------------------------------
  // حذف همه داده‌ها
  // ------------------------------------------------------------

  void clear() {
    _items.clear();
  }

  // ------------------------------------------------------------
  // دریافت آیتم با شناسه
  // ------------------------------------------------------------

  TourismItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // بررسی وجود آیتم
  // ------------------------------------------------------------

  bool contains(String id) {
    return _items.any(
      (item) => item.id == id,
    );
  }

  // ------------------------------------------------------------
  // دریافت بر اساس نوع
  // ------------------------------------------------------------

  List<TourismItem> byType(String type) {
    final normalizedType =
        type.trim().toLowerCase();

    return _items
        .where(
          (item) =>
              item.type.trim().toLowerCase() ==
              normalizedType,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // دریافت چند نوع
  // ------------------------------------------------------------

  List<TourismItem> byTypes(
    Iterable<String> types,
  ) {
    final normalizedTypes = types
        .map(
          (type) => type.trim().toLowerCase(),
        )
        .toSet();

    return _items
        .where(
          (item) => normalizedTypes.contains(
            item.type.trim().toLowerCase(),
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------
  // دریافت بر اساس دسته‌بندی
  // ------------------------------------------------------------

  List<TourismItem> byCategory(
    String category,
  ) {
    final normalizedCategory =
        category.trim().toLowerCase();

    return _items
        .where(
          (item) =>
              (item.category ?? '')
                  .trim()
                  .toLowerCase() ==
              normalizedCategory,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // فقط آیتم‌های دارای موقعیت
  // ------------------------------------------------------------

  List<TourismItem> withLocation() {
    return _items
        .where(
          (item) => item.hasLocation,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // فقط آیتم‌های دارای ویدئو
  // ------------------------------------------------------------

  List<TourismItem> withVideo() {
    return _items
        .where(
          (item) => item.hasVideo,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // فقط آیتم‌های دارای لینک رزرو
  // ------------------------------------------------------------

  List<TourismItem> withBooking() {
    return _items
        .where(
          (item) => item.hasBooking,
        )
        .toList();
  }

  // ------------------------------------------------------------
  // جاذبه‌های گردشگری
  // ------------------------------------------------------------

  List<TourismItem> get attractions {
    return byType('attraction');
  }

  // ------------------------------------------------------------
  // اقامتگاه‌ها
  // ------------------------------------------------------------

  List<TourismItem> get accommodations {
    return byType('accommodation');
  }

  // ------------------------------------------------------------
  // مراکز سلامت
  // ------------------------------------------------------------

  List<TourismItem> get healthCenters {
    return byType('health');
  }

  // ------------------------------------------------------------
  // فیلم‌های گردشگری
  // ------------------------------------------------------------

  List<TourismItem> get videos {
    return byType('video');
  }

  // ------------------------------------------------------------
  // راهنماهای سفر
  // ------------------------------------------------------------

  List<TourismItem> get travelGuides {
    return byType('travelGuide');
  }

  // ------------------------------------------------------------
  // خدمات
  // ------------------------------------------------------------

  List<TourismItem> get services {
    return byType('service');
  }
}
