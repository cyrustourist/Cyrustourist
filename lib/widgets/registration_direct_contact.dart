import 'package:flutter/material.dart';

/// کارت «تماس با پشتیبانی» برای بخش ثبت‌نام لیدرها و آژانس‌های مسافرتی.
///
/// فقط متن است و هیچ لینک یا دکمه‌ای ندارد که کاربر را از برنامه خارج کند
/// (طبق قوانین مایکت). کاربر از منوی «شناسه کاربری» ← «ارتباط با ما» ←
/// «چت با پشتیبانی» اقدام می‌کند.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'تماس با پشتیبانی',
            style: TextStyle(
              color: _goldBright,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای ثبت‌نام $subject، از منوی «شناسه کاربری» ← «ارتباط با ما» ← «چت با پشتیبانی» اقدام کنید.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}
