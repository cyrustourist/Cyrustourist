import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:latlong2/latlong.dart';

import '../../services/json_disk_cache.dart';

/// نوع اطلاعاتی که از نقشه درخواست می‌شود.
enum MapPlaceType {
  healthTourism,
  touristAttraction,
  accommodation,

  // ============================================================
  // خدمات سریع کلید ۱ (نقشه) — کاملاً مستقل از کلید ۲، ۳ و ۵
  // ============================================================
  fuel,
  atm,
  restaurant,
  parking,
  restroom,
  police,
  market,
  carService,
  simCard,

  // ============================================================
  // کلید ۹ (جستجوی هوشمند) — دسته‌های اختصاصی که در خدمات سریع
  // کلید ۱ وجود نداشتند
  // ============================================================
  cafe,
  historicalSite,
  natureSite,
}

/// سرویس مرکزی اطلاعات مکان‌های گردشگری.
///
/// کلیدهای اصلی:
/// 2 = گردشگری سلامت
/// 3 = جاذبه‌های گردشگری
/// 5 = اقامتگاه
///
/// این فایل عمداً از UI و SmartMapPage جداست تا در مراحل بعد
/// بتوانیم منبع داده، فیلترها و نمایش نتایج را بدون سنگین کردن
/// smart_map_page.dart توسعه دهیم.
class MapPlacesService {
  MapPlacesService._();

  static final MapPlacesService instance =
    MapPlacesService._();

  static const String _userAgent =
      'CyrusTourist/1.0 (cyrustourist.ir)';

  static const String _nominatimHost =
      'nominatim.openstreetmap.org';

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// دریافت مکان‌های گردشگری سلامت
  /// در محدوده یک نقطه.
  Future<List<MapPlace>> searchHealthTourism({
    required LatLng center,
    double radiusMeters = 15000,
    String language = 'fa',
  }) {
    return searchNearby(
      center: center,
      type: MapPlaceType.healthTourism,
      radiusMeters: radiusMeters,
      language: language,
    );
  }

  /// دریافت جاذبه‌های گردشگری
  /// در محدوده یک نقطه.
  Future<List<MapPlace>> searchTouristAttractions({
    required LatLng center,
    double radiusMeters = 20000,
    String language = 'fa',
  }) {
    return searchNearby(
      center: center,
      type: MapPlaceType.touristAttraction,
      radiusMeters: radiusMeters,
      language: language,
    );
  }

  /// دریافت اقامتگاه‌ها
  /// در محدوده یک نقطه.
  Future<List<MapPlace>> searchAccommodations({
    required LatLng center,
    double radiusMeters = 15000,
    String language = 'fa',
  }) {
    return searchNearby(
      center: center,
      type: MapPlaceType.accommodation,
      radiusMeters: radiusMeters,
      language: language,
    );
  }

