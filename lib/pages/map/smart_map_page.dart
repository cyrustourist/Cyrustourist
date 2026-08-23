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
  bool gpsEnabled = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
    });
  }

  // ----------------------------------------------------------
  // LOCATION
  // ----------------------------------------------------------

  Future<void> getLocation() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        if (!mounted) return;

        setState(() {
          loading = false;
          gpsEnabled = false;
        });

        _showGpsWarning();
        return;
      }

      if (mounted) {
        setState(() {
          gpsEnabled = true;
        });
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        _showMessage(
          'دسترسی مکان فعال نیست',
          Icons.location_off,
        );

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        userLocation = point;
        loading = false;
      });

      mapController.move(
        point,
        15,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        'خطا در دریافت موقعیت',
        Icons.error_outline,
      );
    }
  }

  // ----------------------------------------------------------
  // GPS WARNING
  // ----------------------------------------------------------

  void _showGpsWarning() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xffB3261E),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.gps_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'GPS خاموش است. لطفاً مکان‌یابی گوشی را فعال کنید.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'تنظیمات',
          textColor: Colors.white,
          onPressed: () {
            Geolocator.openLocationSettings();
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MESSAGE
  // ----------------------------------------------------------

  void _showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xff102A38),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MARKERS
  // ----------------------------------------------------------

  List<Marker> markers() {
    if (userLocation == null) {
      return [];
    }

    return [
      Marker(
        point: userLocation!,
        width: 70,
        height: 70,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                Colors.blue.withValues(alpha: 0.18),
            border: Border.all(
              color:
                  Colors.blue.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    ];
  }

  // ----------------------------------------------------------
  // MAP CONTROLS
  // ----------------------------------------------------------

  void zoomIn() {
    final zoom =
        mapController.camera.zoom;

    mapController.move(
      mapController.camera.center,
      zoom + 1,
    );
  }

  void zoomOut() {
    final zoom =
        mapController.camera.zoom;

    mapController.move(
      mapController.camera.center,
      zoom - 1,
    );
  }

  void goNorth() {
    mapController.rotate(0);

    _showMessage(
      'نقشه به سمت شمال برگشت',
      Icons.explore,
    );
  }

  void goToMyLocation() {
    if (userLocation != null) {
      mapController.move(
        userLocation!,
        15,
      );
    } else {
      getLocation();
    }
  }

  // ----------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------

  void openSearch() {
    _showMessage(
      'جستجوی مبدأ و مقصد در مرحله بعد فعال می‌شود',
      Icons.search,
    );
  }

  // ----------------------------------------------------------
  // ROUTE
  // ----------------------------------------------------------

  void openRouting() {
    _showMessage(
      'مسیر‌یابی واقعی در مرحله بعد فعال می‌شود',
      Icons.alt_route,
    );
  }

  // ----------------------------------------------------------
  // 3D BUTTON
  // ----------------------------------------------------------

  Widget mapButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    double size = 52,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(17),
          onTap: onPressed,
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 160),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: active
                    ? const [
                        Color(0xff24C6DC),
                        Color(0xff1976D2),
                      ]
                    : const [
                        Color(0xffFFFFFF),
                        Color(0xffDCEAF0),
                      ],
              ),
              border: Border.all(
                color: active
                    ? Colors.white70
                    : Colors.white,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white54,
                  blurRadius: 3,
                  offset: Offset(-1, -2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: active
                  ? Colors.white
                  : const Color(0xff123746),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEARCH / ROUTE LARGE BUTTON
  // ----------------------------------------------------------

  Widget largeMapAction({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          height: 56,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: primary
                  ? const [
                      Color(0xff00B4DB),
                      Color(0xff0083B0),
                    ]
                  : const [
                      Colors.white,
                      Color(0xffE4EEF2),
                    ],
            ),
            border: Border.all(
              color: Colors.white70,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: primary
                    ? Colors.white
                    : const Color(0xff123746),
                size: 27,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: primary
                      ? Colors.white
                      : const Color(0xff123746),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppText.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            const Color(0xff071722),

        // ----------------------------------------------------
        // APP BAR
        // ----------------------------------------------------

        appBar: AppBar(
          backgroundColor:
              const Color(0xff071722),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          leading: Padding(
            padding:
                const EdgeInsets.all(8),
            child: mapButton(
              icon: Icons.arrow_back,
              tooltip:
                  'بازگشت به سایروس توریست',
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: 46,
            ),
          ),

          title: Column(
            children: [
              Text(
                AppText.map(),
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                'Cyrus Tourist',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // ----------------------------------------------------
        // BODY
        // ----------------------------------------------------

        body: Stack(
          children: [
            // MAP
            FlutterMap(
              mapController:
                  mapController,
              options: const MapOptions(
                initialCenter:
                    iranCenter,
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'cyrustourist.ir.app',
                ),
                MarkerLayer(
                  markers: markers(),
                ),
              ],
            ),

            // ------------------------------------------------
            // TOP SEARCH / ROUTE
            // ------------------------------------------------

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: largeMapAction(
                      icon: Icons.search,
                      title:
                          'جستجوی مبدأ و مقصد',
                      primary: true,
                      onPressed:
                          openSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  mapButton(
                    icon:
                        Icons.alt_route,
                    tooltip:
                        'مسیر‌یابی',
                    onPressed:
                        openRouting,
                  ),
                ],
              ),
            ),

            // ------------------------------------------------
            // GPS STATUS
            // ------------------------------------------------

            if (!gpsEnabled)
              Positioned(
                top: 88,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Geolocator
                        .openLocationSettings();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xffB3261E,
                      ).withValues(
                        alpha: 0.94,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black45,
                          blurRadius: 10,
                          offset:
                              Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.gps_off,
                          color:
                              Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'GPS خاموش است — برای مکان‌یابی لمس کنید',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ------------------------------------------------
            // RIGHT CONTROLS
            // ------------------------------------------------

            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  mapButton(
                    icon:
                        Icons.add,
                    tooltip: 'بزرگنمایی',
                    onPressed:
                        zoomIn,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  mapButton(
                    icon:
                        Icons.remove,
                    tooltip:
                        'کوچک‌نمایی',
                    onPressed:
                        zoomOut,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  mapButton(
                    icon:
                        Icons.explore,
                    tooltip:
                        'بازگشت به شمال',
                    onPressed:
                        goNorth,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  mapButton(
                    icon:
                        Icons.my_location,
                    tooltip:
                        'موقعیت من',
                    active:
                        userLocation !=
                            null,
                    onPressed:
                        goToMyLocation,
                  ),
                ],
              ),
            ),

            // ------------------------------------------------
            // LOADING
            // ------------------------------------------------

            if (loading)
              Positioned(
                bottom: 30,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xff071722,
                    ).withValues(
                      alpha: 0.92,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color:
                            Colors.black54,
                        blurRadius: 12,
                        offset:
                            Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'در حال مکان‌یابی...',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
