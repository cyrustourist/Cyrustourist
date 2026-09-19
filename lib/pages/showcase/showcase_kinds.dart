import 'package:flutter/material.dart';

import '../../models/showcase_item.dart';

/// یک کلید نوار ابزار (چیپ). اگر [opensKind] داشته باشد، به‌جای فیلتر،
/// صفحه‌ی دیگری (مثلاً لیدرها) را باز می‌کند.
class ShowcaseFilter {
  const ShowcaseFilter({
    required this.key,
    required this.labels,
    this.keywords = const [],
    this.opensKind,
  });

  final String key;
  final Map<String, String> labels;

  /// کلمات کمکی برای تطبیق داده‌های محلی که هنوز کلید دسته ندارند
  final List<String> keywords;
  final ShowcaseKind? opensKind;

  String label(String lang) => ShowcaseItem.pick(labels, lang);

  factory ShowcaseFilter.fromJson(Map<String, dynamic> j) {
    final labels = <String, String>{};
    final raw = j['label'];
    if (raw is Map) {
      raw.forEach((k, v) => labels[k.toString()] = v?.toString() ?? '');
    } else if (raw is String) {
      labels['fa'] = raw;
    }
    ShowcaseKind? opens;
    final o = j['opens']?.toString();
    if (o != null) {
      for (final k in ShowcaseKind.values) {
        if (k.apiName == o) opens = k;
      }
    }
    return ShowcaseFilter(
      key: j['key']?.toString() ?? '',
      labels: labels,
      keywords: (j['keywords'] is List)
          ? (j['keywords'] as List).map((e) => e.toString()).toList()
          : const [],
      opensKind: opens,
    );
  }
}

/// تنظیمات هر صفحه‌ی نمایش: عنوان، نوار ابزار اختصاصی، متن‌ها.
class ShowcaseKindInfo {
  const ShowcaseKindInfo({
    required this.kind,
    required this.titles,
    required this.hints,
    required this.emptyTexts,
    required this.icon,
    this.filters = const [],
    this.dynamicFilters = false,
  });

  final ShowcaseKind kind;
  final Map<String, String> titles;
  final Map<String, String> hints;
  final Map<String, String> emptyTexts;
  final IconData icon;

  /// فیلترهای ثابت (بعد از «همه»)
  final List<ShowcaseFilter> filters;

  /// اگر true باشد، چیپ‌ها از دسته‌های موجود در داده ساخته می‌شوند
  final bool dynamicFilters;

  String title(String lang) => ShowcaseItem.pick(titles, lang);
  String hint(String lang) => ShowcaseItem.pick(hints, lang);
  String emptyText(String lang) => ShowcaseItem.pick(emptyTexts, lang);
}

const ShowcaseFilter _leaderChip = ShowcaseFilter(
  key: 'leader',
  labels: {'fa': 'لیدر تور', 'en': 'Tour Leader', 'ar': 'قائد الجولة'},
  opensKind: ShowcaseKind.leader,
);

const Map<String, String> _soonText = {
  'fa': 'به‌زودی این بخش تکمیل می‌شود — سپاس از همراهی‌تان با سایروس توریست 🌿',
  'en': 'Coming soon — thank you for being with Cyrus Tourist 🌿',
  'ar': 'قريبًا — شكرًا لمرافقتكم سايروس توريست 🌿',
};

class ShowcaseKinds {
  ShowcaseKinds._();

