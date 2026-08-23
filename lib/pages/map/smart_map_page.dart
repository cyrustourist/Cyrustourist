import 'dart:convert';
import 'dart:io';

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
  LatLng? originLocation;
  LatLng? destinationLocation;

  String? originName;
  String? destinationName;

  bool loading = false;
  bool gpsEnabled = true;

  // ----------------------------------------------------------
  // INIT
  // ----------------------------------------------------------

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
          permission ==
              LocationPermission.deniedForever) {
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
        content: const Row(
          children: [
            Icon(
              Icons.gps_off,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
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
  // REAL OSM / NOMINATIM SEARCH
  // ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchPlaces(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': cleanQuery,
        'format': 'jsonv2',
        'limit': '6',
        'addressdetails': '1',
        'accept-language':
            AppText.rtl ? 'fa,en' : 'en,fa',
      },
    );

    final client = HttpClient();

    try {
      client.userAgent =
          'CyrusTourist/1.0 (cyrustourist.ir)';

      final request =
          await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response =
          await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Nominatim HTTP ${response.statusCode}',
        );
      }

      final body =
          await response.transform(
        utf8.decoder,
      ).join();

      final decoded =
          jsonDecode(body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item,
            ),
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // ----------------------------------------------------------
  // SEARCH PANEL
  // ----------------------------------------------------------

  void openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SearchPanel(
          initialOrigin:
              originName,
          initialDestination:
              destinationName,
          userLocation:
              userLocation,
          onOriginSelected:
              _selectOrigin,
          onDestinationSelected:
              _selectDestination,
          onClearOrigin:
              _clearOrigin,
          onClearDestination:
              _clearDestination,
          onSwap:
              _swapPlaces,
          searchPlaces:
              searchPlaces,
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SELECT ORIGIN
  // ----------------------------------------------------------

  void _selectOrigin(
    LatLng point,
    String name,
  ) {
    setState(() {
      originLocation = point;
      originName = name;
    });

    mapController.move(
      point,
      15,
    );
  }

  // ----------------------------------------------------------
  // SELECT DESTINATION
  // ----------------------------------------------------------

  void _selectDestination(
    LatLng point,
    String name,
  ) {
    setState(() {
      destinationLocation = point;
      destinationName = name;
    });

    mapController.move(
      point,
      15,
    );
  }

  // ----------------------------------------------------------
  // CURRENT LOCATION AS ORIGIN
  // ----------------------------------------------------------

  void useCurrentLocationAsOrigin() {
    if (userLocation == null) {
      getLocation();
      return;
    }

    setState(() {
      originLocation = userLocation;
      originName = 'موقعیت فعلی من';
    });

    mapController.move(
      userLocation!,
      15,
    );
  }

  // ----------------------------------------------------------
  // CLEAR ORIGIN
  // ----------------------------------------------------------

  void _clearOrigin() {
    setState(() {
      originLocation = null;
      originName = null;
    });
  }

  // ----------------------------------------------------------
  // CLEAR DESTINATION
  // ----------------------------------------------------------

  void _clearDestination() {
    setState(() {
      destinationLocation = null;
      destinationName = null;
    });
  }

  // ----------------------------------------------------------
  // SWAP
  // ----------------------------------------------------------

  void _swapPlaces() {
    setState(() {
      final oldOrigin =
          originLocation;

      originLocation =
          destinationLocation;

      destinationLocation =
          oldOrigin;

      final oldOriginName =
          originName;

      originName =
          destinationName;

      destinationName =
          oldOriginName;
    });

    if (originLocation != null) {
      mapController.move(
        originLocation!,
        15,
      );
    }
  }

  // ----------------------------------------------------------
  // ZOOM
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

  // ----------------------------------------------------------
  // NORTH
  // ----------------------------------------------------------

  void goNorth() {
    mapController.rotate(0);

    _showMessage(
      'نقشه به سمت شمال برگشت',
      Icons.explore,
    );
  }

  // ----------------------------------------------------------
  // MY LOCATION
  // ----------------------------------------------------------

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
  // ROUTING PLACEHOLDER
  // ----------------------------------------------------------

  void openRouting() {
    if (originLocation == null ||
        destinationLocation == null) {
      openSearch();
      return;
    }

    _showMessage(
      'مبدأ و مقصد انتخاب شده‌اند؛ مسیر‌یابی واقعی در مرحله بعد فعال می‌شود.',
      Icons.alt_route,
    );
  }

  // ----------------------------------------------------------
  // MARKERS
  // ----------------------------------------------------------

  List<Marker> markers() {
    final List<Marker> result = [];

    if (userLocation != null) {
      result.add(
        Marker(
          point: userLocation!,
          width: 70,
          height: 70,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  Colors.blue.withValues(
                alpha: 0.18,
              ),
              border: Border.all(
                color:
                    Colors.blue.withValues(
                  alpha: 0.35,
                ),
                width: 2,
              ),
            ),
            child: Container(
              margin:
                  const EdgeInsets.all(12),
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
      );
    }

    if (originLocation != null) {
      result.add(
        Marker(
          point: originLocation!,
          width: 58,
          height: 70,
          child: _placeMarker(
            color:
                const Color(0xff1976D2),
            icon:
                Icons.trip_origin,
            label: 'مبدأ',
          ),
        ),
      );
    }

    if (destinationLocation != null) {
      result.add(
        Marker(
          point: destinationLocation!,
          width: 58,
          height: 70,
          child: _placeMarker(
            color:
                const Color(0xffE53935),
            icon:
                Icons.location_on,
            label: 'مقصد',
          ),
        ),
      );
    }

    return result;
  }

  Widget _placeMarker({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 25,
          ),
        ),
        Container(
          margin:
              const EdgeInsets.only(top: 2),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 3D SMALL BUTTON
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
                const Duration(
              milliseconds: 160,
            ),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:
                    Alignment.bottomRight,
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
                  offset:
                      Offset(-1, -2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: active
                  ? Colors.white
                  : const Color(
                      0xff123746,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // LARGE SEARCH BUTTON
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
              end:
                  Alignment.bottomRight,
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
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: primary
                    ? Colors.white
                    : const Color(
                        0xff123746,
                      ),
                size: 27,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary
                        ? Colors.white
                        : const Color(
                            0xff123746,
                          ),
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
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
        body: Stack(
          children: [
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

            // TOP SEARCH
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
                  const SizedBox(
                    width: 10,
                  ),
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

            // GPS STATUS
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

            // RIGHT CONTROLS
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  mapButton(
                    icon: Icons.add,
                    tooltip:
                        'بزرگنمایی',
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

            // LOADING
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

// ============================================================
// SEARCH PANEL
// ============================================================

class _SearchPanel extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;

  final LatLng? userLocation;

  final void Function(
    LatLng point,
    String name,
  ) onOriginSelected;

  final void Function(
    LatLng point,
    String name,
  ) onDestinationSelected;

  final VoidCallback onClearOrigin;
  final VoidCallback onClearDestination;
  final VoidCallback onSwap;

  final Future<List<Map<String, dynamic>>> Function(
    String query,
  ) searchPlaces;

  const _SearchPanel({
    required this.initialOrigin,
    required this.initialDestination,
    required this.userLocation,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onClearOrigin,
    required this.onClearDestination,
    required this.onSwap,
    required this.searchPlaces,
  });

  @override
  State<_SearchPanel> createState() =>
      _SearchPanelState();
}

class _SearchPanelState
    extends State<_SearchPanel> {
  final TextEditingController originController =
      TextEditingController();

  final TextEditingController destinationController =
      TextEditingController();

  bool originMode = true;
  bool searching = false;

  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();

    originController.text =
        widget.initialOrigin ?? '';

    destinationController.text =
        widget.initialDestination ?? '';
  }

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------

  Future<void> performSearch(
    String query,
  ) async {
    if (query.trim().length < 2) {
      setState(() {
        results = [];
      });
      return;
    }

    setState(() {
      searching = true;
      results = [];
    });

    try {
      final data =
          await widget.searchPlaces(
        query,
      );

      if (!mounted) return;

      setState(() {
        results = data;
        searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        searching = false;
        results = [];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'جستجوی مکان انجام نشد. اتصال اینترنت را بررسی کنید.',
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // SELECT RESULT
  // ----------------------------------------------------------

  void selectResult(
    Map<String, dynamic> result,
  ) {
    final lat =
        double.tryParse(
      result['lat']?.toString() ?? '',
    );

    final lon =
        double.tryParse(
      result['lon']?.toString() ?? '',
    );

    final name =
        result['display_name']
                ?.toString() ??
            'مکان انتخاب‌شده';

    if (lat == null || lon == null) {
      return;
    }

    final point =
        LatLng(lat, lon);

    if (originMode) {
      widget.onOriginSelected(
        point,
        name,
      );

      originController.text =
          name;
    } else {
      widget.onDestinationSelected(
        point,
        name,
      );

      destinationController.text =
          name;
    }

    setState(() {
      results = [];
    });
  }

  // ----------------------------------------------------------
  // CURRENT LOCATION
  // ----------------------------------------------------------

  void useCurrentLocation() {
    if (widget.userLocation == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'ابتدا باید موقعیت فعلی دریافت شود.',
          ),
        ),
      );
      return;
    }

    widget.onOriginSelected(
      widget.userLocation!,
      'موقعیت فعلی من',
    );

    originController.text =
        'موقعیت فعلی من';

    setState(() {
      originMode = true;
      results = [];
    });
  }

  // ----------------------------------------------------------
  // FIELD
  // ----------------------------------------------------------

  Widget searchField({
    required bool origin,
  }) {
    final controller =
        origin
            ? originController
            : destinationController;

    final color = origin
        ? const Color(0xff1976D2)
        : const Color(0xffE53935);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction:
            TextInputAction.search,
        onTap: () {
          setState(() {
            originMode = origin;
          });
        },
        onSubmitted:
            performSearch,
        decoration:
            InputDecoration(
          prefixIcon: Icon(
            origin
                ? Icons.trip_origin
                : Icons.location_on,
            color: color,
          ),
          suffixIcon: controller
                  .text
                  .isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    controller.clear();

                    if (origin) {
                      widget
                          .onClearOrigin();
                    } else {
                      widget
                          .onClearDestination();
                    }

                    setState(() {
                      results = [];
                    });
                  },
                )
              : null,
          hintText: origin
              ? 'جستجوی مبدأ...'
              : 'جستجوی مقصد...',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // RESULT ITEM
  // ----------------------------------------------------------

  Widget resultItem(
    Map<String, dynamic> result,
  ) {
    final name =
        result['display_name']
                ?.toString() ??
            '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),
        onTap: () {
          selectResult(result);
        },
        child: Container(
          margin:
              const EdgeInsets.only(
            bottom: 8,
          ),
          padding:
              const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                const Color(0xffF4F8FA),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color:
                  Colors.blueGrey.shade100,
            ),
          ),
          child: Row(
            children: [
              Icon(
                originMode
                    ? Icons.trip_origin
                    : Icons.location_on,
                color: originMode
                    ? const Color(
                        0xff1976D2,
                      )
                    : const Color(
                        0xffE53935,
                      ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xff18343F),
                  ),
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
    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Padding(
      padding:
          EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 650,
        ),
        decoration: const BoxDecoration(
          color: Color(0xff071722),
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const SizedBox(
                height: 10,
              ),

              // HANDLE
              Container(
                width: 45,
                height: 5,
                decoration:
                    BoxDecoration(
                  color: Colors.white38,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // TITLE
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 27,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'جستجوی مبدأ و مقصد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ORIGIN
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                ),
                child: searchField(
                  origin: true,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // CURRENT LOCATION
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                ),
                child: Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        useCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color:
                          Color(0xff29B6F6),
                    ),
                    label: const Text(
                      'استفاده از موقعیت فعلی من',
                      style: TextStyle(
                        color:
                            Color(0xffB9E9FF),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              // SWAP
              IconButton(
                onPressed:
                    widget.onSwap,
                tooltip:
                    'تعویض مبدأ و مقصد',
                icon: const Icon(
                  Icons.swap_vert_circle,
                  color: Colors.white,
                  size: 35,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              // DESTINATION
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                ),
                child: searchField(
                  origin: false,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // SEARCH BUTTON
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        searching
                            ? null
                            : () {
                                final text =
                                    originMode
                                        ? originController
                                            .text
                                        : destinationController
                                            .text;

                                performSearch(
                                  text,
                                );
                              },
                    icon: searching
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.search,
                          ),
                    label: Text(
                      searching
                          ? 'در حال جستجو...'
                          : 'جستجوی مکان واقعی',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xff0083B0,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 8,
                      shadowColor:
                          Colors.black54,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // RESULTS
              if (results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    itemCount:
                        results.length,
                    itemBuilder:
                        (context, index) {
                      return resultItem(
                        results[index],
                      );
                    },
                  ),
                ),

              if (results.isEmpty &&
                  !searching)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: 18,
                  ),
                  child: Text(
                    'برای جستجو، نام شهر، خیابان یا مکان را وارد کنید.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
