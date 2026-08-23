import 'package:flutter/material.dart';

import '../map_place.dart';


class MapPlaceActions extends StatelessWidget {

  final MapPlace place;

  final VoidCallback? onRoute;

  final VoidCallback? onFavorite;

  final VoidCallback? onShare;


  const MapPlaceActions({

    super.key,

    required this.place,

    this.onRoute,

    this.onFavorite,

    this.onShare,

  });



  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: const [

          BoxShadow(

            color: Colors.black26,

            blurRadius: 10,

            offset: Offset(0, 4),

          ),

        ],

      ),


      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [


          _ActionButton(

            icon: Icons.directions,

            title: 'مسیر',

            color: Colors.blue,

            onTap: onRoute,

          ),



          _ActionButton(

            icon: Icons.favorite,

            title: 'علاقه‌مندی',

            color: Colors.red,

            onTap: onFavorite,

          ),



          _ActionButton(

            icon: Icons.share,

            title: 'اشتراک',

            color: Colors.green,

            onTap: onShare,

          ),


        ],

      ),

    );

  }

}





class _ActionButton extends StatelessWidget {


  final IconData icon;

  final String title;

  final Color color;

  final VoidCallback? onTap;



  const _ActionButton({

    required this.icon,

    required this.title,

    required this.color,

    this.onTap,

  });



  @override
  Widget build(BuildContext context) {


    return InkWell(

      borderRadius: BorderRadius.circular(50),

      onTap: onTap,


      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [


          Container(

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: color.withOpacity(0.12),

              shape: BoxShape.circle,

            ),


            child: Icon(

              icon,

              color: color,

              size: 26,

            ),

          ),


          const SizedBox(height: 6),


          Text(

            title,

            style: const TextStyle(

              fontSize: 12,

              fontWeight: FontWeight.bold,

            ),

          ),


        ],

      ),

    );

  }

}
