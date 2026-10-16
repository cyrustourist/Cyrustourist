import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../core/language/menu_translations.dart';
import 'user_profile_service.dart';

/// طرح تیک (آبی / طلایی) — قیمت و مدت از پنل مدیریت تعیین می‌شود.
class BadgePlan {
  const BadgePlan({
    required this.code,
    required this.nameFa,
    required this.price,
    required this.currency,
    required this.durationDays,
    this.requiresCode,
  });

  final String code;
  final String nameFa;
  final int price;
  final String currency;
  final int durationDays;
  final String? requiresCode;

  factory BadgePlan.fromJson(Map<String, dynamic> j) => BadgePlan(
        code: '${j['code']}',
        nameFa: '${j['name_fa'] ?? j['code']}',
        price: int.tryParse('${j['price_amount']}') ?? 0,
        currency: '${j['currency'] ?? 'IRT'}',
        durationDays: int.tryParse('${j['duration_days']}') ?? 365,
        requiresCode: (j['requires_code'] == null || '${j['requires_code']}'.isEmpty)
            ? null
            : '${j['requires_code']}',
      );
}

class BadgeStatus {
  const BadgeStatus({
    this.active = const {},
    this.lastRequestCode,
    this.lastRequestBadge,
    this.lastRequestStatus,
  });

  /// کد تیک ← تاریخ انقضا (UTC، قالب «YYYY-MM-DD HH:MM:SS»)
  final Map<String, String> active;
  final String? lastRequestCode;
  final String? lastRequestBadge;
  final String? lastRequestStatus;

  bool get hasBlue => active.containsKey('blue');
  bool get hasGold => active.containsKey('gold');
}

class BadgeRequestResult {
  const BadgeRequestResult({
    required this.ok,
    this.message = '',
    this.requestCode,
    this.status,
    this.price = 0,
    this.existing = false,
    this.errorCode = '',
  });

  final bool ok;
  final String message;
  final String? requestCode;
  final String? status;
  final int price;
  final bool existing;
  final String errorCode; // terms | need_google | already_active | requires_blue | ...
}

/// ارتباط با API تیک آبی/طلایی (Worker پنل). پروفایل کاربر هنوز روی گوشی است؛
/// فقط یک شناسهٔ تصادفی (user_uid) برای ثبت درخواست‌ها به سرور داده می‌شود.
class RegisterResult {
  const RegisterResult({required this.ok, this.code = '', this.message = ''});
  final bool ok;
  final String code; // username_taken | username_invalid | auth_failed | net | ...
  final String message;

  bool get isUsernameError => code == 'username_taken' || code == 'username_invalid';
}

class BadgeService {
  BadgeService._();

  static const String _uidKey = 'cyrus_user_uid';
  static const String _base = ApiConfig.panelBaseUrl;

  static String get baseUrl => _base;

  static const String _tokenKey = 'cyrus_device_token';

  /// توکن محرمانهٔ این دستگاه. user_uid در چت دیده می‌شود، پس بدون این توکن
  /// هیچ‌کس نمی‌تواند به‌جای کاربر استوری بگذارد یا پروفایل را تغییر دهد.
  static Future<String> deviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    var t = prefs.getString(_tokenKey);
    if (t == null || t.length < 24) {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final r = Random.secure();
      t = List.generate(44, (_) => chars[r.nextInt(chars.length)]).join();
      await prefs.setString(_tokenKey, t);
    }
    return t;
  }

  static Future<String> userUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString(_uidKey);
    if (uid == null || uid.length < 8) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final r = Random.secure();
      uid = 'u${List.generate(23, (_) => chars[r.nextInt(chars.length)]).join()}';
      await prefs.setString(_uidKey, uid);
    }
    return uid;
  }

  /// وقتی ورود با گوگل حساب قبلی را پیدا کند، شناسهٔ همان حساب جایگزین می‌شود.
  static Future<void> setUserUid(String uid) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(uid)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, uid);
  }

  /// فراخوانی عمومی برای سرویس‌های دیگر (گوگل، پروفایل عمومی).
  static Future<Map<String, dynamic>?> call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) =>
      _call(
        method,
        path,
        query: {...?query, 'lang': MenuLanguage.current},
        body: body == null ? null : {...body, 'lang': MenuLanguage.current},
      );

  static Future<Map<String, dynamic>?> _call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    // یک کلاینت مشترک با اتصال زنده (keep-alive): هر درخواست دیگر دست‌دادن TLS تازه نمی‌خواهد.
    final client = _sharedClient;
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: query);
      final req = await client.openUrl(method, uri).timeout(const Duration(seconds: 10));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set('X-Cyrus-Token', await deviceToken());
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(const Duration(seconds: 10));
      final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static final HttpClient _sharedClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(seconds: 90)
    ..maxConnectionsPerHost = 6;

  /// ثبت/به‌روزرسانی کاربر در سرور. خطای نام کاربری تکراری در نتیجه برمی‌گردد.
  static Future<RegisterResult> registerUser() async {
    try {
      final uid = await userUid();
      final p = await UserProfileService.load();
      final j = await _call('POST', '/api/users/register', query: {'lang': MenuLanguage.current}, body: {
        'user_uid': uid,
        'display_name': p.displayName,
        'username': p.username,
        'city': p.city,
        'bio': p.bio,
        'profile_visibility': p.visibility,
        'video_link': p.videoLink,
        'photo_data': p.photoBase64,
      });
      if (j == null) return const RegisterResult(ok: false, code: 'net');
      if (j['success'] == true) return const RegisterResult(ok: true);
      return RegisterResult(ok: false, code: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
    } catch (_) {
      return const RegisterResult(ok: false, code: 'net');
    }
  }

  static Future<List<BadgePlan>> fetchPlans() async {
    final j = await _call('GET', '/api/badges/plans');
    if (j == null || j['success'] != true) return const [];
    return (j['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(BadgePlan.fromJson)
        .toList();
  }

  static Future<BadgeStatus?> fetchStatus() async {
    final uid = await userUid();
    final j = await _call('GET', '/api/badges/status',
        query: {'subject_type': 'user', 'subject_id': uid});
    if (j == null || j['success'] != true) return null;
    final active = <String, String>{};
    for (final b in (j['badges'] as List? ?? const [])) {
      if (b is Map) active['${b['badge_code']}'] = '${b['expires_at']}';
    }
    final last = j['last_request'];
    return BadgeStatus(
      active: active,
      lastRequestCode: last is Map ? '${last['request_code']}' : null,
      lastRequestBadge: last is Map ? '${last['badge_code']}' : null,
      lastRequestStatus: last is Map ? '${last['status']}' : null,
    );
  }

  static Future<BadgeRequestResult> requestBadge(String code, {bool termsAccepted = false}) async {
    final uid = await userUid();
    await registerUser();
    final j = await _call('POST', '/api/badges/request', body: {
      'user_uid': uid,
      'subject_type': 'user',
      'subject_id': uid,
      'badge_code': code,
      'terms_accepted': termsAccepted,
    });
    if (j == null) {
      return const BadgeRequestResult(ok: false, message: 'ارتباط با سرور برقرار نشد. دوباره تلاش کنید.');
    }
    if (j['success'] != true) {
      return BadgeRequestResult(
        ok: false,
        message: '${j['message'] ?? 'درخواست ثبت نشد.'}',
        errorCode: '${j['error'] ?? ''}',
      );
    }
    return BadgeRequestResult(
      ok: true,
      requestCode: '${j['request_code']}',
      status: '${j['status']}',
      price: int.tryParse('${j['price_amount']}') ?? 0,
      existing: j['existing'] == true,
    );
  }
}
