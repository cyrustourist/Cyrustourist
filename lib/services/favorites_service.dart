import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tourism_item.dart';

/// مدیریت مرکزی علاقه‌مندی‌های سایروس توریست.
///
/// این سرویس بین کلیدهای ۲ تا ۱۰ مشترک است.
///
/// قابلیت‌ها:
/// - افزودن
/// - حذف
/// - Toggle
/// - حذف همه
/// - ذخیره دائمی
/// - بازیابی پس از اجرای دوباره برنامه
/// - جستجو
/// - فیلتر بر اساس نوع محتوا
/// - مرتب‌سازی
/// - بدون ایجاد مختصات جعلی
///
/// وضعیت Favorite عمداً داخل TourismItem ذخیره نمی‌شود.
class FavoritesService {
  static const String _storageKey =
      'cyrus_tourist_favorites';

  final List<TourismItem> _items = [];

  bool _loaded = false;

  // ------------------------------------------------------------
  // اطلاعات عمومی
  // ------------------------------------------------------------

  /// فهرست علاقه‌مندی‌ها به صورت فقط‌خواندنی
  List<TourismItem> get items =>
      List.unmodifiable(_items);

  /// تعداد علاقه‌مندی‌ها
  int get count => _items.length;

  /// آیا هنوز اطلاعات از حافظه بارگذاری نشده است؟
  bool get isLoaded => _loaded;

  /// آیا فهرست خالی است؟
  bool get isEmpty => _items.isEmpty;

  /// آیا فهرست خالی نیست؟
  bool get isNotEmpty => _items.isNotEmpty;

  // ------------------------------------------------------------
  // بررسی Favorite
  // ------------------------------------------------------------

  /// بررسی وجود یک آیتم در علاقه‌مندی‌ها
  bool contains(String id) {
    return _items.any(
      (item) => item.id == id,
    );
  }

  /// دریافت یک آیتم بر اساس ID
  TourismItem? getById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // بارگذاری
  // ------------------------------------------------------------

  /// بارگذاری علاقه‌مندی‌های ذخیره‌شده.
  ///
  /// داده خراب نباید باعث Crash برنامه شود.
  Future<void> load() async {
    if (_loaded) {
      return;
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final savedItems =
          prefs.getStringList(_storageKey) ??
              <String>[];

      _items.clear();

      for (final value in savedItems) {
        try {
          final decoded = jsonDecode(value);

          if (decoded is Map) {
            final map =
                Map<String, dynamic>.from(decoded);

            final item = TourismItem.fromMap(map);

            if (item.id.trim().isNotEmpty) {
              _items.add(item);
            }
          }
        } catch (_) {
          // یک آیتم خراب نباید باعث Crash برنامه شود.
          continue;
        }
      }
    } catch (_) {
      // خطای حافظه محلی نباید باعث Crash برنامه شود.
      _items.clear();
    }

    _loaded = true;
  }

  // ------------------------------------------------------------
  // افزودن
  // ------------------------------------------------------------

  /// اضافه کردن یک آیتم.
  Future<bool> add(TourismItem item) async {
    if (item.id.trim().isEmpty) {
      return false;
    }

    if (contains(item.id)) {
      return false;
    }

    _items.add(item);

    await _save();

    return true;
  }

  // ------------------------------------------------------------
  // حذف
  // ------------------------------------------------------------

  /// حذف یک آیتم
  Future<bool> remove(String id) async {
    final oldLength = _items.length;

    _items.removeWhere(
      (item) => item.id == id,
    );

    if (_items.length == oldLength) {
      return false;
    }

    await _save();

    return true;
  }

  // ------------------------------------------------------------
  // Toggle
  // ------------------------------------------------------------

  /// افزودن یا حذف هوشمند.
  ///
  /// خروجی:
  /// true  = آیتم اضافه شد
  /// false = آیتم حذف شد
  Future<bool> toggle(TourismItem item) async {
    if (contains(item.id)) {
      await remove(item.id);
      return false;
    }

    await add(item);
    return true;
  }

  // ------------------------------------------------------------
  // حذف همه
  // ------------------------------------------------------------

  /// حذف تمام علاقه‌مندی‌ها.
  ///
  /// تأیید نمایش داده نمی‌شود و UI باید قبل از اجرای این
  /// متد از کاربر تأیید بگیرد.
  Future<void> clearAll() async {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();

    await _save();
  }

