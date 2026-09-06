import 'package:flutter/material.dart';

import '../pages/residence_register_page.dart';

/// دکمه حساب کاربری در هدر سایروس توریست.
///
/// این فایل فقط رابط کاربری و مسیر‌دهی هدر را مدیریت می‌کند.
/// منطق حساب کاربری و فرم‌های ثبت‌نام در فایل‌های اصلی خودشان باقی می‌مانند.
///
/// زبان‌های پشتیبانی‌شده:
/// fa, en, ar, tr, ru, fr, de, es, zh, ja
class CyrusHeaderAccountButton extends StatelessWidget {
  const CyrusHeaderAccountButton({
    super.key,
    this.currentLanguage = 'fa',
    this.username,
    this.onAccountPressed,
    this.onAccommodationRegistration,
    this.onHotelRegistration,
    this.onCottageRegistration,
    this.onHealthTourismRegistration,
  });

  /// زبان فعلی برنامه.
  final String currentLanguage;

  /// نام کاربری فعلی.
  ///
  /// اگر null یا خالی باشد، متن مناسب همان زبان نمایش داده می‌شود.
  final String? username;

  /// ورود به حساب کاربری.
  final VoidCallback? onAccountPressed;

  /// اتصال به فایل/صفحه ثبت‌نام اقامتگاه.
  final VoidCallback? onAccommodationRegistration;

  /// اتصال به فایل/صفحه ثبت‌نام هتل.
  final VoidCallback? onHotelRegistration;

  /// اتصال به فایل/صفحه ثبت‌نام کلبه.
  final VoidCallback? onCottageRegistration;

  /// اتصال به فایل/صفحه ثبت‌نام گردشگری سلامت.
  final VoidCallback? onHealthTourismRegistration;

  String get _language {
    const supported = <String>{
      'fa',
      'en',
      'ar',
      'tr',
      'ru',
      'fr',
      'de',
      'es',
      'zh',
      'ja',
    };

    return supported.contains(currentLanguage.toLowerCase())
        ? currentLanguage.toLowerCase()
        : 'fa';
  }

  bool get _isRtl => _language == 'fa' || _language == 'ar';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: PopupMenuButton<String>(
        tooltip: _tr('حساب کاربری', 'Account', 'الحساب', 'Hesap',
            'Аккаунт', 'Compte', 'Konto', 'Cuenta', '账户', 'アカウント'),
        onSelected: (value) {
          switch (value) {
            case 'account':
              onAccountPressed?.call();
              break;

            // هر چهار مسیر ثبت‌نام فعلاً به یک فایل ثبت‌نام
            // آماده و موجود وصل می‌شوند: residence_register_page.dart
            // (همان کلیدی که بالای «نمایش فیلم‌ها»، کلید ۴، قرار دارد).
            case 'accommodation':
              if (onAccommodationRegistration != null) {
                onAccommodationRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResidenceRegisterPage(),
                  ),
                );
              }
              break;

            case 'hotel':
              if (onHotelRegistration != null) {
                onHotelRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResidenceRegisterPage(),
                  ),
                );
              }
              break;

            case 'cottage':
              if (onCottageRegistration != null) {
                onCottageRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResidenceRegisterPage(),
                  ),
                );
              }
              break;

            case 'health':
              if (onHealthTourismRegistration != null) {
                onHealthTourismRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResidenceRegisterPage(),
                  ),
                );
              }
              break;
          }
        },
        color: const Color(0xff0b1d2a),
        elevation: 14,
        offset: const Offset(0, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(
            color: Color(0xffd6ad4f),
            width: 1.2,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'account',
            child: _HeaderAccountMenuItem(
              icon: Icons.person_rounded,
              iconColor: const Color(0xffe5bd55),
              title: username != null && username!.trim().isNotEmpty
                  ? username!.trim()
                  : _tr(
                      'نام کاربری',
                      'Username',
                      'اسم المستخدم',
                      'Kullanıcı adı',
                      'Имя пользователя',
                      'Nom d’utilisateur',
                      'Benutzername',
                      'Nombre de usuario',
                      '用户名',
                      'ユーザー名',
                    ),
              subtitle: _tr(
                'حساب کاربری',
                'Account',
                'الحساب',
                'Hesap',
                'Аккаунт',
                'Compte',
                'Konto',
                'Cuenta',
                '账户',
                'アカウント',
              ),
              bold: true,
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'accommodation',
            child: _HeaderAccountMenuItem(
              icon: Icons.hotel_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام اقامتگاه',
                'Accommodation Registration',
                'تسجيل مكان الإقامة',
                'Konaklama Kaydı',
                'Регистрация жилья',
                'Inscription hébergement',
                'Unterkunft registrieren',
                'Registro de alojamiento',
                '住宿登记',
                '宿泊施設登録',
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'hotel',
            child: _HeaderAccountMenuItem(
              icon: Icons.apartment_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام هتل',
                'Hotel Registration',
                'تسجيل الفندق',
                'Otel Kaydı',
                'Регистрация отеля',
                'Inscription hôtel',
                'Hotelregistrierung',
                'Registro de hotel',
                '酒店登记',
                'ホテル登録',
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'cottage',
            child: _HeaderAccountMenuItem(
              icon: Icons.cabin_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام کلبه',
                'Cottage Registration',
                'تسجيل الكوخ',
                'Bungalov Kaydı',
                'Регистрация коттеджа',
                'Inscription chalet',
                'Hüttenregistrierung',
                'Registro de cabaña',
                '小屋登记',
                'コテージ登録',
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'health',
            child: _HeaderAccountMenuItem(
              icon: Icons.local_hospital_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام گردشگری سلامت',
                'Health Tourism Registration',
                'تسجيل السياحة العلاجية',
                'Sağlık Turizmi Kaydı',
                'Регистрация медицинского туризма',
                'Inscription tourisme de santé',
                'Gesundheitstourismus registrieren',
                'Registro de turismo de salud',
                '医疗旅游登记',
                '医療ツーリズム登録',
              ),
            ),
          ),
        ],
        child: const _HeaderAccountButton(),
      ),
    );
  }

  String _tr(
    String fa,
    String en,
    String ar,
    String tr,
    String ru,
    String fr,
    String de,
    String es,
    String zh,
    String ja,
  ) {
    switch (_language) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      case 'tr':
        return tr;
      case 'ru':
        return ru;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'es':
        return es;
      case 'zh':
        return zh;
      case 'ja':
        return ja;
      case 'fa':
      default:
        return fa;
    }
  }
}

/// ظاهر اصلی دکمه آدمک در هدر.
class _HeaderAccountButton extends StatelessWidget {
  const _HeaderAccountButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff173246),
            Color(0xff081722),
          ],
        ),
        border: Border.all(
          color: const Color(0xffd6ad4f),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x55d6ad4f),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xffe5bd55),
        size: 25,
      ),
    );
  }
}

/// آیتم داخلی منوی حساب.
class _HeaderAccountMenuItem extends StatelessWidget {
  const _HeaderAccountMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.bold = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xff132b3a),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color(0x66d6ad4f),
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xffaebbc2),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
