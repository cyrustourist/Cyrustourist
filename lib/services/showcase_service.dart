import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/agency.dart';
import '../models/leader.dart';
import '../models/showcase_item.dart';
import '../pages/movie_video_page.dart' show MovieSlotData, kMovieSlots;
import '../pages/residence_video_page.dart'
    show ResidenceVideoData, kResidenceSlots;
import '../pages/showcase/showcase_kinds.dart';
import '../config/api_config.dart';
import '../core/network/api_service.dart';

/// تنظیمات اتصال به سرور.
///
/// آدرس واقعی از تنظیمات مرکزی [ApiConfig] خوانده می‌شود (طبق «دستور کار
/// فنی Android» — Base URL فقط یک محل دارد). اگر بک‌اند این Endpoint را
/// هنوز نداشته باشد، درخواست با خطا مواجه و به‌صورت خودکار از Cache یا
/// داده‌ی محلی همین فایل استفاده می‌شود؛ چیزی Crash نمی‌کند.
class ShowcaseConfig {
  ShowcaseConfig._();

  static const String apiBaseUrl = ApiConfig.baseUrl;

  /// کلید عمومی اختیاری (هدر X-Api-Key)
  static const String apiKey = ApiConfig.apiKey;

  static const Duration timeout = ApiConfig.timeout;
}

enum ShowcaseSource { local, server, cache }

class ShowcaseLoad {
  const ShowcaseLoad({
    required this.items,
    this.filters,
    this.source = ShowcaseSource.local,
  });

  final List<ShowcaseItem> items;

  /// نوار ابزار ارسالی از سرور (اختیاری؛ اگر نباشد نوار پیش‌فرض می‌آید)
  final List<ShowcaseFilter>? filters;
  final ShowcaseSource source;
}

class ShowcaseService {
  ShowcaseService._();

