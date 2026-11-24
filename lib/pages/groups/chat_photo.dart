import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../services/group_texts.dart';
import 'group_ui.dart';

/// حداکثر تعداد عکس در یک بار انتخاب.
const int kChatPhotoMax = 10;

/// عکس‌های آمادهٔ ارسال در چت: هر عکس base64 فشرده + یک توضیح اختیاری (روی عکس اول گذاشته می‌شود).
class ChatPhotoBatch {
  const ChatPhotoBatch(this.images, this.caption);
  final List<String> images;
  final String caption;
}

Future<ImageSource?> _askSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
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
}

/// انتخاب عکس (گالری: چندتایی تا [maxCount] / دوربین: یکی) ← فشرده‌سازی هر عکس
/// (حداکثر ضلع ۱۲۸۰، JPEG، حدود ۱۰۰ کیلوبایت) ← پیش‌نمایش با امکان نوشتن توضیح.
/// null یعنی لغو یا ناموفق.
Future<ChatPhotoBatch?> pickChatPhotos(BuildContext context, {int maxCount = kChatPhotoMax}) async {
  final source = await _askSource(context);
  if (source == null || !context.mounted) return null;
  try {
    final List<XFile> files;
    if (source == ImageSource.camera || maxCount <= 1) {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 92);
      files = x == null ? const <XFile>[] : <XFile>[x];
    } else {
      final xs = await ImagePicker().pickMultiImage(maxWidth: 2000, maxHeight: 2000, imageQuality: 92, limit: maxCount);
      files = xs.take(maxCount).toList();
      if (xs.length > maxCount && context.mounted) {
        gToast(context, GT.t('photo_limit', {'n': '$maxCount'}));
      }
    }
    if (files.isEmpty || !context.mounted) return null;

    final out = <String>[];
    for (final f in files) {
      final raw = await f.readAsBytes();
      final b64 = await compute(_compressForChat, raw);
      if (b64 != null) out.add(b64);
    }
    if (!context.mounted) return null;
    if (out.isEmpty) {
      gToast(context, GT.t('photo_bad'));
      return null;
    }
    if (out.length < files.length) gToast(context, GT.t('photo_some_bad'));
    return await _preview(context, out);
  } catch (_) {
    return null;
  }
}

Future<ChatPhotoBatch?> _preview(BuildContext context, List<String> images) {
  final caption = TextEditingController();
  final many = images.length > 1;
  return showDialog<ChatPhotoBatch>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: gDir,
      child: AlertDialog(
        backgroundColor: gPanel,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!many)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.memory(base64Decode(images.first), fit: BoxFit.contain),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final b in images)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(base64Decode(b), width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 160),
                    ),
                ],
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
            onPressed: () => Navigator.of(ctx).pop(ChatPhotoBatch(images, caption.text.trim())),
            child: Text(many ? '${GT.t('photo_send')} (${images.length})' : GT.t('photo_send'), style: const TextStyle(fontWeight: FontWeight.w900)),
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
