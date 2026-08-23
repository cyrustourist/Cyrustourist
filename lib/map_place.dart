import 'package:latlong2/latlong.dart';

/// دسته‌بندی مکان‌های گردشگری و خدماتی
enum PlaceCategory {
  health,
  attraction,
  accommodation,
  restaurant,
  culture,
  service,
  other,
}

/// مدل مشترک تمام مکان‌های روی نقشه.
///
/// این مدل برای بیمارستان، درمانگاه، جاذبه گردشگری،
/// هتل، بوم‌گردی، هتل‌آپارتمان، کلبه، رستوران و...
/// استفاده خواهد شد.
class MapPlace {
  final String id;
  final String name;
  final String? description;

  /// مختصات مکان
  final LatLng location;

  /// دسته‌بندی اصلی مکان
  final PlaceCategory category;

  /// آدرس
  final String? address;

  /// شماره تلفن
  final String? phone;

  /// وب‌سایت
  final String? website;

  /// امتیاز مکان
  final double? rating;

  /// تعداد نظرات
  final int? reviewCount;

  /// فاصله از موقعیت فعلی کاربر، بر حسب متر
  final double? distanceMeters;

  /// آیا کاربر این مکان را به علاقه‌مندی‌ها اضافه کرده؟
  final bool isFavorite;

  /// آدرس تصویر مکان در صورت وجود
  final String? imageUrl;

  /// نوع منبع اطلاعات
  ///
  /// مثال:
  /// openstreetmap
  /// nominatim
  /// local
  /// remote
  final String? source;

  const MapPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.rating,
    this.reviewCount,
    this.distanceMeters,
    this.isFavorite = false,
    this.imageUrl,
    this.source,
  });

  /// رنگ مکان‌نما بر اساس دسته‌بندی
  int get markerColorValue {
    switch (category) {
      case PlaceCategory.health:
        return 0xFFE53935; // قرمز

      case PlaceCategory.attraction:
        return 0xFF2E7D32; // سبز

      case PlaceCategory.accommodation:
        return 0xFF1976D2; // آبی

      case PlaceCategory.restaurant:
        return 0xFFEF6C00; // نارنجی

      case PlaceCategory.culture:
        return 0xFF7B1FA2; // بنفش

      case PlaceCategory.service:
        return 0xFFF9A825; // زرد

      case PlaceCategory.other:
        return 0xFF455A64; // خاکستری
    }
  }

  /// نام دسته‌بندی برای نمایش به کاربر
  String categoryTitle({
    required String language,
  }) {
    switch (category) {
      case PlaceCategory.health:
        switch (language) {
          case 'en':
            return 'Health';
          case 'ar':
            return 'الصحة';
          default:
            return 'گردشگری سلامت';
        }

      case PlaceCategory.attraction:
        switch (language) {
          case 'en':
            return 'Attraction';
          case 'ar':
            return 'المعالم السياحية';
          default:
            return 'جاذبه گردشگری';
        }

      case PlaceCategory.accommodation:
        switch (language) {
          case 'en':
            return 'Accommodation';
          case 'ar':
            return 'الإقامة';
          default:
            return 'اقامتگاه';
        }

      case PlaceCategory.restaurant:
        switch (language) {
          case 'en':
            return 'Restaurant';
          case 'ar':
            return 'مطعم';
          default:
            return 'رستوران';
        }

      case PlaceCategory.culture:
        switch (language) {
          case 'en':
            return 'Culture & Art';
          case 'ar':
            return 'الثقافة والفن';
          default:
            return 'فرهنگ و هنر';
        }

      case PlaceCategory.service:
        switch (language) {
          case 'en':
            return 'Tourism Service';
          case 'ar':
            return 'خدمات سياحية';
          default:
            return 'خدمات گردشگری';
        }

      case PlaceCategory.other:
        switch (language) {
          case 'en':
            return 'Other';
          case 'ar':
            return 'أخرى';
          default:
            return 'سایر';
        }
    }
  }

  /// آیکون پیشنهادی برای مکان‌نما
  String get iconName {
    switch (category) {
      case PlaceCategory.health:
        return 'health';

      case PlaceCategory.attraction:
        return 'attraction';

      case PlaceCategory.accommodation:
        return 'hotel';

      case PlaceCategory.restaurant:
        return 'restaurant';

      case PlaceCategory.culture:
        return 'culture';

      case PlaceCategory.service:
        return 'service';

      case PlaceCategory.other:
        return 'place';
    }
  }

  /// ایجاد نسخه جدید از مکان با تغییر علاقه‌مندی
  MapPlace copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? location,
    PlaceCategory? category,
    String? address,
    String? phone,
    String? website,
    double? rating,
    int? reviewCount,
    double? distanceMeters,
    bool? isFavorite,
    String? imageUrl,
    String? source,
  }) {
    return MapPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceMeters:
          distanceMeters ?? this.distanceMeters,
      isFavorite:
          isFavorite ?? this.isFavorite,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
    );
  }

  /// تبدیل به Map برای ذخیره‌سازی آینده
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category.name,
      'address': address,
      'phone': phone,
      'website': website,
      'rating': rating,
      'reviewCount': reviewCount,
      'distanceMeters': distanceMeters,
      'isFavorite': isFavorite,
      'imageUrl': imageUrl,
      'source': source,
    };
  }

  /// ساخت MapPlace از اطلاعات ذخیره‌شده
  factory MapPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    final categoryName =
        json['category']?.toString();

    final category =
        PlaceCategory.values.firstWhere(
      (item) => item.name == categoryName,
      orElse: () => PlaceCategory.other,
    );

    return MapPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description:
          json['description']?.toString(),
      location: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0,
        (json['longitude'] as num?)?.toDouble() ?? 0,
      ),
      category: category,
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      rating:
          (json['rating'] as num?)?.toDouble(),
      reviewCount:
          (json['reviewCount'] as num?)?.toInt(),
      distanceMeters:
          (json['distanceMeters'] as num?)
              ?.toDouble(),
      isFavorite:
          json['isFavorite'] == true,
      imageUrl:
          json['imageUrl']?.toString(),
      source: json['source']?.toString(),
    );
  }
}
