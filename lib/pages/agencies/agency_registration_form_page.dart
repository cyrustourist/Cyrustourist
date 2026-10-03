import 'package:flutter/material.dart';

import '../../widgets/advanced_registration_form.dart';

/// «درخواست ثبت‌نام آژانس» — فرم پیشرفته؛ فقط ارسال درخواست به پشتیبانی.
/// ثبت‌نام نهایی و فعال‌سازی فقط توسط مدیریت (پنل) انجام می‌شود.
class AgencyRegistrationFormPage extends StatelessWidget {
  const AgencyRegistrationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvancedRegistrationForm(
      pageTitle: 'درخواست ثبت‌نام آژانس',
      messageTitle: 'درخواست ثبت‌نام آژانس',
      intro:
          'اطلاعات شما فقط برای هماهنگی توسط پشتیبانی CYRUS TOURIST استفاده می‌شود. '
          'لوگو و عکس پروفایل آژانس را بعد از تأیید، مدیریت از طریق پنل ثبت می‌کند.',
      successText:
          'درخواست شما با موفقیت دریافت شد. اطلاعات آژانس شما توسط مدیریت CYRUS TOURIST '
          'بررسی خواهد شد و پس از بررسی، جهت ادامه مراحل با شما تماس گرفته خواهد شد.',
      accent: Color(0xffffd36a),
      sections: [
        RegSection(
          title: 'مشخصات آژانس',
          color: Color(0xffffd36a),
          icon: Icons.business_center_rounded,
          fields: [
            RegField(key: 'name', label: 'نام آژانس', required: true, icon: Icons.apartment_rounded),
            RegField(key: 'manager', label: 'نام مدیر آژانس', required: true, icon: Icons.person_rounded),
            RegField(key: 'license', label: 'شماره مجوز (در صورت وجود)', icon: Icons.verified_rounded),
            RegField(key: 'experience', label: 'سابقه فعالیت', hint: 'مثلاً ۱۰ سال', icon: Icons.history_rounded),
          ],
        ),
        RegSection(
          title: 'تماس و آدرس',
          color: Color(0xff29e0ad),
          icon: Icons.call_rounded,
          fields: [
            RegField(key: 'phone', label: 'شماره تماس', hint: '09xxxxxxxxx', type: RegFieldType.phone, required: true, icon: Icons.phone_android_rounded),
            RegField(key: 'province', label: 'استان', required: true, icon: Icons.map_rounded),
            RegField(key: 'city', label: 'شهر محل فعالیت', required: true, icon: Icons.location_city_rounded),
            RegField(key: 'address', label: 'آدرس دفتر', type: RegFieldType.multiline, icon: Icons.place_rounded),
          ],
        ),
        RegSection(
          title: 'خدمات و تورها',
          color: Color(0xff66d9ff),
          icon: Icons.luggage_rounded,
          chipKey: 'services',
          chipLabel: 'خدمات ارائه‌شده',
          chipOptions: [
            'تور داخلی',
            'تور خارجی',
            'بلیط هواپیما',
            'رزرو هتل',
            'ویزا',
            'بیمه مسافرتی',
            'ترانسفر',
            'تور سازمانی',
            'تور سلامت',
          ],
          fields: [
            RegField(key: 'regions', label: 'مناطق / مقاصد اصلی', hint: 'مثلاً شمال، خراسان، ترکیه', icon: Icons.explore_rounded),
            RegField(key: 'description', label: 'توضیحات (اختیاری)', type: RegFieldType.multiline, icon: Icons.notes_rounded),
          ],
        ),
        RegSection(
          title: 'وب‌سایت و شبکه‌های اجتماعی',
          color: Color(0xffc89cff),
          icon: Icons.public_rounded,
          fields: [
            RegField(key: 'website', label: 'وب‌سایت', hint: 'https://', type: RegFieldType.url, icon: Icons.language_rounded),
            RegField(key: 'instagram', label: 'اینستاگرام', hint: '@agency', type: RegFieldType.url, icon: Icons.camera_alt_rounded),
            RegField(key: 'telegram', label: 'تلگرام / ایتا', type: RegFieldType.url, icon: Icons.send_rounded),
          ],
        ),
      ],
    );
  }
}
