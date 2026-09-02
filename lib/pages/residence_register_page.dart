import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/location_service.dart';
import 'map/smart_map_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);
const Color _tealBright = Color(0xff6bf0c8);

/// اطلاعات پشتیبانی — همان مقادیر استفاده‌شده در residences-registration.js سایت
class _SupportInfo {
  static const String phone = '09153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
  static const String telegramLabel = '@Cyrustourist';
  static const String whatsapp = 'https://wa.me/989153448818';
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
    {
      'icon': '🎥',
      'text': 'امکان تولید فیلم توسط سایروس توریست به سفارش مالک'
    },
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
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _goldBright),
        title: Text(
          _showSupportStep
              ? '🤝 هماهنگی با پشتیبانی'
              : '🏡 ثبت اقامتگاه در سایروس توریست',
          style: const TextStyle(
            color: _goldBright,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: _showSupportStep
            ? _buildSupportStep()
            : _buildMainStep(),
      ),
    );
  }

  // ===================== STEP 1: MAIN =====================

  Widget _buildMainStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        const Text(
          'اقامتگاه خود (هتل، مهمان‌خانه، بوم‌گردی یا کمپ) را به گردشگران سایروس توریست معرفی کنید.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.9),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: '🌟 مزایای ثبت اقامتگاه',
          child: Column(
            children: _benefits
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['icon']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b['text']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: '🎬 نمونه نمایش فیلم اقامتگاه',
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _DemoAparatPlayer(aparatVideoId: 'w43c127'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'این یک نمونه از نمایش فیلم اقامتگاه شماست. برای افزودن فیلم اقامتگاه خودتان دو روش دارید:\n'
                '۱. ارسال لینک فیلم شبکه‌های اجتماعی‌تان به پشتیبانی سایروس توریست\n'
                '۲. سفارش تولید محتوای حرفه‌ای توسط تیم سایروس توریست (به‌صورت حضوری یا دورکاری)',
                style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.9),
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
                          builder: (_) => const SmartMapScreen(),
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
                child: _filledButton(
                  icon: Icons.event_available_rounded,
                  label: '📅 رزرو',
                  colors: const [_teal, _tealBright],
                  textColor: const Color(0xff03202a),
                  onTap: _openReserveSheet,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleLinkButton(
                    icon: Icons.camera_alt_rounded,
                    onTap: () =>
                        _openUrl(context, _SupportInfo.instagramUrl),
                  ),
                  const SizedBox(width: 14),
                  _circleLinkButton(
                    icon: Icons.public_rounded,
                    onTap: () => _openUrl(context, _SupportInfo.websiteUrl),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'نمونه‌ی اینستاگرام و وب‌سایت — برای آزمایش، لینک‌های سایروس توریست نمایش داده شده است.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: '📋 قوانین و شرایط خدمات',
          child: const Text(
            'شرایط و خدمات ثبت اقامتگاه در سایروس توریست بر پایه زیرساخت اینترنت کشور و صرفاً به‌صورت تبلیغات مجازی ارائه می‌شود. '
            'سایروس توریست در صورت بروز هرگونه اختلال، قطعی یا محدودیت در زیرساخت اینترنت، هیچ‌گونه مسئولیتی در قبال آن نخواهد داشت.\n\n'
            'هزینه خدمات ثبت اقامتگاه به‌صورت سالانه محاسبه و دریافت می‌شود.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.9),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _rulesAccepted = !_rulesAccepted),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _rulesAccepted,
                  activeColor: _teal,
                  onChanged: (v) =>
                      setState(() => _rulesAccepted = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'قوانین و شرایط خدمات سایروس توریست را مطالعه کرده‌ام و می‌پذیرم.',
                      style: TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: _filledButton(
            icon: _rulesAccepted
                ? Icons.check_circle_rounded
                : Icons.lock_rounded,
            label: _rulesAccepted
                ? 'ادامه و ارتباط با پشتیبانی'
                : 'ادامه',
            colors: _rulesAccepted
                ? const [_teal, _tealBright]
                : const [Color(0xff22323c), Color(0xff22323c)],
            textColor: _rulesAccepted
                ? const Color(0xff03202a)
                : Colors.white38,
            onTap: _rulesAccepted
                ? () => setState(() => _showSupportStep = true)
                : null,
          ),
        ),
      ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            '⚠️ موقعیت‌مکانی خاموش است',
            style: TextStyle(color: _goldBright),
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('📍 موقعیت شما دریافت شد',
            style: TextStyle(color: _goldBright)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                onTap: () => _goToPaymentWarning(),
              ),
              _reserveOption(
                icon: Icons.phone_rounded,
                label: 'تلفن ثابت اقامتگاه',
                onTap: () => _goToPaymentWarning(),
              ),
              _reserveOption(
                icon: Icons.support_agent_rounded,
                label: 'پشتیبانی سایروس توریست',
                onTap: () => _goToPaymentWarning(),
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
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xff103b50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xffffb020), size: 38),
              const SizedBox(height: 10),
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
                style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.9),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _filledButton(
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
                    side: BorderSide(color: _gold.withValues(alpha: 0.6)),
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

  Widget _buildSupportStep() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'برای تکمیل مراحل ثبت و هماهنگی معرفی اقامتگاه، با پشتیبانی سایروس توریست در ارتباط باشید.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.9),
          ),
          const SizedBox(height: 20),
          _contactRow(
            icon: Icons.call_rounded,
            title: 'تماس با پشتیبانی',
            subtitle: _SupportInfo.phone,
            onTap: () => _openUrl(context, 'tel:${_SupportInfo.phone}'),
          ),
          _contactRow(
            icon: Icons.send_rounded,
            title: 'پشتیبانی تلگرام',
            subtitle: _SupportInfo.telegramLabel,
            onTap: () => _openUrl(context, _SupportInfo.telegram),
          ),
          _contactRow(
            icon: Icons.chat_rounded,
            title: 'پشتیبانی واتساپ',
            subtitle: _SupportInfo.phone,
            onTap: () => _openUrl(context, _SupportInfo.whatsapp),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showSupportStep = false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('بازگشت'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _goldBright,
                side: BorderSide(color: _gold.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 24),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SHARED WIDGETS =====================

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _goldBright,
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _outlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: _gold.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _filledButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _circleLinkButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xff103b50),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: _gold),
      ),
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
