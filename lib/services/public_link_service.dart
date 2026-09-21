import '../models/showcase_item.dart';

/// ===============================================================
/// لینک‌های عمومی سایروس توریست (Share / QR / Deep Link)
/// ---------------------------------------------------------------
/// طبق دستورکار: لینک عمومی بر اساس «شناسه‌ی داخلی پایدار» (Internal
/// Stable ID) ساخته می‌شود، نه بر اساس کد مدیریتی قابل تغییر.
///
///   Entity Type + Entity ID  →  https://cyrustourist.ir/<type>/<id>
///
/// ساختار نهایی URL را Backend مشخص می‌کند؛ اگر عوض شد فقط همین فایل
/// (متد [entityUrl]) تغییر می‌کند.
/// ===============================================================
class PublicLinkService {
  PublicLinkService._();

  static const String baseUrl = 'https://cyrustourist.ir';

  // سه مسیر رسمی نصب (دستورکار — بخش ۳۲)
  static const String bazaarUrl =
      'http://cafebazaar.ir/app/?id=cyrustourist.ir.app&ref=share';
  static const String myketUrl = 'https://myket.ir/app/cyrustourist.ir.app';
  static const String directDownloadUrl =
      'https://cyrustourist.ir/downloads/android.html';

  /// انواع موجودیت قابل اشتراک
  static const String tour = 'tour';
  static const String video = 'video';
  static const String guide = 'guide';
  static const String agency = 'agency';
  static const String accommodation = 'accommodation';
  static const String attraction = 'attraction';
  static const String health = 'health';

  static String entityUrl(String entityType, String entityId) {
    return '$baseUrl/$entityType/$entityId';
  }

  /// نوع موجودیت برای هر بخش «نمایش»
  static String typeForShowcaseKind(ShowcaseKind kind) {
    switch (kind) {
      case ShowcaseKind.leader:
        return guide;
      case ShowcaseKind.agency:
        return agency;
      case ShowcaseKind.accommodation:
        return accommodation;
      case ShowcaseKind.attraction:
        return attraction;
      case ShowcaseKind.health:
        return health;
      case ShowcaseKind.video:
        return video;
    }
  }
}
