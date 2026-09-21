import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/public_link_service.dart';

const Color _sheet = Color(0xff0a2030);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);

/// ===============================================================
/// اشتراک‌گذاری عمومی (Share / Copy Link / QR / Open / Share QR)
/// ---------------------------------------------------------------
/// برای هر موجودیتی که «نوع + شناسه‌ی پایدار» دارد کار می‌کند:
///   ShareSheet.show(context, entityType: 'tour', entityId: '76', title: '...')
/// QR در همان لحظه از لینک عمومی ساخته می‌شود و هیچ‌جا ذخیره نمی‌شود.
/// ===============================================================
class ShareSheet {
  ShareSheet._();

  static Future<void> show(
    BuildContext context, {
    required String entityType,
    required String entityId,
    required String title,
    bool autoShareQr = false,
  }) {
    return showLink(
      context,
      url: PublicLinkService.entityUrl(entityType, entityId),
      title: title,
      autoShareQr: autoShareQr,
    );
  }

  /// برگه‌ی اشتراک برای یک لینک دلخواه (مثلاً «معرفی به دوستان»).
  /// اگر [shareText] داده شود، دکمه‌ی «اشتراک‌گذاری» همان متن کامل را
  /// (با لینک داخلش) به شبکه‌های اجتماعی می‌فرستد.
  static Future<void> showLink(
    BuildContext context, {
    required String url,
    required String title,
    String? shareText,
    String heading = 'اشتراک‌گذاری',
    bool autoShareQr = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheetBody(
        url: url,
        title: title,
        shareText: shareText,
        heading: heading,
        autoShareQr: autoShareQr,
      ),
    );
  }

  static Future<void> shareLink(String title, String url, {String? text}) async {
    try {
      await Share.share(text ?? '$title\n$url', subject: title);
    } catch (_) {}
  }

  static Future<void> copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff13364b),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('لینک کپی شد', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  static Future<void> openPage(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _ShareSheetBody extends StatefulWidget {
  const _ShareSheetBody({
    required this.url,
    required this.title,
    required this.autoShareQr,
    this.shareText,
    this.heading = 'اشتراک‌گذاری',
  });

  final String url;
  final String title;
  final bool autoShareQr;
  final String? shareText;
  final String heading;

  @override
  State<_ShareSheetBody> createState() => _ShareSheetBodyState();
}

class _ShareSheetBodyState extends State<_ShareSheetBody> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.autoShareQr) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _shareQr());
    }
  }

  /// QR را به‌صورت تصویر PNG اشتراک می‌گذارد؛ اگر نشد فقط لینک را
  /// اشتراک می‌گذارد (برنامه خراب نمی‌شود).
  Future<void> _shareQr() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no qr');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('no bytes');
      await Share.shareXFiles(
        [
          XFile.fromData(
            data.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'cyrustourist-qr.png',
          ),
        ],
        text: widget.shareText ?? '${widget.title}\n${widget.url}',
      );
    } catch (_) {
      await ShareSheet.shareLink(widget.title, widget.url, text: widget.shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 22 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: _sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.heading,
                style: const TextStyle(color: _goldBright, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: widget.url,
                    version: QrVersions.auto,
                    size: 170,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  widget.url,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.ios_share_rounded,
                      label: 'اشتراک‌گذاری',
                      onTap: () => ShareSheet.shareLink(widget.title, widget.url, text: widget.shareText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.link_rounded,
                      label: 'کپی لینک',
                      onTap: () => ShareSheet.copyLink(context, widget.url),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'اشتراک QR',
                      onTap: _shareQr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.open_in_new_rounded,
                      label: 'باز کردن صفحه',
                      onTap: () => ShareSheet.openPage(widget.url),
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

/// کاشی مرتب: آیکون بالا، نام پایین
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xff0d2537),
          border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: _gold, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _goldBright, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// یک کلید اشتراک‌گذاری زیبا؛ با لمس آن برگه‌ی گزینه‌ها (QR، کپی لینک،
/// اشتراک، باز کردن صفحه، اشتراک QR) باز می‌شود.
///  - compact: کلید کوچک (مثلاً بالای متن توضیحات، سمت چپ)
///  - wide: کلید تمام‌عرض (مثلاً بعد از کلید وب‌سایت)
class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.wide = false,
    this.label = 'اشتراک‌گذاری',
  });

  final String entityType;
  final String entityId;
  final String title;
  final bool wide;
  final String label;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: wide ? 52 : 38,
      padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wide ? 16 : 20),
        gradient: const LinearGradient(colors: [_gold, _goldBright]),
        boxShadow: [
          BoxShadow(color: _gold.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ios_share_rounded, color: const Color(0xff3a2a00), size: wide ? 21 : 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xff3a2a00),
              fontSize: wide ? 14 : 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(wide ? 16 : 20),
        onTap: () => ShareSheet.show(
          context,
          entityType: entityType,
          entityId: entityId,
          title: title,
        ),
        child: child,
      ),
    );
  }
}

/// آیکون کوچک اشتراک (برای AppBar)
class ShareIconButton extends StatelessWidget {
  const ShareIconButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.color = _gold,
  });

  final String entityType;
  final String entityId;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'اشتراک‌گذاری',
      icon: Icon(Icons.ios_share_rounded, color: color),
      onPressed: () => ShareSheet.show(
        context,
        entityType: entityType,
        entityId: entityId,
        title: title,
      ),
    );
  }
}
