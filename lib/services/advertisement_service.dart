import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/cyrus_advertisement.dart';
import 'cache_service.dart';

/// سرویس مرکزی تبلیغات سایروس توریست.
///
/// تبلیغ‌های هر جایگاه (۱، ۲ یا ۳) را از API عمومی می‌گیرد و برای
/// نمایش سریع‌تر در بازدیدهای بعدی، آخرین نتیجه را Cache می‌کند
/// (الگوی data / updatedAt / source، مطابق بقیه‌ی سرویس‌های اپ).
class AdvertisementService {
  AdvertisementService._();

  static final AdvertisementService instance = AdvertisementService._();

  /// آدرس پایه‌ی API عمومی سایروس توریست (همان Worker اعلان‌ها).
  static const String _baseUrl =
      'https://cyrus-tourist-api.cyrustourist.workers.dev/advertisements';

  String _cacheKey(int slot) => 'cyrus_advertisements_slot_$slot';

  /// دریافت لیست تبلیغ‌های فعال یک جایگاه.
  ///
  /// ابتدا (در صورت وجود) نسخه‌ی Cache‌شده را فوراً برمی‌گرداند تا صفحه
  /// معطل نشود؛ در پس‌زمینه نسخه‌ی تازه از سرور گرفته و Cache به‌روزرسانی
  /// می‌شود. در صورت خطای شبکه یا نبود اینترنت، فقط لیست خالی برمی‌گردد
  /// (بدون کرش یا نمایش خطا) تا فضای تبلیغ به‌سادگی نمایش داده نشود.
  Future<List<CyrusAdvertisement>> fetchAds(int slot) async {
    if (slot < 1 || slot > 3) {
      return const [];
    }

    final client = HttpClient();

    try {
      client.connectionTimeout = const Duration(seconds: 8);

      final uri = Uri.parse('$_baseUrl?slot=$slot');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();

      if (response.statusCode != 200) {
        return await _fallbackFromCache(slot);
      }

      final body = await response.transform(const Utf8Decoder()).join();
      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return await _fallbackFromCache(slot);
      }

      final rawList = decoded['data'];

      if (rawList is! List) {
        return await _fallbackFromCache(slot);
      }

      // نکته: `linkUrl` اجباری نیست — خیلی از تبلیغ‌ها فقط عکس‌اند و
      // لینک مقصد ندارند؛ قبلاً همین تبلیغ‌ها با فیلتر اشتباه این‌جا
      // (بررسی خالی‌نبودنِ linkUrl) به‌کل حذف می‌شدند و عکسی از سرور
      // اضافه نمی‌شد. فقط داشتن عکس معتبر کافی است.
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(CyrusAdvertisement.fromJson)
          .where((ad) => ad.imageUrl.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      unawaited(
        CacheService.instance.setEntry(
          _cacheKey(slot),
          rawList,
          source: 'api',
        ),
      );

      return items;
    } catch (error) {
      debugPrint('Cyrus Tourist Advertisement fetch error: $error');
      return await _fallbackFromCache(slot);
    } finally {
      client.close();
    }
  }

  Future<List<CyrusAdvertisement>> _fallbackFromCache(int slot) async {
    final entry = await CacheService.instance.getEntry(_cacheKey(slot));
    final rawList = entry?.data;

    if (rawList is! List) {
      return const [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CyrusAdvertisement.fromJson)
        .where((ad) => ad.imageUrl.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
