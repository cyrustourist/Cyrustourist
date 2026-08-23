import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../map_place.dart';


class MapMarkerFactory {


  static Marker buildMarker({
    required MapPlace place,
    required VoidCallback onTap,
  }) {

    return Marker(

      point: place.location,

      width: 55,

      height: 70,


      child: GestureDetector(

        onTap: onTap,


        child: Column(

          children: [

            Container(

              padding:
                  const EdgeInsets.all(8),


              decoration:
                  BoxDecoration(

                color:
                    _categoryColor(
                      place.category,
                    ),

                shape:
                    BoxShape.circle,


                boxShadow: const [

                  BoxShadow(

                    color:
                        Colors.black38,

                    blurRadius:
                        8,

                    offset:
                        Offset(0,3),

                  ),

                ],

              ),


              child:
                  Icon(

                _categoryIcon(
                  place.category,
                ),

                color:
                    Colors.white,

                size:
                    26,

              ),

            ),


            const SizedBox(
              height: 3,
            ),


            Container(

              padding:
                  const EdgeInsets
                      .symmetric(

                horizontal: 6,

                vertical: 3,

              ),


              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                      8,
                    ),

              ),


              child:
                  Text(

                place.name,

                maxLines:
                    1,

                overflow:
                    TextOverflow.ellipsis,


                style:
                    const TextStyle(

                  fontSize:
                      10,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }





  static Color _categoryColor(
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





  static IconData _categoryIcon(
    PlaceCategory category,
  ) {

    switch(category) {


      case PlaceCategory.health:
        return Icons.local_hospital;


      case PlaceCategory.attraction:
        return Icons.park;


      case PlaceCategory.accommodation:
        return Icons.hotel;


      case PlaceCategory.restaurant:
        return Icons.restaurant;


      default:
        return Icons.place;

    }

  }

}
