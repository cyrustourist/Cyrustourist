import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'CyrusTourist',
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
      current = AppLanguage.persian;
    }

    else if (saved == 'ar') {
      current = AppLanguage.arabic;
    }

    else if (saved == 'en') {
      current = AppLanguage.english;
    }

    else {

      final code = WidgetsBinding
          .instance
          .platformDispatcher
          .locale
          .languageCode
          .toLowerCase();


      if (code == 'fa') {
        current = AppLanguage.persian;
      }

      else if (code == 'ar') {
        current = AppLanguage.arabic;
      }

      else {
        current = AppLanguage.english;
      }
    }
  }


  static Future<void> setLanguage(
      AppLanguage lang) async {

    current = lang;

    final pref =
        await SharedPreferences.getInstance();


    if (lang == AppLanguage.persian) {
      await pref.setString('language','fa');
    }

    else if (lang == AppLanguage.arabic) {
      await pref.setString('language','ar');
    }

    else {
      await pref.setString('language','en');
    }
  }
}



class AppText {


  static bool get rtl {

    return LanguageManager.current !=
        AppLanguage.english;

  }



  static String title() {

    switch(LanguageManager.current){

      case AppLanguage.persian:
        return 'سایروس توریست';

      case AppLanguage.arabic:
        return 'سايروس توريست';

      case AppLanguage.english:
        return 'Cyrus Tourist';

    }
  }



  static String map(){

    switch(LanguageManager.current){

      case AppLanguage.persian:
        return 'نقشه گردشگری';

      case AppLanguage.arabic:
        return 'خريطة السياحة';

      case AppLanguage.english:
        return 'Tourism Map';

    }
  }



  static String languageName(){

    switch(LanguageManager.current){

      case AppLanguage.persian:
        return 'پارسی';

      case AppLanguage.arabic:
        return 'العربية';

      case AppLanguage.english:
        return 'English';

    }
  }


}


// ============================================================
// SPLASH
// ============================================================


class SplashPage extends StatefulWidget {

  const SplashPage({super.key});


  @override
  State<SplashPage> createState() =>
      _SplashPageState();

}



class _SplashPageState
    extends State<SplashPage>{


  @override
  void initState(){

    super.initState();


    _start();

  }



  Future<void> _start() async {

    await LanguageManager.load();


    Timer(
      const Duration(seconds:2),

      (){

        if(!mounted)return;


        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder:(_)=>
              const HomePage(),
          ),
        );

      },

    );

  }



  @override
  Widget build(BuildContext context){

    return Scaffold(

      body:SizedBox.expand(

        child:Image.asset(

          'assets/images/splash.jpg',

          fit:BoxFit.cover,

        ),

      ),

    );

  }

}
// ============================================================
// HOME PAGE
// ORIGINAL IMAGE + TRANSPARENT TOUCH AREAS
// ============================================================

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();

}



class _HomePageState extends State<HomePage> {



  void openLanguage(){

    showModalBottomSheet(
      context: context,

      builder:(_){

        return Directionality(

          textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,

          child: Column(

            mainAxisSize:
            MainAxisSize.min,

            children:[


              ListTile(

                title:
                const Text('پارسی'),

                onTap:() async{

                  await LanguageManager
                      .setLanguage(
                    AppLanguage.persian,
                  );

                  setState((){});

                  Navigator.pop(context);

                },

              ),



              ListTile(

                title:
                const Text('English'),

                onTap:() async{

                  await LanguageManager
                      .setLanguage(
                    AppLanguage.english,
                  );

                  setState((){});

                  Navigator.pop(context);

                },

              ),



              ListTile(

                title:
                const Text('العربية'),

                onTap:() async{

                  await LanguageManager
                      .setLanguage(
                    AppLanguage.arabic,
                  );

                  setState((){});

                  Navigator.pop(context);

                },

              ),

            ],

          ),

        );

      },

    );

  }





