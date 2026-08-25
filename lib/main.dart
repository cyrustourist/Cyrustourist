import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/map_state_service.dart';
import 'providers/map_state_provider.dart';
import 'pages/map/smart_map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      ),
      home: const SplashPage(),
    );
  }
}

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

      case AppLanguage.arabic:
        await pref.setString('language', 'ar');
        break;

      case AppLanguage.english:
        await pref.setString('language', 'en');
        break;
    }
  }
}

class AppText {
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

  static bool get rtl =>
      LanguageManager.current != AppLanguage.english;

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

    LanguageManager.load();

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
          errorBuilder: (context, error, stack) {
            return const Center(
              child: Text(
                'Splash image not found',
                style: TextStyle(
                  color: Colors.white,
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
// تصویر اصلی بدون تغییر
// فقط Touch Zone ها
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

  // ==========================================================
  // TAP
  // ==========================================================

  Future<void> tap(int number) async {
    setState(() {
      selected = number;
    });

    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    if (!mounted) return;

    setState(() {
      selected = 0;
    });

    // --------------------------------------------------------
    // کلید 1 = Smart Map
    // --------------------------------------------------------

    if (number == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SmartMapPage(),
        ),
      );
    }

    // --------------------------------------------------------
    // کلید 9
    // فعلاً همان وضعیت قبلی حفظ شده است
    // --------------------------------------------------------

    if (number == 9) {
      // TODO: صفحه Me
    }
  }

  // ==========================================================
  // TOUCH AREA
  //
  // مختصات بر اساس خود تصویر 9:16 هستند.
  //
  // مهم:
  // هیچ Widget قابل مشاهده‌ای روی تصویر ساخته نمی‌شود.
  // فقط GestureDetector شفاف وجود دارد.
  // ==========================================================

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => tap(number),
        child: AnimatedScale(
          scale: selected == number ? 0.92 : 1.0,
          duration: const Duration(
            milliseconds: 120,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            double imageW = screenW;
            double imageH = screenW * 16 / 9;

            if (imageH > screenH) {
              imageH = screenH;
              imageW = screenH * 9 / 16;
            }

            return Center(
              child: SizedBox(
                width: screenW,
                height: screenH,
                child: Stack(
                  children: [
                    // ==================================================
                    // HOME IMAGE
                    // ==================================================

                    Center(
                      child: SizedBox(
                        width: imageW,
                        height: imageH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              homeImage,
                              fit: BoxFit.fill,
                            ),

                            // ==================================================
                            // TOUCH ZONES HOME
                            //
                            // تنظیم بر اساس موقعیت واقعی کلیدهای داخل تصویر
                            //
                            // ردیف اول:
                            // 0.535 تا 0.715
                            //
                            // ردیف دوم:
                            // 0.725 تا 0.905
                            //
                            // هیچ ناحیه‌ای روی دیگری قرار ندارد.
                            // ==================================================

                            // -------------------------
                            // ردیف اول: کلیدهای 1 تا 5
                            // -------------------------

                            area(
                              1,
                              0.02,
                              0.535,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              2,
                              0.21,
                              0.535,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              3,
                              0.40,
                              0.535,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              4,
                              0.59,
                              0.535,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              5,
                              0.78,
                              0.535,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            // -------------------------
                            // ردیف دوم: کلیدهای 6 تا 10
                            // -------------------------

                            area(
                              6,
                              0.02,
                              0.725,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              7,
                              0.21,
                              0.725,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              8,
                              0.40,
                              0.725,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              9,
                              0.59,
                              0.725,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),

                            area(
                              10,
                              0.78,
                              0.725,
                              0.18,
                              0.18,
                              imageW,
                              imageH,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // LANGUAGE BUTTON
                    // ==================================================

                    Positioned(
                      top: 15,
                      left: 15,
                      child: GestureDetector(
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            backgroundColor:
                                const Color(0xff071722),
                            builder: (_) {
                              return Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text(
                                      'پارسی',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () async {
                                      await LanguageManager
                                          .setLanguage(
                                        AppLanguage.persian,
                                      );

                                      if (mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  ListTile(
                                    title: const Text(
                                      'English',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () async {
                                      await LanguageManager
                                          .setLanguage(
                                        AppLanguage.english,
                                      );

                                      if (mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  ListTile(
                                    title: const Text(
                                      'العربية',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () async {
                                      await LanguageManager
                                          .setLanguage(
                                        AppLanguage.arabic,
                                      );

                                      if (mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff0b506b,
                            ),
                            borderRadius:
                                BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xffffd36a,
                              ),
                            ),
                          ),
                          child: Text(
                            AppText.languageName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
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
    );
  }
}
