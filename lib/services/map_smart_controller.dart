import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../map_place.dart';

import 'map_places_service.dart';
import 'location_service.dart';
import 'location_storage_service.dart';


class MapSmartController extends ChangeNotifier {


  final MapPlacesService _placesService =
      MapPlacesService();



  LatLng? userLocation;



  List<MapPlace> places = [];

  List<MapPlace> visiblePlaces = [];



  PlaceCategory? activeCategory;



  double searchRadiusKm = 10;



  bool isLoading = false;


  bool isLocationLoading = false;


  String? errorMessage;




  // ==========================
  // دریافت موقعیت هوشمند
  // ==========================

  Future<void> initializeLocation() async {


    isLocationLoading = true;

    errorMessage = null;

    notifyListeners();



    try {


      // مرحله اول:
      // دریافت آخرین موقعیت ذخیره شده

      final savedLocation =
          await LocationStorageService
              .loadLocation();



      if (savedLocation != null) {


        userLocation =
            savedLocation;


        notifyListeners();

      }




      // مرحله دوم:
      // دریافت GPS واقعی


      final position =
          await LocationService
              .getCurrentLocation();



      if (position == null) {


        errorMessage =
            'موقعیت مکانی در دسترس نیست. لطفاً GPS و دسترسی مکان را بررسی کنید';


      } else {


        final location =
            LatLng(
              position.latitude,
              position.longitude,
            );



        userLocation =
            location;



        await LocationStorageService
            .saveLocation(
              location,
            );


      }



    } catch (e) {


      errorMessage =
          'خطا در دریافت موقعیت کاربر';


    }



    isLocationLoading = false;


    notifyListeners();

  }





  // ==========================
  // تنظیم دستی موقعیت
  // ==========================

  void setUserLocation(
    LatLng location,
  ) {


    userLocation =
        location;


    notifyListeners();


  }






  // ==========================
  // تغییر فاصله جستجو
  // ==========================

  void setRadius(
    double km,
  ) {


    searchRadiusKm =
        km;


    _applyFilter();


    notifyListeners();


  }






  // ==========================
  // انتخاب دسته بندی
  // ==========================

  void setCategory(
    PlaceCategory? category,
  ) {


    activeCategory =
        category;


    _applyFilter();


    notifyListeners();


  }






  // ==========================
  // جستجوی مکان‌ها
  // ==========================

  Future<void> search({

    required String query,

  }) async {



    if (userLocation == null) {


      errorMessage =
          'موقعیت کاربر مشخص نیست';


      notifyListeners();


      return;

    }




    if (query.trim().isEmpty) {


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






  // ==========================
  // فیلتر فاصله و دسته
  // ==========================

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







  // ==========================
  // پاک کردن نتایج
  // ==========================

  void clear() {


    places.clear();


    visiblePlaces.clear();


    notifyListeners();


  }






  // ==========================
  // نزدیک ترین مکان
  // ==========================

  MapPlace? get nearestPlace {



    if (visiblePlaces.isEmpty) {


      return null;


    }



    return visiblePlaces.first;


  }



}
