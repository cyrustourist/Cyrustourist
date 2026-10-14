import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../models/price_pack.dart';
import '../services/badge_service.dart';
import '../widgets/price_pack_editor.dart';
import 'stay_registration_page.dart' show showStayCaptcha;

const Color _bg = Color(0xfff3f6f7);
const Color _bar = Color(0xff0b6e69);
const Color _ink = Color(0xff202936);
const Color _soft = Color(0xff687482);
const Color _teal = Color(0xff11998e);
const Color _line = Color(0xffe0e8ec);

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'ویرایش جدول قیمت و آفر',
    'loading': 'در حال دریافت…',
    'retry': 'تلاش دوباره',
    'netErr': 'ارتباط با سرور برقرار نشد.',
    'left': 'امروز {n} از {m} انتشار فوری باقی مانده است. تغییرات بلافاصله و بدون نیاز به تأیید پشتیبانی در اپ نمایش داده می‌شود.',
    'none': 'سهمیهٔ انتشار فوری امروز تمام شد. ویرایش بعدی در صف تأیید ناظر قرار می‌گیرد و پس از تأیید نمایش داده می‌شود.',
    'queued': 'یک ویرایش قیمت شما در انتظار تأیید ناظر است.',
    'publish': 'انتشار فوری',
    'sendReview': 'ارسال برای تأیید ناظر',
    'sending': 'در حال ارسال…',
    'okPub': 'قیمت‌ها منتشر شد.',
    'okQueue': 'ویرایش شما ثبت شد و پس از تأیید ناظر منتشر می‌شود.',
    'notPublished': 'ابتدا باید ثبت‌نام اقامتگاه توسط پشتیبانی تأیید شود.',
    'needFix': 'موارد جدول را اصلاح کنید.',
    'hint': 'هر بار انتشار، یک پازل ساده برای تأیید انسانی دارد.',
    'only': 'فقط همین جدول قیمت و آفر، روزی ۳ بار بدون تأیید ناظر مستقیم منتشر می‌شود. سایر بخش‌های اقامتگاه پس از بررسی پشتیبانی تغییر می‌کند.',
    'chTitle': 'تغییرات جدید (سبز)',
    'chNone': 'هنوز تغییری نسبت به قیمت منتشرشده ندارید.',
    'chNew': 'واحد جدید',
    'chGone': 'واحد حذف شد',
    'f_name': 'نام',
    'f_wd': 'میان‌هفته',
    'f_we': 'آخر هفته',
    'f_pk': 'تعطیلات',
    'f_extra': 'نفر اضافه (+)',
    'f_base': 'ظرفیت پایه',
    'f_max': 'حداکثر ظرفیت',
    'f_minPk': 'حداقل شب تعطیلات',
    'f_disc': 'تخفیف ۳ شب به بالا',
    'f_open': 'وضعیت',
    'f_on': 'آفر',
    'f_pct': 'درصد تخفیف',
    'f_text': 'متن آفر',
    'v_open': 'موجود',
    'v_closed': 'ناموجود',
    'v_on': 'روشن',
    'v_off': 'خاموش',
    'promoRow': 'آفر و هدیه',
  },
  'en': {
    'title': 'Edit price table and offer',
    'loading': 'Loading…',
    'retry': 'Try again',
    'netErr': 'Could not reach the server.',
    'left': 'You have {n} of {m} instant publishes left today. Changes appear in the app immediately, without support approval.',
    'none': 'Today\'s instant publishes are used up. The next edit goes to the moderator queue and appears after approval.',
    'queued': 'One of your price edits is waiting for moderator approval.',
    'publish': 'Publish now',
    'sendReview': 'Send for moderator approval',
    'sending': 'Sending…',
    'okPub': 'Prices published.',
    'okQueue': 'Your edit was recorded and will be published after moderator approval.',
    'notPublished': 'The property registration must be approved by support first.',
    'needFix': 'Please fix the highlighted items.',
    'hint': 'Each publish asks for a quick puzzle to confirm you are human.',
    'only': 'Only this price and offer table is published directly, 3 times a day, without moderator approval. Other property details change after support review.',
    'chTitle': 'New changes (green)',
    'chNone': 'No changes compared with the published prices.',
    'chNew': 'New unit',
    'chGone': 'Unit removed',
    'f_name': 'Name',
    'f_wd': 'Weekdays',
    'f_we': 'Weekends',
    'f_pk': 'Holidays',
    'f_extra': 'Extra guest (+)',
    'f_base': 'Base capacity',
    'f_max': 'Max capacity',
    'f_minPk': 'Min. holiday nights',
    'f_disc': '3+ nights discount',
    'f_open': 'Status',
    'f_on': 'Offer',
    'f_pct': 'Discount percent',
    'f_text': 'Offer text',
    'v_open': 'Available',
    'v_closed': 'Unavailable',
    'v_on': 'On',
    'v_off': 'Off',
    'promoRow': 'Offer and gift',
  },
  'ar': {
    'title': 'تعديل جدول الأسعار والعرض',
    'loading': 'جارٍ التحميل…',
    'retry': 'حاول مجدداً',
    'netErr': 'تعذر الاتصال بالخادم.',
    'left': 'بقي لك {n} من {m} نشر فوري اليوم. تظهر التغييرات في التطبيق فوراً دون موافقة الدعم.',
    'none': 'انتهت مرات النشر الفوري اليوم. التعديل التالي يذهب إلى طابور المشرف ويظهر بعد الموافقة.',
    'queued': 'أحد تعديلات الأسعار بانتظار موافقة المشرف.',
    'publish': 'انشر الآن',
    'sendReview': 'إرسال لموافقة المشرف',
    'sending': 'جارٍ الإرسال…',
    'okPub': 'تم نشر الأسعار.',
    'okQueue': 'تم تسجيل تعديلك وسيُنشر بعد موافقة المشرف.',
    'notPublished': 'يجب أن يوافق الدعم على تسجيل الإقامة أولاً.',
    'needFix': 'يرجى تصحيح العناصر المحددة.',
    'hint': 'يطلب كل نشر أحجية بسيطة للتأكد أنك إنسان.',
    'only': 'هذا الجدول فقط (الأسعار والعرض) يُنشر مباشرة 3 مرات في اليوم دون موافقة المشرف. تتغير بقية بيانات الإقامة بعد مراجعة الدعم.',
    'chTitle': 'التغييرات الجديدة (أخضر)',
    'chNone': 'لا تغييرات مقارنة بالأسعار المنشورة.',
    'chNew': 'وحدة جديدة',
    'chGone': 'تم حذف الوحدة',
    'f_name': 'الاسم',
    'f_wd': 'أيام الأسبوع',
    'f_we': 'نهاية الأسبوع',
    'f_pk': 'العطل',
    'f_extra': 'شخص إضافي (+)',
    'f_base': 'السعة الأساسية',
    'f_max': 'السعة القصوى',
    'f_minPk': 'الحد الأدنى لليالي العطل',
    'f_disc': 'خصم 3 ليالٍ فأكثر',
    'f_open': 'الحالة',
    'f_on': 'العرض',
    'f_pct': 'نسبة الخصم',
    'f_text': 'نص العرض',
    'v_open': 'متاح',
    'v_closed': 'غير متاح',
    'v_on': 'مفعّل',
    'v_off': 'متوقف',
    'promoRow': 'العرض والهدية',
  },
};

