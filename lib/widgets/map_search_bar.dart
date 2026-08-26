import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {

  final TextEditingController controller;

  final VoidCallback? onSearch;

  final ValueChanged<String>? onChanged;

  final String? hintText;

  const MapSearchBar({

    super.key,

    required this.controller,

    this.onSearch,

    this.onChanged,

    this.hintText,

  });



  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.all(12),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(25),

        boxShadow: const [

          BoxShadow(

            color: Colors.black26,

            blurRadius: 12,

            offset: Offset(0, 5),

          ),

        ],

      ),


      child: TextField(

        controller: controller,

        onChanged: onChanged,

        onSubmitted: (_) {
          if (onSearch != null) {
            onSearch!();
          }
        },

        textDirection: TextDirection.rtl,


        decoration: InputDecoration(

          hintText:
              hintText ??
                  'جستجوی مکان، بیمارستان، هتل، جاذبه...',


          prefixIcon: IconButton(

            icon: const Icon(

              Icons.search,

              color: Colors.blue,

            ),


            onPressed: onSearch,

          ),


          suffixIcon: IconButton(

            icon: const Icon(

              Icons.clear,

            ),


            onPressed: () {

              controller.clear();

              if (onChanged != null) {
                onChanged!('');
              }

            },

          ),


          border: InputBorder.none,


          contentPadding:

              const EdgeInsets.symmetric(

            horizontal: 20,

            vertical: 16,

          ),

        ),

      ),

    );

  }

}
