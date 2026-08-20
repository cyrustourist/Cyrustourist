import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CyrusTouristApp());
}

// ============================================================
// CYRUS TOURIST APP
// ============================================================

class CyrusTouristApp extends StatelessWidget {
  const CyrusTouristApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CyrusTourist',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff075b86),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

// ============================================================
// SPLASH PAGE
// ============================================================

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
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'CyrusTourist',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openFeature(
    BuildContext context,
    int number,
    String title,
  ) {
    // کلید ۱ = نقشه گردشگری
    if (number == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SmartMapPage(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        content: Text(
          '$title\nاین بخش در حال آماده‌سازی است.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      const _HomeItem(
        number: 1,
        title: 'نقشه گردشگری',
        icon: Icons.map_rounded,
      ),
      const _HomeItem(
        number: 2,
        title: 'اقامتگاه',
        icon: Icons.hotel_rounded,
      ),
      const _HomeItem(
        number: 3,
        title: 'فیلم‌های گردشگری',
        icon: Icons.movie_rounded,
      ),
      const _HomeItem(
        number: 4,
        title: 'جاذبه‌های گردشگری',
        icon: Icons.account_balance_rounded,
      ),
      const _HomeItem(
        number: 5,
        title: 'جاذبه‌های اطراف من',
        icon: Icons.near_me_rounded,
      ),
      const _HomeItem(
        number: 6,
        title: 'راهنمای سفر',
        icon: Icons.menu_book_rounded,
      ),
      const _HomeItem(
        number: 7,
        title: 'علاقه‌مندی‌ها',
        icon: Icons.favorite_rounded,
      ),
      const _HomeItem(
        number: 8,
        title: 'پشتیبانی و تماس',
        icon: Icons.support_agent_rounded,
      ),
      const _HomeItem(
        number: 9,
        title: 'درباره ما',
        icon: Icons.info_rounded,
      ),
      const _HomeItem(
        number: 10,
        title: 'شبکه‌های اجتماعی',
        icon: Icons.share_rounded,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              // ------------------------------------------------
              // HOME IMAGE
              // ------------------------------------------------

              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Image.asset(
                      'assets/images/home.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'CyrusTourist',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------
              // HOME CONTENT
              // ------------------------------------------------

              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      22,
                      16,
                      24,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'CYRUS TOURIST',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Cyrus is a tourist',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 3),

                        const Text(
                          'Let\'s get to know Iran better.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 24),

                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.45,
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return _HomeButton(
                              number: item.number,
                              title: item.title,
                              icon: item.icon,
                              onTap: () {
                                _openFeature(
                                  context,
                                  item.number,
                                  item.title,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Travel • Discover • Enjoy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

// ============================================================
// HOME ITEM
// ============================================================

class _HomeItem {
  final int number;
  final String title;
  final IconData icon;

  const _HomeItem({
    required this.number,
    required this.title,
    required this.icon,
  });
}

// ============================================================
// HOME BUTTON
// ============================================================

class _HomeButton extends StatefulWidget {
  final int number;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.number,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.white.withValues(
          alpha: pressed ? 0.75 : 0.91,
        ),
        borderRadius: BorderRadius.circular(18),
        elevation: pressed ? 2 : 7,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTapDown: (_) {
            setState(() {
              pressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              pressed = false;
            });
          },
          onTap: () {
            setState(() {
              pressed = false;
            });

            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 29,
                  color: const Color(0xff075b86),
                ),

                const SizedBox(height: 6),

                Text(
                  '${widget.number}. ${widget.title}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff06121d),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

// ============================================================
// SMART MAP PAGE
// ============================================================

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() => _SmartMapPageState();
}

class _SmartMapPageState extends State<SmartMapPage> {
  final MapController mapController = MapController();

  static const LatLng iranCenter =
      LatLng(32.4279, 53.6880);

  LatLng? userLocation;

  bool locationLoading = false;

  bool showLodging = false;
  bool showAttractions = false;
  bool showHealth = false;
  bool showServices = false;

  @override
  void initState() {
    super.initState();

    // تلاش خودکار برای دریافت مکان کاربر
    _getMyLocation(silent: true);
  }

  // ==========================================================
  // GET MY LOCATION
  // ==========================================================

  Future<void> _getMyLocation({
    bool silent = false,
  }) async {
    if (locationLoading) return;

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!silent && mounted) {
          _showLocationMessage(
            'برای پیدا کردن بهترین جاذبه‌ها و مسیرها، '
            'لطفاً مکان‌نما را روشن کنید.',
          );
        }

        return;
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
        if (!silent && mounted) {
          _showLocationMessage(
            'برای نمایش مکان شما، '
            'لطفاً اجازه دسترسی به موقعیت مکانی را فعال کنید.',
          );
        }

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        userLocation = location;
      });

      mapController.move(
        location,
        14.5,
      );
    } catch (_) {
      if (!silent && mounted) {
        _showLocationMessage(
          'دریافت مکان شما انجام نشد.\n'
          'لطفاً روشن بودن مکان‌نما و دسترسی موقعیت را بررسی کنید.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          locationLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // LOCATION MESSAGE
  // ==========================================================

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORY TOGGLE
  // ==========================================================

  void _toggleCategory(
    String name,
    bool currentValue,
    void Function(bool value) setter,
  ) {
    final newValue = !currentValue;

    setState(() {
      setter(newValue);
    });

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration:
            const Duration(milliseconds: 1200),
        content: Text(
          newValue
              ? '$name روی نقشه فعال شد.'
              : '$name از نقشه خاموش شد.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ==========================================================
  // ALL CATEGORIES
  // ==========================================================

  void _showAll() {
    setState(() {
      showLodging = true;
      showAttractions = true;
      showHealth = true;
      showServices = true;
    });

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration:
            Duration(milliseconds: 1300),
        content: Text(
          'همه دسته‌های گردشگری روی نقشه فعال شدند.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ==========================================================
  // MARKERS
  // ==========================================================

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // --------------------------------------------------------
    // USER LOCATION
    // این مکان‌نما عمداً حفظ شده است.
    // --------------------------------------------------------

    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 58,
          height: 58,
          child: const Icon(
            Icons.my_location,
            size: 43,
            color: Colors.blue,
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // TEST CATEGORY MARKERS
    // بعداً داده واقعی جایگزین می‌شود.
    // --------------------------------------------------------

    if (showLodging) {
      markers.add(
        _categoryMarker(
          const LatLng(35.6892, 51.3890),
          Icons.hotel,
          'اقامتگاه',
        ),
      );
    }

    if (showAttractions) {
      markers.add(
        _categoryMarker(
          const LatLng(35.7000, 51.4200),
          Icons.account_balance,
          'جاذبه گردشگری',
        ),
      );
    }

    if (showHealth) {
      markers.add(
        _categoryMarker(
          const LatLng(35.7219, 51.3347),
          Icons.local_hospital,
          'گردشگری سلامت',
        ),
      );
    }

    if (showServices) {
      markers.add(
        _categoryMarker(
          const LatLng(35.6700, 51.4300),
          Icons.build,
          'خدماتی',
        ),
      );
    }

    return markers;
  }

  Marker _categoryMarker(
    LatLng point,
    IconData icon,
    String title,
  ) {
    return Marker(
      point: point,
      width: 58,
      height: 58,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context)
              .hideCurrentSnackBar();

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              behavior:
                  SnackBarBehavior.floating,
              duration:
                  const Duration(milliseconds: 1200),
              content: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        child: Icon(
          icon,
          size: 40,
          color: Colors.blue,
        ),
      ),
    );
  }

  // ==========================================================
  // MAP PAGE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final allActive =
        showLodging &&
        showAttractions &&
        showHealth &&
        showServices;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نقشه گردشگری',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // ==================================================
          // MAP
          // ==================================================

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: const MapOptions(
                    initialCenter: iranCenter,
                    initialZoom: 5.5,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/'
                          '{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'cyrustourist.ir.app',
                    ),

                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),

                // --------------------------------------------
                // MAP CONTROLS
                // --------------------------------------------

                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      _MapControlButton(
                        icon: Icons.my_location,
                        tooltip: 'مکان من',
                        onTap: () {
                          _getMyLocation();
                        },
                      ),

                      const SizedBox(height: 8),

                      _MapControlButton(
                        icon: Icons.add,
                        tooltip: 'بزرگ‌نمایی',
                        onTap: () {
                          final zoom =
                              mapController
                                  .camera
                                  .zoom;

                          mapController.move(
                            mapController
                                .camera
                                .center,
                            zoom + 1,
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      _MapControlButton(
                        icon: Icons.remove,
                        tooltip: 'کوچک‌نمایی',
                        onTap: () {
                          final zoom =
                              mapController
                                  .camera
                                  .zoom;

                          mapController.move(
                            mapController
                                .camera
                                .center,
                            zoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // --------------------------------------------
                // LOCATION LOADING
                // --------------------------------------------

                if (locationLoading)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.94),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 17,
                            height: 17,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'در حال پیدا کردن مکان شما...',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ==================================================
          // BUTTONS UNDER MAP
          // ==================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              8,
              8,
              8,
              10,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MapCategoryButton(
                        icon: Icons.hotel,
                        title: 'اقامتگاه',
                        active: showLodging,
                        onTap: () {
                          _toggleCategory(
                            'اقامتگاه',
                            showLodging,
                            (value) {
                              showLodging = value;
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: _MapCategoryButton(
                        icon:
                            Icons.account_balance,
                        title:
                            'جاذبه گردشگری',
                        active:
                            showAttractions,
                        onTap: () {
                          _toggleCategory(
                            'جاذبه گردشگری',
                            showAttractions,
                            (value) {
                              showAttractions =
                                  value;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: _MapCategoryButton(
                        icon:
                            Icons.local_hospital,
                        title:
                            'گردشگری سلامت',
                        active: showHealth,
                        onTap: () {
                          _toggleCategory(
                            'گردشگری سلامت',
                            showHealth,
                            (value) {
                              showHealth = value;
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: _MapCategoryButton(
                        icon: Icons.build,
                        title: 'خدماتی',
                        active: showServices,
                        onTap: () {
                          _toggleCategory(
                            'خدماتی',
                            showServices,
                            (value) {
                              showServices =
                                  value;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: _MapCategoryButton(
                        icon: Icons.layers,
                        title: 'همه',
                        active: allActive,
                        onTap: _showAll,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: _MapCategoryButton(
                        icon:
                            Icons.arrow_back_rounded,
                        title:
                            'بازگشت به Cyrus Tourist',
                        active: false,
                        onTap: () {
                          Navigator.of(context)
                              .pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP CONTROL BUTTON
// ============================================================

class _MapControlButton
    extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color:
                  const Color(0xff075b86),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP CATEGORY BUTTON
// ============================================================

class _MapCategoryButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _MapCategoryButton({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? const Color(0xff075b86)
          : const Color(0xffeef3f6),
      borderRadius:
          BorderRadius.circular(13),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 5,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active
                    ? Colors.white
                    : const Color(
                        0xff075b86,
                      ),
              ),

              const SizedBox(width: 5),

              Flexible(
                child: Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : const Color(
                            0xff06121d,
                          ),
                    fontSize: 12,
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
}
