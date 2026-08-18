import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const CyrusTouristApp());
}

class CyrusTouristApp extends StatelessWidget {
  const CyrusTouristApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyrus Tourist',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const SplashPage(),
    );
  }
}

// ------------------------------------------------------------
// Splash - نمایش تصویر آغازین به مدت ۲ ثانیه
// ------------------------------------------------------------

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image(
              image: AssetImage('assets/images/splash.jpg'),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// صفحه اصلی
// ------------------------------------------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1024,
                  height: 1536,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: Image(
                          image: AssetImage('assets/images/home.jpg'),
                          fit: BoxFit.contain,
                        ),
                      ),

                      // کلید ورود به نقشه
                      Positioned(
                        left: 25,
                        right: 25,
                        bottom: 205,
                        height: 130,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TouristMapPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// صفحه نقشه گردشگری
// ------------------------------------------------------------

class TouristMapPage extends StatefulWidget {
  const TouristMapPage({super.key});

  @override
  State<TouristMapPage> createState() => _TouristMapPageState();
}

class _TouristMapPageState extends State<TouristMapPage> {
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(
    32.4279,
    53.6880,
  );

  LatLng? _userLocation;

  bool _loadingLocation = false;

  // ----------------------------------------------------------
  // دریافت موقعیت کاربر
  // ----------------------------------------------------------

  Future<void> _locateUser() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position =
          await Geolocator.getCurrentPosition();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _userLocation = location;
        _center = location;
      });

      _mapController.move(
        location,
        14,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // رابط کاربری نقشه
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقشه گردشگری'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 5.5,

              // فعال بودن کامل لمس نقشه:
              // حرکت، زوم، کشیدن و سایر تعاملات
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'cyrustourist.ir.app',
              ),

              // مکان‌نمای کاربر
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // دکمه مکان من
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              onPressed:
                  _loadingLocation ? null : _locateUser,
              child: _loadingLocation
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
