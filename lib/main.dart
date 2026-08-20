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
      ),
      home: const SplashPage(),
    );
  }
}

// ============================================================
// LANGUAGE
// ============================================================

enum AppLanguage {
  persian,
  english,
  arabic,
}

class AppText {
  static AppLanguage get language {
    final code = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();

    if (code == 'fa') return AppLanguage.persian;
    if (code == 'ar') return AppLanguage.arabic;

    return AppLanguage.english;
  }

  static bool get rtl => language != AppLanguage.english;

  static String homeTitle() {
    switch (language) {
      case AppLanguage.persian:
        return 'سایروس توریست';
      case AppLanguage.arabic:
        return 'سايروس توريست';
      case AppLanguage.english:
        return 'Cyrus Tourist';
    }
  }

  static String map() {
    switch (language) {
      case AppLanguage.persian:
        return 'نقشه گردشگری';
      case AppLanguage.arabic:
        return 'خريطة السياحة';
      case AppLanguage.english:
        return 'Tourism Map';
    }
  }

  static String residence() {
    switch (language) {
      case AppLanguage.persian:
        return 'اقامتگاه';
      case AppLanguage.arabic:
        return 'أماكن الإقامة';
      case AppLanguage.english:
        return 'Residence';
    }
  }

  static String films() {
    switch (language) {
      case AppLanguage.persian:
        return 'فیلم‌های گردشگری';
      case AppLanguage.arabic:
        return 'أفلام سياحية';
      case AppLanguage.english:
        return 'Tourism Films';
    }
  }

  static String attractions() {
    switch (language) {
      case AppLanguage.persian:
        return 'جاذبه‌های گردشگری';
      case AppLanguage.arabic:
        return 'المعالم السياحية';
      case AppLanguage.english:
        return 'Tourist Attractions';
    }
  }

  static String nearby() {
    switch (language) {
      case AppLanguage.persian:
        return 'جاذبه‌های اطراف من';
      case AppLanguage.arabic:
        return 'المعالم القريبة مني';
      case AppLanguage.english:
        return 'Attractions Around Me';
    }
  }

  static String iran() {
    switch (language) {
      case AppLanguage.persian:
        return 'ایران';
      case AppLanguage.arabic:
        return 'إيران';
      case AppLanguage.english:
        return 'Iran';
    }
  }

  static String guide() {
    switch (language) {
      case AppLanguage.persian:
        return 'راهنمای سفر';
      case AppLanguage.arabic:
        return 'دليل السفر';
      case AppLanguage.english:
        return 'Travel Guide';
    }
  }

  static String me() {
    switch (language) {
      case AppLanguage.persian:
        return 'من';
      case AppLanguage.arabic:
        return 'أنا';
      case AppLanguage.english:
        return 'Me';
    }
  }

  static String favorites() {
    switch (language) {
      case AppLanguage.persian:
        return 'علاقه‌مندی‌ها';
      case AppLanguage.arabic:
        return 'المفضلة';
      case AppLanguage.english:
        return 'Favorites';
    }
  }

  static String support() {
    switch (language) {
      case AppLanguage.persian:
        return 'پشتیبانی و تماس';
      case AppLanguage.arabic:
        return 'الدعم والاتصال';
      case AppLanguage.english:
        return 'Support & Contact';
    }
  }

  static String about() {
    switch (language) {
      case AppLanguage.persian:
        return 'درباره ما';
      case AppLanguage.arabic:
        return 'معلومات عنا';
      case AppLanguage.english:
        return 'About Us';
    }
  }

  static String social() {
    switch (language) {
      case AppLanguage.persian:
        return 'شبکه‌های اجتماعی';
      case AppLanguage.arabic:
        return 'الشبكات الاجتماعية';
      case AppLanguage.english:
        return 'Social Networks';
    }
  }

  static String slogan() {
    switch (language) {
      case AppLanguage.persian:
        return 'سفر، کشف، لذت';
      case AppLanguage.arabic:
        return 'سافر، اكتشف، استمتع';
      case AppLanguage.english:
        return 'Travel, Discover, Enjoy';
    }
  }