/// ویرایش جدول قیمت و آفر پس از تأیید اقامتگاه:
/// با پازل ضد ربات؛ روزی ۳ بار مستقیم منتشر می‌شود، بار چهارم در صف ناظر.
class PricePackEditPage extends StatefulWidget {
  const PricePackEditPage({super.key, required this.accommodationId, this.name = ''});

  final int accommodationId;
  final String name;

  @override
  State<PricePackEditPage> createState() => _PricePackEditPageState();
}

class _PricePackEditPageState extends State<PricePackEditPage> {
  bool _loading = true;
  bool _busy = false;
  bool _showErr = false;
  String _loadError = '';
  PricePack _pack = PricePack.empty();
  PricePack _initial = PricePack.empty();
  int _limit = 3;
  int _remaining = 3;
  bool _queued = false;

  String get _lang => MenuLanguage.current == 'fa' || MenuLanguage.current == 'ar' ? MenuLanguage.current : 'en';
  bool get _rtl => _lang != 'en';

  String _t(String k, {Map<String, String> a = const {}}) {
    final m = _tx[_lang] ?? _tx['en']!;
    var s = m[k] ?? _tx['en']![k] ?? k;
    a.forEach((x, v) => s = s.replaceAll('{$x}', v));
    return s;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = '';
    });
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/stay-reg/price', query: {'user_uid': uid, 'id': '${widget.accommodationId}'});
    if (!mounted) return;
    if (j == null || j['success'] != true) {
      setState(() {
        _loading = false;
        _loadError = '${j?['message'] ?? _t('netErr')}';
      });
      return;
    }
    final p = PricePack.tryParse(j['price_pack']);
    setState(() {
      _loading = false;
      _initial = p ?? PricePack.empty();
      _pack = _initial.copy();
      _limit = int.tryParse('${j['limit']}') ?? 3;
      _remaining = int.tryParse('${j['remaining']}') ?? 0;
      _queued = j['queued'] == true;
      if (j['published'] != true) _loadError = _t('notPublished');
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _publish() async {
    if (_busy) return;
    if (!_pack.isValid) {
      setState(() => _showErr = true);
      _snack(_t('needFix'));
      return;
    }
    for (var attempt = 0; attempt < 4; attempt++) {
      final cap = await showStayCaptcha(context);
      if (cap == null || !mounted) return;
      setState(() => _busy = true);
      final uid = await BadgeService.userUid();
      final body = <String, dynamic>{
        'user_uid': uid,
        'id': widget.accommodationId,
        'hp': '',
        'price_pack': _pack.toJson(),
        ...cap,
      };
      final j = await BadgeService.call('POST', '/api/stay-reg/price', body: body);
      if (!mounted) return;
      setState(() => _busy = false);
      if (j == null) return _snack(_t('netErr'));
      if (j['success'] == true) {
        final published = j['published'] == true;
        setState(() {
          _remaining = int.tryParse('${j['remaining']}') ?? 0;
          _queued = !published;
          if (published) {
            _initial = _pack.copy();
          }
        });
        _snack(published ? _t('okPub') : _t('okQueue'));
        return;
      }
      final code = '${j['error'] ?? ''}';
      _snack('${j['message'] ?? _t('netErr')}');
      if (!code.startsWith('captcha_')) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bar,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_t('title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: _teal),
        const SizedBox(height: 12),
        Text(_t('loading'), style: const TextStyle(color: _soft)),
      ]));
    }
    final blocked = _loadError.isNotEmpty;
    if (blocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_loadError, textAlign: TextAlign.center, style: const TextStyle(color: _ink, height: 1.9)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(_t('retry'))),
          ]),
        ),
      );
    }
    final canDirect = _remaining > 0;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 28), children: [
      if (widget.name.trim().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.name.trim(), style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      _banner(
        canDirect ? _t('left', a: {'n': formatNumber(_remaining, _lang), 'm': formatNumber(_limit, _lang)}) : _t('none'),
        canDirect ? const Color(0xffeafaf1) : const Color(0xfffff3d6),
        canDirect ? const Color(0xff176b43) : const Color(0xffb45309),
        canDirect ? Icons.bolt_rounded : Icons.hourglass_top_rounded,
      ),
      if (_queued) ...[
        const SizedBox(height: 8),
        _banner(_t('queued'), const Color(0xffe6f1ff), const Color(0xff1d5fb4), Icons.schedule_rounded),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: PricePackEditor(
          initial: _initial,
          lang: _lang,
          showErrors: _showErr,
          onChanged: (p) => setState(() => _pack = p),
        ),
      ),
      const SizedBox(height: 12),
      _changesCard(),
      const SizedBox(height: 10),
      Text(_t('hint'), style: const TextStyle(color: _soft, fontSize: 12, height: 1.8)),
      const SizedBox(height: 10),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _busy ? null : _publish,
          style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(_busy ? _t('sending') : (canDirect ? _t('publish') : _t('sendReview')), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    ]);
  }

  // ---------------- جدول تغییرات جدید (سبز) ----------------

  String _num(int v) => formatNumber(v, _lang);

  /// هر ردیف: [برچسب، مقدار قبلی، مقدار جدید]
  List<List<String>> _diff() {
    final out = <List<String>>[];
    final old = {for (final u in _initial.units) u.id: u};
    for (final u in _pack.units) {
      final o = old[u.id];
      final nm = u.name.trim().isEmpty ? '—' : u.name.trim();
      if (o == null) {
        out.add([nm, '', _t('chNew')]);
        continue;
      }
      void chk(String key, String a, String b) {
        if (a != b) out.add(['$nm · ${_t('f_$key')}', a, b]);
      }
      chk('name', o.name.trim(), u.name.trim());
      chk('wd', _num(o.wd), _num(u.wd));
      chk('we', _num(o.we), _num(u.we));
      chk('pk', _num(o.pk), _num(u.pk));
      chk('extra', _num(o.extra), _num(u.extra));
      chk('base', _num(o.base), _num(u.base));
      chk('max', _num(o.max), _num(u.max));
      chk('minPk', _num(o.minPk), _num(u.minPk));
      chk('disc', '${_num(o.disc)}٪', '${_num(u.disc)}٪');
      chk('open', o.open ? _t('v_open') : _t('v_closed'), u.open ? _t('v_open') : _t('v_closed'));
    }
    for (final o in _initial.units) {
      if (!_pack.units.any((u) => u.id == o.id)) out.add([o.name.trim(), '', _t('chGone')]);
    }
    final a = _initial.promo, b = _pack.promo;
    final pr = _t('promoRow');
    if (a.on != b.on) out.add(['$pr · ${_t('f_on')}', a.on ? _t('v_on') : _t('v_off'), b.on ? _t('v_on') : _t('v_off')]);
    if (b.on || a.on) {
      if (a.pct != b.pct) out.add(['$pr · ${_t('f_pct')}', '${_num(a.pct)}٪', '${_num(b.pct)}٪']);
      if (a.text.trim() != b.text.trim()) out.add(['$pr · ${_t('f_text')}', a.text.trim(), b.text.trim()]);
    }
    return out;
  }

  Widget _changesCard() {
    const green = Color(0xff176b43);
    const greenBg = Color(0xffeafaf1);
    final rows = _diff();
    return Container(
      decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xff9ad8b6))),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.compare_arrows_rounded, color: green, size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(_t('chTitle'), style: const TextStyle(color: green, fontSize: 14, fontWeight: FontWeight.w900))),
          if (rows.isNotEmpty) Text(_num(rows.length), style: const TextStyle(color: green, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Text(_t('chNone'), style: const TextStyle(color: _soft, fontSize: 12.5, height: 1.8))
        else
          for (final r in rows)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Text(r[0], style: const TextStyle(color: _ink, fontSize: 12.5))),
                if (r[1].isNotEmpty) ...[
                  Text(r[1], style: const TextStyle(color: _soft, fontSize: 12, decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: green),
                  const SizedBox(width: 6),
                ],
                Text(r[2], style: const TextStyle(color: green, fontSize: 13.5, fontWeight: FontWeight.w900)),
              ]),
            ),
        const SizedBox(height: 8),
        Text(_t('only'), style: const TextStyle(color: _soft, fontSize: 11, height: 1.8)),
      ]),
    );
  }

  Widget _banner(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 13, height: 1.8, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
