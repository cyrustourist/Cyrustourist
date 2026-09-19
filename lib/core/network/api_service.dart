import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../../config/api_config.dart';
import 'api_exceptions.dart';

/// ===============================================================
/// Cyrus Tourist — سرویس مرکزی ارتباط با API
/// ---------------------------------------------------------------
/// تمام درخواست‌های شبکه باید از همین کلاس عبور کنند (نه HttpClient
/// پراکنده در هر صفحه)، تا Timeout، Retry، مدیریت خطا و لاگ یک‌جا و
/// یکسان باشند. این سرویس هرگز Exception خام بالا نمی‌فرستد که برنامه
/// را Crash کند؛ همیشه یکی از [ApiException]های تعریف‌شده را می‌دهد
/// تا لایه‌ی بالاتر (Repository/Cache) تصمیم بگیرد.
/// ===============================================================
class ApiService {
  ApiService._();

  static void _log(String tag, String detail) {
    // هرگز Password/Token/Secret اینجا چاپ نشود.
    if (kDebugMode) debugPrint('[CyrusAPI] $tag: $detail');
  }

  /// بررسی سلامت سرور قبل از دریافت اطلاعات اصلی (GET /health).
  /// هرگز throw نمی‌کند؛ فقط true/false برمی‌گرداند.
  static Future<bool> isHealthy() async {
    try {
      await getJson(ApiConfig.healthPath, retry: 0);
      _log('API_SUCCESS', 'health check ok');
      return true;
    } catch (e) {
      _log('API_ERROR', 'health check failed: $e');
      return false;
    }
  }

  /// GET و پارس JSON. در صورت خطا یکی از [ApiException]ها را پرتاب می‌کند.
  static Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    int? retry,
  }) {
    return _send('GET', path, query: query, retry: retry);
  }

  /// POST با بدنه‌ی JSON.
  static Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    int? retry,
  }) {
    return _send('POST', path, body: body, retry: retry);
  }

  static Future<dynamic> putJson(
    String path, {
    Map<String, dynamic>? body,
    int? retry,
  }) {
    return _send('PUT', path, body: body, retry: retry);
  }

  static Future<dynamic> deleteJson(String path, {int? retry}) {
    return _send('DELETE', path, retry: retry);
  }

  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    int? retry,
  }) async {
    final maxRetry = retry ?? ApiConfig.maxRetry;
    Object? lastError;

    for (var attempt = 0; attempt <= maxRetry; attempt++) {
      final client = HttpClient()..connectionTimeout = ApiConfig.timeout;
      try {
        final uri = ApiConfig.uri(path, query);
        final request = await client.openUrl(method, uri).timeout(ApiConfig.timeout);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (ApiConfig.apiKey.isNotEmpty) {
          request.headers.set('X-Api-Key', ApiConfig.apiKey);
        }
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.add(utf8.encode(jsonEncode(body)));
        }

        final response = await request.close().timeout(ApiConfig.timeout);
        final text = await response.transform(utf8.decoder).join();

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiServerException(response.statusCode, 'HTTP ${response.statusCode}');
        }

        try {
          _log('API_SUCCESS', '$method $path (${response.statusCode})');
          return text.isEmpty ? null : jsonDecode(text);
        } on FormatException {
          throw const ApiParseException();
        }
      } on ApiServerException catch (e) {
        lastError = e;
        // خطای ۴xx (به‌جز 408/429) با تلاش دوباره حل نمی‌شود.
        if (e.isClientError && e.statusCode != 408 && e.statusCode != 429) break;
      } on SocketException catch (e) {
        lastError = ApiNetworkException(e.message);
      } on HttpException catch (e) {
        lastError = ApiNetworkException(e.message);
      } catch (e) {
        lastError = e.toString().contains('TimeoutException')
            ? const ApiTimeoutException()
            : ApiNetworkException(e.toString());
      } finally {
        client.close(force: true);
      }

      if (attempt < maxRetry) {
        _log('API_ERROR', '$method $path attempt ${attempt + 1} failed, retrying');
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    _log('API_ERROR', '$method $path failed after retries: $lastError');
    if (lastError is ApiException) throw lastError;
    throw ApiNetworkException('$lastError');
  }
}
