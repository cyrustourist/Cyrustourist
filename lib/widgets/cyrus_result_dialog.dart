import 'dart:async';

import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../core/language/new_texts.dart';

const Color _kGreen = Color(0xff16a34a);
const Color _kRed = Color(0xffdc2626);

/// نتیجهٔ هر تغییر را وسط صفحه نشان می‌دهد:
/// تیک سبز = انجام شد ، ضربدر قرمز = انجام نشد. خودکار بسته می‌شود؛ با لمس هم بسته می‌شود.
Future<void> showCyrusResult(BuildContext context, {required bool ok, String? message}) async {
  if (!context.mounted) return;
  final text = (message == null || message.trim().isEmpty) ? NT.t(ok ? 'res_ok' : 'res_no') : message.trim();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'result',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (c, a1, a2) => _ResultBox(ok: ok, text: text),
  );
}

class _ResultBox extends StatefulWidget {
  const _ResultBox({required this.ok, required this.text});
  final bool ok;
  final String text;

  @override
  State<_ResultBox> createState() => _ResultBoxState();
}

class _ResultBoxState extends State<_ResultBox> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.ok ? 2300 : 3800), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.ok ? _kGreen : _kRed;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 340),
            curve: Curves.elasticOut,
            builder: (c, v, child) => Transform.scale(scale: v, child: child),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320, minWidth: 220),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                decoration: BoxDecoration(
                  color: const Color(0xff0e2433),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 0, spreadRadius: 8)],
                    ),
                    child: Icon(widget.ok ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 56),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.8, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
