import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../map_place.dart';

import '../../services/map_smart_controller.dart';

import '../../widgets/map_markers_layer.dart';
import '../../widgets/map_search_bar.dart';
import '../../widgets/map_place_bottom_sheet.dart';



class SmartMapScreen extends StatefulWidget {

  const SmartMapScreen({
    super.key,
  });


  @override
  State<SmartMapScreen> createState() =>
      _SmartMapScreenState();

}




class _SmartMapScreenState
    extends State<SmartMapScreen> {


  final MapController mapController =
      MapController();



  final MapSmartController controller =
      MapSmartController();




  LatLng defaultLocation =
      const LatLng(
        35.6892,
        51.3890,
      );




  @override
  void initState() {

    super.initState();


    controller.addListener(
      _refresh,
    );


    controller.initializeLocation();

  }





  void _refresh() {


    if(!mounted) return;


    setState(() {});


    if(controller.userLocation != null){

      mapController.move(

        controller.userLocation!,

        14,

      );

    }

  }





  @override
  void dispose() {

    controller.removeListener(
      _refresh,
    );


    controller.dispose();


    super.dispose();

  }





  Future<void> search(
    String text,
  ) async {


    await controller.search(

      query: text,

    );



    if(controller.nearestPlace != null){


      mapController.move(

        controller.nearestPlace!.location,

        15,

      );


    }


  }





  void showPlace(
    MapPlace place,
  ){


    showModalBottomSheet(

      context: context,


      isScrollControlled: true,


      builder: (_) {


        return MapPlaceBottomSheet(

          place: place,

        );


      },


    );


  }







  @override
  Widget build(
    BuildContext context,
  ){


    final center =
        controller.userLocation ??
        defaultLocation;




    return Scaffold(


      body: Stack(


        children: [



          FlutterMap(


            mapController:
                mapController,



            options: MapOptions(


              initialCenter:
                  center,



              initialZoom:
                  13,


            ),




            children: [




              TileLayer(


                urlTemplate:

                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',



                userAgentPackageName:

                'ir.cyrustourist.app',



              ),





              MapMarkersLayer(


                places:

                controller.visiblePlaces,



                onTap:

                showPlace,



              ),



            ],



          ),







          Positioned(


            top: 45,


            left: 15,


            right: 15,



            child:


            MapSearchBar(


              onSearch:

              search,



            ),



          ),








          if(controller.isLoading ||
              controller.isLocationLoading)



            const Center(


              child:


              CircularProgressIndicator(),


            ),







          if(controller.errorMessage != null)


            Positioned(


              top: 110,


              left: 20,


              right: 20,



              child:


              Card(


                child:


                Padding(


                  padding:
                      const EdgeInsets.all(12),



                  child:


                  Text(

                    controller.errorMessage!,

                    textAlign:
                        TextAlign.center,


                  ),



                ),



              ),



            ),







          Positioned(


            bottom: 25,


            right: 20,



            child:


            FloatingActionButton(


              child:


              const Icon(

                Icons.my_location,

              ),



              onPressed: (){



                if(controller.userLocation != null){



                  mapController.move(


                    controller.userLocation!,


                    15,



                  );



                }



              },


            ),



          ),




        ],


      ),


    );

  }



}
