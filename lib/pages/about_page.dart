import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String websiteUrl =
      'https://cyrustourist-maker.github.io/Cyrustourist/';

  Future<void> _openWebsite(BuildContext context) async {
    final Uri uri = Uri.parse(websiteUrl);

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('امکان باز کردن وب‌سایت وجود ندارد.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در باز کردن وب‌سایت'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),

        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'درباره ما',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // لوگو
                Center(
                  child: Image.asset(
                    'assets/images/logo-new.jpg',
                    height: 105,
                    width: 105,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 22),

                // عنوان
                const Text(
                  'سایروس توریست؛ برای شناختن، دیدن و تجربه کردن ایران',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                // معرفی
                const Text(
                  'Cyrus Tourist با عشق به ایران و با هدف معرفی زیبایی‌های سرزمین چهار فصل ایران آغاز به کار کرده است؛ سرزمینی سرشار از تاریخ و تمدن، طبیعت بکر، فرهنگ و هنر، شهرهای دیدنی و جاذبه‌های فراوان.\n\n'
                  'سایروس توریست تلاش می‌کند ایران را به شکلی واقعی، جذاب و امروزی به گردشگران معرفی کند و مسیر شناخت و تجربه این سرزمین را برای مسافران ساده‌تر و لذت‌بخش‌تر سازد.\n\n'
                  'در این مجموعه، معرفی جاذبه‌های تاریخی و طبیعی، طبیعت‌گردی، اقامتگاه‌ها، راهنمای سفر، نقشه گردشگری و فیلم‌های گردشگری در کنار ابزارهای کاربردی سفر گرد هم آمده‌اند تا یک همراه جامع برای گردشگران ایرانی و بین‌المللی فراهم شود.\n\n'
                  'یکی از بخش‌های مهم فعالیت سایروس توریست، تولید محتوای گردشگری است؛ از فیلم‌ها و تیزرهای معرفی گرفته تا مستندها و محتوای تخصصی که با هدف معرفی بهتر مقاصد، مجموعه‌ها و فعالان گردشگری تولید می‌شوند.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 25),

                // چشم انداز
                const Text(
                  'چشم‌انداز ما',
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'ما باور داریم ایران تنها یک مقصد گردشگری نیست؛ بلکه گنجینه‌ای زنده از تاریخ، فرهنگ، طبیعت و تجربه‌های فراموش‌نشدنی است.\n\n'
                  'هدف ما ساخت و توسعه یک پلتفرم گردشگری هوشمند و بین‌المللی است تا گردشگران بتوانند ایران را آسان‌تر پیدا کنند، بهتر بشناسند و با اطمینان بیشتری تجربه کنند.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 22),

                // شعار
                const Text(
                  'سایروس توریست؛ پنجره‌ای به سوی زیبایی‌های ایران.\n'
                  'سفر کن، کشف کن، لذت ببر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                ),

                const SizedBox(height: 25),

                // اطلاعات پروژه
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0b506b).withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xffffd36a).withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'درباره پروژه',
                        style: TextStyle(
                          color: Color(0xffffd36a),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(
                        'آغاز به کار سایروس توریست: ۸ آبان ۱۳۹۸\n'
                        'تاریخ میلادی: ۳۰ اکتبر ۲۰۱۹\n'
                        'مدیر پروژه: مهندس تیرانداز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.9,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // وب سایت
                const Text(
                  'وب‌سایت رسمی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                InkWell(
                  onTap: () => _openWebsite(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xffffd36a),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Icon(
                          Icons.language,
                          color: Color(0xffffd36a),
                        ),

                        SizedBox(width: 10),

                        Flexible(
                          child: Text(
                            'cyrustourist-maker.github.io/Cyrustourist/',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xffffd36a),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),

                        SizedBox(width: 8),

                        Icon(
                          Icons.open_in_new,
                          color: Color(0xffffd36a),
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'برای مشاهده وب‌سایت و اطلاعات بیشتر، روی لینک بالا کلیک کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
