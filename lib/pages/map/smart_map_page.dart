import 'dart:convert';
import 'dart:io';

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
  State<SmartMapScreen> createState() => _SmartMapScreenState();
}

class _SmartMapScreenState extends State<SmartMapScreen> {
  final MapController mapController = MapController();

  final TextEditingController searchTextController =
      TextEditingController();

  late final MapSmartController controller;

  // ------------------------------------------------------------
  // MAP / ROUTE
  // ------------------------------------------------------------

  List<LatLng> routePoints = [];

  MapPlace? selectedDestination;

  LatLng? originLocation;
  String? originName;

  LatLng? destinationLocation;
  String? destinationName;

  bool originMode = false;
  bool routeLoading = false;
  bool searching = false;

  double? routeDistanceKm;
  double? routeDurationMin;

  String selectedLanguage = 'fa';

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    controller = MapSmartController();

    _detectDeviceLanguage();
    _initialize();
  }

  void _detectDeviceLanguage() {
    final language =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    if (language == 'en') {
      selectedLanguage = 'en';
    } else if (language == 'ar') {
      selectedLanguage = 'ar';
    } else {
      selectedLanguage = 'fa';
    }
  }

  Future<void> _initialize() async {
    await controller.initializeLocation();

    if (!mounted) return;

    final location = controller.userLocation;

    if (location != null) {
      originLocation = location;
      originName = _text(
        'موقعیت فعلی من',
        'My current location',
        'موقعي الحالي',
      );

      mapController.move(
        location,
        14,
      );
    }

    setState(() {});
  }

  // ------------------------------------------------------------
  // TRANSLATION
  // ------------------------------------------------------------

  String _text(
    String fa,
    String en,
    String ar,
  ) {
    switch (selectedLanguage) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Future<void> search(String text) async {
    final query = text.trim();

    if (query.length < 2) {
      _showMessage(
        _text(
          'حداقل دو حرف وارد کنید.',
          'Enter at least two characters.',
          'أدخل حرفين على الأقل.',
        ),
      );
      return;
    }

    if (searching) return;

    setState(() {
      searching = true;
    });

    try {
      await controller.search(
        query: query,
      );

      if (!mounted) return;

      final place = controller.nearestPlace;

      if (place == null) {
        setState(() {
          searching = false;
        });

        _showMessage(
          _text(
            'مکانی پیدا نشد.',
            'No place was found.',
            'لم يتم العثور على المكان.',
          ),
        );

        return;
      }

      if (originMode) {
        _setOrigin(
          place.location,
          place.name,
        );
      } else {
        _setDestination(
          place.location,
          place.name,
          place,
        );
      }

      setState(() {
        searching = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        searching = false;
      });

      _showMessage(
        _text(
          'جستجو انجام نشد. اتصال اینترنت را بررسی کنید.',
          'Search failed. Check your internet connection.',
          'فشل البحث. تحقق من اتصال الإنترنت.',
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // ORIGIN
  // ------------------------------------------------------------

  void _setOrigin(
    LatLng point,
    String name,
  ) {
    setState(() {
      originLocation = point;
      originName = name;

      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });

    mapController.move(
      point,
      15,
    );

    _showMessage(
      _text(
        'مبدأ انتخاب شد.',
        'Origin selected.',
        'تم اختيار نقطة البداية.',
      ),
    );
  }

  void useCurrentLocationAsOrigin() {
    final location = controller.userLocation;

    if (location == null) {
      _initialize();
      return;
    }

    _setOrigin(
      location,
      _text(
        'موقعیت فعلی من',
        'My current location',
        'موقعي الحالي',
      ),
    );
  }

  // ------------------------------------------------------------
  // DESTINATION
  // ------------------------------------------------------------

  void _setDestination(
    LatLng point,
    String name,
    MapPlace place,
  ) {
    setState(() {
      destinationLocation = point;
      destinationName = name;
      selectedDestination = place;

      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });

    mapController.move(
      point,
      15,
    );

    _showMessage(
      _text(
        'مقصد انتخاب شد؛ حالا مسیریابی را بزنید.',
        'Destination selected; press Route to navigate.',
        'تم اختيار الوجهة؛ اضغط على المسار.',
      ),
    );
  }

  // ------------------------------------------------------------
  // SWAP
  // ------------------------------------------------------------

  void _swapPlaces() {
    final oldOrigin = originLocation;
    final oldOriginName = originName;

    setState(() {
      originLocation = destinationLocation;
      originName = destinationName;

      destinationLocation = oldOrigin;
      destinationName = oldOriginName;

      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });

    if (originLocation != null) {
      mapController.move(
        originLocation!,
        15,
      );
    }

    _showMessage(
      _text(
        'مبدأ و مقصد تعویض شدند.',
        'Origin and destination swapped.',
        'تم تبديل البداية والوجهة.',
      ),
    );
  }

  // ------------------------------------------------------------
  // ROUTING
  // ------------------------------------------------------------

  Future<void> buildRoute() async {
    if (originLocation == null) {
      useCurrentLocationAsOrigin();

      if (originLocation == null) {
        _showMessage(
          _text(
            'ابتدا مبدأ را مشخص کنید.',
            'Please select an origin first.',
            'حدد نقطة البداية أولاً.',
          ),
        );
        return;
      }
    }

    if (destinationLocation == null) {
      _showMessage(
        _text(
          'ابتدا مقصد را انتخاب کنید.',
          'Please select a destination first.',
          'حدد الوجهة أولاً.',
        ),
      );

      return;
    }

    if (routeLoading) return;

    setState(() {
      routeLoading = true;
    });

    final start = originLocation!;
    final destination = destinationLocation!;

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    final client = HttpClient();

    try {
      client.userAgent =
          'CyrusTourist/1.0 (cyrustourist.ir)';

      final request = await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close();

      final body =
          await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'OSRM HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(body);

      if (data is! Map ||
          data['code'] != 'Ok' ||
          data['routes'] is! List ||
          (data['routes'] as List).isEmpty) {
        throw Exception('No route');
      }

      final route =
          (data['routes'] as List).first;

      final geometry = route['geometry'];

      if (geometry is! Map ||
          geometry['coordinates'] is! List) {
        throw Exception(
          'Invalid route geometry',
        );
      }

      final coordinates =
          geometry['coordinates'] as List;

      final points = <LatLng>[];

      for (final coordinate in coordinates) {
        if (coordinate is! List ||
            coordinate.length < 2) {
          continue;
        }

        final longitude =
            double.tryParse(
          coordinate[0].toString(),
        );

        final latitude =
            double.tryParse(
          coordinate[1].toString(),
        );

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        points.add(
          LatLng(
            latitude,
            longitude,
          ),
        );
      }

      if (points.length < 2) {
        throw Exception(
          'Route geometry is empty',
        );
      }

      final distanceMeters =
          (route['distance'] as num?)
                  ?.toDouble() ??
              0;

      final durationSeconds =
          (route['duration'] as num?)
                  ?.toDouble() ??
              0;

      if (!mounted) return;

      setState(() {
        routePoints = points;
        routeDistanceKm =
            distanceMeters / 1000;
        routeDurationMin =
            durationSeconds / 60;
        routeLoading = false;
      });

      _fitRoute(points);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        routeLoading = false;
        routePoints = [];
        routeDistanceKm = null;
        routeDurationMin = null;
      });

      _showMessage(
        _text(
          'مسیریابی انجام نشد. اتصال اینترنت را بررسی کنید.',
          'Route could not be calculated. Check your internet connection.',
          'تعذر حساب المسار. تحقق من اتصال الإنترنت.',
        ),
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  // ------------------------------------------------------------
  // FIT ROUTE
  // ------------------------------------------------------------

  void _fitRoute(
    List<LatLng> points,
  ) {
    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
        maxZoom: 15,
      ),
    );
  }

  // ------------------------------------------------------------
  // CLEAR ROUTE
  // ------------------------------------------------------------

  void clearRoute() {
    setState(() {
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
  }

  // ------------------------------------------------------------
  // PLACE
  // ------------------------------------------------------------

  void showPlace(
    MapPlace place,
  ) {
    setState(() {
      selectedDestination = place;
      destinationLocation = place.location;
      destinationName = place.name;
    });

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

  // ------------------------------------------------------------
  // SEARCH MODE
  // ------------------------------------------------------------

  void _setSearchMode(
    bool origin,
  ) {
    setState(() {
      originMode = origin;
    });

    _showMessage(
      origin
          ? _text(
              'اکنون مبدأ را جستجو کنید.',
              'Now search for the origin.',
              'ابحث الآن عن نقطة البداية.',
            )
          : _text(
              'اکنون هدف سفر را جستجو کنید.',
              'Now search for the travel destination.',
              'ابحث الآن عن هدف السفر.',
            ),
    );
  }

  // ------------------------------------------------------------
  // LANGUAGE
  // ------------------------------------------------------------

  void _changeLanguage(
    String language,
  ) {
    setState(() {
      selectedLanguage = language;
    });
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      );
  }

  // ------------------------------------------------------------
  // BACK
  // ------------------------------------------------------------

  void _goBackToCyrusTourist() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------
  // ROUTE INFO
  // ------------------------------------------------------------

  String _distanceText() {
    final distance = routeDistanceKm;

    if (distance == null) {
      return '';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
  }

  String _durationText() {
    final duration = routeDurationMin;

    if (duration == null) {
      return '';
    }

    if (duration < 60) {
      return '${duration.round()} min';
    }

    final hours = duration ~/ 60;
    final minutes =
        (duration % 60).round();

    return '$hours h $minutes min';
  }

  // ------------------------------------------------------------
  // SEARCH HEADER
  // ------------------------------------------------------------

  Widget _searchModeButton({
    required bool origin,
  }) {
    final active = originMode == origin;

    return Expanded(
      child: Material(
        color: active
            ? const Color(0xff0083B0)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        elevation: 4,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(14),
          onTap: () {
            _setSearchMode(origin);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  origin
                      ? Icons.trip_origin
                      : Icons.location_on,
                  size: 19,
                  color: active
                      ? Colors.white
                      : origin
                          ? const Color(
                              0xff1976D2,
                            )
                          : const Color(
                              0xffE53935,
                            ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    origin
                        ? _text(
                            'جستجوی مبدأ',
                            'Search origin',
                            'بحث عن البداية',
                          )
                        : _text(
                            'جستجوی هدف سفر',
                            'Search destination',
                            'بحث عن الوجهة',
                          ),
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : const Color(
                              0xff18343F,
                            ),
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
    );
  }

  // ------------------------------------------------------------
  // ROUTE SUMMARY
  // ------------------------------------------------------------

  Widget _routeSummary() {
    if (routePoints.length < 2) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Card(
        elevation: 10,
        color: const Color(0xff071722),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.alt_route,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 5,
                  children: [
                    Text(
                      '${_text('مسافت', 'Distance', 'المسافة')}: '
                      '${_distanceText()}',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_text('زمان', 'Time', 'الوقت')}: '
                      '${_durationText()}',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: clearRoute,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final userLocation =
        controller.userLocation;

    final isRtl =
        selectedLanguage == 'fa' ||
        selectedLanguage == 'ar';

    return Directionality(
      textDirection: isRtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // --------------------------------------------------
            // MAP
            // --------------------------------------------------

            FlutterMap(
              mapController:
                  mapController,
              options: MapOptions(
                initialCenter:
                    userLocation ??
                    const LatLng(
                      35.6892,
                      51.3890,
                    ),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'ir.cyrustourist.app',
                ),

                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6,
                        color:
                            const Color(
                          0xff0083B0,
                        ),
                        borderStrokeWidth:
                            2,
                        borderColor:
                            Colors.white,
                      ),
                    ],
                  ),

                MapMarkersLayer(
                  places:
                      controller.visiblePlaces,
                  onTap: showPlace,
                ),
              ],
            ),

            // --------------------------------------------------
            // TOP PANEL
            // --------------------------------------------------

            Positioned(
              top: 42,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        elevation: 6,
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          onTap:
                              _goBackToCyrusTourist,
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons
                                      .arrow_back,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  _text(
                                    'سایروس توریست',
                                    'Cyrus Tourist',
                                    'سايروس توريست',
                                  ),
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: MapSearchBar(
                          controller: searchTextController,
                          onSearch: () => search(
                            searchTextController.text,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _searchModeButton(
                        origin: true,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      _searchModeButton(
                        origin: false,
                      ),
                      const SizedBox(
                        width: 8,
                      ),

                      PopupMenuButton<
                          String>(
                        initialValue:
                            selectedLanguage,
                        onSelected:
                            _changeLanguage,
                        itemBuilder:
                            (_) => const [
                          PopupMenuItem(
                            value: 'fa',
                            child:
                                Text(
                              'پارسی',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'en',
                            child:
                                Text(
                              'English',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ar',
                            child:
                                Text(
                              'العربية',
                            ),
                          ),
                        ],
                        child: Material(
                          elevation: 5,
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                          child:
                              const Padding(
                            padding:
                                EdgeInsets.all(
                              10,
                            ),
                            child: Icon(
                              Icons.language,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // CURRENT ROUTE FIELDS
                  Material(
                    elevation: 5,
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .trip_origin,
                                color:
                                    Color(
                                  0xff1976D2,
                                ),
                                size: 20,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Text(
                                  originName ??
                                      _text(
                                        'مبدأ: موقعیت من',
                                        'Origin: My location',
                                        'البداية: موقعي',
                                      ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    _text(
                                  'موقعیت من',
                                  'My location',
                                  'موقعي',
                                ),
                                onPressed:
                                    useCurrentLocationAsOrigin,
                                icon:
                                    const Icon(
                                  Icons
                                      .my_location,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          const Divider(
                            height: 8,
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .location_on,
                                color:
                                    Color(
                                  0xffE53935,
                                ),
                                size: 22,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Text(
                                  destinationName ??
                                      _text(
                                        'مقصد: هنوز انتخاب نشده',
                                        'Destination: Not selected',
                                        'الوجهة: لم يتم اختيارها',
                                      ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      _swapPlaces,
                                  icon:
                                      const Icon(
                                    Icons
                                        .swap_vert,
                                  ),
                                  label:
                                      Text(
                                    _text(
                                      'تعویض',
                                      'Swap',
                                      'تبديل',
                                    ),
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xffEAF3F7,
                                    ),
                                    foregroundColor:
                                        const Color(
                                      0xff123746,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                flex: 2,
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      routeLoading
                                          ? null
                                          : buildRoute,
                                  icon:
                                      const Icon(
                                    Icons
                                        .directions,
                                  ),
                                  label:
                                      Text(
                                    _text(
                                      'مسیریابی',
                                      'Route',
                                      'المسار',
                                    ),
                                  ),
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xff0083B0,
                                    ),
                                    foregroundColor:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // LOADING SEARCH / LOCATION
            // --------------------------------------------------

            if (controller.isLoading ||
                controller.isLocationLoading ||
                searching)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black
                        .withValues(
                      alpha: 0.08,
                    ),
                    alignment:
                        Alignment.center,
                    child: Card(
                      elevation: 8,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(18),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              searching
                                  ? _text(
                                      'در حال جستجوی هدف سفر...',
                                      'Searching for travel destination...',
                                      'جارٍ البحث عن هدف السفر...',
                                    )
                                  : _text(
                                      'در حال دریافت موقعیت...',
                                      'Getting your location...',
                                      'جارٍ تحديد موقعك...',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // --------------------------------------------------
            // ROUTING LOADING
            // --------------------------------------------------

            if (routeLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black
                        .withValues(
                      alpha: 0.10,
                    ),
                    alignment:
                        Alignment.center,
                    child: Card(
                      elevation: 8,
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(20),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              _text(
                                'در حال محاسبه مسیر...',
                                'Calculating route...',
                                'جارٍ حساب المسار...',
                              ),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // --------------------------------------------------
            // ERROR
            // --------------------------------------------------

            if (controller.errorMessage !=
                null)
              Positioned(
                top: 210,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 7,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(12),
                    child: Text(
                      controller.errorMessage!,
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                ),
              ),

            // --------------------------------------------------
            // ROUTE SUMMARY
            // --------------------------------------------------

            if (routePoints.length >= 2)
              _routeSummary(),

            // --------------------------------------------------
            // MY LOCATION
            // --------------------------------------------------

            Positioned(
              bottom:
                  routePoints.length >= 2
                      ? 105
                      : 25,
              right: 20,
              child:
                  FloatingActionButton(
                heroTag:
                    'my_location_smart_map',
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(
                  0xff123746,
                ),
                onPressed:
                    useCurrentLocationAsOrigin,
                child: const Icon(
                  Icons.my_location,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    controller.dispose();
    searchTextController.dispose();
    super.dispose();
  }
}
