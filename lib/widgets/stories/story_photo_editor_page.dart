import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/language/menu_translations.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);

/// ویرایشگر عکس استوری: برش پیشرفته (آزاد/نسبت‌های آماده)، چرخش و آینه،
/// و رنگ‌بندی (نور، کنتراست، اشباع، گرمی رنگ + فیلترهای آماده).
/// خروجی: بایت‌های JPEG ویرایش‌شده (null = انصراف).
class StoryPhotoEditorPage extends StatefulWidget {
  const StoryPhotoEditorPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<StoryPhotoEditorPage> createState() => _StoryPhotoEditorPageState();
}

class _Ratio {
  const _Ratio(this.key, this.value);
  final String key; // free | orig | 1:1 ...
  final double? value; // عرض ÷ ارتفاع؛ null = آزاد
}

class _Preset {
  const _Preset(this.fa, this.en, this.b, this.c, this.s, this.w);
  final String fa;
  final String en;
  final double b, c, s, w;
}

const List<_Preset> _kPresets = [
  _Preset('اصلی', 'Original', 0, 0, 0, 0),
  _Preset('زنده', 'Vivid', 0.04, 0.15, 0.45, 0.05),
  _Preset('گرم', 'Warm', 0.03, 0.05, 0.1, 0.55),
  _Preset('سرد', 'Cool', 0, 0.05, 0.05, -0.55),
  _Preset('سیاه‌وسفید', 'B&W', 0, 0.12, -1, 0),
  _Preset('قدیمی', 'Sepia', 0.02, 0.0, -0.75, 0.8),
  _Preset('محو', 'Fade', 0.12, -0.2, -0.25, 0.05),
];

