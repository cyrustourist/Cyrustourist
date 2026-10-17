import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'safe_prefs.dart';

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

  /// آخرین دلیل خطای شبکه/سرور (برای نمایش در پیام‌های خطا؛ هرگز Token نگه نمی‌دارد).
  static String lastError = '';

  // اگر SharedPreferences روی گوشی خطا بدهد، توکن و شناسه تا بستن اپ در حافظه می‌مانند
  // تا چت، پروفایل و تماس از کار نیفتند.
  static String? _memToken;
  static String? _memUid;

  /// توکن محرمانهٔ این دستگاه. user_uid در چت دیده می‌شود، پس بدون این توکن
  /// هیچ‌کس نمی‌تواند به‌جای کاربر استوری بگذارد یا پروفایل را تغییر دهد.
  static Future<String> deviceToken() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      lastError = 'prefs:${e.runtimeType}';
    }
    var t = _memToken ?? prefs?.getString(_tokenKey);
    if (t == null || t.length < 24) {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final r = Random.secure();
      t = List.generate(44, (_) => chars[r.nextInt(chars.length)]).join();
      try {
        await prefs?.setString(_tokenKey, t);
      } catch (e) {
        lastError = 'prefs:${e.runtimeType}';
      }
    }
    _memToken = t;
    return t;
  }

  static Future<String> userUid() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      lastError = 'prefs:${e.runtimeType}';
    }
    var uid = _memUid ?? prefs?.getString(_uidKey);
    if (uid == null || uid.length < 8) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final r = Random.secure();
      uid = 'u${List.generate(23, (_) => chars[r.nextInt(chars.length)]).join()}';
      try {
        await prefs?.setString(_uidKey, uid);
      } catch (e) {
        lastError = 'prefs:${e.runtimeType}';
      }
    }
    _memUid = uid;
    return uid;
  }

  /// وقتی ورود با گوگل حساب قبلی را پیدا کند، شناسهٔ همان حساب جایگزین می‌شود.
  static Future<void> setUserUid(String uid) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(uid)) return;
    _memUid = uid;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_uidKey, uid);
    } catch (e) {
      lastError = 'prefs:${e.runtimeType}';
    }
  }

  /// فراخوانی عمومی برای سرویس‌های دیگر (گوگل، پروفایل عمومی).
  static Future<Map<String, dynamic>?> call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) =>
      _call(
        method,
        path,
        query: {...?query, 'lang': MenuLanguage.current},
        body: body == null ? null : {...body, 'lang': MenuLanguage.current},
        timeout: timeout,
      );

  static Future<Map<String, dynamic>?> _call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // هر درخواست کلاینت جداگانه دارد و در پایان (حتی با Timeout) کامل بسته می‌شود؛
    // با کلاینت مشترک، اتصال‌های معلق پایش تماس (هر ۳ ثانیه) کم‌کم همهٔ ۶ اتصال را پر می‌کردند
    // و ثبت پروفایل/چت هم Timeout می‌خورد.
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: query);
      final req = await client.openUrl(method, uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set('X-Cyrus-Token', await deviceToken());
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      Object? decoded;
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        lastError = 'http ${res.statusCode} (پاسخ غیر JSON)';
        return null;
      }
      if (decoded is Map<String, dynamic>) {
        lastError = '';
        return decoded;
      }
      lastError = 'http ${res.statusCode} (پاسخ نامعتبر)';
      return null;
    } on TimeoutException {
      lastError = 'timeout';
      return null;
    } on SocketException catch (e) {
      lastError = 'شبکه: ${e.message}';
      return null;
    } catch (e) {
      lastError = '${e.runtimeType}';
      return null;
    } finally {
      client.close(force: true);
    }
  }

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
      if (j == null) return RegisterResult(ok: false, code: 'net', message: lastError);
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
