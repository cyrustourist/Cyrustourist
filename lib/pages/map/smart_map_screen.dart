import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../map_place.dart';
import '../../services/location_service.dart';
import '../../services/map_places_service.dart';

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


  final MapPlacesService placesService =
      MapPlacesService();


  LatLng userLocation =
      const LatLng(
        35.6892,
        51.3890,
      );


  List<MapPlace> places = [];


  bool loading = false;



  @override
  void initState() {

    super.initState();

    _loadLocation();

  }




  Future<void> _loadLocation() async {

    final location =
        await LocationService()
            .getCurrentLocation();


    if(location != null){

      setState(() {

        userLocation = location;

      });


      mapController.move(
        location,
        14,
      );

    }

  }




  Future<void> search(
      String text,
  ) async {


    if(text.trim().isEmpty){
      return;
    }


    setState(() {

      loading = true;

    });



    final result =
        await placesService.searchPlaces(

      query: text,

      userLocation:
          userLocation,

    );



    setState(() {

      places = result;

      loading = false;

    });


    if(result.isNotEmpty){

      mapController.move(
        result.first.location,
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


    return Scaffold(


      body: Stack(


        children: [


          FlutterMap(

            mapController:
                mapController,


            options: MapOptions(

              initialCenter:
                  userLocation,


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
                    places,


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




          if(loading)

            const Center(

              child:

              CircularProgressIndicator(),

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


                mapController.move(

                  userLocation,

                  15,

                );


              },

            ),

          ),



        ],


      ),


    );

  }


}
