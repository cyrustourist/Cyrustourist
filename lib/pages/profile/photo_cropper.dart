import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../core/language/menu_translations.dart';

const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'ویرایش عکس پروفایل',
    'hint': 'عکس را بکشید و با دو انگشت زوم کنید',
    'rotL': 'چرخش چپ',
    'rotR': 'چرخش راست',
    'flip': 'آینه',
    'reset': 'بازنشانی',
    'zoom': 'زوم',
    'bright': 'روشنایی',
    'contrast': 'کنتراست',
    'sat': 'اشباع رنگ',
    'filters': 'فیلتر',
    'f0': 'اصلی',
    'f1': 'سیاه‌وسفید',
    'f2': 'گرم',
    'f3': 'سرد',
    'f4': 'پرجلوه',
    'f5': 'محو',
    'f6': 'قدیمی',
    'cancel': 'انصراف',
    'ok': 'تأیید',
    'fail': 'ویرایش عکس انجام نشد. دوباره تلاش کنید.',
  },
  'en': {
    'title': 'Edit profile photo',
    'hint': 'Drag the photo and pinch to zoom',
    'rotL': 'Rotate left',
    'rotR': 'Rotate right',
    'flip': 'Mirror',
    'reset': 'Reset',
    'zoom': 'Zoom',
    'bright': 'Brightness',
    'contrast': 'Contrast',
    'sat': 'Saturation',
    'filters': 'Filters',
    'f0': 'Original',
    'f1': 'B&W',
    'f2': 'Warm',
    'f3': 'Cool',
    'f4': 'Vivid',
    'f5': 'Fade',
    'f6': 'Vintage',
    'cancel': 'Cancel',
    'ok': 'Done',
    'fail': 'Could not edit the photo. Try again.',
  },
  'ar': {
    'title': 'تعديل صورة الملف الشخصي',
    'hint': 'اسحب الصورة وكبّرها بإصبعين',
    'rotL': 'تدوير لليسار',
    'rotR': 'تدوير لليمين',
    'flip': 'عكس',
    'reset': 'إعادة ضبط',
    'zoom': 'تكبير',
    'bright': 'السطوع',
    'contrast': 'التباين',
    'sat': 'التشبّع',
    'filters': 'الفلاتر',
    'f0': 'الأصلية',
    'f1': 'أبيض وأسود',
    'f2': 'دافئ',
    'f3': 'بارد',
    'f4': 'زاهٍ',
    'f5': 'باهت',
    'f6': 'قديم',
    'cancel': 'إلغاء',
    'ok': 'تأكيد',
    'fail': 'تعذر تعديل الصورة. حاول مجدداً.',
  },
};

String _t(String k) {
  final m = _tx[MenuLanguage.current] ?? _tx['en']!;
  return m[k] ?? _tx['en']![k] ?? k;
}

// ماتریس‌های رنگ ۴×۵ (فیلترهای آماده)
const List<List<double>> _presets = [
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0], // اصلی
  [0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0], // سیاه‌وسفید
  [1.1, 0, 0, 0, 12, 0, 1.0, 0, 0, 4, 0, 0, 0.85, 0, -10, 0, 0, 0, 1, 0], // گرم
  [0.9, 0, 0, 0, -8, 0, 1.0, 0, 0, 2, 0, 0, 1.15, 0, 14, 0, 0, 0, 1, 0], // سرد
  [1.25, -0.05, -0.05, 0, -8, -0.05, 1.25, -0.05, 0, -8, -0.05, -0.05, 1.25, 0, -8, 0, 0, 0, 1, 0], // پرجلوه
  [0.85, 0.1, 0.05, 0, 22, 0.05, 0.85, 0.1, 0, 22, 0.05, 0.1, 0.85, 0, 22, 0, 0, 0, 1, 0], // محو
  [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0], // قدیمی (سپیا)
];

List<double> _mul(List<double> a, List<double> b) {
  // a ∘ b: ابتدا b سپس a (ماتریس‌های ۴×۵ با ردیف پنجم ضمنی [0 0 0 0 1])
  final r = List<double>.filled(20, 0);
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 5; j++) {
      var v = 0.0;
      for (var k = 0; k < 4; k++) {
        v += a[i * 5 + k] * b[k * 5 + j];
      }
      if (j == 4) v += a[i * 5 + 4];
      r[i * 5 + j] = v;
    }
  }
  return r;
}

List<double> _adjust(double bright, double contrast, double sat) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final s = sat;
  final sm = <double>[
    lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0,
    lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0,
    lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
  final t = (1 - contrast) * 128 + bright * 255;
  final cm = <double>[
    contrast, 0, 0, 0, t,
    0, contrast, 0, 0, t,
    0, 0, contrast, 0, t,
    0, 0, 0, 1, 0,
  ];
  return _mul(cm, sm);
}

/// ویرایشگر عکس پروفایل: برش دایره‌ای، چرخش، آینه، زوم، فیلتر و تنظیم روشنایی/کنتراست/اشباع.
/// خروجی JPEG ۴۰۰×۴۰۰ (کم‌حجم)؛ اگر کاربر انصراف دهد null برمی‌گردد.
Future<Uint8List?> cropProfilePhoto(BuildContext context, Uint8List bytes) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PhotoCropDialog(bytes: bytes),
  );
}

class _PhotoCropDialog extends StatefulWidget {
  const _PhotoCropDialog({required this.bytes});
  final Uint8List bytes;

