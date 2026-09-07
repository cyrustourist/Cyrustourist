import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/app_language.dart';
import '../main.dart' show SmartMapPage;
import 'residence_register_page.dart';

// ===================== رنگ‌ها و برند =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _cardAlt = Color(0xff0a1c28);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);
const Color _tealBright = Color(0xff6df5cf);

const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];

Color _goldA(double a) => _gold.withValues(alpha: a);

String get _lang {
  switch (LanguageManager.current) {
    case AppLanguage.persian:
      return 'fa';
    case AppLanguage.english:
      return 'en';
    case AppLanguage.arabic:
      return 'ar';
    default:
      return 'en';
  }
}

bool get _isRtl => _lang == 'fa' || _lang == 'ar';

/// متن سه‌زبانه‌ی ساده — با t(fa, en, ar) بر اساس زبان فعلی اپ برمی‌گرداند
String t(String fa, String en, String ar) {
  switch (_lang) {
    case 'en':
      return en;
    case 'ar':
      return ar;
    default:
      return fa;
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('امکان باز کردن لینک وجود ندارد.',
            'Unable to open this link.', 'تعذر فتح هذا الرابط.'))),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('خطا در باز کردن لینک.',
            'Error opening the link.', 'خطأ في فتح الرابط.'))),
      );
    }
  }
}

// ============================================================
// مدل داده‌ی اقامتگاه — با کد یکتا و پشتیبانی چندزبانه
// ============================================================
//
// هر «جایگاه» (slot) یک کد یکتا دارد. تا وقتی اقامتگاهی به آن
// اختصاص نیافته (assigned=false)، فقط کد نمایش داده می‌شود و با
// تپ روی آن، دعوت به «عضویت یک‌ساله» (ثبت‌نام اقامتگاه) نشان داده
// می‌شود. وقتی مشخصات کامل یک اقامتگاه برای یک کد مشخص داده شود،
// همان ردیف در kResidenceSlots با assigned:true و داده‌های واقعی
// جایگزین می‌شود.
//
// بازه‌ی فعلی کدها: ۱ تا ۲۰ (دسته‌ی راه‌اندازی اولیه). ساختار کد
// برای گسترش تا کدهای بالاتر (مثلاً کدهای ویژه/رند بالای ۱۰۰۰)
// در آینده محدودیتی ندارد — کافی است ردیف جدید با کد دلخواه به
// kResidenceSlots اضافه شود.

class ResidenceVideoData {
  const ResidenceVideoData({
    required this.code,
    this.assigned = false,
    this.name,
    this.nameEn,
    this.nameAr,
    this.city,
    this.cityEn,
    this.cityAr,
    this.province,
    this.provinceEn,
    this.provinceAr,
    this.description,
    this.descriptionEn,
    this.descriptionAr,
    this.aparatHash,
    this.mobilePhone,
    this.landlinePhone,
    this.supportPhone,
    this.instagramUrl,
    this.websiteUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
  });

  /// کد یکتای جایگاه (۱ تا ۲۰ فعلاً)
  final int code;

  /// آیا این جایگاه به یک اقامتگاه واقعی اختصاص یافته است
  final bool assigned;

  final String? name;
  final String? nameEn;
  final String? nameAr;

  final String? city;
  final String? cityEn;
  final String? cityAr;

  final String? province;
  final String? provinceEn;
  final String? provinceAr;

  final String? description;
  final String? descriptionEn;
  final String? descriptionAr;

  /// هش ویدیوی آپارات (همان بخش بعد از videohash/ در لینک امبد)
  final String? aparatHash;

  final String? mobilePhone;
  final String? landlinePhone;
  final String? supportPhone;

  final String? instagramUrl;
  final String? websiteUrl;

  final double? latitude;
  final double? longitude;

  final double? rating;
  final int? ratingCount;

  bool get hasAnyPhone =>
      mobilePhone != null || landlinePhone != null || supportPhone != null;

  String get displayName {
    final localized = t(name ?? '', nameEn ?? name ?? '', nameAr ?? name ?? '');
    return localized.isNotEmpty
        ? localized
        : t('اقامتگاه شماره $code', 'Residence #$code', 'إقامة رقم $code');
  }

  String get displayCity =>
      t(city ?? '', cityEn ?? city ?? '', cityAr ?? city ?? '');

