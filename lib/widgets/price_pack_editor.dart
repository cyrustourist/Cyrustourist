import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/price_pack.dart';
import 'price_pack_view.dart';

const Color _ink = Color(0xff202936);
const Color _soft = Color(0xff687482);
const Color _teal = Color(0xff11998e);
const Color _gold = Color(0xffc88a14);
const Color _line = Color(0xffe0e8ec);
const Color _err = Color(0xffc0392b);
const Color _bgField = Color(0xfff7f9fa);

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'unit': 'واحد',
    'add': 'افزودن واحد',
    'del': 'حذف این واحد',
    'name': 'نام واحد (مثلاً ویلای ۴ نفره)',
    'prices': 'قیمت هر شب (تومان)',
    'wd': 'میان‌هفته (شنبه تا چهارشنبه)',
    'we': 'آخر هفته (پنجشنبه و جمعه)',
    'pk': 'تعطیلات و نوروز',
    'extra': 'هر نفر اضافه، هر شب (+)',
    'cap': 'ظرفیت و شرایط',
    'base': 'ظرفیت پایه (قیمت برای این تعداد)',
    'max': 'حداکثر ظرفیت',
    'minPk': 'حداقل شب در تعطیلات',
    'disc': 'تخفیف ۳ شب به بالا (٪)',
    'open': 'موجود برای رزرو',
    'example': 'مثال: ظرفیت پایه ۴ نفر و «هر نفر اضافه ۴۵۰٬۰۰۰ تومان» یعنی برای ۶ نفر، ۲ × ۴۵۰٬۰۰۰ تومان به قیمت هر شب اضافه می‌شود.',
    'promo': 'آفر و هدیه تخفیف',
    'promoOn': 'آفر روشن باشد',
    'pct': 'درصد تخفیف',
    'text': 'متن کوتاه آفر',
    'textHint': 'مثلاً جشنواره پاییزی',
    'preview': 'این‌طور زیر فیلم نمایش داده می‌شود',
    'e_units': 'حداقل یک واحد لازم است.',
    'e_name': 'نام هر واحد را وارد کنید.',
    'e_cap': 'ظرفیت پایه و حداکثر ظرفیت را درست وارد کنید.',
    'e_price': 'قیمت میان‌هفته، آخر هفته و تعطیلات را وارد کنید (حداقل ۱٬۰۰۰ تومان).',
    'e_extra': 'برای نفر اضافه قیمت بگذارید.',
    'e_minPk': 'حداقل شب تعطیلات باید بین ۱ تا ۳۰ باشد.',
    'e_disc': 'تخفیف باید بین ۰ تا ۵۰ باشد.',
    'e_promo': 'درصد آفر ۱ تا ۷۰ و یک متن کوتاه لازم است.',
    'sug1': 'جشنواره پاییزی',
    'sug2': 'آفر نوروزی',
    'sug3': 'تخفیف ویژه آخر هفته',
    'sug4': 'هدیه سایروس توریست',
  },
  'en': {
    'unit': 'Unit',
    'add': 'Add unit',
    'del': 'Delete this unit',
    'name': 'Unit name (e.g. 4-person villa)',
    'prices': 'Price per night (Toman)',
    'wd': 'Weekdays (Sat to Wed)',
    'we': 'Weekends (Thu and Fri)',
    'pk': 'Holidays & Nowruz',
    'extra': 'Each extra guest, per night (+)',
    'cap': 'Capacity and terms',
    'base': 'Base capacity (price covers this many)',
    'max': 'Maximum capacity',
    'minPk': 'Min. nights on holidays',
    'disc': '3+ nights discount (%)',
    'open': 'Available for booking',
    'example': 'Example: base capacity 4 and "extra guest 450,000 Toman" means 6 guests add 2 × 450,000 Toman to the nightly price.',
    'promo': 'Offer and discount gift',
    'promoOn': 'Offer is on',
    'pct': 'Discount percent',
    'text': 'Short offer text',
    'textHint': 'e.g. Autumn festival',
    'preview': 'This is how it appears under the video',
    'e_units': 'At least one unit is required.',
    'e_name': 'Enter a name for every unit.',
    'e_cap': 'Check base and maximum capacity.',
    'e_price': 'Enter weekday, weekend and holiday prices (at least 1,000 Toman).',
    'e_extra': 'Set a price for extra guests.',
    'e_minPk': 'Minimum holiday nights must be 1 to 30.',
    'e_disc': 'Discount must be 0 to 50.',
    'e_promo': 'The offer needs 1 to 70 percent and a short text.',
    'sug1': 'Autumn festival',
    'sug2': 'Nowruz offer',
    'sug3': 'Weekend special',
    'sug4': 'Cyrus Tourist gift',
  },
  'ar': {
    'unit': 'وحدة',
    'add': 'إضافة وحدة',
    'del': 'حذف هذه الوحدة',
    'name': 'اسم الوحدة (مثلاً فيلا لـ 4 أشخاص)',
    'prices': 'السعر لكل ليلة (تومان)',
    'wd': 'أيام الأسبوع (السبت إلى الأربعاء)',
    'we': 'نهاية الأسبوع (الخميس والجمعة)',
    'pk': 'العطل والنوروز',
    'extra': 'كل شخص إضافي، لكل ليلة (+)',
    'cap': 'السعة والشروط',
    'base': 'السعة الأساسية (السعر لهذا العدد)',
    'max': 'السعة القصوى',
    'minPk': 'الحد الأدنى لليالي العطل',
    'disc': 'خصم 3 ليالٍ فأكثر (٪)',
    'open': 'متاح للحجز',
    'example': 'مثال: السعة الأساسية 4 وسعر الشخص الإضافي 450٬000 تومان، فلـ 6 أشخاص يضاف 2 × 450٬000 تومان إلى سعر الليلة.',
    'promo': 'العرض وهدية الخصم',
    'promoOn': 'تفعيل العرض',
    'pct': 'نسبة الخصم',
    'text': 'نص قصير للعرض',
    'textHint': 'مثلاً مهرجان الخريف',
    'preview': 'هكذا يظهر تحت الفيديو',
    'e_units': 'يلزم وحدة واحدة على الأقل.',
    'e_name': 'أدخل اسماً لكل وحدة.',
    'e_cap': 'تحقق من السعة الأساسية والقصوى.',
    'e_price': 'أدخل أسعار أيام الأسبوع ونهاية الأسبوع والعطل (1٬000 تومان على الأقل).',
    'e_extra': 'حدد سعراً للشخص الإضافي.',
    'e_minPk': 'الحد الأدنى لليالي العطل بين 1 و30.',
    'e_disc': 'الخصم بين 0 و50.',
    'e_promo': 'العرض يحتاج نسبة من 1 إلى 70 ونصاً قصيراً.',
    'sug1': 'مهرجان الخريف',
    'sug2': 'عرض النوروز',
    'sug3': 'عرض نهاية الأسبوع',
    'sug4': 'هدية سايروس توريست',
  },
};

