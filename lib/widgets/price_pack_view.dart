import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/price_pack.dart';

const Color _kAppBg = Color(0xff06121d);
const Color _kCard = Color(0xff0b2636);
const Color _kCard2 = Color(0xff0e2f43);
const Color _kLine = Color(0xff25404f);
const Color _kGold = Color(0xffffd36a);
const Color _kGoldDeep = Color(0xffc99b3b);
const Color _kGoldText = Color(0xffffe9ab);
const Color _kInk = Color(0xffeaf0f3);
const Color _kMuted = Color(0xff92a6b1);
const Color _kDark = Color(0xff2a1f00);

/// متن‌های سه‌زبانه‌ی بخش قیمت (سایر زبان‌ها انگلیسی)
const Map<String, Map<String, String>> kPriceTx = {
  'fa': {
    'title': 'جدول قیمت',
    'night': 'تومان / شب',
    'wd': 'میان‌هفته',
    'wdSub': 'شنبه تا چهارشنبه',
    'we': 'آخر هفته',
    'weSub': 'پنجشنبه و جمعه',
    'pk': 'تعطیلات و نوروز',
    'minNights': 'حداقل {n} شب',
    'extra': 'هر نفر اضافه، هر شب',
    'cap': 'ظرفیت {n} نفر',
    'maxCap': 'حداکثر {n} نفر',
    'longDisc': 'تخفیف ۳ شب به بالا {n}٪',
    'calc': 'هزینه اقامت',
    'approx': 'تقریبی',
    'guests': 'تعداد نفرات',
    'nights': 'تعداد شب',
    'total': 'جمع تقریبی',
    'promoApplied': 'آفر {n}٪ اعمال شد',
    'longApplied': 'اقامت طولانی {n}٪ اعمال شد',
    'nightsTimes': '{n} شب × {p}',
    'closed': 'این واحد فعلاً ناموجود است.',
    'peakMin': 'در تعطیلات حداقل {n} شب اقامت لازم است.',
    'note': 'قیمت را صاحب اقامتگاه تعیین می‌کند. رزرو و پرداخت مستقیم با اقامتگاه انجام می‌شود و در برنامه پرداختی وجود ندارد.',
    'off': 'تخفیف',
    'open': 'موجود',
    'closedTag': 'ناموجود',
  },
  'en': {
    'title': 'Price table',
    'night': 'Toman / night',
    'wd': 'Weekdays',
    'wdSub': 'Saturday to Wednesday',
    'we': 'Weekends',
    'weSub': 'Thursday and Friday',
    'pk': 'Holidays & Nowruz',
    'minNights': 'Min. {n} nights',
    'extra': 'Each extra guest, per night',
    'cap': 'Sleeps {n}',
    'maxCap': 'Up to {n} guests',
    'longDisc': '{n}% off for 3+ nights',
    'calc': 'Stay cost',
    'approx': 'estimate',
    'guests': 'Guests',
    'nights': 'Nights',
    'total': 'Estimated total',
    'promoApplied': '{n}% offer applied',
    'longApplied': '{n}% long-stay discount applied',
    'nightsTimes': '{n} nights × {p}',
    'closed': 'This unit is currently unavailable.',
    'peakMin': 'Holidays require at least {n} nights.',
    'note': 'Prices are set by the property owner. Booking and payment are made directly with the property; there is no payment inside the app.',
    'off': 'OFF',
    'open': 'Available',
    'closedTag': 'Unavailable',
  },
  'ar': {
    'title': 'جدول الأسعار',
    'night': 'تومان / ليلة',
    'wd': 'أيام الأسبوع',
    'wdSub': 'من السبت إلى الأربعاء',
    'we': 'نهاية الأسبوع',
    'weSub': 'الخميس والجمعة',
    'pk': 'العطل والنوروز',
    'minNights': 'الحد الأدنى {n} ليالٍ',
    'extra': 'كل شخص إضافي، لكل ليلة',
    'cap': 'سعة {n} أشخاص',
    'maxCap': 'حتى {n} أشخاص',
    'longDisc': 'خصم {n}٪ لـ 3 ليالٍ فأكثر',
    'calc': 'تكلفة الإقامة',
    'approx': 'تقريبية',
    'guests': 'عدد الأشخاص',
    'nights': 'عدد الليالي',
    'total': 'المجموع التقريبي',
    'promoApplied': 'تم تطبيق عرض {n}٪',
    'longApplied': 'تم تطبيق خصم الإقامة الطويلة {n}٪',
    'nightsTimes': '{n} ليالٍ × {p}',
    'closed': 'هذه الوحدة غير متاحة حالياً.',
    'peakMin': 'في العطل يلزم الإقامة {n} ليالٍ على الأقل.',
    'note': 'يحدد صاحب الإقامة الأسعار. الحجز والدفع مباشرة مع الإقامة ولا يوجد دفع داخل التطبيق.',
    'off': 'خصم',
    'open': 'متاح',
    'closedTag': 'غير متاح',
  },
};

