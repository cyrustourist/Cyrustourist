import 'package:flutter/services.dart';

import '../models/tourism_item.dart';

/// سرویس مرکزی اشتراک‌گذاری سایروس توریست.
///
/// این سرویس اطلاعات یک آیتم گردشگری را به متن قابل
/// اشتراک‌گذاری تبدیل می‌کند.
///
/// اتصال به Share Sheet واقعی دستگاه در مرحله UI
/// انجام خواهد شد تا وابستگی غیرضروری به پکیج جدید
/// ایجاد نشود.
class ShareService {
  /// ساخت متن مناسب برای اشتراک‌گذاری یک آیتم
  String buildShareText(
    TourismItem item, {
    String languageCode = 'fa',
  }) {
    final title = item.titleForLanguage(languageCode);
    final description = item.descriptionForLanguage(languageCode);

    final parts = <String>[
      title,
    ];

    if (description.trim().isNotEmpty) {
      parts.add(description.trim());
    }

    if (item.address != null &&
        item.address!.trim().isNotEmpty) {
      parts.add(item.address!.trim());
    }

    if (item.websiteUrl != null &&
        item.websiteUrl!.trim().isNotEmpty) {
      parts.add(item.websiteUrl!.trim());
    }

    if (item.videoUrl != null &&
        item.videoUrl!.trim().isNotEmpty) {
      parts.add(item.videoUrl!.trim());
    }

    if (item.hasLocation) {
      parts.add(
        'https://www.google.com/maps/search/?api=1'
        '&query=${item.latitude},${item.longitude}',
      );
    }

    return parts.join('\n\n');
  }

  /// کپی متن در کلیپ‌بورد دستگاه
  Future<void> copyText(String text) async {
    await Clipboard.setData(
      ClipboardData(text: text),
    );
  }
}
