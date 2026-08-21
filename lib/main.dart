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
  int selected = 0;

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

  Future<void> openLanguage() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff071722),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lang('پارسی', AppLanguage.persian),
          _lang('English', AppLanguage.english),
          _lang('العربية', AppLanguage.arabic),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _lang(String text, AppLanguage lang) {
    return ListTile(
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        await LanguageManager.setLanguage(lang);
        if (mounted) {
          Navigator.pop(context);
          setState(() {});
        }
      },
    );
  }

  Future<void> tap(int n) async {
    setState(() => selected = n);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => selected = 0);

    if (n == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartMapPage()),
      );
    }
  }

  Widget area(int n, double l, double t, double w, double h,
      double iw, double ih) {
    return Positioned(
      left: iw * l,
      top: ih * t,
      width: iw * w,
      height: ih * h,
      child: GestureDetector(
        onTap: () => tap(n),
        child: AnimatedScale(
          scale: selected == n ? .92 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: selected == n
                  ? [
                      BoxShadow(
                        color: const Color(0xffffd36a)
                            .withValues(alpha: .8),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            double w = c.maxWidth;
            double h = w * 16 / 9;

            if (h > c.maxHeight) {
              h = c.maxHeight;
              w = h * 9 / 16;
            }

            return Center(
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(homeImage, fit: BoxFit.cover),

                    Positioned(
                      top: 15,
                      right: AppText.rtl ? 15 : null,
                      left: AppText.rtl ? null : 15,
                      child: GestureDetector(
                        onTap: openLanguage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xff0b506b),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xffffd36a),
                            ),
                          ),
                          child: Text(
                            AppText.languageName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    area(1,.02,.62,.18,.10,w,h),
                    area(2,.21,.62,.18,.10,w,h),
                    area(3,.40,.62,.18,.10,w,h),
                    area(4,.59,.62,.18,.10,w,h),
                    area(5,.78,.62,.18,.10,w,h),
                    area(6,.02,.73,.18,.10,w,h),
                    area(7,.21,.73,.18,.10,w,h),
                    area(8,.40,.73,.18,.10,w,h),
                    area(9,.59,.73,.18,.10,w,h),
                    area(10,.78,.73,.18,.10,w,h),
                  ],
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
