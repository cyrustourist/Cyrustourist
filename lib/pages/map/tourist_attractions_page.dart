import 'package:flutter/material.dart';

class TouristAttractionsPage extends StatefulWidget {
  const TouristAttractionsPage({
    super.key,
  });

  @override
  State<TouristAttractionsPage> createState() =>
      _TouristAttractionsPageState();
}

class _TouristAttractionsPageState
    extends State<TouristAttractionsPage> {
  String selectedLanguage = 'fa';

  String _text(
    String fa,
    String en,
    String ar,
  ) {
    switch (selectedLanguage) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  final List<_AttractionCategory> categories = [
    _AttractionCategory(
      icon: Icons.account_balance_rounded,
      fa: 'تاریخی',
      en: 'Historical',
      ar: 'تاريخية',
    ),
    _AttractionCategory(
      icon: Icons.landscape_rounded,
      fa: 'طبیعت',
      en: 'Nature',
      ar: 'طبيعة',
    ),
    _AttractionCategory(
      icon: Icons.museum_rounded,
      fa: 'موزه',
      en: 'Museums',
      ar: 'متاحف',
    ),
    _AttractionCategory(
      icon: Icons.castle_rounded,
      fa: 'آثار باستانی',
      en: 'Archaeological',
      ar: 'آثار أثرية',
    ),
    _AttractionCategory(
      icon: Icons.photo_camera_rounded,
      fa: 'دیدنی‌ها',
      en: 'Sightseeing',
      ar: 'معالم',
    ),
    _AttractionCategory(
      icon: Icons.park_rounded,
      fa: 'پارک',
      en: 'Parks',
      ar: 'حدائق',
    ),
  ];

  final List<_AttractionItem> attractions = [
    _AttractionItem(
      icon: Icons.account_balance_rounded,
      fa: 'تخت جمشید',
      en: 'Persepolis',
      ar: 'تخت جمشيد',
      category: 'historical',
    ),
    _AttractionItem(
      icon: Icons.landscape_rounded,
      fa: 'کوه دماوند',
      en: 'Mount Damavand',
      ar: 'جبل دماوند',
      category: 'nature',
    ),
    _AttractionItem(
      icon: Icons.architecture_rounded,
      fa: 'سی‌وسه پل',
      en: 'Si-o-se-pol',
      ar: 'سي وسه پل',
      category: 'historical',
    ),
    _AttractionItem(
      icon: Icons.museum_rounded,
      fa: 'موزه ملی ایران',
      en: 'National Museum of Iran',
      ar: 'المتحف الوطني الإيراني',
      category: 'museum',
    ),
    _AttractionItem(
      icon: Icons.castle_rounded,
      fa: 'ارگ بم',
      en: 'Bam Citadel',
      ar: 'قلعة بم',
      category: 'archaeological',
    ),
    _AttractionItem(
      icon: Icons.park_rounded,
      fa: 'پارک ملت',
      en: 'Mellat Park',
      ar: 'حديقة ملت',
      category: 'park',
    ),
  ];

  String selectedCategory = 'all';

  List<_AttractionItem> get filteredAttractions {
    if (selectedCategory == 'all') {
      return attractions;
    }

    return attractions
        .where(
          (item) => item.category == selectedCategory,
        )
        .toList();
  }

  void _selectCategory(
    String category,
  ) {
    setState(() {
      selectedCategory = category;
    });
  }

  void _showAttraction(
    _AttractionItem item,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection:
              selectedLanguage == 'en'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xff071722),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  item.icon,
                  color: const Color(0xffffd36a),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  item.title(selectedLanguage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _text(
                    'این جاذبه در فهرست دیدنی‌های سایروس توریست قرار دارد.',
                    'This attraction is listed among Cyrus Tourist sights.',
                    'هذا المعلم مدرج ضمن معالم سايروس توريست.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.map_rounded,
                    ),
                    label: Text(
                      _text(
                        'نمایش روی نقشه',
                        'Show on map',
                        'عرض على الخريطة',
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xffffc84d),
                      foregroundColor:
                          const Color(0xff071722),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final rtl =
        selectedLanguage != 'en';

    return Directionality(
      textDirection:
          rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            const Color(0xffedf4f7),
        appBar: AppBar(
          elevation: 6,
          backgroundColor:
              const Color(0xff071722),
          foregroundColor: Colors.white,
          title: Text(
            _text(
              'جاذبه‌های گردشگری',
              'Tourist Attractions',
              'المعالم السياحية',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'fa',
                  child: Text('پارسی'),
                ),
                PopupMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                PopupMenuItem(
                  value: 'ar',
                  child: Text('العربية'),
                ),
              ],
              icon: const Icon(
                Icons.language_rounded,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // =================================================
              // HEADER
              // =================================================

              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  8,
                ),
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xff123d50),
                      Color(0xff071722),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.28,
                      ),
                      blurRadius: 14,
                      offset:
                          const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffffd36a,
                        ).withValues(
                          alpha: 0.16,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color:
                            Color(0xffffd36a),
                        size: 31,
                      ),
                    ),
                    const SizedBox(
                      width: 13,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _text(
                              'دنیای دیدنی‌های ایران',
                              'Discover Iran',
                              'اكتشف إيران',
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            _text(
                              'جاذبه مورد علاقه خود را انتخاب کنید',
                              'Choose an attraction to explore',
                              'اختر معلماً لاستكشافه',
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // CATEGORY BUTTONS
              // =================================================

              SizedBox(
                height: 91,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  scrollDirection:
                      Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),
                  itemCount:
                      categories.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    width: 9,
                  ),
                  itemBuilder:
                      (context, index) {
                    final category =
                        categories[index];

                    final categoryId =
                        _categoryId(
                      category,
                    );

                    final active =
                        selectedCategory ==
                            categoryId;

                    return _CategoryButton(
                      category: category,
                      title:
                          category.title(
                        selectedLanguage,
                      ),
                      active: active,
                      onTap: () {
                        _selectCategory(
                          categoryId,
                        );
                      },
                    );
                  },
                ),
              ),

              // =================================================
              // ALL BUTTON
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    color:
                        selectedCategory ==
                                'all'
                            ? const Color(
                                0xff0083B0,
                              )
                            : Colors.white,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      onTap: () {
                        _selectCategory(
                          'all',
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Icon(
                              Icons
                                  .apps_rounded,
                              color:
                                  selectedCategory ==
                                          'all'
                                      ? Colors
                                          .white
                                      : const Color(
                                          0xff0083B0,
                                        ),
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Text(
                              _text(
                                'همه جاذبه‌ها',
                                'All Attractions',
                                'كل المعالم',
                              ),
                              style: TextStyle(
                                color:
                                    selectedCategory ==
                                            'all'
                                        ? Colors
                                            .white
                                        : const Color(
                                            0xff123746,
                                          ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // ATTRACTIONS LIST
              // =================================================

              Expanded(
                child:
                    filteredAttractions.isEmpty
                        ? Center(
                            child: Text(
                              _text(
                                'جاذبه‌ای پیدا نشد.',
                                'No attractions found.',
                                'لم يتم العثور على معالم.',
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              14,
                              6,
                              14,
                              20,
                            ),
                            itemCount:
                                filteredAttractions
                                    .length,
                            itemBuilder:
                                (
                                  context,
                                  index,
                                ) {
                              final item =
                                  filteredAttractions[
                                      index];

                              return _AttractionCard(
                                item: item,
                                title:
                                    item.title(
                                  selectedLanguage,
                                ),
                                onTap: () {
                                  _showAttraction(
                                    item,
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryId(
    _AttractionCategory category,
  ) {
    if (category.fa == 'تاریخی') {
      return 'historical';
    }

    if (category.fa == 'طبیعت') {
      return 'nature';
    }

    if (category.fa == 'موزه') {
      return 'museum';
    }

    if (category.fa == 'آثار باستانی') {
      return 'archaeological';
    }

    if (category.fa == 'دیدنی‌ها') {
      return 'sightseeing';
    }

    if (category.fa == 'پارک') {
      return 'park';
    }

    return 'all';
  }
}

// ===============================================================
// CATEGORY MODEL
// ===============================================================

class _AttractionCategory {
  final IconData icon;
  final String fa;
  final String en;
  final String ar;

  const _AttractionCategory({
    required this.icon,
    required this.fa,
    required this.en,
    required this.ar,
  });

  String title(
    String language,
  ) {
    if (language == 'en') {
      return en;
    }

    if (language == 'ar') {
      return ar;
    }

    return fa;
  }
}

// ===============================================================
// ATTRACTION MODEL
// ===============================================================

class _AttractionItem {
  final IconData icon;
  final String fa;
  final String en;
  final String ar;
  final String category;

  const _AttractionItem({
    required this.icon,
    required this.fa,
    required this.en,
    required this.ar,
    required this.category,
  });

  String title(
    String language,
  ) {
    if (language == 'en') {
      return en;
    }

    if (language == 'ar') {
      return ar;
    }

    return fa;
  }
}

// ===============================================================
// CATEGORY BUTTON
// ===============================================================

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.title,
    required this.active,
    required this.onTap,
  });

  final _AttractionCategory category;
  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      elevation: 6,
      borderRadius:
          BorderRadius.circular(17),
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(17),
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          width: 92,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: active
                  ? const [
                      Color(0xffffe39a),
                      Color(0xffffc84d),
                    ]
                  : const [
                      Color(0xff123d50),
                      Color(0xff071722),
                    ],
            ),
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: active
                  ? const Color(
                      0xffffd36a,
                    )
                  : const Color(
                      0xffffd36a,
                    ).withValues(
                      alpha: 0.35,
                    ),
              width:
                  active ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.35,
                ),
                blurRadius: 9,
                offset:
                    const Offset(0, 5),
              ),
              if (active)
                BoxShadow(
                  color:
                      const Color(
                    0xffffd36a,
                  ).withValues(
                    alpha: 0.42,
                  ),
                  blurRadius: 14,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 27,
                color: active
                    ? const Color(
                        0xff071722,
                      )
                    : const Color(
                        0xffffd36a,
                      ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: active
                      ? const Color(
                          0xff071722,
                        )
                      : Colors.white,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// ATTRACTION CARD
// ===============================================================

class _AttractionCard
    extends StatelessWidget {
  const _AttractionCard({
    required this.item,
    required this.title,
    required this.onTap,
  });

  final _AttractionItem item;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        elevation: 6,
        borderRadius:
            BorderRadius.circular(21),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(21),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Color(0xff0083B0),
                        Color(0xff123d50),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 8,
                        offset:
                            const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color:
                        const Color(
                      0xffffd36a,
                    ),
                    size: 31,
                  ),
                ),
                const SizedBox(
                  width: 13,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xff123746,
                          ),
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Cyrus Tourist',
                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      Color(0xff0083B0),
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
