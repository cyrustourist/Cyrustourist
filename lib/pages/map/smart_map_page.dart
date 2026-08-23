import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/language/app_text.dart';

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() => _SmartMapPageState();
}

class _SmartMapPageState extends State<SmartMapPage> {
  final MapController mapController = MapController();

  static const LatLng iranCenter = LatLng(
    32.4279,
    53.6880,
  );

  LatLng? userLocation;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
    });
  }

  Future<void> getLocation() async {
    setState(() {
      loading = true;
    });

    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        setState(() {
          loading = false;
        });

        _showMessage(
          'GPS خاموش است',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        setState(() {
          loading = false;
        });

        _showMessage(
          'دسترسی مکان فعال نیست',
        );

        return;
      }

      final position =
          await Geolocator.getCurrentPosition();

      final point = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        userLocation = point;
        loading = false;
      });

      mapController.move(
        point,
        14,
      );

    } catch (e) {
      setState(() {
        loading = false;
      });

      _showMessage(
        'خطا در دریافت موقعیت',
      );
    }
  }


  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }


  List<Marker> markers() {

    if (userLocation == null) {
      return [];
    }

    return [
      Marker(
        point: userLocation!,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 35,
          ),
        ),
      ),
    ];
  }


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
          ),

          centerTitle: true,
        ),


        body: Stack(

          children: [

            FlutterMap(

              mapController:
                  mapController,

              options: const MapOptions(

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


            Positioned(

              right: 20,

              bottom: 20,

              child: FloatingActionButton(

                backgroundColor:
                    Colors.white,

                onPressed:
                    getLocation,


                child:

                    loading

                    ? const SizedBox(

                        width:25,
                        height:25,

                        child:
                        CircularProgressIndicator(),

                      )

                    : const Icon(
                        Icons.my_location,
                      ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}