class _StoryPhotoEditorPageState extends State<StoryPhotoEditorPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  // تصویر کاری (کم‌حجم‌شده برای پیش‌نمایش سریع؛ چرخش/آینه روی همین اعمال می‌شود)
  Uint8List? _work;
  int _iw = 1, _ih = 1;
  bool _loading = true;
  bool _saving = false;

  // برش (مختصات نرمال ۰..۱ روی تصویر کاری)
  Rect _crop = const Rect.fromLTRB(0, 0, 1, 1);
  int _ratioIdx = 0;

  // رنگ‌بندی
  double _bright = 0, _contrast = 0, _sat = 0, _warm = 0;
  int _presetIdx = 0;

  // لمس برش
  _Drag _drag = _Drag.none;
  Rect _dragStartCrop = Rect.zero;
  Offset _dragStartPos = Offset.zero;

  static const List<_Ratio> _ratios = [
    _Ratio('free', null),
    _Ratio('orig', -1),
    _Ratio('1:1', 1),
    _Ratio('4:5', 4 / 5),
    _Ratio('9:16', 9 / 16),
    _Ratio('3:4', 3 / 4),
    _Ratio('16:9', 16 / 9),
    _Ratio('3:2', 3 / 2),
  ];

  bool get _fa => MenuLanguage.current == 'fa';
  String _t(String fa, String en) => _fa ? fa : en;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _prepare();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      final r = await compute(_prepareIsolate, widget.bytes);
      if (!mounted) return;
      setState(() {
        _work = r.bytes;
        _iw = r.w;
        _ih = r.h;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------
  // نسبت ابعاد
  // ------------------------------------------------------------

  double? _ratioValue(int i) {
    final v = _ratios[i].value;
    if (v == null) return null;
    if (v < 0) return _iw / _ih; // اصلی
    return v;
  }

  void _applyRatio(int i) {
    final r = _ratioValue(i);
    setState(() {
      _ratioIdx = i;
      if (r == null) return;
      // بزرگ‌ترین مستطیل هم‌مرکز با نسبت r (در پیکسل)
      double nw = 1;
      double nh = _iw / (r * _ih);
      if (nh > 1) {
        nh = 1;
        nw = r * _ih / _iw;
      }
      final cx = _crop.center.dx, cy = _crop.center.dy;
      double l = (cx - nw / 2).clamp(0.0, 1.0 - nw);
      double t = (cy - nh / 2).clamp(0.0, 1.0 - nh);
      _crop = Rect.fromLTWH(l, t, nw, nh);
    });
  }

  // ------------------------------------------------------------
  // چرخش و آینه
  // ------------------------------------------------------------

  Future<void> _transform(String op) async {
    if (_work == null) return;
    setState(() => _loading = true);
    try {
      final r = await compute(_transformIsolate, _TransformArgs(_work!, op));
      if (!mounted) return;
      setState(() {
        _work = r.bytes;
        _iw = r.w;
        _ih = r.h;
        _crop = const Rect.fromLTRB(0, 0, 1, 1);
        _loading = false;
      });
      _applyRatio(_ratioIdx);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------------------------------------------------
  // ماتریس رنگ (همان برای پیش‌نمایش و خروجی)
  // ------------------------------------------------------------

  List<double> get _matrix => buildColorMatrix(_bright, _contrast, _sat, _warm);

  bool get _colorChanged => _bright != 0 || _contrast != 0 || _sat != 0 || _warm != 0;

  void _setPreset(int i) {
    final p = _kPresets[i];
    setState(() {
      _presetIdx = i;
      _bright = p.b;
      _contrast = p.c;
      _sat = p.s;
      _warm = p.w;
    });
  }

  void _resetColors() => _setPreset(0);

  // ------------------------------------------------------------
  // ذخیره
  // ------------------------------------------------------------

  Future<void> _done() async {
    if (_saving || _work == null) return;
    setState(() => _saving = true);
    try {
      final out = await compute(
        _exportIsolate,
        _ExportArgs(
          bytes: _work!,
          l: _crop.left,
          t: _crop.top,
          r: _crop.right,
          b: _crop.bottom,
          matrix: _colorChanged ? _matrix : null,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(out);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('ذخیره‌ی عکس انجام نشد', 'Could not save the photo'))));
    }
  }

  // ------------------------------------------------------------
  // رابط
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(_t('ویرایش عکس', 'Edit photo'), style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            TextButton(
              onPressed: _saving || _loading ? null : _done,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                  : Text(_t('تأیید', 'Done'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _loading || _work == null ? const Center(child: CircularProgressIndicator(color: _gold)) : _canvas()),
              _bottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // محل نمایش تصویر داخل کادر (با حفظ نسبت)
  Rect _fitRect(Size box) {
    final ar = _iw / _ih;
    double w = box.width, h = box.width / ar;
    if (h > box.height) {
      h = box.height;
      w = h * ar;
    }
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  Widget _canvas() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, c) {
        final box = Size(c.maxWidth, c.maxHeight);
        final fit = _fitRect(box);
        final cropOnTab = _tabs.index == 0;

        Widget image = Image.memory(_work!, fit: BoxFit.fill, gaplessPlayback: true);
        if (_colorChanged) {
          image = ColorFiltered(colorFilter: ColorFilter.matrix(_matrix), child: image);
        }

        return Stack(
          children: [
            Positioned.fromRect(rect: fit, child: image),
            if (cropOnTab)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _onPanStart(d.localPosition, fit),
                  onPanUpdate: (d) => _onPanUpdate(d.localPosition, fit),
                  onPanEnd: (_) => _drag = _Drag.none,
                  child: CustomPaint(painter: _CropPainter(fit: fit, crop: _crop)),
                ),
              )
            else
              Positioned.fromRect(
                rect: fit,
                child: IgnorePointer(
                  child: CustomPaint(painter: _CropShadePainter(crop: _crop)),
                ),
              ),
          ],
        );
      }),
    );
  }

  Rect _toDisplay(Rect n, Rect fit) => Rect.fromLTRB(
        fit.left + n.left * fit.width,
        fit.top + n.top * fit.height,
        fit.left + n.right * fit.width,
        fit.top + n.bottom * fit.height,
      );

  void _onPanStart(Offset p, Rect fit) {
    final r = _toDisplay(_crop, fit);
    const hit = 34.0;
    _dragStartCrop = _crop;
    _dragStartPos = p;
    if ((p - r.topLeft).distance <= hit) {
      _drag = _Drag.tl;
    } else if ((p - r.topRight).distance <= hit) {
      _drag = _Drag.tr;
    } else if ((p - r.bottomLeft).distance <= hit) {
      _drag = _Drag.bl;
    } else if ((p - r.bottomRight).distance <= hit) {
      _drag = _Drag.br;
    } else if ((p.dy - r.top).abs() <= hit * 0.6 && p.dx > r.left && p.dx < r.right && _ratioValue(_ratioIdx) == null) {
      _drag = _Drag.top;
    } else if ((p.dy - r.bottom).abs() <= hit * 0.6 && p.dx > r.left && p.dx < r.right && _ratioValue(_ratioIdx) == null) {
      _drag = _Drag.bottom;
    } else if ((p.dx - r.left).abs() <= hit * 0.6 && p.dy > r.top && p.dy < r.bottom && _ratioValue(_ratioIdx) == null) {
      _drag = _Drag.left;
    } else if ((p.dx - r.right).abs() <= hit * 0.6 && p.dy > r.top && p.dy < r.bottom && _ratioValue(_ratioIdx) == null) {
      _drag = _Drag.right;
    } else if (r.contains(p)) {
      _drag = _Drag.move;
    } else {
      _drag = _Drag.none;
    }
  }

  void _onPanUpdate(Offset p, Rect fit) {
    if (_drag == _Drag.none) return;
    final dx = (p.dx - _dragStartPos.dx) / fit.width;
    final dy = (p.dy - _dragStartPos.dy) / fit.height;
    final s = _dragStartCrop;
    const minSide = 0.08;
    final ratio = _ratioValue(_ratioIdx);

    Rect next;
    switch (_drag) {
      case _Drag.move:
        final w = s.width, h = s.height;
        final l = (s.left + dx).clamp(0.0, 1.0 - w);
        final t = (s.top + dy).clamp(0.0, 1.0 - h);
        next = Rect.fromLTWH(l, t, w, h);
        break;
      case _Drag.left:
        next = Rect.fromLTRB((s.left + dx).clamp(0.0, s.right - minSide), s.top, s.right, s.bottom);
        break;
      case _Drag.right:
        next = Rect.fromLTRB(s.left, s.top, (s.right + dx).clamp(s.left + minSide, 1.0), s.bottom);
        break;
      case _Drag.top:
        next = Rect.fromLTRB(s.left, (s.top + dy).clamp(0.0, s.bottom - minSide), s.right, s.bottom);
        break;
      case _Drag.bottom:
        next = Rect.fromLTRB(s.left, s.top, s.right, (s.bottom + dy).clamp(s.top + minSide, 1.0));
        break;
      default:
        next = _resizeCorner(s, dx, dy, ratio, minSide);
    }
    setState(() => _crop = next);
  }

  Rect _resizeCorner(Rect s, double dx, double dy, double? ratio, double minSide) {
    // گوشه‌ی مقابل ثابت می‌ماند
    final bool left = _drag == _Drag.tl || _drag == _Drag.bl;
    final bool top = _drag == _Drag.tl || _drag == _Drag.tr;
    final Offset anchor = Offset(left ? s.right : s.left, top ? s.bottom : s.top);
    double mx = (left ? s.left : s.right) + dx;
    double my = (top ? s.top : s.bottom) + dy;
    mx = mx.clamp(0.0, 1.0);
    my = my.clamp(0.0, 1.0);

    double w = (mx - anchor.dx).abs();
    double h = (my - anchor.dy).abs();

    if (ratio != null) {
      // نسبت در پیکسل: (w*iw)/(h*ih) = ratio  →  h = w*iw/(ratio*ih)
      final k = _iw / (ratio * _ih);
      h = w * k;
      // محدود به فضای موجود تا لبه‌ی تصویر
      final maxW = left ? anchor.dx : 1.0 - anchor.dx;
      final maxH = top ? anchor.dy : 1.0 - anchor.dy;
      if (w > maxW) {
        w = maxW;
        h = w * k;
      }
      if (h > maxH) {
        h = maxH;
        w = h / k;
      }
    }
    w = math.max(w, minSide);
    h = math.max(h, ratio != null ? minSide * (_iw / (ratio * _ih)) : minSide);

    final double l = left ? anchor.dx - w : anchor.dx;
    final double t = top ? anchor.dy - h : anchor.dy;
    final r = Rect.fromLTWH(l, t, w, h);
    // اطمینان از ماندن داخل تصویر
    return Rect.fromLTRB(r.left.clamp(0.0, 1.0), r.top.clamp(0.0, 1.0), r.right.clamp(0.0, 1.0), r.bottom.clamp(0.0, 1.0));
  }

  Widget _bottomPanel() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabs,
            onTap: (_) => setState(() {}),
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: const Icon(Icons.crop_rounded, size: 20), text: _t('برش و ابعاد', 'Crop & size')),
              Tab(icon: const Icon(Icons.tune_rounded, size: 20), text: _t('رنگ‌بندی', 'Colors')),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: _tabs.index == 0 ? _cropTools() : _colorTools(),
          ),
        ],
      ),
    );
  }

  // ---------------- ابزار برش ----------------

  String _ratioLabel(_Ratio r) {
    switch (r.key) {
      case 'free':
        return _t('آزاد', 'Free');
      case 'orig':
        return _t('اصلی', 'Original');
      default:
        return r.key;
    }
  }

  Widget _cropTools() {
    final outW = (_crop.width * _iw).round();
    final outH = (_crop.height * _ih).round();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _ratios.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _ratioIdx;
              return GestureDetector(
                onTap: () => _applyRatio(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? _gold : _bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _ratioLabel(_ratios[i]),
                    style: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolBtn(Icons.rotate_left_rounded, _t('چرخش چپ', 'Rotate L'), () => _transform('rotl')),
            _toolBtn(Icons.rotate_right_rounded, _t('چرخش راست', 'Rotate R'), () => _transform('rotr')),
            _toolBtn(Icons.flip_rounded, _t('آینه افقی', 'Flip H'), () => _transform('fliph')),
            _toolBtn(Icons.flip_rounded, _t('آینه عمودی', 'Flip V'), () => _transform('flipv'), quarter: true),
            _toolBtn(Icons.restart_alt_rounded, _t('بازنشانی', 'Reset'), () {
              setState(() => _crop = const Rect.fromLTRB(0, 0, 1, 1));
              _applyRatio(_ratioIdx);
            }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_t('اندازه‌ی خروجی', 'Output size')}: $outW × $outH px',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap, {bool quarter = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            quarter ? RotatedBox(quarterTurns: 1, child: Icon(icon, color: _gold, size: 26)) : Icon(icon, color: _gold, size: 26),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  // ---------------- ابزار رنگ ----------------

  Widget _colorTools() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _presetIdx && _isPreset(i);
              return GestureDetector(
                onTap: () => _setPreset(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? _gold : _bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _fa ? _kPresets[i].fa : _kPresets[i].en,
                    style: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                ),
              );
            },
          ),
        ),
        _slider(Icons.wb_sunny_outlined, _t('نور', 'Brightness'), _bright, (v) => setState(() => _bright = v)),
        _slider(Icons.contrast_rounded, _t('کنتراست', 'Contrast'), _contrast, (v) => setState(() => _contrast = v)),
        _slider(Icons.color_lens_outlined, _t('اشباع رنگ', 'Saturation'), _sat, (v) => setState(() => _sat = v)),
        _slider(Icons.thermostat_rounded, _t('گرمی رنگ', 'Warmth'), _warm, (v) => setState(() => _warm = v)),
        if (_colorChanged)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _resetColors,
              icon: const Icon(Icons.restart_alt_rounded, color: _gold, size: 18),
              label: Text(_t('بازنشانی رنگ‌ها', 'Reset colors'), style: const TextStyle(color: _gold, fontSize: 12)),
            ),
          ),
      ],
    );
  }

  bool _isPreset(int i) {
    final p = _kPresets[i];
    return p.b == _bright && p.c == _contrast && p.s == _sat && p.w == _warm;
  }

  Widget _slider(IconData icon, String label, double v, ValueChanged<double> onChanged) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Icon(icon, color: _gold, size: 18),
          const SizedBox(width: 6),
          SizedBox(width: 74, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _gold,
                thumbColor: _gold,
                inactiveTrackColor: Colors.white24,
                trackHeight: 2.5,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: v,
                min: -1,
                max: 1,
                onChanged: (x) {
                  onChanged(x);
                  _presetIdx = -1;
                },
                onChangeEnd: (_) => setState(() {}),
              ),
            ),
          ),
          SizedBox(width: 34, child: Text('${(v * 100).round()}', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white54, fontSize: 11))),
        ],
      ),
    );
  }
}

