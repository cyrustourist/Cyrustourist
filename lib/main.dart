import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

class AppLanguageStore {
  static const String _fileName = 'cyrustourist_language.txt';

  static String get _filePath {
    // Package ID پروژه
    return '/data/user/0/cyrustourist.ir.app/files/$_fileName';
  }

  static Future<AppLanguage?> load() async {
    try {
      final file = File(_filePath);

      if (!await file.exists()) {
        return null;
      }

      final value = (await file.readAsString()).trim();

      switch (value) {
        case 'persian':
          return AppLanguage.persian;
        case 'english':
          return AppLanguage.english;
        case 'arabic':
          return AppLanguage.arabic;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(AppLanguage language) async {
    try {
      final file = File(_filePath);

      await file.parent.create(recursive: true);

      await file.writeAsString(
        language.name,
        encoding: utf8,
        flush: true,
      );
    } catch (_) {
      // اگر ذخیره‌سازی به هر دلیل ممکن نبود،
      // خود برنامه همچنان بدون هنگ و خطا کار می‌کند.
    }
  }
}

// ============================================================
// APP LANGUAGE CONTROLLER
// ============================================================

class AppLanguageController extends ChangeNotifier {
  AppLanguage? _manualLanguage;
  bool _loaded = false;

  AppLanguage get language {
    if (_manualLanguage != null) {
      return _manualLanguage!;
    }

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

  bool get hasManualLanguage => _manualLanguage != null;

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    _manualLanguage = await AppLanguageStore.load();
    _loaded = true;

    notifyListeners();
  }

  Future<void> setManualLanguage(AppLanguage language) async {
    _manualLanguage = language;

    notifyListeners();

    await AppLanguageStore.save(language);
  }
}

final AppLanguageController appLanguageController =
    AppLanguageController();

// ============================================================
// LANGUAGE TEXT
// ============================================================

class AppText {
  static AppLanguage get language =>
      appLanguageController.language;

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
        return 'نمایش فیلم';
      case AppLanguage.arabic:
        return 'عرض الأفلام';
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
        return 'برای نمایش موقعیت شما، لطفاً مکان‌نما را روشن کنید.';
      case AppLanguage.arabic:
        return 'لعرض موقعك، يرجى تشغيل الموقع.';
      case AppLanguage.english:
        return 'Please turn on location to show your position.';
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

  static String languageName(AppLanguage value) {
    switch (value) {
      case AppLanguage.persian:
        return 'پارسی';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.arabic:
        return 'العربية';
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
    await appLanguageController.load();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    appLanguageController.addListener(_languageChanged);
  }

  @override
  void dispose() {
    appLanguageController.removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return Directionality(
          textDirection:
              AppText.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xff071722),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xffd7a33d),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppText.languageName(AppText.language),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 12),

                _languageChoice(
                  context,
                  AppLanguage.persian,
                  'پارسی',
                  'فا',
                ),

                const SizedBox(height: 8),

                _languageChoice(
                  context,
                  AppLanguage.english,
                  'English',
                  'EN',
                ),

                const SizedBox(height: 8),

                _languageChoice(
                  context,
                  AppLanguage.arabic,
                  'العربية',
                  'ع',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageChoice(
    BuildContext context,
    AppLanguage language,
    String title,
    String badge,
  ) {
    final selected =
        AppText.language == language;

    return GestureDetector(
      onTap: () async {
        await appLanguageController
            .setManualLanguage(language);

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 150),
        height: 54,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [
                    const Color(0xff0b6c83),
                    const Color(0xff0b506b),
                  ]
                : [
                    const Color(0xff123747),
                    const Color(0xff09212d),
                  ],
          ),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xffd7a33d)
                : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    const Color(0xffd7a33d),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xffd7a33d),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return Directionality(
          textDirection:
              AppText.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          child: Scaffold(
            backgroundColor:
                const Color(0xff06121d),
            body: SafeArea(
              child: Center(
                child: AspectRatio(
                  // home.jpg واقعی:
                  // 1024 × 1536 = نسبت 2:3
                  aspectRatio: 2 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [

                      // ==================================================
                      // ORIGINAL HOME IMAGE
                      // بدون هیچ تغییر در خود تصویر
                      // ==================================================

                      Image.asset(
                        'assets/images/home.jpg',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color:
                                const Color(0xff06121d),
                            alignment:
                                Alignment.center,
                            child: const Text(
                              'CyrusTourist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),

                      // ==================================================
                      // LANGUAGE BUTTON
                      // مستقل از تصویر
                      // بالا - سمت چپ
                      // ==================================================

                      Positioned(
                        top: 10,
                        left: 10,
                        child: _languageButton(),
                      ),

                      // ==================================================
                      // TRANSPARENT TOUCH AREAS
                      // فقط لمس؛ هیچ ظاهر جدیدی روی عکس نیست.
                      // ==================================================

                      LayoutBuilder(
                        builder:
                            (context, constraints) {
                          final w =
                              constraints.maxWidth;
                          final h =
                              constraints.maxHeight;

                          return Stack(
                            children: [

                              // ------------------------------
                              // 1 - نقشه گردشگری
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.02,
                                top: h * 0.48,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SmartMapPage(),
                                    ),
                                  );
                                },
                              ),

                              // ------------------------------
                              // 2
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.21,
                                top: h * 0.48,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 3
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.41,
                                top: h * 0.48,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 4
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.61,
                                top: h * 0.48,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 5
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.81,
                                top: h * 0.48,
                                width: w * 0.17,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 6
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.02,
                                top: h * 0.64,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 7
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.21,
                                top: h * 0.64,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 8
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.41,
                                top: h * 0.64,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 9
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.61,
                                top: h * 0.64,
                                width: w * 0.18,
                                height: h * 0.14,
                                onTap: () {},
                              ),

                              // ------------------------------
                              // 10
                              // ------------------------------

                              _transparentHitArea(
                                left: w * 0.81,
                                top: h * 0.64,
                                width: w * 0.17,
                                height: h * 0.14,
                                onTap: () {},
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _languageButton() {
    String badge;

    switch (AppText.language) {
      case AppLanguage.persian:
        badge = 'فا';
        break;
      case AppLanguage.english:
        badge = 'EN';
        break;
      case AppLanguage.arabic:
        badge = 'ع';
        break;
    }

    return GestureDetector(
      onTap: _openLanguageSelector,
      child: Container(
        width: 58,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff1590a3),
              Color(0xff073c52),
            ],
          ),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xffd7a33d),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 9,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.language_rounded,
              color: Colors.white,
              size: 19,
            ),
            const SizedBox(width: 4),
            Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transparentHitArea({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior:
            HitTestBehavior.translucent,
        onTap: onTap,
        child: const SizedBox.expand(),
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

        _showLocationMessage(
          AppText.locationOff(),
          Icons.location_off_rounded,
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
          Icons.location_disabled_rounded,
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

      _showLocationMessage(
        AppText.locationOff(),
        Icons.location_searching_rounded,
      );
    }
  }

  void _showLocationMessage(
    String message,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          backgroundColor:
              const Color(0xff071722),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffd7a33d),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  textAlign: AppText.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          duration:
              const Duration(seconds: 4),
        ),
      );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          content: Text(
            message,
            textAlign:
                TextAlign.center,
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
            decoration:
                BoxDecoration(
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
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color:
                const Color(0xff0b506b),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.30,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color:
              const Color(0xff0b506b),
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
          foregroundColor:
              Colors.white,
          centerTitle: true,
          title: Text(
            AppText.map(),
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
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
                            _markers(),
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
                                BorderRadius
                                    .circular(22),
                          ),
                          child: Text(
                            AppText.mapReady(),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

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
                        0xff0b506b,
                      ),
                      onPressed:
                          _loadUserLocation,
                      child:
                          locationLoading
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
      decoration:
          const BoxDecoration(
        color: Color(0xff071722),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 82,
            child: Row(
              children: [
                Expanded(
                  child:
                      MapServiceButton(
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
                  child:
                      MapServiceButton(
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
                  child:
                      MapServiceButton(
                    icon: Icons
                        .health_and_safety_rounded,
                    title:
                        AppText.health(),
                    onTap:
                        onHealth,
                  ),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child:
                      MapServiceButton(
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
            child:
                ElevatedButton.icon(
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
        scale:
            pressed ? 0.93 : 1.0,
        duration:
            const Duration(
          milliseconds: 100,
        ),
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 100,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 5,
          ),
          decoration:
              BoxDecoration(
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
                      pressed
                          ? 0.15
                          : 0.40,
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
                    const Color(
                  0xff0b506b,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                widget.title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
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
