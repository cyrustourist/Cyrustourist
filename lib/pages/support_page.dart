import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/app_language.dart';

String _t(String fa, String en, String ar) {
  switch (LanguageManager.current) {
    case AppLanguage.persian:
      return fa;
    case AppLanguage.arabic:
      return ar;
    case AppLanguage.english:
      return en;
  }
}

TextDirection get _supportDir =>
    LanguageManager.current == AppLanguage.english
        ? TextDirection.ltr
        : TextDirection.rtl;

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
      _message(context, _t('لینک نامعتبر است.', 'Invalid link.', 'الرابط غير صالح.'));
      return;
    }

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _message(
          context,
          _t('امکان باز کردن این بخش وجود ندارد.',
              'This section cannot be opened.', 'لا يمكن فتح هذا القسم.'),
        );
      }
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          _t('برنامه مناسب برای این عملیات پیدا نشد.',
              'No suitable app was found for this action.',
              'لم يتم العثور على تطبيق مناسب لهذا الإجراء.'),
        );
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

  Future<void> _call(BuildContext context) =>
      _openUrl(context, 'tel:$phoneNumber');

  Future<void> _whatsapp(BuildContext context) async {
    final number = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) {
      _message(
        context,
        _t('شماره واتساپ تنظیم نشده است.', 'WhatsApp number is not set.',
            'رقم واتساب غير مضبوط.'),
      );
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

Future<void> _eitaa(BuildContext context) => _openUrl(context, eitaaUrl);

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: enabled ? goldColor : Colors.white24,
                  size: 18,
                ),
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
      textDirection: _supportDir,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _t('پشتیبانی و تماس', 'Support & Contact', 'الدعم والتواصل'),
            style: const TextStyle(fontWeight: FontWeight.w800),
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
                Text(
                  _t('راه‌های ارتباط با Cyrus Tourist',
                      'Ways to Contact Cyrus Tourist',
                      'طرق التواصل مع Cyrus Tourist'),
                  style: const TextStyle(
                    color: goldBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _t(
                    'برای پرسش، پیشنهاد، گزارش مشکل یا همکاری با ما، یکی از گزینه‌های زیر را انتخاب کنید.',
                    'For questions, suggestions, reporting an issue, or collaborating with us, choose one of the options below.',
                    'للأسئلة أو الاقتراحات أو الإبلاغ عن مشكلة أو التعاون معنا، اختر أحد الخيارات أدناه.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 20),
                _actionCard(
                  context: context,
                  icon: Icons.phone_in_talk_rounded,
                  title: _t('تماس با ما', 'Call Us', 'اتصل بنا'),
                  subtitle: phoneNumber,
                  onTap: () => _call(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.chat_rounded,
                  title: _t('واتساپ', 'WhatsApp', 'واتساب'),
                  subtitle: _t('ارتباط مستقیم با پشتیبانی',
                      'Direct contact with support', 'تواصل مباشر مع الدعم'),
                  onTap: () => _whatsapp(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.send_rounded,
                  title: _t('تلگرام', 'Telegram', 'تيليجرام'),
                  subtitle: telegramUsername,
                  onTap: () => _telegram(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.groups_rounded,
                  title: _t('گروه تلگرام', 'Telegram Group', 'مجموعة تيليجرام'),
                  subtitle: _t('عضویت در گروه Cyrus Tourist',
                      'Join the Cyrus Tourist group',
                      'انضم إلى مجموعة Cyrus Tourist'),
                  onTap: () => _openUrl(context, telegramGroupUrl),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.email_rounded,
                  title: _t('ایمیل', 'Email', 'البريد الإلكتروني'),
                  subtitle: emailAddress,
                  onTap: () => _email(context),
                ),
                _actionCard(
                  context: context,
                  icon: Icons.language_rounded,
                  title: _t('وب‌سایت رسمی', 'Official Website', 'الموقع الرسمي'),
                  subtitle: _t('مشاهده اطلاعات و خدمات بیشتر',
                      'View more information and services',
                      'عرض المزيد من المعلومات والخدمات'),
                  onTap: () => _website(context),
                ),
                const SizedBox(height: 4),
                _futureCard(),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.location_on_rounded,
                  title: _t('آدرس', 'Address', 'العنوان'),
                  text: address,
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.feedback_rounded,
                  title: _t('پیشنهاد یا گزارش مشکل', 'Feedback or Report an Issue',
                      'اقتراح أو الإبلاغ عن مشكلة'),
                  text: _t(
                    'بازخورد شما به ما کمک می‌کند Cyrus Tourist را بهتر و کاربردی‌تر کنیم.',
                    'Your feedback helps us make Cyrus Tourist better and more useful.',
                    'ملاحظاتكم تساعدنا على جعل Cyrus Tourist أفضل وأكثر فائدة.',
                  ),
                  buttonText: _t('ارسال پیام به پشتیبانی', 'Send Message to Support',
                      'إرسال رسالة إلى الدعم'),
                  onTap: () => _email(context),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Cyrus Tourist',
                  style: TextStyle(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _t('سفر کن، کشف کن، لذت ببر', 'Travel, Discover, Enjoy',
                      'سافر، اكتشف، استمتع'),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          Text(
            _t('همراه شما هستیم', 'We Are With You', 'نحن معك'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: SupportPage.goldBright, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            _t(
              'پشتیبانی Cyrus Tourist برای سفر بهتر و استفاده آسان‌تر از برنامه در کنار شماست.',
              'Cyrus Tourist support is here for a better trip and easier use of the app.',
              'دعم Cyrus Tourist بجانبك من أجل رحلة أفضل واستخدام أسهل للتطبيق.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
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
    child: Row(
      children: [
        const _Icon3D(icon: Icons.forum_rounded, enabled: false),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('چت آنلاین', 'Online Chat', 'الدردشة المباشرة'),
                style: const TextStyle(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                _t(
                  'این قابلیت در نسخه آینده به پشتیبانی آنلاین متصل می‌شود.',
                  'This feature will connect to live support in a future version.',
                  'ستتصل هذه الميزة بالدعم المباشر في نسخة مستقبلية.',
                ),
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 20),
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
