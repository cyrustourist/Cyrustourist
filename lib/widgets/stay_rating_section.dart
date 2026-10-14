import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/badge_service.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _cardSoft = Color(0xff0e2f43);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

/// متن‌های پیش‌فرض؛ هر متن نماینده‌ی یک ستاره است (۱ تا ۵).
/// کلید هر متن (r1..r5) همراه امتیاز در سرور ذخیره می‌شود.
const Map<String, List<String>> _kPresetTexts = {
  'fa': [
    'ضعیف بود؛ توصیه نمی‌کنم',
    'کمتر از انتظارم بود',
    'متوسط بود؛ قابل قبول',
    'خوب بود؛ راضی بودم',
    'عالی بود؛ حتماً پیشنهاد می‌کنم',
  ],
  'en': [
    'Poor — I would not recommend it',
    'Below my expectations',
    'Average — acceptable',
    'Good — I was satisfied',
    'Excellent — highly recommended',
  ],
  'ar': [
    'سيئ — لا أنصح به',
    'أقل من توقعاتي',
    'متوسط — مقبول',
    'جيد — كنت راضياً',
    'ممتاز — أنصح به بشدة',
  ],
};

const Map<String, Map<String, String>> _kTx = {
  'fa': {
    'title': 'به این مکان ستاره بدهید',
    'hint': 'روی ستاره بزنید یا یکی از متن‌ها را انتخاب کنید',
    'submit': 'ثبت امتیاز',
    'update': 'ویرایش امتیاز من',
    'thanks': 'امتیاز شما ثبت شد. سپاسگزاریم!',
    'pick': 'ابتدا یک ستاره انتخاب کنید',
    'votes': 'رأی',
    'noVotes': 'هنوز امتیازی ثبت نشده؛ اولین نفر باشید',
    'net': 'ارتباط با سرور برقرار نشد',
    'yours': 'امتیاز شما',
  },
  'en': {
    'title': 'Rate this place',
    'hint': 'Tap a star or choose one of the sentences',
    'submit': 'Submit rating',
    'update': 'Update my rating',
    'thanks': 'Your rating was saved. Thank you!',
    'pick': 'Please pick a star first',
    'votes': 'ratings',
    'noVotes': 'No ratings yet — be the first',
    'net': 'Could not reach the server',
    'yours': 'Your rating',
  },
  'ar': {
    'title': 'قيّم هذا المكان',
    'hint': 'اضغط على نجمة أو اختر إحدى العبارات',
    'submit': 'إرسال التقييم',
    'update': 'تعديل تقييمي',
    'thanks': 'تم حفظ تقييمك. شكراً لك!',
    'pick': 'اختر نجمة أولاً',
    'votes': 'تقييم',
    'noVotes': 'لا توجد تقييمات بعد — كن الأول',
    'net': 'تعذر الاتصال بالخادم',
    'yours': 'تقييمك',
  },
};

/// ===============================================================
/// بخش «ستاره دادن» برای صفحه‌ی جزئیات اقامتگاه / مرکز سلامت
/// ---------------------------------------------------------------
/// - میانگین و تعداد رأی‌ها + نمودار پخش ستاره‌ها
/// - کاربر روی ستاره می‌زند یا یکی از ۵ متن پیش‌فرض را انتخاب می‌کند
///   (هر متن = یک ستاره)؛ سپس «ثبت امتیاز»
/// - هر کاربر یک امتیاز دارد و می‌تواند آن را تغییر دهد
/// سرور: GET /api/stay-reg/rating و POST /api/stay-reg/rate
/// ===============================================================
class StayRatingSection extends StatefulWidget {
  const StayRatingSection({
    super.key,
    required this.kind,
    required this.targetId,
    required this.lang,
    this.onChanged,
  });

  /// 'stay' یا 'health'
  final String kind;
  final int targetId;

  /// fa / en / ar
  final String lang;

  /// بعد از ثبت موفق: (میانگین، تعداد)
  final void Function(double average, int count)? onChanged;

  @override
  State<StayRatingSection> createState() => _StayRatingSectionState();
}

class _StayRatingSectionState extends State<StayRatingSection> {
  double _avg = 0;
  int _count = 0;
  Map<int, int> _dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int _mine = 0; // امتیاز ثبت‌شده‌ی خود کاربر
  int _sel = 0; // انتخاب فعلی
  bool _loading = true;
  bool _busy = false;
  String? _msg;
  bool _msgOk = false;