String _ascii(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(r - 0x06F0 + 48);
    } else if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(r - 0x0660 + 48);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

class _NumFormatter extends TextInputFormatter {
  const _NumFormatter({this.group = false, this.maxDigits = 10});

  final bool group;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = _ascii(newValue.text).replaceAll(RegExp(r'[^\d]'), '');
    if (d.length > maxDigits) d = d.substring(0, maxDigits);
    var out = d;
    if (group && d.length > 3) {
      final b = StringBuffer();
      for (var i = 0; i < d.length; i++) {
        if (i > 0 && (d.length - i) % 3 == 0) b.write(',');
        b.write(d[i]);
      }
      out = b.toString();
    }
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

int _parse(String s) => int.tryParse(_ascii(s).replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

/// متن دقیق خطای پک قیمت: نام/شمارهٔ واحد + همان فیلدی که ایراد دارد (خالی = بدون خطا)
String pricePackErrorText(PricePack p, String lang) {
  final e = p.error;
  if (e == null) return '';
  final m = _tx[lang] ?? _tx['en']!;
  String t(String k) => m[k] ?? _tx['en']![k] ?? k;
  if (e == 'promo') return t('e_promo');
  if (e == 'units') return t('e_units');
  final i = p.errorUnit;
  var prefix = '';
  if (i >= 0) {
    final nm = p.units[i].name.trim();
    prefix = '${t('unit')} ${i + 1}${nm.isEmpty ? '' : ' ($nm)'}: ';
  }
  return '$prefix${t('e_$e')}';
}

String _group(int n) {
  if (n <= 0) return '';
  final d = '$n';
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(',');
    b.write(d[i]);
  }
  return b.toString();
}

/// ویرایشگر پک قیمت و آفر (فرم ثبت‌نام و صفحه‌ی ویرایش قیمت).
/// هر تغییر یک نسخه‌ی تازه از پک را از طریق [onChanged] می‌فرستد.
class PricePackEditor extends StatefulWidget {
  const PricePackEditor({super.key, required this.initial, required this.onChanged, required this.lang, this.showErrors = false, this.focusTick = 0});

