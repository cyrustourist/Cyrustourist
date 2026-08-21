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

    if (lang == AppLanguage.persian) {
      await pref.setString('language', 'fa');
    } else if (lang == AppLanguage.arabic) {
      await pref.setString('language', 'ar');
    } else {
      await pref.setString('language', 'en');
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
// ICONS
// ============================================================

class AppIcons {
  static IconData get(int number) {
    switch (number) {
      case 1:
        return Icons.map_rounded;

      case 2:
        return Icons.health_and_safety_rounded;

      case 3:
        return Icons.location_on_rounded;

      case 4:
        return Icons.ondemand_video_rounded;

      case 5:
        return Icons.hotel_rounded;

      case 6:
        return Icons.explore_rounded;

      case 7:
        return Icons.language_rounded;

      case 8:
        return Icons.info_outline_rounded;

      case 9:
        return Icons.support_agent_rounded;

      case 10:
        return Icons.star_rounded;

      default:
        return Icons.apps_rounded;
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
  int _selectedButton = 0;

  String get _homeImage {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'assets/images/home_fa.jpg';

      case AppLanguage.english:
        return 'assets/images/home_en.jpg';

      case AppLanguage.arabic:
        return 'assets/images/home_ar.jpg';
    }
  }

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
            decoration: const BoxDecoration(
              color: Color(0xff071722),
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
                    color: Colors.white30,
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
      trailing:
          LanguageManager.current == language
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

  // ==========================================================
  // BUTTON ACTION
  // ==========================================================

  Future<void> serviceTap(int number) async {
    setState(() {
      _selectedButton = number;
    });

    await Future.delayed(
      const Duration(milliseconds: 180),
    );

    if (!mounted) return;

    setState(() {
      _selectedButton = 0;
    });

    if (number == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SmartMapPage(),
        ),
      );
    } else {
      _showComingSoon(number);
    }
  }

  void _showComingSoon(int number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
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

  // ==========================================================
  // HOME BUTTON
  // ==========================================================

  Widget serviceButton(
    int number, {
    required double width,
    required double height,
  }) {
    final selected =
        _selectedButton == number;

    return GestureDetector(
      onTap: () => serviceTap(number),

      child: AnimatedScale(
        scale: selected ? 0.92 : 1.0,

        duration:
            const Duration(milliseconds: 100),

        curve: Curves.easeOut,

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 120),

          width: width,
          height: height,

          margin:
              const EdgeInsets.all(4),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color:
                  const Color(0xffffd36a)
                      .withValues(
                alpha:
                    selected
                        ? 0.95
                        : 0.55,
              ),
              width: 1.2,
            ),

            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Colors.white.withValues(
                  alpha:
                      selected
                          ? 0.28
                          : 0.18,
                ),
                const Color(0xff0b506b)
                    .withValues(
                  alpha:
                      selected
                          ? 0.78
                          : 0.62,
                ),
              ],
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha:
                      selected
                          ? 0.75
                          : 0.45,
                ),
                blurRadius:
                    selected ? 5 : 10,
                offset:
                    Offset(
                  0,
                  selected ? 2 : 5,
                ),
              ),

              BoxShadow(
                color:
                    const Color(0xffffd36a)
                        .withValues(
                  alpha:
                      selected
                          ? 0.35
                          : 0.10,
                ),
                blurRadius:
                    selected ? 12 : 4,
              ),
            ],
          ),

          child: Stack(
            children: [
              Positioned(
                top: 2,
                left: 8,
                right: 8,
                child: Container(
                  height: 1.5,
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white
                            .withValues(
                          alpha: 0.75,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Center(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),

                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [
                      Icon(
                        AppIcons.get(
                          number,
                        ),

                        color:
                            const Color(
                          0xffffd36a,
                        ),

                        size:
                            height * 0.28,

                        shadows: const [
                          Shadow(
                            color:
                                Colors.black87,
                            blurRadius: 4,
                            offset:
                                Offset(1, 2),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        AppText.button(
                          number,
                        ),

                        maxLines: 2,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          color:
                              Colors.white,

                          fontSize:
                              height < 70
                                  ? 8.5
                                  : 10,

                          height: 1.05,

                          fontWeight:
                              FontWeight.w800,

                          shadows: const [
                            Shadow(
                              color:
                                  Colors.black,
                              blurRadius: 3,
                              offset:
                                  Offset(1, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        '$number',

                        style:
                            TextStyle(
                          color:
                              const Color(
                            0xffffd36a,
                          ),

                          fontSize:
                              height < 70
                                  ? 8
                                  : 9,

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
      ),
    );
  }

  Widget buildButtons(
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
              for (
                int i = 1;
                i <= 5;
                i++
              )
                serviceButton(
                  i,
                  width:
                      buttonWidth,
                  height:
                      buttonHeight,
                ),
            ],
          ),

          const SizedBox(
            height: 4,
          ),

          Row(
            children: [
              for (
                int i = 6;
                i <= 10;
                i++
              )
                serviceButton(
                  i,
                  width:
                      buttonWidth,
                  height:
                      buttonHeight,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HOME BUILD
  // ==========================================================

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
                  width:
                      imageWidth,
                  height:
                      imageHeight,

                  child: Stack(
                    fit:
                        StackFit.expand,

                    children: [
                      Image.asset(
                        _homeImage,
                        fit:
                            BoxFit.cover,
                      ),

                      IgnorePointer(
                        child:
                            Container(
                          decoration:
                              BoxDecoration(
                            gradient:
                                LinearGradient(
                              begin:
                                  Alignment
                                      .topCenter,
                              end:
                                  Alignment
                                      .bottomCenter,
                              colors: [
                                Colors.black
                                    .withValues(
                                  alpha:
                                      0.08,
                                ),
                                Colors
                                    .transparent,
                                Colors.black
                                    .withValues(
                                  alpha:
                                      0.20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // LANGUAGE
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
                              horizontal:
                                  12,
                              vertical:
                                  8,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xff0b506b,
                              ).withValues(
                                alpha: 0.88,
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
                                  alpha:
                                      0.75,
                                ),
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black
                                          .withValues(
                                    alpha:
                                        0.55,
                                  ),
                                  blurRadius:
                                      9,
                                  offset:
                                      const Offset(
                                    0,
                                    4,
                                  ),
                                ),
                              ],
                            ),

                            child: Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,

                              children: [
                                const Icon(
                                  Icons
                                      .language,
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
                                        Colors
                                            .white,
                                    fontWeight:
                                        FontWeight
                                            .bold,
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
                      // TITLE
                      // ==================================================

                      Positioned(
                        top:
                            imageHeight *
                                0.12,

                        left: 15,
                        right: 15,

                        child:
                            IgnorePointer(
                          child: Text(
                            AppText
                                .title(),

                            textAlign:
                                TextAlign
                                    .center,

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  imageWidth *
                                      0.075,

                              fontWeight:
                                  FontWeight
                                      .w900,

                              letterSpacing:
                                  LanguageManager
                                              .current ==
                                          AppLanguage
                                              .english
                                      ? 1.5
                                      : 0,

                              shadows:
                                  const [
                                Shadow(
                                  color:
                                      Colors.black,
                                  blurRadius:
                                      8,
                                  offset:
                                      Offset(
                                    2,
                                    3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      buildButtons(
                        imageWidth,
                        imageHeight,
                      ),

                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,

                        child:
                            IgnorePointer(
                          child: Text(
                            LanguageManager
                                        .current ==
                                    AppLanguage
                                        .persian
                                ? 'همراه هوشمند سفر شما'
                                : LanguageManager
                                            .current ==
                                        AppLanguage
                                            .arabic
                                    ? 'رفيقك الذكي في السفر'
                                    : 'Your Smart Travel Companion',

                            textAlign:
                                TextAlign
                                    .center,

                            style:
                                TextStyle(
                              color:
                                  const Color(
                                0xffffd36a,
                              ),

                              fontSize:
                                  imageWidth *
                                      0.027,

                              fontWeight:
                                  FontWeight
                                      .bold,

                              shadows:
                                  const [
                                Shadow(
                                  color:
                                      Colors.black,
                                  blurRadius:
                                      5,
                                ),
                              ],
                            ),
                          ),
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
// SMART MAP PAGE
// ============================================================

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() =>
      _SmartMapPageState();
}

class _SmartMapPageState
    extends State<SmartMapPage>
    with SingleTickerProviderStateMixin {

  final MapController mapController =
      MapController();

  static const LatLng iranCenter =
      LatLng(
    32.4279,
    53.6880,
  );

  LatLng? userLocation;

  bool loading = true;
  bool mapReady = false;

  late AnimationController
      _animationController;

  late Animation<double>
      _scaleAnimation;

  late Animation<double>
      _rotationAnimation;

  late Animation<double>
      _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,

      duration:
          const Duration(
        seconds: 3,
      ),
    )..repeat();

    _scaleAnimation =
        Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent:
            _animationController,
        curve:
            Curves.easeInOut,
      ),
    );

    _rotationAnimation =
        Tween<double>(
      begin: 0,
      end: 6.283185,
    ).animate(
      CurvedAnimation(
        parent:
            _animationController,
        curve:
            Curves.linear,
      ),
    );

    _glowAnimation =
        Tween<double>(
      begin: 0.25,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent:
            _animationController,
        curve:
            Curves.easeInOut,
      ),
    );

    WidgetsBinding
        .instance
        .addPostFrameCallback(
      (_) {
        _prepareMap();
      },
    );
  }

  @override
  void dispose() {
    _animationController
        .dispose();

    super.dispose();
  }

  // ==========================================================
  // PREPARE MAP
  // ==========================================================

  Future<void> _prepareMap() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      mapReady = false;
    });

    await Future.delayed(
      const Duration(
        milliseconds: 1800,
      ),
    );

    if (!mounted) return;

    setState(() {
      mapReady = true;
    });

    await getLocation();
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

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
              LocationPermission.denied ||
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

      final point =
          LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        userLocation =
            point;

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

  // ==========================================================
  // MARKERS
  // ==========================================================

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

  // ==========================================================
  // LOADING TEXT
  // ==========================================================

  String get loadingTitle {
    switch (
        LanguageManager.current) {
      case AppLanguage.persian:
        return 'در حال آماده‌سازی نقشه گردشگری...';

      case AppLanguage.english:
        return 'Preparing Tourism Map...';

      case AppLanguage.arabic:
        return 'جارٍ إعداد الخريطة السياحية...';
    }
  }

  String get loadingSubtitle {
    switch (
        LanguageManager.current) {
      case AppLanguage.persian:
        return 'لطفاً چند لحظه صبر کنید';

      case AppLanguage.english:
        return 'Please wait a moment';

      case AppLanguage.arabic:
        return 'يرجى الانتظار لحظة';
    }
  }

  String get locationText {
    switch (
        LanguageManager.current) {
      case AppLanguage.persian:
        return 'در حال بررسی موقعیت شما...';

      case AppLanguage.english:
        return 'Checking your location...';

      case AppLanguage.arabic:
        return 'جارٍ تحديد موقعك...';
    }
  }

  // ==========================================================
  // PROFESSIONAL LOADING SCREEN
  // ==========================================================

  Widget loadingScreen() {
    return Container(
      color:
          const Color(0xff071722),

      child:
          Center(
        child:
            AnimatedBuilder(
          animation:
              _animationController,

          builder:
              (context, child) {
            return Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                // ==================================================
                // LOGO + RINGS
                // ==================================================

                SizedBox(
                  width: 210,
                  height: 210,

                  child:
                      Stack(
                    alignment:
                        Alignment
                            .center,

                    children: [
                      // OUTER RING

                      Transform.rotate(
                        angle:
                            _rotationAnimation
                                .value,

                        child:
                            Container(
                          width: 190,
                          height: 190,

                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xffffd36a,
                              ).withValues(
                                alpha:
                                    _glowAnimation
                                        .value,
                              ),

                              width: 2,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(
                                  0xffffd36a,
                                ).withValues(
                                  alpha:
                                      _glowAnimation
                                          .value *
                                      0.45,
                                ),

                                blurRadius:
                                    25,

                                spreadRadius:
                                    3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // INNER RING

                      Transform.rotate(
                        angle:
                            -_rotationAnimation
                                .value,

                        child:
                            Container(
                          width: 155,
                          height: 155,

                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xff0b8caf,
                              ).withValues(
                                alpha:
                                    0.8,
                              ),

                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // LOGO

                      Transform.scale(
                        scale:
                            _scaleAnimation
                                .value,

                        child:
                            Container(
                          width: 112,
                          height: 112,

                          padding:
                              const EdgeInsets
                                  .all(
                            8,
                          ),

                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,

                            color:
                                Colors.white,

                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(
                                  0xffffd36a,
                                ).withValues(
                                  alpha:
                                      _glowAnimation
                                          .value,
                                ),

                                blurRadius:
                                    28,

                                spreadRadius:
                                    3,
                              ),
                            ],
                          ),

                          child:
                              ClipOval(
                            child:
                                Image.asset(
                              'assets/images/logo-new.jpg',

                              fit:
                                  BoxFit
                                      .cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // APP NAME
                // ==================================================

                Text(
                  AppText.title(),

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xffffd36a,
                    ),

                    fontSize: 25,

                    fontWeight:
                        FontWeight.w900,

                    shadows: [
                      Shadow(
                        color:
                            Colors.black,
                        blurRadius:
                            8,
                        offset:
                            Offset(
                          1,
                          2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // LOADING TITLE
                // ==================================================

                Text(
                  loadingTitle,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize: 15,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // ==================================================
                // SUBTITLE
                // ==================================================

                Text(
                  loadingSubtitle,

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.70,
                    ),

                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // PROGRESS
                // ==================================================

                SizedBox(
                  width: 190,

                  child:
                      ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),

                    child:
                        const LinearProgressIndicator(
                      minHeight: 4,

                      backgroundColor:
                          Color(
                        0xff183746,
                      ),

                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Color(
                          0xffffd36a,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // MAP PAGE
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          AppText.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,

      child:
          Scaffold(
        backgroundColor:
            const Color(0xff071722),

        appBar:
            AppBar(
          backgroundColor:
              const Color(
            0xff071722,
          ),

          foregroundColor:
              Colors.white,

          title:
              Text(
            AppText.map(),

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          centerTitle:
              true,
        ),

        body:
            Stack(
          children: [
            // ====================================================
            // MAP
            // ====================================================

            Column(
              children: [
                Expanded(
                  child:
                      Stack(
                    children: [
                      FlutterMap(
                        mapController:
                            mapController,

                        options:
                            const MapOptions(
                          initialCenter:
                              iranCenter,

                          initialZoom:
                              5,
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

                      // ==================================================
                      // LOCATION BUTTON
                      // ==================================================

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
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .my_location,
                                    ),
                        ),
                      ),

                      // ==================================================
                      // LOCATION STATUS
                      // ==================================================

                      if (loading &&
                          mapReady)
                        Positioned(
                          top: 15,
                          left: 15,
                          right: 15,

                          child:
                              Center(
                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    16,
                                vertical:
                                    10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xff071722,
                                ).withValues(
                                  alpha:
                                      0.90,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  25,
                                ),

                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xffffd36a,
                                  ).withValues(
                                    alpha:
                                        0.55,
                                  ),
                                ),
                              ),

                              child:
                                  Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,

                                children: [
                                  const SizedBox(
                                    width:
                                        16,
                                    height:
                                        16,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,

                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        Color(
                                          0xffffd36a,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                        10,
                                  ),

                                  Text(
                                    locationText,

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .white,

                                      fontSize:
                                          11,

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
                    ],
                  ),
                ),

                // ==================================================
                // MAP TOOLBOX
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets
                          .all(10),

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
                            LanguageManager.current ==
                                    AppLanguage
                                        .persian
                                ? 'اقامتگاه'
                                : LanguageManager
                                            .current ==
                                        AppLanguage
                                            .arabic
                                    ? 'الإقامة'
                                    : 'Accommodation',
                          ),

                          mapServiceButton(
                            Icons.place,
                            LanguageManager.current ==
                                    AppLanguage
                                        .persian
                                ? 'جاذبه‌ها'
                                : LanguageManager
                                            .current ==
                                        AppLanguage
                                            .arabic
                                    ? 'المعالم'
                                    : 'Attractions',
                          ),

                          mapServiceButton(
                            Icons.health_and_safety,
                            LanguageManager.current ==
                                    AppLanguage
                                        .persian
                                ? 'سلامت'
                                : LanguageManager
                                            .current ==
                                        AppLanguage
                                            .arabic
                                    ? 'الصحة'
                                    : 'Health',
                          ),

                          mapServiceButton(
                            Icons
                                .miscellaneous_services,
                            LanguageManager.current ==
                                    AppLanguage
                                        .persian
                                ? 'خدمات'
                                : LanguageManager
                                            .current ==
                                        AppLanguage
                                            .arabic
                                    ? 'الخدمات'
                                    : 'Services',
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

                          child:
                              Text(
                            AppText.title(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ====================================================
            // PROFESSIONAL LOADING SCREEN
            // ====================================================

            if (!mapReady)
              Positioned.fill(
                child:
                    loadingScreen(),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MAP TOOLBOX BUTTON
  // ==========================================================

  Widget mapServiceButton(
    IconData icon,
    String text,
  ) {
    return Expanded(
      child:
          Container(
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

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withValues(
                alpha: 0.30,
              ),

              blurRadius: 8,

              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child:
            Column(
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

            const SizedBox(
              height: 3,
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
