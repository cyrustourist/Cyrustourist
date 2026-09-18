import 'package:flutter/material.dart';

import '../../widgets/registration_direct_contact.dart';
import '../../models/leader.dart';
import 'leader_profile_page.dart';
import 'leader_registration_form_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

const List<String> _panelFeatures = [
  'پروفایل اختصاصی',
  'معرفی و سوابق',
  'نمایش عکس',
  'نمایش ویدئوی معرفی',
  'معرفی تورها',
  'نمایش امتیاز کاربران',
  'نمایش نظرات کاربران',
  'معرفی به عنوان لیدر محلی در صورت تأیید',
  'نمایش وضعیت مجوز در صورت تأیید',
  'امکانات تبلیغاتی پنل',
  'نمایش در سایت و اپلیکیشن CYRUS TOURIST',
];

const String _termsText =
    'قوانین و شرایط استفاده از پنل لیدر CYRUS TOURIST را مطالعه کرده‌ام و می‌پذیرم.';

class LeaderRegistrationIntroPage extends StatefulWidget {
  const LeaderRegistrationIntroPage({super.key});

  @override
  State<LeaderRegistrationIntroPage> createState() =>
      _LeaderRegistrationIntroPageState();
}

class _LeaderRegistrationIntroPageState extends State<LeaderRegistrationIntroPage> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: const Text(
            'ثبت‌نام به عنوان لیدر',
            style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'امکانات پنل لیدر',
                style: TextStyle(
                  color: _goldBright,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    for (final f in _panelFeatures)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: _teal, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Material(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderProfilePage(leader: demoLeader),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, color: _gold, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'مشاهده نمونه کامل پروفایل لیدر',
                            style: TextStyle(
                              color: _goldBright,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios_new, size: 14, color: _gold),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.2)),
                ),
                child: InkWell(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        activeColor: _teal,
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _termsText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accepted ? _gold : Colors.white.withValues(alpha: 0.08),
                    foregroundColor: _accepted ? const Color(0xff06121d) : Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _accepted
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderRegistrationFormPage(),
                            ),
                          )
                      : null,
                  child: const Text(
                    'ادامه ثبت‌نام',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              RegistrationDirectContact(subject: 'لیدرها'),
            ],
          ),
        ),
      ),
    );
  }
}
