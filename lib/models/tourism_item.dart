/// مدل استاندارد اطلاعات گردشگری در اپلیکیشن سایروس توریست.
///
/// این مدل برای انواع مختلف محتوای گردشگری استفاده می‌شود؛
/// مانند جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت، ویدئوها و خدمات.
///
/// نکته:
/// وضعیت Favorite عمداً در این مدل قرار نگرفته است.
/// Favorite یک وضعیت مربوط به کاربر است و در FavoritesService مدیریت خواهد شد.
class TourismItem {
  /// شناسه یکتا
  final String id;

  /// نوع محتوا
  ///
  /// نمونه‌ها:
  /// attraction
  /// accommodation
  /// health
  /// video
  /// service
  /// travelGuide
  final String type;

  /// دسته‌بندی محتوا
  final String? category;

  // ------------------------------------------------------------
  // عنوان‌ها
  // ------------------------------------------------------------

  final String titleFa;
  final String titleEn;
  final String titleAr;

  // ------------------------------------------------------------
  // توضیحات
  // ------------------------------------------------------------

  final String? descriptionFa;
  final String? descriptionEn;
  final String? descriptionAr;

  // ------------------------------------------------------------
  // تصویر
  // ------------------------------------------------------------

  /// آدرس تصویر یا مسیر Asset
  ///
  /// می‌تواند بعداً یکی از این حالت‌ها باشد:
  /// assets/images/example.jpg
  /// https://example.com/image.jpg
  final String? imageUrl;

  // ------------------------------------------------------------
  // اطلاعات تماس و مکان
  // ------------------------------------------------------------

  final String? address;
  final String? phone;
  final String? websiteUrl;

  // ------------------------------------------------------------
  // ویدئو
  // ------------------------------------------------------------

  /// لینک ویدئو، آپارات یا منبع ویدئویی دیگر
  final String? videoUrl;

  // ------------------------------------------------------------
  // موقعیت جغرافیایی
  // ------------------------------------------------------------

  final double? latitude;
  final double? longitude;

  const TourismItem({
    required this.id,
    required this.type,
    this.category,
    required this.titleFa,
    required this.titleEn,
    required this.titleAr,
    this.descriptionFa,
    this.descriptionEn,
    this.descriptionAr,
    this.imageUrl,
    this.address,
    this.phone,
    this.websiteUrl,
    this.videoUrl,
    this.latitude,
    this.longitude,
  });

  // ------------------------------------------------------------
  // بررسی وجود مختصات معتبر
  // ------------------------------------------------------------

  bool get hasLocation {
    if (latitude == null || longitude == null) {
      return false;
    }

    return latitude! >= -90 &&
        latitude! <= 90 &&
        longitude! >= -180 &&
        longitude! <= 180;
  }

  // ------------------------------------------------------------
  // بررسی وجود اطلاعات ویدئو
  // ------------------------------------------------------------

  bool get hasVideo {
    return videoUrl != null && videoUrl!.trim().isNotEmpty;
  }

  // ------------------------------------------------------------
  // بررسی وجود لینک وب
  // ------------------------------------------------------------

  bool get hasWebsite {
    return websiteUrl != null && websiteUrl!.trim().isNotEmpty;
  }

  // ------------------------------------------------------------
  // دریافت عنوان بر اساس زبان
  // ------------------------------------------------------------

  String titleForLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return titleEn.trim().isNotEmpty ? titleEn : titleFa;

      case 'ar':
        return titleAr.trim().isNotEmpty ? titleAr : titleFa;

      case 'fa':
      default:
        return titleFa;
    }
  }

  // ------------------------------------------------------------
  // دریافت توضیحات بر اساس زبان
  // ------------------------------------------------------------

  String descriptionForLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return (descriptionEn ?? '').trim().isNotEmpty
            ? descriptionEn!
            : (descriptionFa ?? '');

      case 'ar':
        return (descriptionAr ?? '').trim().isNotEmpty
            ? descriptionAr!
            : (descriptionFa ?? '');

      case 'fa':
      default:
        return descriptionFa ?? '';
    }
  }

  // ------------------------------------------------------------
  // تبدیل مدل به Map
  // ------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'titleFa': titleFa,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'descriptionFa': descriptionFa,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'imageUrl': imageUrl,
      'address': address,
      'phone': phone,
      'websiteUrl': websiteUrl,
      'videoUrl': videoUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // ------------------------------------------------------------
  // ساخت مدل از Map
  // ------------------------------------------------------------

  factory TourismItem.fromMap(Map<String, dynamic> map) {
    return TourismItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      category: map['category']?.toString(),
      titleFa: map['titleFa']?.toString() ?? '',
      titleEn: map['titleEn']?.toString() ?? '',
      titleAr: map['titleAr']?.toString() ?? '',
      descriptionFa: map['descriptionFa']?.toString(),
      descriptionEn: map['descriptionEn']?.toString(),
      descriptionAr: map['descriptionAr']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      websiteUrl: map['websiteUrl']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
    );
  }

  // ------------------------------------------------------------
  // تبدیل امن مقدار به double
  // ------------------------------------------------------------

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  // ------------------------------------------------------------
  // ساخت نسخه جدید از آیتم
  // ------------------------------------------------------------

  TourismItem copyWith({
    String? id,
    String? type,
    String? category,
    String? titleFa,
    String? titleEn,
    String? titleAr,
    String? descriptionFa,
    String? descriptionEn,
    String? descriptionAr,
    String? imageUrl,
    String? address,
    String? phone,
    String? websiteUrl,
    String? videoUrl,
    double? latitude,
    double? longitude,
  }) {
    return TourismItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      titleFa: titleFa ?? this.titleFa,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      descriptionFa: descriptionFa ?? this.descriptionFa,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // ------------------------------------------------------------
  // مقایسه دو آیتم
  // ------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TourismItem) {
      return false;
    }

    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  // ------------------------------------------------------------
  // نمایش برای Debug
  // ------------------------------------------------------------

  @override
  String toString() {
    return 'TourismItem('
        'id: $id, '
        'type: $type, '
        'titleFa: $titleFa, '
        'latitude: $latitude, '
        'longitude: $longitude'
        ')';
  }
}
