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
// CYRUS TOURIST
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

    if (code == 'fa') {
      return AppLanguage.persian;
    }

    if (code == 'ar') {
      return AppLanguage.arabic;
    }

    return AppLanguage.english;
  }

  static bool get rtl {
    return language != AppLanguage.english;
  }

  static String title() {
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
        return 'برای پیدا کردن بهترین مکان‌ها، لطفاً مکان‌نما را روشن کنید.';
      case AppLanguage.arabic:
        return 'للعثور على أفضل الأماكن، يرجى تشغيل الموقع.';
      case AppLanguage.english:
        return 'To find the best places, please turn on your location.';
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
        return 'نقشه گردشگری';
      case AppLanguage.arabic:
        return 'خريطة السياحة';
      case AppLanguage.english:
        return 'Tourism Map';
    }
  }

  static String backToHome() {
    switch (language) {
      case AppLanguage.persian:
        return 'بازگشت به سایروس توریست';
      case AppLanguage.arabic:
        return 'العودة إلى سايروس توريست';
      case AppLanguage.english:
        return 'Back to Cyrus Tourist';
    }
  }

  static String health() {
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
}

// ============================================================
// SPLASH
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
          child: Stack(
            fit: StackFit.expand,
            children: [

              // عکس دوم
              Image.asset(
                'assets/images/home.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: const Color(0xff06121d),
                  );
                },
              ),

              // لایه بسیار ملایم برای خوانایی کلیدها
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),

              // محتوای روی عکس
              LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      14,
                      12,
                      10,
                    ),
                    child: Column(
                      children: [

                        // عنوان
                        Text(
                          'CYRUS TOURIST',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                constraints.maxWidth < 380
                                    ? 21
                                    : 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
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
                          AppText.title(),
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

                        // ۱۰ کلید روی عکس
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

                              return HomeButton(
                                number: number,
                                title:
                                    _homeTitle(number),
                                icon:
                                    _homeIcon(number),
                                onTap: () {
                                  _homeAction(
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
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

  void _homeAction(
    BuildContext context,
    int number,
  ) {
    // فقط کلید شماره ۱ فعلاً وارد نقشه می‌شود.
    if (number == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SmartMapPage(),
        ),
      );
      return;
    }

    // کلیدهای ۲ تا ۱۰ برای مرحله بعد
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${_homeTitle(number)}\n${AppText.comingSoon()}',
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ============================================================
// HOME BUTTON
// ============================================================

class HomeButton extends StatefulWidget {
  final int number;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HomeButton({
    super.key,
    required this.number,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> {
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
        scale: pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: pressed ? 0.78 : 0.91,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xffd7a33d),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: pressed ? 0.18 : 0.40,
                ),
                blurRadius: pressed ? 4 : 11,
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
                            color: Colors.black
                                .withValues(alpha: 0.28),
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

                    const SizedBox(width: 7),

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
  // USER LOCATION
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

        _showMessage(
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

        _showMessage(
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

      _showMessage(
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

  void _showMessage(String message) {
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
  // SAMPLE MARKERS
  // ==========================================================

  List<Marker> _markers() {
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
          width: 62,
          height: 62,
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
                size: 35,
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
      width: 52,
      height: 52,
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
          size: 28,
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
                        markers: _markers(),
                      ),
                    ],
                  ),

                  // عنوان بالای نقشه
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.black
                                .withValues(
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

                  // کلید مکان من
                  Positioned(
                    bottom: 18,
                    right: 14,
                    child:
                        FloatingActionButton(
                      heroTag:
                          'myLocationButton',
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          const Color(
                              0xff0b506b),
                      onPressed:
                          _loadUserLocation,
                      child: locationLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
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

            MapServicesPanel(
              onResidence: () {
                _serviceMessage(
                  AppText.residence(),
                );
              },
              onAttractions: () {
                _serviceMessage(
                  AppText.attractions(),
                );
              },
              onHealth: () {
                _serviceMessage(
                  AppText.health(),
                );
              },
              onServices: () {
                _serviceMessage(
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

  void _serviceMessage(String title) {
    _showMessage(
      '$title\n${AppText.comingSoon()}',
    );
  }
}

// ============================================================
// MAP SERVICES PANEL
// ============================================================

class MapServicesPanel extends StatelessWidget {
  final VoidCallback onResidence;
  final VoidCallback onAttractions;
  final VoidCallback onHealth;
  final VoidCallback onServices;
  final VoidCallback onBack;

  const MapServicesPanel({
    super.key,
    required this.onResidence,
    required this.onAttractions,
    required this.onHealth,
    required this.onServices,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        10,
        9,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff071722),
      ),
      child: Column(
        children: [

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
                    onTap:
                        onResidence,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon: Icons
                        .account_balance_rounded,
                    title:
                        AppText.attractions(),
                    onTap:
                        onAttractions,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon:
                        Icons.health_and_safety_rounded,
                    title:
                        AppText.health(),
                    onTap:
                        onHealth,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: MapServiceButton(
                    icon: Icons
                        .miscellaneous_services_rounded,
                    title:
                        AppText.services(),
                    onTap:
                        onServices,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: Text(
                AppText.backToHome(),
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
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 100),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 3,
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
                textAlign: TextAlign.center,
                style:
                    const TextStyle(
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