  static String locationOff() {
    switch (language) {
      case AppLanguage.persian:
        return 'برای پیدا کردن بهترین جاذبه‌های اطراف شما، لطفاً مکان‌نما را روشن کنید.';
      case AppLanguage.arabic:
        return 'للعثور على أفضل المعالم القريبة منك، يرجى تشغيل الموقع.';
      case AppLanguage.english:
        return 'To find the best attractions around you, please turn on your location.';
    }
  }

  static String locationPermission() {
    switch (language) {
      case AppLanguage.persian:
        return 'اجازه دسترسی به مکان برای نمایش موقعیت شما لازم است.';
      case AppLanguage.arabic:
        return 'يلزم السماح بالوصول إلى الموقع لعرض موقعك.';
      case AppLanguage.english:
        return 'Location permission is required to show your position.';
    }
  }

  static String locationFound() {
    switch (language) {
      case AppLanguage.persian:
        return 'مکان شما روی نقشه نمایش داده شد.';
      case AppLanguage.arabic:
        return 'تم عرض موقعك على الخريطة.';
      case AppLanguage.english:
        return 'Your location is now shown on the map.';
    }
  }

  static String mapReady() {
    switch (language) {
      case AppLanguage.persian:
        return 'نقشه گردشگری آماده است';
      case AppLanguage.arabic:
        return 'خريطة السياحة جاهزة';
      case AppLanguage.english:
        return 'Tourism map is ready';
    }
  }

  static String back() {
    switch (language) {
      case AppLanguage.persian:
        return 'بازگشت';
      case AppLanguage.arabic:
        return 'رجوع';
      case AppLanguage.english:
        return 'Back';
    }
  }

  static String healthTourism() {
    switch (language) {
      case AppLanguage.persian:
        return 'گردشگری سلامت';
      case AppLanguage.arabic:
        return 'السياحة العلاجية';
      case AppLanguage.english:
        return 'Health Tourism';
    }
  }

  static String services() {
    switch (language) {
      case AppLanguage.persian:
        return 'خدماتی';
      case AppLanguage.arabic:
        return 'الخدمات';
      case AppLanguage.english:
        return 'Services';
    }
  }

  static String comingSoon() {
    switch (language) {
      case AppLanguage.persian:
        return 'این بخش در مرحله بعد فعال می‌شود.';
      case AppLanguage.arabic:
        return 'سيتم تفعيل هذا القسم في المرحلة القادمة.';
      case AppLanguage.english:
        return 'This section will be activated in the next stage.';
    }
  }

