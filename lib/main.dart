import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notification_service.dart';
import 'config/map_ir_config.dart';
import 'config/carto_config.dart';

import 'map_place.dart';
import 'core/language/app_language.dart';
import 'core/language/menu_translations.dart';
import 'services/map_places_service.dart';
import 'pages/category_explorer_page.dart';
import 'pages/favorites_page.dart';

// ============================================================
// NEW PAGES
// ============================================================

import 'pages/video_page.dart';
import 'pages/travel/travel_guide_page.dart' as travel_guide;

// ------------------------------------------------------------
// فایل‌های هدر و کلیدهای ۷/۸/۹ (اتصال نهایی)
// ------------------------------------------------------------
import 'widgets/cyrus_language_button.dart';
import 'widgets/cyrus_header_account_button.dart';
import 'widgets/toolbox/cyrus_smart_toolbox.dart';
import 'widgets/account/cyrus_account_screen.dart';
import 'widgets/search/cyrus_smart_search.dart';
import 'widgets/settings/cyrus_settings_screen.dart';

// ============================================================
// MAIN
// ============================================================

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init ignored on web/unsupported platforms: $e');
  }

  await NotificationService.instance.initialize();

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
      navigatorKey: navigatorKey,
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
// TEXT & MULTI-LANGUAGE MANAGEMENT
// ============================================================

