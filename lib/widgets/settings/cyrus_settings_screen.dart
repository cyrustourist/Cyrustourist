import 'package:flutter/material.dart';

import 'cyrus_settings_panel.dart';

/// صفحه مستقل تنظیمات سایروس توریست.
///
/// این فایل فقط صفحه و اتصال پایه به پنل تنظیمات را فراهم می‌کند.
/// گزینه‌های نهایی تنظیمات در مراحل بعدی و پس از تأیید اضافه خواهند شد.
class CyrusSettingsScreen extends StatelessWidget {
  const CyrusSettingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071722),
      body: CyrusSettingsPanel(
        title: 'تنظیمات',
        subtitle: 'تنظیمات سایروس توریست',
        onClose: () {
          Navigator.of(context).maybePop();
        },
        items: const [],
      ),
    );
  }
}
