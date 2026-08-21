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

  static String title() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'سایروس توریست';

      case AppLanguage.english:
        return 'Cyrus Tourist';

      case AppLanguage.arabic:
        return 'سايروس توريست';
    }
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

  static String button(int number) {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        const items = [
          '',
          'نقشه گردشگری',
          'گردشگری سلامت',
          'جاذبه‌های گردشگری',
          'فیلم‌های گردشگری',
          'اقامتگاه',
          'راهنمای سفر',
          'شبکه‌های اجتماعی',
          'درباره ما',
          'پشتیبانی و تماس',
          'علاقه‌مندی‌ها',
        ];
        return items[number];

      case AppLanguage.english:
        const items = [
          '',
          'Tourism Map',
          'Health Tourism',
          'Tourist Attractions',
          'Tourism Videos',
          'Accommodation',
          'Travel Guide',
          'Social Networks',
          'About Us',
          'Support & Contact',
          'Favorites',
        ];
        return items[number];

      case AppLanguage.arabic:
        const items = [
          '',
          'خريطة السياحة',
          'السياحة العلاجية',
          'المعالم السياحية',
          'أفلام سياحية',
          'الإقامة',
          'دليل السفر',
          'الشبكات الاجتماعية',
          'معلومات عنا',
          'الدعم والاتصال',
          'المفضلة',
        ];
        return items[number];
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
// IMAGE CONTAINS ALL VISUAL TEXT AND BUTTONS
// FLUTTER ONLY PROVIDES TRANSPARENT TOUCH AREAS
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pressedButton = 0;

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
      builder: (_) {
        return Directionality(
          textDirection:
              AppText.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              25,
            ),
            decoration: const BoxDecoration(
              color: Color(0xff071722),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),

                _languageItem(
                  '🇮🇷',
                  'پارسی',
                  AppLanguage.persian,
                ),

                _languageItem(
                  '🇬🇧',
                  'English',
                  AppLanguage.english,
                ),

                _languageItem(
                  '🇸🇦',
                  'العربية',
                  AppLanguage.arabic,
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
    String flag,
    String title,
    AppLanguage language,
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
  // BUTTON ACTION
  // ----------------------------------------------------------

  Future<void> serviceTap(int number) async {
    setState(() {
      _pressedButton = number;
    });

    await Future.delayed(
      const Duration(milliseconds: 180),
    );

    if (!mounted) return;

    setState(() {
      _pressedButton = 0;
    });

    switch (number) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SmartMapPage(),
          ),
        );
        break;

      case 2:
        _showComingSoon(number);
        break;

      case 3:
        _showComingSoon(number);
        break;

      case 4:
        _showComingSoon(number);
        break;

      case 5:
        _showComingSoon(number);
        break;

      case 6:
        _showComingSoon(number);
        break;

      case 7:
        _showComingSoon(number);
        break;

      case 8:
        _showComingSoon(number);
        break;

      case 9:
        _showComingSoon(number);
        break;

      case 10:
        _showComingSoon(number);
        break;
    }
  }

  void _showComingSoon(int number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xff0b506b),
        content: Text(
          AppText.button(number),
          textAlign:
              AppText.rtl
                  ? TextAlign.right
                  : TextAlign.left,
        ),
        duration:
            const Duration(seconds: 2),
      ),
    );
  }

  // ----------------------------------------------------------
  // TRANSPARENT TOUCH BUTTON
  // ----------------------------------------------------------

  Widget touchButton({
    required int number,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final selected =
        _pressedButton == number;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior:
            HitTestBehavior.translucent,
        onTap: () => serviceTap(number),
        child: AnimatedScale(
          scale: selected ? 0.94 : 1.0,
          duration:
              const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(
                      alpha: 0.08,
                    )
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(18),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xffffd36a,
                        ).withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD HOME
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder:
                (context, constraints) {
              final screenWidth =
                  constraints.maxWidth;

              final screenHeight =
                  constraints.maxHeight;

              double width =
                  screenWidth;

              double height =
                  width * 16 / 9;

              if (height >
                  screenHeight) {
                height =
                    screenHeight;

                width =
                    height * 9 / 16;
              }

              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      // ==================================================
                      // LANGUAGE-SPECIFIC IMAGE
                      // ==================================================

                      Positioned.fill(
                        child: Image.asset(
                          homeImage,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // ==================================================
                      // LANGUAGE BUTTON
                      // ==================================================

                      Positioned(
                        top: height * 0.025,
                        left:
                            AppText.rtl
                                ? null
                                : width * 0.035,
                        right:
                            AppText.rtl
                                ? width * 0.035
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
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xff0b506b,
                              ).withValues(
                                alpha: 0.90,
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
                                  alpha: 0.85,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withValues(
                                    alpha: 0.55,
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
                                  MainAxisSize
                                      .min,
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
                                  width: 5,
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
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // TOUCH AREAS
                      //
                      // 5 BUTTONS TOP ROW
                      // 5 BUTTONS BOTTOM ROW
                      //
                      // Coordinates are relative to the 9:16 image.
                      // ==================================================

                      touchButton(
                        number: 1,
                        left: width * 0.00,
                        top: height * 0.695,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 2,
                        left: width * 0.20,
                        top: height * 0.695,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 3,
                        left: width * 0.40,
                        top: height * 0.695,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 4,
                        left: width * 0.60,
                        top: height * 0.695,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 5,
                        left: width * 0.80,
                        top: height * 0.695,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 6,
                        left: width * 0.00,
                        top: height * 0.805,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 7,
                        left: width * 0.20,
                        top: height * 0.805,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 8,
                        left: width * 0.40,
                        top: height * 0.805,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 9,
                        left: width * 0.60,
                        top: height * 0.805,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      touchButton(
                        number: 10,
                        left: width * 0.80,
                        top: height * 0.805,
                        width: width * 0.20,
                        height: height * 0.10,
                      ),

                      // ==================================================
                      // MAP SPECIAL LIGHT EFFECT
                      // ==================================================

                      Positioned(
                        left: width * 0.01,
                        top: height * 0.695,
                        width: width * 0.18,
                        height: height * 0.10,
                        child:
                            IgnorePointer(
                          child:
                              const _MapPulseEffect(),
                        ),
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
// MAP PULSE EFFECT
// ============================================================

class _MapPulseEffect extends StatefulWidget {
  const _MapPulseEffect();

  @override
  State<_MapPulseEffect> createState() =>
      _MapPulseEffectState();
}

class _MapPulseEffectState
    extends State<_MapPulseEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final value =
            _controller.value;

        return Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(
                0xffffd36a,
              ).withValues(
                alpha:
                    0.08 +
                    (value * 0.18),
              ),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// SMART MAP PAGE
// ============================================================

class SmartMapPage
    extends StatefulWidget {
  const SmartMapPage({super.key});

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

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        getLocation();
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

      LocationPermission
          permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission
              .denied) {
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

    if (userLocation !=
        null) {
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
              color: Colors.blue
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

  String mapServiceText(
    String fa,
    String en,
    String ar,
  ) {
    switch (
        LanguageManager
            .current) {
      case AppLanguage.persian:
        return fa;

      case AppLanguage.english:
        return en;

      case AppLanguage.arabic:
        return ar;
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Directionality(
      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            const Color(
          0xff071722,
        ),
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
                      child: loading
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

            // ==================================================
            // MAP SERVICES
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(
                10,
              ),
              color:
                  const Color(
                0xff071722,
              ),
              child:
                  Column(
                children: [
                  Row(
                    children: [
                      mapServiceButton(
                        Icons.hotel,
                        mapServiceText(
                          'اقامتگاه',
                          'Accommodation',
                          'الإقامة',
                        ),
                      ),
                      mapServiceButton(
                        Icons.place,
                        mapServiceText(
                          'جاذبه‌ها',
                          'Attractions',
                          'المعالم',
                        ),
                      ),
                      mapServiceButton(
                        Icons.health_and_safety,
                        mapServiceText(
                          'سلامت',
                          'Health',
                          'الصحة',
                        ),
                      ),
                      mapServiceButton(
                        Icons
                            .miscellaneous_services,
                        mapServiceText(
                          'خدمات',
                          'Services',
                          'الخدمات',
                        ),
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
                        AppText.title(),
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
    String text,
  ) {
    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.all(
          4,
        ),
        height: 70,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
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
                  TextOverflow
                      .ellipsis,
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
