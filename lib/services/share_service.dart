import 'package:flutter/services.dart';

import '../models/tourism_item.dart';

/// سرویس مرکزی اشتراک‌گذاری سایروس توریست.
///
/// متن اشتراک‌گذاری را برای جاذبه، اقامتگاه، مرکز سلامت،
/// ویدئو، راهنمای سفر و سایر محتواها آماده می‌کند.
class ShareService {
  /// ساخت متن اشتراک‌گذاری بر اساس زبان برنامه.
  String buildShareText(
    TourismItem item, {
    String languageCode = 'fa',
  }) {
    final title = item.titleForLanguage(languageCode);
    final description = item.descriptionForLanguage(languageCode);

    final parts = <String>[];

    if (title.trim().isNotEmpty) {
      parts.add(title.trim());
    }

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

  /// کپی متن در کلیپ‌بورد دستگاه.
  Future<void> copyText(String text) async {
    await Clipboard.setData(
      ClipboardData(text: text),
    );
  }
}
