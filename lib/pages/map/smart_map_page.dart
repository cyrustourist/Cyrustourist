import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum MapLanguage { fa, en, ar }

/// Routing strategy kept extensible for a future traffic-aware provider.
enum RouteStrategy { fastest, lowTrafficReady }

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() => _SmartMapPageState();
}

class _SmartMapPageState extends State<SmartMapPage> {
  final MapController mapController = MapController();

  static const LatLng iranCenter = LatLng(32.4279, 53.6880);

  LatLng? userLocation;
  LatLng? originLocation;
  LatLng? destinationLocation;

  String? originName;
  String? destinationName;

  bool loading = false;
  bool gpsEnabled = true;
  bool routingLoading = false;
  int _routingRequestId = 0;

  RouteStrategy routeStrategy = RouteStrategy.fastest;

  MapLanguage pageLanguage = MapLanguage.fa;

  List<LatLng> routePoints = [];

  double? routeDistanceKm;
  double? routeDurationMin;

  bool get isRtl =>
      pageLanguage == MapLanguage.fa ||
      pageLanguage == MapLanguage.ar;

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

  String get mapTitle =>
      tr('نقشه گردشگری', 'Tourism Map', 'الخريطة السياحية');

  String get searchTitle =>
      tr(
        'جستجوی مبدأ و مقصد',
        'Search origin & destination',
        'بحث عن البداية والوجهة',
      );

  String get searchPlaceTitle =>
      tr(
        'جستجوی هدف گردشگری',
        'Search tourist destination',
        'البحث عن هدف سياحي',
      );

  String get routeTitle =>
      tr('مسیریابی', 'Route', 'المسار');

  String get clearRouteTitle =>
      tr('پاک کردن مسیر', 'Clear route', 'مسح المسار');

  String get gpsOffTitle => tr(
        'GPS خاموش است — برای فعال‌سازی مکان‌یابی ضربه بزنید',
        'GPS is off — tap to enable location',
        'GPS متوقف — اضغط لتفعيل الموقع',
      );

  String get locatingTitle =>
      tr(
        'در حال مکان‌یابی...',
        'Locating...',
        'جارٍ تحديد الموقع...',
      );

  String get currentLocationTitle =>
      tr('موقعیت من', 'My location', 'موقعي');

  String get northTitle =>
      tr('بازگشت به شمال', 'North', 'الشمال');

  String get zoomInTitle =>
      tr('بزرگنمایی', 'Zoom in', 'تكبير');

  String get zoomOutTitle =>
      tr('کوچک‌نمایی', 'Zoom out', 'تصغير');

  String get backTitle =>
      tr(
        'بازگشت به سایروس توریست',
        'Back to Cyrus Tourist',
        'العودة إلى سايروس توريست',
      );

  String get languageTitle =>
      tr('زبان', 'Language', 'اللغة');

  String get distanceTitle =>
      tr('مسافت', 'Distance', 'المسافة');

  String get durationTitle =>
      tr('زمان تقریبی', 'ETA', 'الوقت التقريبي');

  String get routingErrorTitle => tr(
        'دریافت مسیر انجام نشد. اتصال اینترنت را بررسی کنید.',
        'Could not get the route. Check your internet connection.',
        'تعذر الحصول على المسار. تحقق من اتصال الإنترنت.',
      );

