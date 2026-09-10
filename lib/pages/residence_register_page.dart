import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/location_service.dart';
import '../main.dart' show SmartMapPage;

// ===================== رنگ‌ها و برند =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _cardAlt = Color(0xff0a1c28);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);
const Color _tealBright = Color(0xff6df5cf);

// گرادیان برند سایروس توریست — هماهنگ با هدر سایت (ct-registration-header)
const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];

const List<Color> _callGradient = [Color(0xff00b09b), Color(0xff96c93d)];
const List<Color> _telegramGradient = [Color(0xff229ed9), Color(0xff2aabee)];
const List<Color> _whatsappGradient = [Color(0xff25d366), Color(0xff128c7e)];
const List<Color> _eitaaGradient = [Color(0xff0e8f7e), Color(0xfff5a623)];

Color _goldA(double a) => _gold.withValues(alpha: a);

/// اطلاعات پشتیبانی — همان مقادیر استفاده‌شده در residences-registration.js سایت
class _SupportInfo {
  static const String phone = '09153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
  static const String telegramLabel = '@Cyrustourist';
  static const String whatsapp = 'https://wa.me/989153448818';
  static const String eitaa = 'https://eitaa.com/cyrustourist';
  static const String instagramUrl =
      'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
  static const String websiteUrl =
      'https://cyrustourist-maker.github.io/Cyrustourist/';
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در باز کردن لینک.')),
      );
    }
  }
}

class ResidenceRegisterPage extends StatefulWidget {
  const ResidenceRegisterPage({super.key});

  @override
  State<ResidenceRegisterPage> createState() =>
      _ResidenceRegisterPageState();
}

class _ResidenceRegisterPageState extends State<ResidenceRegisterPage> {
  bool _rulesAccepted = false;
  bool _showSupportStep = false;

