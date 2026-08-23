import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

import '../map_place.dart';

class MapPlacesService {
  final Distance _distance = const Distance();

  /// جستجوی عمومی مکان‌ها
  ///
  /// برای:
  /// - بیمارستان
  /// - جاذبه گردشگری
  /// - هتل
  /// - بوم‌گردی
  /// - رستوران
  /// - خدمات گردشگری
  ///
  /// از Nominatim + OpenStreetMap استفاده می‌کند.
  Future<List<MapPlace>> searchPlaces({
    required String query,
    required LatLng userLocation,
    PlaceCategory? category,
    String language = 'fa',
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'limit': '20',
        'addressdetails': '1',
        'accept-language': language,
      },
    );

    final client = HttpClient();

    try {
      client.userAgent =
          'CyrusTourist/1.0 (cyrustourist.ir)';

      final request =
          await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response =
          await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Search failed ${response.statusCode}',
        );
      }

      final body =
          await response
              .transform(
                utf8.decoder,
              )
              .join();

      final data = jsonDecode(body);

      if (data is! List) {
        return [];
      }

      final places = <MapPlace>[];

      for (final item in data) {
        if (item is! Map) continue;

        final lat =
            double.tryParse(
          item['lat']?.toString() ?? '',
        );

        final lon =
            double.tryParse(
          item['lon']?.toString() ?? '',
        );

        if (lat == null || lon == null) {
          continue;
        }

        final point = LatLng(
          lat,
          lon,
        );

        final detectedCategory =
            category ??
                detectCategory(
                  item,
                  query,
                );

        places.add(
          MapPlace(
            id:
                item['place_id']
                    ?.toString() ??
                    '${lat}_$lon',

            name:
                extractName(item),

            description:
                item['display_name']
                    ?.toString(),

            location:
                point,

            category:
                detectedCategory,

            address:
                item['display_name']
                    ?.toString(),

            distanceMeters:
                _distance.as(
              LengthUnit.Meter,
              userLocation,
              point,
            ),

            source:
                'openstreetmap',
          ),
        );
      }

      places.sort(
        (a, b) =>
            (a.distanceMeters ?? 0)
                .compareTo(
              b.distanceMeters ?? 0,
            ),
      );

      return places;
    } finally {
      client.close(force: true);
    }
  }


  /// تشخیص دسته مکان بر اساس اطلاعات دریافت شده
  PlaceCategory detectCategory(
    Map item,
    String query,
  ) {
    final text =
        (
          '${item['display_name']} '
          '${item['type']} '
          '$query'
        )
            .toLowerCase();

    // سلامت
    if (_containsAny(
      text,
      [
        'hospital',
        'clinic',
        'doctor',
        'pharmacy',
        'health',
        'بیمارستان',
        'درمانگاه',
        'داروخانه',
        'پزشک',
      ],
    )) {
      return PlaceCategory.health;
    }


    // اقامت
    if (_containsAny(
      text,
      [
        'hotel',
        'guest',
        'resort',
        'hostel',
        'هتل',
        'اقامت',
        'بوم',
        'کلبه',
      ],
    )) {
      return PlaceCategory.accommodation;
    }


    // رستوران
    if (_containsAny(
      text,
      [
        'restaurant',
        'cafe',
        'food',
        'رستوران',
        'کافه',
        'غذا',
      ],
    )) {
      return PlaceCategory.restaurant;
    }


    // جاذبه
    if (_containsAny(
      text,
      [
        'museum',
        'castle',
        'park',
        'monument',
        'tourism',
        'attraction',
        'موزه',
        'پارک',
        'آثار',
        'جاذبه',
        'گردشگری',
      ],
    )) {
      return PlaceCategory.attraction;
    }


    return PlaceCategory.other;
  }


  /// استخراج نام قابل نمایش
  String extractName(
    Map item,
  ) {
    final display =
        item['display_name']
            ?.toString();

    if (display == null ||
        display.isEmpty) {
      return 'مکان بدون نام';
    }

    return display
        .split(',')
        .first
        .trim();
  }


  bool _containsAny(
    String text,
    List<String> words,
  ) {
    for (final word in words) {
      if (text.contains(
        word.toLowerCase(),
      )) {
        return true;
      }
    }

    return false;
  }


  /// دریافت نزدیک‌ترین مکان‌ها
  List<MapPlace> nearestPlaces(
    List<MapPlace> places,
    LatLng userLocation,
  ) {
    final result =
        List<MapPlace>.from(
      places,
    );

    result.sort(
      (a, b) {
        final da =
            _distance.as(
          LengthUnit.Meter,
          userLocation,
          a.location,
        );

        final db =
            _distance.as(
          LengthUnit.Meter,
          userLocation,
          b.location,
        );

        return da.compareTo(db);
      },
    );

    return result;
  }
}
