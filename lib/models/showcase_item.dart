// مدل مشترک همه‌ی صفحه‌های «نمایش» (فیلم، جاذبه، اقامتگاه، سلامت،
// لیدر، آژانس). داده‌ی محلی و داده‌ی سرور هر دو به همین مدل تبدیل
// می‌شوند تا یک قالب برای همه کار کند.

enum ShowcaseKind { video, attraction, accommodation, health, leader, agency }

extension ShowcaseKindX on ShowcaseKind {
  /// نام این بخش در آدرس API سرور: /api/v1/showcase/<apiName>
  String get apiName {
    switch (this) {
      case ShowcaseKind.video:
        return 'video';
      case ShowcaseKind.attraction:
        return 'attraction';
      case ShowcaseKind.accommodation:
        return 'accommodation';
      case ShowcaseKind.health:
        return 'health';
      case ShowcaseKind.leader:
        return 'leader';
      case ShowcaseKind.agency:
        return 'agency';
    }
  }

  /// آیا آیتم‌های این بخش فیلم دارند (قلب علاقه‌مندی و دکمه پخش)
  bool get isVideoLike =>
      this == ShowcaseKind.video || this == ShowcaseKind.attraction;
}

/// سطح نمایش (درآمدزایی): سرور تعیین می‌کند، اپ فقط نمایش می‌دهد.
enum ShowcaseTier { normal, vip, sponsored }

ShowcaseTier showcaseTierFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'vip':
      return ShowcaseTier.vip;
    case 'sponsored':
    case 'ad':
      return ShowcaseTier.sponsored;
    default:
      return ShowcaseTier.normal;
  }
}

