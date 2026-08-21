import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CyrusTouristApp());
}

// ============================================================
// APP
// ============================================================

class CyrusTouristApp extends StatelessWidget {
  const CyrusTouristApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyrus Tourist',
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

class LanguageManager {
  static AppLanguage current = AppLanguage.english;

  static Future<void> load() async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getString('language');

    if (saved == 'fa') {
      current = AppLanguage.persian;
    } else if (saved == 'ar') {
      current = AppLanguage.arabic;
    } else if (saved == 'en') {
      current = AppLanguage.english;
    } else {
      final code = WidgetsBinding
          .instance
          .platformDispatcher
          .locale
          .languageCode
          .toLowerCase();

      if (code == 'fa') {
        current = AppLanguage.persian;
      } else if (code == 'ar') {
        current = AppLanguage.arabic;
      } else {
        current = AppLanguage.english;
      }
    }
  }

  static Future<void> setLanguage(AppLanguage lang) async {
    current = lang;

    final pref = await SharedPreferences.getInstance();

    switch (lang) {
      case AppLanguage.persian:
        await pref.setString('language', 'fa');
        break;

      case AppLanguage.english:
        await pref.setString('language', 'en');
        break;

      case AppLanguage.arabic:
        await pref.setString('language', 'ar');
        break;
    }
  }
}

// ============================================================
// TEXT
// ============================================================

class AppText {
  static bool get rtl {
    return LanguageManager.current != AppLanguage.english;
  }

  static String languageName() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'پارسی';

      case AppLanguage.english:
        return 'English';

