import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  final String aparatUrl =
      'https://www.aparat.com/Cyrustourist';

  Future<void> openAparat() async {
    final uri = Uri.parse(aparatUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget videoCategoryCard({
    required BuildContext context,
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: openAparat,
        child: Container(
          margin: const EdgeInsets.all(8),
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xffffd36a),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffffd36a)
                    .withValues(alpha: .35),
                blurRadius: 15,
              ),
            ],
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withValues(alpha: .35),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Color(0xffffd36a),
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget filmItem(int number) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xff0b506b),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffffd36a),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Icon(
              Icons.play_circle,
              color: Color(0xffffd36a),
              size: 55,
            ),
          ),
          Expanded(
            child: Text(
              'فیلم منتخب گردشگری شماره $number\nCyrus Tourist',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xff071722),

        appBar: AppBar(
          backgroundColor:
              const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'نمایش فیلم‌های گردشگری',
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 10),

              Row(
                children: [
                  videoCategoryCard(
                    context: context,
                    image:
                        'assets/images/video_accommodation.jpg',
                    title: 'فیلم‌های اقامتی',
                    subtitle:
                        'اقامتگاه | بوم‌گردی | کلبه',
                  ),

                  videoCategoryCard(
                    context: context,
                    image:
                        'assets/images/video_attraction.jpg',
                    title:
                        'جاذبه‌های گردشگری',
                    subtitle:
                        'تاریخ | طبیعت | فرهنگ',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'فیلم‌های منتخب Cyrus Tourist',
                style: TextStyle(
                  color: Color(0xffffd36a),
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...List.generate(
                10,
                (index) => filmItem(index + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
