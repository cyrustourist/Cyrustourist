import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/app_language.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String websiteUrl =
      'https://cyrustourist-maker.github.io/Cyrustourist/';

  String _t(String fa, String en, String ar) {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return fa;
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.english:
        return en;
    }
  }

  TextDirection get _dir => LanguageManager.current == AppLanguage.english
      ? TextDirection.ltr
      : TextDirection.rtl;

  Future<void> _openWebsite(BuildContext context) async {
    final Uri uri = Uri.parse(websiteUrl);

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('امکان باز کردن وب‌سایت وجود ندارد.',
                'The website cannot be opened.', 'لا يمكن فتح الموقع الإلكتروني.')),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('خطا در باز کردن وب‌سایت',
                'Error opening the website', 'خطأ في فتح الموقع الإلكتروني')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),

        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            _t('درباره ما', 'About Us', 'من نحن'),
            style: const TextStyle(
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
                Text(
                  _t(
                    'سایروس توریست؛ برای شناختن، دیدن و تجربه کردن ایران',
                    'Cyrus Tourist; to Know, See, and Experience Iran',
                    'سايروس توريست؛ لمعرفة إيران ورؤيتها وتجربتها',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                // معرفی
                Text(
                  _t(
                    'Cyrus Tourist با عشق به ایران و با هدف معرفی زیبایی‌های سرزمین چهار فصل ایران آغاز به کار کرده است؛ سرزمینی سرشار از تاریخ و تمدن، طبیعت بکر، فرهنگ و هنر، شهرهای دیدنی و جاذبه‌های فراوان.\n\n'
                    'سایروس توریست تلاش می‌کند ایران را به شکلی واقعی، جذاب و امروزی به گردشگران معرفی کند و مسیر شناخت و تجربه این سرزمین را برای مسافران ساده‌تر و لذت‌بخش‌تر سازد.\n\n'
                    'در این مجموعه، معرفی جاذبه‌های تاریخی و طبیعی، طبیعت‌گردی، اقامتگاه‌ها، راهنمای سفر، نقشه گردشگری و فیلم‌های گردشگری در کنار ابزارهای کاربردی سفر گرد هم آمده‌اند تا یک همراه جامع برای گردشگران ایرانی و بین‌المللی فراهم شود.\n\n'
                    'یکی از بخش‌های مهم فعالیت سایروس توریست، تولید محتوای گردشگری است؛ از فیلم‌ها و تیزرهای معرفی گرفته تا مستندها و محتوای تخصصی که با هدف معرفی بهتر مقاصد، مجموعه‌ها و فعالان گردشگری تولید می‌شوند.',
                    'Cyrus Tourist was founded out of a love for Iran, with the goal of showcasing the beauty of this land of four seasons; a land rich in history and civilization, untouched nature, culture and art, beautiful cities, and countless attractions.\n\n'
                    'Cyrus Tourist strives to present Iran to travelers in a real, appealing, and modern way, making it easier and more enjoyable for them to discover and experience this land.\n\n'
                    'This platform brings together historical and natural attractions, nature tourism, accommodations, a travel guide, a tourism map, and travel videos alongside practical travel tools to provide a complete companion for Iranian and international tourists.\n\n'
                    'One of the key parts of Cyrus Tourist\'s work is producing tourism content; from introductory videos and teasers to documentaries and specialized content aimed at better showcasing destinations, venues, and tourism professionals.',
                    'انطلقت سايروس توريست بدافع من حب إيران وبهدف التعريف بجمال أرض الفصول الأربعة؛ أرض غنية بالتاريخ والحضارة، والطبيعة البكر، والثقافة والفن، والمدن الجميلة، والمعالم الكثيرة.\n\n'
                    'تسعى سايروس توريست إلى تقديم إيران للسياح بشكل واقعي وجذاب وعصري، وتسهيل رحلة التعرف على هذه الأرض وتجربتها للمسافرين.\n\n'
                    'تجمع هذه المنصة بين التعريف بالمعالم التاريخية والطبيعية، والسياحة الطبيعية، وأماكن الإقامة، ودليل السفر، وخريطة السياحة، وأفلام السياحة، إلى جانب أدوات سفر عملية، لتوفير رفيق شامل للسياح الإيرانيين والدوليين.\n\n'
                    'من أهم أنشطة سايروس توريست إنتاج محتوى سياحي؛ من الأفلام والإعلانات التعريفية إلى الأفلام الوثائقية والمحتوى المتخصص الذي يُنتج بهدف التعريف الأفضل بالوجهات والمجموعات والعاملين في مجال السياحة.',
                  ),
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 25),

                // چشم انداز
                Text(
                  _t('چشم‌انداز ما', 'Our Vision', 'رؤيتنا'),
                  style: const TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _t(
                    'ما باور داریم ایران تنها یک مقصد گردشگری نیست؛ بلکه گنجینه‌ای زنده از تاریخ، فرهنگ، طبیعت و تجربه‌های فراموش‌نشدنی است.\n\n'
                    'هدف ما ساخت و توسعه یک پلتفرم گردشگری هوشمند و بین‌المللی است تا گردشگران بتوانند ایران را آسان‌تر پیدا کنند، بهتر بشناسند و با اطمینان بیشتری تجربه کنند.',
                    'We believe Iran is not just a tourist destination; it is a living treasure of history, culture, nature, and unforgettable experiences.\n\n'
                    'Our goal is to build and develop a smart, international tourism platform so travelers can find Iran more easily, get to know it better, and experience it with more confidence.',
                    'نؤمن بأن إيران ليست مجرد وجهة سياحية؛ بل كنز حي من التاريخ والثقافة والطبيعة والتجارب التي لا تُنسى.\n\n'
                    'هدفنا هو بناء وتطوير منصة سياحية ذكية وعالمية ليتمكن السياح من العثور على إيران بسهولة أكبر، والتعرف عليها بشكل أفضل، وتجربتها بثقة أكبر.',
                  ),
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 22),

                // شعار
                Text(
                  _t(
                    'سایروس توریست؛ پنجره‌ای به سوی زیبایی‌های ایران.\n'
                    'سفر کن، کشف کن، لذت ببر',
                    'Cyrus Tourist; a window to the beauty of Iran.\n'
                    'Travel, Discover, Enjoy',
                    'سايروس توريست؛ نافذة على جمال إيران.\n'
                    'سافر، اكتشف، استمتع',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        _t('درباره پروژه', 'About the Project', 'عن المشروع'),
                        style: const TextStyle(
                          color: Color(0xffffd36a),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _t(
                          'آغاز به کار سایروس توریست: ۸ آبان ۱۳۹۸\n'
                          'تاریخ میلادی: ۳۰ اکتبر ۲۰۱۹\n'
                          'مدیر پروژه: مهندس تیرانداز',
                          'Cyrus Tourist launch date: 8 Aban 1398 (Iranian calendar)\n'
                          'Gregorian date: October 30, 2019\n'
                          'Project Manager: Eng. Tirandaz',
                          'تاريخ انطلاق سايروس توريست: 8 آبان 1398 هـ.ش\n'
                          'الموافق: 30 أكتوبر 2019 م\n'
                          'مدير المشروع: المهندس تيرانداز',
                        ),
                        style: const TextStyle(
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
                Text(
                  _t('وب‌سایت رسمی', 'Official Website', 'الموقع الرسمي'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

                Text(
                  _t(
                    'برای مشاهده وب‌سایت و اطلاعات بیشتر، روی لینک بالا کلیک کنید.',
                    'Click the link above to view the website and learn more.',
                    'انقر على الرابط أعلاه لعرض الموقع الإلكتروني ومزيد من المعلومات.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
