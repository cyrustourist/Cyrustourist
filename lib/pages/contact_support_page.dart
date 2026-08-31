import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const Color backgroundColor = Color(0xff06121d);
  static const Color panelColor = Color(0xff0b2636);
  static const Color panelLight = Color(0xff10394c);
  static const Color goldColor = Color(0xffffd36a);
  static const Color goldBright = Color(0xffffe39a);

  static const String phoneNumber = '09153448818';
  static const String whatsappNumber = '09153448818';
  static const String telegramUsername = '@Cyrustourist';
  static const String telegramGroupUrl = 'https://t.me/cyrustourist_app';
  static const String emailAddress = 'cyrustourist@gmail.com';
  static const String address = 'استان خراسان رضوی، بلوار پیروزی، رضا شهر';
  static const String websiteUrl = 'https://cyrustourist-maker.github.io/Cyrustourist/';

  Future<void> _openUrl(BuildContext context, String value) async {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null) {
      _message(context, 'لینک نامعتبر است.');
      return;
    }

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _message(context, 'امکان باز کردن این بخش وجود ندارد.');
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, 'برنامه مناسب برای این عملیات پیدا نشد.');
      }
    }
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _whatsapp(BuildContext context) async {
    final number = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) {
      _message(context, 'شماره واتساپ تنظیم نشده است.');
      return;
    }
    final international = number.startsWith('0') ? '98${number.substring(1)}' : number;
    await _openUrl(context, 'https://wa.me/$international');
  }

  Future<void> _telegram(BuildContext context) =>
      _openUrl(context, 'https://t.me/${telegramUsername.replaceAll('@', '')}');

  Future<void> _email(BuildContext context) => _openUrl(
        context,
        Uri(
          scheme: 'mailto',
          path: emailAddress,
          queryParameters: const {'subject': 'Cyrus Tourist Support'},
        ).toString(),
      );

  Future<void> _website(BuildContext context) => _openUrl(context, websiteUrl);

  Future<void> _address(BuildContext context) => _openUrl(
        context,
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [panelLight, panelColor],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: goldColor.withValues(alpha: 0.38)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                _Icon3D(icon: icon, enabled: enabled),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: enabled ? goldBright : Colors.white54,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: enabled ? goldColor : Colors.white24,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'پشتیبانی و تماس',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            child: Column(
              children: [
                _HeroSupport(),
                const SizedBox(height: 22),
                const Text(
                  'راه‌های ارتباط با Cyrus Tourist',
                  style: TextStyle(
                    color: goldBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'برای پرسش، پیشنهاد، گزارش مشکل یا همکاری با ما، یکی از گزینه‌های زیر را انتخاب کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 20),
                _actionCard(
                  context: context,
                  icon: Icons.phone_in_talk_rounded,
                  title: 'تماس با ما',
                  subtitle: phoneNumber,
                ),
                _actionCard(
                  context: context,
                  icon: Icons.chat_rounded,
                  title: 'واتساپ',
                  subtitle: 'ارتباط مستقیم با پشتیبانی',
                  onTap: () => _whatsapp(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.send_rounded,
                  title: 'تلگرام',
                  subtitle: telegramUsername,
                  onTap: () => _telegram(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.groups_rounded,
                  title: 'گروه تلگرام',
                  subtitle: 'عضویت در گروه Cyrus Tourist',
                  onTap: () => _openUrl(context, telegramGroupUrl),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.email_rounded,
                  title: 'ایمیل',
                  subtitle: emailAddress,
                  onTap: () => _email(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.language_rounded,
                  title: 'وب‌سایت رسمی',
                  subtitle: 'مشاهده اطلاعات و خدمات بیشتر',
                  onTap: () => _website(context),
                ),
                const SizedBox(height: 4),
                _actionCard(
                  context: context,
                  icon: Icons.location_on_rounded,
                  title: 'آدرس و موقعیت',
                  subtitle: address,
                  onTap: () => _address(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.feedback_rounded,
                  title: 'پیشنهاد یا گزارش مشکل',
                  subtitle: 'ارسال پیام مستقیم به پشتیبانی از طریق ایمیل',
                  onTap: () => _email(context),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Cyrus Tourist',
                  style: TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'سفر کن، کشف کن، لذت ببر',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon3D extends StatelessWidget {
  const _Icon3D({required this.icon, required this.enabled});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: enabled
              ? [const Color(0xffffe39a), const Color(0xffb87918)]
              : [Colors.white24, Colors.white10],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SupportPage.goldColor.withValues(alpha: enabled ? 0.7 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 7,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: enabled ? const Color(0xff06121d) : Colors.white38,
        size: 29,
      ),
    );
  }
}

class _HeroSupport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff123e51), Color(0xff071c29)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SupportPage.goldColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffffe39a), Color(0xffb87918)],
              ),
              boxShadow: [
                BoxShadow(
                  color: SupportPage.goldColor.withValues(alpha: 0.3),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(4, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: SupportPage.backgroundColor,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'همراه شما هستیم',
            textAlign: TextAlign.center,
            style: TextStyle(color: SupportPage.goldBright, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'پشتیبانی Cyrus Tourist برای سفر بهتر و استفاده آسان‌تر از برنامه در کنار شماست.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
          ),
        ],
      ),
    );
  }
}

Widget _futureCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xff0b2636).withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SupportPage.goldColor.withValues(alpha: 0.22)),
    ),
    child: const Row(
      children: [
        _Icon3D(icon: Icons.forum_rounded, enabled: false),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('چت آنلاین', style: TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('این قابلیت در نسخه آینده به پشتیبانی آنلاین متصل می‌شود.', style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
            ],
          ),
        ),
        Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 20),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text, this.buttonText, this.onTap});

  final IconData icon;
  final String title;
  final String text;
  final String? buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: SupportPage.panelColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SupportPage.goldColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: SupportPage.goldColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: SupportPage.goldBright, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.7)),
                  ],
                ),
              ),
            ],
          ),
          if (buttonText != null && onTap != null) ...[
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(buttonText!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SupportPage.goldColor,
                  side: BorderSide(color: SupportPage.goldColor.withValues(alpha: 0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
