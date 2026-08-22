import '../models/tourism_item.dart';

/// سرویس مرکزی مرتب‌سازی اطلاعات گردشگری سایروس توریست.
///
/// برای جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت، فیلم‌ها،
/// راهنماها و سایر محتواهای TourismItem قابل استفاده است.
class SortService {
  /// مرتب‌سازی بر اساس عنوان
  static List<TourismItem> byTitle(
    List<TourismItem> items, {
    String languageCode = 'fa',
    bool ascending = true,
  }) {
    final result = List<TourismItem>.from(items);

    result.sort((a, b) {
      final titleA = a.titleForLanguage(languageCode).trim();
      final titleB = b.titleForLanguage(languageCode).trim();

      final comparison = titleA.compareTo(titleB);

      return ascending ? comparison : -comparison;
    });

    return result;
  }

  /// مرتب‌سازی بر اساس نوع محتوا
  static List<TourismItem> byType(
    List<TourismItem> items, {
    bool ascending = true,
  }) {
    final result = List<TourismItem>.from(items);

    result.sort((a, b) {
      final comparison = a.type.compareTo(b.type);

      return ascending ? comparison : -comparison;
    });

    return result;
  }

  /// مرتب‌سازی بر اساس دسته‌بندی
  static List<TourismItem> byCategory(
    List<TourismItem> items, {
    String languageCode = 'fa',
    bool ascending = true,
  }) {
    final result = List<TourismItem>.from(items);

    result.sort((a, b) {
      final categoryA = (a.category ?? '').trim();
      final categoryB = (b.category ?? '').trim();

      final comparison = categoryA.compareTo(categoryB);

      return ascending ? comparison : -comparison;
    });

    return result;
  }

  /// مرتب‌سازی بر اساس فاصله از کاربر.
  ///
  /// distanceProvider باید فاصله هر آیتم را بر حسب متر برگرداند.
  /// آیتم‌هایی که فاصله ندارند، در انتهای فهرست قرار می‌گیرند.
  static List<TourismItem> byDistance(
    List<TourismItem> items, {
    required double? Function(TourismItem item) distanceProvider,
    bool nearestFirst = true,
  }) {
    final result = List<TourismItem>.from(items);

    result.sort((a, b) {
      final distanceA = distanceProvider(a);
      final distanceB = distanceProvider(b);

      if (distanceA == null && distanceB == null) {
        return 0;
      }

      if (distanceA == null) {
        return 1;
      }

      if (distanceB == null) {
        return -1;
      }

      final comparison = distanceA.compareTo(distanceB);

      return nearestFirst ? comparison : -comparison;
    });

    return result;
  }

  /// مرتب‌سازی با تابع سفارشی.
  ///
  /// برای توسعه‌های آینده و مرتب‌سازی‌های تخصصی استفاده می‌شود.
  static List<TourismItem> custom(
    List<TourismItem> items, {
    required int Function(TourismItem a, TourismItem b) compare,
  }) {
    final result = List<TourismItem>.from(items);

    result.sort(compare);

    return result;
  }
}
