import 'package:flutter/material.dart';

import '../../core/language/app_language.dart';

class TravelGuidePage extends StatefulWidget {
  const TravelGuidePage({super.key});

  @override
  State<TravelGuidePage> createState() => _TravelGuidePageState();
}

class _TravelGuidePageState extends State<TravelGuidePage> {
  static const Color backgroundColor = Color(0xff06121d);
  static const Color cardColor = Color(0xff0b2636);
  static const Color cardColor2 = Color(0xff0e3042);
  static const Color goldColor = Color(0xffffd36a);
  static const Color goldBright = Color(0xffffe39a);

  AppLanguage get language => LanguageManager.current;
  bool get isRtl => language != AppLanguage.english;

  String _t(String fa, String en, String ar) {
    switch (language) {
      case AppLanguage.persian:
        return fa;
      case AppLanguage.english:
        return en;
      case AppLanguage.arabic:
        return ar;
    }
  }

  List<_GuideItem> get guideItems => [
        _GuideItem(
          icon: Icons.luggage_rounded,
          title: _t('قبل از سفر', 'Before the Trip', 'قبل السفر'),
          subtitle: _t(
            'آماده‌سازی هوشمندانه برای یک سفر بهتر',
            'Smart preparation for a better trip',
            'استعداد ذكي لرحلة أفضل',
          ),
          tips: _tList(
            [
              'مقصد و مسیر سفر را از قبل بررسی کنید.',
              'مدارک شناسایی و وسایل ضروری را همراه داشته باشید.',
              'لباس مناسب فصل و مقصد انتخاب کنید.',
              'مقدار کافی آب و خوراکی برای مسیر در نظر بگیرید.',
              'پیش از حرکت وضعیت خودرو و سوخت را بررسی کنید.',
            ],
            [
              'Check your destination and route in advance.',
              'Carry identification documents and essential items.',
              'Choose clothing suitable for the season and destination.',
              'Take enough water and food for the journey.',
              'Check your vehicle and fuel before departure.',
            ],
            [
              'تحقق من الوجهة ومسار الرحلة مسبقاً.',
              'احمل وثائق الهوية والأغراض الضرورية.',
              'اختر ملابس مناسبة للموسم والوجهة.',
              'احمل كمية كافية من الماء والطعام للطريق.',
              'تحقق من حالة السيارة والوقود قبل الانطلاق.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.map_rounded,
          title: _t('مسیر و جابه‌جایی', 'Routes & Transportation', 'المسارات والتنقل'),
          subtitle: _t(
            'راهنمای استفاده بهتر از مسیر و نقشه',
            'A better way to use routes and maps',
            'دليل أفضل لاستخدام الطرق والخرائط',
          ),
          tips: _tList(
            [
              'پیش از حرکت مسیر اصلی و مسیرهای جایگزین را بررسی کنید.',
              'برای مسیرهای طولانی زمان کافی در نظر بگیرید.',
              'در زمان رانندگی از تلفن همراه استفاده نکنید.',
              'در مناطق ناشناخته، موقعیت مکانی خود را بررسی کنید.',
              'در جاده‌های کوهستانی با سرعت مطمئن حرکت کنید.',
            ],
            [
              'Check the main and alternative routes before departure.',
              'Allow enough time for long journeys.',
              'Do not use your phone while driving.',
              'Check your location in unfamiliar areas.',
              'Drive at a safe speed on mountain roads.',
            ],
            [
              'تحقق من الطريق الرئيسي والطرق البديلة قبل الانطلاق.',
              'خصص وقتاً كافياً للرحلات الطويلة.',
              'لا تستخدم الهاتف أثناء القيادة.',
              'تحقق من موقعك في المناطق غير المألوفة.',
              'قد بسرعة آمنة على الطرق الجبلية.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.terrain_rounded,
          title: _t('طبیعت‌گردی و کوهنوردی', 'Nature & Hiking', 'الطبيعة وتسلق الجبال'),
          subtitle: _t(
            'طبیعت را ببینید و سالم به خانه برگردید',
            'Enjoy nature and return home safely',
            'استمتع بالطبيعة وعد إلى المنزل بأمان',
          ),
          tips: _tList(
            [
              'کفش و لباس مناسب مسیر همراه داشته باشید.',
              'آب کافی و وسایل ضروری را فراموش نکنید.',
              'قبل از ورود به مسیرهای ناشناخته، شرایط مسیر را بررسی کنید.',
              'تنها در مسیرهای دشوار و ناشناخته حرکت نکنید.',
              'زباله‌های خود را در طبیعت رها نکنید.',
            ],
            [
              'Wear suitable shoes and clothing for the route.',
              'Do not forget enough water and essential equipment.',
              'Check trail conditions before entering unfamiliar routes.',
              'Do not travel alone on difficult or unfamiliar routes.',
              'Do not leave your waste in nature.',
            ],
            [
              'ارتدِ أحذية وملابس مناسبة للمسار.',
              'لا تنسَ الماء الكافي والمعدات الضرورية.',
              'تحقق من حالة المسار قبل دخول الطرق غير المألوفة.',
              'لا تسلك الطرق الصعبة وغير المألوفة بمفردك.',
              'لا تترك النفايات في الطبيعة.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.home_work_rounded,
          title: _t('اقامتگاه و بوم‌گردی', 'Accommodation & Ecotourism', 'الإقامة والسياحة البيئية'),
          subtitle: _t(
            'انتخاب اقامتگاهی مناسب برای سفر',
            'Choose the right place to stay',
            'اختر مكان الإقامة المناسب لرحلتك',
          ),
          tips: _tList(
            [
              'موقعیت اقامتگاه را قبل از انتخاب بررسی کنید.',
              'امکانات و شرایط اقامت را از قبل بپرسید.',
              'برای اقامتگاه‌های دور از شهر، مسیر دسترسی را بررسی کنید.',
              'به قوانین و فرهنگ محلی احترام بگذارید.',
              'در بوم‌گردی‌ها به حفظ محیط‌زیست و بافت سنتی کمک کنید.',
            ],
            [
              'Check the accommodation location before choosing it.',
              'Ask about facilities and stay conditions in advance.',
              'Check access routes for accommodation outside cities.',
              'Respect local rules and culture.',
              'Help preserve the environment and traditional character of ecotourism sites.',
            ],
            [
              'تحقق من موقع مكان الإقامة قبل اختياره.',
              'استفسر مسبقاً عن المرافق وشروط الإقامة.',
              'تحقق من طريق الوصول إلى أماكن الإقامة خارج المدن.',
              'احترم القوانين والثقافة المحلية.',
              'ساهم في حماية البيئة والطابع التقليدي في السياحة البيئية.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.restaurant_rounded,
          title: _t('گردشگری خوراک', 'Food Tourism', 'سياحة الطعام'),
          subtitle: _t(
            'طعم غذاهای محلی ایران را تجربه کنید',
            'Experience the flavors of local Iran',
            'اكتشف نكهات الأطعمة المحلية في إيران',
          ),
          tips: _tList(
            [
              'غذاهای محلی هر منطقه را با رعایت نکات بهداشتی امتحان کنید.',
              'از مراکز معتبر و تمیز غذا تهیه کنید.',
              'آب آشامیدنی سالم همراه داشته باشید.',
              'فرهنگ غذایی و سنت‌های محلی را محترم بشمارید.',
              'تجربه غذاهای سنتی بخشی از سفر و شناخت فرهنگ ایران است.',
            ],
            [
              'Try local foods while following health and hygiene guidance.',
              'Choose clean and reputable food providers.',
              'Carry safe drinking water.',
              'Respect local food culture and traditions.',
              'Traditional food is part of discovering Iran and its culture.',
            ],
            [
              'جرّب الأطعمة المحلية مع مراعاة قواعد الصحة والنظافة.',
              'اختر أماكن طعام موثوقة ونظيفة.',
              'احمل معك مياه شرب آمنة.',
              'احترم ثقافة الطعام والتقاليد المحلية.',
              'تجربة الطعام التقليدي جزء من اكتشاف إيران وثقافتها.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.eco_rounded,
          title: _t('حفاظت از طبیعت', 'Protecting Nature', 'حماية الطبيعة'),
          subtitle: _t(
            'سفر مسئولانه برای آیندگان',
            'Responsible travel for future generations',
            'سفر مسؤول من أجل الأجيال القادمة',
          ),
          tips: _tList(
            [
              'زباله در طبیعت رها نکنید.',
              'به درختان و پوشش گیاهی آسیب نزنید.',
              'از روشن کردن آتش در محل‌های ممنوع خودداری کنید.',
              'حیات‌وحش را تعقیب یا تغذیه نکنید.',
              'آب و منابع طبیعی را بیهوده مصرف نکنید.',
            ],
            [
              'Do not leave waste in nature.',
              'Do not damage trees or vegetation.',
              'Do not light fires where they are prohibited.',
              'Do not chase or feed wildlife.',
              'Use water and natural resources responsibly.',
            ],
            [
              'لا تترك النفايات في الطبيعة.',
              'لا تضر بالأشجار أو الغطاء النباتي.',
              'تجنب إشعال النار في الأماكن الممنوعة.',
              'لا تطارد الحيوانات البرية أو تطعمها.',
              'استخدم المياه والموارد الطبيعية بمسؤولية.',
            ],
          ),
        ),
        _GuideItem(
          icon: Icons.emergency_rounded,
          title: _t('ایمنی در سفر', 'Travel Safety', 'السلامة أثناء السفر'),
          subtitle: _t(
            'چند نکته ساده برای سفری امن‌تر',
            'Simple tips for a safer journey',
            'نصائح بسيطة لرحلة أكثر أماناً',
          ),
          tips: _tList(
            [
              'شماره‌های ضروری و اطلاعات تماس همراهان را در دسترس داشته باشید.',
              'در شرایط نامناسب جوی از ادامه مسیر پرخطر خودداری کنید.',
              'در مسیرهای کوهستانی و طبیعت، زمان بازگشت را در نظر بگیرید.',
              'وسایل کمک‌های اولیه را در سفرهای طبیعت‌گردی همراه داشته باشید.',
              'در شرایط اضطراری ابتدا خود و همراهان را به محل امن منتقل کنید.',
            ],
            [
              'Keep emergency numbers and companions’ contact details available.',
              'Avoid continuing a risky journey in bad weather.',
              'Plan your return time on mountain and nature routes.',
              'Carry first-aid supplies on nature trips.',
              'In an emergency, move yourself and your companions to safety first.',
            ],
            [
              'احتفظ بأرقام الطوارئ وبيانات الاتصال بالمرافقين في متناول اليد.',
              'تجنب مواصلة الطريق الخطر في الأحوال الجوية السيئة.',
              'حدد وقت العودة في المسارات الجبلية والطبيعية.',
              'احمل مستلزمات الإسعافات الأولية في رحلات الطبيعة.',
              'في حالة الطوارئ، انقل نفسك ومرافقيك إلى مكان آمن أولاً.',
            ],
          ),
        ),
      ];

  List<String> _tList(List<String> fa, List<String> en, List<String> ar) {
    switch (language) {
      case AppLanguage.persian:
        return fa;
      case AppLanguage.english:
        return en;
      case AppLanguage.arabic:
        return ar;
    }
  }

  List<String> get checklistItems => _tList(
        [
          'مدارک شناسایی',
          'کیف پول و وسایل ضروری',
          'شارژر و پاوربانک',
          'آب آشامیدنی',
          'داروهای مورد نیاز',
          'لباس مناسب مقصد',
          'کفش مناسب',
          'وسایل کمک‌های اولیه',
          'بررسی خودرو و سوخت',
          'بررسی مسیر سفر',
        ],
        [
          'Identification documents',
          'Wallet and essential items',
          'Charger and power bank',
          'Drinking water',
          'Required medicines',
          'Clothing suitable for the destination',
          'Suitable shoes',
          'First-aid supplies',
          'Vehicle and fuel check',
          'Trip route check',
        ],
        [
          'وثائق الهوية',
          'المحفظة والأغراض الضرورية',
          'الشاحن وبطارية الشحن',
          'مياه الشرب',
          'الأدوية اللازمة',
          'ملابس مناسبة للوجهة',
          'أحذية مناسبة',
          'مستلزمات الإسعافات الأولية',
          'فحص السيارة والوقود',
          'التحقق من مسار الرحلة',
        ],
      );

  late List<bool> checkedItems;

  @override
  void initState() {
    super.initState();
    checkedItems = List<bool>.filled(checklistItems.length, false);
  }

  int get checkedCount => checkedItems.where((item) => item).length;

  void _resetChecklist() {
    setState(() {
      checkedItems = List<bool>.filled(checklistItems.length, false);
    });
  }

  void _showGuideDetails(_GuideItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            decoration: const BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: goldColor.withValues(alpha: 0.13),
                        border: Border.all(color: goldColor.withValues(alpha: 0.55)),
                      ),
                      child: Icon(item.icon, color: goldColor, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: goldBright,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: item.tips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: goldColor.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 27,
                                  height: 27,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: goldColor.withValues(alpha: 0.12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: goldColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.tips[index],
                                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(
                          _t('بستن', 'Close', 'إغلاق'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: backgroundColor,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff12394d), Color(0xff09212f)],
        ),
        border: Border.all(color: goldColor.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: goldColor.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldColor.withValues(alpha: 0.13),
              border: Border.all(color: goldColor.withValues(alpha: 0.65), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.16),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.explore_rounded, color: goldColor, size: 37),
          ),
          const SizedBox(height: 13),
          Text(
            _t('راهنمای سفر سایروس توریست', 'Cyrus Tourist Travel Guide', 'دليل سفر سايروس توريست'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: goldBright, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(
            _t(
              'سفر بهتر، ایمن‌تر و لذت‌بخش‌تر با چند نکته ساده',
              'Travel better, safer and happier with a few simple tips',
              'سافر بشكل أفضل وأكثر أماناً ومتعة مع بعض النصائح البسيطة',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(_GuideItem item, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.23),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showGuideDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        goldColor.withValues(alpha: 0.18),
                        goldColor.withValues(alpha: 0.07),
                      ],
                    ),
                    border: Border.all(color: goldColor.withValues(alpha: 0.38)),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.07),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: goldColor, size: 29),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: goldColor.withValues(alpha: 0.10),
                    border: Border.all(color: goldColor.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    isRtl ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                    color: goldColor,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: cardColor2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: goldColor.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldColor.withValues(alpha: 0.12),
                  border: Border.all(color: goldColor.withValues(alpha: 0.40)),
                ),
                child: const Icon(Icons.checklist_rounded, color: goldColor, size: 27),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('چک‌لیست سفر', 'Travel Checklist', 'قائمة السفر'),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(color: goldBright, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _t(
                        'قبل از حرکت موارد ضروری را بررسی کنید.',
                        'Check essential items before departure.',
                        'تحقق من العناصر الضرورية قبل الانطلاق.',
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '$checkedCount/${checklistItems.length}',
                style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: checkedCount / checklistItems.length,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(checklistItems.length, (index) {
            return CheckboxListTile(
              value: checkedItems[index],
              onChanged: (value) {
                setState(() {
                  checkedItems[index] = value ?? false;
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: goldColor,
              checkColor: backgroundColor,
              controlAffinity: isRtl
                  ? ListTileControlAffinity.leading
                  : ListTileControlAffinity.trailing,
              title: Text(
                checklistItems[index],
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: checkedItems[index] ? Colors.white54 : Colors.white,
                  fontSize: 13,
                  decoration: checkedItems[index] ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetChecklist,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _t('پاک کردن چک‌لیست', 'Clear Checklist', 'مسح قائمة السفر'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: goldColor,
                side: BorderSide(color: goldColor.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 20),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: const Color(0xff0a202d),
        border: Border.all(color: goldColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          const Icon(Icons.favorite_rounded, color: goldColor, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _t(
                'ایران را ببینیم، طبیعت را دوست داشته باشیم و با سفر مسئولانه، زیبایی‌های کشورمان را برای آیندگان حفظ کنیم.',
                'Explore Iran, respect nature, and preserve the beauty of our country for future generations through responsible travel.',
                'لنستكشف إيران، ونحترم الطبيعة، ونحافظ على جمال بلدنا للأجيال القادمة من خلال السفر المسؤول.',
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            tooltip: _t('بازگشت', 'Back', 'رجوع'),
            icon: Icon(
              isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
              color: goldColor,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            _t('راهنمای سفر', 'Travel Guide', 'دليل السفر'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        width: 5,
                        height: 25,
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: goldColor.withValues(alpha: 0.35), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _t('راهنمای کاربردی سفر', 'Practical Travel Guide', 'دليل السفر العملي'),
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGuideCard(guideItems[index], index),
                  childCount: guideItems.length,
                ),
              ),
              SliverToBoxAdapter(child: _buildChecklist()),
              SliverToBoxAdapter(child: _buildTravelMessage()),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tips;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tips,
  });
}
