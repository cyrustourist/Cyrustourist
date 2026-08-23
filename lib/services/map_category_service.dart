import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import 'map_places_service.dart';


class MapCategoryService {
  final MapPlacesService _placesService =
      MapPlacesService();


  // =========================================================
  // گردشگری سلامت - کلید شماره ۲
  // =========================================================

  Future<List<MapPlace>> getHealthPlaces({
    required LatLng userLocation,
  }) async {
    final places =
        await _placesService.searchPlaces(
      query:
          'hospital clinic medical center pharmacy',
      userLocation: userLocation,
      category: PlaceCategory.health,
    );

    return _sortNearest(
      places,
      userLocation,
    );
  }



  // =========================================================
  // جاذبه های گردشگری - کلید شماره ۳
  // =========================================================

  Future<List<MapPlace>> getTourismAttractions({
    required LatLng userLocation,
  }) async {
    final places =
        await _placesService.searchPlaces(
      query:
          'tourism attraction museum park landmark',
      userLocation: userLocation,
      category: PlaceCategory.attraction,
    );

    return _sortNearest(
      places,
      userLocation,
    );
  }



  // =========================================================
  // اماکن گردشگری و اقامت - کلید شماره ۵
  // =========================================================

  Future<List<MapPlace>> getTourismAccommodation({
    required LatLng userLocation,
  }) async {
    final places =
        await _placesService.searchPlaces(
      query:
          'hotel eco lodge guest house resort cottage',
      userLocation: userLocation,
      category: PlaceCategory.accommodation,
    );

    return _sortNearest(
      places,
      userLocation,
    );
  }



  // =========================================================
  // غذا و رستوران
  // =========================================================

  Future<List<MapPlace>> getFoodPlaces({
    required LatLng userLocation,
  }) async {
    final places =
        await _placesService.searchPlaces(
      query:
          'restaurant cafe food',
      userLocation: userLocation,
      category: PlaceCategory.restaurant,
    );

    return _sortNearest(
      places,
      userLocation,
    );
  }



  // =========================================================
  // مرتب سازی نزدیک ترین مکان ها
  // =========================================================

  List<MapPlace> _sortNearest(
    List<MapPlace> places,
    LatLng userLocation,
  ) {
    return _placesService.nearestPlaces(
      places,
      userLocation,
    );
  }



  // =========================================================
  // رنگ مکان نما روی نقشه
  // =========================================================

  int getMarkerColor(
    PlaceCategory category,
  ) {
    switch (category) {

      case PlaceCategory.health:
        return 0xffE53935; // قرمز سلامت

      case PlaceCategory.attraction:
        return 0xff43A047; // سبز گردشگری

      case PlaceCategory.accommodation:
        return 0xffFB8C00; // نارنجی اقامت

      case PlaceCategory.restaurant:
        return 0xff8E24AA; // بنفش غذا

      default:
        return 0xff1976D2; // آبی عمومی
    }
  }



  // =========================================================
  // عنوان دسته برای نمایش کاربر
  // =========================================================

  String categoryTitle(
    PlaceCategory category,
  ) {
    switch (category) {

      case PlaceCategory.health:
        return 'گردشگری سلامت';

      case PlaceCategory.attraction:
        return 'جاذبه گردشگری';

      case PlaceCategory.accommodation:
        return 'اقامتگاه و هتل';

      case PlaceCategory.restaurant:
        return 'رستوران و کافه';

      default:
        return 'مکان گردشگری';
    }
  }
}
