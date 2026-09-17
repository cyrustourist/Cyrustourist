import 'package:flutter/material.dart';

import '../../models/agency.dart';
import 'agency_profile_page.dart';
import 'agency_registration_form_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

const List<String> _panelFeatures = [
  'پروفایل اختصاصی آژانس',
  'معرفی و سوابق فعالیت',
  'نمایش لوگو و تصاویر',
  'نمایش ویدئوی معرفی',
  'معرفی تورهای آژانس',
  'نمایش امتیاز کاربران',
  'نمایش نظرات کاربران',
  'معرفی به عنوان آژانس معتبر در صورت تأیید',
  'نمایش وضعیت مجوز رسمی در صورت تأیید',
  'امکانات تبلیغاتی پنل',
  'نمایش در سایت و اپلیکیشن CYRUS TOURIST',
];

const String _termsText =
    'قوانین و شرایط استفاده از پنل آژانس CYRUS TOURIST را مطالعه کرده‌ام و می‌پذیرم.';

class AgencyRegistrationIntroPage extends StatefulWidget {
  const AgencyRegistrationIntroPage({super.key});

  @override
  State<AgencyRegistrationIntroPage> createState() =>
      _AgencyRegistrationIntroPageState();
}

class _AgencyRegistrationIntroPageState extends State<AgencyRegistrationIntroPage> {
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
            'ثبت‌نام آژانس مسافرتی',
            style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'امکانات پنل آژانس',
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
                      builder: (_) => const AgencyProfilePage(agency: demoAgency),
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
                            'مشاهده نمونه کامل پروفایل آژانس',
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
                              builder: (_) => const AgencyRegistrationFormPage(),
                            ),
                          )
                      : null,
                  child: const Text(
                    'ادامه ثبت‌نام',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