  // ------------------------------------------------------------
  // جستجو
  // ------------------------------------------------------------

  /// جستجو در علاقه‌مندی‌ها.
  ///
  /// عنوان، توضیحات، دسته‌بندی و آدرس را بررسی می‌کند.
  /// جستجو برای فارسی، انگلیسی و عربی آماده است.
  List<TourismItem> search(
    String query, {
    String languageCode = 'fa',
  }) {
    final normalizedQuery =
        _normalize(query);

    if (normalizedQuery.isEmpty) {
      return List<TourismItem>.from(_items);
    }

    return _items.where((item) {
      final title = _normalize(
        item.titleForLanguage(languageCode),
      );

      final description = _normalize(
        item.descriptionForLanguage(languageCode),
      );

      final category = _normalize(
        item.category ?? '',
      );

      final address = _normalize(
        item.address ?? '',
      );

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          category.contains(normalizedQuery) ||
          address.contains(normalizedQuery);
    }).toList();
  }

  // ------------------------------------------------------------
  // فیلتر نوع محتوا
  // ------------------------------------------------------------

  /// دریافت علاقه‌مندی‌های یک نوع خاص.
  ///
  /// نمونه:
  /// attraction
  /// accommodation
  /// health
  /// video
  /// travelGuide
  List<TourismItem> byType(String type) {
    return _items.where(
      (item) =>
          item.type.toLowerCase() ==
          type.toLowerCase(),
    ).toList();
  }

  /// دریافت چند نوع محتوا به صورت هم‌زمان.
  List<TourismItem> byTypes(
    List<String> types,
  ) {
    final normalizedTypes = types
        .map((type) => type.toLowerCase())
        .toSet();

    return _items.where(
      (item) => normalizedTypes.contains(
        item.type.toLowerCase(),
      ),
    ).toList();
  }

  // ------------------------------------------------------------
  // مرتب‌سازی
  // ------------------------------------------------------------

  /// مرتب‌سازی بر اساس عنوان.
  List<TourismItem> sortByTitle({
    String languageCode = 'fa',
    bool ascending = true,
  }) {
    final result =
        List<TourismItem>.from(_items);

    result.sort((a, b) {
      final titleA = a
          .titleForLanguage(languageCode)
          .toLowerCase();

      final titleB = b
          .titleForLanguage(languageCode)
          .toLowerCase();

      final comparison =
          titleA.compareTo(titleB);

      return ascending
          ? comparison
          : -comparison;
    });

    return result;
  }

  /// مرتب‌سازی بر اساس نوع محتوا.
  List<TourismItem> sortByType({
    bool ascending = true,
  }) {
    final result =
        List<TourismItem>.from(_items);

    result.sort((a, b) {
      final comparison =
          a.type.compareTo(b.type);

      return ascending
          ? comparison
          : -comparison;
    });

    return result;
  }

  // ------------------------------------------------------------
  // اطلاعات آماری
  // ------------------------------------------------------------

  /// تعداد علاقه‌مندی‌های هر نوع محتوا.
  int countByType(String type) {
    return _items.where(
      (item) =>
          item.type.toLowerCase() ==
          type.toLowerCase(),
    ).length;
  }

  /// تعداد جاذبه‌ها
  int get attractionCount =>
      countByType('attraction');

  /// تعداد اقامتگاه‌ها
  int get accommodationCount =>
      countByType('accommodation');

  /// تعداد مراکز سلامت
  int get healthCount =>
      countByType('health');

  /// تعداد فیلم‌ها
  int get videoCount =>
      countByType('video');

  /// تعداد راهنماهای سفر
  int get travelGuideCount =>
      countByType('travelGuide');

  // ------------------------------------------------------------
  // ذخیره‌سازی
  // ------------------------------------------------------------

  /// ذخیره دائمی اطلاعات.
  Future<void> _save() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final values = _items
          .map(
            (item) => jsonEncode(
              item.toMap(),
            ),
          )
          .toList();

      await prefs.setStringList(
        _storageKey,
        values,
      );
    } catch (_) {
      // خطای ذخیره‌سازی نباید باعث Crash برنامه شود.
    }
  }

  // ------------------------------------------------------------
  // نرمال‌سازی جستجو
  // ------------------------------------------------------------

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }
}
