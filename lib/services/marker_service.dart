import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerService {

  static List<Marker> userMarker(
    LatLng? location,
  ) {

    if (location == null) {
      return [];
    }


    return [
      Marker(
        point: location,

        width: 70,
        height: 70,

        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: Colors.blue.withValues(
              alpha: 0.25,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(
                  alpha: 0.35,
                ),

                blurRadius: 18,
                spreadRadius: 5,
              ),
            ],
          ),

          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 38,
          ),
        ),
      ),
    ];
  }


  static Marker tourismMarker({
    required LatLng location,
    required IconData icon,
    required String title,
  }) {

    return Marker(
      point: location,

      width: 60,
      height: 70,

      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: Colors.white,

              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.25,
                  ),

                  blurRadius: 8,
                ),
              ],
            ),

            child: Icon(
              icon,
              color: const Color(0xff0b506b),
              size: 28,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
