import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/account_service.dart';
import '../../services/sms_status_service.dart';
import '../../widgets/cyrus_result_dialog.dart';

const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

const Map<String, Map<String, String>> _L = {
  'fa': {
    'ready': 'آماده است — یک بار کلیک کنید',
    'sending': 'در حال ارسال… دوباره کلیک نکنید',
    'sentOk': 'کد ارسال شد. کد را وارد کنید.',
    'wait': 'ارسال دوباره ممکن است بعد از',
    'sec': 'ثانیه',
    'btnSend': 'دریافت کد تأیید',
    'btnSendSub': 'یک بار کلیک کنید؛ کلید قفل می‌شود تا پیامک تکراری نرود',
    'btnLocked': 'قفل شد — کد در راه است',
    'btnReq': 'درخواست کد از پشتیبانی',
    'btnReqSub': 'ارسال خودکار پیامک خاموش است؛ پشتیبانی کد را برای شما صادر می‌کند',
    'offTitle': 'ارسال خودکار پیامک فعلاً خاموش است',
    'offText': 'با «تأیید با جی‌میل» (کارت پایین‌تر) حساب را تأیید کنید، یا شمارهٔ خود را بنویسید و «درخواست کد از پشتیبانی» را بزنید؛ کد را از پشتیبانی (ایتا یا تلگرام) می‌گیرید و همین‌جا وارد می‌کنید.',
    'reqSent': 'درخواست شما به پشتیبانی رسید. کد را از پشتیبانی بگیرید و در کادر زیر وارد کنید.',
    'phoneEmpty': 'شمارهٔ همراه را وارد کنید (مثلاً 09123456789).',
  },
  'en': {
    'ready': 'Ready — click once',
    'sending': 'Sending… do not click again',
    'sentOk': 'Code sent. Enter it below.',
    'wait': 'You can resend after',
    'sec': 's',
    'btnSend': 'Get verification code',
    'btnSendSub': 'Click once; the button locks so duplicate SMS are not sent',
    'btnLocked': 'Locked — code is on its way',
    'btnReq': 'Request a code from support',
    'btnReqSub': 'Automatic SMS is off; support will issue a code for you',
    'offTitle': 'Automatic SMS is currently off',
    'offText': 'Verify with Gmail (card below), or enter your number and tap "Request a code from support"; get the code from support (Eitaa or Telegram) and enter it here.',
    'reqSent': 'Your request reached support. Get the code from support and enter it below.',
    'phoneEmpty': 'Enter your mobile number (e.g. 09123456789).',
  },
  'ar': {
    'ready': 'جاهز — انقر مرة واحدة',
    'sending': 'جارٍ الإرسال… لا تنقر مجدداً',
    'sentOk': 'تم إرسال الرمز. أدخله أدناه.',
    'wait': 'يمكنك إعادة الإرسال بعد',
    'sec': 'ث',
    'btnSend': 'الحصول على رمز التحقق',
    'btnSendSub': 'انقر مرة واحدة؛ يُقفل الزر لمنع إرسال رسائل مكررة',
    'btnLocked': 'تم القفل — الرمز في الطريق',
    'btnReq': 'طلب رمز من الدعم',
    'btnReqSub': 'الإرسال التلقائي متوقف؛ سيصدر لك الدعم الرمز',
    'offTitle': 'الإرسال التلقائي للرسائل متوقف حالياً',
    'offText': 'أكّد حسابك عبر Gmail (البطاقة أدناه)، أو أدخل رقمك واضغط «طلب رمز من الدعم»، ثم احصل على الرمز من الدعم (إيتا أو تيليجرام) وأدخله هنا.',
    'reqSent': 'وصل طلبك إلى الدعم. احصل على الرمز منهم وأدخله أدناه.',
    'phoneEmpty': 'أدخل رقم هاتفك (مثال 09123456789).',
  },
};

