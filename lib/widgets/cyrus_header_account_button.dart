import 'package:flutter/material.dart';

import '../pages/agencies/agency_registration_intro_page.dart';
import '../pages/leaders/leader_registration_intro_page.dart';
import '../pages/profile/my_profile_page.dart';
import '../pages/residence_register_page.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';

/// دکمه حساب کاربری در هدر سایروس توریست.
///
/// این فایل فقط رابط کاربری و مسیر‌دهی هدر را مدیریت می‌کند.
/// منطق حساب کاربری و فرم‌های ثبت‌نام در فایل‌های اصلی خودشان باقی می‌مانند.
///
/// زبان‌های پشتیبانی‌شده:
/// fa, en, ar, tr, ru, fr, de, es, zh, it
class CyrusHeaderAccountButton extends StatelessWidget {
  /// نمایش گزینه‌های ثبت‌نام در منوی آیکون آدمک.
  /// برای نسخه‌ی مارکت false است؛ برای فعال‌سازی دوباره true کنید.
  static const bool showRegistrationMenu = false;

  const CyrusHeaderAccountButton({
    super.key,
    this.currentLanguage = 'fa',
    this.username,
    this.onAccountPressed,
    this.onAccommodationRegistration,
    this.onHotelRegistration,
    this.onCottageRegistration,
    this.onHealthTourismRegistration,
    this.onLeaderRegistration,
    this.onAgencyRegistration,
    this.refreshToken = 0,
    this.width,
    this.height,
  });

  /// اندازه دلخواه آیکون هدر؛ اگر null باشد ۴۴×۴۴ (پیش‌فرض قبلی).
  final double? width;
  final double? height;

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

  /// ثبت‌نام لیدرها (پیش‌فرض: صفحه معرفی ثبت‌نام لیدر).
  final VoidCallback? onLeaderRegistration;

  /// ثبت‌نام آژانس مسافرتی (پیش‌فرض: صفحه معرفی ثبت‌نام آژانس).
  final VoidCallback? onAgencyRegistration;

  /// هر بار که این مقدار عوض شود، بج قرمز آیکون هدر دوباره
  /// تعداد آگهی‌های خوانده‌نشده را از سرور می‌خواند (مثلاً بعد از
  /// بازگشت کاربر از صفحه‌ی آگهی‌ها/حساب کاربری).
  final Object refreshToken;

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
      'it',
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
        tooltip: _tr('شناسه کاربری', 'User ID', 'معرّف المستخدم', 'Kullanıcı Kimliği', 'ID пользователя', 'Identifiant', 'Benutzer-ID', 'ID de usuario', '用户ID', 'ID utente'),
        onSelected: (value) {
          switch (value) {
            case 'account':
              _openAccountOrProfile(context);
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
                    builder: (_) => const ResidenceRegisterPage(
                      type: ResidenceRegisterType.accommodation,
                    ),
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
                    builder: (_) => const ResidenceRegisterPage(
                      type: ResidenceRegisterType.hotel,
                    ),
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
                    builder: (_) => const ResidenceRegisterPage(
                      type: ResidenceRegisterType.cottage,
                    ),
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
                    builder: (_) => const ResidenceRegisterPage(
                      type: ResidenceRegisterType.health,
                    ),
                  ),
                );
              }
              break;

            case 'leader':
              if (onLeaderRegistration != null) {
                onLeaderRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LeaderRegistrationIntroPage(),
                  ),
                );
              }
              break;

            case 'agency':
              if (onAgencyRegistration != null) {
                onAgencyRegistration!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgencyRegistrationIntroPage(),
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
            child: _AccountMenuHeader(
              fallbackTitle: username != null && username!.trim().isNotEmpty
                  ? username!.trim()
                  : _tr(
                      'افزودن عکس و نام',
                      'Add photo and name',
                      'إضافة صورة واسم',
                      'Fotoğraf ve ad ekle',
                      'Добавить фото и имя',
                      'Ajouter photo et nom',
                      'Foto und Namen hinzufügen',
                      'Añadir foto y nombre',
                      '添加头像和名称',
                      'Aggiungi foto e nome',
                    ),
              fallbackSubtitle: _tr(
                'شناسه کاربری', 'User ID', 'معرّف المستخدم', 'Kullanıcı Kimliği', 'ID пользователя', 'Identifiant', 'Benutzer-ID', 'ID de usuario', '用户ID', 'ID utente',
              ),
            ),
          ),

          if (showRegistrationMenu) ...[
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
                'Registrazione alloggio',
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
                'Registrazione hotel',
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
                'Registrazione cottage',
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
                'Registrazione turismo sanitario',
              ),
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'leader',
            child: _HeaderAccountMenuItem(
              icon: Icons.groups_2_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام لیدرها',
                'Leader Registration',
                'تسجيل قادة الرحلات',
                'Lider Kaydı',
                'Регистрация лидеров',
                'Inscription des guides',
                'Leiter registrieren',
                'Registro de líderes',
                '领队登记',
                'Registrazione leader',
              ),
            ),
          ),

          PopupMenuItem<String>(
            value: 'agency',
            child: _HeaderAccountMenuItem(
              icon: Icons.business_center_rounded,
              iconColor: const Color(0xffd6ad4f),
              title: _tr(
                'ثبت‌نام آژانس مسافرتی',
                'Travel Agency Registration',
                'تسجيل وكالة السفر',
                'Seyahat Acentesi Kaydı',
                'Регистрация турагентства',
                'Inscription agence de voyage',
                'Reisebüro registrieren',
                'Registro de agencia de viajes',
                '旅行社登记',
                'Registrazione agenzia di viaggio',
              ),
            ),
          ),
          ],
        ],
        child: _HeaderAccountButton(
          key: ValueKey(refreshToken),
          width: width,
          height: height,
        ),
      ),
    );
  }

  /// اگر کاربر هنوز نام یا نام کاربری ندارد، مستقیم به صفحهٔ «پروفایل من» می‌رود؛
  /// در غیر این صورت مثل قبل صفحهٔ حساب کاربری باز می‌شود.
  Future<void> _openAccountOrProfile(BuildContext context) async {
    final navigator = Navigator.of(context);
    final p = await UserProfileService.load();
    final noProfile = p.displayName.isEmpty && p.username.isEmpty;
    if (noProfile) {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const MyProfilePage()),
      );
    } else {
      onAccountPressed?.call();
    }
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
    String it,
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
      case 'it':
        return it;
      case 'fa':
      default:
        return fa;
    }
  }
}

