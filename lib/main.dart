import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/map_state_service.dart';
import 'providers/map_state_provider.dart';
import 'pages/map/smart_map_page.dart';


// ============================================================
// MAIN
// ============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CyrusTouristApp());
}


// ============================================================
// APP
// ============================================================

class CyrusTouristApp extends StatelessWidget {
  const CyrusTouristApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyrus Tourist',

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: SplashPage(),
    );
  }
}


// ============================================================
// LANGUAGE
// ============================================================

enum AppLanguage {
  persian,
  english,
  arabic,
}


class LanguageManager {

  static AppLanguage current =
      AppLanguage.english;


  static Future<void> load() async {

    final pref =
        await SharedPreferences.getInstance();


    final saved =
        pref.getString('language');


    if (saved == 'fa') {

      current =
          AppLanguage.persian;

    } else if (saved == 'ar') {

      current =
          AppLanguage.arabic;

    } else if (saved == 'en') {

      current =
          AppLanguage.english;

    } else {

      final code =
          WidgetsBinding
              .instance
              .platformDispatcher
              .locale
              .languageCode
              .toLowerCase();


      if (code == 'fa') {

        current =
            AppLanguage.persian;

      } else if (code == 'ar') {

        current =
            AppLanguage.arabic;

      } else {

        current =
            AppLanguage.english;

      }
    }
  }



  static Future<void> setLanguage(
      AppLanguage lang) async {

    current = lang;


    final pref =
        await SharedPreferences.getInstance();


    switch(lang) {

      case AppLanguage.persian:
        await pref.setString(
            'language',
            'fa');
        break;


      case AppLanguage.arabic:
        await pref.setString(
            'language',
            'ar');
        break;


      case AppLanguage.english:
        await pref.setString(
            'language',
            'en');
        break;
    }
  }
}


// ============================================================
// TEXT
// ============================================================

class AppText {
  static String map() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'نقشه';
      case AppLanguage.arabic:
        return 'الخريطة';
      case AppLanguage.english:
        return 'Map';
    }
  }



  static bool get rtl =>
      LanguageManager.current !=
      AppLanguage.english;



  static String title() {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'سایروس توریست';


      case AppLanguage.english:
        return 'Cyrus Tourist';


      case AppLanguage.arabic:
        return 'سايروس توريست';
    }
  }



  static String languageName() {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'پارسی';


      case AppLanguage.english:
        return 'English';


      case AppLanguage.arabic:
        return 'العربية';
    }
  }



}

// ============================================================
// HOME PAGE
// ============================================================



// Splash screen
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    LanguageManager.load();

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      body: SizedBox.expand(

        child: Image.asset(
          'assets/images/splash.jpg',
          fit: BoxFit.cover,

          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Splash image not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),

      ),

    );
  }
}

class HomePage extends StatefulWidget {

  const HomePage({
    super.key,
  });


  @override
  State<HomePage> createState() =>
      _HomePageState();
}