  String? get displayProvince => province == null
      ? null
      : t(province!, provinceEn ?? province!, provinceAr ?? province!);

  String get displayDescription => t(
        description ?? '',
        descriptionEn ?? description ?? '',
        descriptionAr ?? description ?? '',
      );
}

// ============================================================
// نمونه‌ی ۲۰ جایگاه — کد ۱ نمونه‌ی کامل، کدهای ۲ تا ۲۰ خالی
// ============================================================
//
// وقتی مشخصات کامل یک اقامتگاه برای یک کد داده شود، کافی است
// ردیف همان کد در این لیست با assigned:true و داده‌های واقعی
// جایگزین شود.

const List<ResidenceVideoData> kResidenceSlots = [
  ResidenceVideoData(
    code: 1,
    assigned: true,
    name: 'اقامتگاه نمونه سایروس توریست',
    nameEn: 'Cyrus Tourist Sample Residence',
    nameAr: 'إقامة سايروس توريست النموذجية',
    city: 'مشهد',
    cityEn: 'Mashhad',
    cityAr: 'مشهد',
    province: 'خراسان رضوی',
    provinceEn: 'Razavi Khorasan',
    provinceAr: 'خراسان الرضوية',
    description:
        'این یک نمونه از صفحه‌ی معرفی و نمایش فیلم اقامتگاه است. پس از ثبت‌نام اقامتگاه شما در سایروس توریست، همین قالب با فیلم، توضیحات، آدرس، آب‌وهوا و راه‌های تماس واقعی اقامتگاه شما پر می‌شود.',
    descriptionEn:
        'This is a sample of the residence introduction and video page. Once you register your residence with Cyrus Tourist, this same template is filled with your real video, description, address, weather and contact details.',
    descriptionAr:
        'هذا نموذج لصفحة تعريف وعرض فيديو الإقامة. بعد تسجيل إقامتك في سايروس توريست، يتم ملء هذا النموذج نفسه بالفيديو والوصف والعنوان والطقس ووسائل التواصل الحقيقية الخاصة بك.',
    aparatHash: 'w43c127',
    mobilePhone: '09153448818',
    landlinePhone: '09153448818',
    supportPhone: '09153448818',
    instagramUrl:
        'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
    websiteUrl: 'https://cyrustourist-maker.github.io/Cyrustourist/',
    latitude: 36.2970,
    longitude: 59.6062,
    rating: 4.7,
    ratingCount: 128,
  ),
  ResidenceVideoData(code: 2),
  ResidenceVideoData(code: 3),
  ResidenceVideoData(code: 4),
  ResidenceVideoData(code: 5),
  ResidenceVideoData(code: 6),
  ResidenceVideoData(code: 7),
  ResidenceVideoData(code: 8),
  ResidenceVideoData(code: 9),
  ResidenceVideoData(code: 10),
  ResidenceVideoData(code: 11),
  ResidenceVideoData(code: 12),
  ResidenceVideoData(code: 13),
  ResidenceVideoData(code: 14),
  ResidenceVideoData(code: 15),
  ResidenceVideoData(code: 16),
  ResidenceVideoData(code: 17),
  ResidenceVideoData(code: 18),
  ResidenceVideoData(code: 19),
  ResidenceVideoData(code: 20),
];

// ============================================================
// صفحه‌ی گالری ۲۰ جایگاه
// ============================================================

class ResidenceSlotGalleryPage extends StatelessWidget {
  const ResidenceSlotGalleryPage({super.key, this.slots = kResidenceSlots});

  final List<ResidenceVideoData> slots;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            t('فیلم‌های اقامتگاه‌ها', 'Residence Videos', 'فيديوهات الإقامة'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 168,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _SlotCard(data: slots[index]),
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.data});

  final ResidenceVideoData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        if (data.assigned) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResidenceVideoPage(data: data)),
          );
        } else {
          _showAvailableSheet(context, data.code);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: data.assigned
              ? const LinearGradient(
                  colors: [_cardAlt, _card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: data.assigned ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: data.assigned ? _goldA(0.28) : _goldA(0.18),
            style: data.assigned ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: data.assigned ? _assignedContent() : _emptyContent(),
      ),
    );
  }

  Widget _codeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _brandGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#${data.code}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _assignedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _codeBadge(),
            const Icon(Icons.play_circle_fill_rounded,
                color: _gold, size: 20),
          ],
        ),
        const Spacer(),
        Text(
          data.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _goldBright, size: 12),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                data.displayCity,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _goldBright, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _codeBadge(),
        const Spacer(),
        const Icon(Icons.add_circle_outline_rounded,
            color: Colors.white38, size: 26),
        const SizedBox(height: 6),
        Text(
          t('جای خالی', 'Available slot', 'مكان متاح'),
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          t('عضویت یک‌ساله', '1-year membership', 'عضوية لمدة سنة'),
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
      ],
    );
  }
}

