import 'package:flutter/material.dart';

import '../map_place.dart';
import 'map_favorite_button.dart';


class MapPlaceDetailsSheet extends StatelessWidget {

  final MapPlace place;

  final bool isFavorite;

  final VoidCallback? onFavorite;

  final VoidCallback? onRoute;


  const MapPlaceDetailsSheet({

    super.key,

    required this.place,

    this.isFavorite = false,

    this.onFavorite,

    this.onRoute,

  });



  static void show(

    BuildContext context,

    MapPlace place, {

    bool isFavorite = false,

    VoidCallback? onFavorite,

    VoidCallback? onRoute,

  }) {


    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,


      builder: (_) {

        return MapPlaceDetailsSheet(

          place: place,

          isFavorite: isFavorite,

          onFavorite: onFavorite,

          onRoute: onRoute,

        );

      },

    );

  }





  @override
  Widget build(BuildContext context) {


    return Container(

      margin: const EdgeInsets.all(12),

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(28),

        boxShadow: const [

          BoxShadow(

            color: Colors.black26,

            blurRadius: 15,

            offset: Offset(0, 5),

          ),

        ],

      ),



      child: Column(

        mainAxisSize: MainAxisSize.min,


        children: [


          Container(

            width: 45,

            height: 5,

            margin: const EdgeInsets.only(

              bottom: 15,

            ),


            decoration: BoxDecoration(

              color: Colors.grey,

              borderRadius:

                  BorderRadius.circular(10),

            ),

          ),



          Row(

            children: [


              CircleAvatar(

                radius: 28,

                backgroundColor:

                    _categoryColor(place.category),


                child: Icon(

                  _categoryIcon(place.category),

                  color: Colors.white,

                  size: 28,

                ),

              ),



              const SizedBox(width: 12),



              Expanded(

                child: Text(

                  place.name,

                  style: const TextStyle(

                    fontSize: 20,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),



              MapFavoriteButton(

                isFavorite: isFavorite,

                onTap: onFavorite,

              ),

            ],

          ),



          const SizedBox(height: 15),



          if (place.address != null)

            Text(

              place.address!,

              maxLines: 3,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(

                fontSize: 14,

              ),

            ),



          const SizedBox(height: 10),



          if (place.distanceMeters != null)

            Row(

              children: [


                const Icon(

                  Icons.near_me,

                  color: Colors.blue,

                ),


                const SizedBox(width: 8),


                Text(

                  _distance(),

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ],

            ),



          const SizedBox(height: 15),



          SizedBox(

            width: double.infinity,


            child: ElevatedButton.icon(

              onPressed: onRoute,


              icon: const Icon(

                Icons.navigation,

              ),


              label: const Text(

                'مسیر‌یابی',

              ),


              style: ElevatedButton.styleFrom(

                padding:

                    const EdgeInsets.symmetric(

                  vertical: 14,

                ),

                shape:

                    RoundedRectangleBorder(

                  borderRadius:

                      BorderRadius.circular(16),

                ),

              ),

            ),

          ),


        ],

      ),

    );

  }





  String _distance() {

    final meter = place.distanceMeters!;


    if (meter < 1000) {

      return '${meter.round()} متر';

    }


    return '${(meter / 1000).toStringAsFixed(1)} کیلومتر';

  }





  Color _categoryColor(

    PlaceCategory category,

  ) {


    switch(category) {


      case PlaceCategory.health:

        return Colors.red;


      case PlaceCategory.attraction:

        return Colors.green;


      case PlaceCategory.accommodation:

        return Colors.lightBlue;


      case PlaceCategory.restaurant:

        return Colors.deepOrange;


      default:

        return Colors.blue;

    }

  }





  IconData _categoryIcon(

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

        return Icons.place;

    }

  }

}