  static ShowcaseKindInfo of(ShowcaseKind kind) {
    switch (kind) {
      case ShowcaseKind.video:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.video,
          titles: {
            'fa': 'گالری فیلم‌های گردشگری',
            'en': 'Tourism Video Gallery',
            'ar': 'معرض فيديوهات السياحة',
          },
          hints: {
            'fa': 'جست‌وجو با کد، نام فیلم، شهر یا استان...',
            'en': 'Search by code, title, city or province...',
            'ar': 'ابحث بالرمز أو الاسم أو المدينة أو المحافظة...',
          },
          emptyTexts: _soonText,
          icon: Icons.movie_filter_rounded,
          dynamicFilters: true,
          filters: [_leaderChip],
        );

      case ShowcaseKind.attraction:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.attraction,
          titles: {
            'fa': 'نمایش جاذبه‌های گردشگری',
            'en': 'Tourist Attractions Showcase',
            'ar': 'عرض المعالم السياحية',
          },
          hints: {
            'fa': 'جست‌وجوی جاذبه با کد، نام، شهر یا استان...',
            'en': 'Search attractions by code, name, city or province...',
            'ar': 'ابحث عن المعالم بالرمز أو الاسم أو المدينة...',
          },
          emptyTexts: _soonText,
          icon: Icons.landscape_rounded,
          filters: [
            _leaderChip,
            ShowcaseFilter(
              key: 'nature',
              labels: {'fa': 'طبیعت‌گردی', 'en': 'Nature', 'ar': 'السياحة الطبيعية'},
              keywords: ['طبیعت', 'آبشار', 'چشمه', 'جنگل', 'کوهنوردی', 'محیط زیست', 'سواحل', 'جزایر', 'nature', 'waterfall', 'spring', 'forest', 'mountain'],
            ),
            ShowcaseFilter(
              key: 'historic',
              labels: {'fa': 'میراث تاریخی', 'en': 'Historic', 'ar': 'تراث تاريخي'},
              keywords: ['میراث', 'تاریخ', 'باغ', 'موزه', 'قلعه', 'historic', 'heritage', 'museum', 'castle', 'garden'],
            ),
            ShowcaseFilter(
              key: 'culture',
              labels: {'fa': 'فرهنگ و هنر', 'en': 'Culture & Art', 'ar': 'الثقافة والفنون'},
              keywords: ['فرهنگ', 'هنر', 'ادب', 'نوروز', 'culture', 'art', 'literature', 'nowruz'],
            ),
            ShowcaseFilter(
              key: 'food',
              labels: {'fa': 'گردشگری خوراک', 'en': 'Food', 'ar': 'سياحة الطعام'},
              keywords: ['خوراک', 'غذا', 'food'],
            ),
            ShowcaseFilter(
              key: 'health',
              labels: {'fa': 'گردشگری سلامت', 'en': 'Health', 'ar': 'السياحة العلاجية'},
              keywords: ['سلامت', 'درمان', 'آبگرم', 'health', 'spa', 'clinic'],
            ),
          ],
        );

