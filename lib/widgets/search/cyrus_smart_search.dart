import 'package:flutter/material.dart';

/// کلید ۹ — جستجوی هوشمند سایروس توریست.
///
/// این فایل مستقل است و فعلاً هیچ وابستگی به main.dart یا صفحات
/// اصلی برنامه ندارد.
/// اتصال نهایی در مرحله یکپارچه‌سازی انجام خواهد شد.
class CyrusSmartSearch extends StatelessWidget {
  const CyrusSmartSearch({
    super.key,
    this.languageCode = 'fa',
  });

  final String languageCode;

  bool get _isRtl =>
      languageCode.toLowerCase() == 'fa' ||
      languageCode.toLowerCase() == 'ar';

  @override
  Widget build(BuildContext context) {
    final items = _SearchTranslations.items(languageCode);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _buildSearchBox(),
                    const SizedBox(height: 18),

                    _buildSectionTitle(
                      items.sectionGeneral,
                      Icons.search_rounded,
                    ),
                    const SizedBox(height: 10),

                    CyrusSmartSearchButton(
                      item: items.quickSearch,
                      onTap: () => _searchTapped(context, items.quickSearch),
                    ),
                    CyrusSmartSearchButton(
                      item: items.cityProvince,
                      onTap: () =>
                          _searchTapped(context, items.cityProvince),
                    ),

                    const SizedBox(height: 18),

                    _buildSectionTitle(
                      items.sectionPlaces,
                      Icons.travel_explore_rounded,
                    ),
                    const SizedBox(height: 10),

                    CyrusSmartSearchButton(
                      item: items.restaurant,
                      onTap: () =>
                          _searchTapped(context, items.restaurant),
                    ),
                    CyrusSmartSearchButton(
                      item: items.cafe,
                      onTap: () => _searchTapped(context, items.cafe),
                    ),
                    CyrusSmartSearchButton(
                      item: items.shopping,
                      onTap: () =>
                          _searchTapped(context, items.shopping),
                    ),
                    CyrusSmartSearchButton(
                      item: items.historical,
                      onTap: () =>
                          _searchTapped(context, items.historical),
                    ),
                    CyrusSmartSearchButton(
                      item: items.nature,
                      onTap: () => _searchTapped(context, items.nature),
                    ),

                    const SizedBox(height: 18),

                    _buildSectionTitle(
                      items.sectionSmart,
                      Icons.psychology_rounded,
                    ),
                    const SizedBox(height: 10),

                    CyrusSmartSearchButton(
                      item: items.interests,
                      onTap: () =>
                          _searchTapped(context, items.interests),
                    ),
                    CyrusSmartSearchButton(
                      item: items.naturalLanguage,
                      onTap: () =>
                          _searchTapped(context, items.naturalLanguage),
                    ),
                    CyrusSmartSearchButton(
                      item: items.aroundMe,
                      onTap: () =>
                          _searchTapped(context, items.aroundMe),
                    ),
                    CyrusSmartSearchButton(
                      item: items.voice,
                      onTap: () => _searchTapped(context, items.voice),
                    ),
                    CyrusSmartSearchButton(
                      item: items.image,
                      futureFeature: true,
                      onTap: () =>
                          _futureFeatureTapped(context, items.image),
                    ),
                    CyrusSmartSearchButton(
                      item: items.suggestions,
                      onTap: () =>
                          _searchTapped(context, items.suggestions),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = _SearchTranslations.text(
      languageCode,
      'title',
    );

    final subtitle = _SearchTranslations.text(
      languageCode,
      'subtitle',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff102b3a),
            Color(0xff071722),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xffc99b3b),
            width: 0.7,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffd6ad55).withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildHeaderIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xffffd979),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xffc9d4d9),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xffffd978),
            Color(0xffb77b1f),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffe1b85a).withOpacity(0.38),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.manage_search_rounded,
        color: Color(0xff071722),
        size: 31,
      ),
    );
  }

  Widget _buildSearchBox() {
    final hint = _SearchTranslations.text(
      languageCode,
      'searchHint',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff102532),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffc99b3b).withOpacity(0.65),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xff8fa4ad),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xffffd56d),
          ),
          suffixIcon: const Icon(
            Icons.tune_rounded,
            color: Color(0xffc99b3b),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
        onSubmitted: (value) {
          // موتور جستجوی واقعی در مرحله اتصال به داده‌ها فعال خواهد شد.
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xffc99b3b).withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xffc99b3b).withOpacity(0.45),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xffffd56d),
            size: 19,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xffffd978),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  void _searchTapped(
    BuildContext context,
    CyrusSearchItem item,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.title,
          textDirection: _isRtl
              ? TextDirection.rtl
              : TextDirection.ltr,
        ),
        backgroundColor: const Color(0xff173444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _futureFeatureTapped(
    BuildContext context,
    CyrusSearchItem item,
  ) {
    final title = _SearchTranslations.text(
      languageCode,
      'futureTitle',
    );

    final message = _SearchTranslations.text(
      languageCode,
      'futureMessage',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff102532),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: Color(0xffc99b3b),
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xffffd56d),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xffffd978),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textDirection:
                _isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xffd6e0e4),
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _SearchTranslations.text(
                  languageCode,
                  'close',
                ),
                style: const TextStyle(
                  color: Color(0xffffd56d),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// مدل هر گزینه جستجوی هوشمند.
class CyrusSearchItem {
  const CyrusSearchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

/// مجموعه‌ی همه‌ی گزینه‌های جستجوی هوشمند به همراه عنوان بخش‌ها، برای
/// یک زبان مشخص. قبلاً این کلاس اصلاً تعریف نشده بود در حالی که
/// _SearchTranslations.items() آن را برمی‌گرداند — همین باعث خطای
/// «Method not found: CyrusSearchItems» می‌شد.
class CyrusSearchItems {
  const CyrusSearchItems({
    required this.sectionGeneral,
    required this.sectionPlaces,
    required this.sectionSmart,
    required this.quickSearch,
    required this.cityProvince,
    required this.restaurant,
    required this.cafe,
    required this.shopping,
    required this.historical,
    required this.nature,
    required this.interests,
    required this.naturalLanguage,
    required this.aroundMe,
    required this.voice,
    required this.image,
    required this.suggestions,
  });

  final String sectionGeneral;
  final String sectionPlaces;
  final String sectionSmart;

  final CyrusSearchItem quickSearch;
  final CyrusSearchItem cityProvince;
  final CyrusSearchItem restaurant;
  final CyrusSearchItem cafe;
  final CyrusSearchItem shopping;
  final CyrusSearchItem historical;
  final CyrusSearchItem nature;
  final CyrusSearchItem interests;
  final CyrusSearchItem naturalLanguage;
  final CyrusSearchItem aroundMe;
  final CyrusSearchItem voice;
  final CyrusSearchItem image;
  final CyrusSearchItem suggestions;
}

/// دکمه سه‌بعدی جستجوی هوشمند.
class CyrusSmartSearchButton extends StatefulWidget {
  const CyrusSmartSearchButton({
    super.key,
    required this.item,
    required this.onTap,
    this.futureFeature = false,
  });

  final CyrusSearchItem item;
  final VoidCallback onTap;
  final bool futureFeature;

  @override
  State<CyrusSmartSearchButton> createState() =>
      _CyrusSmartSearchButtonState();
}

class _CyrusSmartSearchButtonState
    extends State<CyrusSmartSearchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _pressed ? 3 : 0,
          0,
        ),
        margin: const EdgeInsets.only(bottom: 11),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xff102532),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: widget.futureFeature
                  ? const Color(0xff7f7048)
                  : const Color(0xffc99b3b).withOpacity(0.75),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff000000).withOpacity(0.35),
                blurRadius: _pressed ? 4 : 8,
                offset: Offset(
                  0,
                  _pressed ? 2 : 5,
                ),
              ),
              if (!widget.futureFeature)
                BoxShadow(
                  color: const Color(0xffd6ad55).withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.futureFeature
                        ? const [
                            Color(0xff4b4b43),
                            Color(0xff69634b),
                          ]
                        : const [
                            Color(0xffe1b85a),
                            Color(0xff9d681b),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffe0b34f)
                          .withOpacity(0.20),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  widget.item.icon,
                  color: const Color(0xff071722),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.subtitle,
                      style: const TextStyle(
                        color: Color(0xff9eb0b8),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.futureFeature
                    ? Icons.lock_clock_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: widget.futureFeature
                    ? const Color(0xffc0a75d)
                    : const Color(0xffffd56d),
                size: widget.futureFeature ? 20 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ترجمه‌های ۱۰ زبانه کلید ۹.
class _SearchTranslations {
  _SearchTranslations._();

  static String text(
    String languageCode,
    String key,
  ) {
    final lang = languageCode.toLowerCase();
    final data = _translations[lang] ?? _translations['fa']!;
    return data[key] ?? _translations['fa']![key]!;
  }

  static CyrusSearchItems items(
    String languageCode,
  ) {
    final lang = languageCode.toLowerCase();
    final data = _translations[lang] ?? _translations['fa']!;

    return CyrusSearchItems(
      sectionGeneral: data['sectionGeneral']!,
      sectionPlaces: data['sectionPlaces']!,
      sectionSmart: data['sectionSmart']!,
      quickSearch: CyrusSearchItem(
        icon: Icons.search_rounded,
        title: data['quickSearch']!,
        subtitle: data['quickSearchSub']!,
      ),
      cityProvince: CyrusSearchItem(
        icon: Icons.location_city_rounded,
        title: data['cityProvince']!,
        subtitle: data['cityProvinceSub']!,
      ),
      restaurant: CyrusSearchItem(
        icon: Icons.restaurant_rounded,
        title: data['restaurant']!,
        subtitle: data['restaurantSub']!,
      ),
      cafe: CyrusSearchItem(
        icon: Icons.local_cafe_rounded,
        title: data['cafe']!,
        subtitle: data['cafeSub']!,
      ),
      shopping: CyrusSearchItem(
        icon: Icons.shopping_bag_rounded,
        title: data['shopping']!,
        subtitle: data['shoppingSub']!,
      ),
      historical: CyrusSearchItem(
        icon: Icons.account_balance_rounded,
        title: data['historical']!,
        subtitle: data['historicalSub']!,
      ),
      nature: CyrusSearchItem(
        icon: Icons.forest_rounded,
        title: data['nature']!,
        subtitle: data['natureSub']!,
      ),
      interests: CyrusSearchItem(
        icon: Icons.favorite_rounded,
        title: data['interests']!,
        subtitle: data['interestsSub']!,
      ),
      naturalLanguage: CyrusSearchItem(
        icon: Icons.psychology_rounded,
        title: data['naturalLanguage']!,
        subtitle: data['naturalLanguageSub']!,
      ),
      aroundMe: CyrusSearchItem(
        icon: Icons.my_location_rounded,
        title: data['aroundMe']!,
        subtitle: data['aroundMeSub']!,
      ),
      voice: CyrusSearchItem(
        icon: Icons.mic_rounded,
        title: data['voice']!,
        subtitle: data['voiceSub']!,
      ),
      image: CyrusSearchItem(
        icon: Icons.image_search_rounded,
        title: data['image']!,
        subtitle: data['imageSub']!,
      ),
      suggestions: CyrusSearchItem(
        icon: Icons.auto_awesome_rounded,
        title: data['suggestions']!,
        subtitle: data['suggestionsSub']!,
      ),
    );
  }

  static const Map<String, Map<String, String>> _translations = {
    'fa': {
      'title': 'جستجوی هوشمند',
      'subtitle': 'همه جستجوهای گردشگری در یک مسیر هوشمند',
      'searchHint': 'چه چیزی می‌خواهید پیدا کنید؟',
      'sectionGeneral': 'جستجوی عمومی',
      'sectionPlaces': 'مکان‌ها و تجربه‌ها',
      'sectionSmart': 'جستجوی هوشمند',
      'quickSearch': 'جستجوی سریع',
      'quickSearchSub': 'جستجوی مستقیم در محتوای گردشگری',
      'cityProvince': 'جستجوی شهر و استان',
      'cityProvinceSub': 'پیدا کردن شهرها و استان‌های ایران',
      'restaurant': 'جستجوی رستوران و غذا',
      'restaurantSub': 'رستوران‌ها، غذاها و تجربه‌های غذایی',
      'cafe': 'جستجوی کافه',
      'cafeSub': 'کافه‌ها و مکان‌های مناسب برای استراحت',
      'shopping': 'جستجوی مراکز خرید و بازار',
      'shoppingSub': 'بازارها، مراکز خرید و خرید محلی',
      'historical': 'جستجوی آثار تاریخی و فرهنگی',
      'historicalSub': 'بناها، آثار و میراث فرهنگی',
      'nature': 'جستجوی طبیعت و مناطق بکر',
      'natureSub': 'جنگل، دریا، کوه، کویر و مناطق طبیعی',
      'interests': 'جستجو بر اساس علاقه',
      'interestsSub': 'نتایج متناسب با علایق شما',
      'naturalLanguage': 'جستجوی هوشمند با جمله طبیعی',
      'naturalLanguageSub':
          'مثلاً: یک جای خنک و طبیعت‌گردی نزدیک شیراز',
      'aroundMe': 'جستجو در اطراف من',
      'aroundMeSub': 'یافتن گزینه‌های گردشگری نزدیک موقعیت شما',
      'voice': 'جستجوی صوتی',
      'voiceSub': 'جستجو با فرمان و پرسش صوتی',
      'image': 'جستجو با تصویر',
      'imageSub': 'پیدا کردن مکان از روی عکس — در بروزرسانی آینده',
      'suggestions': 'پیشنهاد هوشمند هنگام جستجو',
      'suggestionsSub': 'پیشنهاد نتایج مرتبط در زمان جستجو',
      'futureTitle': 'این قابلیت در راه است',
      'futureMessage':
          'جستجوی تصویری در یکی از بروزرسانی‌های آینده سایروس توریست فعال خواهد شد.',
      'close': 'بستن',
    },
    'en': {
      'title': 'Smart Search',
      'subtitle': 'All tourism searches through one smart gateway',
      'searchHint': 'What are you looking for?',
      'sectionGeneral': 'General Search',
      'sectionPlaces': 'Places & Experiences',
      'sectionSmart': 'Smart Search',
      'quickSearch': 'Quick Search',
      'quickSearchSub': 'Search tourism content directly',
      'cityProvince': 'Search Cities & Provinces',
      'cityProvinceSub': 'Find cities and provinces of Iran',
      'restaurant': 'Restaurants & Food',
      'restaurantSub': 'Restaurants, food and dining experiences',
      'cafe': 'Search Cafes',
      'cafeSub': 'Cafes and relaxing places',
      'shopping': 'Shopping Centers & Bazaars',
      'shoppingSub': 'Markets, malls and local shopping',
      'historical': 'Historical & Cultural Sites',
      'historicalSub': 'Monuments, heritage and cultural sites',
      'nature': 'Nature & Hidden Places',
      'natureSub': 'Forests, seas, mountains, deserts and nature',
      'interests': 'Search by Interest',
      'interestsSub': 'Results based on your interests',
      'naturalLanguage': 'Natural Language Search',
      'naturalLanguageSub':
          'Example: a cool nature place near Shiraz',
      'aroundMe': 'Search Around Me',
      'aroundMeSub': 'Find tourism options near your location',
      'voice': 'Voice Search',
      'voiceSub': 'Search using your voice',
      'image': 'Image Search',
      'imageSub': 'Find places from photos — coming in a future update',
      'suggestions': 'Smart Search Suggestions',
      'suggestionsSub': 'Relevant suggestions while you search',
      'futureTitle': 'Coming Soon',
      'futureMessage':
          'Image search will be introduced in a future Cyrus Tourist update.',
      'close': 'Close',
    },
    'ar': {
      'title': 'البحث الذكي',
      'subtitle': 'جميع عمليات البحث السياحية عبر بوابة ذكية واحدة',
      'searchHint': 'ماذا تريد أن تجد؟',
      'sectionGeneral': 'البحث العام',
      'sectionPlaces': 'الأماكن والتجارب',
      'sectionSmart': 'البحث الذكي',
      'quickSearch': 'البحث السريع',
      'quickSearchSub': 'البحث المباشر في المحتوى السياحي',
      'cityProvince': 'البحث عن المدن والمحافظات',
      'cityProvinceSub': 'العثور على مدن ومحافظات إيران',
      'restaurant': 'المطاعم والطعام',
      'restaurantSub': 'المطاعم والأطعمة وتجارب الطعام',
      'cafe': 'البحث عن المقاهي',
      'cafeSub': 'المقاهي والأماكن المناسبة للاستراحة',
      'shopping': 'مراكز التسوق والأسواق',
      'shoppingSub': 'الأسواق ومراكز التسوق والتسوق المحلي',
      'historical': 'المواقع التاريخية والثقافية',
      'historicalSub': 'المعالم والتراث والمواقع الثقافية',
      'nature': 'الطبيعة والأماكن البكر',
      'natureSub': 'الغابات والبحار والجبال والصحارى',
      'interests': 'البحث حسب الاهتمام',
      'interestsSub': 'نتائج تناسب اهتماماتك',
      'naturalLanguage': 'البحث باللغة الطبيعية',
      'naturalLanguageSub': 'اكتب طلبك بجملة طبيعية',
      'aroundMe': 'البحث من حولي',
      'aroundMeSub': 'العثور على خيارات سياحية قريبة',
      'voice': 'البحث الصوتي',
      'voiceSub': 'البحث باستخدام الصوت',
      'image': 'البحث بالصورة',
      'imageSub': 'العثور على الأماكن من الصور — قريباً',
      'suggestions': 'الاقتراحات الذكية',
      'suggestionsSub': 'اقتراح نتائج مرتبطة أثناء البحث',
      'futureTitle': 'هذه الميزة قادمة',
      'futureMessage':
          'سيتم تفعيل البحث بالصور في أحد التحديثات المستقبلية.',
      'close': 'إغلاق',
    },
    'tr': {
      'title': 'Akıllı Arama',
      'subtitle': 'Tüm turizm aramaları tek akıllı merkezde',
      'searchHint': 'Ne arıyorsunuz?',
      'sectionGeneral': 'Genel Arama',
      'sectionPlaces': 'Yerler ve Deneyimler',
      'sectionSmart': 'Akıllı Arama',
      'quickSearch': 'Hızlı Arama',
      'quickSearchSub': 'Turizm içeriklerinde hızlı arama',
      'cityProvince': 'Şehir ve İl Arama',
      'cityProvinceSub': 'İran şehirlerini ve illerini bulun',
      'restaurant': 'Restoran ve Yemek',
      'restaurantSub': 'Restoranlar ve yemek deneyimleri',
      'cafe': 'Kafe Arama',
      'cafeSub': 'Kafeler ve dinlenme yerleri',
      'shopping': 'Alışveriş Merkezleri ve Pazarlar',
      'shoppingSub': 'Pazarlar ve alışveriş merkezleri',
      'historical': 'Tarihi ve Kültürel Yerler',
      'historicalSub': 'Anıtlar ve kültürel miras',
      'nature': 'Doğa ve Bakir Alanlar',
      'natureSub': 'Orman, deniz, dağ ve çöl',
      'interests': 'İlgi Alanına Göre Arama',
      'interestsSub': 'İlgi alanlarınıza göre sonuçlar',
      'naturalLanguage': 'Doğal Dil ile Arama',
      'naturalLanguageSub': 'İsteğinizi doğal bir cümleyle yazın',
      'aroundMe': 'Çevremde Ara',
      'aroundMeSub': 'Konumunuza yakın turizm seçenekleri',
      'voice': 'Sesli Arama',
      'voiceSub': 'Sesinizi kullanarak arayın',
      'image': 'Görsel Arama',
      'imageSub': 'Fotoğraftan yer bulma — gelecekte',
      'suggestions': 'Akıllı Öneriler',
      'suggestionsSub': 'Arama sırasında ilgili öneriler',
      'futureTitle': 'Yakında',
      'futureMessage':
          'Görsel arama gelecekteki bir Cyrus Tourist güncellemesinde sunulacaktır.',
      'close': 'Kapat',
    },
    'ru': {
      'title': 'Умный поиск',
      'subtitle': 'Все туристические поиски в одном умном центре',
      'searchHint': 'Что вы ищете?',
      'sectionGeneral': 'Общий поиск',
      'sectionPlaces': 'Места и впечатления',
      'sectionSmart': 'Умный поиск',
      'quickSearch': 'Быстрый поиск',
      'quickSearchSub': 'Быстрый поиск туристического контента',
      'cityProvince': 'Поиск городов и провинций',
      'cityProvinceSub': 'Найдите города и провинции Ирана',
      'restaurant': 'Рестораны и еда',
      'restaurantSub': 'Рестораны и гастрономические впечатления',
      'cafe': 'Поиск кафе',
      'cafeSub': 'Кафе и места для отдыха',
      'shopping': 'Торговые центры и рынки',
      'shoppingSub': 'Рынки и торговые центры',
      'historical': 'Исторические и культурные места',
      'historicalSub': 'Памятники и культурное наследие',
      'nature': 'Природа и нетронутые места',
      'natureSub': 'Леса, моря, горы и пустыни',
      'interests': 'Поиск по интересам',
      'interestsSub': 'Результаты по вашим интересам',
      'naturalLanguage': 'Поиск естественным языком',
      'naturalLanguageSub': 'Опишите запрос обычным предложением',
      'aroundMe': 'Поиск рядом со мной',
      'aroundMeSub': 'Туристические места рядом с вами',
      'voice': 'Голосовой поиск',
      'voiceSub': 'Поиск с помощью голоса',
      'image': 'Поиск по изображению',
      'imageSub': 'Поиск места по фото — в будущем',
      'suggestions': 'Умные предложения',
      'suggestionsSub': 'Связанные предложения во время поиска',
      'futureTitle': 'Скоро',
      'futureMessage':
          'Поиск по изображению появится в одном из будущих обновлений.',
      'close': 'Закрыть',
    },
    'fr': {
      'title': 'Recherche intelligente',
      'subtitle': 'Toutes les recherches touristiques en un seul endroit',
      'searchHint': 'Que recherchez-vous ?',
      'sectionGeneral': 'Recherche générale',
      'sectionPlaces': 'Lieux et expériences',
      'sectionSmart': 'Recherche intelligente',
      'quickSearch': 'Recherche rapide',
      'quickSearchSub': 'Rechercher rapidement le contenu touristique',
      'cityProvince': 'Villes et provinces',
      'cityProvinceSub': 'Trouver les villes et provinces d’Iran',
      'restaurant': 'Restaurants et cuisine',
      'restaurantSub': 'Restaurants et expériences culinaires',
      'cafe': 'Recherche de cafés',
      'cafeSub': 'Cafés et lieux de détente',
      'shopping': 'Centres commerciaux et marchés',
      'shoppingSub': 'Marchés et centres commerciaux',
      'historical': 'Sites historiques et culturels',
      'historicalSub': 'Monuments et patrimoine culturel',
      'nature': 'Nature et lieux préservés',
      'natureSub': 'Forêts, mers, montagnes et déserts',
      'interests': 'Recherche par intérêt',
      'interestsSub': 'Résultats selon vos intérêts',
      'naturalLanguage': 'Recherche en langage naturel',
      'naturalLanguageSub': 'Décrivez votre demande naturellement',
      'aroundMe': 'Recherche autour de moi',
      'aroundMeSub': 'Options touristiques près de votre position',
      'voice': 'Recherche vocale',
      'voiceSub': 'Rechercher avec votre voix',
      'image': 'Recherche par image',
      'imageSub': 'Trouver un lieu depuis une photo — bientôt',
      'suggestions': 'Suggestions intelligentes',
      'suggestionsSub': 'Suggestions pertinentes pendant la recherche',
      'futureTitle': 'Bientôt disponible',
      'futureMessage':
          'La recherche par image sera disponible dans une future mise à jour.',
      'close': 'Fermer',
    },
    'de': {
      'title': 'Intelligente Suche',
      'subtitle': 'Alle Tourismussuchen in einem intelligenten Zentrum',
      'searchHint': 'Wonach suchen Sie?',
      'sectionGeneral': 'Allgemeine Suche',
      'sectionPlaces': 'Orte und Erlebnisse',
      'sectionSmart': 'Intelligente Suche',
      'quickSearch': 'Schnellsuche',
      'quickSearchSub': 'Touristische Inhalte schnell durchsuchen',
      'cityProvince': 'Städte und Provinzen',
      'cityProvinceSub': 'Städte und Provinzen im Iran finden',
      'restaurant': 'Restaurants und Essen',
      'restaurantSub': 'Restaurants und kulinarische Erlebnisse',
      'cafe': 'Cafés suchen',
      'cafeSub': 'Cafés und Orte zum Entspannen',
      'shopping': 'Einkaufszentren und Märkte',
      'shoppingSub': 'Märkte und Einkaufszentren',
      'historical': 'Historische und kulturelle Orte',
      'historicalSub': 'Denkmäler und Kulturerbe',
      'nature': 'Natur und unberührte Orte',
      'natureSub': 'Wälder, Meere, Berge und Wüsten',
      'interests': 'Suche nach Interessen',
      'interestsSub': 'Ergebnisse passend zu Ihren Interessen',
      'naturalLanguage': 'Suche in natürlicher Sprache',
      'naturalLanguageSub': 'Beschreiben Sie Ihre Suche natürlich',
      'aroundMe': 'In meiner Nähe suchen',
      'aroundMeSub': 'Touristische Optionen in Ihrer Nähe',
      'voice': 'Sprachsuche',
      'voiceSub': 'Mit Ihrer Stimme suchen',
      'image': 'Bildsuche',
      'imageSub': 'Orte anhand von Fotos finden — später',
      'suggestions': 'Intelligente Vorschläge',
      'suggestionsSub': 'Relevante Vorschläge während der Suche',
      'futureTitle': 'Kommt bald',
      'futureMessage':
          'Die Bildsuche wird in einem zukünftigen Update verfügbar sein.',
      'close': 'Schließen',
    },
    'es': {
      'title': 'Búsqueda inteligente',
      'subtitle': 'Todas las búsquedas turísticas en un solo lugar',
      'searchHint': '¿Qué estás buscando?',
      'sectionGeneral': 'Búsqueda general',
      'sectionPlaces': 'Lugares y experiencias',
      'sectionSmart': 'Búsqueda inteligente',
      'quickSearch': 'Búsqueda rápida',
      'quickSearchSub': 'Buscar contenido turístico rápidamente',
      'cityProvince': 'Ciudades y provincias',
      'cityProvinceSub': 'Encuentra ciudades y provincias de Irán',
      'restaurant': 'Restaurantes y comida',
      'restaurantSub': 'Restaurantes y experiencias gastronómicas',
      'cafe': 'Buscar cafeterías',
      'cafeSub': 'Cafeterías y lugares para relajarse',
      'shopping': 'Centros comerciales y mercados',
      'shoppingSub': 'Mercados y centros comerciales',
      'historical': 'Lugares históricos y culturales',
      'historicalSub': 'Monumentos y patrimonio cultural',
      'nature': 'Naturaleza y lugares vírgenes',
      'natureSub': 'Bosques, mares, montañas y desiertos',
      'interests': 'Buscar por interés',
      'interestsSub': 'Resultados según tus intereses',
      'naturalLanguage': 'Búsqueda con lenguaje natural',
      'naturalLanguageSub': 'Describe tu solicitud con una frase',
      'aroundMe': 'Buscar cerca de mí',
      'aroundMeSub': 'Opciones turísticas cerca de tu ubicación',
      'voice': 'Búsqueda por voz',
      'voiceSub': 'Busca usando tu voz',
      'image': 'Búsqueda por imagen',
      'imageSub': 'Encontrar lugares desde fotos — próximamente',
      'suggestions': 'Sugerencias inteligentes',
      'suggestionsSub': 'Sugerencias relevantes mientras buscas',
      'futureTitle': 'Próximamente',
      'futureMessage':
          'La búsqueda por imagen estará disponible en una futura actualización.',
      'close': 'Cerrar',
    },
    'zh': {
      'title': '智能搜索',
      'subtitle': '通过一个智能入口完成所有旅游搜索',
      'searchHint': '您想寻找什么？',
      'sectionGeneral': '常规搜索',
      'sectionPlaces': '地点与体验',
      'sectionSmart': '智能搜索',
      'quickSearch': '快速搜索',
      'quickSearchSub': '快速搜索旅游内容',
      'cityProvince': '城市和省份搜索',
      'cityProvinceSub': '查找伊朗的城市和省份',
      'restaurant': '餐厅和美食',
      'restaurantSub': '餐厅、美食和用餐体验',
      'cafe': '咖啡馆搜索',
      'cafeSub': '咖啡馆和休闲场所',
      'shopping': '购物中心和市场',
      'shoppingSub': '市场、商场和本地购物',
      'historical': '历史与文化遗址',
      'historicalSub': '古迹、遗产和文化景点',
      'nature': '自然与原生态地区',
      'natureSub': '森林、海洋、山脉和沙漠',
      'interests': '按兴趣搜索',
      'interestsSub': '根据您的兴趣提供结果',
      'naturalLanguage': '自然语言搜索',
      'naturalLanguageSub': '用自然句子描述您的需求',
      'aroundMe': '搜索附近',
      'aroundMeSub': '查找您当前位置附近的旅游选择',
      'voice': '语音搜索',
      'voiceSub': '使用语音进行搜索',
      'image': '图片搜索',
      'imageSub': '通过照片寻找地点 — 未来更新',
      'suggestions': '智能搜索建议',
      'suggestionsSub': '搜索时提供相关建议',
      'futureTitle': '即将推出',
      'futureMessage': '图片搜索将在未来的赛勒斯旅游更新中推出。',
      'close': '关闭',
    },
    'it': {
      'title': 'Ricerca intelligente',
      'subtitle': 'Tutte le ricerche turistiche in un unico hub intelligente',
      'searchHint': 'Cosa stai cercando?',
      'sectionGeneral': 'Ricerca generale',
      'sectionPlaces': 'Luoghi ed esperienze',
      'sectionSmart': 'Ricerca intelligente',
      'quickSearch': 'Ricerca rapida',
      'quickSearchSub': 'Cerca rapidamente contenuti turistici',
      'cityProvince': 'Città e province',
      'cityProvinceSub': 'Trova città e province dell\u2019Iran',
      'restaurant': 'Ristoranti e cucina',
      'restaurantSub': 'Ristoranti ed esperienze gastronomiche',
      'cafe': 'Cerca caffetterie',
      'cafeSub': 'Caffetterie e luoghi per rilassarsi',
      'shopping': 'Centri commerciali e mercati',
      'shoppingSub': 'Mercati, centri commerciali e shopping locale',
      'historical': 'Siti storici e culturali',
      'historicalSub': 'Monumenti, patrimonio e siti culturali',
      'nature': 'Natura e luoghi incontaminati',
      'natureSub': 'Foreste, mari, montagne e deserti',
      'interests': 'Cerca per interesse',
      'interestsSub': 'Risultati in base ai tuoi interessi',
      'naturalLanguage': 'Ricerca in linguaggio naturale',
      'naturalLanguageSub': 'Descrivi la tua richiesta con una frase',
      'aroundMe': 'Cerca vicino a me',
      'aroundMeSub': 'Opzioni turistiche vicino alla tua posizione',
      'voice': 'Ricerca vocale',
      'voiceSub': 'Cerca usando la tua voce',
      'image': 'Ricerca per immagine',
      'imageSub': 'Trova un luogo da una foto — prossimamente',
      'suggestions': 'Suggerimenti intelligenti',
      'suggestionsSub': 'Suggerimenti pertinenti durante la ricerca',
      'futureTitle': 'Disponibile a breve',
      'futureMessage':
          'La ricerca per immagine sarà disponibile in un futuro aggiornamento.',
      'close': 'Chiudi',
    },
  };
}

/// مجموعه گزینه‌های جستجو.
class CyrusSmartSearchItems {
  const CyrusSmartSearchItems({
    required this.sectionGeneral,
    required this.sectionPlaces,
    required this.sectionSmart,
    required this.quickSearch,
    required this.cityProvince,
    required this.restaurant,
    required this.cafe,
    required this.shopping,
    required this.historical,
    required this.nature,
    required this.interests,
    required this.naturalLanguage,
    required this.aroundMe,
    required this.voice,
    required this.image,
    required this.suggestions,
  });

  final String sectionGeneral;
  final String sectionPlaces;
  final String sectionSmart;

  final CyrusSearchItem quickSearch;
  final CyrusSearchItem cityProvince;
  final CyrusSearchItem restaurant;
  final CyrusSearchItem cafe;
  final CyrusSearchItem shopping;
  final CyrusSearchItem historical;
  final CyrusSearchItem nature;
  final CyrusSearchItem interests;
  final CyrusSearchItem naturalLanguage;
  final CyrusSearchItem aroundMe;
  final CyrusSearchItem voice;
  final CyrusSearchItem image;
  final CyrusSearchItem suggestions;
}
