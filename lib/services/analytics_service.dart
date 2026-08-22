/// سرویس مرکزی ثبت رویدادهای اپلیکیشن سایروس توریست.
///
/// این سرویس فعلاً بدون وابستگی به سرویس‌های خارجی طراحی شده
/// تا در آینده بتوان Firebase Analytics یا سرویس مشابه را
/// بدون تغییر در صفحات برنامه به آن متصل کرد.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  bool _initialized = false;

  /// آیا سرویس آماده شده است؟
  bool get isInitialized => _initialized;

  /// آماده‌سازی سرویس تحلیل رفتار کاربران.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
  }

  /// ثبت یک رویداد عمومی.
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // محل اتصال سرویس Analytics واقعی در آینده.
    // فعلاً رویدادها بدون ارسال اطلاعات شخصی ثبت می‌شوند.
  }

  /// ثبت باز شدن صفحه.
  Future<void> logScreenView(String screenName) async {
    await logEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
      },
    );
  }

  /// ثبت جستجوی کاربر.
  Future<void> logSearch(String query) async {
    final value = query.trim();

    if (value.isEmpty) {
      return;
    }

    await logEvent(
      'search',
      parameters: {
        'query': value,
      },
    );
  }

  /// ثبت مشاهده یک محتوای گردشگری.
  Future<void> logTourismItemView({
    required String itemId,
    required String type,
  }) async {
    if (itemId.trim().isEmpty) {
      return;
    }

    await logEvent(
      'tourism_item_view',
      parameters: {
        'item_id': itemId,
        'item_type': type,
      },
    );
  }

  /// ثبت اضافه شدن آیتم به علاقه‌مندی‌ها.
  Future<void> logFavoriteAdded({
    required String itemId,
    required String type,
  }) async {
    await logEvent(
      'favorite_added',
      parameters: {
        'item_id': itemId,
        'item_type': type,
      },
    );
  }

  /// ثبت حذف آیتم از علاقه‌مندی‌ها.
  Future<void> logFavoriteRemoved({
    required String itemId,
    required String type,
  }) async {
    await logEvent(
      'favorite_removed',
      parameters: {
        'item_id': itemId,
        'item_type': type,
      },
    );
  }

  /// ثبت باز شدن مسیر یا نقشه.
  Future<void> logMapOpened({
    String? itemId,
  }) async {
    await logEvent(
      'map_opened',
      parameters: {
        if (itemId != null && itemId.trim().isNotEmpty)
          'item_id': itemId,
      },
    );
  }

  /// ثبت اشتراک‌گذاری محتوا.
  Future<void> logShare({
    required String itemId,
    String? platform,
  }) async {
    await logEvent(
      'content_shared',
      parameters: {
        'item_id': itemId,
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform,
      },
    );
  }

  /// ثبت تغییر زبان.
  Future<void> logLanguageChanged(
    String languageCode,
  ) async {
    final language = languageCode.trim();

    if (language.isEmpty) {
      return;
    }

    await logEvent(
      'language_changed',
      parameters: {
        'language': language,
      },
    );
  }

  /// ثبت خطا بدون ذخیره اطلاعات حساس کاربر.
  Future<void> logError({
    required String error,
    String? source,
  }) async {
    if (error.trim().isEmpty) {
      return;
    }

    await logEvent(
      'app_error',
      parameters: {
        'error': error,
        if (source != null && source.trim().isNotEmpty)
          'source': source,
      },
    );
  }

  /// بازنشانی وضعیت سرویس.
  Future<void> reset() async {
    _initialized = false;
  }
}
