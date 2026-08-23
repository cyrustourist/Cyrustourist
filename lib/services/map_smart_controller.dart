import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import 'map_places_service.dart';
import 'map_distance_filter.dart';


class MapSmartController extends ChangeNotifier {

  final MapPlacesService _placesService =
      MapPlacesService();


  LatLng? userLocation;


  List<MapPlace> places = [];


  List<MapPlace> visiblePlaces = [];


  PlaceCategory? activeCategory;


  double searchRadiusKm = 10;


  bool isLoading = false;


  String? errorMessage;



  /// تنظیم موقعیت کاربر
  void setUserLocation(
    LatLng location,
  ) {

    userLocation = location;

    notifyListeners();

  }



  /// تغییر فاصله جستجو
  void setRadius(
    double km,
  ) {

    searchRadiusKm = km;

    _applyFilter();

    notifyListeners();

  }



  /// انتخاب دسته بندی
  void setCategory(
    PlaceCategory? category,
  ) {

    activeCategory = category;

    _applyFilter();

    notifyListeners();

  }



  /// جستجوی مکان‌ها
  Future<void> search({

    required String query,

  }) async {


    if (userLocation == null) {

      errorMessage =
          'موقعیت کاربر مشخص نیست';

      notifyListeners();

      return;

    }



    isLoading = true;

    errorMessage = null;

    notifyListeners();



    try {


      places =
          await _placesService.searchPlaces(

        query: query,

        userLocation:
            userLocation!,

        category:
            activeCategory,

      );



      _applyFilter();



    } catch (e) {


      errorMessage =
          'خطا در دریافت مکان‌ها';


    }



    isLoading = false;

    notifyListeners();

  }





  /// اعمال فیلتر فاصله و دسته
  void _applyFilter() {


    if (userLocation == null) {

      visiblePlaces = [];

      return;

    }



    visiblePlaces =
        places.where((place) {


      final distance =
          place.distanceMeters ?? 0;



      final inRadius =
          distance <=
              (searchRadiusKm * 1000);



      final inCategory =
          activeCategory == null ||
          place.category ==
              activeCategory;



      return inRadius &&
          inCategory;


    }).toList();



    visiblePlaces.sort(

      (a,b) =>

          (a.distanceMeters ?? 0)
              .compareTo(
                b.distanceMeters ?? 0,
              ),

    );


  }




  /// پاک کردن نتایج
  void clear() {


    places.clear();

    visiblePlaces.clear();

    notifyListeners();

  }



  /// نزدیک‌ترین مکان
  MapPlace? get nearestPlace {


    if (visiblePlaces.isEmpty) {

      return null;

    }


    return visiblePlaces.first;

  }


}
