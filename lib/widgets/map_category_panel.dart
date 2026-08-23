import 'package:flutter/material.dart';

import '../services/map_distance_filter.dart';
import '../map_place.dart';

class MapCategoryPanel extends StatefulWidget {
  final PlaceCategory? selectedCategory;
  final int selectedRadius;

  final Function(
    PlaceCategory category,
  ) onCategorySelected;

  final Function(
    int radius,
  ) onRadiusSelected;


  const MapCategoryPanel({
    super.key,
    required this.selectedCategory,
    required this.selectedRadius,
    required this.onCategorySelected,
    required this.onRadiusSelected,
  });


  @override
  State<MapCategoryPanel> createState() =>
      _MapCategoryPanelState();
}


class _MapCategoryPanelState
    extends State<MapCategoryPanel> {


  final List<int> radiusList = [
    5,
    10,
    15,
    25,
    50,
    100,
  ];


  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xff071722),
        borderRadius:
            BorderRadius.circular(28),

        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),


      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 45,
            height: 5,
            decoration:
                BoxDecoration(
              color: Colors.white38,
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),


          const SizedBox(height: 18),


          const Text(
            'جستجوی هوشمند نقشه',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),


          const SizedBox(height: 18),



          Row(
            children: [

              Expanded(
                child: _categoryButton(
                  title: 'سلامت',
                  icon: Icons.local_hospital,
                  color:
                      const Color(0xffD32F2F),
                  category:
                      PlaceCategory.health,
                ),
              ),


              const SizedBox(width: 10),


              Expanded(
                child: _categoryButton(
                  title: 'جاذبه',
                  icon:
                      Icons.park,
                  color:
                      const Color(0xff2E7D32),
                  category:
                      PlaceCategory.attraction,
                ),
              ),


              const SizedBox(width: 10),


              Expanded(
                child: _categoryButton(
                  title: 'اقامت',
                  icon:
                      Icons.hotel,
                  color:
                      const Color(0xffFF9800),
                  category:
                      PlaceCategory.accommodation,
                ),
              ),

            ],
          ),



          const SizedBox(height: 20),



          Align(
            alignment:
                Alignment.centerRight,

            child: const Text(
              'فاصله جستجو',
              style:
                  TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),



          const SizedBox(height: 10),



          Wrap(
            spacing: 8,
            runSpacing: 8,

            children:
                radiusList.map(
              (km) {

                final active =
                    km ==
                        widget.selectedRadius;


                return GestureDetector(

                  onTap: () {

                    widget
                        .onRadiusSelected(
                      km,
                    );

                    setState(() {});
                  },


                  child:
                      AnimatedContainer(

                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),


                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),


                    decoration:
                        BoxDecoration(

                      color: active
                          ? const Color(
                              0xff0083B0,
                            )
                          : Colors.white
                              .withValues(
                              alpha: 0.12,
                            ),


                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),


                      border:
                          Border.all(
                        color: active
                            ? Colors.white
                            : Colors.white24,
                      ),

                    ),


                    child:
                        Text(

                      '$km km',

                      style:
                          TextStyle(

                        color:
                            Colors.white,

                        fontWeight:
                            active
                                ? FontWeight.bold
                                : FontWeight.normal,

                      ),
                    ),
                  ),
                );

              },
            ).toList(),
          ),



          const SizedBox(height: 12),

        ],
      ),
    );
  }





  Widget _categoryButton({

    required String title,
    required IconData icon,
    required Color color,
    required PlaceCategory category,

  }) {


    final active =
        widget.selectedCategory ==
            category;


    return GestureDetector(

      onTap: () {

        widget
            .onCategorySelected(
          category,
        );

      },


      child:
          AnimatedContainer(

        duration:
            const Duration(
          milliseconds: 180,
        ),


        padding:
            const EdgeInsets
                .symmetric(
          vertical: 14,
        ),


        decoration:
            BoxDecoration(

          color:
              active
                  ? color
                  : Colors.white
                      .withValues(
                      alpha: 0.10,
                    ),


          borderRadius:
              BorderRadius.circular(
            18,
          ),


          border:
              Border.all(
            color:
                active
                    ? Colors.white
                    : color,
            width: 1.2,
          ),

        ),



        child:
            Column(

          children: [

            Icon(
              icon,
              color:
                  Colors.white,
              size: 28,
            ),


            const SizedBox(
              height: 6,
            ),


            Text(

              title,

              style:
                  const TextStyle(

                color:
                    Colors.white,

                fontWeight:
                    FontWeight.bold,

                fontSize:
                    12,

              ),
            ),

          ],
        ),
      ),
    );
  }
}
