import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/story_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);

/// ساخت استوری (عکس یا متن). فقط برای دارندگان تیک؛ سرور هم دوباره بررسی می‌کند.
class StoryComposerPage extends StatefulWidget {
  const StoryComposerPage({super.key});

  @override
  State<StoryComposerPage> createState() => _StoryComposerPageState();
}

class _StoryComposerPageState extends State<StoryComposerPage> {
  final _picker = ImagePicker();
  final _textCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  bool _isText = false;
  int _bgIdx = 0;
  Uint8List? _bytes;
  bool _busy = false;
  StoryMe? _me;

  @override
  void initState() {
    super.initState();
    StoryService.me().then((m) {
      if (mounted) setState(() => _me = m);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final f = await _picker.pickImage(source: src, maxWidth: 900, maxHeight: 1400, imageQuality: 60);
      if (f == null) return;
      final b = await f.readAsBytes();
      if (!mounted) return;
      setState(() => _bytes = b);
    } catch (_) {
      _snack(NT.t('g_fail'));
    }
  }

  Future<void> _publish() async {
    if (_busy) return;
    String b64 = '';
    if (_isText) {
      if (_textCtrl.text.trim().isEmpty) return _snack(NT.t('st_empty'));
    } else {
      if (_bytes == null) return _snack(NT.t('st_empty'));
      b64 = base64Encode(_bytes!);
      if (b64.length > 270000) return _snack(NT.t('st_big'));
    }
    setState(() => _busy = true);
    final r = await StoryService.create(
      kind: _isText ? 'text' : 'image',
      text: _isText ? _textCtrl.text.trim() : _capCtrl.text.trim(),
      bg: _bgIdx,
      imageBase64: b64,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _snack(NT.t('st_posted'));
      Navigator.of(context).pop(true);
    } else {
      _snack(r.code == 'net' ? NT.t('g_net') : (r.message.isEmpty ? NT.t('g_fail') : r.message));
    }
  }

  Widget _tab(String label, bool sel, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? _gold : _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  Widget _photoBody() {
    return Column(children: [
      Container(
        height: 330,
        width: double.infinity,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.25))),
        clipBehavior: Clip.antiAlias,
        child: _bytes == null
            ? const Center(child: Icon(Icons.add_a_photo_rounded, color: _gold, size: 48))
            : Image.memory(_bytes!, fit: BoxFit.contain),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded, color: _gold),
            label: Text(NT.t('st_camera'), style: const TextStyle(color: _gold)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, color: _gold),
            label: Text(NT.t('st_gallery'), style: const TextStyle(color: _gold)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _capCtrl,
        maxLength: 120,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: NT.t('st_caption'),
          labelStyle: const TextStyle(color: Colors.white54),
          counterStyle: const TextStyle(color: Colors.white38),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gold.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
        ),
      ),
    ]);
  }

  Widget _textBody() {
    final c = kStoryGradients[_bgIdx];
    return Column(children: [
      Container(
        height: 330,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(c[0]), Color(c[1])]),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: _textCtrl,
          maxLength: 200,
          maxLines: null,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: NT.t('st_text_hint'),
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 20),
            counterStyle: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 10,
        children: List.generate(kStoryGradients.length, (i) {
          final g = kStoryGradients[i];
          return GestureDetector(
            onTap: () => setState(() => _bgIdx = i),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(g[0]), Color(g[1])]),
                border: Border.all(color: i == _bgIdx ? Colors.white : Colors.transparent, width: 2.5),
              ),
            ),
          );
        }),
      ),
    ]);
  }

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
          title: Text(NT.t('st_new'), style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            Row(children: [
              _tab(NT.t('st_photo'), !_isText, () => setState(() => _isText = false)),
              const SizedBox(width: 10),
              _tab(NT.t('st_text'), _isText, () => setState(() => _isText = true)),
            ]),
            const SizedBox(height: 14),
            if (_isText) _textBody() else _photoBody(),
            const SizedBox(height: 10),
            Text(NT.t('st_expires'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (_me != null && _me!.dailyLimit > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  NT.t('st_quota').replaceAll('{u}', '${_me!.storiesToday}').replaceAll('{n}', '${_me!.dailyLimit}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _gold, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: const Color(0xff06121d), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _busy ? null : _publish,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xff06121d)))
                    : Text(NT.t('st_publish'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
