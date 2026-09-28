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

  /// آدرس پایه‌ی Worker؛ برای تبدیل آدرس‌های نسبی (مثل /ads/image/3)
  /// به آدرس کامل. اگر سرور آدرس کامل بدهد، دست‌نخورده می‌ماند.
  static const String _origin =
      'https://cyrus-tourist-admin-panel.cyrustourist.workers.dev';

  static String _absUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('data:')) return v;
    if (v.startsWith('//')) return 'https:$v';
    return v.startsWith('/') ? '$_origin$v' : '$_origin/$v';
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  factory CyrusAdvertisement.fromJson(Map<String, dynamic> json) {
    final rawActive = json['is_active'] ?? json['isActive'] ?? json['active'];
    final active = rawActive == null
        ? true
        : (rawActive == true || _asInt(rawActive, fallback: 1) == 1);

    return CyrusAdvertisement(
      id: _asInt(json['id']),
      slot: _asInt(json['slot'] ?? json['position']),
      imageUrl: _absUrl(_firstString(
          json, ['image_url', 'imageUrl', 'image', 'img', 'photo', 'url'])),
      linkUrl: _firstString(
          json, ['link_url', 'linkUrl', 'link', 'target_url', 'href']),
      sortOrder: _asInt(json['sort_order'] ?? json['sortOrder'] ?? json['order'],
          fallback: 1),
      isActive: active,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
