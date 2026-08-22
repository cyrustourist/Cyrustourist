import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapControllerService {

  final MapController controller =
      MapController();


  static const LatLng iranCenter =
      LatLng(
        32.4279,
        53.6880,
      );


  void moveToLocation(
    LatLng location, {
    double zoom = 15,
  }) {
    controller.move(
      location,
      zoom,
    );
  }


  void moveToIranCenter({
    double zoom = 5,
  }) {
    controller.move(
      iranCenter,
      zoom,
    );
  }


  void zoomIn() {
    controller.move(
      controller.camera.center,
      controller.camera.zoom + 1,
    );
  }


  void zoomOut() {
    controller.move(
      controller.camera.center,
      controller.camera.zoom - 1,
    );
  }
}
