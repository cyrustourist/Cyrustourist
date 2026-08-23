import 'package:flutter/material.dart';

import '../map_place.dart';


class MapPlaceCard extends StatelessWidget {

  final MapPlace place;

  final VoidCallback? onSearch;

  final VoidCallback? onFavorite;


  const MapPlaceCard({

    super.key,

    required this.place,

    this.onSearch,

    this.onFavorite,

  });



  @override
  Widget build(BuildContext context) {

    return Container(

      margin:
          const EdgeInsets.all(12),


      padding:
          const EdgeInsets.all(16),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),


        boxShadow: const [

          BoxShadow(

            color:
                Colors.black26,

            blurRadius:
                12,

            offset:
                Offset(0,5),

          ),

        ],

      ),



      child:
          Column(

        mainAxisSize:
            MainAxisSize.min,


        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [



          Row(

            children: [


              Container(

                padding:
                    const EdgeInsets.all(10),


                decoration:
                    BoxDecoration(

                  color:
                      _categoryColor(
                        place.category,
                      ),

                  shape:
                      BoxShape.circle,

                ),


                child:
                    Icon(

                  _categoryIcon(
                    place.category,
                  ),

                  color:
                      Colors.white,

                ),

              ),



              const SizedBox(
                width: 12,
              ),



              Expanded(

                child:
                    Text(

                  place.name,

                  style:
                      const TextStyle(

                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

              ),



              IconButton(

                onPressed:
                    onFavorite,


                icon:
                    const Icon(

                  Icons.favorite_border,

                  color:
                      Colors.red,

                ),

              ),


            ],

          ),



          const SizedBox(
            height: 12,
          ),



          if (place.address != null)

            Row(

              crossAxisAlignment:
                  CrossAxisAlignment.start,


              children: [


                const Icon(

                  Icons.location_on,

                  size:
                      18,

                ),


                const SizedBox(
                  width: 6,
                ),


                Expanded(

                  child:
                      Text(

                    place.address!,

                    maxLines:
                        3,

                    overflow:
                        TextOverflow.ellipsis,

                  ),

                ),

              ],

            ),



          const SizedBox(
            height: 10,
          ),



          if (place.distanceMeters != null)

            Text(

              'فاصله: ${_formatDistance(place.distanceMeters!)}',

              style:
                  const TextStyle(

                fontWeight:
                    FontWeight.w600,

              ),

            ),



          const SizedBox(
            height: 15,
          ),



          SizedBox(

            width:
                double.infinity,


            child:
                ElevatedButton.icon(

              onPressed:
                  onSearch,


              icon:
                  const Icon(
                    Icons.search,
                  ),


              label:
                  const Text(
                    'جستجو و مسیریابی',
                  ),

            ),

          ),


        ],

      ),

    );

  }





  String _formatDistance(
    double meters,
  ) {

    if (meters < 1000) {

      return '${meters.round()} متر';

    }


    return '${(meters / 1000).toStringAsFixed(1)} کیلومتر';

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

        return Colors.orange;


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
