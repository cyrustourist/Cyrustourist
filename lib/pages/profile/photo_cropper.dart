import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

/// کادر دایره‌ای: کاربر عکس را جابه‌جا و زوم می‌کند، سپس خروجی JPEG ۴۰۰×۴۰۰ (کم‌حجم) برمی‌گردد.
/// اگر کاربر انصراف دهد null برمی‌گردد.
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
  static const double _box = 300;
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _ctrl = TransformationController();
  double _w = 0;
  double _h = 0;
  bool _ready = false;
  bool _busy = false;

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
      final s = _box / (image.width < image.height ? image.width : image.height);
      _w = image.width * s;
      _h = image.height * s;
      // وسط عکس داخل کادر
      _ctrl.value = Matrix4.translationValues(-(_w - _box) / 2, -(_h - _box) / 2, 0);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برش عکس انجام نشد. دوباره تلاش کنید.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: const Color(0xff0e2433),
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تنظیم عکس پروفایل', style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('عکس را بکشید و با دو انگشت زوم کنید', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 14),
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
                                  child: SizedBox(
                                    width: _w,
                                    height: _h,
                                    child: Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                      child: const Text('انصراف'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_busy || !_ready) ? null : _confirm,
                      style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: const Color(0xff06121d)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('تأیید', style: TextStyle(fontWeight: FontWeight.w800)),
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
