import '../models/tourism_item.dart';

/// سرویس مرکزی جستجوی سایروس توریست.
///
/// جستجو در تمام بخش‌های برنامه قابل استفاده است:
/// جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت، فیلم‌ها،
— راهنماها و خدمات.
///
/// جستجو با عنوان، توضیحات، دسته‌بندی، آدرس و نوع محتوا
/// انجام می‌شود و برای فارسی، English و العربية آماده است.
class SearchService {
  /// جستجوی عمومی در فهرست آیتم‌ها.
  ///
  /// اگر query خالی باشد، تمام آیتم‌ها برگردانده می‌شوند.
  List<TourismItem> search({
    required List<TourismItem> items,
    required String query,
    String languageCode = 'fa',
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return List<TourismItem>.from(items);
    }

    return items.where((item) {
      final title = _normalize(
        item.titleForLanguage(languageCode),
      );

      final description = _normalize(
        item.descriptionForLanguage(languageCode),
      );

      final category = _normalize(
        item.category ?? '',
      );

      final address = _normalize(
        item.address ?? '',
      );

      final type = _normalize(item.type);

      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          category.contains(normalizedQuery) ||
          address.contains(normalizedQuery) ||
          type.contains(normalizedQuery);
    }).toList();
  }

  /// جستجو در تمام زبان‌های موجود.
  ///
  /// زمانی مفید است که کاربر مثلاً در حالت فارسی،
  /// نام انگلیسی یا عربی یک مکان را جستجو کند.
  List<TourismItem> searchAllLanguages({
    required List<TourismItem> items,
    required String query,
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return List<TourismItem>.from(items);
    }

    return items.where((item) {
      final values = <String>[
        item.titleFa,
        item.titleEn,
        item.titleAr,
        item.descriptionFa ?? '',
        item.descriptionEn ?? '',
        item.descriptionAr ?? '',
        item.category ?? '',
        item.address ?? '',
        item.type,
      ];

      return values.any(
        (value) =>
            _normalize(value).contains(normalizedQuery),
      );
    }).toList();
  }

  /// جستجو بر اساس نوع محتوا.
  ///
  /// نمونه:
  /// health
  /// attraction
  /// accommodation
  /// video
  /// travelGuide
  List<TourismItem> searchByType({
    required List<TourismItem> items,
    required String type,
    String query = '',
    String languageCode = 'fa',
  }) {
    final typeItems = items.where(
      (item) =>
          item.type.toLowerCase() ==
          type.toLowerCase(),
    );

    return search(
      items: typeItems.toList(),
      query: query,
      languageCode: languageCode,
    );
  }

  /// جستجوی چند نوع محتوا به صورت هم‌زمان.
  List<TourismItem> searchByTypes({
    required List<TourismItem> items,
    required List<String> types,
    String query = '',
    String languageCode = 'fa',
  }) {
    final normalizedTypes = types
        .map((type) => type.toLowerCase())
        .toSet();

    final filtered = items.where(
      (item) =>
          normalizedTypes.contains(
            item.type.toLowerCase(),
          ),
    );

    return search(
      items: filtered.toList(),
      query: query,
      languageCode: languageCode,
    );
  }

  /// جستجوی عنوان.
  List<TourismItem> searchTitles({
    required List<TourismItem> items,
    required String query,
    String languageCode = 'fa',
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return List<TourismItem>.from(items);
    }

    return items.where((item) {
      final titles = <String>[
        item.titleFa,
        item.titleEn,
        item.titleAr,
      ];

      if (languageCode == 'fa') {
        return _normalize(item.titleFa)
            .contains(normalizedQuery);
      }

      if (languageCode == 'en') {
        return _normalize(item.titleEn)
            .contains(normalizedQuery);
      }

      if (languageCode == 'ar') {
        return _normalize(item.titleAr)
            .contains(normalizedQuery);
      }

      return titles.any(
        (title) =>
            _normalize(title).contains(normalizedQuery),
      );
    }).toList();
  }

  /// نرمال‌سازی متن برای جستجوی بهتر.
  ///
  /// تفاوت‌های رایج فارسی و عربی مانند:
  /// ي → ی
  /// ك → ک
  /// و فاصله‌های اضافی را مدیریت می‌کند.
  String _normalize(String value) {
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