/// یکسان‌سازی متن برای جست‌وجو: ی/ک عربی، ارقام فارسی/عربی، نیم‌فاصله.
String showcaseNormalize(String input) {
  var s = input.toLowerCase();
  s = s
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ة', 'ه')
      .replaceAll('\u200c', ' ')
      .replaceAll('\u064b', '')
      .replaceAll('\u064e', '')
      .replaceAll('\u064f', '')
      .replaceAll('\u0650', '');
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class ShowcaseItem {
  const ShowcaseItem({
    required this.kind,
    required this.code,
    this.titles = const {},
    this.locations = const {},
    this.descriptions = const {},
    this.categoryLabels = const {},
    this.categories = const [],
    this.videoUrl,
    this.coverUrl,
    this.coverAsset,
    this.durationSeconds,
    this.phone,
    this.instagramUrl,
    this.websiteUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
    this.tier = ShowcaseTier.normal,
    this.priority = 0,
    this.ctaUrl,
    this.ctaLabels = const {},
    this.expiresAt,
    this.native,
  });

  final ShowcaseKind kind;

  /// کد یکتا در هر بخش (قابل جست‌وجو)
  final int code;

  /// متن‌های چندزبانه: کلید = کد زبان (fa, en, ar, ...)
  final Map<String, String> titles;
  final Map<String, String> locations;
  final Map<String, String> descriptions;
  final Map<String, String> categoryLabels;

  /// کلید دسته‌ها برای نوار ابزار (مثلاً hotel, nature) — از دیتابیس
  final List<String> categories;

  final String? videoUrl;
  final String? coverUrl;
  final String? coverAsset;
  final int? durationSeconds;

  final String? phone;
  final String? instagramUrl;
  final String? websiteUrl;
  final double? latitude;
  final double? longitude;

  final double? rating;
  final int? ratingCount;

  // ---------------- درآمدزایی (از سرور) ----------------
  final ShowcaseTier tier;

  /// عدد بزرگ‌تر = بالاتر در لیست
  final int priority;

  final String? ctaUrl;
  final Map<String, String> ctaLabels;
  final DateTime? expiresAt;

  /// مدل اصلی محلی (MovieSlotData / ResidenceVideoData / Leader / Agency)
  /// برای باز کردن همان صفحه‌ی جزئیات موجود.
  final Object? native;

  static String pick(Map<String, String> map, String lang) {
    final v = map[lang];
    if (v != null && v.isNotEmpty) return v;
    final en = map['en'];
    if (en != null && en.isNotEmpty) return en;
    final fa = map['fa'];
    if (fa != null && fa.isNotEmpty) return fa;
    for (final e in map.values) {
      if (e.isNotEmpty) return e;
    }
    return '';
  }

  String get id => '${kind.apiName}:$code';

  String title(String lang) => pick(titles, lang);
  String location(String lang) => pick(locations, lang);
  String description(String lang) => pick(descriptions, lang);
  String categoryLabel(String lang) => pick(categoryLabels, lang);
  String ctaLabel(String lang) => pick(ctaLabels, lang);

  /// استان = آخرین بخش بعد از «،» یا «,»
  String province(String lang) {
    final loc = location(lang);
    if (loc.isEmpty) return '';
    final parts = loc.split(RegExp(r'[،,]'));
    return parts.last.trim();
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  /// هش ویدیوی آپارات (اگر videoUrl از آپارات باشد)
  String? get aparatHash {
    final url = videoUrl;
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('aparat')) return null;
    final segs = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segs.isEmpty) return null;
    if (segs.first == 'v' && segs.length >= 2) return segs[1];
    return segs.last;
  }

  /// متن جست‌وجو: کد + همه‌ی زبان‌های عنوان/مکان/توضیح/دسته
  String get searchText => showcaseNormalize([
        code.toString(),
        ...titles.values,
        ...locations.values,
        ...descriptions.values,
        ...categoryLabels.values,
        ...categories,
      ].join(' '));

  /// متن مخصوص فیلتر نوار ابزار (بدون توضیحات، تا اشتباه تطبیق ندهد)
  String get filterText => showcaseNormalize([
        ...titles.values,
        ...categoryLabels.values,
        ...categories,
      ].join(' '));

  int get tierWeight {
    switch (tier) {
      case ShowcaseTier.sponsored:
        return 2;
      case ShowcaseTier.vip:
        return 1;
      case ShowcaseTier.normal:
        return 0;
    }
  }

  /// ساختار سازگار با VideoFavoritesService (صفحه علاقه‌مندی‌ها)
  Map<String, String> toFavoriteMap() => {
        'title_fa': pick(titles, 'fa'),
        'title_en': pick(titles, 'en'),
        'title_ar': pick(titles, 'ar'),
        'location_fa': pick(locations, 'fa'),
        'location_en': pick(locations, 'en'),
        'location_ar': pick(locations, 'ar'),
        'category_fa': pick(categoryLabels, 'fa'),
        'category_en': pick(categoryLabels, 'en'),
        'category_ar': pick(categoryLabels, 'ar'),
        'kind': kind.apiName,
        'code': code.toString(),
        'image': coverUrl ?? coverAsset ?? 'assets/images/video_attraction.jpg',
        'url': videoUrl ?? id,
      };

  static Map<String, String> _map(dynamic v) {
    if (v is Map) {
      final out = <String, String>{};
      v.forEach((k, val) {
        final s = val?.toString() ?? '';
        if (s.isNotEmpty) out[k.toString()] = s;
      });
      return out;
    }
    if (v is String && v.isNotEmpty) return {'fa': v};
    return const {};
  }

  /// از JSON سرور — ساختار در سند API آمده است.
  factory ShowcaseItem.fromJson(ShowcaseKind kind, Map<String, dynamic> j) {
    double? d(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int? i(dynamic v) => v == null ? null : int.tryParse(v.toString());

    return ShowcaseItem(
      kind: kind,
      code: i(j['code']) ?? i(j['id']) ?? 0,
      titles: _map(j['title']),
      locations: _map(j['location']),
      descriptions: _map(j['description']),
      categoryLabels: _map(j['category_label']),
      categories: (j['categories'] is List)
          ? (j['categories'] as List).map((e) => e.toString()).toList()
          : const [],
      videoUrl: j['video_url']?.toString(),
      coverUrl: j['cover_url']?.toString(),
      durationSeconds: i(j['duration']),
      phone: j['phone']?.toString(),
      instagramUrl: j['instagram']?.toString(),
      websiteUrl: j['website']?.toString(),
      latitude: d(j['lat']),
      longitude: d(j['lng']),
      rating: d(j['rating']),
      ratingCount: i(j['rating_count']),
      tier: showcaseTierFromString(j['tier']?.toString()),
      priority: i(j['priority']) ?? 0,
      ctaUrl: j['cta_url']?.toString(),
      ctaLabels: _map(j['cta_label']),
      expiresAt: DateTime.tryParse(j['expires_at']?.toString() ?? ''),
    );
  }
}
