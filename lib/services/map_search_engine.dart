import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import 'map_places_service.dart';
import 'map_distance_filter.dart';

class MapSearchEngine {
  final MapPlacesService placesService;

  MapSearchEngine({
    required this.placesService,
  });

  /// جستجوی هوشمند برای کلیدهای نقشه
  ///
  /// category:
  /// health = سلامت
  /// attraction = جاذبه گردشگری
  /// accommodation = اقامتگاه
  ///

  Future<List<MapPlace>> searchNearby({
    required LatLng userLocation,
    required PlaceCategory category,
    required int radiusKm,
    String language = 'fa',
  }) async {
    final query = _categoryQuery(category);

    final results =
        await placesService.searchPlaces(
      query: query,
      userLocation: userLocation,
      category: category,
      language: language,
    );

    final filtered =
        MapDistanceFilter.filter(
      places: results,
      center: userLocation,
      radiusKm: radiusKm,
    );

    return filtered;
  }


  /// جستجوی عمومی هوشمند
  Future<List<MapPlace>> smartSearch({
    required String text,
    required LatLng userLocation,
    required int radiusKm,
    String language = 'fa',
  }) async {

    final results =
        await placesService.searchPlaces(
      query: text,
      userLocation: userLocation,
      language: language,
    );


    return MapDistanceFilter.filter(
      places: results,
      center: userLocation,
      radiusKm: radiusKm,
    );
  }



  String _categoryQuery(
    PlaceCategory category,
  ) {

    switch(category) {

      case PlaceCategory.health:
        return '''
        hospital clinic medical center pharmacy درمانگاه بیمارستان
        داروخانه پزشک
        ''';


      case PlaceCategory.attraction:
        return '''
        tourist attraction museum park historical place
        جاذبه گردشگری موزه پارک مکان تاریخی
        ''';


      case PlaceCategory.accommodation:
        return '''
        hotel resort guesthouse eco lodge
        هتل اقامتگاه بوم گردی کلبه
        ''';


      case PlaceCategory.restaurant:
        return '''
        restaurant cafe food
        رستوران کافه غذا
        ''';


      case PlaceCategory.other:
        return 'tourism';
    }
  }


  /// پیشنهاد نزدیک‌ترین مکان‌ها
  List<MapPlace> nearest(
    List<MapPlace> places,
  ) {

    final copy =
        List<MapPlace>.from(
      places,
    );


    copy.sort(
      (a,b) =>
          (a.distanceMeters ?? 0)
          .compareTo(
            b.distanceMeters ?? 0,
          ),
    );


    return copy;
  }
}
