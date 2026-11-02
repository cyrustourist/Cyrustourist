import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../core/language/menu_translations.dart';

/// شمارهٔ پشتیبانی پیش‌فرض (اگر سرور شماره‌ای نفرستاده باشد).
const String kSupportPhoneDefault = '09153448818';

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'حق عضویت و ثبت‌نام یک‌ساله',
    'hero': 'ثبت درخواست شما انجام شد',
    'heroSub': 'درخواست شما در انتظار تأیید پشتیبانی است. مبلغ حق عضویت را اینجا ببینید.',
    'code': 'کد رهگیری',
    'priceLabel': 'حق عضویت + ثبت‌نام یک‌ساله',
    'priceNone': 'قیمت را پشتیبانی اعلام می‌کند',
    'priceNoneSub': 'برای بررسی قیمت با پشتیبانی تماس بگیرید.',
    'note': 'توضیحات',
    'payTitle': 'پرداخت کارت‌به‌کارت',
    'card': 'شمارهٔ کارت',
    'holder': 'به نام',
    'copyCard': 'کپی شمارهٔ کارت',
    'copied': 'کپی شد',
    'stepsTitle': 'مراحل بعدی',
    'st1': 'قیمت را ببینید یا برای بررسی قیمت با پشتیبانی تماس بگیرید.',
    'st2': 'مبلغ را واریز کنید (کارت‌به‌کارت) و رسید را برای پشتیبانی بفرستید.',
    'st3': 'پشتیبانی درخواست شما را بررسی و تأیید می‌کند.',
    'supportTitle': 'تماس با پشتیبانی',
    'supportSub': 'برای بررسی قیمت و هماهنگی پرداخت',
    'call': 'تماس بگیرید',
    'copyPhone': 'کپی شماره',
    'sms': 'پیامک',
  },
  'en': {
    'title': 'Membership fee & one-year registration',
    'hero': 'Your request was submitted',
    'heroSub': 'Your request is waiting for support approval. See the membership fee here.',
    'code': 'Tracking code',
    'priceLabel': 'Membership fee + one-year registration',
    'priceNone': 'Support will tell you the price',
    'priceNoneSub': 'Call support to check the price.',
    'note': 'Notes',
    'payTitle': 'Card-to-card payment',
    'card': 'Card number',
    'holder': 'Card holder',
    'copyCard': 'Copy card number',
    'copied': 'Copied',
    'stepsTitle': 'Next steps',
    'st1': 'Check the price, or call support to confirm it.',
    'st2': 'Pay (card-to-card) and send the receipt to support.',
    'st3': 'Support reviews and approves your request.',
    'supportTitle': 'Contact support',
    'supportSub': 'To check the price and arrange payment',
    'call': 'Call',
    'copyPhone': 'Copy number',
    'sms': 'SMS',
  },
  'ar': {
    'title': 'رسوم العضوية والتسجيل لمدة سنة',
    'hero': 'تم إرسال طلبك',
    'heroSub': 'طلبك بانتظار موافقة الدعم. اطّلع على رسوم العضوية هنا.',
    'code': 'رمز التتبع',
    'priceLabel': 'رسوم العضوية + التسجيل لمدة سنة',
    'priceNone': 'سيعلمك الدعم بالسعر',
    'priceNoneSub': 'اتصل بالدعم للاستعلام عن السعر.',
    'note': 'ملاحظات',
    'payTitle': 'الدفع من بطاقة إلى بطاقة',
    'card': 'رقم البطاقة',
    'holder': 'باسم',
    'copyCard': 'نسخ رقم البطاقة',
    'copied': 'تم النسخ',
    'stepsTitle': 'الخطوات التالية',
    'st1': 'اطّلع على السعر أو اتصل بالدعم للتأكد منه.',
    'st2': 'ادفع (من بطاقة إلى بطاقة) وأرسل الإيصال إلى الدعم.',
    'st3': 'يراجع الدعم طلبك ويوافق عليه.',
    'supportTitle': 'اتصل بالدعم',
    'supportSub': 'للاستعلام عن السعر وترتيب الدفع',
    'call': 'اتصال',
    'copyPhone': 'نسخ الرقم',
    'sms': 'رسالة',
  },
};

String _t(String k) {
  final m = _tx[MenuLanguage.current] ?? _tx['en']!;
  return m[k] ?? _tx['en']![k] ?? k;
}

/// صفحهٔ «بررسی قیمت حق عضویت»: قیمت را ادمین از پنل (تنظیمات گروه‌ها ← حق عضویت) می‌گذارد.
class MembershipFeePage extends StatefulWidget {
  const MembershipFeePage({super.key, this.trackingCode = '', this.supportPhone = ''});

