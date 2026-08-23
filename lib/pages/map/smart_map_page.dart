import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


enum MapLanguage { fa, en, ar }

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
  MapLanguage pageLanguage = MapLanguage.fa;
  List<LatLng> routePoints = [];
  double? routeDistanceKm;
  double? routeDurationMin;
  bool routingLoading = false;

  // ----------------------------------------------------------
  // INIT
  // ----------------------------------------------------------

  bool get isRtl =>
      pageLanguage == MapLanguage.fa || pageLanguage == MapLanguage.ar;

  String get _nominatimLanguage {
    switch (pageLanguage) {
      case MapLanguage.en:
        return 'en';
      case MapLanguage.ar:
        return 'ar,en';
      case MapLanguage.fa:
        return 'fa,en';
    }
  }

  String tr(String fa, String en, String ar) {
    switch (pageLanguage) {
      case MapLanguage.en:
        return en;
      case MapLanguage.ar:
        return ar;
      case MapLanguage.fa:
        return fa;
    }
  }

  String get mapTitle => tr('نقشه گردشگری', 'Tourism Map', 'الخريطة السياحية');
  String get searchTitle => tr('جستجوی مبدأ و مقصد', 'Search origin & destination', 'بحث عن البداية والوجهة');
  String get routeTitle => tr('مسیر‌یابی', 'Route', 'المسار');
  String get clearRouteTitle => tr('پاک کردن مسیر', 'Clear route', 'مسح المسار');
  String get gpsOffTitle => tr(gpsOffTitle, 'GPS is off — tap to enable location', 'GPS متوقف — اضغط لتفعيل الموقع');
  String get locatingTitle => tr('در حال مکان‌یابی...', 'Locating...', 'جارٍ تحديد الموقع...');
  String get currentLocationTitle => tr('موقعیت من', 'My location', 'موقعي');
  String get northTitle => tr('بازگشت به شمال', 'North', 'الشمال');
  String get zoomInTitle => tr('بزرگنمایی', 'Zoom in', 'تكبير');
  String get zoomOutTitle => tr('کوچک‌نمایی', 'Zoom out', 'تصغير');
  String get backTitle => tr('بازگشت به سایروس توریست', 'Back to Cyrus Tourist', 'العودة إلى سايروس توريست');
  String get languageTitle => tr('زبان', 'Language', 'اللغة');
  String get distanceTitle => tr('مسافت', 'Distance', 'المسافة');
  String get durationTitle => tr('زمان تقریبی', 'ETA', 'الوقت التقريبي');
  String get routingErrorTitle => tr('دریافت مسیر انجام نشد. اتصال اینترنت را بررسی کنید.', 'Could not get the route. Check your internet connection.', 'تعذر الحصول على المسار. تحقق من اتصال الإنترنت.');
  String get needPointsTitle => tr('ابتدا مبدأ و مقصد را انتخاب کنید.', 'Select an origin and destination first.', 'اختر نقطة البداية والوجهة أولاً');

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
        if (originLocation == null) {
          originLocation = point;
          originName = tr(
            'موقعیت فعلی من',
            'My current location',
            'موقعي الحالي',
          );
        }
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
        'accept-language': _nominatimLanguage,
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
          language: pageLanguage,
          tr: tr,
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
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
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
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
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
      originName = tr('موقعیت فعلی من', 'My current location', 'موقعي الحالي');
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
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
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
  }

  // ----------------------------------------------------------
  // CLEAR DESTINATION
  // ----------------------------------------------------------

  void _clearDestination() {
    setState(() {
      destinationLocation = null;
      destinationName = null;
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
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
  // REAL ROUTING - OSRM
  // ----------------------------------------------------------

  Future<void> openRouting() async {
    if (originLocation == null || destinationLocation == null) {
      _showMessage(needPointsTitle, Icons.alt_route);
      openSearch();
      return;
    }
    if (routingLoading) return;

    setState(() => routingLoading = true);

    final origin = originLocation!;
    final destination = destinationLocation!;
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    final client = HttpClient();
    try {
      client.userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('OSRM HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map ||
          decoded['code'] != 'Ok' ||
          decoded['routes'] is! List ||
          (decoded['routes'] as List).isEmpty) {
        throw Exception('OSRM route not found');
      }

      final route = (decoded['routes'] as List).first;
      final geometry = route['geometry'];
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (coordinates is! List || coordinates.isEmpty) {
        throw Exception('OSRM geometry missing');
      }

      final points = <LatLng>[];
      for (final item in coordinates) {
        if (item is List && item.length >= 2) {
          points.add(
            LatLng(
              (item[1] as num).toDouble(),
              (item[0] as num).toDouble(),
            ),
          );
        }
      }
      if (points.length < 2) throw Exception('OSRM route too short');

      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() {
        routePoints = points;
        routeDistanceKm = distanceMeters / 1000;
        routeDurationMin = durationSeconds / 60;
        routingLoading = false;
      });

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(70),
          maxZoom: 15,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        routingLoading = false;
        routePoints = [];
        routeDistanceKm = null;
        routeDurationMin = null;
      });
      _showMessage(routingErrorTitle, Icons.error_outline);
    } finally {
      client.close(force: true);
    }
  }

  void clearRoute() {
    setState(() {
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final options = <MapLanguage, String>{
          MapLanguage.fa: 'فارسی',
          MapLanguage.en: 'English',
          MapLanguage.ar: 'العربية',
        };
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff071722),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in options.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: entry.key == pageLanguage
                          ? const Color(0xff0083B0)
                          : Colors.white.withValues(alpha: 0.08),
                      leading: Icon(
                        entry.key == pageLanguage
                            ? Icons.check_circle
                            : Icons.language,
                        color: Colors.white,
                      ),
                      title: Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        setState(() => pageLanguage = entry.key);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _routeSummary() {
    final distance = routeDistanceKm ?? 0;
    final duration = routeDurationMin ?? 0;
    final distanceText = distance < 1
        ? '${(distance * 1000).round()} m'
        : '${distance.toStringAsFixed(1)} km';
    final durationText = duration < 60
        ? '${duration.round()} min'
        : '${(duration / 60).floor()} h ${(duration % 60).round()} min';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xff071722).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff2D6678)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 4,
              children: [
                _routeMetric(Icons.straighten, distanceTitle, distanceText),
                _routeMetric(Icons.schedule, durationTitle, durationText),
              ],
            ),
          ),
          IconButton(
            tooltip: clearRouteTitle,
            onPressed: clearRoute,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _routeMetric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }


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
      textDirection: isRtl
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
              tooltip: backTitle,
              onPressed: () {
                Navigator.of(context).pop();
              },
              size: 46,
            ),
          ),
          title: Column(
            children: [
              Text(
                mapTitle,
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
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6,
                        color: const Color(0xff0083B0),
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ],
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
                    icon: Icons.language,
                    tooltip: languageTitle,
                    onPressed: _showLanguagePicker,
                  ),
                  const SizedBox(width: 8),
                  mapButton(
                    icon: Icons.alt_route,
                    tooltip: routeTitle,
                    active: routePoints.length >= 2,
                    onPressed: openRouting,
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
                            gpsOffTitle,
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

            if (routePoints.length >= 2)
              Positioned(
                left: 16,
                right: 82,
                bottom: 24,
                child: _routeSummary(),
              ),

            // RIGHT CONTROLS
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  mapButton(
                    icon: Icons.add,
                    tooltip: zoomInTitle,
                    onPressed:
                        zoomIn,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  mapButton(
                    icon:
                        Icons.remove,
                    tooltip: zoomOutTitle,
                    onPressed:
                        zoomOut,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  mapButton(
                    icon:
                        Icons.explore,
                    tooltip: northTitle,
                    onPressed:
                        goNorth,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  mapButton(
                    icon:
                        Icons.my_location,
                    tooltip: currentLocationTitle,
                    active:
                        userLocation !=
                            null,
                    onPressed:
                        goToMyLocation,
                  ),
                ],
              ),
            ),

            if (routingLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.10),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff071722),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tr('در حال محاسبه مسیر...', 'Calculating route...', 'جارٍ حساب المسار...'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        locatingTitle,
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
  final MapLanguage language;
  final String Function(String, String, String) tr;

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
    required this.language,
    required this.tr,
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

  bool get isRtl =>
      pageLanguage == MapLanguage.fa || pageLanguage == MapLanguage.ar;

  String get _nominatimLanguage {
    switch (pageLanguage) {
      case MapLanguage.en:
        return 'en';
      case MapLanguage.ar:
        return 'ar,en';
      case MapLanguage.fa:
        return 'fa,en';
    }
  }

  String tr(String fa, String en, String ar) {
    switch (pageLanguage) {
      case MapLanguage.en:
        return en;
      case MapLanguage.ar:
        return ar;
      case MapLanguage.fa:
        return fa;
    }
  }

  String get mapTitle => tr('نقشه گردشگری', 'Tourism Map', 'الخريطة السياحية');
  String get searchTitle => tr('جستجوی مبدأ و مقصد', 'Search origin & destination', 'بحث عن البداية والوجهة');
  String get routeTitle => tr('مسیر‌یابی', 'Route', 'المسار');
  String get clearRouteTitle => tr('پاک کردن مسیر', 'Clear route', 'مسح المسار');
  String get gpsOffTitle => tr(gpsOffTitle, 'GPS is off — tap to enable location', 'GPS متوقف — اضغط لتفعيل الموقع');
  String get locatingTitle => tr('در حال مکان‌یابی...', 'Locating...', 'جارٍ تحديد الموقع...');
  String get currentLocationTitle => tr('موقعیت من', 'My location', 'موقعي');
  String get northTitle => tr('بازگشت به شمال', 'North', 'الشمال');
  String get zoomInTitle => tr('بزرگنمایی', 'Zoom in', 'تكبير');
  String get zoomOutTitle => tr('کوچک‌نمایی', 'Zoom out', 'تصغير');
  String get backTitle => tr('بازگشت به سایروس توریست', 'Back to Cyrus Tourist', 'العودة إلى سايروس توريست');
  String get languageTitle => tr('زبان', 'Language', 'اللغة');
  String get distanceTitle => tr('مسافت', 'Distance', 'المسافة');
  String get durationTitle => tr('زمان تقریبی', 'ETA', 'الوقت التقريبي');
  String get routingErrorTitle => tr('دریافت مسیر انجام نشد. اتصال اینترنت را بررسی کنید.', 'Could not get the route. Check your internet connection.', 'تعذر الحصول على المسار. تحقق من اتصال الإنترنت.');
  String get needPointsTitle => tr('ابتدا مبدأ و مقصد را انتخاب کنید.', 'Select an origin and destination first.', 'اختر نقطة البداية والوجهة أولاً');

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
        SnackBar(
          content: Text(
            widget.tr(
              'جستجوی مکان انجام نشد. اتصال اینترنت را بررسی کنید.',
              'Place search failed. Check your internet connection.',
              'فشل البحث عن المكان. تحقق من اتصال الإنترنت.',
            ),
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
        SnackBar(
          content: Text(
            widget.tr(
              'ابتدا باید موقعیت فعلی دریافت شود.',
              'Get your current location first.',
              'احصل على موقعك الحالي أولاً.',
            ),
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
        onChanged: (_) {
          setState(() {});
        },
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
              ? widget.tr('جستجوی مبدأ...', 'Search origin...', 'بحث عن البداية...')
              : widget.tr('جستجوی مقصد...', 'Search destination...', 'بحث عن الوجهة...'),
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
                      widget.tr(
                        'جستجوی مبدأ و مقصد',
                        'Search origin & destination',
                        'بحث عن البداية والوجهة',
                      ),
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
                    label: Text(
                      widget.tr(
                        'استفاده از موقعیت فعلی من',
                        'Use my current location',
                        'استخدام موقعي الحالي',
                      ),
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
                onPressed: () {
                  final originText = originController.text;
                  originController.text = destinationController.text;
                  destinationController.text = originText;
                  setState(() {
                    originMode = true;
                    results = [];
                  });
                  widget.onSwap();
                },
                tooltip: widget.tr(
                  'تعویض مبدأ و مقصد',
                  'Swap origin & destination',
                  'تبديل البداية والوجهة',
                ),
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
                          ? widget.tr('در حال جستجو...', 'Searching...', 'جارٍ البحث...')
                          : widget.tr('جستجوی مکان واقعی', 'Search places', 'بحث عن مكان'),
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
