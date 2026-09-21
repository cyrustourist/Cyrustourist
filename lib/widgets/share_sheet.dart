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
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheetBody(
        url: PublicLinkService.entityUrl(entityType, entityId),
        title: title,
        autoShareQr: autoShareQr,
      ),
    );
  }

  static Future<void> shareLink(String title, String url) async {
    try {
      await Share.share('$title\n$url', subject: title);
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
  });

  final String url;
  final String title;
  final bool autoShareQr;

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
        text: '${widget.title}\n${widget.url}',
      );
    } catch (_) {
      await ShareSheet.shareLink(widget.title, widget.url);
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
              const Text(
                'اشتراک‌گذاری',
                style: TextStyle(color: _goldBright, fontSize: 16, fontWeight: FontWeight.w900),
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
              ShareActionsWrap(
                title: widget.title,
                url: widget.url,
                onShareQr: _shareQr,
                showQrButton: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دکمه‌های اشتراک (برای صفحه‌ی جزئیات و برگه‌ی اشتراک).
class ShareActionsWrap extends StatelessWidget {
  const ShareActionsWrap({
    super.key,
    required this.title,
    required this.url,
    this.onQr,
    this.onShareQr,
    this.showQrButton = true,
  });

  final String title;
  final String url;
  final VoidCallback? onQr;
  final VoidCallback? onShareQr;
  final bool showQrButton;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.ios_share_rounded, 'اشتراک‌گذاری', () => ShareSheet.shareLink(title, url)),
      (Icons.link_rounded, 'کپی لینک', () => ShareSheet.copyLink(context, url)),
      if (showQrButton && onQr != null) (Icons.qr_code_2_rounded, 'QR Code', onQr!),
      (Icons.open_in_new_rounded, 'باز کردن صفحه', () => ShareSheet.openPage(url)),
      if (onShareQr != null) (Icons.qr_code_scanner_rounded, 'اشتراک QR', onShareQr!),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (e) => InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: e.$3,
              child: Container(
                width: 104,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color(0xff0d2537),
                  border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.$1, color: _gold, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        e.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _goldBright, fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// کارت «اشتراک‌گذاری» آماده برای هر صفحه‌ی جزئیات (تور، فیلم ویژه، ...)
/// با ۵ گزینه‌ی دستورکار: اشتراک‌گذاری، کپی لینک، QR Code، باز کردن صفحه، اشتراک QR.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.heading = 'اشتراک‌گذاری',
  });

  final String entityType;
  final String entityId;
  final String title;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final url = PublicLinkService.entityUrl(entityType, entityId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff0b2636),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ios_share_rounded, color: _gold, size: 17),
              const SizedBox(width: 6),
              Text(
                heading,
                style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShareActionsWrap(
            title: title,
            url: url,
            onQr: () => ShareSheet.show(
              context,
              entityType: entityType,
              entityId: entityId,
              title: title,
            ),
            onShareQr: () => ShareSheet.show(
              context,
              entityType: entityType,
              entityId: entityId,
              title: title,
              autoShareQr: true,
            ),
          ),
        ],
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
