import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

/// نوع اطلاعاتی که از نقشه درخواست می‌شود.
enum MapPlaceType {
  healthTourism,
  touristAttraction,
  accommodation,
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
    final tags = _buildTags(type);

    final query = _buildOverpassQuery(
      center: center,
      radiusMeters: radiusMeters,
      tags: tags,
    );

    final data = await _requestOverpass(query);

    return _parseOverpassResults(
      data,
      type,
      language,
    );
  }

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

      final request = await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Nominatim HTTP ${response.statusCode}',
        );
      }

      final body = await response
          .transform(utf8.decoder)
          .join();

      final decoded = jsonDecode(body);

      if (decoded is! List) {
        return [];
      }

      final cities = <MapPlaceCity>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        final lat = double.tryParse(
          item['lat']?.toString() ?? '',
        );

        final lon = double.tryParse(
          item['lon']?.toString() ?? '',
        );

        if (lat == null || lon == null) {
          continue;
        }

        cities.add(
          MapPlaceCity(
            name: item['display_name']?.toString() ??
                cleanCity,
            point: LatLng(lat, lon),
            placeId: item['place_id']?.toString(),
            osmType: item['osm_type']?.toString(),
            osmId: item['osm_id']?.toString(),
          ),
        );
      }

      return cities;
    } finally {
      client.close(force: true);
    }
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
    }
  }

  String _buildOverpassQuery({
    required LatLng center,
    required double radiusMeters,
    required List<String> tags,
  }) {
    final lat = center.latitude;
    final lon = center.longitude;

    final nodeParts = <String>[];
    final wayParts = <String>[];
    final relationParts = <String>[];

    for (final tag in tags) {
      final expression = _tagExpression(tag);

      nodeParts.add(
        'node(around:$radiusMeters,$lat,$lon)$expression;',
      );

      wayParts.add(
        'way(around:$radiusMeters,$lat,$lon)$expression;',
      );

      relationParts.add(
        'relation(around:$radiusMeters,$lat,$lon)$expression;',
      );
    }

    return '''
[out:json][timeout:25];

(
${nodeParts.join('\n')}
${wayParts.join('\n')}
${relationParts.join('\n')}
);

out center tags;
''';
  }

  String _tagExpression(String tag) {
    if (tag.contains('=')) {
      final parts = tag.split('=');

      final key = parts.first;
      final value = parts.sublist(1).join('=');

      return '["$key"="$value"]';
    }

    return '["$tag"]';
  }

  Future<dynamic> _requestOverpass(
    String query,
  ) async {
    const endpoints = <String>[
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    Object? lastError;

    for (final endpoint in endpoints) {
      final client = HttpClient();

      try {
        client.userAgent = _userAgent;

        final request = await client.postUrl(
          Uri.parse(endpoint),
        );

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

        final response = await request
            .close()
            .timeout(
              const Duration(seconds: 30),
            );

        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(
              const Duration(seconds: 15),
            );

        if (response.statusCode == HttpStatus.ok) {
          return jsonDecode(body);
        }

        lastError = Exception(
          'Overpass HTTP ${response.statusCode}',
        );
      } catch (error) {
        lastError = error;
      } finally {
        client.close(force: true);
      }
    }

    throw Exception(
      'Map places service failed: $lastError',
    );
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
