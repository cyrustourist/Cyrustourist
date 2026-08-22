import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationManager {

  static Future<bool> checkService() async {
    return await Geolocator.isLocationServiceEnabled();
  }


  static Future<LocationPermission> requestPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    return permission;
  }


  static Future<LatLng?> getCurrentLocation() async {

    final enabled =
        await checkService();

    if (!enabled) {
      return null;
    }

    final permission =
        await requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }


    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );


    return LatLng(
      position.latitude,
      position.longitude,
    );
  }
}