  static Future<ShowcaseLoad> load(ShowcaseKind kind,
      {String lang = 'fa'}) async {
    final local = ShowcaseLoad(items: localItems(kind));
    final endpoint = _endpointFor(kind);

    // فقط Endpointهایی که در Worker فعلی وجود دارند از سرور خوانده می‌شوند.
    // برای بخش‌های هنوز آماده‌نشده، مستقیم از Cache/Fallback محلی استفاده می‌شود.
    if (endpoint == null) return local;

    final cacheKey = 'showcase_cache_${kind.apiName}';
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    try {
      final json = await ApiService.getJson(endpoint);
      final parsed = _parse(kind, json, ShowcaseSource.server);
      if (parsed.items.isNotEmpty) {
        await prefs?.setString(cacheKey, jsonEncode(json));
        return parsed;
      }
    } catch (_) {}

    final cached = prefs?.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final parsed = _parse(kind, jsonDecode(cached), ShowcaseSource.cache);
        if (parsed.items.isNotEmpty) return parsed;
      } catch (_) {}
    }

    return local;
  }

  /// Endpointهای واقعی Worker فعلی.
  /// عمداً /api/v1/showcase/* استفاده نمی‌شود؛ آن مسیر در Worker فعلی وجود ندارد.
  static String? _endpointFor(ShowcaseKind kind) {
    switch (kind) {
      case ShowcaseKind.video:
        return '/tourism-videos';
      case ShowcaseKind.attraction:
        return '/attractions';
      case ShowcaseKind.accommodation:
        return '/accommodations';
      case ShowcaseKind.health:
        return '/health-tourism';
      case ShowcaseKind.leader:
      case ShowcaseKind.agency:
        // این دو ماژول هنوز Endpoint عمومی نهایی در Worker فعلی ندارند.
        return null;
    }
  }

  static ShowcaseLoad _parse(
      ShowcaseKind kind, dynamic decoded, ShowcaseSource source) {
    final items = <ShowcaseItem>[];
    List<dynamic> rawItems = const [];

    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map) {
      final raw = decoded['items'] ?? decoded['data'] ?? decoded['results'];
      if (raw is List) rawItems = raw;
    }

    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      try {
        final item = _fromServerRow(kind, row);
        if (!item.isExpired) items.add(item);
      } catch (_) {
        // یک رکورد خراب نباید کل لیست را از کار بیندازد.
      }
    }

    return ShowcaseLoad(items: items, source: source);
  }

  static ShowcaseItem _fromServerRow(
      ShowcaseKind kind, Map<String, dynamic> j) {
    String? s(dynamic v) => v?.toString().trim().isEmpty == true
        ? null
        : v?.toString();
    double? d(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int code() => int.tryParse((j['id'] ?? j['code'] ?? 0).toString()) ?? 0;

    final fa = s(j['name_fa'] ?? j['title_fa'] ?? j['title'] ?? j['name']);
    final en = s(j['name_en'] ?? j['title_en']);
    final ar = s(j['name_ar'] ?? j['title_ar']);
    final cityFa = s(j['city_name'] ?? j['city_fa'] ?? j['city']);
    final cityEn = s(j['city_en']);
    final cityAr = s(j['city_ar']);
    final descFa = s(j['description_fa'] ?? j['message']);
    final descEn = s(j['description_en']);
    final descAr = s(j['description_ar']);

    return ShowcaseItem(
      kind: kind,
      code: code(),
      titles: _m(fa, en, ar),
      locations: _m(cityFa, cityEn, cityAr),
      descriptions: _m(descFa, descEn, descAr),
      categoryLabels: _m(s(j['category_fa'] ?? j['category']),
          s(j['category_en']), s(j['category_ar'])),
      videoUrl: s(j['video_url'] ?? j['video']),
      coverUrl: s(j['image_url'] ?? j['image'] ?? j['cover_url']),
      phone: s(j['phone_mobile'] ?? j['phone'] ?? j['mobile_phone']),
      instagramUrl: s(j['instagram_url'] ?? j['instagram']),
      websiteUrl: s(j['website_url'] ?? j['website']),
      latitude: d(j['latitude'] ?? j['lat']),
      longitude: d(j['longitude'] ?? j['lng']),
      rating: d(j['rating']),
      ratingCount: int.tryParse((j['rating_count'] ?? 0).toString()),
      native: j,
    );
  }

  // ------------------------------------------------------------
  // داده‌های محلی (تا زمان اتصال دیتابیس)
  // ------------------------------------------------------------

  static List<ShowcaseItem> localItems(ShowcaseKind kind) {
    switch (kind) {
      case ShowcaseKind.video:
      case ShowcaseKind.attraction:
        // فعلاً هر دو از همین لینک فیلم‌های موجود ساخته می‌شوند.
        return kMovieSlots
            .where((s) => s.assigned)
            .map((s) => _fromMovie(kind, s))
            .toList();

      case ShowcaseKind.accommodation:
        return kResidenceSlots
            .where((s) => s.assigned)
            .map(_fromResidence)
            .toList();

      case ShowcaseKind.health:
        return const [];

      case ShowcaseKind.leader:
        var code = 0;
        return approvedLeaders.map((l) => _fromLeader(++code, l)).toList();

      case ShowcaseKind.agency:
        var code = 0;
        return approvedAgencies.map((a) => _fromAgency(++code, a)).toList();
    }
  }

  static Map<String, String> _m(String? fa, [String? en, String? ar]) {
    final out = <String, String>{};
    if (fa != null && fa.isNotEmpty) out['fa'] = fa;
    if (en != null && en.isNotEmpty) out['en'] = en;
    if (ar != null && ar.isNotEmpty) out['ar'] = ar;
    return out;
  }

  static ShowcaseItem _fromMovie(ShowcaseKind kind, MovieSlotData s) {
    final hasDesc = (s.description ?? '').isNotEmpty;
    final cat = s.category ?? '';
    final city = s.city ?? '';
    final catEn = s.categoryEn ?? '';
    final cityEn = s.cityEn ?? '';
    final catAr = s.categoryAr ?? '';
    final cityAr = s.cityAr ?? '';

    final descriptions = hasDesc
        ? _m(s.description, s.descriptionEn, s.descriptionAr)
        : {
            'fa': 'بخشی از مجموعه فیلم‌های گردشگری سایروس توریست'
                '${cat.isNotEmpty ? '، در دسته‌ی $cat' : ''}'
                '${city.isNotEmpty ? '، در $city' : ''}.',
            'en': 'Part of the Cyrus Tourist video collection'
                '${catEn.isNotEmpty ? ', in the $catEn category' : ''}'
                '${cityEn.isNotEmpty ? ', in $cityEn' : ''}.',
            'ar': 'جزء من مجموعة فيديوهات سايروس توريست'
                '${catAr.isNotEmpty ? '، في فئة $catAr' : ''}'
                '${cityAr.isNotEmpty ? '، في $cityAr' : ''}.',
          };

    return ShowcaseItem(
      kind: kind,
      code: s.code,
      titles: _m(s.name, s.nameEn, s.nameAr),
      locations: _m(s.city, s.cityEn, s.cityAr),
      descriptions: descriptions,
      categoryLabels: _m(s.category, s.categoryEn, s.categoryAr),
      videoUrl: s.aparatUrl,
      phone: s.mobilePhone,
      instagramUrl: s.instagramUrl,
      websiteUrl: s.websiteUrl,
      latitude: s.latitude,
      longitude: s.longitude,
      native: s,
    );
  }

  static ShowcaseItem _fromResidence(ResidenceVideoData s) {
    String join(String? a, String? b) => [a, b]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join('، ');

    final hash = s.aparatHash;
    return ShowcaseItem(
      kind: ShowcaseKind.accommodation,
      code: s.code,
      titles: _m(s.name, s.nameEn, s.nameAr),
      locations: _m(join(s.city, s.province), join(s.cityEn, s.provinceEn),
          join(s.cityAr, s.provinceAr)),
      descriptions: _m(s.description, s.descriptionEn, s.descriptionAr),
      videoUrl: (hash != null && hash.isNotEmpty)
          ? 'https://www.aparat.com/v/$hash'
          : null,
      phone: s.mobilePhone ?? s.supportPhone ?? s.landlinePhone,
      instagramUrl: s.instagramUrl,
      websiteUrl: s.websiteUrl,
      latitude: s.latitude,
      longitude: s.longitude,
      rating: s.rating,
      ratingCount: s.ratingCount,
      native: s,
    );
  }

  static ShowcaseItem _fromLeader(int code, Leader l) {
    return ShowcaseItem(
      kind: ShowcaseKind.leader,
      code: code,
      titles: _m(l.name),
      locations: _m(l.city),
      descriptions: _m(l.bio),
      categoryLabels: _m(l.specialty),
      categories: [
        if (l.isLocalLeader) 'local',
        if (l.isLicensed) 'licensed',
      ],
      coverAsset: l.photoAsset,
      videoUrl: l.introVideoUrl,
      rating: l.rating,
      ratingCount: l.reviewCount,
      native: l,
    );
  }

  static ShowcaseItem _fromAgency(int code, Agency a) {
    return ShowcaseItem(
      kind: ShowcaseKind.agency,
      code: code,
      titles: _m(a.name),
      locations: _m(a.city),
      descriptions: _m(a.bio.isNotEmpty ? a.bio : a.services),
      categoryLabels: _m(a.services),
      categories: [if (a.isLicensed) 'licensed'],
      coverAsset: a.logoAsset,
      videoUrl: a.introVideoUrl,
      phone: a.phone,
      websiteUrl: a.website,
      rating: a.rating,
      ratingCount: a.reviewCount,
      native: a,
    );
  }
}

