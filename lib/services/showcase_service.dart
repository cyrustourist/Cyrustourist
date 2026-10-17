import 'dart:convert';
import 'dart:io';

import 'safe_prefs.dart';

import '../models/agency.dart';
import '../models/leader.dart';
import '../models/showcase_item.dart';
import '../models/stay_details.dart';
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

  /// نسخه‌ی کامل: داده‌ی پنل (در صورت وجود) بالا + فایل‌های داخل اپ پایین.
  /// (مثلاً برای لینک‌های عمیق). صفحه‌ی گالری از [localOnly] / [loadCached] /
  /// [loadRemote] استفاده می‌کند تا هرگز منتظر سرور نماند.
  static Future<ShowcaseLoad> load(ShowcaseKind kind,
      {String lang = 'fa'}) async {
    final remote = await loadRemote(kind);
    return merge(kind, remote, localItems(kind));
  }

  /// فوری و بدون شبکه: فقط فایل‌های داخل نرم‌افزار.
  static ShowcaseLoad localOnly(ShowcaseKind kind) =>
      ShowcaseLoad(items: localItems(kind));

  /// تقریباً فوری: آخرین داده‌ی موفقِ پنل که روی گوشی ذخیره شده (بدون شبکه).
  static Future<ShowcaseLoad?> loadCached(ShowcaseKind kind) async {
    if (_endpointFor(kind) == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('showcase_cache_${kind.apiName}');
      if (cached == null || cached.isEmpty) return null;
      final parsed = _parse(kind, jsonDecode(cached), ShowcaseSource.cache);
      return parsed.items.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  /// دریافت از پنل مدیریت. اگر سرور جواب نداد (شبکه/خطا) `null` برمی‌گردد
  /// تا صفحه همان فایل‌های داخل اپ را نگه دارد. اگر سرور جواب سالم داد ولی
  /// فهرست خالی بود، فهرست خالیِ معتبر برمی‌گردد (مثلاً همه‌ی لیدرها غیرفعال شده‌اند).
  static Future<ShowcaseLoad?> loadRemote(ShowcaseKind kind) async {
    final endpoint = _endpointFor(kind);
    if (endpoint == null) return null;

    final cacheKey = 'showcase_cache_${kind.apiName}';
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    ShowcaseLoad? emptyOk;
    for (final base in _basesFor(kind)) {
      try {
        final json = await ApiService.getJson(endpoint, baseUrl: base);
        if (json is Map && json['success'] == false) continue;
        final parsed = _parse(kind, json, ShowcaseSource.server);
        if (parsed.items.isNotEmpty) {
          // عکس‌های base64 حجیم‌اند؛ کش خیلی بزرگ گوشی را کند می‌کند.
          final text = jsonEncode(json);
          if (text.length < 1500 * 1024) {
            await prefs?.setString(cacheKey, text);
          }
          return parsed;
        }
        if (_isValidList(json)) emptyOk ??= parsed; // سالم ولی خالی
      } catch (_) {}
    }
    if (emptyOk != null) {
      await prefs?.remove(cacheKey); // پنل سالم است ولی چیزی ندارد
      return emptyOk;
    }
    return null;
  }

  static bool _isValidList(dynamic d) {
    if (d is List) return true;
    if (d is Map) {
      return d['items'] is List ||
          d['data'] is List ||
          d['results'] is List ||
          d['guides'] is List;
    }
    return false;
  }

  /// ادغام: ردیف‌های بالا = پنل مدیریت (به ترتیب اولویتِ پنل)،
  /// ردیف‌های پایین = فایل‌های داخل نرم‌افزار (بدون تکرار).
  static ShowcaseLoad merge(
      ShowcaseKind kind, ShowcaseLoad? remote, List<ShowcaseItem> local) {
    if (remote == null || remote.items.isEmpty) {
      return ShowcaseLoad(
        items: local,
        filters: remote?.filters,
        source: remote?.source ?? ShowcaseSource.local,
      );
    }
    final serverItems = remote.items;
    final serverIds = serverItems.map((e) => e.id).toSet();
    final serverVideos = <String>{
      for (final e in serverItems)
        if ((e.videoUrl ?? '').isNotEmpty) e.videoUrl!.trim(),
    };
    final serverTitles = <String>{
      for (final e in serverItems)
        if (e.title('fa').trim().isNotEmpty) e.title('fa').trim(),
    };

    var base = local;
    // اگر کدِ یکی از موارد داخلی با کد پنل یکی بود، کدها جابه‌جا می‌شوند
    // تا قلب علاقه‌مندی/باز کردن جزئیات قاطی نشود.
    if (base.any((e) => e.kind == kind && serverIds.contains(e.id))) {
      base = localItems(kind, codeShift: 100000);
    }
    final extras = base.where((e) {
      final v = (e.videoUrl ?? '').trim();
      if (v.isNotEmpty && serverVideos.contains(v)) return false;
      final t = e.title('fa').trim();
      if (t.isNotEmpty && serverTitles.contains(t)) return false;
      return true;
    }).toList();

    return ShowcaseLoad(
      items: [...serverItems, ...extras],
      filters: remote.filters,
      source: remote.source,
    );
  }

  static List<String?> _basesFor(ShowcaseKind kind) {
    // اقامتگاه و گردشگری سلامت هر دو از دیتابیس Worker پنل مدیریت خوانده می‌شوند.
    if (kind == ShowcaseKind.accommodation ||
        kind == ShowcaseKind.health ||
        kind == ShowcaseKind.agency) {
      return [ApiConfig.panelBaseUrl, null];
    }
    // لیدرها فقط در دیتابیس پنل هستند (/guides)؛ جاذبه‌ها هم اول از پنل.
    if (kind == ShowcaseKind.leader) return [ApiConfig.panelBaseUrl];
    if (kind == ShowcaseKind.attraction) {
      return [ApiConfig.panelBaseUrl, null];
    }
    // فیلم‌ها: داده‌ی کامل (تلفن‌ها، شبکه‌ها، مسیر، مختصات، امکانات) فقط در
    // Worker پنل ساخته می‌شود؛ Worker قدیمی ردیف خام و ناقص می‌دهد.
    if (kind == ShowcaseKind.video) {
      return [ApiConfig.panelBaseUrl, null];
    }
    return [null];
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
        return '/guides'; // فقط لیدرهای Active از دیتابیس پنل
      case ShowcaseKind.agency:
        return '/travel-agencies'; // آژانس‌های ثبت‌شده در پنل مدیریت (جدول travel_agencies)
    }
  }

  static ShowcaseLoad _parse(
      ShowcaseKind kind, dynamic decoded, ShowcaseSource source) {
    final items = <ShowcaseItem>[];
    List<dynamic> rawItems = const [];

    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map) {
      final raw = decoded['items'] ??
          decoded['data'] ??
          decoded['results'] ??
          decoded['guides'];
      if (raw is List) rawItems = raw;
    }

    var index = -1;
    for (final raw in rawItems) {
      index++;
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      // ترتیب پنل برای لیدرها حفظ شود (بالاتر در پاسخ = بالاتر در لیست)
      if (kind == ShowcaseKind.leader && row['priority'] == null) {
        row['priority'] = rawItems.length - index;
      }
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
    // اولین مقدار غیرخالی (ستون خالی دیتابیس '' است، نه null)
    String? p(List<dynamic> vs) {
      for (final v in vs) {
        final t = v?.toString().trim() ?? '';
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    double? d(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int code() {
      final direct = int.tryParse((j['id'] ?? j['code'] ?? '').toString());
      if (direct != null) return direct;
      // لیدرها: guide_id مثل GUIDE-00012
      final digits =
          RegExp(r'(\d+)\s*$').firstMatch((j['guide_id'] ?? '').toString());
      return int.tryParse(digits?.group(1) ?? '') ?? 0;
    }

    // آژانس مسافرتی: ردیف پنل → مدل Agency (برای صفحهٔ پروفایل آژانس)
    if (kind == ShowcaseKind.agency) {
      final a = Agency.fromRow(j);
      final item = _fromAgency(code(), a);
      return ShowcaseItem(
        kind: ShowcaseKind.agency,
        code: item.code,
        titles: item.titles,
        locations: _m(a.city, s(j['city_en']), s(j['city_ar'])),
        descriptions: _m(a.bio.isNotEmpty ? a.bio : a.services,
            s(j['description_en']), s(j['description_ar'])),
        categoryLabels: item.categoryLabels,
        categories: item.categories,
        coverUrl: a.logoUrl,
        videoUrl: cleanVideoUrl(a.introVideoUrl),
        phone: a.phone,
        instagramUrl: p([j['instagram_url']]),
        websiteUrl: a.website,
        latitude: d(j['latitude']),
        longitude: d(j['longitude']),
        rating: a.rating,
        ratingCount: a.reviewCount,
        tier: showcaseTierFromString(s(j['tier'])),
        priority: int.tryParse((j['priority'] ?? 0).toString()) ?? 0,
        expiresAt: DateTime.tryParse(j['expires_at']?.toString() ?? ''),
        native: a,
      );
    }

    final isLeader = kind == ShowcaseKind.leader;
    final amenityKeys = <String>{};
    if (isLeader) {
      try {
        final raw = j['amenities'];
        final list = raw is List ? raw : jsonDecode(raw?.toString() ?? '[]');
        if (list is List) amenityKeys.addAll(list.map((e) => e.toString()));
      } catch (_) {}
    }

    final isHealth = kind == ShowcaseKind.health;
    final isStay = kind == ShowcaseKind.accommodation || isHealth;
    final stay = isStay ? StayDetails.fromRow(j, health: isHealth) : null;

    final fullName =
        '${j['first_name'] ?? ''} ${j['last_name'] ?? ''}'.trim();
    final fa = p([j['name_fa'], j['title_fa'], j['title'], j['name'], fullName]);
    final en = p([j['name_en'], j['title_en']]);
    final ar = p([j['name_ar'], j['title_ar']]);

    // مکان: «شهر، استان» (اگر ستون province پر باشد) — مثل نمونه‌ی داخل اپ
    String? joinPlace(String? city, String? province) {
      final parts = [city, province]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('، ');
    }

    final cityFa = joinPlace(
        p([j['city_name'], j['city_fa'], j['city']]), p([j['province'], j['province_fa']]));
    final cityEn = joinPlace(s(j['city_en']), s(j['province_en']));
    final cityAr = joinPlace(s(j['city_ar']), s(j['province_ar']));

    final descFa = p([j['description_full'], j['description_fa'], j['message'], j['bio']]);
    final descEn = s(j['description_en']);
    final descAr = s(j['description_ar']);

    // دسته: برای اقامتگاه از «نوع اقامتگاه» می‌آید (هتل، بوم‌گردی، ...)
    final typeLabels = stay?.typeLabels ?? const <String, String>{};
    final hasType = typeLabels.isNotEmpty;
    final catFa = hasType
        ? typeLabels['fa']
        : p([j['category_fa'], j['category'], j['specialty']]);
    final catEn = hasType ? typeLabels['en'] : s(j['category_en']);
    final catAr = hasType ? typeLabels['ar'] : s(j['category_ar']);

    final tier = s(j['tier']);
    final rating = d(j['rating'] ?? j['average_rating']);
    final ratingCount = int.tryParse((j['rating_count'] ?? 0).toString());

    // شماره‌ی اصلی: همراه ← ثابت ← کمکی
    final stayPhones = stay?.phones ?? const <String>[];
    final mainPhone = isStay
        ? (stayPhones.isNotEmpty ? stayPhones.first : null)
        : p([j['phone_primary'], j['phone_mobile'], j['mobile'], j['phone'], j['mobile_phone']]);
    final typeKey = stay?.typeKey ?? '';

    return ShowcaseItem(
      kind: kind,
      code: code(),
      titles: _m(fa, en, ar),
      locations: _m(cityFa, cityEn, cityAr),
      descriptions: _m(descFa, descEn, descAr),
      categoryLabels: _m(catFa, catEn, catAr),
      categories: typeKey.isNotEmpty
          ? [typeKey]
          : (isLeader
              ? [
                  if (_asInt0(j['is_local_guide']) == 1 ||
                      amenityKeys.contains('local'))
                    'local',
                  if ('${j['license_status']}' == 'Licensed' ||
                      amenityKeys.contains('licensed'))
                    'licensed',
                  if (amenityKeys.contains('nature_tours')) 'nature',
                  if (amenityKeys.contains('historical_tours')) 'historic',
                ]
              : const []),
      videoUrl: cleanVideoUrl(p([j['videoEmbedUrl'], j['video_url'], j['video']])),
      coverUrl: (isLeader
              ? p([
                  j['profile_photo_url'],
                  j['owner_profile_photo'],
                  j['image_url'],
                ])
              : null) ??
          p([j['image_url'], j['image'], j['cover_url']]) ??
          // فقط «عکس پروفایل» ثبت می‌شود؛ اگر فیلم نبود همان کاور کارت است
          (isStay &&
                  aparatHashFromAny(
                          p([j['videoEmbedUrl'], j['video_url'], j['video']])) ==
                      null
              ? stay?.ownerPhoto
              : null),
      phone: mainPhone,
      instagramUrl: p([j['instagram_url'], j['instagram']]),
      websiteUrl: p([j['website_url'], j['website']]),
      latitude: d(j['latitude'] ?? j['lat']),
      longitude: d(j['longitude'] ?? j['lng']),
      rating: rating,
      ratingCount: ratingCount,
      tier: showcaseTierFromString(tier),
      priority: int.tryParse((j['priority'] ?? 0).toString()) ?? 0,
      expiresAt: DateTime.tryParse(j['expires_at']?.toString() ?? ''),
      native: j,
      stay: stay,
    );
  }

  // ------------------------------------------------------------
  // داده‌های محلی (تا زمان اتصال دیتابیس)
  // ------------------------------------------------------------

  static List<ShowcaseItem> localItems(ShowcaseKind kind, {int codeShift = 0}) {
    switch (kind) {
      case ShowcaseKind.video:
      case ShowcaseKind.attraction:
        // فعلاً هر دو از همین لینک فیلم‌های موجود ساخته می‌شوند.
        return kMovieSlots
            .where((s) => s.assigned)
            .map((s) => _fromMovie(kind, s, codeShift))
            .toList();

      case ShowcaseKind.accommodation:
        return kResidenceSlots
            .where((s) => s.assigned)
            .map((s) => _fromResidence(s, codeShift))
            .toList();

      case ShowcaseKind.health:
        return const [];

      case ShowcaseKind.leader:
        var code = codeShift;
        return approvedLeaders.map((l) => _fromLeader(++code, l)).toList();

      case ShowcaseKind.agency:
        var code = codeShift;
        return approvedAgencies.map((a) => _fromAgency(++code, a)).toList();
    }
  }

  static int _asInt0(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

  static Map<String, String> _m(String? fa, [String? en, String? ar]) {
    final out = <String, String>{};
    if (fa != null && fa.isNotEmpty) out['fa'] = fa;
    if (en != null && en.isNotEmpty) out['en'] = en;
    if (ar != null && ar.isNotEmpty) out['ar'] = ar;
    return out;
  }

  static ShowcaseItem _fromMovie(ShowcaseKind kind, MovieSlotData s,
      [int codeShift = 0]) {
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
      code: s.code + codeShift,
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

  static ShowcaseItem _fromResidence(ResidenceVideoData s,
      [int codeShift = 0]) {
    String join(String? a, String? b) => [a, b]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join('، ');

    final hash = s.aparatHash;
    return ShowcaseItem(
      kind: ShowcaseKind.accommodation,
      code: s.code + codeShift,
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
