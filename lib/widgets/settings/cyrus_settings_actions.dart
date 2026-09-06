import 'package:flutter/material.dart';

import 'cyrus_settings_panel.dart';

/// عملیات و گزینه‌های تنظیمات سایروس توریست.
///
/// این فایل عمداً مستقل نگه داشته شده است تا بعداً گزینه‌های
/// تأییدشده تنظیمات بدون دستکاری ساختار اصلی برنامه اضافه شوند.
///
/// نکته اتصال نهایی:
/// گزینه‌های «شبکه‌های مجازی / درباره ما / پشتیبانی» در نهایت
/// از طریق cyrus_settings_social_about_support.dart به
/// cyrus_settings_screen.dart وصل شدند، چون آن فایل از قبل
/// UI سه‌بعدی و ترجمه کامل ۱۰ زبان آماده داشت. این فایل
/// (cyrus_settings_actions.dart) فعلاً استفاده نمی‌شود و برای
/// گزینه‌های تأییدشده‌ی بعدی نگه داشته شده است.
class CyrusSettingsActions {
  CyrusSettingsActions._();

  /// ساخت فهرست گزینه‌های تنظیمات.
  ///
  /// در حال حاضر فهرست خالی است تا فقط گزینه‌هایی که مهندس
  /// تأیید می‌کند به تنظیمات اضافه شوند.
  static List<CyrusSettingsItem> buildItems({
    required BuildContext context,
  }) {
    return const [];
  }

  /// باز کردن صفحه تنظیمات.
  static Future<void> openSettings(
    BuildContext context,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _SettingsScreenPlaceholder(),
      ),
    );
  }
}

/// صفحه واسط داخلی برای جلوگیری از وابستگی مستقیم این فایل
/// به فایل صفحه تنظیمات.
class _SettingsScreenPlaceholder extends StatelessWidget {
  const _SettingsScreenPlaceholder();

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
        items: CyrusSettingsActions.buildItems(
          context: context,
        ),
      ),
    );
  }
}