enum _Drag { none, move, tl, tr, bl, br, left, right, top, bottom }

// ================================================================
// نقاشی کادر برش
// ================================================================

class _CropPainter extends CustomPainter {
  _CropPainter({required this.fit, required this.crop});
  final Rect fit;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(
      fit.left + crop.left * fit.width,
      fit.top + crop.top * fit.height,
      fit.left + crop.right * fit.width,
      fit.top + crop.bottom * fit.height,
    );

    // سایه‌ی بیرون کادر
    final shade = Paint()..color = const Color(0xaa000000);
    canvas.drawPath(
      Path()
        ..addRect(fit)
        ..addRect(r)
        ..fillType = PathFillType.evenOdd,
      shade,
    );

    // خطوط سه‌قسمتی
    final grid = Paint()
      ..color = const Color(0x66ffffff)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = r.left + r.width * i / 3;
      final y = r.top + r.height * i / 3;
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), grid);
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), grid);
    }

    final border = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(r, border);

    // دستگیره‌های گوشه
    final h = Paint()..color = _gold;
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      canvas.drawCircle(c, 9, h);
      canvas.drawCircle(c, 4, Paint()..color = const Color(0xff06121d));
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.crop != crop || old.fit != fit;
}

/// در تب رنگ‌بندی، فقط ناحیه‌ی بیرون برش کمی تیره نشان داده می‌شود.
class _CropShadePainter extends CustomPainter {
  _CropShadePainter({required this.crop});
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTRB(crop.left * size.width, crop.top * size.height, crop.right * size.width, crop.bottom * size.height);
    canvas.drawPath(
      Path()
        ..addRect(Offset.zero & size)
        ..addRect(r)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = const Color(0x88000000),
    );
  }

  @override
  bool shouldRepaint(covariant _CropShadePainter old) => old.crop != crop;
}

