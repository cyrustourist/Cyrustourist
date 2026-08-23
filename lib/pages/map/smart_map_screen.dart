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

  final MapSmartController controller = MapSmartController();

  List<LatLng> routePoints = [];

  MapPlace? selectedDestination;

  bool routeLoading = false;

  String selectedLanguage = 'fa';

  @override
  void initState() {
    super.initState();

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

    if (controller.userLocation != null) {
      mapController.move(
        controller.userLocation!,
        14,
      );
    }

    setState(() {});
  }

  Future<void> search(String text) async {
    if (text.trim().isEmpty) return;

    await controller.search(
      query: text,
    );

    if (!mounted) return;

    setState(() {});

    if (controller.nearestPlace != null) {
      final place = controller.nearestPlace!;

      setState(() {
        selectedDestination = place;
        routePoints = [];
      });

      mapController.move(
        place.location,
        15,
      );
    }
  }

  Future<void> buildRoute(MapPlace place) async {
    final start = controller.userLocation;

    if (start == null) {
      _showMessage(
        _text(
          'موقعیت فعلی شما مشخص نیست',
          'Your current location is not available',
          'موقعيتك الحالية غير متاحة',
        ),
      );
      return;
    }

    setState(() {
      routeLoading = true;
      selectedDestination = place;
    });

    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${place.location.longitude},${place.location.latitude}',
        {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
        },
      );

      final client = HttpClient();

      try {
        final request = await client.getUrl(uri);

        request.headers.set(
          HttpHeaders.acceptHeader,
          'application/json',
        );

        final response = await request.close();

        if (response.statusCode != 200) {
          throw Exception(
            'Routing failed: ${response.statusCode}',
          );
        }

        final body = await response
            .transform(utf8.decoder)
            .join();

        final data = jsonDecode(body);

        if (data is! Map ||
            data['routes'] is! List ||
            (data['routes'] as List).isEmpty) {
          throw Exception('No route');
        }

        final route = (data['routes'] as List).first;

        final geometry = route['geometry'];

        if (geometry is! Map ||
            geometry['coordinates'] is! List) {
          throw Exception('Invalid route geometry');
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

        if (points.isEmpty) {
          throw Exception('Empty route');
        }

        if (!mounted) return;

        setState(() {
          routePoints = points;
          routeLoading = false;
        });

        _fitRoute(points);
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        routeLoading = false;
      });

      _showMessage(
        _text(
          'مسیر‌یابی انجام نشد. لطفاً دوباره تلاش کنید.',
          'Route could not be calculated. Please try again.',
          'تعذر حساب المسار. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty) return;

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

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    double zoom = 13;

    final latDistance = maxLat - minLat;
    final lngDistance = maxLng - minLng;

    final distance =
        latDistance > lngDistance
            ? latDistance
            : lngDistance;

    if (distance > 5) {
      zoom = 8;
    } else if (distance > 2) {
      zoom = 10;
    } else if (distance > 0.8) {
      zoom = 11;
    } else if (distance > 0.3) {
      zoom = 12;
    } else if (distance > 0.1) {
      zoom = 13;
    }

    mapController.move(
      center,
      zoom,
    );
  }

  void showPlace(MapPlace place) {
    setState(() {
      selectedDestination = place;
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

  void _goBackToCyrusTourist() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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

  void _changeLanguage(String language) {
    setState(() {
      selectedLanguage = language;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = controller.userLocation;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
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

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 6,
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
                          BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(14),
                        onTap:
                            _goBackToCyrusTourist,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const Text(
                                '↩️',
                                style:
                                    TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _text(
                                  'سایروس توریست',
                                  'Cyrus Tourist',
                                  'سايروس توريست',
                                ),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
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
                        onSearch: search,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Material(
                        elevation: 5,
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            _text(
                              'جستجوی هدف سفر',
                              'Search travel destination',
                              'ابحث عن هدف السفر',
                            ),
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    PopupMenuButton<String>(
                      initialValue:
                          selectedLanguage,
                      onSelected:
                          _changeLanguage,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'fa',
                          child: Text('پارسی'),
                        ),
                        PopupMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        PopupMenuItem(
                          value: 'ar',
                          child: Text('العربية'),
                        ),
                      ],
                      child: Material(
                        elevation: 5,
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        child: const Padding(
                          padding:
                              EdgeInsets.all(10),
                          child: Icon(
                            Icons.language,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (controller.isLoading ||
              controller.isLocationLoading)
            const Center(
              child:
                  CircularProgressIndicator(),
            ),

          if (routeLoading)
            Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _text(
                          'در حال محاسبه مسیر...',
                          'Calculating route...',
                          'جارٍ حساب المسار...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (controller.errorMessage != null)
            Positioned(
              top: 150,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),
                  child: Text(
                    controller.errorMessage!,
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),
            ),

          if (selectedDestination != null &&
              !routeLoading)
            Positioned(
              left: 20,
              right: 20,
              bottom: 95,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          selectedDestination!
                              .name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        onPressed: () =>
                            buildRoute(
                          selectedDestination!,
                        ),
                        icon: const Icon(
                          Icons.directions,
                        ),
                        label: Text(
                          _text(
                            'مسیریابی',
                            'Route',
                            'المسار',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'my_location',
              child: const Icon(
                Icons.my_location,
              ),
              onPressed: () {
                if (controller.userLocation !=
                    null) {
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