      case AppLanguage.arabic:
        return 'العربية';
    }
  }

  static String map() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'نقشه گردشگری';

      case AppLanguage.english:
        return 'Tourism Map';

      case AppLanguage.arabic:
        return 'خريطة السياحة';
    }
  }

  static String mapLoading() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'در حال آماده‌سازی نقشه...';

      case AppLanguage.english:
        return 'Preparing the map...';

      case AppLanguage.arabic:
        return 'جارٍ تجهيز الخريطة...';
    }
  }

  static String locationSearching() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'در حال پیدا کردن موقعیت شما';

      case AppLanguage.english:
        return 'Finding your location';

      case AppLanguage.arabic:
        return 'جارٍ تحديد موقعك';
    }
  }

  static String locationUnavailable() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'موقعیت مکانی در دسترس نیست';

      case AppLanguage.english:
        return 'Location is unavailable';

      case AppLanguage.arabic:
        return 'الموقع غير متاح';
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
    _start();
  }

  Future<void> _start() async {
    await LanguageManager.load();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pressedButton = 0;

  // ----------------------------------------------------------
  // SELECT LANGUAGE IMAGE
  // ----------------------------------------------------------

  String get homeImage {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'assets/images/home_fa.jpg';

      case AppLanguage.english:
        return 'assets/images/home_en.jpg';

      case AppLanguage.arabic:
        return 'assets/images/home_ar.jpg';
    }
  }

  // ----------------------------------------------------------
  // LANGUAGE
  // ----------------------------------------------------------

  Future<void> openLanguage() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection:
              AppText.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xff0b506b),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _languageItem(
                  'پارسی',
                  AppLanguage.persian,
                  '🇮🇷',
                ),

                _languageItem(
                  'English',
                  AppLanguage.english,
                  '🇬🇧',
                ),

                _languageItem(
                  'العربية',
                  AppLanguage.arabic,
                  '🇸🇦',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Widget _languageItem(
    String title,
    AppLanguage language,
    String flag,
  ) {
    final selected =
        LanguageManager.current == language;

    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(
          fontSize: 25,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_circle,
              color: Color(0xffffd36a),
            )
          : null,
      onTap: () async {
        await LanguageManager.setLanguage(
          language,
        );

        if (!mounted) return;

        Navigator.pop(context);

        setState(() {});
      },
    );
  }

  // ----------------------------------------------------------
  // BUTTON TOUCH
  // ----------------------------------------------------------

  Future<void> serviceTap(int number) async {
    setState(() {
      _pressedButton = number;
    });

    // افکت فشرده شدن
    await Future.delayed(
      const Duration(milliseconds: 130),
    );

    if (!mounted) return;

    // --------------------------------------------------------
    // MAP BUTTON
    // --------------------------------------------------------

    if (number == 1) {
      setState(() {
        _pressedButton = 0;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MapLoadingPage(),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // OTHER BUTTONS
    // --------------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 80),
    );

    if (!mounted) return;

    setState(() {
      _pressedButton = 0;
    });
  }

  // ----------------------------------------------------------
  // TRANSPARENT TOUCH BUTTON
  // ----------------------------------------------------------

  Widget touchButton({
    required int number,
    required double width,
    required double height,
  }) {
    final selected =
        _pressedButton == number;

    return GestureDetector(
      behavior:
          HitTestBehavior.translucent,

      onTap: () {
        serviceTap(number);
      },

      child: AnimatedScale(
        scale:
            selected ? 0.91 : 1.0,

        duration:
            const Duration(milliseconds: 110),

        curve:
            Curves.easeOutBack,

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 110),

          width: width,
          height: height,

          decoration: BoxDecoration(
            color:
                Colors.transparent,

            borderRadius:
                BorderRadius.circular(18),

            boxShadow:
                selected
                    ? [
                        BoxShadow(
                          color:
                              const Color(
                            0xffffd36a,
                          ).withValues(
                            alpha: 0.60,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUTTON POSITION
  // ----------------------------------------------------------

  Widget buildTouchAreas(
    double width,
    double height,
  ) {
    final buttonWidth =
        width / 5;

    final buttonHeight =
        height * 0.105;

    return Positioned(
      left: 3,
      right: 3,
      bottom: height * 0.075,
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                touchButton(
                  number: i,
                  width: buttonWidth,
                  height: buttonHeight,
                ),
            ],
          ),

          const SizedBox(
            height: 4,
          ),

          Row(
            children: [
              for (int i = 6; i <= 10; i++)
                touchButton(
                  number: i,
                  width: buttonWidth,
                  height: buttonHeight,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HOME
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,

      child: Scaffold(
        backgroundColor:
            Colors.black,

        body: SafeArea(
          child: LayoutBuilder(
            builder:
                (
                  context,
                  constraints,
                ) {
              final screenWidth =
                  constraints.maxWidth;

              final screenHeight =
                  constraints.maxHeight;

              double imageWidth =
                  screenWidth;

              double imageHeight =
                  imageWidth * 16 / 9;

              if (imageHeight >
                  screenHeight) {
                imageHeight =
                    screenHeight;

                imageWidth =
                    imageHeight * 9 / 16;
              }

              return Center(
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,

                  child: Stack(
                    fit: StackFit.expand,

                    children: [
                      // ==================================================
                      // LANGUAGE IMAGE
                      // ==================================================

                      Image.asset(
                        homeImage,
                        fit: BoxFit.cover,
                      ),

                      // ==================================================
                      // LANGUAGE BUTTON
                      // ==================================================

                      Positioned(
                        top: 15,

                        left:
                            AppText.rtl
                                ? null
                                : 15,

                        right:
                            AppText.rtl
                                ? 15
                                : null,

                        child:
                            GestureDetector(
                          onTap:
                              openLanguage,

                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xff0b506b,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),

                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xffffd36a,
                                ).withValues(
                                  alpha: 0.80,
                                ),
                                width: 1.2,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors
                                          .black
                                          .withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 9,
                                  offset:
                                      const Offset(
                                    0,
                                    4,
                                  ),
                                ),
                              ],
                            ),

                            child:
                                Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                const Icon(
                                  Icons.language,
                                  color:
                                      Color(
                                    0xffffd36a,
                                  ),
                                  size: 18,
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  AppText
                                      .languageName(),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // 10 TRANSPARENT TOUCH AREAS
                      // ==================================================

                      buildTouchAreas(
                        imageWidth,
                        imageHeight,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP LOADING PAGE
// ============================================================

class MapLoadingPage extends StatefulWidget {
  const MapLoadingPage({super.key});

  @override
  State<MapLoadingPage> createState() =>
      _MapLoadingPageState();
}

class _MapLoadingPageState
    extends State<MapLoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController
      _animationController;

  late Animation<double>
      _scaleAnimation;

  LatLng? foundLocation;

  bool searching = true;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 1100,
      ),
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(
      CurvedAnimation(
        parent:
            _animationController,
        curve:
            Curves.easeInOut,
      ),
    );

    _prepareMap();
  }

  Future<void> _prepareMap() async {
    LatLng? location;

    try {
      final enabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (enabled) {
        LocationPermission permission =
            await Geolocator
                .checkPermission();

        if (permission ==
            LocationPermission.denied) {
          permission =
              await Geolocator
                  .requestPermission();
        }

        if (permission !=
                LocationPermission.denied &&
            permission !=
                LocationPermission
                    .deniedForever) {
          final position =
              await Geolocator
                  .getCurrentPosition(
            locationSettings:
                const LocationSettings(
              accuracy:
                  LocationAccuracy.high,
            ),
          ).timeout(
            const Duration(
              seconds: 8,
            ),
          );

          location = LatLng(
            position.latitude,
            position.longitude,
          );
        }
      }
    } catch (_) {
      location = null;
    }

    if (!mounted) return;

    setState(() {
      foundLocation = location;
      searching = false;
    });

    // اجازه بده انیمیشن کوتاه کامل شود
    await Future.delayed(
      const Duration(
        milliseconds: 650,
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SmartMapPage(
          initialLocation:
              foundLocation,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              AnimatedBuilder(
                animation:
                    _scaleAnimation,

                builder:
                    (
                      context,
                      child,
                    ) {
                  return Transform.scale(
                    scale:
                        _scaleAnimation.value,

                    child:
                        Container(
                      width: 105,
                      height: 105,

                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,

                        color:
                            const Color(
                          0xff0b506b,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xffffd36a,
                          ),
                          width: 2,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xffffd36a,
                            ).withValues(
                              alpha: 0.45,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),

                      child:
                          const Icon(
                        Icons
                            .location_on_rounded,
                        color:
                            Color(
                          0xffffd36a,
                        ),
                        size: 58,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 35,
              ),

              Text(
                AppText.mapLoading(),
                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                searching
                    ? AppText
                        .locationSearching()
                    : AppText
                        .mapLoading(),

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      const Color(
                    0xffffd36a,
                  ).withValues(
                    alpha: 0.90,
                  ),
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              const SizedBox(
                width: 28,
                height: 28,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                      Color(0xffffd36a),
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
// SMART MAP PAGE
// ============================================================

class SmartMapPage extends StatefulWidget {
  final LatLng? initialLocation;

  const SmartMapPage({
    super.key,
    this.initialLocation,
  });

  @override
  State<SmartMapPage> createState() =>
      _SmartMapPageState();
}

class _SmartMapPageState
    extends State<SmartMapPage> {
  final MapController
      mapController =
      MapController();

  static const LatLng iranCenter =
      LatLng(
    32.4279,
    53.6880,
  );

  LatLng? userLocation;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    userLocation =
        widget.initialLocation;

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (userLocation != null) {
          mapController.move(
            userLocation!,
            13,
          );
        }
      },
    );
  }

  Future<void> getLocation() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final enabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!enabled) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return;
      }

      LocationPermission permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission
                  .denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition();

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
        13,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  List<Marker> markers() {
    final list =
        <Marker>[];

    if (userLocation != null) {
      list.add(
        Marker(
          point:
              userLocation!,

          width: 60,
          height: 60,

          child:
              Container(
            decoration:
                BoxDecoration(
              color:
                  Colors.blue
                      .withValues(
                alpha: 0.25,
              ),
              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons.my_location,
              color:
                  Colors.blue,
              size: 35,
            ),
          ),
        ),
      );
    }

    return list;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
              const Color(
            0xff071722,
          ),

          foregroundColor:
              Colors.white,

          title: Text(
            AppText.map(),
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          centerTitle: true,
        ),

        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController:
                        mapController,

                    options:
                        MapOptions(
                      initialCenter:
                          userLocation ??
                              iranCenter,

                      initialZoom:
                          userLocation !=
                                  null
                              ? 13
                              : 5,
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
                            markers(),
                      ),
                    ],
                  ),

                  Positioned(
                    right: 15,
                    bottom: 15,

                    child:
                        FloatingActionButton(
                      backgroundColor:
                          Colors.white,

                      onPressed:
                          getLocation,

                      child:
                          loading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : const Icon(
                                  Icons
                                      .my_location,
                                ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                10,
              ),

              color:
                  const Color(
                0xff071722,
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      mapServiceButton(
                        Icons.hotel,
                        'Accommodation',
                        'الإقامة',
                        'اقامتگاه',
                      ),

                      mapServiceButton(
                        Icons.place,
                        'Attractions',
                        'المعالم',
                        'جاذبه‌ها',
                      ),

                      mapServiceButton(
                        Icons
                            .health_and_safety,
                        'Health',
                        'الصحة',
                        'سلامت',
                      ),

                      mapServiceButton(
                        Icons
                            .miscellaneous_services,
                        'Services',
                        'الخدمات',
                        'خدمات',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child: Text(
                        LanguageManager
                                    .current ==
                                AppLanguage
                                    .persian
                            ? 'بازگشت'
                            : LanguageManager
                                        .current ==
                                    AppLanguage
                                        .arabic
                                ? 'رجوع'
                                : 'Back',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget mapServiceButton(
    IconData icon,
    String english,
    String arabic,
    String persian,
  ) {
    String text;

    switch (
        LanguageManager.current) {
      case AppLanguage.persian:
        text = persian;
        break;

      case AppLanguage.arabic:
        text = arabic;
        break;

      case AppLanguage.english:
        text = english;
        break;
    }

    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.all(4),

        height: 70,

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              color:
                  const Color(
                0xff0b506b,
              ),
            ),

            Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
