import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/account_service.dart';
import '../../services/sms_status_service.dart';
import '../../widgets/cyrus_result_dialog.dart';

const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

/// تأیید شماره همراه با کد پیامک (OTP). فقط پس از کد درست، شماره «تأییدشده» ثبت می‌شود.
class PhoneVerifyCard extends StatefulWidget {
  const PhoneVerifyCard({super.key});

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

  @override
  void initState() {
    super.initState();
    _load();
    _loadSms();
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
    if (_busy || _phone.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final r = await AccountService.phoneSend(_phone.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _codeSent = true;
    });
    await _result(r.ok, r.code == 'net' ? NT.t('g_net') : r.message);
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
    } else {
      await _result(false, r.code == 'net' ? NT.t('g_net') : r.message);
    }
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffff8a3d).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffff8a3d).withValues(alpha: 0.5)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xffff8a3d), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_smsNote(), style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.7))),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: _gold), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: (_busy || !_sms.canSend) ? null : _send,
                child: Text(NT.t('ph_send'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
              ),
            ),
            if (_codeSent) ...[
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