  final PricePack initial;
  final ValueChanged<PricePack> onChanged;
  final String lang;
  final bool showErrors;

  /// با هر بار شکست اعتبارسنجی یکی زیاد می‌شود تا ویرایشگر به واحدِ دارای خطا برود
  final int focusTick;

  @override
  State<PricePackEditor> createState() => _PricePackEditorState();
}

class _PricePackEditorState extends State<PricePackEditor> {
  late PricePack _p;
  int _sel = 0;
  final Map<String, Map<String, TextEditingController>> _ctl = {};
  late final TextEditingController _pct;
  late final TextEditingController _promoText;

  String _t(String k) => (_tx[widget.lang] ?? _tx['en']!)[k] ?? _tx['en']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _p = widget.initial.copy();
    if (_p.units.isEmpty) _p.units.add(PriceUnit(id: 'u1'));
    _pct = TextEditingController(text: '${_p.promo.pct}');
    _promoText = TextEditingController(text: _p.promo.text);
  }

  @override
  void dispose() {
    for (final m in _ctl.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _pct.dispose();
    _promoText.dispose();
    super.dispose();
  }

  Map<String, TextEditingController> _ctlFor(PriceUnit u) {
    return _ctl.putIfAbsent(u.id, () {
      return {
        'name': TextEditingController(text: u.name),
        'wd': TextEditingController(text: _group(u.wd)),
        'we': TextEditingController(text: _group(u.we)),
        'pk': TextEditingController(text: _group(u.pk)),
        'extra': TextEditingController(text: _group(u.extra)),
        'base': TextEditingController(text: '${u.base}'),
        'max': TextEditingController(text: '${u.max}'),
        'minPk': TextEditingController(text: '${u.minPk}'),
        'disc': TextEditingController(text: '${u.disc}'),
      };
    });
  }

  void _emit() => widget.onChanged(_p.copy());

  void _addUnit() {
    if (_p.units.length >= 6) return;
    var n = _p.units.length + 1;
    while (_p.units.any((u) => u.id == 'u$n')) {
      n++;
    }
    setState(() {
      _p.units.add(PriceUnit(id: 'u$n'));
      _sel = _p.units.length - 1;
    });
    _emit();
  }

  void _delUnit() {
    if (_p.units.length < 2) return;
    final u = _p.units[_sel];
    final m = _ctl.remove(u.id);
    if (m != null) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    setState(() {
      _p.units.removeAt(_sel);
      _sel = 0;
    });
    _emit();
  }

  @override
  void didUpdateWidget(covariant PricePackEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTick != oldWidget.focusTick) {
      final i = _p.errorUnit;
      if (i >= 0 && i < _p.units.length && i != _sel) setState(() => _sel = i);
    }
  }

  String _errText() => pricePackErrorText(_p, widget.lang);

