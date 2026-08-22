import '../models/tourism_item.dart';

/// سرویس مرکزی آماده‌سازی اطلاعات جزئیات یک محتوای گردشگری.
///
/// این سرویس برای صفحات جاذبه، اقامتگاه، سلامت، فیلم،
/// راهنمای سفر و سایر محتواها قابل استفاده است.
///
/// هدف این سرویس جلوگیری از تکرار منطق مشترک در صفحات مختلف است.
class DetailsService {
  DetailsService._();

  // ------------------------------------------------------------
  // عنوان
  // ------------------------------------------------------------

  /// دریافت عنوان مناسب بر اساس زبان.
  static String title(
    TourismItem item,
    String languageCode,
  ) {
    return item.titleForLanguage(languageCode).trim();
  }

  // ------------------------------------------------------------
  // توضیحات
  // ------------------------------------------------------------

  /// دریافت توضیحات مناسب بر اساس زبان.
  static String description(
    TourismItem item,
    String languageCode,
  ) {
    return item
        .descriptionForLanguage(languageCode)
        .trim();
  }

  // ------------------------------------------------------------
  // دسته‌بندی
  // ------------------------------------------------------------

  static String category(TourismItem item) {
    return (item.category ?? '').trim();
  }

  // ------------------------------------------------------------
  // آدرس
  // ------------------------------------------------------------

  static String address(TourismItem item) {
    return (item.address ?? '').trim();
  }

  /// بررسی وجود آدرس.
  static bool hasAddress(TourismItem item) {
    return address(item).isNotEmpty;
  }

  // ------------------------------------------------------------
  // شماره تماس
  // ------------------------------------------------------------

  static String phone(TourismItem item) {
    return (item.phone ?? '').trim();
  }

  /// بررسی وجود شماره تماس.
  static bool hasPhone(TourismItem item) {
    return phone(item).isNotEmpty;
  }

  // ------------------------------------------------------------
  // وب‌سایت
  // ------------------------------------------------------------

  static String website(TourismItem item) {
    return (item.websiteUrl ?? '').trim();
  }

  /// بررسی وجود وب‌سایت.
  static bool hasWebsite(TourismItem item) {
    return item.hasWebsite;
  }

  // ------------------------------------------------------------
  // ویدئو
  // ------------------------------------------------------------

  static String video(TourismItem item) {
    return (item.videoUrl ?? '').trim();
  }

  /// بررسی وجود ویدئو.
  static bool hasVideo(TourismItem item) {
    return item.hasVideo;
  }

  // ------------------------------------------------------------
  // موقعیت جغرافیایی
  // ------------------------------------------------------------

  /// بررسی وجود مختصات معتبر.
  static bool hasLocation(TourismItem item) {
    return item.hasLocation;
  }

  /// دریافت عرض جغرافیایی.
  static double? latitude(TourismItem item) {
    if (!item.hasLocation) {
      return null;
    }

    return item.latitude;
  }

  /// دریافت طول جغرافیایی.
  static double? longitude(TourismItem item) {
    if (!item.hasLocation) {
      return null;
    }

    return item.longitude;
  }

  // ------------------------------------------------------------
  // تصویر
  // ------------------------------------------------------------

  static String imageUrl(TourismItem item) {
    return (item.imageUrl ?? '').trim();
  }

  /// بررسی وجود تصویر.
  static bool hasImage(TourismItem item) {
    return imageUrl(item).isNotEmpty;
  }

  // ------------------------------------------------------------
  // نوع محتوا
  // ------------------------------------------------------------

  static String type(TourismItem item) {
    return item.type.trim();
  }

  // ------------------------------------------------------------
  // شناسه
  // ------------------------------------------------------------

  static String id(TourismItem item) {
    return item.id.trim();
  }

  // ------------------------------------------------------------
  // بررسی اطلاعات اصلی
  // ------------------------------------------------------------

  /// بررسی اینکه آیتم حداقل اطلاعات لازم برای نمایش دارد.
  static bool isDisplayable(TourismItem item) {
    return item.id.trim().isNotEmpty &&
        (item.titleFa.trim().isNotEmpty ||
            item.titleEn.trim().isNotEmpty ||
            item.titleAr.trim().isNotEmpty);
  }

  // ------------------------------------------------------------
  // بررسی امکان مسیریابی
  // ------------------------------------------------------------

  /// اگر مختصات معتبر وجود داشته باشد،
  /// امکان نمایش روی نقشه و مسیریابی وجود دارد.
  static bool canNavigate(TourismItem item) {
    return item.hasLocation;
  }

  // ------------------------------------------------------------
  // بررسی اطلاعات تماس
  // ------------------------------------------------------------

  /// آیا آیتم حداقل یکی از راه‌های تماس را دارد؟
  static bool hasContact(TourismItem item) {
    return hasPhone(item) || hasWebsite(item);
  }

  // ------------------------------------------------------------
  // بررسی قابلیت‌های آیتم
  // ------------------------------------------------------------

  /// فهرست قابلیت‌های موجود برای یک آیتم.
  ///
  /// مقادیر:
  /// location
  /// phone
  /// website
  /// video
  /// image
  /// address
  static Set<String> availableFeatures(
    TourismItem item,
  ) {
    final features = <String>{};

    if (hasLocation(item)) {
      features.add('location');
    }

    if (hasPhone(item)) {
      features.add('phone');
    }

    if (hasWebsite(item)) {
      features.add('website');
    }

    if (hasVideo(item)) {
      features.add('video');
    }

    if (hasImage(item)) {
      features.add('image');
    }

    if (hasAddress(item)) {
      features.add('address');
    }

    return features;
  }
}
