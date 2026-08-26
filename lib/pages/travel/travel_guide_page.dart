import 'package:flutter/material.dart';

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

  final List<_GuideItem> guideItems = const [
    _GuideItem(
      icon: Icons.luggage_rounded,
      title: 'قبل از سفر',
      subtitle: 'آماده‌سازی هوشمندانه برای یک سفر بهتر',
      tips: [
        'مقصد و مسیر سفر را از قبل بررسی کنید.',
        'مدارک شناسایی و وسایل ضروری را همراه داشته باشید.',
        'لباس مناسب فصل و مقصد انتخاب کنید.',
        'مقدار کافی آب و خوراکی برای مسیر در نظر بگیرید.',
        'پیش از حرکت وضعیت خودرو و سوخت را بررسی کنید.',
      ],
    ),
    _GuideItem(
      icon: Icons.map_rounded,
      title: 'مسیر و جابه‌جایی',
      subtitle: 'راهنمای استفاده بهتر از مسیر و نقشه',
      tips: [
        'پیش از حرکت مسیر اصلی و مسیرهای جایگزین را بررسی کنید.',
        'برای مسیرهای طولانی زمان کافی در نظر بگیرید.',
        'در زمان رانندگی از تلفن همراه استفاده نکنید.',
        'در مناطق ناشناخته، موقعیت مکانی خود را بررسی کنید.',
        'در جاده‌های کوهستانی با سرعت مطمئن حرکت کنید.',
      ],
    ),
    _GuideItem(
      icon: Icons.terrain_rounded,
      title: 'طبیعت‌گردی و کوهنوردی',
      subtitle: 'طبیعت را ببینید و سالم به خانه برگردید',
      tips: [
        'کفش و لباس مناسب مسیر همراه داشته باشید.',
        'آب کافی و وسایل ضروری را فراموش نکنید.',
        'قبل از ورود به مسیرهای ناشناخته، شرایط مسیر را بررسی کنید.',
        'تنها در مسیرهای دشوار و ناشناخته حرکت نکنید.',
        'زباله‌های خود را در طبیعت رها نکنید.',
      ],
    ),
    _GuideItem(
      icon: Icons.home_work_rounded,
      title: 'اقامتگاه و بوم‌گردی',
      subtitle: 'انتخاب اقامتگاهی مناسب برای سفر',
      tips: [
        'موقعیت اقامتگاه را قبل از انتخاب بررسی کنید.',
        'امکانات و شرایط اقامت را از قبل بپرسید.',
        'برای اقامتگاه‌های دور از شهر، مسیر دسترسی را بررسی کنید.',
        'به قوانین و فرهنگ محلی احترام بگذارید.',
        'در بوم‌گردی‌ها به حفظ محیط‌زیست و بافت سنتی کمک کنید.',
      ],
    ),
    _GuideItem(
      icon: Icons.restaurant_rounded,
      title: 'گردشگری خوراک',
      subtitle: 'طعم غذاهای محلی ایران را تجربه کنید',
      tips: [
        'غذاهای محلی هر منطقه را با رعایت نکات بهداشتی امتحان کنید.',
        'از مراکز معتبر و تمیز غذا تهیه کنید.',
        'آب آشامیدنی سالم همراه داشته باشید.',
        'فرهنگ غذایی و سنت‌های محلی را محترم بشمارید.',
        'تجربه غذاهای سنتی بخشی از سفر و شناخت فرهنگ ایران است.',
      ],
    ),
    _GuideItem(
      icon: Icons.eco_rounded,
      title: 'حفاظت از طبیعت',
      subtitle: 'سفر مسئولانه برای آیندگان',
      tips: [
        'زباله در طبیعت رها نکنید.',
        'به درختان و پوشش گیاهی آسیب نزنید.',
        'از روشن کردن آتش در محل‌های ممنوع خودداری کنید.',
        'حیات‌وحش را تعقیب یا تغذیه نکنید.',
        'آب و منابع طبیعی را بیهوده مصرف نکنید.',
      ],
    ),
    _GuideItem(
      icon: Icons.emergency_rounded,
      title: 'ایمنی در سفر',
      subtitle: 'چند نکته ساده برای سفری امن‌تر',
      tips: [
        'شماره‌های ضروری و اطلاعات تماس همراهان را در دسترس داشته باشید.',
        'در شرایط نامناسب جوی از ادامه مسیر پرخطر خودداری کنید.',
        'در مسیرهای کوهستانی و طبیعت، زمان بازگشت را در نظر بگیرید.',
        'وسایل کمک‌های اولیه را در سفرهای طبیعت‌گردی همراه داشته باشید.',
        'در شرایط اضطراری ابتدا خود و همراهان را به محل امن منتقل کنید.',
      ],
    ),
  ];

  final List<String> checklistItems = const [
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
  ];

  late List<bool> checkedItems;

  @override
  void initState() {
    super.initState();
    checkedItems = List<bool>.filled(checklistItems.length, false);
  }

  int get checkedCount {
    return checkedItems.where((item) => item).length;
  }

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
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            decoration: const BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                        border: Border.all(
                          color: goldColor.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: goldColor,
                        size: 30,
                      ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: item.tips.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: goldColor.withValues(alpha: 0.18),
                              ),
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
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: backgroundColor,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'بستن',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
          colors: [
            Color(0xff12394d),
            Color(0xff09212f),
          ],
        ),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 15,
            offset: const Offset(0, 7),
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
              border: Border.all(
                color: goldColor.withValues(alpha: 0.65),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: goldColor,
              size: 37,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'راهنمای سفر سایروس توریست',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: goldBright,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'سفر بهتر، ایمن‌تر و لذت‌بخش‌تر با چند نکته ساده',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
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
        border: Border.all(
          color: goldColor.withValues(alpha: 0.22),
        ),
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
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: goldColor,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
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
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
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
        border: Border.all(
          color: goldColor.withValues(alpha: 0.30),
        ),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: goldColor.withValues(alpha: 0.40),
                  ),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: goldColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'چک‌لیست سفر',
                      style: TextStyle(
                        color: goldBright,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'قبل از حرکت موارد ضروری را بررسی کنید.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$checkedCount/${checklistItems.length}',
                style: const TextStyle(
                  color: goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                goldColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            checklistItems.length,
            (index) {
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
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  checklistItems[index],
                  style: TextStyle(
                    color: checkedItems[index]
                        ? Colors.white54
                        : Colors.white,
                    fontSize: 13,
                    decoration: checkedItems[index]
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetChecklist,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'پاک کردن چک‌لیست',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: goldColor,
                side: BorderSide(
                  color: goldColor.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
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
        border: Border.all(
          color: goldColor.withValues(alpha: 0.20),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: goldColor,
            size: 24,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'ایران را ببینیم، طبیعت را دوست داشته باشیم و با سفر مسئولانه، زیبایی‌های کشورمان را برای آیندگان حفظ کنیم.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.65,
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
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'راهنمای سفر',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 25,
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'راهنمای کاربردی سفر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildGuideCard(
                      guideItems[index],
                      index,
                    );
                  },
                  childCount: guideItems.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildChecklist(),
              ),
              SliverToBoxAdapter(
                child: _buildTravelMessage(),
              ),
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