  String get _l => _kTx.containsKey(widget.lang) ? widget.lang : 'en';
  String _t(String k) => _kTx[_l]![k] ?? _kTx['en']![k] ?? k;
  List<String> get _texts => _kPresetTexts[_l]!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.targetId <= 0) {
      setState(() => _loading = false);
      return;
    }
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('GET', '/api/stay-reg/rating', query: {
        'kind': widget.kind,
        'id': '${widget.targetId}',
        'user_uid': uid,
      });
      if (!mounted) return;
      if (j != null && j['success'] == true) {
        final d = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        final raw = j['distribution'];
        if (raw is Map) {
          raw.forEach((k, v) {
            final kk = int.tryParse('$k');
            if (kk != null && kk >= 1 && kk <= 5) d[kk] = int.tryParse('$v') ?? 0;
          });
        }
        final mine = j['mine'];
        setState(() {
          _avg = double.tryParse('${j['average'] ?? 0}') ?? 0;
          _count = int.tryParse('${j['count'] ?? 0}') ?? 0;
          _dist = d;
          if (mine is Map) {
            _mine = int.tryParse('${mine['stars'] ?? 0}') ?? 0;
            _sel = _mine;
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_sel < 1) {
      setState(() {
        _msg = _t('pick');
        _msgOk = false;
      });
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/stay-reg/rate', body: {
      'kind': widget.kind,
      'id': widget.targetId,
      'user_uid': uid,
      'stars': _sel,
      'text_key': 'r$_sel',
    });
    if (!mounted) return;
    if (j == null) {
      setState(() {
        _busy = false;
        _msg = _t('net');
        _msgOk = false;
      });
      return;
    }
    if (j['success'] == true) {
      HapticFeedback.mediumImpact();
      final avg = double.tryParse('${j['average'] ?? 0}') ?? _avg;
      final cnt = int.tryParse('${j['count'] ?? 0}') ?? _count;
      setState(() {
        _busy = false;
        _mine = _sel;
        _msg = _t('thanks');
        _msgOk = true;
      });
      widget.onChanged?.call(avg, cnt);
      _load();
    } else {
      setState(() {
        _busy = false;
        _msg = '${j['message'] ?? _t('net')}';
        _msgOk = false;
      });
    }
  }

  void _pick(int stars) {
    HapticFeedback.selectionClick();
    setState(() {
      _sel = stars;
      _msg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rtl = _l != 'en';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardSoft, _card],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rate_rounded, color: _gold, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(_t('title'),
                    style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 12),
            _summary(),
            const SizedBox(height: 14),
            Center(child: _starPicker()),
            const SizedBox(height: 4),
            Center(
              child: Text(_t('hint'), style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 5; i++) _presetTile(i + 1),
            if (_msg != null) ...[
              const SizedBox(height: 8),
              Text(_msg!,
                  style: TextStyle(
                    color: _msgOk ? _teal : const Color(0xffffb4a8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  )),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _bg,
                  disabledBackgroundColor: _gold.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _bg))
                    : Text(_mine > 0 ? _t('update') : _t('submit'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
        ),
      );
    }
    if (_count == 0) {
      return Text(_t('noVotes'), style: const TextStyle(color: Colors.white60, fontSize: 12.5));
    }
    final maxN = _dist.values.fold<int>(1, (a, b) => b > a ? b : a);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(children: [
          Text(_avg.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
          Text('$_count ${_t('votes')}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(children: [
            for (var s = 5; s >= 1; s--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  SizedBox(
                    width: 12,
                    child: Text('$s', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ),
                  const Icon(Icons.star_rounded, color: _gold, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_dist[s] ?? 0) / maxN,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: _gold,
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _starPicker() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => _pick(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: i <= _sel ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Icon(
                  i <= _sel ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 42,
                  color: i <= _sel ? _gold : Colors.white30,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _presetTile(int stars) {
    final on = _sel == stars;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(stars),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: on ? _gold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? _gold : Colors.white.withValues(alpha: 0.1), width: on ? 1.4 : 1),
          ),
          child: Row(children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 13,
                    color: i < stars ? _gold : Colors.white24,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _texts[stars - 1],
                style: TextStyle(
                  color: on ? _goldBright : Colors.white70,
                  fontSize: 13,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (on) const Icon(Icons.check_circle_rounded, color: _teal, size: 20),
          ]),
        ),
      ),
    );
  }
}