  static String serviceNextStage() {
    switch (language) {
      case AppLanguage.persian:
        return 'این بخش در مرحله بعد تکمیل می‌شود.';
      case AppLanguage.arabic:
        return 'سيتم استكمال هذا القسم في المرحلة القادمة.';
      case AppLanguage.english:
        return 'This section will be completed in the next stage.';
    }
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
          errorBuilder: (_, __, ___) {
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          AppText.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [

                // ==================================================
                // HOME IMAGE
                // ==================================================

                Image.asset(
                  'assets/images/home.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xff06121d),
                    );
                  },
                ),

                // ==================================================
                // DARK OVERLAY
                // ==================================================

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // HOME CONTENT
                // ==================================================

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        16,
                        12,
                        10,
                      ),
                      child: Column(
                        children: [

                          Text(
                            'CYRUS TOURIST',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  constraints.maxWidth < 380
                                      ? 20
                                      : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            AppText.homeTitle(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==================================================
                          // 10 BUTTONS
                          // ==================================================

                          Expanded(
                            child: GridView.builder(
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: 10,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.48,
                              ),
                              itemBuilder: (context, index) {
                                final number = index + 1;

                                return HomeServiceButton(
                                  number: number,
                                  title:
                                      _homeTitle(number),
                                  icon:
                                      _homeIcon(number),
                                  active: number == 1,
                                  onTap: () {
                                    _handleHomeButton(
                                      context,
                                      number,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            AppText.slogan(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 2),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [

                              TextButton(
                                onPressed: () {
                                  _showInfo(
                                    context,
                                    AppText.about(),
                                  );
                                },
                                child: Text(
                                  AppText.about(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),

                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  _showInfo(
                                    context,
                                    AppText.social(),
                                  );
                                },
                                child: Text(
                                  AppText.social(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _homeTitle(int number) {
    switch (number) {
      case 1:
        return AppText.map();
      case 2:
        return AppText.residence();
      case 3:
        return AppText.films();
      case 4:
        return AppText.attractions();
      case 5:
        return AppText.nearby();
      case 6:
        return AppText.iran();
      case 7:
        return AppText.guide();
      case 8:
        return AppText.me();
      case 9:
        return AppText.favorites();
      case 10:
        return AppText.support();
      default:
        return '';
    }
  }

  IconData _homeIcon(int number) {
    switch (number) {
      case 1:
        return Icons.map_rounded;
      case 2:
        return Icons.hotel_rounded;
      case 3:
        return Icons.movie_rounded;
      case 4:
        return Icons.account_balance_rounded;
      case 5:
        return Icons.location_on_rounded;
      case 6:
        return Icons.flag_rounded;
      case 7:
        return Icons.menu_book_rounded;
      case 8:
        return Icons.person_rounded;
      case 9:
        return Icons.favorite_rounded;
      case 10:
        return Icons.support_agent_rounded;
      default:
        return Icons.circle;
    }
  }

  void _handleHomeButton(
    BuildContext context,
    int number,
  ) {
    if (number == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SmartMapPage(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${_homeTitle(number)}\n${AppText.comingSoon()}',
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _showInfo(
    BuildContext context,
    String title,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(AppText.slogan()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppText.back()),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// HOME SERVICE BUTTON
// ============================================================

class HomeServiceButton extends StatefulWidget {
  final int number;
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const HomeServiceButton({
    super.key,
    required this.number,
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<HomeServiceButton> createState() =>
      _HomeServiceButtonState();
}

class _HomeServiceButtonState
    extends State<HomeServiceButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: widget.active ? 0.95 : 0.88,
            ),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: pressed ? 0.18 : 0.38,
                ),
                blurRadius: pressed ? 4 : 12,
                offset: Offset(
                  0,
                  pressed ? 2 : 6,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 6,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            const Color(0xff0b506b),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 5,
                            offset:
                                const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xffd7a33d),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff09212d),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
  State<SmartMapPage> createState() =>
      _SmartMapPageState();
}

class _SmartMapPageState
    extends State<SmartMapPage> {
  final MapController mapController =
      MapController();

  static const LatLng iranCenter =
      LatLng(32.4279, 53.6880);

  LatLng? userLocation;

  bool locationLoading = false;
  bool locationEnabled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadUserLocation();
    });
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> _loadUserLocation() async {
    if (locationLoading) return;

    if (mounted) {
      setState(() {
        locationLoading = true;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          locationEnabled = false;
          locationLoading = false;
        });

        _showLocationMessage(
          AppText.locationOff(),
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          locationEnabled = false;
          locationLoading = false;
        });

        _showLocationMessage(
          AppText.locationPermission(),
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

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        userLocation = location;
        locationEnabled = true;
        locationLoading = false;
      });

      mapController.move(
        location,
        13.0,
      );

      _showLocationMessage(
        AppText.locationFound(),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        locationLoading = false;
        locationEnabled = false;
      });
    }
  }

  void _showLocationMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          duration:
              const Duration(seconds: 3),
        ),
      );
  }

  // ==========================================================
  // TEST MARKERS
  // ==========================================================

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    markers.add(
      _categoryMarker(
        const LatLng(35.6892, 51.3890),
        Icons.account_balance,
      ),
    );

    markers.add(
      _categoryMarker(
        const LatLng(35.7000, 51.4200),
        Icons.museum,
      ),
    );

    markers.add(
      _categoryMarker(
        const LatLng(35.7219, 51.3347),
        Icons.park,
      ),
    );

    markers.add(
      _categoryMarker(
        const LatLng(35.6700, 51.4300),
        Icons.location_city,
      ),
    );

    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 58,
          height: 58,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(
                alpha: 0.18,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 34,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Marker _categoryMarker(
    LatLng point,
    IconData icon,
  ) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xff0b506b),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.30,
              ),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xff0b506b),
          size: 27,
        ),
      ),
    );
  }

  // ==========================================================
  // MAP PAGE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            const Color(0xff071722),

        appBar: AppBar(
          backgroundColor:
              const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            AppText.map(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: Column(
          children: [

            // ==================================================
            // REAL MAP
            // ==================================================

            Expanded(
              child: Stack(
                children: [

                  FlutterMap(
                    mapController:
                        mapController,
                    options: const MapOptions(
                      initialCenter:
                          iranCenter,
                      initialZoom: 5.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                    ),
                    children: [

                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'cyrustourist.ir.app',
                      ),

                      MarkerLayer(
                        markers:
                            _buildMarkers(),
                      ),
                    ],
                  ),

                  // ==================================================
                  // MAP TITLE
                  // ==================================================

                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.black.withValues(
                              alpha: 0.62,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              22,
                            ),
                          ),
                          child: Text(
                            AppText.mapReady(),
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // MY LOCATION
                  // ==================================================

                  Positioned(
                    bottom: 18,
                    right: 14,
                    child: FloatingActionButton(
                      heroTag:
                          'myLocationButton',
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          const Color(
                        0xff0b506b,
                      ),
                      onPressed:
                          _loadUserLocation,
                      child: locationLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              locationEnabled
                                  ? Icons
                                      .my_location
                                  : Icons
                                      .location_searching,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // SERVICES BELOW MAP
            // ==================================================

            _MapServicesPanel(
              onResidence: () {
                _showMapService(
                  context,
                  AppText.residence(),
                );
              },
              onAttractions: () {
                _showMapService(
                  context,
                  AppText.attractions(),
                );
              },
              onHealth: () {
                _showMapService(
                  context,
                  AppText.healthTourism(),
                );
              },
              onServices: () {
                _showMapService(
                  context,
                  AppText.services(),
                );
              },
              onBack: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMapService(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title\n${AppText.serviceNextStage()}',
            textAlign: TextAlign.center,
          ),
          duration:
              const Duration(seconds: 2),
        ),
      );
  }
}

// ============================================================
// MAP SERVICES PANEL
// ============================================================

class _MapServicesPanel
    extends StatelessWidget {
  final VoidCallback onResidence;
  final VoidCallback onAttractions;
  final VoidCallback onHealth;
  final VoidCallback onServices;
  final VoidCallback onBack;

  const _MapServicesPanel({
    required this.onResidence,
    required this.onAttractions,
    required this.onHealth,
    required this.onServices,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff071722),
      ),
      child: Column(
        children: [

          // ==================================================
          // FOUR SERVICE BUTTONS
          // ==================================================

          SizedBox(
            height: 82,
            child: Row(
              children: [

                Expanded(
                  child: MapServiceButton(
                    icon:
                        Icons.hotel_rounded,
                    title:
                        AppText.residence(),
                    onTap: onResidence,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon: Icons
                        .account_balance_rounded,
                    title:
                        AppText.attractions(),
                    onTap: onAttractions,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon:
                        Icons.favorite_rounded,
                    title:
                        AppText.healthTourism(),
                    onTap: onHealth,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon: Icons
                        .miscellaneous_services_rounded,
                    title:
                        AppText.services(),
                    onTap: onServices,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // ==================================================
          // BACK TO CYRUS TOURIST
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: Text(
                AppText.homeTitle(),
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xffd7a33d),
                foregroundColor:
                    Colors.white,
                elevation: 8,
                shadowColor:
                    Colors.black,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP SERVICE BUTTON
// ============================================================

class MapServiceButton
    extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MapServiceButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<MapServiceButton> createState() =>
      _MapServiceButtonState();
}

class _MapServiceButtonState
    extends State<MapServiceButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedScale(
        scale: pressed ? 0.93 : 1.0,
        duration:
            const Duration(milliseconds: 100),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color:
                  const Color(0xffd7a33d),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha:
                      pressed ? 0.15 : 0.40,
                ),
                blurRadius:
                    pressed ? 3 : 8,
                offset: Offset(
                  0,
                  pressed ? 1 : 4,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              Icon(
                widget.icon,
                size: 25,
                color:
                    const Color(0xff0b506b),
              ),

              const SizedBox(height: 3),

              Text(
                widget.title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color:
                      Color(0xff09212d),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
