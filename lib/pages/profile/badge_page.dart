import 'package:flutter/material.dart';

import '../../services/badge_service.dart';
import '../support_chat_page.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _blue = Color(0xff2a8cff);
const Color _goldBadge = Color(0xffffc233);

const Map<String, String> _kStatusFa = {
  'pending_payment': 'در انتظار پرداخت',
  'paid': 'پرداخت شد',
  'under_review': 'در حال بررسی توسط پشتیبانی',
  'approved': 'تأیید شد',
  'rejected': 'رد شد',
  'refunded': 'بازگشت وجه',
  'cancelled': 'لغو شد',
};

/// «تیک آبی و طلایی» — درخواست سالانهٔ نشان اعتبار برای کاربر.
/// پرداخت و بررسی توسط پشتیبانی انجام می‌شود (درگاه آنلاین هنوز وصل نیست).
class BadgePage extends StatefulWidget {
  const BadgePage({super.key});

  @override
  State<BadgePage> createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> {
  List<BadgePlan> _plans = const [];
  BadgeStatus? _status;
  bool _loading = true;
  bool _failed = false;
  String? _busyCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final results = await Future.wait([BadgeService.fetchPlans(), BadgeService.fetchStatus()]);
    if (!mounted) return;
    final plans = results[0] as List<BadgePlan>;
    setState(() {
      _plans = plans;
      _status = results[1] as BadgeStatus?;
      _failed = plans.isEmpty;
      _loading = false;
    });
  }

  String _price(BadgePlan p) {
    if (p.price <= 0) return 'قیمت از طرف پشتیبانی اعلام می‌شود';
    final s = p.price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf تومان';
  }

  String _duration(int days) => days == 365 ? 'اعتبار یک‌ساله' : 'اعتبار $days روز';

  Future<void> _request(BadgePlan p) async {
    setState(() => _busyCode = p.code);
    final r = await BadgeService.requestBadge(p.code);
    if (!mounted) return;
    setState(() => _busyCode = null);
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      return;
    }
    await _load();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card,
          title: Text(
            r.existing ? 'درخواست قبلی شما باز است' : 'درخواست شما ثبت شد',
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'کد درخواست: ${r.requestCode}\n\n'
            '${r.price > 0 ? 'برای پرداخت و بررسی مدارک، این کد را برای پشتیبانی بفرستید.' : 'پشتیبانی درخواست شما را بررسی می‌کند.'}',
            style: const TextStyle(color: Colors.white, height: 1.9),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('بعداً', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SupportChatPage(
                    languageCode: 'fa',
                    initialTopic: 3,
                    initialDetails: 'کد درخواست تیک: ${r.requestCode}',
                  ),
                ));
              },
              child: const Text('ارسال به پشتیبانی'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final s = _status;
    if (s == null) return const SizedBox.shrink();
    final lines = <Widget>[];
    s.active.forEach((code, exp) {
      lines.add(Row(children: [
        Icon(Icons.verified_rounded, color: code == 'gold' ? _goldBadge : _blue, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${code == 'gold' ? 'تیک طلایی' : 'تیک آبی'} فعال · تا ${exp.length >= 10 ? exp.substring(0, 10) : exp}',
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ]));
    });
    if (s.lastRequestStatus != null && s.lastRequestStatus != 'approved') {
      lines.add(Padding(
        padding: EdgeInsets.only(top: lines.isEmpty ? 0 : 8),
        child: Text(
          'آخرین درخواست (${s.lastRequestCode}): ${_kStatusFa[s.lastRequestStatus] ?? s.lastRequestStatus}',
          style: const TextStyle(color: Color(0xffcfe0ea), fontSize: 12.5, height: 1.8),
        ),
      ));
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xff1d3a4d))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
    );
  }

  Widget _planCard(BadgePlan p) {
    final isGold = p.code == 'gold';
    final color = isGold ? _goldBadge : _blue;
    final has = isGold ? (_status?.hasGold ?? false) : (_status?.hasBlue ?? false);
    final blocked = p.requiresCode == 'blue' && !(_status?.hasBlue ?? false);
    final busy = _busyCode == p.code;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.verified_rounded, color: color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(p.nameFa, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(_price(p), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(_duration(p.durationDays), style: const TextStyle(color: Color(0xff8fa5b2), fontSize: 12.5)),
          if (blocked)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('برای تیک طلایی، ابتدا تیک آبی لازم است.', style: TextStyle(color: Color(0xffffb347), fontSize: 12.5)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: isGold ? _bg : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: (has || blocked || busy || _busyCode != null) ? null : () => _request(p),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(has ? 'فعال است' : 'درخواست ${p.nameFa}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

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
          title: const Text('تیک آبی و طلایی', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    const Text(
                      'تیک آبی نشان تأیید هویت و تیک طلایی نشان ویژه است. هر دو سالانه‌اند و بعد از بررسی پشتیبانی فعال می‌شوند.',
                      style: TextStyle(color: Color(0xffcfe0ea), fontSize: 13, height: 1.9),
                    ),
                    const SizedBox(height: 14),
                    _statusCard(),
                    if (_failed)
                      Column(children: [
                        const SizedBox(height: 30),
                        const Text('دریافت اطلاعات ناموفق بود.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        OutlinedButton(onPressed: _load, child: const Text('تلاش دوباره', style: TextStyle(color: _gold))),
                      ])
                    else
                      for (final p in _plans) _planCard(p),
                  ],
                ),
        ),
      ),
    );
  }
}
