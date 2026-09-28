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

  /// تبلیغات در دیتابیس Worker پنل مدیریت ثبت می‌شوند (cyrus-tourist-admin-panel)؛
  /// Worker مربوط به cyrus-tourist-api مسیر /advertisements ندارد
  /// (پاسخ Endpoint not found)، پس اپ باید از همین آدرس بخواند.
  static const String _baseUrl =
      'https://cyrus-tourist-admin-panel.cyrustourist.workers.dev/advertisements';

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
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final response =
          await request.close().timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        debugPrint(
            'Cyrus Ads slot $slot: HTTP ${response.statusCode} from $uri');
        return await _fallbackFromCache(slot);
      }

      final body = await response
          .transform(const Utf8Decoder())
          .join()
          .timeout(const Duration(seconds: 12));
      final decoded = jsonDecode(body);

      // پاسخ می‌تواند مستقیماً لیست باشد یا داخل data/ads/items/result.
      dynamic rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map) {
        if (decoded['success'] == false) {
          debugPrint('Cyrus Ads slot $slot: success=false → $body');
          return await _fallbackFromCache(slot);
        }
        for (final key in const ['data', 'ads', 'advertisements', 'items', 'result']) {
          if (decoded[key] is List) {
            rawList = decoded[key];
            break;
          }
        }
      }

      if (rawList is! List) {
        debugPrint('Cyrus Ads slot $slot: unexpected response shape → $body');
        return await _fallbackFromCache(slot);
      }

      // فقط داشتن عکس معتبر کافی است (لینک اختیاری است).
      final items = rawList
          .whereType<Map>()
          .map((m) => CyrusAdvertisement.fromJson(Map<String, dynamic>.from(m)))
          .where((ad) => ad.imageUrl.isNotEmpty && ad.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      debugPrint('Cyrus Ads slot $slot: ${items.length} active ad(s) from API');

      // عکس‌های base64 حجیم‌اند؛ کش کردنشان SharedPreferences را کند می‌کند.
      if (body.length < 400 * 1024) {
        unawaited(
          CacheService.instance.setEntry(
            _cacheKey(slot),
            rawList,
            source: 'api',
          ),
        );
      }

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
        .whereType<Map>()
        .map((m) => CyrusAdvertisement.fromJson(Map<String, dynamic>.from(m)))
        .where((ad) => ad.imageUrl.isNotEmpty && ad.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
