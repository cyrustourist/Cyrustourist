import 'package:flutter/material.dart';

import '../map_place.dart';
import 'map_place_card.dart';


class MapPlaceBottomSheet extends StatelessWidget {

  final MapPlace place;

  final VoidCallback? onFavorite;

  final VoidCallback? onSearch;


  const MapPlaceBottomSheet({

    super.key,

    required this.place,

    this.onFavorite,

    this.onSearch,

  });



  static void show(

    BuildContext context,

    MapPlace place, {

    VoidCallback? onFavorite,

    VoidCallback? onSearch,

  }) {


    showModalBottomSheet(

      context: context,


      backgroundColor:

          Colors.transparent,


      isScrollControlled:

          true,


      builder: (_) {


        return MapPlaceBottomSheet(

          place: place,

          onFavorite: onFavorite,

          onSearch: onSearch,

        );


      },

    );

  }





  @override
  Widget build(BuildContext context) {


    return Container(

      padding:

          const EdgeInsets.only(

            top: 8,

            bottom: 20,

          ),


      decoration:

          const BoxDecoration(

        color: Colors.transparent,

      ),



      child: Column(

        mainAxisSize:

            MainAxisSize.min,


        children: [


          Container(

            width: 45,

            height: 5,


            margin:

                const EdgeInsets.only(

                  bottom: 8,

                ),


            decoration:

                BoxDecoration(

              color:

                  Colors.white,

              borderRadius:

                  BorderRadius.circular(

                    10,

                  ),

            ),

          ),



          MapPlaceCard(

            place: place,

            onFavorite:

                onFavorite,

            onSearch:

                onSearch,

          ),


        ],

      ),

    );

  }

}
