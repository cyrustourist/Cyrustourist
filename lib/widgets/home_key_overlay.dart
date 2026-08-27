import 'package:flutter/material.dart';
import '../pages/support_page.dart';

class HomeKeyOverlay extends StatefulWidget {
  const HomeKeyOverlay({super.key});

  @override
  State<HomeKeyOverlay> createState() => _HomeKeyOverlayState();
}

class _HomeKeyOverlayState extends State<HomeKeyOverlay> {

  int? activeKey;

  void openKey(int key) {
    setState(() {
      activeKey = key;
    });

    if (key == 9) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SupportPage(),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // کلید شماره ۹ - پشتیبانی
        Positioned(
          left: 40,
          bottom: 80,
          width: 120,
          height: 60,
          child: GestureDetector(
            onTap: () {
              openKey(9);
            },

            child: Container(
              decoration: BoxDecoration(
                color: activeKey == 9
                    ? Colors.amber.withOpacity(0.6)
                    : Colors.transparent,

                borderRadius: BorderRadius.circular(15),
              ),

              child: const Center(
                child: Text(
                  '۹',
                  style: TextStyle(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }
}
