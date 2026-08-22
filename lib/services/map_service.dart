import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static const LatLng iranCenter = LatLng(
    32.4279,
    53.6880,
  );

  static const double defaultZoom = 5;

  static const double userZoom = 15;

  static final MapController controller =
      MapController();

  static void moveTo(
    LatLng location, {
    double zoom = userZoom,
  }) {
    controller.move(
      location,
      zoom,
    );
  }

  static void moveToIran() {
    controller.move(
      iranCenter,
      defaultZoom,
    );
  }

  static LatLng createPosition(
    double latitude,
    double longitude,
  ) {
    return LatLng(
      latitude,
      longitude,
    );
  }

  static bool isValidPosition(
    LatLng point,
  ) {
    return point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  static double distanceBetween(
    LatLng first,
    LatLng second,
  ) {
    const distance = Distance();

    return distance.as(
      LengthUnit.Meter,
      first,
      second,
    );
  }
}
