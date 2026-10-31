import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../services/group_texts.dart';
import 'group_ui.dart';

/// عکس آمادهٔ ارسال در چت: base64 فشرده + توضیح اختیاری.
class ChatPhotoPick {
  const ChatPhotoPick(this.base64, this.caption);
  final String base64;
  final String caption;
}

/// انتخاب عکس (گالری/دوربین) ← فشرده‌سازی (حداکثر ضلع ۱۲۸۰، JPEG، حدود ۱۰۰ کیلوبایت)
/// ← پیش‌نمایش با امکان نوشتن توضیح. null یعنی لغو یا ناموفق.
Future<ChatPhotoPick?> pickChatPhoto(BuildContext context) async {
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
    final x = await ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 92);
    if (x == null || !context.mounted) return null;
    final raw = await x.readAsBytes();
    final b64 = await compute(_compressForChat, raw);
    if (b64 == null) {
      if (context.mounted) gToast(context, GT.t('photo_bad'));
      return null;
    }
    if (!context.mounted) return null;
    return await _preview(context, b64);
  } catch (_) {
    return null;
  }
}

Future<ChatPhotoPick?> _preview(BuildContext context, String b64) {
  final caption = TextEditingController();
  return showDialog<ChatPhotoPick>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: gDir,
      child: AlertDialog(
        backgroundColor: gPanel,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Image.memory(base64Decode(b64), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: caption,
              maxLength: 300,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: GT.t('photo_caption'),
                hintStyle: const TextStyle(color: gMuted),
                counterText: '',
                filled: true,
                fillColor: gBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gLine)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gLine)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(GT.t('cancel'), style: const TextStyle(color: Colors.white70))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
            onPressed: () => Navigator.of(ctx).pop(ChatPhotoPick(b64, caption.text.trim())),
            child: Text(GT.t('photo_send'), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}

String? _compressForChat(Uint8List raw) {
  final decoded0 = img.decodeImage(raw);
  if (decoded0 == null) return null;
  final decoded = img.bakeOrientation(decoded0);
  final longest = math.max(decoded.width, decoded.height);
  if (math.min(decoded.width, decoded.height) < 16) return null;
  for (final size in const [1280, 1024, 800, 640]) {
    final img.Image work = longest > size
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? size : null,
            height: decoded.height > decoded.width ? size : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;
    for (final q in const [80, 70, 60, 50]) {
      final out = img.encodeJpg(work, quality: q);
      if (out.length <= 100000) return base64Encode(out);
    }
  }
  return null;
}
