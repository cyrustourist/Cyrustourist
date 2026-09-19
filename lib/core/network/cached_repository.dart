import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../services/cache_service.dart';
import 'api_service.dart';

/// منبع واقعیِ داده‌ای که در نهایت به دست UI رسیده.
enum DataSource { api, cache, fallback, empty }

class RepositoryResult<T> {
  const RepositoryResult({required this.data, required this.source});

  final T data;
  final DataSource source;
}

/// ===============================================================
/// Cyrus Tourist — Repository عمومی «API → Cache → Fallback → Empty»
/// ---------------------------------------------------------------
/// هر بخش از برنامه (شهرها، اقامتگاه‌ها، جاذبه‌ها، لیدرها، گردشگری
/// سلامت، اعلان‌ها، تنظیمات و ...) به‌جای نوشتن دوباره‌ی همین منطق،
/// فقط یک نمونه از این کلاس با پارامترهای خودش می‌سازد.
///
/// مثال ساخت یک ریپازیتوری برای اقامتگاه‌ها:
///
/// ```dart
/// final repo = CachedRepository<List<dynamic>>(
///   cacheKey: 'accommodations',
///   endpointPath: '/api/v1/accommodations',
///   fallbackAsset: 'assets/fallback/accommodations.json',
///   parse: (json) => json['items'] as List<dynamic>,
/// );
/// final result = await repo.load();
/// // result.data, result.source (api / cache / fallback / empty)
/// ```
/// ===============================================================
class CachedRepository<T> {
  CachedRepository({
    required this.cacheKey,
    required this.endpointPath,
    required this.fallbackAsset,
    required this.parse,
    this.query,
  });

  /// کلید ذخیره‌سازی محلی (بدون تکرار بین بخش‌های مختلف).
  final String cacheKey;

  /// مسیر Endpoint نسبت به [ApiConfig.baseUrl]، مثلاً '/api/v1/accommodations'.
  final String endpointPath;

  /// فایل JSON داخل assets که فقط وقتی API و Cache هیچ‌کدام در دسترس
  /// نبودند استفاده می‌شود (هرگز جایگزین دائمی نمی‌شود).
  final String fallbackAsset;

  /// تبدیل JSON خام (Map/List) به مدل موردنظر صفحه.
  final T Function(dynamic json) parse;

  final Map<String, dynamic>? query;

  Future<RepositoryResult<T>> load() async {
    // ۱) API — همیشه اولویت اول با داده‌ی واقعی است.
    try {
      final json = await ApiService.getJson(endpointPath, query: query);
      if (json != null) {
        final data = parse(json);
        await CacheService.instance.setEntry(cacheKey, json, source: 'api');
        return RepositoryResult(data: data, source: DataSource.api);
      }
    } catch (_) {
      // عمداً نادیده گرفته می‌شود؛ به مرحله‌ی بعد (Cache) می‌رویم.
    }

    // ۲) Cache — آخرین اطلاعات معتبر ذخیره‌شده روی گوشی.
    try {
      final entry = await CacheService.instance.getEntry(cacheKey);
      if (entry != null) {
        return RepositoryResult(data: parse(entry.data), source: DataSource.cache);
      }
    } catch (_) {}

    // ۳) Fallback — فایل نمونه‌ی داخل خود برنامه.
    try {
      final raw = await rootBundle.loadString(fallbackAsset);
      final json = jsonDecode(raw);
      return RepositoryResult(data: parse(json), source: DataSource.fallback);
    } catch (_) {}

    // ۴) هیچ‌کدام موجود نبود — تصمیم نمایش «در حال آماده‌سازی» با صفحه‌ی
    // فراخواننده است؛ اینجا فقط علامت می‌دهیم.
    throw StateError('no_data_available:$cacheKey');
  }
}