  /// جستجوی عمومی مکان‌های اطراف.
  Future<List<MapPlace>> searchNearby({
    required LatLng center,
    required MapPlaceType type,
    double radiusMeters = 15000,
    String language = 'fa',
  }) async {
    // کش کوتاه‌مدت: تکرار همان جستجو (همان دسته، همان محدوده) فوری جواب می‌دهد.
    final cacheKey =
        '${type.name}|${center.latitude.toStringAsFixed(2)}|'
        '${center.longitude.toStringAsFixed(2)}|'
        '${radiusMeters.round()}|$language';

    final cached = _nearbyCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.time) < _cacheTtl) {
      return cached.places;
    }

    // ۱) کش دیسکی (فوری، بدون اینترنت): تا ۲۴ ساعت مستقیم استفاده می‌شود؛
    //    اگر از ۱۵ دقیقه قدیمی‌تر بود، در پس‌زمینه از OpenStreetMap تازه می‌شود.
    final diskKey = 'ov|$cacheKey';
    final disk = await JsonDiskCache.read(diskKey);
    List<MapPlace>? diskPlaces;
    if (disk != null) {
      diskPlaces = _parseCachedOverpass(disk.body, type, language);
      if (diskPlaces != null && diskPlaces.isNotEmpty && disk.age < const Duration(hours: 24)) {
        _putNearbyCache(cacheKey, diskPlaces, disk.time);
        if (disk.age > _cacheTtl) {
          unawaited(_refreshNearby(cacheKey, diskKey, center, type, radiusMeters, language));
        }
        return diskPlaces;
      }
    }

    // ۲) OpenStreetMap (Overpass)
    try {
      final places = await _fetchNearby(cacheKey, diskKey, center, type, radiusMeters, language);
      return places;
    } catch (_) {
      // اگر همه سرورها جواب ندادند، آخرین نتیجه ذخیره‌شده (هر چقدر قدیمی) نشان داده شود.
      if (cached != null && cached.places.isNotEmpty) {
        return cached.places;
      }
      if (diskPlaces != null && diskPlaces.isNotEmpty) {
        return diskPlaces;
      }
      rethrow;
    }
  }

  final Set<String> _refreshing = {};

  void _putNearbyCache(String key, List<MapPlace> places, DateTime time) {
    if (_nearbyCache.length > 40) {
      _nearbyCache.remove(_nearbyCache.keys.first);
    }
    _nearbyCache[key] = _NearbyCacheEntry(places, time);
  }

  List<MapPlace>? _parseCachedOverpass(String body, MapPlaceType type, String language) {
    try {
      return _parseOverpassResults(jsonDecode(body), type, language);
    } catch (_) {
      return null;
    }
  }

  Future<List<MapPlace>> _fetchNearby(
    String cacheKey,
    String diskKey,
    LatLng center,
    MapPlaceType type,
    double radiusMeters,
    String language,
  ) async {
    final query = _buildOverpassQuery(
      center: center,
      radiusMeters: radiusMeters,
      tags: _buildTags(type),
    );

    final data = await _requestOverpassWithRetry(query);
    final places = _parseOverpassResults(data, type, language);

    if (places.isNotEmpty) {
      _putNearbyCache(cacheKey, places, DateTime.now());
      try {
        unawaited(JsonDiskCache.write(diskKey, jsonEncode(data)));
      } catch (_) {}
    }

    return places;
  }

  Future<void> _refreshNearby(
    String cacheKey,
    String diskKey,
    LatLng center,
    MapPlaceType type,
    double radiusMeters,
    String language,
  ) async {
    if (!_refreshing.add(cacheKey)) return;
    try {
      await _fetchNearby(cacheKey, diskKey, center, type, radiusMeters, language);
    } catch (_) {
    } finally {
      _refreshing.remove(cacheKey);
    }
  }

  static const Duration _cacheTtl = Duration(minutes: 15);

  final Map<String, _NearbyCacheEntry> _nearbyCache = {};

  /// جستجوی یک شهر از طریق Nominatim.
  ///
  /// این متد فقط مختصات شهر را پیدا می‌کند.
  /// سپس می‌توان همان مختصات را به searchNearby داد.
  Future<List<MapPlaceCity>> searchCity(
    String city, {
    String language = 'fa',
    int limit = 8,
  }) async {
    final cleanCity = city.trim();

    if (cleanCity.length < 2) {
      return [];
    }

    // کش خودکار: همان جستجو قبلاً انجام شده بود ← فوری (تا ۳۰ روز)؛ اگر از یک روز قدیمی‌تر بود در پس‌زمینه تازه می‌شود
    final cityKey = 'nm|${_languageCode(language)}|$limit|${cleanCity.toLowerCase()}';
    final cityHit = await JsonDiskCache.read(cityKey);
    if (cityHit != null && cityHit.age < const Duration(days: 30)) {
      final parsed = _parseCities(cityHit.body, cleanCity);
      if (parsed.isNotEmpty) {
        if (cityHit.age > const Duration(days: 1)) {
          unawaited(_fetchCityBody(cleanCity, language, limit, cityKey).catchError((Object _) {}));
        }
        return parsed;
      }
    }

    try {
      final body = await _fetchCityBody(cleanCity, language, limit, cityKey);
      return _parseCities(body, cleanCity);
    } catch (_) {
      if (cityHit != null) {
        final parsed = _parseCities(cityHit.body, cleanCity);
        if (parsed.isNotEmpty) return parsed;
      }
      rethrow;
    }
  }

  Future<String> _fetchCityBody(String cleanCity, String language, int limit, String cityKey) async {
    final uri = Uri.https(
      _nominatimHost,
      '/search',
      {
        'q': cleanCity,
        'format': 'jsonv2',
        'limit': '$limit',
        'addressdetails': '1',
        'accept-language': _languageCode(language),
      },
    );

    final client = HttpClient();

    try {
      client.userAgent = _userAgent;

      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 10));

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request
          .close()
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Nominatim HTTP ${response.statusCode}',
        );
      }

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(body);
      if (decoded is List) {
        unawaited(JsonDiskCache.write(cityKey, body));
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }

  List<MapPlaceCity> _parseCities(String body, String cleanCity) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return [];
    }
    if (decoded is! List) return [];

    final cities = <MapPlaceCity>[];
    for (final item in decoded) {
      if (item is! Map) continue;

      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      cities.add(
        MapPlaceCity(
          name: item['display_name']?.toString() ?? cleanCity,
          point: LatLng(lat, lon),
          placeId: item['place_id']?.toString(),
          osmType: item['osm_type']?.toString(),
          osmId: item['osm_id']?.toString(),
        ),
      );
    }
    return cities;
  }

  // ============================================================
  // OVERPASS
  // ============================================================

  List<String> _buildTags(
    MapPlaceType type,
  ) {
    switch (type) {
      case MapPlaceType.healthTourism:
        return const [
          'healthcare',
          'amenity=hospital',
          'amenity=clinic',
          'amenity=doctors',
          'amenity=pharmacy',
          'healthcare=centre',
          'healthcare=clinic',
          'healthcare=hospital',
          'healthcare=doctor',
          'healthcare=alternative',
          'amenity=spa',
        ];

      case MapPlaceType.touristAttraction:
        return const [
          'tourism=attraction',
          'tourism=museum',
          'tourism=gallery',
          'tourism=viewpoint',
          'tourism=artwork',
          'historic=monument',
          'historic=castle',
          'historic=archaeological_site',
          'historic=ruins',
          'historic=memorial',
          'leisure=park',
        ];

      case MapPlaceType.accommodation:
        return const [
          'tourism=hotel',
          'tourism=hostel',
          'tourism=guest_house',
          'tourism=motel',
          'tourism=camp_site',
          'tourism=caravan_site',
          'tourism=chalet',
          'tourism=apartment',
          'tourism=alpine_hut',
        ];

      // ============================================================
      // خدمات سریع کلید ۱ (نقشه)
      // ============================================================

      case MapPlaceType.fuel:
        return const [
          'amenity=fuel',
        ];

      case MapPlaceType.atm:
        return const [
          'amenity=atm',
          'amenity=bank',
        ];

      case MapPlaceType.restaurant:
        return const [
          'amenity=restaurant',
          'amenity=fast_food',
          'amenity=cafe',
        ];

      case MapPlaceType.parking:
        return const [
          'amenity=parking',
        ];

      case MapPlaceType.restroom:
        return const [
          'amenity=toilets',
        ];

      case MapPlaceType.police:
        return const [
          'amenity=police',
        ];

      case MapPlaceType.market:
        return const [
          'shop=supermarket',
          'shop=convenience',
          'shop=mall',
        ];

      case MapPlaceType.carService:
        return const [
          'shop=car_repair',
          'amenity=car_wash',
        ];

      case MapPlaceType.simCard:
        return const [
          'shop=mobile_phone',
          'office=telecommunication',
        ];

      case MapPlaceType.cafe:
        return const [
          'amenity=cafe',
          'amenity=ice_cream',
          'shop=coffee',
          'shop=pastry',
        ];

      case MapPlaceType.historicalSite:
        return const [
          'historic=monument',
          'historic=castle',
          'historic=archaeological_site',
          'historic=ruins',
          'historic=memorial',
          'historic=fort',
          'historic=tomb',
          'tourism=museum',
        ];

      case MapPlaceType.natureSite:
        return const [
          'leisure=park',
          'leisure=nature_reserve',
          'natural=forest',
          'natural=water',
          'natural=peak',
          'natural=beach',
          'tourism=viewpoint',
          'waterway=waterfall',
        ];
    }
  }

  String _buildOverpassQuery({
    required LatLng center,
    required double radiusMeters,
    required List<String> tags,
  }) {
    final lat = center.latitude;
    final lon = center.longitude;

    final latS = lat.toStringAsFixed(5);
    final lonS = lon.toStringAsFixed(5);
    final r = radiusMeters.round();

    // یک عبارت nwr به‌جای دو عبارت node و way، و تگ‌های هم‌کلید در یک
    // عبارت ترکیبی (regex) ادغام می‌شوند؛ مثلاً ۹ جستجوی tourism=... فقط یک
    // جستجو می‌شود ← زمان پردازش روی سرور خیلی کمتر.
    final bareKeys = <String>{};
    final valuesByKey = <String, List<String>>{};

    for (final tag in tags) {
      if (tag.contains('=')) {
        final idx = tag.indexOf('=');
        valuesByKey
            .putIfAbsent(tag.substring(0, idx), () => <String>[])
            .add(tag.substring(idx + 1));
      } else {
        bareKeys.add(tag);
      }
    }

    final parts = <String>[];

    for (final key in bareKeys) {
      parts.add('nwr(around:$r,$latS,$lonS)["$key"];');
    }

    valuesByKey.forEach((key, values) {
      // اگر خود کلید بدون مقدار هم خواسته شده، همه‌ی مقدارها را پوشش می‌دهد.
      if (bareKeys.contains(key)) return;
      final regex = values.map(RegExp.escape).join('|');
      parts.add('nwr(around:$r,$latS,$lonS)["$key"~"^($regex)\$"];');
    });

    return '''
[out:json][timeout:12];
(
${parts.join('\n')}
);
out center tags qt 200;
''';
  }

  /// درخواست هم‌زمان به چند سرور Overpass؛ اولین پاسخ موفق برنده است
  /// (قبلاً سرورها پشت‌سرهم امتحان می‌شدند و انتظار تا ۹۰ ثانیه می‌رسید).
  /// دو دور تلاش (با ۲ ثانیه وقفه) روی همه سرورها؛ همه‌چیز داخل خود اپ است.
  Future<dynamic> _requestOverpassWithRetry(
    String query,
  ) async {
    Object? lastError;

    for (var round = 0; round < 2; round++) {
      try {
        return await _requestOverpass(query);
      } catch (error) {
        lastError = error;
        if (round == 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    throw Exception('Map places service failed: $lastError');
  }

  Future<dynamic> _requestOverpass(
    String query,
  ) async {
    const endpoints = <String>[
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.private.coffee/api/interpreter',
    ];

    final completer = Completer<dynamic>();
    final clients = <HttpClient>[];
    var settled = 0;
    Object? lastError;
    dynamic emptyResult;

    void finishIfDone() {
      if (completer.isCompleted || settled != endpoints.length) return;

      if (emptyResult != null) {
        completer.complete(emptyResult);
      } else {
        completer.completeError(
          Exception('Map places service failed: $lastError'),
        );
      }
    }

    for (final endpoint in endpoints) {
      _fetchOverpass(endpoint, query, clients).then((data) {
        settled++;

        final elements = data is Map ? data['elements'] : null;
        final hasData = elements is List && elements.isNotEmpty;

        if (hasData) {
          // اولین جواب دارای نتیجه برنده است.
          if (!completer.isCompleted) completer.complete(data);
        } else {
          // جواب خالی فقط وقتی استفاده می‌شود که هیچ سرور دیگری نتیجه نداد.
          emptyResult ??= data;
          finishIfDone();
        }
      }).catchError((Object error) {
        settled++;
        lastError = error;
        finishIfDone();
      });
    }

    try {
      return await completer.future;
    } finally {
      for (final client in clients) {
        client.close(force: true);
      }
    }
  }

  Future<dynamic> _fetchOverpass(
    String endpoint,
    String query,
    List<HttpClient> clients,
  ) async {
    final client = HttpClient();
    clients.add(client);

    client.userAgent = _userAgent;
    client.connectionTimeout = const Duration(seconds: 5);

    final request = await client.postUrl(Uri.parse(endpoint));

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded',
    );

    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/json',
    );

    request.write(
      'data=${Uri.encodeQueryComponent(query)}',
    );

    final response = await request.close().timeout(
          const Duration(seconds: 14),
        );

    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception('Overpass HTTP ${response.statusCode}');
    }

    // تبدیل JSON در یک isolate جدا انجام می‌شود تا صفحه (UI) قفل نکند.
    final decoded = await compute(_decodeJson, body);

    // بعضی سرورها با کد 200 ولی با پیام خطا/timeout و فهرست خالی جواب می‌دهند؛
    // اگر آن را «موفق» حساب کنیم، جواب خالی در رقابت سرورها برنده می‌شود.
    if (decoded is Map) {
      final remark = decoded['remark']?.toString().toLowerCase() ?? '';
      final elements = decoded['elements'];
      if (remark.isNotEmpty &&
          (remark.contains('error') || remark.contains('timed out')) &&
          (elements is! List || elements.isEmpty)) {
        throw Exception('Overpass remark: $remark');
      }
    }

    return decoded;
  }

  // ============================================================
  // PARSER
  // ============================================================

  List<MapPlace> _parseOverpassResults(
    dynamic data,
    MapPlaceType type,
    String language,
  ) {
    if (data is! Map) {
      return [];
    }

    final elements = data['elements'];

    if (elements is! List) {
      return [];
    }

    final result = <MapPlace>[];
    final seen = <String>{};

    for (final item in elements) {
      if (item is! Map) {
        continue;
      }

      final id = item['id']?.toString();

      if (id == null) {
        continue;
      }

      final osmType =
          item['type']?.toString() ?? 'node';

      final uniqueId =
          '$osmType:$id';

      if (!seen.add(uniqueId)) {
        continue;
      }

      final tags = <String, String>{};

      final rawTags = item['tags'];

      if (rawTags is Map) {
        rawTags.forEach(
          (key, value) {
            if (key != null && value != null) {
              tags[key.toString()] =
                  value.toString();
            }
          },
        );
      }

      LatLng? point;

      final lat = item['lat'];
      final lon = item['lon'];

      if (lat is num && lon is num) {
        point = LatLng(
          lat.toDouble(),
          lon.toDouble(),
        );
      }

      if (point == null) {
        final center = item['center'];

        if (center is Map) {
          final centerLat = center['lat'];
          final centerLon = center['lon'];

          if (centerLat is num &&
              centerLon is num) {
            point = LatLng(
              centerLat.toDouble(),
              centerLon.toDouble(),
            );
          }
        }
      }

      if (point == null) {
        continue;
      }

      final name =
          _findName(
        tags,
        language,
      );

      if (name.isEmpty) {
        continue;
      }

      result.add(
        MapPlace(
          id: uniqueId,
          name: name,
          point: point,
          type: type,
          tags: tags,
          osmType: osmType,
          osmId: id,
        ),
      );
    }

    return result;
  }

  String _findName(
    Map<String, String> tags,
    String language,
  ) {
    final lang = _languageCode(language);

    final candidates = <String>[
      if (lang.isNotEmpty)
        'name:$lang',
      'name:fa',
      'name:en',
      'name:ar',
      'name',
      'official_name',
      'alt_name',
    ];

    for (final key in candidates) {
      final value = tags[key];

      if (value != null &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  String _languageCode(
    String language,
  ) {
    final clean = language
        .toLowerCase()
        .trim();

    if (clean.startsWith('fa')) {
      return 'fa';
    }

    if (clean.startsWith('ar')) {
      return 'ar';
    }

    return 'en';
  }
}

/// تبدیل JSON در isolate (تابع سطح‌بالا برای compute).
dynamic _decodeJson(String body) => jsonDecode(body);

// ================================================================
// MAP PLACE
// ================================================================

class MapPlace {
  final String id;
  final String name;
  final LatLng point;
  final MapPlaceType type;

  final Map<String, String> tags;

  final String osmType;
  final String osmId;

  const MapPlace({
    required this.id,
    required this.name,
    required this.point,
    required this.type,
    required this.tags,
    required this.osmType,
    required this.osmId,
  });

  String? get address {
    final parts = <String>[
      tags['addr:street'] ?? '',
tags['addr:city'] ?? '',
tags['addr:district'] ?? '',
    ];

    final values = parts
        .whereType<String>()
        .where(
          (value) =>
              value.trim().isNotEmpty,
        )
        .toList();

    if (values.isEmpty) {
      return null;
    }

    return values.join('، ');
  }

  String? get phone {
    return tags['phone'] ??
        tags['contact:phone'];
  }

  String? get website {
    return tags['website'] ??
        tags['contact:website'];
  }

  String? get openingHours {
    return tags['opening_hours'];
  }

  String? get category {
    switch (type) {
      case MapPlaceType.healthTourism:
        return 'health';

      case MapPlaceType.touristAttraction:
        return 'attraction';

      case MapPlaceType.accommodation:
        return 'accommodation';

      case MapPlaceType.fuel:
        return 'fuel';

      case MapPlaceType.atm:
        return 'atm';

      case MapPlaceType.restaurant:
        return 'restaurant';

      case MapPlaceType.parking:
        return 'parking';

      case MapPlaceType.restroom:
        return 'restroom';

      case MapPlaceType.police:
        return 'police';

      case MapPlaceType.market:
        return 'market';

      case MapPlaceType.carService:
        return 'car_service';

      case MapPlaceType.simCard:
        return 'sim_card';

      case MapPlaceType.cafe:
        return 'cafe';

      case MapPlaceType.historicalSite:
        return 'historical';

      case MapPlaceType.natureSite:
        return 'nature';
    }
  }
}

// ================================================================
// CITY RESULT
// ================================================================

class MapPlaceCity {
  final String name;
  final LatLng point;

  final String? placeId;
  final String? osmType;
  final String? osmId;

  const MapPlaceCity({
    required this.name,
    required this.point,
    this.placeId,
    this.osmType,
    this.osmId,
  });
}

class _NearbyCacheEntry {
  const _NearbyCacheEntry(this.places, this.time);

  final List<MapPlace> places;
  final DateTime time;
}