      case ShowcaseKind.accommodation:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.accommodation,
          titles: {
            'fa': 'نمایش اقامتگاه‌ها',
            'en': 'Accommodation Showcase',
            'ar': 'عرض أماكن الإقامة',
          },
          hints: {
            'fa': 'جست‌وجوی اقامتگاه با کد، نام، شهر یا استان...',
            'en': 'Search stays by code, name, city or province...',
            'ar': 'ابحث عن الإقامة بالرمز أو الاسم أو المدينة...',
          },
          emptyTexts: _soonText,
          icon: Icons.hotel_rounded,
          filters: [
            ShowcaseFilter(
              key: 'leader',
              labels: {'fa': 'لیدرها', 'en': 'Leaders', 'ar': 'القادة'},
              opensKind: ShowcaseKind.leader,
            ),
            ShowcaseFilter(
              key: 'hotel',
              labels: {'fa': 'هتل', 'en': 'Hotel', 'ar': 'فندق'},
              keywords: ['هتل', 'hotel'],
            ),
            ShowcaseFilter(
              key: 'ecolodge',
              labels: {'fa': 'بوم‌گردی', 'en': 'Eco-lodge', 'ar': 'نزل بيئي'},
              keywords: ['بوم گردی', 'بومگردی', 'ecolodge', 'eco-lodge'],
            ),
            ShowcaseFilter(
              key: 'cottage',
              labels: {'fa': 'کلبه', 'en': 'Cottage', 'ar': 'كوخ'},
              keywords: ['کلبه', 'cottage', 'cabin'],
            ),
            ShowcaseFilter(
              key: 'apartment',
              labels: {'fa': 'آپارتمان', 'en': 'Apartment', 'ar': 'شقة'},
              keywords: ['آپارتمان', 'apartment'],
            ),
            ShowcaseFilter(
              key: 'villa',
              labels: {'fa': 'ویلایی', 'en': 'Villa', 'ar': 'فيلا'},
              keywords: ['ویلا', 'villa'],
            ),
            ShowcaseFilter(
              key: 'suite',
              labels: {'fa': 'سوئیت', 'en': 'Suite', 'ar': 'جناح'},
              keywords: ['سوییت', 'سوئیت', 'suite'],
            ),
            ShowcaseFilter(
              key: 'guesthouse',
              labels: {'fa': 'مهمان‌پذیر', 'en': 'Guesthouse', 'ar': 'بيت ضيافة'},
              keywords: ['مهمان پذیر', 'مهمانپذیر', 'guesthouse', 'guest house'],
            ),
          ],
        );

      case ShowcaseKind.health:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.health,
          titles: {
            'fa': 'نمایش گردشگری سلامت',
            'en': 'Health Tourism Showcase',
            'ar': 'عرض السياحة العلاجية',
          },
          hints: {
            'fa': 'جست‌وجوی مرکز درمانی با کد، نام یا شهر...',
            'en': 'Search health centers by code, name or city...',
            'ar': 'ابحث عن المراكز الصحية بالرمز أو الاسم أو المدينة...',
          },
          emptyTexts: _soonText,
          icon: Icons.health_and_safety_rounded,
          filters: [
            ShowcaseFilter(
              key: 'hospital',
              labels: {'fa': 'بیمارستان', 'en': 'Hospital', 'ar': 'مستشفى'},
              keywords: ['بیمارستان', 'hospital'],
            ),
            ShowcaseFilter(
              key: 'clinic',
              labels: {'fa': 'کلینیک', 'en': 'Clinic', 'ar': 'عيادة'},
              keywords: ['کلینیک', 'درمانگاه', 'clinic'],
            ),
            ShowcaseFilter(
              key: 'spa',
              labels: {'fa': 'آبگرم و اسپا', 'en': 'Spa', 'ar': 'منتجع'},
              keywords: ['آبگرم', 'اسپا', 'spa'],
            ),
            ShowcaseFilter(
              key: 'dental',
              labels: {'fa': 'دندان‌پزشکی', 'en': 'Dental', 'ar': 'أسنان'},
              keywords: ['دندان', 'dental'],
            ),
            ShowcaseFilter(
              key: 'cosmetic',
              labels: {'fa': 'زیبایی', 'en': 'Cosmetic', 'ar': 'تجميل'},
              keywords: ['زیبایی', 'cosmetic'],
            ),
          ],
        );

      case ShowcaseKind.leader:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.leader,
          titles: {
            'fa': 'لیدرهای گردشگری',
            'en': 'Tour Leaders',
            'ar': 'قادة الرحلات السياحية',
          },
          hints: {
            'fa': 'جست‌وجوی لیدر با کد، نام یا شهر...',
            'en': 'Search leaders by code, name or city...',
            'ar': 'ابحث عن القادة بالرمز أو الاسم أو المدينة...',
          },
          emptyTexts: {
            'fa': 'هنوز لیدر تأییدشده‌ای ثبت نشده؛ به‌زودی لیدرهای سایروس توریست اینجا نمایش داده می‌شوند 🧭',
            'en': 'No approved leaders yet — Cyrus Tourist leaders will appear here soon 🧭',
            'ar': 'لا يوجد قادة معتمدون بعد — سيظهر قادة سايروس توريست هنا قريبًا 🧭',
          },
          icon: Icons.groups_2_rounded,
          filters: [
            ShowcaseFilter(
              key: 'local',
              labels: {'fa': 'لیدر محلی', 'en': 'Local leader', 'ar': 'قائد محلي'},
            ),
            ShowcaseFilter(
              key: 'licensed',
              labels: {'fa': 'دارای مجوز', 'en': 'Licensed', 'ar': 'مرخّص'},
            ),
            ShowcaseFilter(
              key: 'nature',
              labels: {'fa': 'طبیعت‌گردی', 'en': 'Nature', 'ar': 'السياحة الطبيعية'},
              keywords: ['طبیعت', 'nature'],
            ),
            ShowcaseFilter(
              key: 'historic',
              labels: {'fa': 'میراث تاریخی', 'en': 'Historic', 'ar': 'تراث تاريخي'},
              keywords: ['میراث', 'تاریخ', 'historic'],
            ),
          ],
        );

      case ShowcaseKind.agency:
        return const ShowcaseKindInfo(
          kind: ShowcaseKind.agency,
          titles: {
            'fa': 'آژانس‌های مسافرتی',
            'en': 'Travel Agencies',
            'ar': 'وكالات السفر',
          },
          hints: {
            'fa': 'جست‌وجوی آژانس با کد، نام یا شهر...',
            'en': 'Search agencies by code, name or city...',
            'ar': 'ابحث عن الوكالات بالرمز أو الاسم أو المدينة...',
          },
          emptyTexts: {
            'fa': 'هنوز آژانس تأییدشده‌ای ثبت نشده؛ به‌زودی آژانس‌های همکار اینجا نمایش داده می‌شوند ✈️',
            'en': 'No approved agencies yet — partner agencies will appear here soon ✈️',
            'ar': 'لا توجد وكالات معتمدة بعد — ستظهر الوكالات الشريكة هنا قريبًا ✈️',
          },
          icon: Icons.business_center_rounded,
          filters: [
            ShowcaseFilter(
              key: 'licensed',
              labels: {'fa': 'دارای مجوز', 'en': 'Licensed', 'ar': 'مرخّصة'},
            ),
            ShowcaseFilter(
              key: 'domestic',
              labels: {'fa': 'تور داخلی', 'en': 'Domestic', 'ar': 'رحلات داخلية'},
              keywords: ['داخلی', 'domestic'],
            ),
            ShowcaseFilter(
              key: 'international',
              labels: {'fa': 'تور خارجی', 'en': 'International', 'ar': 'رحلات خارجية'},
              keywords: ['خارجی', 'international'],
            ),
          ],
        );
    }
  }
}