  @override
  Widget build(BuildContext context) {
    if (_sel >= _p.units.length) _sel = 0;
    final u = _p.units[_sel];
    final c = _ctlFor(u);
    final err = widget.showErrors ? _errText() : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (var i = 0; i < _p.units.length; i++)
          _pill(_p.units[i].name.trim().isEmpty ? '${_t('unit')} ${i + 1}' : _p.units[i].name.trim(), i == _sel, () => setState(() => _sel = i)),
        if (_p.units.length < 6) _pill('+ ${_t('add')}', false, _addUnit, dashed: true),
      ]),
      const SizedBox(height: 12),
      _field(c['name']!, _t('name'), (v) {
        u.name = v;
        setState(() {});
        _emit();
      }, text: true, maxLength: 40),
      _sec(_t('prices')),
      _money(c['wd']!, _t('wd'), (v) => u.wd = v),
      _money(c['we']!, _t('we'), (v) => u.we = v),
      _money(c['pk']!, _t('pk'), (v) => u.pk = v),
      _money(c['extra']!, _t('extra'), (v) => u.extra = v),
      _sec(_t('cap')),
      Row(children: [
        Expanded(child: _num(c['base']!, _t('base'), (v) => u.base = v)),
        const SizedBox(width: 10),
        Expanded(child: _num(c['max']!, _t('max'), (v) => u.max = v)),
      ]),
      Row(children: [
        Expanded(child: _num(c['minPk']!, _t('minPk'), (v) => u.minPk = v)),
        const SizedBox(width: 10),
        Expanded(child: _num(c['disc']!, _t('disc'), (v) => u.disc = v)),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: _teal,
        title: Text(_t('open'), style: const TextStyle(color: _ink, fontSize: 13.5)),
        value: u.open,
        onChanged: (v) {
          setState(() => u.open = v);
          _emit();
        },
      ),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xfffff6df), borderRadius: BorderRadius.circular(10)),
        child: Text(_t('example'), style: const TextStyle(color: Color(0xff7a5200), fontSize: 12, height: 1.8)),
      ),
      if (_p.units.length > 1) ...[
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _delUnit,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _err),
            label: Text(_t('del'), style: const TextStyle(color: _err)),
          ),
        ),
      ],
      const Divider(height: 28, color: _line),
      _promoBox(),
      if (err.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(err, style: const TextStyle(color: _err, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  // ---------------- آفر ----------------

  Widget _promoBox() {
    final pr = _p.promo;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Icon(Icons.card_giftcard_rounded, color: _gold, size: 20),
        const SizedBox(width: 6),
        Expanded(child: Text(_t('promo'), style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w900))),
        Switch(
          value: pr.on,
          activeColor: _teal,
          onChanged: (v) {
            setState(() => pr.on = v);
            _emit();
          },
        ),
      ]),
      if (pr.on) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in const [10, 15, 20, 30])
            _pill('${n}٪', pr.pct == n, () {
              setState(() {
                pr.pct = n;
                _pct.text = '$n';
              });
              _emit();
            }),
        ]),
        const SizedBox(height: 10),
        _field(_pct, _t('pct'), (v) {
          setState(() => pr.pct = _parse(v));
          _emit();
        }, formatters: const [_NumFormatter(maxDigits: 2)], keyboard: TextInputType.number),
        _field(_promoText, _t('text'), (v) {
          setState(() => pr.text = v);
          _emit();
        }, text: true, maxLength: 28, hint: _t('textHint')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in const ['sug1', 'sug2', 'sug3', 'sug4'])
            _pill(_t(k), pr.text == _t(k), () {
              setState(() {
                pr.text = _t(k);
                _promoText.text = _t(k);
              });
              _emit();
            }),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xff0b2636), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            if (pr.active) PriceBurst(promo: pr, lang: widget.lang, size: 100) else const SizedBox(height: 10),
            const SizedBox(height: 4),
            Text(_t('preview'), style: const TextStyle(color: Color(0xff92a6b1), fontSize: 11.5)),
          ]),
        ),
      ],
    ]);
  }

  // ---------------- اجزای فرم ----------------

  Widget _pill(String text, bool on, VoidCallback tap, {bool dashed = false}) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: on ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _teal : (dashed ? _soft : _line)),
        ),
        child: Text(text, style: TextStyle(color: on ? Colors.white : _ink, fontSize: 13, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
      ),
    );
  }

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Text(t, style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w900)),
      );

  Widget _money(TextEditingController c, String label, void Function(int) set) {
    return _field(c, label, (v) {
      set(_parse(v));
      setState(() {});
      _emit();
    }, formatters: const [_NumFormatter(group: true)], keyboard: TextInputType.number, suffix: 'تومان');
  }

  Widget _num(TextEditingController c, String label, void Function(int) set) {
    return _field(c, label, (v) {
      set(_parse(v));
      setState(() {});
      _emit();
    }, formatters: const [_NumFormatter(maxDigits: 3)], keyboard: TextInputType.number);
  }

  Widget _field(
    TextEditingController c,
    String label,
    ValueChanged<String> onChanged, {
    bool text = false,
    int? maxLength,
    String? hint,
    String? suffix,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _soft, fontSize: 12.5)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          onChanged: onChanged,
          maxLength: maxLength,
          keyboardType: text ? TextInputType.text : (keyboard ?? TextInputType.number),
          inputFormatters: formatters,
          textDirection: text ? null : TextDirection.ltr,
          textAlign: text ? TextAlign.start : TextAlign.left,
          style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            suffixText: suffix,
            isDense: true,
            filled: true,
            fillColor: _bgField,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.6)),
          ),
        ),
      ]),
    );
  }
}