  final String trackingCode;
  final String supportPhone;

  @override
  State<MembershipFeePage> createState() => _MembershipFeePageState();
}

class _MembershipFeePageState extends State<MembershipFeePage> {
  static const Color _ink = Color(0xff16222d);
  static const Color _soft = Color(0xff62707e);
  static const Color _teal = Color(0xff11998e);
  static const Color _deep = Color(0xff0b6e69);
  static const Color _gold = Color(0xffc88a14);

  Map<String, String> _fee = const {};
  bool _loading = true;

  String get _phone => widget.supportPhone.trim().isNotEmpty ? widget.supportPhone.trim() : kSupportPhoneDefault;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse('${ApiConfig.panelBaseUrl}/api/app/flags')).timeout(const Duration(seconds: 10));
      final res = await req.close().timeout(const Duration(seconds: 10));
      final j = jsonDecode(await res.transform(utf8.decoder).join());
      final f = j is Map ? j['reg_fee'] : null;
      if (f is Map) _fee = {for (final k in ['amount', 'card', 'holder', 'note']) k: '${f[k] ?? ''}'.trim()};
    } catch (_) {
    } finally {
      client.close(force: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String s) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s), behavior: SnackBarBehavior.floating));

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast(_t('copied'));
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffe3ebef)),
          boxShadow: const [BoxShadow(color: Color(0x0f0b2a33), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: child,
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xff0b6e69), Color(0xff1fb36b)]),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_t('hero'), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 10),
          Text(_t('heroSub'), style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13, height: 1.9)),
          if (widget.trackingCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text('${_t('code')}: ${widget.trackingCode}', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
          ],
        ]),
      );

  Widget _priceCard() {
    final amount = _fee['amount'] ?? '';
    final note = _fee['note'] ?? '';
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.sell_rounded, color: _gold, size: 20),
          const SizedBox(width: 8),
          Text(_t('priceLabel'), style: const TextStyle(color: _soft, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: _teal))))
        else if (amount.isNotEmpty)
          Text(amount, style: const TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w900, height: 1.5))
        else ...[
          Text(_t('priceNone'), style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(_t('priceNoneSub'), style: const TextStyle(color: _soft, fontSize: 12.5, height: 1.8)),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(note, style: const TextStyle(color: _soft, fontSize: 12.5, height: 1.9)),
        ],
      ]),
    );
  }

  Widget _payCard() {
    final card = _fee['card'] ?? '';
    final holder = _fee['holder'] ?? '';
    if (card.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.credit_card_rounded, color: _teal, size: 20),
          const SizedBox(width: 8),
          Text(_t('payTitle'), style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff10303a), Color(0xff0b6e69)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('card'), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(card, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
            if (holder.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${_t('holder')}: $holder', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _copy(card.replaceAll(RegExp(r'[^0-9]'), '')),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(_t('copyCard')),
          style: OutlinedButton.styleFrom(foregroundColor: _teal, side: const BorderSide(color: _teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(46)),
        ),
      ]),
    );
  }

  Widget _stepsCard() {
    Widget row(int n, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 12, backgroundColor: const Color(0xffe3f6f2), child: Text('$n', style: const TextStyle(color: _deep, fontSize: 12, fontWeight: FontWeight.w900))),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: _ink, fontSize: 13, height: 1.8))),
          ]),
        );
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_t('stepsTitle'), style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        row(1, _t('st1')),
        row(2, _t('st2')),
        row(3, _t('st3')),
      ]),
    );
  }

  Widget _supportCard() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xfffff6dd), Color(0xffffeeb8)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xfff1d88a)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.support_agent_rounded, color: _gold, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t('supportTitle'), style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900)),
                Text(_t('supportSub'), style: const TextStyle(color: _soft, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(_phone, style: const TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: _phone)),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(_t('call'), style: const TextStyle(fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri(scheme: 'sms', path: _phone)),
                icon: const Icon(Icons.sms_rounded, size: 18),
                label: Text(_t('sms')),
                style: OutlinedButton.styleFrom(foregroundColor: _deep, side: const BorderSide(color: _deep), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: _t('copyPhone'),
              onPressed: () => _copy(_phone),
              icon: const Icon(Icons.copy_rounded, size: 18),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: _deep, side: const BorderSide(color: _deep), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final rtl = MenuLanguage.current == 'fa' || MenuLanguage.current == 'ar';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff3f6f7),
        appBar: AppBar(
          backgroundColor: _deep,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_t('title'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _hero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _priceCard(),
                  _payCard(),
                  _supportCard(),
                  _stepsCard(),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
