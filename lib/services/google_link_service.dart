import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/language/new_texts.dart';
import 'badge_service.dart';

class GoogleLinkResult {
  const GoogleLinkResult({required this.ok, this.message = '', this.emailMasked = '', this.cancelled = false});
  final bool ok;
  final String message;
  final String emailMasked;
  final bool cancelled;
}

/// اتصال جی‌میل کاربر به حسابش با «ورود با گوگل».
/// فقط جی‌میل (تأییدشده توسط گوگل) سمت سرور ذخیره می‌شود؛ رمز یا توکن ذخیره نمی‌شود.
/// ورود اختیاری است؛ بدون آن، همان روش شناسهٔ دستگاه کار می‌کند.
class GoogleLinkService {
  GoogleLinkService._();

  /// «Web client ID» ساخته‌شده در Google Cloud Console (نه Android client).
  /// همین مقدار باید در Worker پنل هم با نام GOOGLE_CLIENT_IDS تنظیم شود.
  static const String webClientId = 'PUT_WEB_CLIENT_ID.apps.googleusercontent.com';

  static final GoogleSignIn _gs = GoogleSignIn(scopes: const ['email'], serverClientId: webClientId);

  /// null = وصل نیست؛ در غیر این صورت جی‌میل پوشانده‌شده (مثل ab***@gmail.com)
  static Future<String?> status() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/auth/me', query: {'user_uid': uid});
    if (j == null || j['success'] != true || j['linked'] != true) return null;
    return '${j['email_masked'] ?? ''}';
  }

  static Future<GoogleLinkResult> link() async {
    if (webClientId.startsWith('PUT_')) {
      return GoogleLinkResult(ok: false, message: NT.t('g_not_set'));
    }
    try {
      await BadgeService.registerUser();
      await _gs.signOut();
      final acc = await _gs.signIn();
      if (acc == null) return const GoogleLinkResult(ok: false, cancelled: true);
      final auth = await acc.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        return GoogleLinkResult(ok: false, message: NT.t('g_token'));
      }
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('POST', '/api/auth/google', body: {'user_uid': uid, 'id_token': token});
      await _gs.signOut();
      if (j == null) return GoogleLinkResult(ok: false, message: NT.t('g_net'));
      if (j['success'] != true) {
        return GoogleLinkResult(ok: false, message: '${j['message'] ?? NT.t('g_fail')}');
      }
      final canon = '${j['user_uid'] ?? ''}';
      if (canon.isNotEmpty && canon != uid) {
        await BadgeService.setUserUid(canon); // حساب قبلی با همین جی‌میل (مثلاً گوشی جدید)
      }
      await BadgeService.registerUser();
      return GoogleLinkResult(ok: true, emailMasked: '${j['email_masked'] ?? ''}');
    } on PlatformException {
      return GoogleLinkResult(ok: false, message: NT.t('g_no_services'));
    } catch (_) {
      return GoogleLinkResult(ok: false, message: NT.t('g_fail'));
    }
  }
}