  final List<Map<String, String>> _benefits = const [
    {'icon': '🎬', 'text': 'نمایش فیلم اقامتگاه در سایت و نرم‌افزار'},
    {'icon': '🎥', 'text': 'امکان تولید فیلم توسط سایروس توریست'},
    {'icon': '🗺️', 'text': 'مسیریابی مستقیم برای گردشگران'},
    {'icon': '📞', 'text': 'تماس مستقیم گردشگر با اقامتگاه'},
    {'icon': '📸', 'text': 'معرفی صفحه اینستاگرام اقامتگاه'},
    {'icon': '🌐', 'text': 'معرفی وب‌سایت اقامتگاه'},
    {'icon': '⭐', 'text': 'دریافت امتیاز و بازخورد گردشگران'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _showSupportStep
              ? _buildSupportStep(key: const ValueKey('support'))
              : _buildMainStep(key: const ValueKey('main')),
        ),
      ),
      bottomNavigationBar: _showSupportStep ? null : _stickyContinueBar(),
    );
  }

  // ===================== هدر گرادیانی برند =====================

  Widget _heroHeader({required bool onSupportStep}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text('🏡', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      onSupportStep
                          ? 'هماهنگی با پشتیبانی'
                          : 'ثبت اقامتگاه در سایروس توریست',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                onSupportStep
                    ? 'یک قدم تا معرفی اقامتگاه شما باقی مانده — با ما در ارتباط باشید.'
                    : 'اقامتگاه خود را به گردشگران سایروس توریست معرفی کنید.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.8,
                ),
              ),
              if (!onSupportStep) ...[
                const SizedBox(height: 14),
                _trustBadgesRow(),
              ],
              const SizedBox(height: 22),
              _stepProgress(onSupportStep: onSupportStep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBadgesRow() {
    const badges = [
      ['✅', 'رایگان'],
      ['🤝', 'بدون واسطه'],
      ['⚡', 'فعال‌سازی سریع'],
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map(
            (b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b[0], style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    b[1],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _stepProgress({required bool onSupportStep}) {
    return Row(
      children: [
        _stepDot(number: '1', label: 'معرفی و مزایا', active: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white.withValues(alpha: onSupportStep ? 0.9 : 0.35),
          ),
        ),
        _stepDot(number: '2', label: 'پشتیبانی', active: onSupportStep),
      ],
    );
  }

  Widget _stepDot({
    required String number,
    required String label,
    required bool active,
  }) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.22),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? const Color(0xff11998e) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1 : 0.75),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===================== STEP 1: MAIN =====================

  Widget _buildMainStep({Key? key}) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        _heroHeader(onSupportStep: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('🌟', 'مزایای ثبت اقامتگاه'),
              const SizedBox(height: 12),
              _FadeInUp(
                delay: const Duration(milliseconds: 60),
                child: _benefitsGrid(),
              ),
              const SizedBox(height: 22),
              _sectionTitle('🌤️', 'آب‌وهوای مقصد'),
              const SizedBox(height: 12),
              _FadeInUp(
                delay: const Duration(milliseconds: 140),
                child: const _CityWeatherCard(),
              ),
              const SizedBox(height: 6),
              const Text(
                'نمونه — بر اساس موقعیت فعلی شما. پس از ثبت‌نام، آب‌وهوای شهر اقامتگاه شما اینجا نمایش داده می‌شود تا گردشگر پیش از سفر تصمیم بهتری بگیرد.',
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.8),
              ),
              const SizedBox(height: 22),
              _sectionTitle('🎬', 'نمونه کارت اقامتگاه شما'),
              const SizedBox(height: 12),
              _FadeInUp(
                delay: const Duration(milliseconds: 220),
                child: _sampleCard(),
              ),
              const SizedBox(height: 22),
              _sectionTitle('📋', 'قوانین و شرایط خدمات'),
              const SizedBox(height: 12),
              _FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _rulesCard(),
              ),
              const SizedBox(height: 14),
              _FadeInUp(
                delay: const Duration(milliseconds: 380),
                child: _acceptCheckCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _goldBright,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // ---------- نوار پایین ثابت (Sticky CTA) ----------

  Widget _stickyContinueBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _goldA(0.14))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: _gradientButton(
        icon: _rulesAccepted ? Icons.check_circle_rounded : Icons.lock_rounded,
        label: _rulesAccepted
            ? 'ادامه و ارتباط با پشتیبانی'
            : 'برای ادامه، قوانین را بپذیرید',
        colors: _rulesAccepted
            ? const [_teal, _tealBright]
            : const [Color(0xff1c2b34), Color(0xff1c2b34)],
        textColor: _rulesAccepted ? const Color(0xff03202a) : Colors.white38,
        onTap: _rulesAccepted
            ? () => setState(() => _showSupportStep = true)
            : null,
      ),
    );
  }

  // ---------- کارت‌های مزایا ----------

  Widget _benefitsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _benefits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 128,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final b = _benefits[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_cardAlt, _card],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _goldA(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: _brandGradient),
                ),
                child: Text(b['icon']!, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  b['text']!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- کارت نمونه اقامتگاه ----------

  Widget _sampleCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _goldA(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: const _DemoAparatPlayer(aparatVideoId: 'w43c127'),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _brandGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'نمونه',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'این یک نمونه از کارت اقامتگاه شماست. برای فیلم اقامتگاه دو روش دارید:\n'
                  '۱. ارسال لینک فیلم شبکه‌های اجتماعی‌تان به پشتیبانی سایروس توریست\n'
                  '۲. سفارش تولید محتوای حرفه‌ای توسط تیم سایروس توریست (حضوری یا دورکاری)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _outlinedIconButton(
                        icon: Icons.map_rounded,
                        label: 'مسیریابی',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SmartMapPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlinedIconButton(
                        icon: Icons.my_location_rounded,
                        label: 'مکان من',
                        onTap: _handleMyLocation,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _gradientButton(
                    icon: Icons.event_available_rounded,
                    label: '📅 رزرو',
                    colors: const [_teal, _tealBright],
                    textColor: const Color(0xff03202a),
                    onTap: _openReserveSheet,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleLinkButton(
                      icon: Icons.camera_alt_rounded,
                      onTap: () => _openUrl(context, _SupportInfo.instagramUrl),
                    ),
                    const SizedBox(width: 14),
                    _circleLinkButton(
                      icon: Icons.public_rounded,
                      onTap: () => _openUrl(context, _SupportInfo.websiteUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'نمونه‌ی اینستاگرام و وب‌سایت — برای آزمایش، لینک‌های سایروس توریست نمایش داده شده است.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- قوانین ----------

  Widget _rulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2a2210),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffffb020).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xffffb020), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'شرایط و خدمات ثبت اقامتگاه در سایروس توریست بر پایه زیرساخت اینترنت کشور و صرفاً به‌صورت تبلیغات مجازی ارائه می‌شود. '
              'سایروس توریست در صورت بروز هرگونه اختلال، قطعی یا محدودیت در زیرساخت اینترنت، هیچ‌گونه مسئولیتی در قبال آن نخواهد داشت.\n\n'
              'هزینه خدمات ثبت اقامتگاه به‌صورت سالانه محاسبه و دریافت می‌شود.',
              style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acceptCheckCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rulesAccepted = !_rulesAccepted);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _rulesAccepted ? _teal.withValues(alpha: 0.12) : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _rulesAccepted ? _teal.withValues(alpha: 0.65) : _goldA(0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rulesAccepted ? _teal : Colors.transparent,
                border: Border.all(
                  color: _rulesAccepted ? _teal : Colors.white38,
                  width: 1.6,
                ),
              ),
              child: _rulesAccepted
                  ? const Icon(Icons.check_rounded, color: Color(0xff03202a), size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'قوانین و شرایط خدمات سایروس توریست را مطالعه کرده‌ام و می‌پذیرم.',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMyLocation() async {
    final position = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (position == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('⚠️ موقعیت‌مکانی خاموش است',
              style: TextStyle(color: _goldBright)),
          content: const Text(
            'برای نمایش مکان اقامتگاه، لطفاً GPS گوشی خود را روشن و دسترسی موقعیت‌مکانی را فعال کنید.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('بستن'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                LocationService.openLocationSettings();
              },
              child: const Text('باز کردن تنظیمات'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('📍 موقعیت شما دریافت شد', style: TextStyle(color: _goldBright)),
        content: const Text(
          'در نسخه‌ی نهایی، فاصله و مسیر دقیق شما تا اقامتگاه اینجا نمایش داده می‌شود. این صفحه فقط یک نمونه‌ی آزمایشی است.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  void _openReserveSheet() {
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
              const Text(
                '📅 رزرو اقامتگاه — یک شماره را انتخاب کنید',
                style: TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              _reserveOption(
                icon: Icons.smartphone_rounded,
                label: 'تلفن همراه اقامتگاه',
                onTap: _goToPaymentWarning,
              ),
              _reserveOption(
                icon: Icons.phone_rounded,
                label: 'تلفن ثابت اقامتگاه',
                onTap: _goToPaymentWarning,
              ),
              _reserveOption(
                icon: Icons.support_agent_rounded,
                label: 'پشتیبانی سایروس توریست',
                onTap: _goToPaymentWarning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reserveOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        onTap();
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
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _goToPaymentWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffffb020).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xffffb020), size: 30),
              ),
              const SizedBox(height: 14),
              const Text(
                'هشدار مهم',
                style: TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'تا پیش از تحویل نهایی اقامتگاه و تأیید حضوری، از پرداخت هرگونه وجه، بیعانه یا ودیعه (اینترنتی یا کارت‌به‌کارت) خودداری کنید. '
                'سایروس توریست هیچ مسئولیتی در قبال پرداخت‌های انجام‌شده پیش از تحویل نهایی نمی‌پذیرد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.9),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _gradientButton(
                  icon: Icons.call_rounded,
                  label: 'تماس',
                  colors: const [_teal, _tealBright],
                  textColor: const Color(0xff03202a),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openUrl(context, 'tel:${_SupportInfo.phone}');
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('بازگشت'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldBright,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _goldA(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  // ===================== STEP 2: SUPPORT =====================

  Widget _buildSupportStep({Key? key}) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        _heroHeader(onSupportStep: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _teal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _teal, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '✅ قوانین و شرایط پذیرفته شد. اکنون می‌توانید برای تکمیل ثبت اقامتگاه با پشتیبانی هماهنگ کنید.',
                        style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _contactRow(
                icon: Icons.call_rounded,
                gradient: _callGradient,
                title: 'تماس با پشتیبانی',
                subtitle: _SupportInfo.phone,
                onTap: () => _openUrl(context, 'tel:${_SupportInfo.phone}'),
              ),
              _contactRow(
                icon: Icons.send_rounded,
                gradient: _telegramGradient,
                title: 'پشتیبانی تلگرام',
                subtitle: _SupportInfo.telegramLabel,
                onTap: () => _openUrl(context, _SupportInfo.telegram),
              ),
              _contactRow(
                icon: Icons.chat_rounded,
                gradient: _whatsappGradient,
                title: 'پشتیبانی واتساپ',
                subtitle: _SupportInfo.phone,
                onTap: () => _openUrl(context, _SupportInfo.whatsapp),
              ),
              _contactRow(
                icon: Icons.mark_unread_chat_alt_rounded,
                gradient: _eitaaGradient,
                title: 'پشتیبانی ایتا',
                subtitle: '@cyrustourist',
                onTap: () => _openUrl(context, _SupportInfo.eitaa),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showSupportStep = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('بازگشت'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldBright,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: _goldA(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactRow({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _goldA(0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  // ===================== ویجت‌های مشترک =====================

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
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: _goldA(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _circleLinkButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xff103b50),
          border: Border.all(color: _goldA(0.4)),
        ),
        child: Icon(icon, color: _gold),
      ),
    );
  }
}

// ===================== ورود پلکانی (Fade + Slide) =====================

class _FadeInUp extends StatefulWidget {
  const _FadeInUp({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, .08),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ===================== کارت آب‌وهوای مقصد =====================
//
// از Open-Meteo (بدون نیاز به کلید API) برای دما/وضعیت هوا و از
// Nominatim (همان سرویسی که در main.dart برای جستجوی مکان استفاده
// می‌شود) برای نام شهر استفاده می‌کند. ابتدا آخرین موقعیت شناخته‌شده
// (سریع) نمایش داده می‌شود، سپس در پس‌زمینه با موقعیت دقیق‌تر
// به‌روزرسانی می‌شود.

class _CityWeatherCard extends StatefulWidget {
  const _CityWeatherCard();

  @override
  State<_CityWeatherCard> createState() => _CityWeatherCardState();
}

class _CityWeatherCardState extends State<_CityWeatherCard> {
  bool _loading = true;
  bool _failed = false;
  bool _locationUnavailable = false;

  double? _temperature;
  int? _weatherCode;
  int? _humidity;
  double? _windSpeed;
  String? _cityName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _locationUnavailable = false;
    });

    try {
      var position = await LocationService.getLastKnownLocation();
      position ??= await LocationService.getCurrentLocation();

      if (position == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _locationUnavailable = true;
        });
        return;
      }

      final results = await Future.wait([
        _fetchWeather(position.latitude, position.longitude),
        _fetchCityName(position.latitude, position.longitude),
      ]);

      if (!mounted) return;

      final weather = results[0] as Map<String, dynamic>?;

      setState(() {
        _loading = false;
        _failed = weather == null;
        _temperature = (weather?['temperature'] as num?)?.toDouble();
        _weatherCode = (weather?['weathercode'] as num?)?.toInt();
        _humidity = (weather?['humidity'] as num?)?.toInt();
        _windSpeed = (weather?['windspeed'] as num?)?.toDouble();
        _cityName = results[1] as String?;
      });

      // به‌روزرسانی خاموش با موقعیت دقیق‌تر GPS (بدون نمایش لودینگ مجدد)
      LocationService.getCurrentLocation().then((accurate) async {
        if (accurate == null || !mounted) return;

        final refined =
            await _fetchWeather(accurate.latitude, accurate.longitude);
        final refinedCity =
            await _fetchCityName(accurate.latitude, accurate.longitude);

        if (!mounted || refined == null) return;

        setState(() {
          _failed = false;
          _temperature = (refined['temperature'] as num?)?.toDouble();
          _weatherCode = (refined['weathercode'] as num?)?.toInt();
          _humidity = (refined['humidity'] as num?)?.toInt();
          _windSpeed = (refined['windspeed'] as num?)?.toDouble();
          _cityName = refinedCity ?? _cityName;
        });
      }).catchError((_) {});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchWeather(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
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

  Future<String?> _fetchCityName(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'jsonv2',
      'accept-language': 'fa',
      'zoom': '10',
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
      final data = jsonDecode(body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      final name = address?['city'] ??
          address?['town'] ??
          address?['county'] ??
          address?['state'] ??
          data['name'];

      return name as String?;
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
    if (code == null) return 'نامشخص';
    if (code == 0) return 'صاف';
    if (code == 1) return 'کمی ابری';
    if (code == 2) return 'نیمه‌ابری';
    if (code == 3) return 'ابری';
    if (code == 45 || code == 48) return 'مه‌آلود';
    if (code >= 51 && code <= 57) return 'نم‌نم باران';
    if (code >= 61 && code <= 67) return 'بارانی';
    if (code >= 71 && code <= 77) return 'برفی';
    if (code >= 80 && code <= 82) return 'رگبار';
    if (code == 85 || code == 86) return 'رگبار برف';
    if (code >= 95) return 'رعدوبرق';
    return 'نامشخص';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff103b50), Color(0xff0d2432)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _goldA(0.22)),
      ),
      child: _loading
          ? _weatherLoading()
          : _locationUnavailable
              ? _weatherLocationOff()
              : _failed
                  ? _weatherFailed()
                  : _weatherContent(),
    );
  }

  Widget _weatherLoading() {
    return const Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: _gold),
        ),
        SizedBox(width: 12),
        Text(
          'در حال دریافت آب‌وهوا…',
          style: TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _weatherLocationOff() {
    return Row(
      children: [
        const Icon(Icons.location_off_rounded, color: Colors.white38),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'برای نمایش آب‌وهوا، دسترسی موقعیت‌مکانی را فعال کنید.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.7),
          ),
        ),
        TextButton(
          onPressed: _load,
          child: const Text('تلاش دوباره', style: TextStyle(color: _gold)),
        ),
      ],
    );
  }

  Widget _weatherFailed() {
    return Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.white38),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'دریافت آب‌وهوا ممکن نشد.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        TextButton(
          onPressed: _load,
          child: const Text('تلاش دوباره', style: TextStyle(color: _gold)),
        ),
      ],
    );
  }

  Widget _weatherContent() {
    final temp = _temperature != null ? '${_temperature!.round()}°' : '—';

    return Row(
      children: [
        Text(_weatherEmoji(_weatherCode), style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    temp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _weatherLabel(_weatherCode),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '📍 ${_cityName ?? 'موقعیت شما'}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _goldBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_humidity != null || _windSpeed != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_humidity != null)
                Text('💧 $_humidity٪',
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
              if (_windSpeed != null)
                Text('🌬️ ${_windSpeed!.round()} km/h',
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
            ],
          ),
      ],
    );
  }
}

/// پخش‌کننده‌ی نمونه برای آپارات — نسخه‌ی مستقل از پخش‌کننده‌ی video_page.dart
class _DemoAparatPlayer extends StatefulWidget {
  const _DemoAparatPlayer({required this.aparatVideoId});

  final String aparatVideoId;

  @override
  State<_DemoAparatPlayer> createState() => _DemoAparatPlayerState();
}

class _DemoAparatPlayerState extends State<_DemoAparatPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.aparatVideoId}/vt/frame';

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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
                const Text(
                  'پخش نمونه بارگذاری نشد',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _failed = false;
                      _loading = true;
                    });
                    _controller.reload();
                  },
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