String priceTx(String lang, String key, {Map<String, String> args = const {}}) {
  final m = kPriceTx[lang] ?? kPriceTx['en']!;
  var s = m[key] ?? kPriceTx['en']![key] ?? key;
  args.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

// ===================================================================
// ستاره‌ی تخفیف (سمت چپ، زیر فیلم)
// ===================================================================

class PriceBurst extends StatefulWidget {
  const PriceBurst({super.key, required this.promo, required this.lang, this.size = 118});

  final PricePromo promo;
  final String lang;
  final double size;

  @override
  State<PriceBurst> createState() => _PriceBurstState();
}

class _PriceBurstState extends State<PriceBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final still = MediaQuery.of(context).disableAnimations;
    final pct = formatNumber(widget.promo.pct, widget.lang);
    return SizedBox(
      width: s,
      height: s + 16,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: s,
            height: s,
            child: still
                ? CustomPaint(painter: _StarPainter())
                : AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) => Transform.rotate(angle: _c.value * 2 * math.pi, child: CustomPaint(painter: _StarPainter())),
                  ),
          ),
          SizedBox(
            width: s,
            height: s,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$pct٪', style: TextStyle(color: _kDark, fontSize: s * 0.25, fontWeight: FontWeight.w900, height: 1.05)),
                  Text(priceTx(widget.lang, 'off'), style: TextStyle(color: _kDark, fontSize: s * 0.1, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          if (widget.promo.text.trim().isNotEmpty)
            Positioned(
              top: s * 0.82,
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  constraints: BoxConstraints(maxWidth: s * 1.3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kAppBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kGold, width: 1.4),
                  ),
                  child: Text(
                    widget.promo.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kGoldText, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const points = 16;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r * 0.97 : r * 0.8;
      final a = math.pi * i / points - math.pi / 2;
      final p = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, Colors.black, 6, true);
    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), const [Color(0xffffe29a), Color(0xffe0b55a), Color(0xffb9831b)], const [0, 0.55, 1]);
    canvas.drawPath(path, paint);

    // حلقه‌ی خط‌چین داخلی
    final ring = Paint()
      ..color = _kDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final ringPath = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.68));
    for (final m in ringPath.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), ring);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===================================================================
// جدول قیمت + هزینه‌ی اقامت (نمای گردشگر)
// ===================================================================

class PricePackView extends StatefulWidget {
  const PricePackView({super.key, required this.pack, required this.lang});

  final PricePack pack;
  final String lang;

  @override
  State<PricePackView> createState() => _PricePackViewState();
}

class _PricePackViewState extends State<PricePackView> {
  int _u = 0;
  int _guests = 2;
  int _nights = 2;
  PriceDay _day = PriceDay.weekday;

  PricePack get _p => widget.pack;
  String get _lang => widget.lang;
  bool get _rtl => _lang != 'en';

  PriceUnit get _unit {
    if (_u >= _p.units.length) _u = 0;
    return _p.units[_u];
  }

  String _n(int v) => formatNumber(v, _lang);
  String _t(String k, {Map<String, String> a = const {}}) => priceTx(_lang, k, args: a);

  @override
  void initState() {
    super.initState();
    _guests = _unit.base;
  }

