import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/language/new_texts.dart';
import 'account_service.dart';
import 'badge_service.dart';

class GoogleLinkResult {
  const GoogleLinkResult({required this.ok, this.message = '', this.emailMasked = '', this.cancelled = false, this.badge = 'none'});
  final bool ok;
  final String message;
  final String emailMasked;
  final bool cancelled;

  /// تیک مؤثر پس از تأیید: none | blue | gold
  final String badge;
}

/// اتصال جی‌میل کاربر به شناسه‌اش با «ورود با گوگل».
/// فقط جی‌میل (تأییدشده توسط گوگل) سمت سرور ذخیره می‌شود؛ رمز یا توکن ذخیره نمی‌شود.
class GoogleLinkService {
  GoogleLinkService._();

  /// اختیاری: اگر «Web client ID» را اینجا بگذارید همان استفاده می‌شود.
  /// در غیر این صورت برنامه آن را از Worker می‌گیرد (GOOGLE_WEB_CLIENT_ID یا اولین مقدار GOOGLE_CLIENT_IDS).
  static const String webClientId = 'PUT_WEB_CLIENT_ID.apps.googleusercontent.com';

  static String _cachedId = '';
  static bool _netFail = false;
  static GoogleSignIn? _gs;

  static Future<String> _clientId() async {
    if (!webClientId.startsWith('PUT_')) return webClientId;
    if (_cachedId.isNotEmpty) return _cachedId;
    final j = await BadgeService.call('GET', '/api/auth/config');
    _netFail = j == null || j['success'] != true;
    final id = (j == null || _netFail) ? '' : '${j['google_client_id'] ?? ''}'.trim();
    if (id.isNotEmpty) _cachedId = id;
    return id;
  }

  /// null = وصل نیست؛ در غیر این صورت جی‌میل پوشانده‌شده (مثل ab***@gmail.com)
  static Future<String?> status() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/auth/me', query: {'user_uid': uid});
    if (j == null || j['success'] != true || j['linked'] != true) return null;
    return '${j['email_masked'] ?? ''}';
  }

  static Future<GoogleLinkResult> link() async {
    final id = await _clientId();
    if (id.isEmpty) {
      // ارتباط با ورکر برقرار نشد، یا ورکر هنوز شناسهٔ کلاینت وب گوگل را ندارد
      return GoogleLinkResult(ok: false, message: NT.t(_netFail ? 'g_net' : 'g_srv'));
    }
    try {
      _gs ??= GoogleSignIn(scopes: const ['email'], serverClientId: id);
      final gs = _gs!;
      await BadgeService.registerUser();
      await gs.signOut();
      final acc = await gs.signIn();
      if (acc == null) return const GoogleLinkResult(ok: false, cancelled: true);
      final auth = await acc.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        return GoogleLinkResult(ok: false, message: NT.t('g_token'));
      }
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/auth/google', body: {'user_uid': uid, 'id_token': token});
      await gs.signOut();
      if (j == null) return GoogleLinkResult(ok: false, message: NT.t('g_net'));
      if (j['success'] != true) {
        return GoogleLinkResult(ok: false, message: '${j['message'] ?? NT.t('g_fail')}');
      }
      final canon = '${j['user_uid'] ?? ''}';
      if (canon.isNotEmpty && canon != uid) {
        await BadgeService.setUserUid(canon); // حساب قبلی با همین جی‌میل (مثلاً گوشی جدید)
        await AccountService.pullProfile();
      }
      await BadgeService.registerUser();
      final accJ = j['account'];
      final badge = accJ is Map ? '${accJ['badge_type'] ?? 'none'}' : 'none';
      return GoogleLinkResult(ok: true, emailMasked: '${j['email_masked'] ?? ''}', badge: badge);
    } on PlatformException catch (e) {
      final m = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (m.contains('network')) return GoogleLinkResult(ok: false, message: NT.t('g_net'));
      // ApiException 10 / 12500 = SHA-1 یا شناسهٔ کلاینت در Google Cloud درست ثبت نشده
      if (m.contains(': 10') || m.contains('12500') || m.contains('developer')) {
        return GoogleLinkResult(ok: false, message: NT.t('g_dev'));
      }
      return GoogleLinkResult(ok: false, message: NT.t('g_no_services'));
    } catch (_) {
      return GoogleLinkResult(ok: false, message: NT.t('g_fail'));
    }
  }
}
