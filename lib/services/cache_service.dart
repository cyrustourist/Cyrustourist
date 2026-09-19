import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// یک رکورد Cache همراه با زمان ذخیره و منبع، طبق «دستور کار فنی Android»:
/// هر Cache باید data / updatedAt / source داشته باشد.
class CacheEntry {
  const CacheEntry({required this.data, required this.updatedAt, required this.source});

  final dynamic data;
  final DateTime updatedAt;

  /// 'api' | 'cache' | 'fallback'
  final String source;

  Map<String, dynamic> toJson() => {
        'data': data,
        'updatedAt': updatedAt.toIso8601String(),
        'source': source,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> j) => CacheEntry(
        data: j['data'],
        updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        source: j['source']?.toString() ?? 'cache',
      );
}

/// سرویس مرکزی Cache سایروس توریست.
///
/// برای ذخیره موقت داده‌های متنی و JSON استفاده می‌شود.
/// این سرویس مستقل طراحی شده تا بعداً بتوانیم Cache را
/// بدون تغییر در صفحات برنامه مدیریت کنیم.
class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  SharedPreferences? _prefs;

  /// پیشوند مخصوص رکوردهای data/updatedAt/source (برای جدا ماندن از
  /// کلیدهای ساده‌ی قدیمی که با setString/setJson ذخیره می‌شوند).
  static const String _entryPrefix = 'entry_v1_';

  /// آماده‌سازی سرویس
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// دریافت SharedPreferences آماده
  Future<SharedPreferences> get _storage async {
    await initialize();
    return _prefs!;
  }

  /// ذخیره‌ی یک رکورد کامل به همراه زمان و منبع (برای Repositoryهای جدید).
  Future<bool> setEntry(String key, dynamic data, {required String source}) async {
    final entry = CacheEntry(data: data, updatedAt: DateTime.now(), source: source);
    return setJson('$_entryPrefix$key', entry.toJson());
  }

  /// خواندن رکورد ذخیره‌شده با [setEntry]؛ اگر وجود نداشت null برمی‌گرداند.
  Future<CacheEntry?> getEntry(String key) async {
    final raw = await getJson('$_entryPrefix$key');
    if (raw is Map<String, dynamic>) return CacheEntry.fromJson(raw);
    if (raw is Map) return CacheEntry.fromJson(Map<String, dynamic>.from(raw));
    return null;
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
