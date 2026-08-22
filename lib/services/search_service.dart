import '../models/tourism_item.dart';

/// سرویس مرکزی جستجوی سایروس توریست.
///
/// جستجو در تمام بخش‌های برنامه قابل استفاده است:
/// جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت، فیلم‌ها،
/// راهنماها و خدمات.
///
/// برای فارسی، English و العربية آماده است.
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
      final values = _searchableValues(
        item,
        languageCode,
      );

      return values.any(
        (value) =>
            _normalize(value).contains(normalizedQuery),
      );
    }).toList();
  }

  /// جستجو در تمام زبان‌های موجود.
  ///
  /// حتی اگر زبان فعلی فارسی باشد،
  /// نام انگلیسی یا عربی نیز قابل جستجو است.
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
        item.accommodationType ?? '',
        ...(item.amenities ?? <String>[]),
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
  /// service
  List<TourismItem> searchByType({
    required List<TourismItem> items,
    required String type,
    String query = '',
    String languageCode = 'fa',
  }) {
    final normalizedType = type.trim().toLowerCase();

    final typeItems = items.where(
      (item) =>
          item.type.trim().toLowerCase() ==
          normalizedType,
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
        .map(
          (type) => type.trim().toLowerCase(),
        )
        .toSet();

    final filtered = items.where(
      (item) => normalizedTypes.contains(
        item.type.trim().toLowerCase(),
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
      final title = item.titleForLanguage(
        languageCode,
      );

      return _normalize(title).contains(
        normalizedQuery,
      );
    }).toList();
  }

  /// جستجوی عنوان در تمام زبان‌ها.
  List<TourismItem> searchTitlesAllLanguages({
    required List<TourismItem> items,
    required String query,
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return List<TourismItem>.from(items);
    }

    return items.where((item) {
      return _normalize(item.titleFa)
              .contains(normalizedQuery) ||
          _normalize(item.titleEn)
              .contains(normalizedQuery) ||
          _normalize(item.titleAr)
              .contains(normalizedQuery);
    }).toList();
  }

  /// جستجوی فقط در یک دسته‌بندی.
  List<TourismItem> searchByCategory({
    required List<TourismItem> items,
    required String category,
    String query = '',
    String languageCode = 'fa',
  }) {
    final normalizedCategory =
        _normalize(category);

    final filtered = items.where(
      (item) =>
          _normalize(item.category ?? '') ==
          normalizedCategory,
    );

    return search(
      items: filtered.toList(),
      query: query,
      languageCode: languageCode,
    );
  }

  /// جستجو در آیتم‌هایی که موقعیت جغرافیایی دارند.
  List<TourismItem> withLocation(
    List<TourismItem> items,
  ) {
    return items
        .where((item) => item.hasLocation)
        .toList();
  }

  /// جستجو در آیتم‌هایی که ویدئو دارند.
  List<TourismItem> withVideo(
    List<TourismItem> items,
  ) {
    return items
        .where((item) => item.hasVideo)
        .toList();
  }

  /// جستجو در آیتم‌هایی که لینک رزرو دارند.
  List<TourismItem> withBooking(
    List<TourismItem> items,
  ) {
    return items
        .where((item) => item.hasBooking)
        .toList();
  }

  /// مقادیر قابل جستجوی یک آیتم.
  List<String> _searchableValues(
    TourismItem item,
    String languageCode,
  ) {
    final values = <String>[
      item.titleForLanguage(languageCode),
      item.descriptionForLanguage(languageCode),
      item.category ?? '',
      item.address ?? '',
      item.type,
      item.accommodationType ?? '',
      ...(item.amenities ?? <String>[]),
    ];

    // در حالت ناشناخته یا خالی، همه زبان‌ها بررسی شوند.
    if (languageCode != 'fa' &&
        languageCode != 'en' &&
        languageCode != 'ar') {
      values.addAll([
        item.titleFa,
        item.titleEn,
        item.titleAr,
        item.descriptionFa ?? '',
        item.descriptionEn ?? '',
        item.descriptionAr ?? '',
      ]);
    }

    return values;
  }

  /// نرمال‌سازی متن برای جستجوی بهتر.
  ///
  /// تفاوت‌های رایج فارسی و عربی:
  /// ي → ی
  /// ى → ی
  /// ك → ک
  /// ة → ه
  /// همچنین فاصله‌های اضافی حذف می‌شوند.
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