  @override
  State<_PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<_PhotoCropDialog> {
  static const double _box = 280;
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _ctrl = TransformationController();
  double _iw = 0;
  double _ih = 0;
  double _w = 0;
  double _h = 0;
  bool _ready = false;
  bool _busy = false;

  int _turns = 0;
  bool _flip = false;
  int _filter = 0;
  double _bright = 0;
  double _contrast = 1;
  double _sat = 1;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      final image = await decodeImageFromList(widget.bytes);
      _iw = image.width.toDouble();
      _ih = image.height.toDouble();
      _layout();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  /// اندازهٔ نمایش بعد از چرخش + وسط‌چین کردن داخل کادر
  void _layout() {
    final odd = _turns.isOdd;
    final rw = odd ? _ih : _iw;
    final rh = odd ? _iw : _ih;
    final s = _box / (rw < rh ? rw : rh);
    _w = rw * s;
    _h = rh * s;
    _ctrl.value = Matrix4.translationValues(-(_w - _box) / 2, -(_h - _box) / 2, 0);
  }

  void _rotate(int d) {
    setState(() {
      _turns = (_turns + d) % 4;
      if (_turns < 0) _turns += 4;
      _layout();
    });
  }

  void _resetAll() {
    setState(() {
      _turns = 0;
      _flip = false;
      _filter = 0;
      _bright = 0;
      _contrast = 1;
      _sat = 1;
      _layout();
    });
  }

  double get _scale => _ctrl.value.getMaxScaleOnAxis();

  void _setZoom(double z) {
    // زوم حول مرکز کادر
    final old = _scale;
    final m = _ctrl.value.clone();
    final f = z / old;
    const c = _box / 2;
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;
    final nx = c - (c - tx) * f;
    final ny = c - (c - ty) * f;
    final n = Matrix4.identity()
      ..translate(nx, ny)
      ..scale(z);
    // مرزها: عکس همیشه کادر را بپوشاند
    final maxX = 0.0, minX = _box - _w * z;
    final maxY = 0.0, minY = _box - _h * z;
    n.setTranslationRaw(nx.clamp(minX, maxX).toDouble(), ny.clamp(minY, maxY).toDouble(), 0);
    setState(() => _ctrl.value = n);
  }

  List<double> get _matrix => _mul(_presets[_filter], _adjust(_bright, _contrast, _sat));

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image shot = await boundary.toImage(pixelRatio: 400 / _box);
      final data = await shot.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('empty');
      final decoded = img.decodePng(data.buffer.asUint8List());
      if (decoded == null) throw Exception('decode');
      final jpg = img.encodeJpg(img.copyResize(decoded, width: 400, height: 400), quality: 82);
      if (mounted) Navigator.pop(context, Uint8List.fromList(jpg));
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('fail'))));
      }
    }
  }

  Widget _tool(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _gold, size: 22),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        ]),
      ),
    );
  }

  Widget _slider(String label, double v, double min, double max, ValueChanged<double> on) {
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: _teal, thumbColor: _gold, inactiveTrackColor: Colors.white24, trackHeight: 2.5),
          child: Slider(value: v.clamp(min, max).toDouble(), min: min, max: max, onChanged: _busy ? null : on),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final double z = _ready ? _scale.clamp(1.0, 5.0).toDouble() : 1.0;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: const Color(0xff0e2433),
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('title'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text(_t('hint'), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: _box,
                height: _box,
                child: !_ready
                    ? const Center(child: CircularProgressIndicator(color: _gold))
                    : Stack(
                        children: [
                          RepaintBoundary(
                            key: _boundaryKey,
                            child: ClipRect(
                              child: SizedBox(
                                width: _box,
                                height: _box,
                                child: InteractiveViewer(
                                  transformationController: _ctrl,
                                  constrained: false,
                                  minScale: 1,
                                  maxScale: 5,
                                  boundaryMargin: EdgeInsets.zero,
                                  onInteractionUpdate: (_) => setState(() {}),
                                  child: SizedBox(
                                    width: _w,
                                    height: _h,
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.matrix(_matrix),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.diagonal3Values(_flip ? -1 : 1, 1, 1),
                                        child: RotatedBox(
                                          quarterTurns: _turns,
                                          child: Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // ماسک دایره‌ای (خارج از RepaintBoundary؛ در خروجی نمی‌آید)
                          IgnorePointer(child: CustomPaint(size: const Size(_box, _box), painter: _CircleMaskPainter())),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _tool(Icons.rotate_left_rounded, _t('rotL'), () => _rotate(-1)),
                _tool(Icons.rotate_right_rounded, _t('rotR'), () => _rotate(1)),
                _tool(Icons.flip_rounded, _t('flip'), () => setState(() => _flip = !_flip)),
                _tool(Icons.restart_alt_rounded, _t('reset'), _resetAll),
              ]),
              if (_ready) _slider(_t('zoom'), z, 1, 5, _setZoom),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChip(
                    label: Text(_t('f$i'), style: TextStyle(color: _filter == i ? const Color(0xff06121d) : Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                    selected: _filter == i,
                    selectedColor: _gold,
                    backgroundColor: const Color(0xff16384b),
                    showCheckmark: false,
                    onSelected: _busy ? null : (_) => setState(() => _filter = i),
                  ),
                ),
              ),
              _slider(_t('bright'), _bright, -0.3, 0.3, (v) => setState(() => _bright = v)),
              _slider(_t('contrast'), _contrast, 0.7, 1.5, (v) => setState(() => _contrast = v)),
              _slider(_t('sat'), _sat, 0, 2, (v) => setState(() => _sat = v)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                      child: Text(_t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_busy || !_ready) ? null : _confirm,
                      style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: const Color(0xff06121d)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_t('ok'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: rect.center, radius: size.width / 2 - 2))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = const Color(0xcc071722));
    canvas.drawCircle(
      rect.center,
      size.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
