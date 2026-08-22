import '../models/tourism_item.dart';

/// سرویس مرکزی مدیریت محتوای گردشگری سایروس توریست.
///
/// این سرویس برای نگهداری، افزودن، حذف و به‌روزرسانی
/// آیتم‌های گردشگری در حافظه برنامه استفاده می‌شود.
class ContentService {
  final List<TourismItem> _items = [];

  /// تمام آیتم‌های موجود
  List<TourismItem> get items => List.unmodifiable(_items);

  /// تعداد آیتم‌ها
  int get count => _items.length;

  /// بررسی وجود آیتم با شناسه مشخص
  bool contains(String id) {
    return _items.any((item) => item.id == id);
  }

  /// دریافت آیتم بر اساس شناسه
  TourismItem? getById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  /// دریافت آیتم‌ها بر اساس نوع
  List<TourismItem> getByType(String type) {
    return _items
        .where(
          (item) =>
              item.type.toLowerCase() ==
              type.toLowerCase(),
        )
        .toList();
  }

  /// دریافت آیتم‌ها بر اساس دسته‌بندی
  List<TourismItem> getByCategory(String category) {
    return _items
        .where(
          (item) =>
              (item.category ?? '').toLowerCase() ==
              category.toLowerCase(),
        )
        .toList();
  }

  /// افزودن یک آیتم
  bool add(TourismItem item) {
    if (contains(item.id)) {
      return false;
    }

    _items.add(item);
    return true;
  }

  /// افزودن چند آیتم
  void addAll(Iterable<TourismItem> items) {
    for (final item in items) {
      add(item);
    }
  }

  /// به‌روزرسانی یک آیتم موجود
  bool update(TourismItem item) {
    final index = _items.indexWhere(
      (value) => value.id == item.id,
    );

    if (index == -1) {
      return false;
    }

    _items[index] = item;
    return true;
  }

  /// افزودن یا به‌روزرسانی آیتم
  void upsert(TourismItem item) {
    if (!update(item)) {
      add(item);
    }
  }

  /// حذف آیتم بر اساس شناسه
  bool remove(String id) {
    final index = _items.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return false;
    }

    _items.removeAt(index);
    return true;
  }

  /// حذف همه آیتم‌ها
  void clear() {
    _items.clear();
  }

  /// جایگزینی کامل فهرست محتوا
  void replaceAll(Iterable<TourismItem> items) {
    _items.clear();
    addAll(items);
  }

  /// بررسی خالی بودن فهرست
  bool get isEmpty => _items.isEmpty;

  /// بررسی داشتن محتوا
  bool get isNotEmpty => _items.isNotEmpty;
}