String _l(String k) {
  final m = _L[MenuLanguage.current] ?? _L['en']!;
  return m[k] ?? _L['en']![k] ?? k;
}

/// تأیید شماره همراه با کد پیامک (OTP). فقط پس از کد درست، شماره «تأییدشده» ثبت می‌شود.
class PhoneVerifyCard extends StatefulWidget {
  const PhoneVerifyCard({super.key, this.onChanged});

  /// بعد از تأیید موفق صدا زده می‌شود (برای بازخوانی پروفایل حساب).
  final Future<void> Function()? onChanged;

  @override
  State<PhoneVerifyCard> createState() => _PhoneVerifyCardState();
}

class _PhoneVerifyCardState extends State<PhoneVerifyCard> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verified; // شمارهٔ پوشانده‌شده
  bool _loading = true;
  bool _busy = false;
  bool _codeSent = false;
  SmsStatus _sms = SmsStatus.open;

  // قفل ضد کلیک چندباره: همان لحظهٔ اول کلید قفل می‌شود (بدون پنجره)، و قفل بین باز و بسته شدن صفحه هم می‌ماند
  static final Map<String, int> _locks = {};
  static int _globalLock = 0;
  bool _sending = false;
  Timer? _tick;
  int _left = 0;
  String _info = '';
  bool _infoOk = true;

  String get _key => _phone.text.replaceAll(RegExp(r'[^0-9]'), '');

  int _remainingSec() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final u = [(_locks[_key] ?? 0), _globalLock].reduce((a, b) => a > b ? a : b);
    final d = ((u - now) / 1000).ceil();
    return d > 0 ? d : 0;
  }

  void _lockFor(int sec) {
    final until = DateTime.now().millisecondsSinceEpoch + sec * 1000;
    _locks[_key] = until;
    _globalLock = DateTime.now().millisecondsSinceEpoch + 8000;
    _startTick();
  }

  void _startTick() {
    _tick?.cancel();
    _left = _remainingSec();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      final r = _remainingSec();
      if (!mounted) return t.cancel();
      setState(() => _left = r);
      if (r <= 0) t.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadSms();
    _phone.addListener(() {
      final r = _remainingSec();
      if (r != _left && mounted) setState(() => _left = r);
      if (r > 0 && (_tick == null || !_tick!.isActive)) _startTick();
    });
  }

  Future<void> _loadSms() async {
    final st = await SmsStatus.load();
    if (!mounted) return;
    setState(() => _sms = st);
  }

  String _smsNote() {
    final key = _sms.reason == 'off' ? 'sms_off_note' : (_sms.reason == 'cap' ? 'sms_cap_note' : 'sms_hours_note');
    return NT.t(key).replaceAll('{a}', '${_sms.from}').replaceAll('{b}', '${_sms.to}');
  }

  @override
  void dispose() {
    _tick?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final a = await AccountService.me();
    if (!mounted) return;
    setState(() {
      _verified = (a != null && a.phoneVerified) ? a.phoneMasked : null;
      _loading = false;
    });
  }

  Future<void> _result(bool ok, String m) async {
    if (!mounted) return;
    await showCyrusResult(context, ok: ok, message: m);
  }

  Future<void> _send() async {
    if (_sending || _busy) return;
    if (_remainingSec() > 0) return;
    if (_phone.text.trim().isEmpty) {
      setState(() {
        _info = _l('phoneEmpty');
        _infoOk = false;
      });
      return;
    }
    HapticFeedback.lightImpact();
    // قفل همزمان و بدون انتظار: حتی اگر پاسخ دیر برسد، کلیک دوم ممکن نیست
    setState(() {
      _sending = true;
      _info = '';
    });
    _lockFor(60);
    final r = await AccountService.phoneSend(_phone.text.trim());
    if (!mounted) return;
    final softFail = !r.ok && r.code != 'otp_wait';
    if (softFail) {
      // خطای شبکه/شماره نامعتبر/…: قفل کوتاه تا کاربر اصلاح کند، پیامکی ارسال نشده است
      _locks[_key] = DateTime.now().millisecondsSinceEpoch + 6000;
      _startTick();
    }
    setState(() {
      _sending = false;
      if (r.ok) _codeSent = true;
      _infoOk = r.ok;
      _info = r.code == 'net'
          ? NT.t('g_net')
          : (r.ok ? (_sms.canSend ? _l('sentOk') : _l('reqSent')) : r.message);
    });
  }

  Future<void> _verify() async {
    if (_busy || _code.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final r = await AccountService.phoneVerify(_phone.text.trim(), _code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _code.clear();
      setState(() => _codeSent = false);
      await _load();
      final tk = r.badge == 'gold' ? NT.t('tk_gold') : (r.badge == 'blue' ? NT.t('tk_blue') : NT.t('tk_none'));
      await _result(true, '${NT.t('ph_done')}\n$tk');
      if (widget.onChanged != null) await widget.onChanged!();
    } else {
      await _result(false, r.code == 'net' ? NT.t('g_net') : r.message);
    }
  }

  Widget _bigButton() {
    final locked = _sending || _left > 0;
    final manual = !_sms.canSend;
    return Opacity(
      opacity: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: locked ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 84),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: locked
                    ? const [Color(0xff087f68), Color(0xff13b98e), Color(0xff55d7b1)]
                    : const [Color(0xff2056a7), Color(0xff2785ff), Color(0xffffca4b)],
              ),
              boxShadow: [BoxShadow(color: locked ? const Color(0xff075749) : const Color(0xff102f52), offset: Offset(0, locked ? 3 : 6))],
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Icon(locked ? Icons.lock_rounded : (manual ? Icons.support_agent_rounded : Icons.sms_rounded), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    locked ? _l('btnLocked') : (manual ? _l('btnReq') : _l('btnSend')),
                    style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    locked ? (_left > 0 ? '${_l('wait')} $_left ${_l('sec')}' : '') : (manual ? _l('btnReqSub') : _l('btnSendSub')),
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.6),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gold.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
      );

  @override
  Widget build(BuildContext context) {
    final done = _verified != null;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (done ? _teal : _gold).withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(done ? Icons.verified_user_rounded : Icons.sms_outlined, color: done ? _teal : _gold),
            const SizedBox(width: 10),
            Expanded(child: Text(done ? NT.t('ph_done') : NT.t('ph_title'), style: TextStyle(color: done ? _teal : _gold, fontWeight: FontWeight.w900, fontSize: 14.5))),
          ]),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: LinearProgressIndicator(color: _gold, backgroundColor: Color(0xff102733)))
          else if (done)
            Directionality(textDirection: TextDirection.ltr, child: Text(_verified!, style: const TextStyle(color: Colors.white, fontSize: 14)))
          else ...[
            Text(NT.t('ph_desc'), style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5, height: 1.7)),
            if (!_sms.canSend) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffff8a3d).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffff8a3d).withValues(alpha: 0.5)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xffff8a3d), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_l('offTitle'), style: const TextStyle(color: Color(0xffffb67a), fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(_sms.reason == 'off' ? _l('offText') : _smsNote(), style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.8)),
                    ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(NT.t('ph_input')),
            ),
            const SizedBox(height: 12),
            _bigButton(),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: (_left > 0 || _sending) ? _gold : _teal),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _sending ? _l('sending') : (_left > 0 ? '${_l('wait')} $_left ${_l('sec')}' : _l('ready')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ]),
            if (_info.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_info, textAlign: TextAlign.center, style: TextStyle(color: _infoOk ? _teal : const Color(0xffff8d9b), fontSize: 12.5, height: 1.8)),
              ),
            if (_codeSent || !_sms.canSend) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: _dec(NT.t('ph_code')).copyWith(counterText: ''),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: const Color(0xff06121d), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _busy ? null : _verify,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xff06121d)))
                      : Text(NT.t('ph_verify'), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}
