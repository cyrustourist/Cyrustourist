import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../pages/profile/my_profile_page.dart';
import '../services/account_service.dart';

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'مراحل ثبت‌نام',
    's1': 'ساخت شناسه کاربری و تأیید جی‌میل یا پیامک',
    's1done': 'حساب شما تأیید شده است — این مرحله انجام شد',
    's2': 'پر کردن فرم ثبت‌نام',
    's3': 'بررسی و تأیید پشتیبانی',
    's3sub': 'درخواست شما توسط پشتیبانی سایروس توریست بررسی و تأیید می‌شود.',
    's4': 'تأیید قوانین و ادامهٔ ثبت‌نام',
    'phone': 'تأیید شمارهٔ همراه (پیامک)',
    'gmail': 'تأیید جی‌میل',
    'go': 'رفتن به شناسه کاربری',
    'recheck': 'تأیید کردم، بررسی دوباره',
    'need': 'یکی از این دو (پیامک یا جی‌میل) کافی است.',
    'ok': 'تأیید شد',
    'verifiedHint': 'حساب تأییدشده است؛ ثبت‌نام را ادامه دهید. تیک آبی یا طلایی را مدیریت پس از بررسی فعال می‌کند.',
  },
  'en': {
    'title': 'Registration steps',
    's1': 'Create your account ID and verify Gmail or SMS',
    's1done': 'Your account is verified — this step is done',
    's2': 'Fill in the registration form',
    's3': 'Support review and approval',
    's3sub': 'Your request is reviewed and approved by Cyrus Tourist support.',
    's4': 'Accept the terms and continue',
    'phone': 'Mobile number (SMS) verification',
    'gmail': 'Gmail verification',
    'go': 'Go to my account',
    'recheck': 'I verified, check again',
    'need': 'Either one (SMS or Gmail) is enough.',
    'ok': 'Verified',
    'verifiedHint': 'Your account is verified; continue registration. Blue or gold tick is activated by management after review.',
  },
  'ar': {
    'title': 'خطوات التسجيل',
    's1': 'إنشاء معرّف الحساب وتأكيد Gmail أو الرسائل النصية',
    's1done': 'تم تأكيد حسابك — اكتملت هذه الخطوة',
    's2': 'تعبئة نموذج التسجيل',
    's3': 'مراجعة الدعم والموافقة',
    's3sub': 'يقوم فريق دعم سايروس توريست بمراجعة طلبك والموافقة عليه.',
    's4': 'الموافقة على الشروط ومتابعة التسجيل',
    'phone': 'تأكيد رقم الهاتف (SMS)',
    'gmail': 'تأكيد Gmail',
    'go': 'الانتقال إلى حسابي',
    'recheck': 'تم التأكيد، تحقق مجدداً',
    'need': 'يكفي أحدهما (SMS أو Gmail).',
    'ok': 'تم التأكيد',
    'verifiedHint': 'حسابك مؤكَّد؛ تابع التسجيل. تفعّل الإدارة العلامة الزرقاء أو الذهبية بعد المراجعة.',
  },
};

String _t(String k) {
  final m = _tx[MenuLanguage.current] ?? _tx['en']!;
  return m[k] ?? _tx['en']![k] ?? k;
}

/// مراحل ثبت‌نام + وضعیت تأیید جی‌میل/پیامک (تیک سبز و کم‌رنگ وقتی تأیید شده).
/// [compact] فقط دو ردیف تأیید را نشان می‌دهد (برای بالای خود فرم).
class RegistrationStepsCard extends StatefulWidget {
  const RegistrationStepsCard({super.key, this.dark = false, this.compact = false, this.onChanged});

  final bool dark;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  @override
  State<RegistrationStepsCard> createState() => _RegistrationStepsCardState();
}

class _RegistrationStepsCardState extends State<RegistrationStepsCard> {
  AccountInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await AccountService.me();
    if (!mounted) return;
    setState(() {
      _info = a;
      _loading = false;
    });
    widget.onChanged?.call(_verified);
  }

  bool get _phoneOk => _info?.phoneVerified == true;
  bool get _mailOk => _info?.emailVerified == true;
  bool get _verified => _phoneOk || _mailOk;

  Future<void> _openAccount() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
    await _load();
  }

  Color get _bg => widget.dark ? const Color(0xff0e2433) : Colors.white;
  Color get _ink => widget.dark ? Colors.white : const Color(0xff202936);
  Color get _soft => widget.dark ? const Color(0xffa9bac6) : const Color(0xff687482);
  Color get _line => widget.dark ? const Color(0x33ffd36a) : const Color(0xffe0e8ec);
  static const Color _green = Color(0xff1fb36b);

  Widget _verifyRow(String label, bool ok, String? extra) {
    return Opacity(
      opacity: ok ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: ok ? _green : _soft, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700))),
          if (ok && extra != null && extra.isNotEmpty)
            Directionality(textDirection: TextDirection.ltr, child: Text(extra, style: TextStyle(color: _soft, fontSize: 12))),
          if (ok) Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: Text(_t('ok'), style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }

  Widget _step(int n, String title, {String? sub, bool done = false, List<Widget> children = const []}) {
    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: done ? _green : const Color(0xff11998e),
            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : Text('$n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 3), child: Text(title, style: TextStyle(color: _ink, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.6))),
              if (sub != null) Text(sub, style: TextStyle(color: _soft, fontSize: 12, height: 1.7)),
              ...children,
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final rows = <Widget>[
      _verifyRow(_t('phone'), _phoneOk, _info?.phoneMasked),
      _verifyRow(_t('gmail'), _mailOk, null),
    ];
    if (widget.compact) {
      if (!_verified) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
        child: Column(children: rows),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_t('title'), style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        _step(1, _verified ? _t('s1done') : _t('s1'), done: _verified, children: [
          const SizedBox(height: 4),
          ...rows,
          if (!_verified) ...[
            Text(_t('need'), style: TextStyle(color: _soft, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _openAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff11998e), foregroundColor: Colors.white),
                  child: Text(_t('go')),
                ),
              ),
            ]),
            TextButton(onPressed: _load, child: Text(_t('recheck'))),
          ],
        ]),
        _step(2, _t('s2')),
        _step(3, _t('s3'), sub: _t('s3sub')),
        _step(4, _t('s4')),
        if (_verified) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_t('verifiedHint'), style: TextStyle(color: _soft, fontSize: 12, height: 1.8))),
      ]),
    );
  }
}
