/// مدل داده‌ی یک «اعلان» سایروس توریست.
///
/// این کلاس معادل آبجکت JSON دریافتی از API اعلان‌ها است:
/// https://cyrus-tourist-api.cyrustourist.workers.dev/notifications
///
/// نکته: این فایل پیش‌تر به‌اشتباه حاوی کد صفحه‌ی AnnouncementsPage بود
/// (که به‌جای آن باید در lib/pages/announcements_page.dart باشد) و
/// اصلاً کلاس CyrusAnnouncement را تعریف نمی‌کرد؛ همین باعث خطاهای
/// بیلد «CyrusAnnouncement isn't defined» می‌شد.
class CyrusAnnouncement {
  const CyrusAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    this.version = '',
    this.isActive = true,
    this.createdAt,
  });

  /// شناسه‌ی یکتای پیام (برای مرتب‌سازی و تشخیص خوانده‌نشده‌ها).
  final int id;

  /// عنوان پیام.
  final String title;

  /// متن کامل پیام (بدون محدودیت طول).
  final String message;

  /// نوع پیام: update | info | event | warning
  final String type;

  /// نسخه‌ی مرتبط با این اعلان (اختیاری، مثلاً "5.8.1").
  final String version;

  /// آیا این پیام هنوز فعال است و باید نمایش داده شود.
  final bool isActive;

  /// زمان ایجاد پیام (اختیاری).
  final DateTime? createdAt;

  factory CyrusAnnouncement.fromJson(Map<String, dynamic> json) {
    return CyrusAnnouncement(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      message: _asString(json['message'] ?? json['body']),
      type: _asString(json['type'], fallback: 'info'),
      version: _asString(json['version']),
      isActive: _asBool(json['isActive'] ?? json['is_active'], fallback: true),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return '$value';
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return fallback;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse('$value');
  }
}
