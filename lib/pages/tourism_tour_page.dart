import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../models/showcase_item.dart';
import 'showcase/showcase_gallery_page.dart';
import 'agencies/agency_registration_intro_page.dart';
import 'tours/tour_categories_page.dart';
import 'leaders/leader_registration_intro_page.dart';
import '../widgets/toolbox/cyrus_smart_toolbox.dart';

/// ===============================================================
/// Cyrus Tourist
/// کلید ۸ — تور گردشگری
///
/// جایگزین «جعبه ابزار» قدیم به‌عنوان کلید مستقل صفحه اصلی است؛
/// خودِ جعبه ابزار (cyrus_smart_toolbox.dart) حذف نشده و اکنون به‌صورت
/// یکی از گزینه‌های همین صفحه (زیرشاخه) در دسترس است.
/// این صفحه فعال است و به main.dart وصل شده؛ گزینه‌های آن به‌ترتیب
/// (طبق دستور کار) در به‌روزرسانی‌های بعدی به لیست _options اضافه
/// می‌شوند — کافی است یک آیتم جدید به انتهای لیست زیر افزوده شود.
/// ===============================================================

class _TourOption {
  const _TourOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}

class TourismTourPage extends StatelessWidget {
  const TourismTourPage({super.key, this.languageCode = 'fa'});

  final String languageCode;

  bool get _isRtl {
    final match = kMenuLanguages.where((l) => l.code == languageCode);
    if (match.isEmpty) return true; // پیش‌فرض فارسی/راست‌به‌چپ
    return match.first.isRtl;
  }

  // ---------------------------------------------------------------
  // گزینه‌های تور گردشگری — به ترتیب اضافه می‌شوند.
  // هر گزینه جدید فقط یک _TourOption دیگر به این لیست است.
  // عنوان/توضیح هر گزینه از MenuTranslations خوانده می‌شود تا هر ۱۰
  // زبان برنامه پوشش داده شود (قبلاً فقط فارسی/انگلیسی بود).
  // ---------------------------------------------------------------
  List<_TourOption> _options(BuildContext context) {
    return [
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 1),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 1),
        icon: Icons.luggage_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TourCategoriesPage()),
        ),
      ),
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 2),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 2),
        icon: Icons.groups_2_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShowcaseGalleryPage(kind: ShowcaseKind.leader),
          ),
        ),
      ),
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 3),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 3),
        icon: Icons.build_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CyrusSmartToolbox(languageCode: languageCode),
          ),
        ),
      ),
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 4),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 4),
        icon: Icons.apartment_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShowcaseGalleryPage(kind: ShowcaseKind.agency),
          ),
        ),
      ),
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 5),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 5),
        icon: Icons.how_to_reg_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderRegistrationIntroPage()),
        ),
      ),
      _TourOption(
        title: MenuTranslations.tourOptionTitle(languageCode, 6),
        subtitle: MenuTranslations.tourOptionSubtitle(languageCode, 6),
        icon: Icons.business_center_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgencyRegistrationIntroPage()),
        ),
      ),
      // گزینه‌های بعدی به ترتیب اینجا اضافه می‌شوند.
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _options(context);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xffffd76a)),
          title: Text(
            MenuTranslations.title(languageCode, 8),
            style: const TextStyle(
              color: Color(0xffffd76a),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: options.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildOptionTile(options[index]),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tour_rounded,
              size: 56,
              color: Color(0xffffd76a),
            ),
            const SizedBox(height: 16),
            Text(
              MenuTranslations.tourEmptyState(languageCode),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xfffff4be),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(_TourOption option) {
    return Material(
      color: const Color(0xff0e2433),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: option.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffffd76a).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffffd76a).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: const Color(0xffffd76a)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: Color(0xfffff4be),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: const Color(0xfffff4be).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                size: 14,
                color: const Color(0xffffd76a).withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
