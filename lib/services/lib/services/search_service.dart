import '../models/tourism_item.dart';

/// موتور جستجوی مرکزی سایروس توریست.
///
/// این سرویس برای کلیدهای مختلف برنامه مشترک است:
/// جاذبه‌ها، اقامتگاه‌ها، سلامت، فیلم‌ها، راهنمای سفر و خدمات.
///
/// جستجو از عنوان، توضیحات، دسته‌بندی و آدرس
/// در هر سه زبان پشتیبانی می‌کند.
class SearchService {
  /// جستجو در فهرست محتوا
  List<TourismItem> search({
    required List<TourismItem> items,
    required String query,
    String? type,
    String? category,
  }) {
    final text = query.trim().toLowerCase();

    return items.where((item) {
      // فیلتر نوع محتوا
      if (type != null &&
          type.trim().isNotEmpty &&
          item.type != type) {
        return false;
      }

      // فیلتر دسته‌بندی
      if (category != null &&
          category.trim().isNotEmpty &&
          item.category != category) {
        return false;
      }

      // اگر عبارت جستجو خالی باشد،
      // تمام موارد فیلترشده نمایش داده می‌شوند.
      if (text.isEmpty) {
        return true;
      }

      final searchableValues = <String>[
        item.titleFa,
        item.titleEn,
        item.titleAr,
        item.descriptionFa ?? '',
        item.descriptionEn ?? '',
        item.descriptionAr ?? '',
        item.address ?? '',
        item.category ?? '',
      ];

      return searchableValues.any(
        (value) => value.toLowerCase().contains(text),
      );
    }).toList();
  }

  /// جستجوی فقط در یک نوع محتوا
  List<TourismItem> searchByType({
    required List<TourismItem> items,
    required String query,
    required String type,
  }) {
    return search(
      items: items,
      query: query,
      type: type,
    );
  }

  /// جستجوی فقط در یک دسته
  List<TourismItem> searchByCategory({
    required List<TourismItem> items,
    required String query,
    required String category,
  }) {
    return search(
      items: items,
      query: query,
      category: category,
    );
  }
}
