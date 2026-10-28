import 'package:flutter/material.dart';

import 'registration_hub_page.dart';

/// نوع ثبت‌نامی که از مسیرهای مختلف برنامه باز می‌شود.
enum ResidenceRegisterType { accommodation, hotel, cottage, health }

/// همهٔ مسیرهای قدیمی ثبت‌نام اقامتگاه/هتل/کلبه/گردشگری سلامت (منوی حساب، صفحهٔ فیلم،
/// ویترین و ...) حالا از همین کلاس می‌گذرند و صفحهٔ ثبت‌نام هم‌شکل سایت
/// ([RegistrationHubPage]) را نشان می‌دهند.
class ResidenceRegisterPage extends StatelessWidget {
  const ResidenceRegisterPage({
    super.key,
    this.type = ResidenceRegisterType.accommodation,
  });

  final ResidenceRegisterType type;

  String get _category =>
      type == ResidenceRegisterType.health ? 'health' : 'residence';

  /// نوع اقامتگاه که در فرم از قبل انتخاب می‌شود (اقامتگاه عمومی: بدون انتخاب).
  String? get _initialType {
    switch (type) {
      case ResidenceRegisterType.hotel:
        return 'hotel';
      case ResidenceRegisterType.cottage:
        return 'cottage';
      case ResidenceRegisterType.accommodation:
      case ResidenceRegisterType.health:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationHubPage(initialCategory: _category, initialType: _initialType);
  }
}