void _showAvailableSheet(BuildContext context, int code) {
  showModalBottomSheet(
    context: context,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _brandGradient),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('جایگاه #$code — هنوز خالی است',
                        'Slot #$code — still available',
                        'المكان رقم $code — لا يزال متاحاً'),
                    style: const TextStyle(
                      color: _goldBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t(
                'این جایگاه هنوز به هیچ اقامتگاهی اختصاص نیافته است. با ثبت‌نام و عضویت یک‌ساله، اقامتگاه شما همین‌جا با فیلم، توضیحات، آب‌وهوا و راه ارتباطی مستقیم به گردشگران معرفی می‌شود.',
                'This slot has not been assigned to any residence yet. With a one-year membership, your residence will be introduced right here with video, description, weather and a direct way for tourists to reach you.',
                'لم يتم تخصيص هذا المكان بعد لأي إقامة. مع عضوية لمدة سنة، سيتم عرض إقامتك هنا بالفيديو والوصف والطقس ووسيلة تواصل مباشرة مع السياح.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.9,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ResidenceRegisterPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_teal, _tealBright]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.how_to_reg_rounded,
                            color: Color(0xff03202a)),
                        const SizedBox(width: 8),
                        Text(
                          t('ثبت‌نام اقامتگاه (عضویت یک‌ساله)',
                              'Register Residence (1-year membership)',
                              'تسجيل الإقامة (عضوية لمدة سنة)'),
                          style: const TextStyle(
                            color: Color(0xff03202a),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// صفحه‌ی نمایش فیلم اقامتگاه (یک جایگاه اختصاص‌یافته)
// ============================================================

class ResidenceVideoPage extends StatefulWidget {
  const ResidenceVideoPage({super.key, required this.data});

  final ResidenceVideoData data;

  @override
  State<ResidenceVideoPage> createState() => _ResidenceVideoPageState();
}

class _ResidenceVideoPageState extends State<ResidenceVideoPage> {
  ResidenceVideoData get _d => widget.data;

  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _AparatEmbedPlayer(aparatHash: _d.aparatHash ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleBlock(),
                    const SizedBox(height: 16),
                    if (_d.displayDescription.trim().isNotEmpty) ...[
                      _descriptionBlock(),
                      const SizedBox(height: 22),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: _gradientButton(
                        icon: Icons.map_rounded,
                        label: t('مسیریابی سریع', 'Fast route', 'المسار السريع'),
                        colors: const [_teal, _tealBright],
                        textColor: const Color(0xff03202a),
                        onTap: _openRoute,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResidenceWeatherButton(
                      city: _d.displayCity,
                      province: _d.displayProvince,
                    ),
                    const SizedBox(height: 12),
                    if (_d.hasAnyPhone) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _outlinedIconButton(
                          icon: Icons.call_rounded,
                          label: t('تماس مستقیم', 'Direct contact', 'اتصال مباشر'),
                          onTap: _openContactSheet,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_d.instagramUrl != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _linkRow(
                          icon: Icons.camera_alt_rounded,
                          label: t('اینستاگرام', 'Instagram', 'إنستغرام'),
                          onTap: () => _openUrl(context, _d.instagramUrl!),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_d.websiteUrl != null)
                      SizedBox(
                        width: double.infinity,
                        child: _linkRow(
                          icon: Icons.public_rounded,
                          label: t('وب‌سایت', 'Website', 'الموقع الإلكتروني'),
                          onTap: () => _openUrl(context, _d.websiteUrl!),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _d.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _goldBright, size: 15),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _d.displayProvince != null
                          ? '${_d.displayCity}، ${_d.displayProvince}'
                          : _d.displayCity,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _goldBright,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_d.rating != null) _ratingBadge(),
      ],
    );
  }

  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldA(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _gold, size: 16),
              const SizedBox(width: 3),
              Text(
                _d.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (_d.ratingCount != null) ...[
            const SizedBox(height: 2),
            Text(
              t('${_d.ratingCount} رأی', '${_d.ratingCount} votes',
                  '${_d.ratingCount} صوت'),
              style: const TextStyle(color: Colors.white38, fontSize: 9.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _descriptionBlock() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _d.displayDescription,
            maxLines: _descriptionExpanded ? null : 3,
            overflow: _descriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _descriptionExpanded = !_descriptionExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _descriptionExpanded
                        ? Icons.undo_rounded
                        : Icons.expand_more_rounded,
                    color: _gold,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _descriptionExpanded
                        ? t('بازگشت', 'Back', 'رجوع')
                        : t('بیشتر', 'More', 'المزيد'),
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRoute() {
    if (_d.latitude != null && _d.longitude != null) {
      HapticFeedback.selectionClick();
      final url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${_d.latitude},${_d.longitude}';
      _openUrl(context, url);
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmartMapPage()),
    );
  }

  void _openContactSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                t('📞 تماس مستقیم — یک شماره را انتخاب کنید',
                    '📞 Direct contact — choose a number',
                    '📞 اتصال مباشر — اختر رقماً'),
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              if (_d.mobilePhone != null)
                _contactOption(
                  icon: Icons.smartphone_rounded,
                  label: t('تلفن همراه', 'Mobile', 'الجوال'),
                  phone: _d.mobilePhone!,
                ),
              if (_d.landlinePhone != null)
                _contactOption(
                  icon: Icons.phone_rounded,
                  label: t('تلفن ثابت', 'Landline', 'الهاتف الأرضي'),
                  phone: _d.landlinePhone!,
                ),
              if (_d.supportPhone != null)
                _contactOption(
                  icon: Icons.support_agent_rounded,
                  label: t('تلفن پشتیبان', 'Support line', 'خط الدعم'),
                  phone: _d.supportPhone!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactOption({
    required IconData icon,
    required String label,
    required String phone,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        // فقط برنامه‌ی تلفن گوشی را با شماره باز می‌کند — تماس
        // خودکار برقرار نمی‌شود (بدون نیاز به مجوز CALL_PHONE)،
        // دقیقاً مطابق بخش پشتیبانی (کلید ۹).
        _openUrl(context, 'tel:$phone');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff103b50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _brandGradient),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5)),
                  Text(phone,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: _goldA(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 19),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
            const Spacer(),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// دکمه/آیکون هواشناسی — بر اساس نام شهر اقامتگاه (نه GPS کاربر)
// ============================================================

class _ResidenceWeatherButton extends StatefulWidget {
  const _ResidenceWeatherButton({required this.city, this.province});

  final String city;
  final String? province;

  @override
  State<_ResidenceWeatherButton> createState() =>
      _ResidenceWeatherButtonState();
}

class _ResidenceWeatherButtonState extends State<_ResidenceWeatherButton> {
  bool _expanded = false;
  bool _loading = false;
  bool _failed = false;
  bool _loaded = false;

  double? _temperature;
  int? _weatherCode;
  int? _humidity;
  double? _windSpeed;

  void _toggle() {
    HapticFeedback.selectionClick();

    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _expanded = true);

    if (!_loaded) _loadWeather();
  }

  void _retry() {
    setState(() {
      _loaded = false;
      _failed = false;
    });
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final coords = await _geocodeCity();

      if (coords == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
          _loaded = true;
        });
        return;
      }

      final weather = await _fetchWeather(coords[0], coords[1]);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loaded = true;
        _failed = weather == null;
        _temperature = (weather?['temperature'] as num?)?.toDouble();
        _weatherCode = (weather?['weathercode'] as num?)?.toInt();
        _humidity = (weather?['humidity'] as num?)?.toInt();
        _windSpeed = (weather?['windspeed'] as num?)?.toDouble();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _loaded = true;
      });
    }
  }

  Future<List<double>?> _geocodeCity() async {
    final query = widget.province != null
        ? '${widget.city}, ${widget.province}'
        : widget.city;

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'accept-language': _lang,
    });

    final client = HttpClient();
    try {
      client.userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = jsonDecode(body);

      if (data is! List || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lon == null) return null;

      return [lat, lon];
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _fetchWeather(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;

      if (current == null) return null;

      return {
        'temperature': current['temperature_2m'],
        'weathercode': current['weather_code'],
        'humidity': current['relative_humidity_2m'],
        'windspeed': current['wind_speed_10m'],
      };
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _weatherEmoji(int? code) {
    if (code == null) return '🌡️';
    if (code == 0) return '☀️';
    if (code == 1 || code == 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 57) return '🌦️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '🌨️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code == 85 || code == 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }

  String _weatherLabel(int? code) {
    if (code == null) return t('نامشخص', 'Unknown', 'غير معروف');
    if (code == 0) return t('صاف', 'Clear', 'صافٍ');
    if (code == 1) return t('کمی ابری', 'Mostly clear', 'صافٍ جزئياً');
    if (code == 2) return t('نیمه‌ابری', 'Partly cloudy', 'غائم جزئياً');
    if (code == 3) return t('ابری', 'Cloudy', 'غائم');
    if (code == 45 || code == 48) return t('مه‌آلود', 'Foggy', 'ضبابي');
    if (code >= 51 && code <= 57) {
      return t('نم‌نم باران', 'Drizzle', 'رذاذ');
    }
    if (code >= 61 && code <= 67) {
      return t('بارانی', 'Rainy', 'ممطر');
    }
    if (code >= 71 && code <= 77) {
      return t('برفی', 'Snowy', 'مثلج');
    }
    if (code >= 80 && code <= 82) {
      return t('رگبار', 'Showers', 'زخات');
    }
    if (code == 85 || code == 86) {
      return t('رگبار برف', 'Snow showers', 'زخات ثلجية');
    }
    if (code >= 95) return t('رعدوبرق', 'Thunderstorm', 'عاصفة رعدية');
    return t('نامشخص', 'Unknown', 'غير معروف');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff103b50), Color(0xff0d2432)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldA(0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _goldBright, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('آب‌وهوای ${widget.city}', 'Weather in ${widget.city}',
                          'طقس ${widget.city}'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (_loaded && !_failed && _temperature != null) ...[
                    Text(_weatherEmoji(_weatherCode),
                        style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 4),
                    Text(
                      '${_temperature!.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _gold),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _weatherBody(),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _weatherBody() {
    if (_loading) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _gold),
          ),
          const SizedBox(width: 10),
          Text(
            t('در حال دریافت آب‌وهوا…', 'Fetching weather…',
                'جارٍ جلب حالة الطقس…'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    if (_failed) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t('دریافت آب‌وهوا ممکن نشد.', 'Could not fetch weather.',
                  'تعذر جلب حالة الطقس.'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _retry,
            child: Text(t('تلاش دوباره', 'Retry', 'إعادة المحاولة'),
                style: const TextStyle(color: _gold)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _weatherLabel(_weatherCode),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        if (_humidity != null)
          Text('💧 $_humidity٪',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        if (_windSpeed != null) ...[
          const SizedBox(width: 10),
          Text('🌬️ ${_windSpeed!.round()} km/h',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        ],
      ],
    );
  }
}

// ============================================================
// پخش‌کننده‌ی عمومی آپارات
// ============================================================

class _AparatEmbedPlayer extends StatefulWidget {
  const _AparatEmbedPlayer({required this.aparatHash});

  final String aparatHash;

  @override
  State<_AparatEmbedPlayer> createState() => _AparatEmbedPlayerState();
}

class _AparatEmbedPlayerState extends State<_AparatEmbedPlayer> {
  late WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant _AparatEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aparatHash != widget.aparatHash) {
      _createController();
    }
  }

  void _createController() {
    if (widget.aparatHash.isEmpty) {
      _failed = true;
      _loading = false;
      return;
    }

    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.aparatHash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('aparat.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_failed || widget.aparatHash.isNotEmpty)
          WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: _gold),
          ),
        if (_failed)
          Container(
            color: _bg,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _gold, size: 30),
                const SizedBox(height: 8),
                Text(
                  t('پخش ویدیو بارگذاری نشد', 'Video failed to load',
                      'تعذر تحميل الفيديو'),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (widget.aparatHash.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _failed = false;
                        _loading = true;
                      });
                      _controller.reload();
                    },
                    child: Text(t('تلاش دوباره', 'Retry', 'إعادة المحاولة')),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