  void serviceTap(int number){

    if(number == 1){

      Navigator.push(

        context,

        MaterialPageRoute(

          builder:(_)=>
          const SmartMapPage(),

        ),

      );

    }

    else {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:

          Text(
            'بخش $number در مرحله بعد فعال می‌شود',
          ),

        ),

      );

    }

  }





  Widget touchBox(
      int number,
      double left,
      double top,
      double width,
      double height,
      ){

    return Align(

      alignment: Alignment(
        -1 + (left + width / 2) * 2,
        -1 + (top + height / 2) * 2,
      ),

      child: FractionallySizedBox(

        widthFactor: width,
        heightFactor: height,

        child: GestureDetector(

          behavior: HitTestBehavior.translucent,

          onTap:(){

            serviceTap(number);

          },

          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Text(
              AppText.button(number),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),

        ),

      ),

    );

  }






  @override
  Widget build(BuildContext context){


    return Directionality(

      textDirection:
      AppText.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,


      child:Scaffold(


        backgroundColor:
        Colors.black,


        body:SafeArea(


          child:Center(


            child:AspectRatio(


              // نسبت عکس 9:16

              aspectRatio:
              9/16,


              child:Stack(


                fit:
                StackFit.expand,


                children:[



                  Image.asset(

                    'assets/images/home.jpg',

                    fit:
                    BoxFit.cover,

                  ),





                  // ------------------------------
                  // LANGUAGE BUTTON
                  // ------------------------------

                  Positioned(

                    left:18,

                    top:18,


                    child:
                    GestureDetector(

                      onTap:
                      openLanguage,


                      child:Container(

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:12,
                          vertical:8,
                        ),


                        decoration:
                        BoxDecoration(

                          color:
                          const Color(0xff0b506b),


                          borderRadius:
                          BorderRadius.circular(18),


                          boxShadow:[

                            BoxShadow(

                              color:
                              Colors.black
                                  .withValues(
                                alpha:0.5,
                              ),

                              blurRadius:8,

                              offset:
                              const Offset(0,4),

                            ),

                          ],

                        ),


                        child:Text(

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





                  // ==================================================
                  // TOUCH AREAS
                  // پایین عکس - ۱۰ کلید
                  // ==================================================


                  // ردیف اول

                  touchBox(
                    1,
                    0,
                    0.695,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    2,
                    0.20,
                    0.695,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    3,
                    0.40,
                    0.695,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    4,
                    0.60,
                    0.695,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    5,
                    0.80,
                    0.695,
                    0.20,
                    0.10,
                  ),



                  // ردیف دوم


                  touchBox(
                    6,
                    0,
                    0.805,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    7,
                    0.20,
                    0.805,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    8,
                    0.40,
                    0.805,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    9,
                    0.60,
                    0.805,
                    0.20,
                    0.10,
                  ),

                  touchBox(
                    10,
                    0.80,
                    0.805,
                    0.20,
                    0.10,
                  ),


                ],


              ),


            ),


          ),


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
  State<SmartMapPage> createState() =>
      _SmartMapPageState();

}




class _SmartMapPageState
    extends State<SmartMapPage>{


  final MapController mapController =
      MapController();



  static const LatLng iranCenter =
      LatLng(32.4279,53.6880);



  LatLng? userLocation;


  bool loading=false;



  @override
  void initState(){

    super.initState();


    WidgetsBinding.instance
        .addPostFrameCallback(
            (_){

          getLocation();

        });

  }




  Future<void> getLocation() async{


    setState((){

      loading=true;

    });



    try{


      bool enabled =
      await Geolocator
          .isLocationServiceEnabled();



      if(!enabled){

        setState((){

          loading=false;

        });

        return;

      }




      LocationPermission permission =
      await Geolocator.checkPermission();



      if(permission ==
          LocationPermission.denied){

        permission =
        await Geolocator.requestPermission();

      }



      if(permission ==
          LocationPermission.deniedForever){

        setState((){

          loading=false;

        });

        return;

      }




      final position =
      await Geolocator
          .getCurrentPosition();



      final point =
      LatLng(
        position.latitude,
        position.longitude,
      );



      setState((){

        userLocation=point;

        loading=false;

      });



      mapController.move(
        point,
        13,
      );



    }

    catch(e){

      setState((){

        loading=false;

      });

    }

  }






  List<Marker> markers(){


    final list=<Marker>[];



    if(userLocation!=null){


      list.add(

        Marker(

          point:userLocation!,


          width:60,

          height:60,


          child:

          Container(

            decoration:
            BoxDecoration(

              color:
              Colors.blue
                  .withValues(
                alpha:0.25,
              ),

              shape:
              BoxShape.circle,

            ),


            child:
            const Icon(

              Icons.my_location,

              color:
              Colors.blue,

              size:35,

            ),

          ),

        ),


      );


    }




    return list;

  }





  @override
  Widget build(BuildContext context){


    return Directionality(

      textDirection:
      AppText.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,


      child:Scaffold(


        backgroundColor:
        const Color(0xff071722),



        appBar:AppBar(

          backgroundColor:
          const Color(0xff071722),


          foregroundColor:
          Colors.white,


          title:
          Text(
            AppText.map(),
          ),

          centerTitle:true,

        ),




        body:Column(


          children:[



            Expanded(


              child:Stack(


                children:[



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



                    children:[



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




                  Positioned(

                    right:15,

                    bottom:15,


                    child:

                    FloatingActionButton(

                      backgroundColor:
                      Colors.white,


                      onPressed:
                      getLocation,


                      child:

                      loading

                          ?

                      const CircularProgressIndicator()

                          :

                      const Icon(
                        Icons.my_location,
                      ),


                    ),

                  ),



                ],


              ),


            ),




            // ------------------------------
            // SERVICES PANEL
            // ------------------------------


            Container(

              padding:
              const EdgeInsets.all(10),


              color:
              const Color(0xff071722),


              child:

              Column(

                children:[



                  Row(

                    children:[


                      serviceButton(
                        Icons.hotel,
                        'اقامتگاه',
                      ),



                      serviceButton(
                        Icons.place,
                        'جاذبه‌ها',
                      ),



                      serviceButton(
                        Icons.favorite,
                        'سلامت',
                      ),



                      serviceButton(
                        Icons.miscellaneous_services,
                        'خدمات',
                      ),


                    ],


                  ),



                  const SizedBox(height:10),



                  SizedBox(

                    width:
                    double.infinity,


                    child:
                    ElevatedButton(

                      onPressed:(){

                        Navigator.pop(context);

                      },


                      child:
                      Text(
                        AppText.title(),
                      ),

                    ),

                  ),



                ],


              ),


            ),



          ],


        ),


      ),


    );


  }





  Widget serviceButton(
      IconData icon,
      String text,
      ){

    return Expanded(


      child:

      Container(

        margin:
        const EdgeInsets.all(4),


        height:70,


        decoration:
        BoxDecoration(

          color:
          Colors.white,


          borderRadius:
          BorderRadius.circular(15),


        ),



        child:
        Column(

          mainAxisAlignment:
          MainAxisAlignment.center,


          children:[


            Icon(
              icon,
              color:
              const Color(0xff0b506b),
            ),



            Text(
              text,

              style:
              const TextStyle(
                fontSize:10,
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
