import 'badge_service.dart';
import 'user_profile_service.dart';

class UsernameCheck {
  const UsernameCheck({required this.available, this.message = ''});
  final bool available;
  final String message;
}

class AccountActionResult {
  const AccountActionResult({required this.ok, this.message = '', this.code = '', this.switched = false, this.badge = 'none'});
  final bool ok;
  final String message;
  final String code;
  final bool switched;

  /// تیک مؤثر بعد از تأیید: none | blue | gold
  final String badge;
}

class AccountInfo {
  const AccountInfo({
    required this.phoneVerified,
    required this.phoneMasked,
    required this.emailVerified,
    required this.badgeType,
    required this.dailyLimit,
    required this.storiesToday,
  });
  final bool phoneVerified;
  final String phoneMasked;
  final bool emailVerified;
  final String badgeType;
  final int dailyLimit;
  final int storiesToday;
}

/// حساب واحد: نام کاربری یکتا، تأیید شماره (OTP) و همگام‌سازی پروفایل با سرور.
class AccountService {
  AccountService._();

  /// اگر سرور در دسترس نباشد، اجازه می‌دهد (سرور هنگام ثبت دوباره بررسی می‌کند).
  static Future<UsernameCheck> usernameAvailable(String name) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/account/username-available', query: {'user_uid': uid, 'username': name});
    if (j == null || j['success'] != true) return const UsernameCheck(available: true);
    return UsernameCheck(available: j['available'] == true, message: '${j['message'] ?? ''}');
  }

  static Future<AccountInfo?> me() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/account/me', query: {'user_uid': uid});
    if (j == null || j['success'] != true || j['account'] is! Map) return null;
    final a = j['account'] as Map;
    return AccountInfo(
      phoneVerified: a['phone_verified'] == true,
      phoneMasked: '${a['phone_masked'] ?? ''}',
      emailVerified: a['email_verified'] == true,
      badgeType: '${a['badge_type'] ?? 'none'}',
      dailyLimit: int.tryParse('${a['daily_story_limit']}') ?? 0,
      storiesToday: int.tryParse('${a['stories_today']}') ?? 0,
    );
  }

  /// بعد از ورود به یک حساب موجود (گوگل/شماره)، پروفایل همان حساب جایگزین پروفایل محلی می‌شود
  /// تا اطلاعات خالی این گوشی روی حساب اصلی نوشته نشود.
  static Future<void> pullProfile() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/account/profile', query: {'user_uid': uid});
    if (j == null || j['success'] != true || j['profile'] is! Map) return;
    final p = j['profile'] as Map;
    final cur = await UserProfileService.load();
    final vis = '${p['profile_visibility'] ?? 'all'}';
    await UserProfileService.save(cur.copyWith(
      displayName: '${p['display_name'] ?? ''}',
      username: '${p['username'] ?? ''}',
      city: '${p['city'] ?? ''}',
      bio: '${p['bio'] ?? ''}',
      photoBase64: '${p['photo_data'] ?? ''}',
      videoLink: '${p['video_link'] ?? ''}',
      visibility: ['all', 'friends', 'none'].contains(vis) ? vis : 'all',
    ));
  }

  static Future<AccountActionResult> phoneSend(String phone) async {
    final uid = await BadgeService.userUid();
    await BadgeService.registerUser();
    final j = await BadgeService.call('POST', '/api/auth/phone/send-otp', body: {'user_uid': uid, 'phone': phone});
    if (j == null) return const AccountActionResult(ok: false, code: 'net');
    return AccountActionResult(ok: j['success'] == true, code: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
  }

  static Future<AccountActionResult> phoneVerify(String phone, String code) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/auth/phone/verify-otp', body: {'user_uid': uid, 'phone': phone, 'code': code});
    if (j == null) return const AccountActionResult(ok: false, code: 'net');
    if (j['success'] != true) {
      return AccountActionResult(ok: false, code: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
    }
    final canon = '${j['user_uid'] ?? ''}';
    final switched = j['switched'] == true;
    if (switched && canon.isNotEmpty && canon != uid) {
      await BadgeService.setUserUid(canon);
      await pullProfile();
    }
    final acc = j['account'];
    final badge = acc is Map ? '${acc['badge_type'] ?? 'none'}' : 'none';
    return AccountActionResult(ok: true, message: '${j['message'] ?? ''}', switched: switched, badge: badge);
  }
}
