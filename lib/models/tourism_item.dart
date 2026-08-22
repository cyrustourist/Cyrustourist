/// مدل استاندارد اطلاعات گردشگری در اپلیکیشن سایروس توریست.
///
/// این مدل برای انواع مختلف محتوا استفاده می‌شود:
/// attraction
/// accommodation
/// health
/// video
/// service
/// travelGuide
///
/// وضعیت Favorite عمداً داخل این مدل ذخیره نمی‌شود.
/// Favorite توسط FavoritesService مدیریت می‌شود.
class TourismItem {
  // ------------------------------------------------------------
  // هویت محتوا
  // ------------------------------------------------------------

  final String id;
  final String type;
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

  final String? imageUrl;

  // ------------------------------------------------------------
  // اطلاعات تماس
  // ------------------------------------------------------------

  final String? address;
  final String? phone;
  final String? websiteUrl;

  // ------------------------------------------------------------
  // لینک‌های اختصاصی
  // ------------------------------------------------------------

  /// لینک ویدئو، آپارات یا منبع رسمی دیگر
  final String? videoUrl;

  /// لینک رزرو اقامتگاه در صورت وجود
  final String? bookingUrl;

  // ------------------------------------------------------------
  // اطلاعات اقامتگاه / خدمات
  // ------------------------------------------------------------

  /// نوع اقامتگاه یا نوع خدمت
  final String? accommodationType;

  /// امکانات
  ///
  /// مانند:
  /// استخر، پارکینگ، رستوران، اینترنت و...
  final List<String>? amenities;

  /// ظرفیت در صورت وجود
  final int? capacity;

  /// امتیاز در صورت وجود
  final double? rating;

  // ------------------------------------------------------------
  // موقعیت جغرافیایی
  // ------------------------------------------------------------

  final double? latitude;
  final double? longitude;

  // ------------------------------------------------------------
  // اطلاعات اضافی قابل توسعه
  // ------------------------------------------------------------

  /// برای اطلاعات آینده بدون تغییر اساسی مدل.
  ///
  /// داده ساختگی در این قسمت قرار نمی‌گیرد.
  final Map<String, dynamic>? extraData;

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
    this.bookingUrl,
    this.accommodationType,
    this.amenities,
    this.capacity,
    this.rating,
    this.latitude,
    this.longitude,
    this.extraData,
  });

  // ------------------------------------------------------------
  // موقعیت معتبر
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
  // ویدئو
  // ------------------------------------------------------------

  bool get hasVideo {
    return videoUrl != null &&
        videoUrl!.trim().isNotEmpty;
  }

  // ------------------------------------------------------------
  // وب‌سایت
  // ------------------------------------------------------------

  bool get hasWebsite {
    return websiteUrl != null &&
        websiteUrl!.trim().isNotEmpty;
  }

  // ------------------------------------------------------------
  // رزرو
  // ------------------------------------------------------------

  bool get hasBooking {
    return bookingUrl != null &&
        bookingUrl!.trim().isNotEmpty;
  }

  // ------------------------------------------------------------
  // امکانات
  // ------------------------------------------------------------

  bool get hasAmenities {
    return amenities != null &&
        amenities!.isNotEmpty;
  }

  // ------------------------------------------------------------
  // امتیاز معتبر
  // ------------------------------------------------------------

  bool get hasRating {
    return rating != null &&
        rating! >= 0 &&
        rating! <= 5;
  }

  // ------------------------------------------------------------
  // دریافت عنوان بر اساس زبان
  // ------------------------------------------------------------

  String titleForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return titleEn.trim().isNotEmpty
            ? titleEn
            : titleFa;

      case 'ar':
        return titleAr.trim().isNotEmpty
            ? titleAr
            : titleFa;

      case 'fa':
      default:
        return titleFa;
    }
  }

  // ------------------------------------------------------------
  // دریافت توضیحات بر اساس زبان
  // ------------------------------------------------------------

  String descriptionForLanguage(
    String languageCode,
  ) {
    switch (languageCode.toLowerCase()) {
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
  // تبدیل به Map
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
      'bookingUrl': bookingUrl,
      'accommodationType': accommodationType,
      'amenities': amenities,
      'capacity': capacity,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'extraData': extraData,
    };
  }

  // ------------------------------------------------------------
  // ساخت از Map
  // ------------------------------------------------------------

  factory TourismItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return TourismItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      category: map['category']?.toString(),
      titleFa: map['titleFa']?.toString() ?? '',
      titleEn: map['titleEn']?.toString() ?? '',
      titleAr: map['titleAr']?.toString() ?? '',
      descriptionFa:
          map['descriptionFa']?.toString(),
      descriptionEn:
          map['descriptionEn']?.toString(),
      descriptionAr:
          map['descriptionAr']?.toString(),
      imageUrl:
          map['imageUrl']?.toString(),
      address:
          map['address']?.toString(),
      phone:
          map['phone']?.toString(),
      websiteUrl:
          map['websiteUrl']?.toString(),
      videoUrl:
          map['videoUrl']?.toString(),
      bookingUrl:
          map['bookingUrl']?.toString(),
      accommodationType:
          map['accommodationType']?.toString(),
      amenities:
          _toStringList(map['amenities']),
      capacity:
          _toInt(map['capacity']),
      rating:
          _toDouble(map['rating']),
      latitude:
          _toDouble(map['latitude']),
      longitude:
          _toDouble(map['longitude']),
      extraData:
          _toMap(map['extraData']),
    );
  }

  // ------------------------------------------------------------
  // تبدیل امن به double
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

    return double.tryParse(
      value.toString(),
    );
  }

  // ------------------------------------------------------------
  // تبدیل امن به int
  // ------------------------------------------------------------

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ------------------------------------------------------------
  // تبدیل امن به List<String>
  // ------------------------------------------------------------

  static List<String>? _toStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return null;
    }

    return value
        .map((item) => item.toString())
        .toList();
  }

  // ------------------------------------------------------------
  // تبدیل امن به Map
  // ------------------------------------------------------------

  static Map<String, dynamic>? _toMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  // ------------------------------------------------------------
  // ساخت نسخه جدید
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
    String? bookingUrl,
    String? accommodationType,
    List<String>? amenities,
    int? capacity,
    double? rating,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? extraData,
  }) {
    return TourismItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      titleFa: titleFa ?? this.titleFa,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      descriptionFa:
          descriptionFa ?? this.descriptionFa,
      descriptionEn:
          descriptionEn ?? this.descriptionEn,
      descriptionAr:
          descriptionAr ?? this.descriptionAr,
      imageUrl:
          imageUrl ?? this.imageUrl,
      address:
          address ?? this.address,
      phone:
          phone ?? this.phone,
      websiteUrl:
          websiteUrl ?? this.websiteUrl,
      videoUrl:
          videoUrl ?? this.videoUrl,
      bookingUrl:
          bookingUrl ?? this.bookingUrl,
      accommodationType:
          accommodationType ??
              this.accommodationType,
      amenities:
          amenities ?? this.amenities,
      capacity:
          capacity ?? this.capacity,
      rating:
          rating ?? this.rating,
      latitude:
          latitude ?? this.latitude,
      longitude:
          longitude ?? this.longitude,
      extraData:
          extraData ?? this.extraData,
    );
  }

  // ------------------------------------------------------------
  // مقایسه
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
  // Debug
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