// ------------------------------------------------------------
// اطلاعات کاور/مدت فیلم از API رسمی آپارات
// ------------------------------------------------------------

class AparatInfo {
  const AparatInfo({this.title, this.coverUrl, this.duration});

  final String? title;
  final String? coverUrl;
  final String? duration;
}

class AparatInfoLoader {
  AparatInfoLoader._();

  static final Map<String, AparatInfo?> _cache = {};

  static Future<AparatInfo?> fetch(String hash) async {
    if (_cache.containsKey(hash)) return _cache[hash];

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('https://www.aparat.com/etc/api/video/videohash/$hash'),
      );
      request.headers.set('User-Agent', 'Mozilla/5.0 (Android; CyrusTourist App)');
      final response = await request.close();
      if (response.statusCode != 200) {
        _cache[hash] = null;
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final video =
          decoded is Map ? decoded['video'] as Map<String, dynamic>? : null;
      if (video == null) {
        _cache[hash] = null;
        return null;
      }
      final info = AparatInfo(
        title: video['title']?.toString(),
        coverUrl:
            video['big_poster'] as String? ?? video['small_poster'] as String?,
        duration: video['duration']?.toString(),
      );
      _cache[hash] = info;
      return info;
    } catch (_) {
      _cache[hash] = null;
      return null;
    } finally {
      client?.close();
    }
  }
}
