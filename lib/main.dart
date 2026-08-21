import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
      title: 'CyrusTourist',
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
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() =>
      _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
// HOME PAGE - ORIGINAL IMAGE + TRANSPARENT TOUCH
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppText.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,

      child: Scaffold(
        backgroundColor: Colors.black,

        body: SafeArea(
          child: Center(
            child: AspectRatio(
              aspectRatio: 2 / 3,

              child: Stack(
                fit: StackFit.expand,

                children: [

                  // عکس اصلی طراحی شده
                  Image.asset(
                    'assets/images/home.jpg',
                    fit: BoxFit.cover,
                  ),


                  // ==================================================
                  // TOUCH AREA
                  // کلید ۱ - نقشه گردشگری
                  // ==================================================

                  Positioned(
                    left: 0,
                    bottom: 0,

                    child: FractionallySizedBox(
                      widthFactor: 0.20,
                      heightFactor: 0.20,

                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.translucent,

                        onTap: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SmartMapPage(),
                            ),
                          );

                        },

                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
