import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tourism_item.dart';

/// مدیریت مرکزی علاقه‌مندی‌های سایروس توریست.
///
/// این سرویس بین کلیدهای ۲ تا ۱۰ مشترک است.
/// وضعیت علاقه‌مندی داخل TourismItem ذخیره نمی‌شود.
class FavoritesService {
  static const String _storageKey = 'cyrus_tourist_favorites';

  final List<TourismItem> _items = [];

  /// فهرست علاقه‌مندی‌ها به صورت فقط‌خواندنی
  List<TourismItem> get items => List.unmodifiable(_items);

  /// تعداد علاقه‌مندی‌ها
  int get count => _items.length;

  /// بررسی وجود یک آیتم در علاقه‌مندی‌ها
  bool contains(String id) {
    return _items.any((item) => item.id == id);
  }

  /// بارگذاری علاقه‌مندی‌های ذخیره‌شده
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedItems = prefs.getStringList(_storageKey) ?? <String>[];

    _items.clear();

    for (final value in savedItems) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map<String, dynamic>) {
          _items.add(TourismItem.fromMap(decoded));
        }
      } catch (_) {
        // داده خراب نباید باعث Crash برنامه شود.
        continue;
      }
    }
  }

  /// اضافه کردن یک آیتم
  Future<void> add(TourismItem item) async {
    if (contains(item.id)) {
      return;
    }

    _items.add(item);
    await _save();
  }

  /// حذف یک آیتم
  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
  }

  /// افزودن یا حذف هوشمند
  Future<void> toggle(TourismItem item) async {
    if (contains(item.id)) {
      await remove(item.id);
    } else {
      await add(item);
    }
  }

  /// حذف همه علاقه‌مندی‌ها
  Future<void> clearAll() async {
    _items.clear();
    await _save();
  }

  /// ذخیره دائمی اطلاعات
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final values = _items
        .map((item) => jsonEncode(item.toMap()))
        .toList();

    await prefs.setStringList(_storageKey, values);
  }
}
