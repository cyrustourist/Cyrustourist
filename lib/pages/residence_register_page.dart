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

  @override
  Widget build(BuildContext context) {
    return RegistrationHubPage(initialCategory: _category);
  }
}
