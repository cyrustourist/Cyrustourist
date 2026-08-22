import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLoaderService {
  static final MapController controller = MapController();

  static LatLng defaultLocation = const LatLng(
    35.6892,
    51.3890,
  );

  static bool isLoaded = false;

  static void loadMap() {
    isLoaded = true;
  }

  static void moveToLocation({
    required double latitude,
    required double longitude,
    double zoom = 15,
  }) {
    controller.move(
      LatLng(latitude, longitude),
      zoom,
    );
  }

  static void moveToDefault() {
    controller.move(
      defaultLocation,
      12,
    );
  }

  static void reset() {
    isLoaded = false;
  }
}
