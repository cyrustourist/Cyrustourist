import 'badge_service.dart';

/// وضعیت ارسال پیامک که مدیر در پنل تعیین می‌کند (کلید روشن/خاموش، ساعت مجاز، سقف روزانه).
class SmsStatus {
  const SmsStatus({required this.canSend, required this.reason, required this.from, required this.to});
  final bool canSend;

  /// '' | 'off' | 'hours' | 'cap'
  final String reason;
  final int from;
  final int to;

  /// اگر ارتباط برقرار نشد، فرض بر «مجاز» است تا خود سرور تصمیم بگیرد.
  static const SmsStatus open = SmsStatus(canSend: true, reason: '', from: 8, to: 24);

  static Future<SmsStatus> load() async {
    final j = await BadgeService.call('GET', '/api/auth/config');
    if (j == null || j['success'] != true) return open;
    final s = j['sms'];
    if (s is! Map) return open;
    int n(dynamic v, int d) => v is num ? v.toInt() : (int.tryParse('$v') ?? d);
    return SmsStatus(
      canSend: s['can_send'] != false,
      reason: '${s['reason'] ?? ''}',
      from: n(s['from'], 8),
      to: n(s['to'], 24),
    );
  }
}