/// ظاهر اصلی دکمه آدمک در هدر، به‌همراه نقطه‌ی قرمز کوچک
/// برای نشان‌دادن وجود آگهی خوانده‌نشده.
class _HeaderAccountButton extends StatefulWidget {
  const _HeaderAccountButton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<_HeaderAccountButton> createState() => _HeaderAccountButtonState();
}

class _HeaderAccountButtonState extends State<_HeaderAccountButton> {
  late Future<int> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = NotificationService.instance.getUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.width ?? 44,
          height: widget.height ?? 44,
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
          child: Icon(
            Icons.person_rounded,
            color: const Color(0xffe5bd55),
            size: widget.height != null ? widget.height! * 0.62 : 25,
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: FutureBuilder<int>(
            future: _unreadFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              if (count <= 0) {
                return const SizedBox.shrink();
              }

              return Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xffe0353d),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xff081722),
                    width: 1.6,
                  ),
                ),
              );
            },
          ),
        ),
      ],
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


/// سرِ منوی حساب کاربری: عکس پروفایل + نام + نام کاربری (از پروفایل ذخیره‌شده روی گوشی).
class _AccountMenuHeader extends StatelessWidget {
  const _AccountMenuHeader({
    required this.fallbackTitle,
    required this.fallbackSubtitle,
  });

  final String fallbackTitle;
  final String fallbackSubtitle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      initialData: UserProfileService.cached,
      future: UserProfileService.load(),
      builder: (context, snap) {
        final p = snap.data;
        final photo = p?.photoBytes;
        final hasName = p != null && p.displayName.isNotEmpty;
        final hasUser = p != null && p.username.isNotEmpty;
        final title = hasName
            ? p.displayName
            : (hasUser ? '@${p.username}' : fallbackTitle);
        final subtitle = (hasName && hasUser) ? '@${p.username}' : fallbackSubtitle;

        return Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff132b3a),
                border: Border.all(color: const Color(0xffe5bd55), width: 1.6),
              ),
              child: ClipOval(
                child: photo != null
                    ? Image.memory(
                        photo,
                        fit: BoxFit.cover,
                        width: 46,
                        height: 46,
                        gaplessPlayback: true,
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Color(0xffe5bd55),
                        size: 25,
                      ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xffaebbc2),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