  String get needPointsTitle => tr(
        'ابتدا مبدأ و مقصد را انتخاب کنید.',
        'Select an origin and destination first.',
        'اختر نقطة البداية والوجهة أولاً.',
      );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation();
    });
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> getLocation() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

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
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        _showMessage(
          tr(
            'دسترسی مکان فعال نیست',
            'Location permission is not enabled',
            'لم يتم تفعيل إذن الموقع',
          ),
          Icons.location_off,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
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

      mapController.move(point, 15);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        tr(
          'خطا در دریافت موقعیت',
          'Could not get current location',
          'تعذر الحصول على الموقع الحالي',
        ),
        Icons.error_outline,
      );
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showGpsWarning() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xffB3261E),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.gps_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(
                  'GPS خاموش است. لطفاً مکان‌یابی گوشی را فعال کنید.',
                  'GPS is off. Please enable location services.',
                  'GPS متوقف. يرجى تفعيل خدمات الموقع.',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: tr(
            'تنظیمات',
            'Settings',
            'الإعدادات',
          ),
          textColor: Colors.white,
          onPressed: () {
            Geolocator.openLocationSettings();
          },
        ),
      ),
    );
  }

  void _showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff102A38),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<Map<String, dynamic>>> searchPlaces(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': cleanQuery,
        'format': 'jsonv2',
        'limit': '8',
        'addressdetails': '1',
        'accept-language': _nominatimLanguage,
      },
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

      if (response.statusCode != 200) {
        throw Exception(
          'Nominatim HTTP ${response.statusCode}',
        );
      }

      final body =
          await response.transform(utf8.decoder).join();

      final decoded = jsonDecode(body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // ============================================================
  // SEARCH PANEL
  // ============================================================

  void openSearch({
    bool destination = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SearchPanel(
          initialOrigin: originName,
          initialDestination: destinationName,
          userLocation: userLocation,
          initialMode: destination ? false : true,
          onOriginSelected: _selectOrigin,
          onDestinationSelected: _selectDestination,
          onClearOrigin: _clearOrigin,
          onClearDestination: _clearDestination,
          onSwap: _swapPlaces,
          searchPlaces: searchPlaces,
          language: pageLanguage,
          tr: tr,
        );
      },
    );
  }

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

    mapController.move(point, 15);
  }

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

    mapController.move(point, 15);
  }

  void useCurrentLocationAsOrigin() {
    if (userLocation == null) {
      getLocation();
      return;
    }

    _selectOrigin(
      userLocation!,
      tr(
        'موقعیت فعلی من',
        'My current location',
        'موقعي الحالي',
      ),
    );
  }

  void _clearOrigin() {
    setState(() {
      originLocation = null;
      originName = null;
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
  }

  void _clearDestination() {
    setState(() {
      destinationLocation = null;
      destinationName = null;
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });
  }

  void _swapPlaces() {
    setState(() {
      final oldOrigin = originLocation;

      originLocation = destinationLocation;
      destinationLocation = oldOrigin;

      final oldOriginName = originName;

      originName = destinationName;
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
  }

  // ============================================================
  // ROUTING
  // ============================================================

  Uri _buildRoutingUri(
    LatLng origin,
    LatLng destination,
  ) {
    switch (routeStrategy) {
      case RouteStrategy.fastest:
      case RouteStrategy.lowTrafficReady:
        break;
    }

    return Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );
  }

  Future<void> openRouting() async {
    if (originLocation == null ||
        destinationLocation == null) {
      _showMessage(
        needPointsTitle,
        Icons.alt_route,
      );

      openSearch(
        destination: originLocation != null &&
            destinationLocation == null,
      );
      return;
    }

    if (routingLoading) return;

    final requestId = ++_routingRequestId;

    setState(() {
      routingLoading = true;
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMin = null;
    });

    final origin = originLocation!;
    final destination = destinationLocation!;

    final uri = _buildRoutingUri(
      origin,
      destination,
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

      final response = await request
          .close()
          .timeout(
            const Duration(seconds: 25),
          );

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'OSRM HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map ||
          decoded['code'] != 'Ok' ||
          decoded['routes'] is! List ||
          (decoded['routes'] as List).isEmpty) {
        throw Exception(
          decoded is Map
              ? (decoded['message']?.toString() ??
                  'OSRM route not found')
              : 'OSRM route not found',
        );
      }

      final route =
          (decoded['routes'] as List).first;

      final geometry = route['geometry'];

      final coordinates =
          geometry is Map
              ? geometry['coordinates']
              : null;

      if (coordinates is! List ||
          coordinates.isEmpty) {
        throw Exception(
          'OSRM geometry missing',
        );
      }

      final points = <LatLng>[];

      for (final item in coordinates) {
        if (item is List &&
            item.length >= 2) {
          final longitude =
              (item[0] as num).toDouble();

          final latitude =
              (item[1] as num).toDouble();

          points.add(
            LatLng(
              latitude,
              longitude,
            ),
          );
        }
      }

      if (points.length < 2) {
        throw Exception(
          'OSRM route too short',
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

      if (!mounted ||
          requestId != _routingRequestId) {
        return;
      }

      setState(() {
        routePoints = points;
        routeDistanceKm =
            distanceMeters / 1000;
        routeDurationMin =
            durationSeconds / 60;
        routingLoading = false;
      });

      mapController.fitCamera(
        CameraFit.bounds(
          bounds:
              LatLngBounds.fromPoints(points),
          padding:
              const EdgeInsets.fromLTRB(
            55,
            55,
            55,
            150,
          ),
          maxZoom: 15,
        ),
      );

      _showMessage(
        tr(
          'مسیر واقعی آماده شد.',
          'Real road route is ready.',
          'تم تجهيز مسار الطريق الحقيقي.',
        ),
        Icons.check_circle_outline,
      );
    } catch (_) {
      if (!mounted ||
          requestId != _routingRequestId) {
        return;
      }

      setState(() {
        routingLoading = false;
        routePoints = [];
        routeDistanceKm = null;
        routeDurationMin = null;
      });

      _showMessage(
        routingErrorTitle,
        Icons.error_outline,
      );
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

  // ============================================================
  // MAP CONTROLS
  // ============================================================

  void zoomIn() {
    mapController.move(
      mapController.camera.center,
      mapController.camera.zoom + 1,
    );
  }

  void zoomOut() {
    mapController.move(
      mapController.camera.center,
      mapController.camera.zoom - 1,
    );
  }

  void goNorth() {
    mapController.rotate(0);

    _showMessage(
      tr(
        'نقشه به سمت شمال برگشت',
        'Map returned to north',
        'عادت الخريطة إلى الشمال',
      ),
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

  // ============================================================
  // LANGUAGE
  // ============================================================

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final options =
            <MapLanguage, String>{
          MapLanguage.fa: 'پارسی',
          MapLanguage.en: 'English',
          MapLanguage.ar: 'العربية',
        };

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff071722),
              borderRadius:
                  BorderRadius.circular(24),
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
                for (final entry
                    in options.entries)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: ListTile(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      tileColor:
                          entry.key ==
                                  pageLanguage
                              ? const Color(
                                  0xff0083B0,
                                )
                              : Colors.white
                                  .withValues(
                                  alpha: 0.08,
                                ),
                      leading: Icon(
                        entry.key ==
                                pageLanguage
                            ? Icons.check_circle
                            : Icons.language,
                        color: Colors.white,
                      ),
                      title: Text(
                        entry.value,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          pageLanguage =
                              entry.key;
                        });

                        Navigator.pop(
                          sheetContext,
                        );
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

  // ============================================================
  // ROUTE SUMMARY
  // ============================================================

  Widget _routeSummary() {
    final distance =
        routeDistanceKm ?? 0;

    final duration =
        routeDurationMin ?? 0;

    final distanceText = distance < 1
        ? '${(distance * 1000).round()} m'
        : '${distance.toStringAsFixed(1)} km';

    final durationText = duration < 60
        ? '${duration.round()} min'
        : '${(duration / 60).floor()} h '
            '${(duration % 60).round()} min';

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        8,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff071722)
            .withValues(alpha: 0.95),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff2D6678),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alt_route,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 4,
              children: [
                _routeMetric(
                  Icons.straighten,
                  distanceTitle,
                  distanceText,
                ),
                _routeMetric(
                  Icons.schedule,
                  durationTitle,
                  durationText,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: clearRouteTitle,
            onPressed: clearRoute,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeMetric(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white70,
        ),
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

  // ============================================================
  // MARKERS
  // ============================================================

  List<Marker> markers() {
    final result = <Marker>[];

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
            icon: Icons.trip_origin,
            label: tr(
              'مبدأ',
              'Origin',
              'البداية',
            ),
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
            icon: Icons.location_on,
            label: tr(
              'مقصد',
              'Destination',
              'الوجهة',
            ),
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

  // ============================================================
  // BUTTONS
  // ============================================================

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
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(17),
              gradient: LinearGradient(
                colors: active
                    ? const [
                        Color(0xff24C6DC),
                        Color(0xff1976D2),
                      ]
                    : const [
                        Colors.white,
                        Color(0xffDCEAF0),
                      ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 5),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            const Color(0xff071722),
        body: SafeArea(
          child: Column(
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
                        initialZoom: 5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'cyrustourist.ir.app',
                        ),
                        if (routePoints.length >=
                            2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points:
                                    routePoints,
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
                        MarkerLayer(
                          markers: markers(),
                        ),
                      ],
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration:
                                BoxDecoration(
                              color: const Color(
                                0xff071722,
                              ).withValues(
                                alpha: 0.88,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                              border: Border.all(
                                color:
                                    Colors.white24,
                              ),
                            ),
                            child: Text(
                              mapTitle,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (!gpsEnabled)
                      Positioned(
                        top: 58,
                        left: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            Geolocator
                                .openLocationSettings();
                          },
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration:
                                BoxDecoration(
                              color: const Color(
                                0xffB3261E,
                              ).withValues(
                                alpha: 0.94,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.gps_off,
                                  color:
                                      Colors.white,
                                ),
                                const SizedBox(
                                    width: 10),
                                Expanded(
                                  child: Text(
                                    gpsOffTitle,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (routingLoading)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black
                                .withValues(
                              alpha: 0.12,
                            ),
                            alignment:
                                Alignment.center,
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xff071722,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xff2D6678,
                                  ),
                                ),
                                boxShadow:
                                    const [
                                  BoxShadow(
                                    color:
                                        Colors.black45,
                                    blurRadius: 18,
                                    offset:
                                        Offset(
                                      0,
                                      8,
                                    ),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 12),
                                  Text(
                                    tr(
                                      'در حال دریافت مسیر...',
                                      'Getting road route...',
                                      'جارٍ الحصول على مسار الطريق...',
                                    ),
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
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
                  ],
                ),
              ),

              _buildBottomControlPanel(
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlPanel(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff071722),
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (routePoints.length >= 2) ...[
              _routeSummary(),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: largeMapAction(
                    icon:
                        Icons.travel_explore,
                    title:
                        searchPlaceTitle,
                    primary: true,
                    onPressed: () =>
                        openSearch(
                      destination:
                          originLocation !=
                                  null &&
                              destinationLocation ==
                                  null,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: largeMapAction(
                    icon: Icons.alt_route,
                    title: routeTitle,
                    primary:
                        routePoints.length >=
                            2,
                    onPressed: openRouting,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              reverse: isRtl,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  mapButton(
                    icon: Icons.add,
                    tooltip: zoomInTitle,
                    onPressed: zoomIn,
                    size: 48,
                  ),
                  const SizedBox(width: 7),
                  mapButton(
                    icon: Icons.remove,
                    tooltip: zoomOutTitle,
                    onPressed: zoomOut,
                    size: 48,
                  ),
                  const SizedBox(width: 7),
                  mapButton(
                    icon: Icons.explore,
                    tooltip: northTitle,
                    onPressed: goNorth,
                    size: 48,
                  ),
                  const SizedBox(width: 7),
                  mapButton(
                    icon:
                        Icons.my_location,
                    tooltip:
                        currentLocationTitle,
                    active:
                        userLocation != null,
                    onPressed:
                        goToMyLocation,
                    size: 48,
                  ),
                  const SizedBox(width: 7),
                  mapButton(
                    icon: Icons.language,
                    tooltip: languageTitle,
                    onPressed:
                        _showLanguagePicker,
                    size: 48,
                  ),
                  const SizedBox(width: 7),
                  _backToCyrusButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backToCyrusButton() {
    return Tooltip(
      message: backTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(17),
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            height: 48,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(17),
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xffD4AF37),
                  Color(0xffA77B18),
                ],
              ),
              border: Border.all(
                color: Colors.white70,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.reply,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  tr(
                    '↪️ سایروس توریست',
                    '↪️ Cyrus Tourist',
                    '↪️ سايروس توريست',
                  ),
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH PANEL
// ============================================================================

class _SearchPanel extends StatefulWidget {
  const _SearchPanel({
    required this.initialOrigin,
    required this.initialDestination,
    required this.userLocation,
    required this.initialMode,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onClearOrigin,
    required this.onClearDestination,
    required this.onSwap,
    required this.searchPlaces,
    required this.language,
    required this.tr,
  });

  final String? initialOrigin;
  final String? initialDestination;
  final LatLng? userLocation;
  final bool initialMode;

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

  final Future<List<Map<String, dynamic>>>
      Function(String query) searchPlaces;

  final MapLanguage language;

  final String Function(
    String fa,
    String en,
    String ar,
  ) tr;

  String get searchPlaceTitle => tr(
        'جستجوی هدف گردشگری',
        'Search tourist destination',
        'البحث عن هدف سياحي',
      );

  @override
  State<_SearchPanel> createState() =>
      _SearchPanelState();
}

class _SearchPanelState
    extends State<_SearchPanel> {
  final TextEditingController
      originController =
      TextEditingController();

  final TextEditingController
      destinationController =
      TextEditingController();

  bool originMode = true;
  bool searching = false;

  List<Map<String, dynamic>> results =
      [];

  bool get isRtl =>
      widget.language ==
          MapLanguage.fa ||
      widget.language ==
          MapLanguage.ar;

  @override
  void initState() {
    super.initState();

    originMode =
        widget.initialMode;

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

  // ============================================================
  // SEARCH CURRENT FIELD
  // ============================================================

  Future<void> searchCurrentField() async {
    final controller = originMode
        ? originController
        : destinationController;

    await performSearch(
      controller.text,
    );
  }

  Future<void> performSearch(
    String query,
  ) async {
    final cleanQuery =
        query.trim();

    if (cleanQuery.length < 2) {
      setState(() {
        results = [];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.tr(
              'حداقل دو حرف وارد کنید.',
              'Enter at least two characters.',
              'أدخل حرفين على الأقل.',
            ),
          ),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      searching = true;
      results = [];
    });

    try {
      final data =
          await widget.searchPlaces(
        cleanQuery,
      );

      if (!mounted) return;

      setState(() {
        results = data;
        searching = false;
      });

      if (data.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              widget.tr(
                'مکانی پیدا نشد.',
                'No places found.',
                'لم يتم العثور على أماكن.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
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
              'جستجو انجام نشد. اینترنت را بررسی کنید.',
              'Search failed. Check your internet connection.',
              'فشل البحث. تحقق من اتصال الإنترنت.',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECT RESULT
  // ============================================================

  void selectResult(
    Map<String, dynamic> result,
  ) {
    final lat = double.tryParse(
      result['lat']?.toString() ?? '',
    );

    final lon = double.tryParse(
      result['lon']?.toString() ?? '',
    );

    if (lat == null || lon == null) {
      return;
    }

    final name =
        result['display_name']
                ?.toString() ??
            widget.tr(
              'مکان انتخاب‌شده',
              'Selected place',
              'المكان المحدد',
            );

    final point =
        LatLng(lat, lon);

    if (originMode) {
      widget.onOriginSelected(
        point,
        name,
      );

      originController.text =
          name;

      setState(() {
        originMode = false;
        results = [];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.tr(
              'مبدأ انتخاب شد؛ حالا مقصد را جستجو کنید.',
              'Origin selected; now search for the destination.',
              'تم اختيار البداية؛ ابحث الآن عن الوجهة.',
            ),
          ),
        ),
      );
    } else {
      widget.onDestinationSelected(
        point,
        name,
      );

      destinationController.text =
          name;

      setState(() {
        results = [];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.tr(
              'مقصد انتخاب شد؛ برای مسیریابی دکمه مسیریابی را بزنید.',
              'Destination selected; press Route to calculate the route.',
              'تم اختيار الوجهة؛ اضغط على المسار لحساب الطريق.',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

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

    final name = widget.tr(
      'موقعیت فعلی من',
      'My current location',
      'موقعي الحالي',
    );

    widget.onOriginSelected(
      widget.userLocation!,
      name,
    );

    originController.text =
        name;

    setState(() {
      originMode = false;
      results = [];
    });
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget searchField({
    required bool origin,
  }) {
    final controller = origin
        ? originController
        : destinationController;

    final color = origin
        ? const Color(0xff1976D2)
        : const Color(0xffE53935);

    final selected =
        originMode == origin;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? color
              : Colors.transparent,
          width: 2,
        ),
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
        textDirection: isRtl
            ? TextDirection.rtl
            : TextDirection.ltr,
        textInputAction:
            TextInputAction.search,
        onTap: () {
          setState(() {
            originMode = origin;
            results = [];
          });
        },
        onSubmitted: (_) {
          setState(() {
            originMode = origin;
          });

          searchCurrentField();
        },
        decoration:
            InputDecoration(
          prefixIcon: Icon(
            origin
                ? Icons.trip_origin
                : Icons.location_on,
            color: color,
          ),
          suffixIcon: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              if (controller.text
                  .isNotEmpty)
                IconButton(
                  tooltip: widget.tr(
                    'پاک کردن',
                    'Clear',
                    'مسح',
                  ),
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
                ),
              IconButton(
                tooltip: widget.tr(
                  'جستجو',
                  'Search',
                  'بحث',
                ),
                icon: Icon(
                  Icons.search,
                  color: color,
                ),
                onPressed: searching
                    ? null
                    : () {
                        setState(() {
                          originMode =
                              origin;
                        });

                        searchCurrentField();
                      },
              ),
            ],
          ),
          hintText: origin
              ? widget.tr(
                  'جستجوی مبدأ...',
                  'Search origin...',
                  'بحث عن البداية...',
                )
              : widget.tr(
                  'جستجوی مقصد...',
                  'Search destination...',
                  'بحث عن الوجهة...',
                ),
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULT
  // ============================================================

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
        onTap: () =>
            selectResult(result),
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  textDirection: isRtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Directionality(
      textDirection: isRtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Padding(
        padding:
            EdgeInsets.only(
          bottom: bottom,
        ),
        child: Container(
          constraints:
              const BoxConstraints(
            maxHeight: 680,
          ),
          decoration:
              const BoxDecoration(
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

                Container(
                  width: 45,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white38,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color:
                            Colors.white,
                        size: 27,
                      ),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child: Text(
                          widget.tr(
                            'جستجوی مبدأ و مقصد',
                            'Search origin & destination',
                            'بحث عن البداية والوجهة',
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 19,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

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
                  height: 4,
                ),

                Align(
                  alignment: isRtl
                      ? Alignment
                          .centerRight
                      : Alignment
                          .centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    child:
                        TextButton.icon(
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
                        style:
                            const TextStyle(
                          color: Color(
                              0xffB9E9FF),
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    final originText =
                        originController
                            .text;

                    originController
                            .text =
                        destinationController
                            .text;

                    destinationController
                            .text =
                        originText;

                    setState(() {
                      originMode =
                          false;
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
                    color:
                        Colors.white,
                    size: 35,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

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

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        ElevatedButton
                            .icon(
                      onPressed: searching
                          ? null
                          : searchCurrentField,
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

                      // ====================================================
                      // FIX:
                      // searchPlaceTitle belongs to _SearchPanel.
                      // Therefore it must be accessed through widget.
                      // ====================================================
                      label: Text(
                        searching
                            ? widget.tr(
                                'در حال جستجو...',
                                'Searching...',
                                'جارٍ البحث...',
                              )
                            : widget.searchPlaceTitle,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize: 15,
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
                        elevation: 8,
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

                if (results.isNotEmpty)
                  Flexible(
                    child:
                        ListView.builder(
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
                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 18,
                    ),
                    child: Text(
                      widget.tr(
                        'نام شهر، خیابان یا مکان را وارد و روی جستجو بزنید.',
                        'Enter a city, street, or place and press Search.',
                        'أدخل مدينة أو شارعًا أو مكانًا واضغط بحث.',
                      ),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 12,
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
}
