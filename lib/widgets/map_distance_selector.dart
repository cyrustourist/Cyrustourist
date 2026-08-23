import 'package:flutter/material.dart';

class MapDistanceSelector extends StatelessWidget {
  final double selectedDistance;
  final ValueChanged<double>? onChanged;

  const MapDistanceSelector({
    super.key,
    required this.selectedDistance,
    this.onChanged,
  });

  static const List<double> distances = [
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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: const [
              Icon(
                Icons.radar,
                color: Colors.blue,
              ),

              SizedBox(width: 8),

              Text(
                'فاصله جستجو',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),


          const SizedBox(height: 12),


          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: distances.map((distance) {

              final bool active =
                  distance == selectedDistance;

              return GestureDetector(
                onTap: () {

                  if (onChanged != null) {
                    onChanged!(distance);
                  }

                },

                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 250),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: active
                        ? Colors.blue
                        : Colors.blue.shade50,

                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(
                      color: active
                          ? Colors.blue
                          : Colors.transparent,
                    ),

                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),


                  child: Text(
                    '${distance.toInt()} km',

                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.blue,

                      fontWeight:
                          FontWeight.bold,

                      fontSize: 15,
                    ),
                  ),

                ),

              );

            }).toList(),
          ),

        ],
      ),
    );
  }
}