class _HomePageState
    extends State<HomePage> {


  int selected = 0;



  String get homeImage {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'assets/images/home_fa.jpg';


      case AppLanguage.english:
        return 'assets/images/home_en.jpg';


      case AppLanguage.arabic:
        return 'assets/images/home_ar.jpg';
    }
  }



  Future<void> openLanguage() async {


    await showModalBottomSheet(

      context: context,


      backgroundColor:
          const Color(0xff071722),


      builder: (_) {


        return Column(

          mainAxisSize:
              MainAxisSize.min,


          children: [

            languageItem(
              'پارسی',
              AppLanguage.persian,
            ),


            languageItem(
              'English',
              AppLanguage.english,
            ),


            languageItem(
              'العربية',
              AppLanguage.arabic,
            ),
          ],
        );
      },
    );


    if(mounted) {

      setState(() {});
    }
  }





  Widget languageItem(
      String text,
      AppLanguage lang) {


    return ListTile(

      title: Text(

        text,

        style:
            const TextStyle(

          color:
              Colors.white,

          fontSize:
              20,

          fontWeight:
              FontWeight.bold,
        ),
      ),


      onTap: () async {


        await LanguageManager
            .setLanguage(lang);



        if(mounted) {


          Navigator.pop(context);


          setState(() {});
        }
      },
    );
  }





  Future<void> tap(int number) async {


    setState(() {

      selected = number;

    });



    await Future.delayed(

      const Duration(
        milliseconds: 150,
      ),

    );



    if(!mounted) return;



    setState(() {

      selected = 0;

    });



    // نقشه گردشگری

    if(number == 1) {


      Navigator.push(

        context,


        MaterialPageRoute(

          builder: (_) =>
              const SmartMapPage(),

        ),

      );
    }
  }






  Widget area(

      int number,

      double left,

      double top,

      double width,

      double height,

      double imageWidth,

      double imageHeight,

      ) {


    return Positioned(


      left:
          imageWidth * left,


      top:
          imageHeight * top,


      width:
          imageWidth * width,


      height:
          imageHeight * height,



      child:
          GestureDetector(


        onTap: () =>
            tap(number),



        child:
            AnimatedScale(


          scale:
              selected == number
                  ? 0.92
                  : 1,


          duration:
              const Duration(
                milliseconds: 120,
              ),



          child:
              AnimatedContainer(


            duration:
                const Duration(
                  milliseconds: 120,
                ),



            decoration:
                BoxDecoration(


              borderRadius:
                  BorderRadius.circular(
                    18,
                  ),



              boxShadow:

                  selected == number

                  ? [

                    BoxShadow(

                      color:
                          const Color(
                            0xffffd36a,
                          )
                          .withValues(
                            alpha: 0.8,
                          ),


                      blurRadius:
                          25,


                      spreadRadius:
                          5,

                    ),

                  ]

                  : [],

            ),
          ),
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:
          Colors.black,



      body:
          SafeArea(


        child:
            LayoutBuilder(


          builder:
              (context, constraints) {



            double width =
                constraints.maxWidth;



            double height =
                width * 16 / 9;



            if(height >
                constraints.maxHeight) {


              height =
                  constraints.maxHeight;


              width =
                  height * 9 / 16;
            }





            return Center(


              child:
                  SizedBox(


                width:
                    width,


                height:
                    height,



                child:
                    Stack(


                  fit:
                      StackFit.expand,



                  children: [



                    Image.asset(

                      homeImage,

                      fit:
                          BoxFit.cover,

                    ),




                    Positioned(


                      top:
                          15,


                      left:
                          15,



                      child:
                          GestureDetector(


                        onTap:
                            openLanguage,



                        child:
                            Container(


                          padding:
                              const EdgeInsets.all(
                                10,
                              ),



                          decoration:
                              BoxDecoration(


                            color:
                                const Color(
                                  0xff0b506b,
                                ),



                            borderRadius:
                                BorderRadius.circular(
                                  22,
                                ),



                            border:
                                Border.all(

                              color:
                                  const Color(
                                    0xffffd36a,
                                  ),
                            ),
                          ),



                          child:
                              Text(

                            AppText.languageName(),



                            style:
                                const TextStyle(

                              color:
                                  Colors.white,


                              fontWeight:
                                  FontWeight.bold,

                            ),
                          ),
                        ),
                      ),
                    ),




                    area(1,.02,.62,.18,.10,width,height),

                    area(2,.21,.62,.18,.10,width,height),

                    area(3,.40,.62,.18,.10,width,height),

                    area(4,.59,.62,.18,.10,width,height),

                    area(5,.78,.62,.18,.10,width,height),


                    area(6,.02,.73,.18,.10,width,height),

                    area(7,.21,.73,.18,.10,width,height),

                    area(8,.40,.73,.18,.10,width,height),

                    area(9,.59,.73,.18,.10,width,height),

                    area(10,.78,.73,.18,.10,width,height),

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

