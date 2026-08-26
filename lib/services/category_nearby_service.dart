import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import '../pages/map/map_places_service.dart' as remote;

/// پل بین موتور جستجوی واقعی نقشه (Overpass + Nominatim)
/// که در lib/pages/map/map_places_service.dart آماده بود
/// و مدل مشترک MapPlace که در کل برنامه (کارت‌ها، جزئیات،
/// علاقه‌مندی‌ها) استفاده می‌شود.
///
/// برای کلیدهای ۲ (سلامت)، ۳ (جاذبه‌ها) و ۵ (اقامتگاه) استفاده می‌شود.
/// هیچ مختصات یا اطلاعات جعلی تولید نمی‌کند؛ همه نتایج از
/// OpenStreetMap دریافت می‌شوند.
class CategoryNearbyService {
  const CategoryNearbyService._();

  static const CategoryNearbyService instance =
      CategoryNearbyService._();

  static const Distance _distance = Distance();

  remote.MapPlaceType _typeFor(
    PlaceCategory category,
  ) {
    switch (category) {
      case PlaceCategory.health:
        return remote.MapPlaceType.healthTourism;

      case PlaceCategory.accommodation:
        return remote.MapPlaceType.accommodation;

      case PlaceCategory.attraction:
      default:
        return remote.MapPlaceType.touristAttraction;
    }
  }

  /// دریافت مکان‌های یک دسته، اطراف یک نقطه مشخص
  /// (می‌تواند موقعیت GPS کاربر یا نتیجه یک جستجو باشد)
  Future<List<MapPlace>> nearby({
    required PlaceCategory category,
    required LatLng center,
    double radiusMeters = 15000,
    String language = 'fa',
  }) async {
    final results =
        await remote.MapPlacesService.instance.searchNearby(
      center: center,
      type: _typeFor(category),
      radiusMeters: radiusMeters,
      language: language,
    );

    final places = results.map((item) {
      return MapPlace(
        id: item.id,
        name: item.name,
        location: item.point,
        category: category,
        address: item.address,
        phone: item.phone,
        website: item.website,
        distanceMeters: _distance.as(
          LengthUnit.Meter,
          center,
          item.point,
        ),
        source: 'openstreetmap',
      );
    }).toList();

    places.sort(
      (a, b) => (a.distanceMeters ?? 0)
          .compareTo(b.distanceMeters ?? 0),
    );

    return places;
  }

  /// جستجوی نام یک شهر یا نام یک مکان/جاذبه، فقط برای
  /// پیدا کردن مختصات واقعی آن و مرکز کردن نقشه روی آن.
  Future<List<SearchedLocation>> searchPlaceOrCity(
    String query, {
    String language = 'fa',
  }) async {
    final results =
        await remote.MapPlacesService.instance.searchCity(
      query,
      language: language,
    );

    return results
        .map(
          (item) => SearchedLocation(
            name: item.name,
            point: item.point,
          ),
        )
        .toList();
  }
}

/// نتیجه جستجوی شهر یا مکان، فقط شامل نام و مختصات.
class SearchedLocation {
  final String name;
  final LatLng point;

  const SearchedLocation({
    required this.name,
    required this.point,
  });
}
