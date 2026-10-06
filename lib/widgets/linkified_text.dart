import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/deep_link_service.dart';

final RegExp _linkRe = RegExp(r'https?://(www\.)?cyrustourist\.ir/[^\s]*', caseSensitive: false);

/// متنی که لینک‌های cyrustourist.ir داخلش با لمس، مستقیم صفحهٔ فیلم/اقامتگاه/... را باز می‌کند.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkColor = const Color(0xff66d9ff),
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Color linkColor;
  final TextAlign? textAlign;

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

  @override
  Widget build(BuildContext context) {
    _clear();
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _linkRe.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final url = m.group(0)!;
      final rec = TapGestureRecognizer()
        ..onTap = () {
          final u = Uri.tryParse(url);
          if (u != null) DeepLinkService.openLink(u);
        };
      _recs.add(rec);
      spans.add(TextSpan(
        text: url,
        recognizer: rec,
        style: TextStyle(color: widget.linkColor, decoration: TextDecoration.underline),
      ));
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));
    return Text.rich(TextSpan(style: widget.style, children: spans), textAlign: widget.textAlign);
  }
}
