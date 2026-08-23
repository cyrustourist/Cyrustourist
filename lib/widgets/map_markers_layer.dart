import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../map_place.dart';
import '../services/map_marker_factory.dart';


class MapMarkersLayer extends StatelessWidget {

  final List<MapPlace> places;

  final Function(MapPlace place)? onTap;


  const MapMarkersLayer({

    super.key,

    required this.places,

    this.onTap,

  });



  @override
  Widget build(BuildContext context) {

    return MarkerLayer(

      markers:

          places.map(

        (place) {


          return Marker(

            point:
                place.location,


            width:
                55,


            height:
                65,


            child:

                GestureDetector(

              onTap: () {

                if (onTap != null) {

                  onTap!(place);

                }

              },


              child:

                  _PlaceMarker(

                    place: place,

                  ),

            ),

          );


        },

      ).toList(),

    );

  }

}





class _PlaceMarker extends StatelessWidget {


  final MapPlace place;


  const _PlaceMarker({

    required this.place,

  });



  @override
  Widget build(BuildContext context) {


    return Column(

      children: [


        Container(

          width:
              42,

          height:
              42,


          decoration:
              BoxDecoration(

            color:
                _markerColor(
                  place.category,
                ),


            shape:
                BoxShape.circle,


            boxShadow: const [

              BoxShadow(

                blurRadius:
                    8,

                color:
                    Colors.black38,

                offset:
                    Offset(0,3),

              ),

            ],

          ),


          child:

              Icon(

            _markerIcon(
              place.category,
            ),

            color:
                Colors.white,

            size:
                24,

          ),

        ),



        Container(

          width:
              12,

          height:
              12,


          decoration:
              BoxDecoration(

            color:
                _markerColor(
                  place.category,
                ),

            shape:
                BoxShape.circle,

          ),

        ),


      ],

    );

  }





  Color _markerColor(
    PlaceCategory category,
  ) {


    switch(category) {


      case PlaceCategory.health:

        return Colors.red;


      case PlaceCategory.attraction:

        return Colors.green;


      case PlaceCategory.accommodation:

        return Colors.orange;


      case PlaceCategory.restaurant:

        return Colors.deepOrange;


      default:

        return Colors.blue;

    }

  }





  IconData _markerIcon(
    PlaceCategory category,
  ) {


    switch(category) {


      case PlaceCategory.health:

        return Icons.local_hospital;


      case PlaceCategory.attraction:

        return Icons.photo_camera;


      case PlaceCategory.accommodation:

        return Icons.hotel;


      case PlaceCategory.restaurant:

        return Icons.restaurant;


      default:

        return Icons.location_on;

    }

  }


}
