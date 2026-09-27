/// مدل داده‌ی یک «تبلیغ» سایروس توریست.
///
/// این کلاس معادل آبجکت JSON دریافتی از API عمومی تبلیغات است:
/// https://cyrus-tourist-api.cyrustourist.workers.dev/advertisements?slot=1
class CyrusAdvertisement {
  const CyrusAdvertisement({
    required this.id,
    required this.slot,
    required this.imageUrl,
    required this.linkUrl,
    this.sortOrder = 1,
    this.isActive = true,
  });

  /// شناسه‌ی یکتای تبلیغ.
  final int id;

  /// جایگاه نمایش (۱، ۲ یا ۳).
  final int slot;

  /// آدرس تصویر تبلیغ (WebP، ذخیره‌شده در D1 یا R2).
  final String imageUrl;

  /// لینک مقصدی که با لمس تبلیغ باز می‌شود.
  final String linkUrl;

  /// ترتیب نمایش در بین تبلیغات همان جایگاه.
  final int sortOrder;

  /// آیا این تبلیغ فعال است (سرور فقط تبلیغ‌های فعال را برمی‌گرداند،
  /// این فیلد صرفاً برای اطمینان نگه داشته شده است).
  final bool isActive;

  factory CyrusAdvertisement.fromJson(Map<String, dynamic> json) {
    return CyrusAdvertisement(
      id: _asInt(json['id']),
      slot: _asInt(json['slot']),
      imageUrl: json['image_url']?.toString() ?? '',
      linkUrl: json['link_url']?.toString() ?? '',
      sortOrder: _asInt(json['sort_order'], fallback: 1),
      isActive: _asInt(json['is_active'], fallback: 1) == 1,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
