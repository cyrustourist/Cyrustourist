import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// اطلاعات تماس مستقیم پشتیبانی ثبت‌نام سایروس توریست.
class RegistrationContactInfo {
  RegistrationContactInfo._();

  static const String phone = '09153448818';
  static const String whatsapp = 'https://wa.me/989153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
  static const String eitaa = 'https://eitaa.com/cyrustourist';
}

/// کارت «تماس مستقیم» برای بخش ثبت‌نام لیدرها و آژانس‌های مسافرتی:
/// شماره تماس (لمس = تماس) + واتساپ، تلگرام و ایتا.
class RegistrationDirectContact extends StatelessWidget {
  const RegistrationDirectContact({
    super.key,
    this.subject = 'لیدرها و آژانس‌های مسافرتی',
  });

  /// موضوع ثبت‌نام؛ داخل متن توضیح کارت نمایش داده می‌شود.
  final String subject;

  static const Color _card = Color(0xff0b2636);
  static const Color _gold = Color(0xffffd36a);
  static const Color _goldBright = Color(0xffffe39a);

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تماس مستقیم با پشتیبانی',
            style: TextStyle(
              color: _goldBright,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'برای ثبت‌نام $subject می‌توانید مستقیماً با ما تماس بگیرید.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // شماره تماس مستقیم
          Material(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(context, 'tel:${RegistrationContactInfo.phone}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.call_rounded, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'تماس تلفنی',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        RegistrationContactInfo.phone,
                        style: const TextStyle(
                          color: _goldBright,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _chip(
                  context,
                  icon: Icons.chat_rounded,
                  label: 'واتساپ',
                  color: const Color(0xff25d366),
                  url: RegistrationContactInfo.whatsapp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  context,
                  icon: Icons.send_rounded,
                  label: 'تلگرام',
                  color: const Color(0xff2aabee),
                  url: RegistrationContactInfo.telegram,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  context,
                  icon: Icons.forum_rounded,
                  label: 'ایتا',
                  color: const Color(0xfff5a623),
                  url: RegistrationContactInfo.eitaa,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context, url),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
