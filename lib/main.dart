import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/map_state_service.dart';
import 'providers/map_state_provider.dart';


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

      home: const SplashPage(),
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
  }

// ============================================================
// SMART MAP PAGE
// ============================================================

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() => _SmartMapPageState();
}

class _SmartMapPageState extends State<SmartMapPage>
    with SingleTickerProviderStateMixin {

  final MapController mapController = MapController();

  static const LatLng iranCenter = LatLng(
    32.4279,
    53.6880,
  );

  LatLng? userLocation;

  bool loading = true;
  bool mapReady = false;
  bool locationLoading = false;

  String? locationWarning;

  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> rotationAnimation;
  late Animation<double> glowAnimation;


  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();


    scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );


    rotationAnimation = Tween<double>(
      begin: 0,
      end: 6.283,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );


    glowAnimation = Tween<double>(
      begin: 0.25,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      prepareMap();
    });
  }


  @override
  void dispose() {

    animationController.dispose();

    super.dispose();
  }



  // ==========================================================
  // MAP START
  // ==========================================================

  Future<void> prepareMap() async {

    if (!mounted) return;


    setState(() {
      mapReady = true;
      loading = false;
    });


    await loadLastLocation();

    await getLocation();
  }



  Future<void> loadLastLocation() async {

    try {

      final pref =
          await SharedPreferences.getInstance();


      final lat =
          pref.getDouble('last_lat');

      final lng =
          pref.getDouble('last_lng');


      if (lat == null || lng == null) return;


      final point = LatLng(
        lat,
        lng,
      );


      if (!mounted) return;


      setState(() {

        userLocation = point;

      });


      mapController.move(
        point,
        13,
      );


    } catch (_) {}
  }



  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> getLocation() async {


    if (locationLoading) return;


    locationLoading = true;


    try {


      final enabled =
          await Geolocator.isLocationServiceEnabled();



      if (!enabled) {

        setState(() {

          locationWarning =
              'موقعیت‌یاب دستگاه خاموش است';

        });


        return;
      }



      LocationPermission permission =
          await Geolocator.checkPermission();



      if (permission ==
          LocationPermission.denied) {


        permission =
            await Geolocator.requestPermission();

      }



      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {


        setState(() {

          locationWarning =
              'دسترسی موقعیت فعال نیست';

        });


        return;
      }



      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );



      final point = LatLng(
        position.latitude,
        position.longitude,
      );



      final pref =
          await SharedPreferences.getInstance();


      await pref.setDouble(
        'last_lat',
        point.latitude,
      );


      await pref.setDouble(
        'last_lng',
        point.longitude,
      );



      if (!mounted) return;



      setState(() {

        userLocation = point;

        locationWarning = null;

      });



      mapController.move(
        point,
        15,
      );


    } catch (_) {


      if (mounted) {

        setState(() {

          locationWarning =
              'خطا در دریافت موقعیت';

        });

      }


    } finally {


      locationLoading = false;

    }
  }
    // ==========================================================
  // MARKERS
  // ==========================================================

  List<Marker> markers() {

    final items = <Marker>[];


    if (userLocation != null) {

      items.add(
        Marker(
          point: userLocation!,
          width: 65,
          height: 65,

          child: Container(

            decoration: BoxDecoration(

              shape: BoxShape.circle,

              color: Colors.blue.withValues(
                alpha: 0.25,
              ),

              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),

            ),


            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 35,
            ),

          ),
        ),
      );

    }


    return items;
  }



  // ==========================================================
  // TEXTS
  // ==========================================================

  String get loadingTitle {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'در حال آماده‌سازی نقشه گردشگری...';


      case AppLanguage.english:
        return 'Preparing Tourism Map...';


      case AppLanguage.arabic:
        return 'جارٍ إعداد الخريطة السياحية...';

    }

  }



  String get loadingSubtitle {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'لطفاً چند لحظه صبر کنید';


      case AppLanguage.english:
        return 'Please wait a moment';


      case AppLanguage.arabic:
        return 'يرجى الانتظار لحظة';

    }

  }



  String get locationText {

    switch(LanguageManager.current) {

      case AppLanguage.persian:
        return 'در حال بررسی موقعیت شما...';


      case AppLanguage.english:
        return 'Checking your location...';


      case AppLanguage.arabic:
        return 'جارٍ تحديد موقعك...';

    }

  }




  // ==========================================================
  // PROFESSIONAL LOADING SCREEN
  // ==========================================================

  Widget loadingScreen() {


    return Container(

      color: const Color(0xff071722),


      child: Center(

        child: AnimatedBuilder(

          animation: animationController,


          builder: (context, child) {


            return Column(

              mainAxisAlignment:
                  MainAxisAlignment.center,


              children: [



                SizedBox(

                  width: 210,
                  height: 210,


                  child: Stack(

                    alignment:
                        Alignment.center,


                    children: [



                      Transform.rotate(

                        angle:
                            rotationAnimation.value,


                        child: Container(

                          width: 190,
                          height: 190,


                          decoration: BoxDecoration(

                            shape:
                                BoxShape.circle,


                            border: Border.all(

                              color:
                                  const Color(0xffffd36a)
                                      .withValues(
                                alpha:
                                    glowAnimation.value,
                              ),


                              width: 2,

                            ),


                            boxShadow: [

                              BoxShadow(

                                color:
                                    const Color(0xffffd36a)
                                        .withValues(
                                  alpha:
                                      glowAnimation.value *
                                          .5,
                                ),


                                blurRadius: 25,

                              ),

                            ],


                          ),

                        ),

                      ),



                      Transform.scale(

                        scale:
                            scaleAnimation.value,


                        child: Container(

                          width: 115,
                          height: 115,


                          padding:
                              const EdgeInsets.all(8),


                          decoration: BoxDecoration(

                            color:
                                Colors.white,


                            shape:
                                BoxShape.circle,

                          ),


                          child: ClipOval(

                            child: Image.asset(

                              'assets/images/logo-new.jpg',

                              fit:
                                  BoxFit.cover,

                            ),

                          ),

                        ),

                      ),



                    ],

                  ),

                ),



                const SizedBox(height: 30),



                Text(

                  AppText.title(),


                  style: const TextStyle(

                    color:
                        Color(0xffffd36a),

                    fontSize:
                        26,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),



                const SizedBox(height: 15),



                Text(

                  loadingTitle,


                  style: const TextStyle(

                    color:
                        Colors.white,

                    fontSize:
                        15,

                  ),

                ),



                const SizedBox(height: 8),



                Text(

                  loadingSubtitle,


                  style: TextStyle(

                    color:
                        Colors.white.withValues(
                      alpha: .7,
                    ),

                  ),

                ),



                const SizedBox(height: 25),



                const SizedBox(

                  width: 180,


                  child: LinearProgressIndicator(

                    minHeight: 4,


                    backgroundColor:
                        Color(0xff183746),


                    valueColor:
                        AlwaysStoppedAnimation(
                      Color(0xffffd36a),
                    ),

                  ),

                ),



              ],

            );

          },

        ),

      ),

    );

  
  }
} 
  // ==========================================================
  // MAP PAGE BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Directionality(

      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,


      child: Scaffold(

        backgroundColor:
            const Color(0xff071722),


        appBar: AppBar(

          backgroundColor:
              const Color(0xff071722),


          foregroundColor:
              Colors.white,


          title: Text(

            AppText.map(),


            style: const TextStyle(

              fontWeight:
                  FontWeight.bold,

            ),

          ),


          centerTitle:
              true,

        ),



        body: Stack(

          children: [


            Column(

              children: [


                Expanded(

                  child: Stack(

                    children: [



                      FlutterMap(

                        mapController:
                            mapController,


                        options:
                            const MapOptions(

                          initialCenter:
                              iranCenter,


                          initialZoom:
                              5,

                        ),



                        children: [


                          TileLayer(

                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',


                            userAgentPackageName:
                                'cyrustourist.ir.app',

                          ),



                          MarkerLayer(

                            markers:
                                markers(),

                          ),


                        ],


                      ),




                      // دکمه موقعیت من

                      Positioned(

                        right:
                            15,


                        bottom:
                            15,


                        child: FloatingActionButton(

                          backgroundColor:
                              Colors.white,


                          onPressed:
                              getLocation,


                          child:

                              loading

                                  ? const SizedBox(

                                      width:
                                          24,

                                      height:
                                          24,


                                      child:
                                          CircularProgressIndicator(

                                        strokeWidth:
                                            2,

                                      ),

                                    )


                                  : const Icon(

                                      Icons.my_location,

                                    ),


                        ),

                      ),




                      // پیام بررسی موقعیت

                      if (loading && mapReady)

                        Positioned(

                          top:
                              15,


                          left:
                              15,


                          right:
                              15,


                          child: Center(

                            child: Container(

                              padding:
                                  const EdgeInsets.symmetric(

                                horizontal:
                                    16,

                                vertical:
                                    10,

                              ),


                              decoration:
                                  BoxDecoration(

                                color:
                                    const Color(0xff071722)
                                        .withValues(
                                      alpha:
                                          .9,
                                    ),


                                borderRadius:
                                    BorderRadius.circular(
                                  25,
                                ),


                              ),


                              child: Row(

                                mainAxisSize:
                                    MainAxisSize.min,


                                children: [


                                  const SizedBox(

                                    width:
                                        16,

                                    height:
                                        16,


                                    child:
                                        CircularProgressIndicator(

                                      strokeWidth:
                                          2,


                                      color:
                                          Color(0xffffd36a),

                                    ),

                                  ),


                                  const SizedBox(
                                    width:
                                        10,
                                  ),


                                  Text(

                                    locationText,


                                    style:
                                        const TextStyle(

                                      color:
                                          Colors.white,

                                      fontSize:
                                          12,

                                    ),

                                  ),


                                ],


                              ),


                            ),

                          ),

                        ),



                    ],


                  ),


                ),



                // نوار خدمات نقشه

                mapTools(),


              ],


            ),



            if (!mapReady)

              Positioned.fill(

                child:
                    loadingScreen(),

              ),


          ],

        ),


      ),

    );

  }
    // ==========================================================
  // MAP TOOLS
  // ==========================================================

  Widget mapTools() {

    return Container(

      padding:
          const EdgeInsets.all(10),


      color:
          const Color(0xff071722),


      child: Column(

        children: [


          Row(

            children: [


              mapServiceButton(
                Icons.hotel,
                LanguageManager.current ==
                        AppLanguage.persian
                    ? 'اقامتگاه'
                    : LanguageManager.current ==
                            AppLanguage.arabic
                        ? 'الإقامة'
                        : 'Accommodation',
              ),



              mapServiceButton(
                Icons.place,
                LanguageManager.current ==
                        AppLanguage.persian
                    ? 'جاذبه‌ها'
                    : LanguageManager.current ==
                            AppLanguage.arabic
                        ? 'المعالم'
                        : 'Attractions',
              ),



              mapServiceButton(
                Icons.health_and_safety,
                LanguageManager.current ==
                        AppLanguage.persian
                    ? 'سلامت'
                    : LanguageManager.current ==
                            AppLanguage.arabic
                        ? 'الصحة'
                        : 'Health',
              ),



              mapServiceButton(
                Icons.miscellaneous_services,
                LanguageManager.current ==
                        AppLanguage.persian
                    ? 'خدمات'
                    : LanguageManager.current ==
                            AppLanguage.arabic
                        ? 'الخدمات'
                        : 'Services',
              ),


            ],

          ),



          const SizedBox(
            height: 10,
          ),



          SizedBox(

            width:
                double.infinity,


            child: ElevatedButton(

              onPressed: () {

                Navigator.pop(context);

              },


              child: Text(

                '↪️ ${AppText.title()}',

              ),

            ),

          ),


        ],

      ),

    );

  }




  // ==========================================================
  // MAP SERVICE BUTTON
  // ==========================================================

  Widget mapServiceButton(

    IconData icon,

    String text,

  ) {


    return Expanded(

      child: Container(

        margin:
            const EdgeInsets.all(4),


        height:
            70,


        decoration:
            BoxDecoration(

          color:
              Colors.white,


          borderRadius:
              BorderRadius.circular(15),


          boxShadow: [

            BoxShadow(

              color:
                  Colors.black.withValues(
                    alpha: .30,
                  ),

              blurRadius:
                  8,


              offset:
                  const Offset(
                    0,
                    3,
                  ),

            ),

          ],

        ),



        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [


            Icon(

              icon,


              color:
                  const Color(0xff0b506b),

            ),



            const SizedBox(
              height: 4,
            ),



            Text(

              text,


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


          ],


        ),


      ),

    );

  }

}