  @override
  Widget build(BuildContext context) {
    if (_p.units.isEmpty) return const SizedBox.shrink();
    final u = _unit;
    if (_guests > u.max) _guests = u.max;
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _priceCard(u),
          const SizedBox(height: 12),
          _calcCard(u),
        ]),
      ),
    );
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kLine),
      );

  Widget _priceCard(PriceUnit u) {
    final rows = <List<dynamic>>[
      [_t('wd'), _t('wdSub'), u.wd],
      [_t('we'), _t('weSub'), u.we],
      [_t('pk'), u.minPk > 1 ? _t('minNights', a: {'n': _n(u.minPk)}) : '', u.pk],
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.sell_rounded, color: _kGold, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(_t('title'), style: const TextStyle(color: _kInk, fontSize: 15, fontWeight: FontWeight.w800))),
          _openTag(u.open),
        ]),
        if (_p.units.length > 1) ...[
          const SizedBox(height: 10),
          _unitSwitch(),
        ] else ...[
          const SizedBox(height: 6),
          Text(u.name, style: const TextStyle(color: _kGoldText, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(_t('cap', a: {'n': _n(u.base)})),
          if (u.max > u.base) _chip(_t('maxCap', a: {'n': _n(u.max)})),
          if (u.disc > 0) _chip(_t('longDisc', a: {'n': _n(u.disc)})),
        ]),
        const SizedBox(height: 6),
        for (var i = 0; i < rows.length; i++) _priceRow(rows[i][0] as String, rows[i][1] as String, rows[i][2] as int, i > 0),
        if (u.max > u.base) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Text(_t('extra'), style: const TextStyle(color: _kInk, fontSize: 13))),
              Text('+${_n(_p.afterPromo(u.extra))}', style: const TextStyle(color: _kGoldText, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(width: 4),
              Text(_lang == 'en' ? 'Toman' : (_lang == 'ar' ? 'تومان' : 'تومان'), style: const TextStyle(color: _kMuted, fontSize: 11.5)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _openTag(bool open) {
    final c = open ? const Color(0xff5fd19a) : const Color(0xffff8d85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(open ? _t('open') : _t('closedTag'), style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
        decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: _kInk, fontSize: 12)),
      );

  Widget _unitSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _kAppBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (var i = 0; i < _p.units.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _u = i;
                _guests = _p.units[i].base;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: i == _u ? const LinearGradient(colors: [_kGold, _kGoldDeep]) : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _p.units[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: i == _u ? _kDark : _kMuted, fontSize: 13, fontWeight: i == _u ? FontWeight.w900 : FontWeight.w500),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _priceRow(String label, String sub, int price, bool divider) {
    final promo = _p.promo.active;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: divider ? const Border(top: BorderSide(color: _kLine)) : null),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: _kInk, fontSize: 14, fontWeight: FontWeight.w600)),
            if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: _kMuted, fontSize: 11.5)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (promo) Text(_n(price), style: const TextStyle(color: _kMuted, fontSize: 11.5, decoration: TextDecoration.lineThrough)),
          Text(_n(_p.afterPromo(price)), style: const TextStyle(color: _kGoldText, fontSize: 16.5, fontWeight: FontWeight.w900)),
          Text(_t('night'), style: const TextStyle(color: _kMuted, fontSize: 10.5)),
        ]),
      ]),
    );
  }

  // ---------------- هزینه‌ی اقامت ----------------

  Widget _calcCard(PriceUnit u) {
    final q = _p.quote(u, _guests, _nights, _day);
    final promoOn = _p.promo.active;
    final lines = <Widget>[];
    if (promoOn) {
      lines.add(_totalLine(_t('promoApplied', a: {'n': _n(_p.promo.pct)}), '-${_n(q.promoOff)}'));
    }
    if (q.longOff > 0) lines.add(_totalLine(_t('longApplied', a: {'n': _n(u.disc)}), '-${_n(q.longOff)}'));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.calculate_rounded, color: _kGold, size: 18),
          const SizedBox(width: 6),
          Text(_t('calc'), style: const TextStyle(color: _kInk, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text(_t('approx'), style: const TextStyle(color: _kMuted, fontSize: 11.5)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _stepper(_t('guests'), _guests, () => setState(() => _guests = math.max(1, _guests - 1)), () => setState(() => _guests = math.min(u.max, _guests + 1)))),
          const SizedBox(width: 10),
          Expanded(child: _stepper(_t('nights'), _nights, () => setState(() => _nights = math.max(1, _nights - 1)), () => setState(() => _nights = math.min(30, _nights + 1)))),
        ]),
        const SizedBox(height: 10),
        _daySwitch(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGold.withValues(alpha: 0.4)),
            gradient: LinearGradient(colors: [_kGold.withValues(alpha: 0.16), _kGoldDeep.withValues(alpha: 0.05)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _totalLine(_t('nightsTimes', a: {'n': _n(_nights), 'p': _n(q.perNight)}), _n(q.subtotal)),
            ...lines,
            const Divider(color: _kLine, height: 14),
            Row(children: [
              Expanded(child: Text(_t('total'), style: const TextStyle(color: _kInk, fontWeight: FontWeight.w800))),
              Text(_n(q.total), style: const TextStyle(color: _kGoldText, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              const Text('تومان', style: TextStyle(color: _kMuted, fontSize: 11.5)),
            ]),
          ]),
        ),
        if (!u.open) _warn(_t('closed')),
        if (_day == PriceDay.peak && _nights < u.minPk) _warn(_t('peakMin', a: {'n': _n(u.minPk)})),
        const SizedBox(height: 10),
        Text(_t('note'), style: const TextStyle(color: _kMuted, fontSize: 11.5, height: 1.8)),
      ]),
    );
  }

  Widget _totalLine(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(a, style: const TextStyle(color: _kMuted, fontSize: 12.5))),
          Text(b, style: const TextStyle(color: _kInk, fontSize: 13)),
        ]),
      );

  Widget _warn(String t) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xff3a2a10), borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(color: Color(0xfff0b35a), fontSize: 12.5)),
      );

  Widget _stepper(String label, int v, VoidCallback minus, VoidCallback plus) {
    Widget btn(IconData i, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(9)),
            child: Icon(i, color: _kInk, size: 18),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _kMuted, fontSize: 12)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: _kAppBg, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          btn(Icons.remove_rounded, minus),
          Text(_n(v), style: const TextStyle(color: _kInk, fontSize: 15, fontWeight: FontWeight.w800)),
          btn(Icons.add_rounded, plus),
        ]),
      ),
    ]);
  }

  Widget _daySwitch() {
    final items = <List<dynamic>>[
      [PriceDay.weekday, _t('wd')],
      [PriceDay.weekend, _t('we')],
      [PriceDay.peak, _t('pk')],
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _kAppBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _day = it[0] as PriceDay),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  gradient: _day == it[0] ? const LinearGradient(colors: [_kGold, _kGoldDeep]) : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  it[1] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _day == it[0] ? _kDark : _kMuted, fontSize: 12, fontWeight: _day == it[0] ? FontWeight.w900 : FontWeight.w500),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