class AppText {
  static String map() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'نقشه';
      case AppLanguage.arabic:
        return 'الخريطة';
      case AppLanguage.english:
        return 'Map';
      case AppLanguage.german:
        return 'Karte';
      case AppLanguage.spanish:
        return 'Mapa';
      case AppLanguage.french:
        return 'Carte';
      case AppLanguage.italian:
        return 'Mappa';
      case AppLanguage.russian:
        return 'Карта';
      case AppLanguage.turkish:
        return 'Harita';
      case AppLanguage.chinese:
        return '地图';
    }
  }

  static bool get rtl =>
      LanguageManager.current == AppLanguage.persian ||
      LanguageManager.current == AppLanguage.arabic;

  static String title() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'سایروس توریست';
      case AppLanguage.arabic:
        return 'سايروس توريست';
      case AppLanguage.english:
      case AppLanguage.german:
      case AppLanguage.spanish:
      case AppLanguage.french:
      case AppLanguage.italian:
      case AppLanguage.russian:
      case AppLanguage.turkish:
      case AppLanguage.chinese:
        return 'Cyrus Tourist';
    }
  }

  static String languageName() {
    return LanguageManager.languageName(LanguageManager.current);
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

    LanguageManager.load();
    MenuLanguage.load();
    MenuTranslations.preloadAll();

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
      },
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
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Cyrus Tourist',
                style: TextStyle(
                  color: Color(0xffffd36a),
                  fontSize: 28,
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
  int selected = 0;
  int _headerBadgeTick = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.maybePlayNewAnnouncementSound();
  }

  String get homeImage => 'assets/images/home-hero.jpg';

  String buttonTitle(int number) {
    switch (number) {
      case 1:
        return 'نقشه گردشگری';
      case 2:
        return 'گردشگری سلامت';
      case 3:
        return 'جاذبه‌های گردشگری';
      case 4:
        return 'نمایش فیلم';
      case 5:
        return 'اقامتگاه‌ها';
      case 6:
        return 'راهنمای سفر';
      case 7:
        return 'جعبه ابزار';
      case 8:
        return 'حساب کاربری';
      case 9:
        return 'جستجوی هوشمند';
      case 10:
        return 'علاقه‌مندی‌ها';
      default:
        return 'Cyrus Tourist';
    }
  }

  Future<void> tap(int number) async {
    setState(() {
      selected = number;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    setState(() {
      selected = 0;
    });

    if (number == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartMapPage()));
      return;
    }

    if (number == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryExplorerPage(initialCategory: PlaceCategory.health),
        ),
      );
      return;
    }

    if (number == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryExplorerPage(initialCategory: PlaceCategory.attraction),
        ),
      );
      return;
    }

    if (number == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPage()));
      return;
    }

    if (number == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryExplorerPage(initialCategory: PlaceCategory.accommodation),
        ),
      );
      return;
    }

    if (number == 6) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => travel_guide.TravelGuidePage()));
      return;
    }

    if (number == 7) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CyrusSmartToolbox(languageCode: MenuLanguage.current),
        ),
      );
      return;
    }

    if (number == 8) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CyrusAccountScreen(languageCode: MenuLanguage.current),
        ),
      );
      return;
    }

    if (number == 9) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CyrusSmartSearch(languageCode: MenuLanguage.current),
        ),
      );
      return;
    }

    if (number == 10) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkInProgressPage(number: number, title: buttonTitle(number)),
      ),
    );
  }

  Widget area(
    int number,
    double left,
    double top,
    double width,
    double height,
    double imageWidth,
    double imageHeight,
  ) {
    return Positioned(
      left: imageWidth * left,
      top: imageHeight * top,
      width: imageWidth * width,
      height: imageHeight * height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => tap(number),
          child: Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.63,
              child: AnimatedScale(
                scale: selected == number ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selected == number
                        ? [
                            BoxShadow(
                              color: const Color(0xffffd36a).withValues(alpha: 0.8),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget caption(
    int number,
    double left,
    double top,
    double width,
    double height,
    double imageWidth,
    double imageHeight, {
    required double captionTop,
    double boxHeight = 0.038,
  }) {
    final text = MenuTranslations.title(MenuLanguage.current, number);
    final label = text.isNotEmpty ? text : buttonTitle(number);

    return Positioned(
      left: imageWidth * left,
      top: imageHeight * captionTop,
      width: imageWidth * width,
      height: imageHeight * boxHeight,
      child: IgnorePointer(
        child: Directionality(
          textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: Color(0xfffff4be),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2.5,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
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
      drawer: _buildMenuDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;
            double height = width * 16 / 9;

            if (height > constraints.maxHeight) {
              height = constraints.maxHeight;
              width = height * 9 / 16;
            }

            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      homeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xff071722),
                      ),
                    ),

                    // دکمه منو
                    Positioned(
                      top: height * 0.085,
                      left: 14,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CyrusSettingsScreen()),
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xff0b1826).withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffffd36a).withValues(alpha: 0.85),
                            ),
                          ),
                          child: const Icon(Icons.menu_rounded, color: Color(0xffffd36a), size: 22),
                        ),
                      ),
                    ),

                    // زبان و حساب کاربری
                    Positioned(
                      top: height * 0.085,
                      right: 14,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff0b1826).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xffffd36a).withValues(alpha: 0.85),
                              ),
                            ),
                            child: CyrusLanguageButton(
                              currentLanguage: MenuLanguage.current,
                              onLanguageChanged: (code) async {
                                await MenuLanguage.setLanguage(code);
                                if (code == 'fa') {
                                  await LanguageManager.setLanguage(AppLanguage.persian);
                                } else if (code == 'ar') {
                                  await LanguageManager.setLanguage(AppLanguage.arabic);
                                } else if (code == 'en') {
                                  await LanguageManager.setLanguage(AppLanguage.english);
                                }
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff0b1826).withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xffffd36a).withValues(alpha: 0.85),
                              ),
                            ),
                            child: CyrusHeaderAccountButton(
                              currentLanguage: MenuLanguage.current,
                              refreshToken: _headerBadgeTick,
                              onAccountPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CyrusAccountScreen(
                                      languageCode: MenuLanguage.current,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {
                                    _headerBadgeTick++;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // لمس کلیدها (ردیف اول 1 تا 5)
                    area(1, .02, .44, .18, .19, width, height),
                    area(2, .21, .44, .18, .19, width, height),
                    area(3, .40, .44, .18, .19, width, height),
                    area(4, .59, .44, .18, .19, width, height),
                    area(5, .78, .44, .18, .19, width, height),

                    // لمس کلیدها (ردیف دوم 6 تا 10)
                    area(6, .02, .64, .18, .175, width, height),
                    area(7, .21, .64, .18, .175, width, height),
                    area(8, .40, .64, .18, .175, width, height),
                    area(9, .59, .64, .18, .175, width, height),
                    area(10, .78, .64, .18, .175, width, height),

                    // زیرنویس‌ها با درصد موقعیت اختصاصی
                    caption(1, .02, .50, .18, .15, width, height, captionTop: .558),
                    caption(2, .21, .50, .18, .15, width, height, captionTop: .558),
                    caption(3, .40, .50, .18, .15, width, height, captionTop: .558),
                    caption(4, .59, .50, .18, .15, width, height, captionTop: .558),
                    caption(5, .78, .50, .18, .15, width, height, captionTop: .558),

                    caption(6, .02, .71, .18, .15, width, height, captionTop: .748),
                    caption(7, .21, .71, .18, .15, width, height, captionTop: .748),
                    caption(8, .40, .71, .18, .15, width, height, captionTop: .748),
                    caption(9, .59, .71, .18, .15, width, height, captionTop: .748),
                    caption(10, .78, .71, .18, .15, width, height, captionTop: .748),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuDrawer() {
    return Drawer(
      backgroundColor: const Color(0xff071722),
      child: SafeArea(
        child: Directionality(
          textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x33ffd36a))),
                ),
                child: const Text(
                  'Cyrus Tourist',
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              for (var number = 1; number <= 10; number++) _drawerItem(number),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(int number) {
    final text = MenuTranslations.title(MenuLanguage.current, number);
    final label = text.isNotEmpty ? text : buttonTitle(number);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xff0b506b),
        foregroundColor: const Color(0xffffd36a),
        child: Text('$number', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.of(context).pop();
        tap(number);
      },
    );
  }
}

// ============================================================
// WORK IN PROGRESS PAGE
// ============================================================

class WorkInProgressPage extends StatelessWidget {
  final int number;
  final String title;

  const WorkInProgressPage({
    super,
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppText.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, color: Color(0xffffd36a), size: 70),
              const SizedBox(height: 25),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xffffd36a),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text('در حال ساخت و بروزرسانی', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                'کلید شماره $number',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('بازگشت'),
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

class _QuickServiceTool {
  final IconData icon;
  final String title;
  final String amenityTag;

  const _QuickServiceTool({
    required this.icon,
    required this.title,
    required this.amenityTag,
  });
}

class SmartMapPage extends StatefulWidget {
  const SmartMapPage({super.key});

  @override
  State<SmartMapPage> createState() => _SmartMapPageState();
}

class _SmartMapPageState extends State<SmartMapPage> with SingleTickerProviderStateMixin {
  final MapController mapController = MapController();
  static const LatLng iranCenter = LatLng(32.4279, 53.6880);

  LatLng? userLocation;
  bool routingInProgress = false;
  int mapProviderStep = 0;

  static const String currentLocationLabel = 'موقعیت فعلی من';

  final TextEditingController originController = TextEditingController(text: currentLocationLabel);
  final TextEditingController destinationController = TextEditingController();

  final FocusNode originFocusNode = FocusNode();
  final FocusNode destinationFocusNode = FocusNode();

  final LayerLink originLayerLink = LayerLink();
  final LayerLink destinationLayerLink = LayerLink();

  OverlayEntry? _suggestionsOverlay;
  Timer? _suggestionsDebounce;

  bool loading = true;
  bool mapReady = false;
  bool locationLoading = false;

  String? locationWarning;

  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> rotationAnimation;
  late Animation<double> glowAnimation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    rotationAnimation = Tween<double>(begin: 0, end: 6.283).animate(
      CurvedAnimation(parent: animationController, curve: Curves.linear),
    );

    glowAnimation = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      prepareMap();
    });

    originFocusNode.addListener(() {
      if (!originFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), _removeSuggestionsOverlay);
      }
    });

    destinationFocusNode.addListener(() {
      if (!destinationFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), _removeSuggestionsOverlay);
      }
    });
  }

  @override
  void dispose() {
    _suggestionsDebounce?.cancel();
    _removeSuggestionsOverlay();

    animationController.dispose();
    originController.dispose();
    destinationController.dispose();
    originFocusNode.dispose();
    destinationFocusNode.dispose();

    super.dispose();
  }

  Future<void> prepareMap() async {
    if (!mounted) return;

    setState(() {
      mapReady = true;
      loading = false;
    });

    await loadLastLocation();
    await getLocation();
  }

  Future<void> loadLastLocation() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final lat = pref.getDouble('last_lat');
      final lng = pref.getDouble('last_lng');

      if (lat == null || lng == null) return;

      final point = LatLng(lat, lng);

      if (!mounted) return;

      setState(() {
        userLocation = point;
      });

      mapController.move(point, 13);
    } catch (_) {}
  }

  bool get _originIsCurrentLocation {
    final text = originController.text.trim();
    return text.isEmpty || text == currentLocationLabel;
  }

  Future<LatLng?> _resolveOrigin() async {
    final referencePoint = userLocation ?? iranCenter;

    if (_originIsCurrentLocation) {
      return referencePoint;
    }

    try {
      final originResults = await MapPlacesService().searchPlaces(
        query: originController.text.trim(),
        userLocation: referencePoint,
      );

      if (originResults.isNotEmpty) {
        return originResults.first.location;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _openDirections(LatLng origin, LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}';

    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localize(
                'امکان باز کردن مسیریاب وجود ندارد.',
                'Could not open navigation.',
                'تعذر فتح تطبيق المسار.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              'خطا در باز کردن مسیریاب.',
              'Error opening navigation.',
              'حدث خطأ أثناء فتح المسار.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _startRouting() async {
    final destinationText = destinationController.text.trim();

    if (destinationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              'لطفاً هدف سفر را وارد کنید.',
              'Please enter a destination.',
              'يرجى إدخال وجهة الرحلة.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      routingInProgress = true;
    });

    final origin = await _resolveOrigin();

    if (!mounted) return;

    if (origin == null) {
      setState(() {
        routingInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              'مبدأ پیدا نشد. لطفاً نام دقیق‌تری وارد کنید.',
              'Origin not found. Please enter a more exact name.',
              'لم يتم العثور على نقطة البداية. يرجى إدخال اسم أدق.',
            ),
          ),
        ),
      );
      return;
    }

    List<MapPlace> results = [];

    try {
      results = await MapPlacesService().searchPlaces(
        query: destinationText,
        userLocation: origin,
      );
    } catch (_) {
      results = [];
    }

    if (!mounted) return;

    setState(() {
      routingInProgress = false;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              'هدف سفر پیدا نشد. لطفاً نام دقیق‌تری وارد کنید.',
              'Destination not found. Please enter a more exact name.',
              'لم يتم العثور على الوجهة. يرجى إدخال اسم أدق.',
            ),
          ),
        ),
      );
      return;
    }

    final destination = results.first.location;
    await _openDirections(origin, destination);
  }

  String _localize(String fa, String en, String ar) {
    if (LanguageManager.current == AppLanguage.english) return en;
    if (LanguageManager.current == AppLanguage.arabic) return ar;
    return fa;
  }

  Future<void> getLocation() async {
    if (locationLoading) return;
    locationLoading = true;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        if (mounted) {
          setState(() {
            locationWarning = _localize(
              'موقعیت‌یاب دستگاه خاموش است',
              'Device location is turned off',
              'خدمة تحديد الموقع في الجهاز متوقفة',
            );
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationWarning = _localize(
              'دسترسی موقعیت فعال نیست',
              'Location access is not granted',
              'الوصول إلى الموقع غير مفعّل',
            );
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final point = LatLng(position.latitude, position.longitude);

      final pref = await SharedPreferences.getInstance();
      await pref.setDouble('last_lat', point.latitude);
      await pref.setDouble('last_lng', point.longitude);

      if (!mounted) return;

      setState(() {
        userLocation = point;
        locationWarning = null;
      });

      mapController.move(point, 15);
    } catch (_) {
      if (mounted) {
        setState(() {
          locationWarning = _localize(
            'خطا در دریافت موقعیت',
            'Could not get your location',
            'تعذر الحصول على الموقع',
          );
        });
      }
    } finally {
      locationLoading = false;
    }
  }

  List<Marker> markers() {
    final items = <Marker>[];

    if (userLocation != null) {
      items.add(
        Marker(
          point: userLocation!,
          width: 65,
          height: 65,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.25),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 35),
          ),
        ),
      );
    }

    return items;
  }

  String get loadingTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'در حال آماده‌سازی نقشه گردشگری...';
      case AppLanguage.arabic:
        return 'جارٍ إعداد الخريطة السياحية...';
      case AppLanguage.english:
        return 'Preparing Tourism Map...';
      case AppLanguage.german:
        return 'Reisekarte wird vorbereitet...';
      case AppLanguage.spanish:
        return 'Preparando el mapa turístico...';
      case AppLanguage.french:
        return 'Préparation de la carte touristique...';
      case AppLanguage.italian:
        return 'Preparazione della mappa turistica...';
      case AppLanguage.russian:
        return 'Подготовка туристической карты...';
      case AppLanguage.turkish:
        return 'Turizm haritası hazırlanıyor...';
      case AppLanguage.chinese:
        return '正在准备旅游地图...';
    }
  }

  String get loadingSubtitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'لطفاً چند لحظه صبر کنید';
      case AppLanguage.arabic:
        return 'يرجى الانتظار لحظة';
      case AppLanguage.english:
        return 'Please wait a moment';
      case AppLanguage.german:
        return 'Bitte einen Moment warten';
      case AppLanguage.spanish:
        return 'Por favor, espera un momento';
      case AppLanguage.french:
        return 'Veuillez patienter un instant';
      case AppLanguage.italian:
        return 'Attendere un momento, per favore';
      case AppLanguage.russian:
        return 'Пожалуйста, подождите немного';
      case AppLanguage.turkish:
        return 'Lütfen bir an bekleyin';
      case AppLanguage.chinese:
        return '请稍候';
    }
  }

  Widget loadingScreen() {
    return Container(
      color: const Color(0xff071722),
      child: Center(
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: rotationAnimation.value,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffffd36a).withValues(
                                alpha: glowAnimation.value,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffffd36a).withValues(
                                  alpha: glowAnimation.value * .5,
                                ),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: scaleAnimation.value,
                        child: Container(
                          width: 115,
                          height: 115,
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo-new.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.map, size: 50, color: Color(0xff071722)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  AppText.title(),
                  style: const TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(loadingTitle, style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  loadingSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: .7)),
                ),
                const SizedBox(height: 25),
                const SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Color(0xff183746),
                    valueColor: AlwaysStoppedAnimation(Color(0xffffd36a)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget mapSearchBox() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Column(
        children: [
          _searchField(
            controller: originController,
            icon: Icons.my_location,
            hint: 'مبدا',
            focusNode: originFocusNode,
            layerLink: originLayerLink,
            isOrigin: true,
          ),
          const SizedBox(height: 8),
          _searchField(
            controller: destinationController,
            icon: Icons.place,
            hint: 'هدف سفر',
            focusNode: destinationFocusNode,
            layerLink: destinationLayerLink,
            isOrigin: false,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: routingInProgress ? null : _startRouting,
              icon: routingInProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xff071722),
                      ),
                    )
                  : const Icon(Icons.directions_rounded, size: 24),
              label: Text(
                routingInProgress ? 'در حال جستجو...' : 'مسیریابی',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffffe39a),
                foregroundColor: const Color(0xff071722),
                elevation: 6,
                shadowColor: const Color(0xffffd36a).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required FocusNode focusNode,
    required LayerLink layerLink,
    required bool isOrigin,
  }) {
    return CompositedTransformTarget(
      link: layerLink,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(18),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (text) => _onSearchTextChanged(text, isOrigin: isOrigin),
          decoration: InputDecoration(
            prefixIcon: isOrigin
                ? IconButton(
                    icon: Icon(icon),
                    tooltip: _localize('استفاده از موقعیت فعلی', 'Use current location', 'استخدام الموقع الحالي'),
                    onPressed: () {
                      setState(() {
                        originController.text = currentLocationLabel;
                      });
                      _removeSuggestionsOverlay();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : Icon(icon),
            hintText: hint,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchTextChanged(String text, {required bool isOrigin}) {
    _suggestionsDebounce?.cancel();

    final query = text.trim();

    if (query.length < 2) {
      _removeSuggestionsOverlay();
      return;
    }

    _suggestionsDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _fetchSuggestions(query, isOrigin: isOrigin),
    );
  }

  Future<void> _fetchSuggestions(String query, {required bool isOrigin}) async {
    final referencePoint = userLocation ?? iranCenter;

    List<MapPlace> results = [];

    try {
      results = await MapPlacesService().searchPlaces(
        query: query,
        userLocation: referencePoint,
      );
    } catch (_) {
      results = [];
    }

    if (!mounted) return;

    final currentText = isOrigin ? originController.text.trim() : destinationController.text.trim();

    if (currentText != query) return;

    _showSuggestionsOverlay(results.take(6).toList(), isOrigin: isOrigin);
  }

  void _showSuggestionsOverlay(List<MapPlace> results, {required bool isOrigin}) {
    _removeSuggestionsOverlay();

    if (results.isEmpty || !mounted) return;

    final layerLink = isOrigin ? originLayerLink : destinationLayerLink;
    final width = MediaQuery.of(context).size.width - 24;

    _suggestionsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = results[index];

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: place.address != null
                        ? Text(place.address!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    onTap: () => _selectSuggestion(place, isOrigin: isOrigin),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_suggestionsOverlay!);
  }

  void _selectSuggestion(MapPlace place, {required bool isOrigin}) {
    if (isOrigin) {
      originController.text = place.name;
    } else {
      destinationController.text = place.name;
    }

    _removeSuggestionsOverlay();
    FocusScope.of(context).unfocus();
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  Future<LatLng?> _findNearestAmenity(
    String amenityTag,
    LatLng center, {
    double radiusMeters = 5000,
  }) async {
    final query = '[out:json][timeout:20];'
        '(node["amenity"="$amenityTag"](around:$radiusMeters,${center.latitude},${center.longitude});'
        'way["amenity"="$amenityTag"](around:$radiusMeters,${center.latitude},${center.longitude});'
        ');out center 30;';

    final uri = Uri.https('overpass-api.de', '/api/interpreter', {'data': query});

    HttpClient? client;

    try {
      if (!kIsWeb) {
        client = HttpClient();
        client.userAgent = 'CyrusTourist/1.0 (cyrustourist app)';
        client.connectionTimeout = const Duration(seconds: 15);
      }

      final request = await (client != null ? client.getUrl(uri) : HttpClient().getUrl(uri));
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = json.decode(body) as Map<String, dynamic>;
      final elements = (data['elements'] as List<dynamic>?) ?? [];

      if (elements.isEmpty) return null;

      const distanceCalculator = Distance();
      LatLng? nearest;
      double bestDistance = double.infinity;

      for (final element in elements) {
        final map = element as Map<String, dynamic>;

        double? lat = (map['lat'] as num?)?.toDouble();
        double? lon = (map['lon'] as num?)?.toDouble();

        if (lat == null || lon == null) {
          final centerTag = map['center'] as Map<String, dynamic>?;
          lat = (centerTag?['lat'] as num?)?.toDouble();
          lon = (centerTag?['lon'] as num?)?.toDouble();
        }

        if (lat == null || lon == null) continue;

        final point = LatLng(lat, lon);
        final d = distanceCalculator(center, point);

        if (d < bestDistance) {
          bestDistance = d;
          nearest = point;
        }
      }

      return nearest;
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  Future<void> _quickService(_QuickServiceTool tool) async {
    setState(() {
      routingInProgress = true;
    });

    final origin = await _resolveOrigin();

    if (!mounted) return;

    if (origin == null) {
      setState(() {
        routingInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              'مبدأ پیدا نشد. لطفاً نام دقیق‌تری وارد کنید.',
              'Origin not found. Please enter a more exact name.',
              'لم يتم العثور على نقطة البداية. يرجى إدخال اسم أدق.',
            ),
          ),
        ),
      );
      return;
    }

    final nearest = await _findNearestAmenity(tool.amenityTag, origin);

    if (!mounted) return;

    setState(() {
      routingInProgress = false;
    });

    if (nearest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localize(
              '${tool.title} نزدیکی پیدا نشد.',
              'No nearby ${tool.title} found.',
              'لم يتم العثور على ${tool.title} قريب.',
            ),
          ),
        ),
      );
      return;
    }

    await _openDirections(origin, nearest);
  }

  Widget mapServiceButton(_QuickServiceTool tool) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _quickService(tool),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 78,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xff0b506b),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffffd36a).withValues(alpha: 0.65)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tool.icon, color: const Color(0xffffd36a), size: 22),
              const SizedBox(height: 3),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapSideButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xff0b506b),
        shape: const CircleBorder(),
        elevation: 4,
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: const Color(0xffffd36a)),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _mapSideControls() {
    return Positioned(
      right: 12,
      bottom: 110,
      child: Column(
        mainAxisSize: MinAxisSize.min,
        children: [
          _mapSideButton(
            icon: Icons.add,
            tooltip: _localize('بزرگ‌نمایی', 'Zoom in', 'تكبير'),
            onPressed: () {
              final camera = mapController.camera;
              mapController.move(camera.center, camera.zoom + 1);
            },
          ),
          _mapSideButton(
            icon: Icons.remove,
            tooltip: _localize('کوچک‌نمایی', 'Zoom out', 'تصغير'),
            onPressed: () {
              final camera = mapController.camera;
              mapController.move(camera.center, camera.zoom - 1);
            },
          ),
          _mapSideButton(
            icon: Icons.explore_outlined,
            tooltip: _localize('قطب‌نما (بازگشت به شمال)', 'Compass (reset to north)', 'البوصلة (إعادة للشمال)'),
            onPressed: () {
              mapController.rotate(0);
            },
          ),
          _mapSideButton(
            icon: Icons.my_location,
            tooltip: _localize('موقعیت من', 'My location', 'موقعي الحالي'),
            onPressed: getLocation,
          ),
        ],
      ),
    );
  }

  Widget mapTools() {
    final tools = <_QuickServiceTool>[
      _QuickServiceTool(icon: Icons.local_gas_station_rounded, title: _localize('پمپ بنزین', 'Fuel', 'محطة وقود'), amenityTag: 'fuel'),
      _QuickServiceTool(icon: Icons.restaurant_rounded, title: _localize('رستوران', 'Food', 'مطعم'), amenityTag: 'restaurant'),
      _QuickServiceTool(icon: Icons.atm_rounded, title: _localize('خودپرداز', 'ATM', 'صراف آلي'), amenityTag: 'atm'),
      _QuickServiceTool(icon: Icons.local_parking_rounded, title: _localize('پارکینگ', 'Parking', 'موقف سيارات'), amenityTag: 'parking'),
      _QuickServiceTool(icon: Icons.local_pharmacy_rounded, title: _localize('داروخانه', 'Pharmacy', 'صيدلية'), amenityTag: 'pharmacy'),
      _QuickServiceTool(icon: Icons.local_taxi_rounded, title: _localize('تاکسی', 'Taxi', 'سيارة أجرة'), amenityTag: 'taxi'),
      _QuickServiceTool(icon: Icons.wc_rounded, title: _localize('سرویس', 'Restroom', 'دورة مياه'), amenityTag: 'toilets'),
      _QuickServiceTool(icon: Icons.emergency_rounded, title: _localize('اورژانس', 'Emergency', 'طوارئ'), amenityTag: 'hospital'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xff071722),
      child: SizedBox(
        height: 78,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            return mapServiceButton(tools[index]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071722),
      appBar: AppBar(
        backgroundColor: const Color(0xff071722),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(AppText.map(), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _localize('موقعیت من', 'My location', 'موقعي'),
            onPressed: getLocation,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: iranCenter,
              initialZoom: 5.2,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              if (mapProviderStep == 0)
                TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: 'https://map.ir/shiveh',
                    layers: const ['Shiveh:Shiveh'],
                    styles: const [],
                    format: 'image/png',
                    version: '1.1.1',
                    transparent: false,
                    otherParameters: const {'width': '256', 'height': '256'},
                  ),
                  tileProvider: NetworkTileProvider(headers: {'x-api-key': MapIrConfig.apiKey}),
                  userAgentPackageName: 'com.cyrustourist.app',
                  errorTileCallback: (_, __, ___) {
                    if (mounted && mapProviderStep == 0) {
                      setState(() {
                        mapProviderStep = 1;
                      });
                    }
                  },
                )
              else if (mapProviderStep == 1)
                TileLayer(
                  urlTemplate: CartoConfig.tileUrlWithKey,
                  userAgentPackageName: 'com.cyrustourist.app',
                  errorTileCallback: (_, __, ___) {
                    if (mounted && mapProviderStep == 1) {
                      setState(() {
                        mapProviderStep = 2;
                      });
                    }
                  },
                )
              else
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.cyrustourist.app',
                ),
              MarkerLayer(markers: markers()),
            ],
          ),

          mapSearchBox(),

          if (!loading) _mapSideControls(),

          if (locationWarning != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff071722).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffffd36a)),
                  ),
                  child: Text(
                    locationWarning!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

          if (loading) Positioned.fill(child: loadingScreen()),

          if (!loading) Positioned(left: 0, right: 0, bottom: 0, child: mapTools()),
        ],
      ),
    );
  }
}
