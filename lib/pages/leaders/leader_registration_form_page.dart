import 'package:flutter/material.dart';

import '../../widgets/advanced_registration_form.dart';

/// «درخواست ثبت‌نام لیدر» — فرم پیشرفته؛ فقط ارسال درخواست به پشتیبانی.
/// ثبت‌نام نهایی و فعال‌سازی فقط توسط مدیریت (پنل) انجام می‌شود.
class LeaderRegistrationFormPage extends StatelessWidget {
  const LeaderRegistrationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvancedRegistrationForm(
      pageTitle: 'درخواست ثبت‌نام لیدر',
      messageTitle: 'درخواست ثبت‌نام لیدر',
      intro:
          'اطلاعات شما فقط برای هماهنگی توسط پشتیبانی CYRUS TOURIST استفاده می‌شود. '
          'عکس پروفایل و مدارک را بعد از تأیید، مدیریت از طریق پنل ثبت می‌کند.',
      successText:
          'درخواست شما با موفقیت دریافت شد. اطلاعات شما توسط مدیریت CYRUS TOURIST '
          'بررسی خواهد شد و پس از بررسی، جهت ادامه مراحل با شما تماس گرفته خواهد شد.',
      accent: Color(0xff29e0ad),
      sections: [
        RegSection(
          title: 'مشخصات فردی',
          color: Color(0xff29e0ad),
          icon: Icons.badge_rounded,
          fields: [
            RegField(key: 'name', label: 'نام و نام خانوادگی', required: true, icon: Icons.person_rounded),
            RegField(key: 'phone', label: 'شماره تماس', hint: '09xxxxxxxxx', type: RegFieldType.phone, required: true, icon: Icons.phone_android_rounded),
            RegField(key: 'province', label: 'استان', required: true, icon: Icons.map_rounded),
            RegField(key: 'city', label: 'شهر محل فعالیت', required: true, icon: Icons.location_city_rounded),
          ],
        ),
        RegSection(
          title: 'تخصص و سابقه',
          color: Color(0xffffd36a),
          icon: Icons.workspace_premium_rounded,
          chipKey: 'fields',
          chipLabel: 'زمینه فعالیت',
          chipOptions: [
            'تاریخی و فرهنگی',
            'طبیعت‌گردی',
            'کویر و ماجراجویی',
            'تور شهری',
            'تور خانوادگی',
            'تور خارجی',
            'گردشگری سلامت',
          ],
          fields: [
            RegField(key: 'experience', label: 'سابقه فعالیت', hint: 'مثلاً ۵ سال', icon: Icons.history_rounded),
            RegField(key: 'license', label: 'شماره کارت لیدری / مجوز (در صورت وجود)', icon: Icons.verified_rounded),
            RegField(key: 'areas', label: 'مناطق فعالیت', hint: 'مثلاً یزد، اصفهان، کویر مرنجاب', icon: Icons.explore_rounded),
          ],
        ),
        RegSection(
          title: 'زبان‌ها',
          color: Color(0xff66d9ff),
          icon: Icons.translate_rounded,
          chipKey: 'languages',
          chipLabel: 'زبان‌هایی که مسلط هستید',
          chipOptions: ['فارسی', 'English', 'العربية', 'Türkçe', 'Русский', 'Deutsch', 'Français'],
          fields: [
            RegField(key: 'description', label: 'معرفی کوتاه (اختیاری)', type: RegFieldType.multiline, icon: Icons.notes_rounded),
          ],
        ),
        RegSection(
          title: 'شبکه‌های اجتماعی',
          color: Color(0xffc89cff),
          icon: Icons.public_rounded,
          fields: [
            RegField(key: 'instagram', label: 'اینستاگرام', hint: '@leader', type: RegFieldType.url, icon: Icons.camera_alt_rounded),
            RegField(key: 'telegram', label: 'تلگرام / ایتا', type: RegFieldType.url, icon: Icons.send_rounded),
          ],
        ),
      ],
    );
  }
}
