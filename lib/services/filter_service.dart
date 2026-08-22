import '../models/tourism_item.dart';

/// سرویس مرکزی فیلتر اطلاعات گردشگری سایروس توریست.
///
/// برای فیلتر کردن جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت،
/// فیلم‌ها، راهنماهای سفر و سایر محتواها استفاده می‌شود.
///
/// این سرویس مستقل از رابط کاربری است و در صفحات مختلف
/// کلیدهای ۲ تا ۱۰ قابل استفاده خواهد بود.
class FilterService {
  /// فیلتر بر اساس نوع محتوا.
  static List<TourismItem> byType(
    List<TourismItem> items,
    String? type,
  ) {
    if (type == null || type.trim().isEmpty) {
      return List<TourismItem>.from(items);
    }

    final normalizedType = type.trim().toLowerCase();

    return items.where((item) {
      return item.type.trim().toLowerCase() ==
          normalizedType;
    }).toList();
  }

  /// فیلتر بر اساس چند نوع محتوا.
  static List<TourismItem> byTypes(
    List<TourismItem> items,
    Iterable<String>? types,
  ) {
    if (types == null) {
      return List<TourismItem>.from(items);
    }

    final normalizedTypes = types
        .map((type) => type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toSet();

    if (normalizedTypes.isEmpty) {
      return List<TourismItem>.from(items);
    }

    return items.where((item) {
      return normalizedTypes.contains(
        item.type.trim().toLowerCase(),
      );
    }).toList();
  }

  /// فیلتر بر اساس دسته‌بندی.
  static List<TourismItem> byCategory(
    List<TourismItem> items,
    String? category,
  ) {
    if (category == null || category.trim().isEmpty) {
      return List<TourismItem>.from(items);
    }

    final normalizedCategory =
        _normalize(category);

    return items.where((item) {
      return _normalize(item.category ?? '') ==
          normalizedCategory;
    }).toList();
  }

  /// فقط آیتم‌های دارای مختصات معتبر.
  static List<TourismItem> withLocation(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return item.hasLocation;
    }).toList();
  }

  /// فقط آیتم‌های فاقد مختصات.
  static List<TourismItem> withoutLocation(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return !item.hasLocation;
    }).toList();
  }

  /// فقط آیتم‌های دارای ویدئو.
  static List<TourismItem> withVideo(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return item.hasVideo;
    }).toList();
  }

  /// فقط آیتم‌های دارای وب‌سایت.
  static List<TourismItem> withWebsite(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return item.hasWebsite;
    }).toList();
  }

  /// فیلتر بر اساس وجود شماره تماس.
  static List<TourismItem> withPhone(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return item.phone != null &&
          item.phone!.trim().isNotEmpty;
    }).toList();
  }

  /// فیلتر بر اساس وجود آدرس.
  static List<TourismItem> withAddress(
    List<TourismItem> items,
  ) {
    return items.where((item) {
      return item.address != null &&
          item.address!.trim().isNotEmpty;
    }).toList();
  }

  /// فیلتر ترکیبی.
  ///
  /// هر پارامتر اختیاری است و فقط در صورت مقدار داشتن
  /// روی فهرست اعمال می‌شود.
  static List<TourismItem> apply(
    List<TourismItem> items, {
    String? type,
    String? category,
    bool? hasLocation,
    bool? hasVideo,
    bool? hasWebsite,
    bool? hasPhone,
    bool? hasAddress,
  }) {
    var result = List<TourismItem>.from(items);

    if (type != null && type.trim().isNotEmpty) {
      result = byType(result, type);
    }

    if (category != null &&
        category.trim().isNotEmpty) {
      result = byCategory(result, category);
    }

    if (hasLocation != null) {
      result = result.where((item) {
        return item.hasLocation == hasLocation;
      }).toList();
    }

    if (hasVideo != null) {
      result = result.where((item) {
        return item.hasVideo == hasVideo;
      }).toList();
    }

    if (hasWebsite != null) {
      result = result.where((item) {
        return item.hasWebsite == hasWebsite;
      }).toList();
    }

    if (hasPhone != null) {
      result = result.where((item) {
        final exists = item.phone != null &&
            item.phone!.trim().isNotEmpty;

        return exists == hasPhone;
      }).toList();
    }

    if (hasAddress != null) {
      result = result.where((item) {
        final exists = item.address != null &&
            item.address!.trim().isNotEmpty;

        return exists == hasAddress;
      }).toList();
    }

    return result;
  }

  /// نرمال‌سازی متن برای فیلتر فارسی و عربی.
  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
