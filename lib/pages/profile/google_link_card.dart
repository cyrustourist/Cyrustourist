import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/google_link_service.dart';
import '../../widgets/cyrus_result_dialog.dart';

const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

/// کارت «تأیید جی‌میل با حساب گوگل» (ورود اختیاری). ورود با پیامک بعداً اضافه می‌شود.
class GoogleLinkCard extends StatefulWidget {
  const GoogleLinkCard({super.key});

  @override
  State<GoogleLinkCard> createState() => _GoogleLinkCardState();
}

class _GoogleLinkCardState extends State<GoogleLinkCard> {
  String? _email; // null = وصل نیست
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await GoogleLinkService.status();
    if (!mounted) return;
    setState(() {
      _email = e;
      _loading = false;
    });
  }

  Future<void> _link() async {
    setState(() => _busy = true);
    final r = await GoogleLinkService.link();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      setState(() => _email = r.emailMasked.isEmpty ? '✓' : r.emailMasked);
      final tk = r.badge == 'gold' ? NT.t('tk_gold') : (r.badge == 'blue' ? NT.t('tk_blue') : NT.t('tk_none'));
      await showCyrusResult(context, ok: true, message: '${NT.t('g_ok')}\n$tk');
    } else if (!r.cancelled) {
      await showCyrusResult(context, ok: false, message: r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = _email != null;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (linked ? _teal : _gold).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(linked ? Icons.mark_email_read_rounded : Icons.mail_outline_rounded, color: linked ? _teal : _gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                linked ? NT.t('g_done') : NT.t('g_title'),
                style: TextStyle(color: linked ? _teal : _gold, fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: LinearProgressIndicator(color: _gold, backgroundColor: Color(0xff102733)),
            )
          else if (linked) ...[
            if (_email!.isNotEmpty && _email != '✓')
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(_email!, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            const SizedBox(height: 6),
            Text(
              NT.t('g_done_desc'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.7),
            ),
          ] else ...[
            Text(
              NT.t('g_desc'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5, height: 1.7),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff1f2937),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide.none,
                ),
                onPressed: _busy ? null : _link,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('G', style: TextStyle(color: Color(0xffea4335), fontWeight: FontWeight.w900, fontSize: 20)),
                label: Text(NT.t('g_btn'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
