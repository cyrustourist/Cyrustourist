import 'package:flutter/material.dart';
import 'map_marker_data.dart';

class MarkerBuilderService {
  static Widget buildMarkerIcon(MapMarkerData marker) {
    switch (marker.type) {
      case MapMarkerType.tourism:
        return const Icon(
          Icons.location_on,
          color: Colors.green,
          size: 42,
        );

      case MapMarkerType.hotel:
        return const Icon(
          Icons.hotel,
          color: Colors.blue,
          size: 38,
        );

      case MapMarkerType.restaurant:
        return const Icon(
          Icons.restaurant,
          color: Colors.orange,
          size: 38,
        );

      case MapMarkerType.nature:
        return const Icon(
          Icons.park,
          color: Colors.green,
          size: 38,
        );

      case MapMarkerType.service:
        return const Icon(
          Icons.info,
          color: Colors.red,
          size: 38,
        );

      default:
        return const Icon(
          Icons.place,
          color: Colors.grey,
          size: 38,
        );
    }
  }
}
