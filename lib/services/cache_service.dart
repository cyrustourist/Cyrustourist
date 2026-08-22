import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مرکزی Cache سایروس توریست.
///
/// برای ذخیره موقت داده‌های متنی و JSON استفاده می‌شود.
/// این سرویس مستقل طراحی شده تا بعداً بتوانیم Cache را
/// بدون تغییر در صفحات برنامه مدیریت کنیم.
class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  SharedPreferences? _prefs;

  /// آماده‌سازی سرویس
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// دریافت SharedPreferences آماده
  Future<SharedPreferences> get _storage async {
    await initialize();
    return _prefs!;
  }

  /// ذخیره متن
  Future<bool> setString(
    String key,
    String value,
  ) async {
    if (key.trim().isEmpty) {
      return false;
    }

    final prefs = await _storage;

    return prefs.setString(key, value);
  }

  /// دریافت متن
  Future<String?> getString(String key) async {
    if (key.trim().isEmpty) {
      return null;
    }

    final prefs = await _storage;

    return prefs.getString(key);
  }

  /// ذخیره JSON
  Future<bool> setJson(
    String key,
    dynamic value,
  ) async {
    try {
      final encoded = jsonEncode(value);

      return await setString(
        key,
        encoded,
      );
    } catch (_) {
      return false;
    }
  }

  /// دریافت JSON
  Future<dynamic> getJson(String key) async {
    final value = await getString(key);

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  /// ذخیره مقدار بولی
  Future<bool> setBool(
    String key,
    bool value,
  ) async {
    if (key.trim().isEmpty) {
      return false;
    }

    final prefs = await _storage;

    return prefs.setBool(key, value);
  }

  /// دریافت مقدار بولی
  Future<bool?> getBool(String key) async {
    if (key.trim().isEmpty) {
      return null;
    }

    final prefs = await _storage;

    return prefs.getBool(key);
  }

  /// ذخیره عدد صحیح
  Future<bool> setInt(
    String key,
    int value,
  ) async {
    if (key.trim().isEmpty) {
      return false;
    }

    final prefs = await _storage;

    return prefs.setInt(key, value);
  }

  /// دریافت عدد صحیح
  Future<int?> getInt(String key) async {
    if (key.trim().isEmpty) {
      return null;
    }

    final prefs = await _storage;

    return prefs.getInt(key);
  }

  /// بررسی وجود کلید
  Future<bool> containsKey(String key) async {
    if (key.trim().isEmpty) {
      return false;
    }

    final prefs = await _storage;

    return prefs.containsKey(key);
  }

  /// حذف یک داده
  Future<bool> remove(String key) async {
    if (key.trim().isEmpty) {
      return false;
    }

    final prefs = await _storage;

    return prefs.remove(key);
  }

  /// حذف تمام Cacheهای برنامه
  Future<bool> clear() async {
    final prefs = await _storage;

    return prefs.clear();
  }
}