// ================================================================
// ماتریس رنگ ۴×۵ (مقیاس ۰..۲۵۵ مانند ColorFilter.matrix فلاتر)
// ================================================================

List<double> _mul(List<double> a, List<double> b) {
  // خروجی = a ∘ b  (ابتدا b، سپس a) روی ماتریس‌های ۴×۵ با سطر پنجم ضمنی [0 0 0 0 1]
  final out = List<double>.filled(20, 0);
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 5; c++) {
      double v = 0;
      for (var k = 0; k < 4; k++) {
        v += a[r * 5 + k] * b[k * 5 + c];
      }
      if (c == 4) v += a[r * 5 + 4];
      out[r * 5 + c] = v;
    }
  }
  return out;
}

/// مقادیر هر ورودی بین ‑۱ و ۱ است.
@visibleForTesting
List<double> buildColorMatrix(double brightness, double contrast, double saturation, double warmth) {
  // نور: جابه‌جایی کلی
  final bo = brightness * 90;
  final B = <double>[
    1, 0, 0, 0, bo, //
    0, 1, 0, 0, bo,
    0, 0, 1, 0, bo,
    0, 0, 0, 1, 0,
  ];

  // کنتراست حول خاکستری میانی
  final f = 1 + contrast * 0.9;
  final co = 128 * (1 - f);
  final C = <double>[
    f, 0, 0, 0, co, //
    0, f, 0, 0, co,
    0, 0, f, 0, co,
    0, 0, 0, 1, 0,
  ];

  // اشباع (وزن‌های روشنایی)
  final s = 1 + saturation;
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final S = <double>[
    lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0, //
    lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0,
    lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // گرمی: قرمز بیشتر / آبی کمتر (و برعکس)
  final W = <double>[
    1 + warmth * 0.22, 0, 0, 0, 0, //
    0, 1 + warmth * 0.04, 0, 0, 0,
    0, 0, 1 - warmth * 0.22, 0, 0,
    0, 0, 0, 1, 0,
  ];

  return _mul(W, _mul(S, _mul(C, B)));
}

// ================================================================
// کارهای سنگین (روی Isolate جدا)
// ================================================================

class _Prepared {
  _Prepared(this.bytes, this.w, this.h);
  final Uint8List bytes;
  final int w, h;
}

_Prepared _prepareIsolate(Uint8List raw) {
  var im = img.decodeImage(raw);
  if (im == null) throw StateError('decode');
  im = img.bakeOrientation(im);
  const maxSide = 1280;
  if (im.width > maxSide || im.height > maxSide) {
    im = im.width >= im.height ? img.copyResize(im, width: maxSide) : img.copyResize(im, height: maxSide);
  }
  return _Prepared(Uint8List.fromList(img.encodeJpg(im, quality: 95)), im.width, im.height);
}

class _TransformArgs {
  _TransformArgs(this.bytes, this.op);
  final Uint8List bytes;
  final String op;
}

_Prepared _transformIsolate(_TransformArgs a) {
  var im = img.decodeImage(a.bytes);
  if (im == null) throw StateError('decode');
  switch (a.op) {
    case 'rotl':
      im = img.copyRotate(im, angle: -90);
      break;
    case 'rotr':
      im = img.copyRotate(im, angle: 90);
      break;
    case 'fliph':
      im = img.flipHorizontal(im);
      break;
    case 'flipv':
      im = img.flipVertical(im);
      break;
  }
  return _Prepared(Uint8List.fromList(img.encodeJpg(im, quality: 95)), im.width, im.height);
}

class _ExportArgs {
  _ExportArgs({required this.bytes, required this.l, required this.t, required this.r, required this.b, required this.matrix});
  final Uint8List bytes;
  final double l, t, r, b;
  final List<double>? matrix;
}

Uint8List _exportIsolate(_ExportArgs a) {
  final decoded = img.decodeImage(a.bytes);
  if (decoded == null) throw StateError('decode');
  // Keep the working image non-nullable throughout crop/resize/export.
  img.Image im = decoded;

  final x = (a.l * im.width).round().clamp(0, im.width - 1);
  final y = (a.t * im.height).round().clamp(0, im.height - 1);
  final w = ((a.r - a.l) * im.width).round().clamp(1, im.width - x);
  final h = ((a.b - a.t) * im.height).round().clamp(1, im.height - y);
  if (x != 0 || y != 0 || w != im.width || h != im.height) {
    im = img.copyCrop(im, x: x, y: y, width: w, height: h);
  }

  final m = a.matrix;
  if (m != null) {
    for (final p in im) {
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      p.r = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0, 255).round();
      p.g = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0, 255).round();
      p.b = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0, 255).round();
    }
  }

  // اندازه‌ی مناسب استوری: حداکثر ۱۰۸۰ و حجم کمتر از حدود ۱۹۰ کیلوبایت
  if (im.width > 1080 || im.height > 1080) {
    im = im.width >= im.height ? img.copyResize(im, width: 1080) : img.copyResize(im, height: 1080);
  }
  Uint8List out = Uint8List.fromList(img.encodeJpg(im, quality: 90));
  for (final q in const [82, 74, 66, 58]) {
    if (out.length <= 190000) break;
    out = Uint8List.fromList(img.encodeJpg(im, quality: q));
  }
  while (out.length > 190000 && im.width > 480) {
    im = img.copyResize(im, width: (im.width * 0.85).round());
    out = Uint8List.fromList(img.encodeJpg(im, quality: 70));
  }
  return out;
}
