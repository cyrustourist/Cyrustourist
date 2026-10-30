import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../services/group_texts.dart';
import '../profile/photo_cropper.dart';
import 'group_ui.dart';

/// انتخاب عکس گروه: گالری یا دوربین ← ویرایشگر پیشرفته (برش دایره‌ای، چرخش، آینه، زوم،
/// فیلتر، روشنایی/کنتراست/اشباع) ← فشرده‌سازی نهایی (مربع ۳۲۰، JPEG، حداکثر حدود ۵۰ کیلوبایت).
/// خروجی base64 (بدون پیشوند data:)؛ null یعنی کاربر لغو کرد یا عکس قابل استفاده نبود.
Future<String?> pickGroupPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: gPanel,
    builder: (ctx) => Directionality(
      textDirection: gDir,
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: gGold),
            title: Text(GT.t('photo_gallery'), style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: gGold),
            title: Text(GT.t('photo_camera'), style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
        ]),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;
  try {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 88);
    if (x == null || !context.mounted) return null;
    final raw = await x.readAsBytes();
    if (!context.mounted) return null;
    final edited = await cropProfilePhoto(context, raw, title: GT.t('photo_edit_title'));
    if (edited == null) return null;
    return compute(_compressSquare, edited);
  } catch (_) {
    return null;
  }
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
