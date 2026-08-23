import 'package:flutter/material.dart';

class MapDistanceFilter {
  static const List<int> distances = [
    5,
    10,
    15,
    25,
    50,
    100,
  ];


  static Future<int?> show({
    required BuildContext context,
    int selected = 10,
  }) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {

        int current = selected;

        return StatefulBuilder(
          builder: (context, setState) {

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff071722),
                borderRadius:
                    BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
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
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 18),


                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.radar,
                        color: Color(0xff29B6F6),
                      ),

                      SizedBox(width: 8),

                      Text(
                        'فاصله جستجوی اطراف من',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 20),


                  Wrap(
                    spacing: 10,
                    runSpacing: 12,

                    children:
                        distances.map((km) {

                      final active =
                          current == km;


                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(18),

                        onTap: () {

                          setState(() {
                            current = km;
                          });

                        },


                        child: AnimatedContainer(
                          duration:
                              const Duration(
                                milliseconds: 200,
                              ),

                          width: 90,
                          height: 55,


                          decoration: BoxDecoration(

                            borderRadius:
                                BorderRadius.circular(18),

                            gradient: active
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xff00B4DB),
                                      Color(0xff0083B0),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xffFFFFFF),
                                      Color(0xffDCEAF0),
                                    ],
                                  ),

                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Colors.black38,
                                blurRadius: 8,
                                offset:
                                    Offset(0,4),
                              ),
                            ],
                          ),


                          child: Center(
                            child: Text(
                              '$km کیلومتر',

                              style: TextStyle(

                                color: active
                                    ? Colors.white
                                    : const Color(
                                        0xff123746,
                                      ),

                                fontWeight:
                                    FontWeight.bold,

                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );


                    }).toList(),
                  ),


                  const SizedBox(height: 20),


                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(

                      onPressed: () {

                        Navigator.pop(
                          context,
                          current,
                        );

                      },


                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            const Color(
                              0xff0083B0,
                            ),

                        foregroundColor:
                            Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                        ),
                      ),


                      child: const Text(
                        'تأیید فاصله جستجو',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
