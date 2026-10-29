import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// انتخاب عکس گروه از گالری و فشرده‌سازی:
/// مربع (برش از وسط)، حداکثر ۳۲۰×۳۲۰، JPEG با کیفیت پله‌ای تا حجم حدود ۵۰ کیلوبایت.
/// خروجی base64 (بدون پیشوند data:)؛ null یعنی انتخاب لغو شد یا عکس قابل استفاده نبود.
Future<String?> pickGroupPhoto() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 90,
  );
  if (x == null) return null;
  final raw = await x.readAsBytes();
  return compute(_compressSquare, raw);
}

String? _compressSquare(Uint8List raw) {
  final decoded0 = img.decodeImage(raw);
  if (decoded0 == null) return null;
  final decoded = img.bakeOrientation(decoded0);
  final side = math.min(decoded.width, decoded.height);
  if (side < 16) return null;
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  for (final size in const [320, 256, 192]) {
    final resized = img.copyResize(square, width: size, height: size, interpolation: img.Interpolation.average);
    for (final q in const [82, 70, 58, 46]) {
      final out = img.encodeJpg(resized, quality: q);
      if (out.length <= 52000) return base64Encode(out);
    }
  }
  return null;
}
