import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';
import '../services/deep_link_service.dart';
import '../services/group_texts.dart';

final RegExp _ownRe = RegExp(r'https?://(www\.)?cyrustourist\.ir/[^\s]*', caseSensitive: false);
final RegExp _anyRe = RegExp(r'https?://[^\s]+', caseSensitive: false);
const String _trailing = '.,;:!?)]}»،؛';

/// متنی که لینک‌های cyrustourist.ir داخلش با لمس، مستقیم صفحهٔ فیلم/اقامتگاه/... را باز می‌کند.
/// اگر [allowExternal] روشن باشد (کلید «لینک آزاد» در پنل)، هر لینک http/https لمس‌شدنی است؛
/// لینک‌های بیرونی بعد از یک تأیید در مرورگر باز می‌شوند.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkColor = const Color(0xff66d9ff),
    this.textAlign,
    this.allowExternal = false,
  });

  final String text;
  final TextStyle? style;
  final Color linkColor;
  final TextAlign? textAlign;
  final bool allowExternal;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recs = [];

  void _clear() {
    for (final r in _recs) {
      r.dispose();
    }
    _recs.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  bool _isOwn(Uri u) => u.host == 'cyrustourist.ir' || u.host == 'www.cyrustourist.ir';

  Future<void> _open(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    if (_isOwn(u)) {
      DeepLinkService.openLink(u);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: (MenuLanguage.current == 'fa' || MenuLanguage.current == 'ar') ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color(0xff0b2636),
          title: Text(GT.t('ext_link_title'), style: const TextStyle(color: Color(0xffffd36a), fontWeight: FontWeight.w900)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GT.t('ext_link_body'), style: const TextStyle(color: Colors.white70, height: 1.8)),
            const SizedBox(height: 10),
            Text(url, textDirection: TextDirection.ltr, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff66d9ff), fontSize: 12.5)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(GT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xffffd36a), foregroundColor: const Color(0xff06121d)),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(GT.t('ext_link_open')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in (widget.allowExternal ? _anyRe : _ownRe).allMatches(widget.text)) {
      var url = m.group(0)!;
      var end = m.end;
      if (widget.allowExternal) {
        while (url.isNotEmpty && _trailing.contains(url[url.length - 1])) {
          url = url.substring(0, url.length - 1);
          end--;
        }
        if (url.length < 8) continue;
      }
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final link = url;
      final rec = TapGestureRecognizer()..onTap = () => _open(link);
      _recs.add(rec);
      spans.add(TextSpan(
        text: url,
        recognizer: rec,
        style: TextStyle(color: widget.linkColor, decoration: TextDecoration.underline),
      ));
      last = end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));
    return Text.rich(TextSpan(style: widget.style, children: spans), textAlign: widget.textAlign);
  }
}
