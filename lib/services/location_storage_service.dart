import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationStorageService {

  static Future<void> saveLocation(
      LatLng location) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setDouble(
      'last_lat',
      location.latitude,
    );

    await prefs.setDouble(
      'last_lng',
      location.longitude,
    );
  }


  static Future<LatLng?> loadLocation() async {

    final prefs =
        await SharedPreferences.getInstance();

    final lat =
        prefs.getDouble('last_lat');

    final lng =
        prefs.getDouble('last_lng');


    if (lat == null || lng == null) {
      return null;
    }


    return LatLng(
      lat,
      lng,
    );
  }
}
