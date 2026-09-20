import 'package:flutter/material.dart';

import '../../models/showcase_item.dart';
import '../../services/showcase_service.dart';

const Color _cardDark = Color(0xff0a1c28);
const Color _gold = Color(0xffffd36a);

String showcaseFormatDuration(int seconds, {bool persianDigits = false}) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  var out = '$m:${s.toString().padLeft(2, '0')}';
  if (persianDigits) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll('$i', fa[i]);
    }
  }
  return out;
}

/// کاور ۱۶:۹ کارت — کاور سرور / کاور واقعی آپارات / تصویر محلی / آیکون.
/// همیشه کل قاب را پر می‌کند (بدون نوار سیاه).
class ShowcaseCover extends StatefulWidget {
  const ShowcaseCover({
    super.key,
    required this.item,
    required this.fallbackIcon,
    this.lang = 'fa',
    this.showDuration = true,
  });

  final ShowcaseItem item;
  final IconData fallbackIcon;
  final String lang;
  final bool showDuration;

  @override
  State<ShowcaseCover> createState() => _ShowcaseCoverState();
}

class _ShowcaseCoverState extends State<ShowcaseCover> {
  AparatInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ShowcaseCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _info = null;
      _load();
    }
  }

  Future<void> _load() async {
    final hash = widget.item.aparatHash;
    if (hash == null || hash.isEmpty) return;
    final info = await AparatInfoLoader.fetch(hash);
    if (!mounted || info == null) return;
    setState(() => _info = info);
  }

  Widget _placeholder() {
    if (widget.item.kind.isVideoLike || widget.item.hasVideo) {
      return Image.asset(
        'assets/images/showcase-hub.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _iconBox(),
      );
    }
    return _iconBox();
  }

  Widget _iconBox() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff12384f), _cardDark],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(widget.fallbackIcon, color: _gold.withValues(alpha: 0.7), size: 38),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final url = (item.coverUrl != null && item.coverUrl!.isNotEmpty)
        ? item.coverUrl
        : _info?.coverUrl;

    Widget image;
    if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (item.coverAsset != null && item.coverAsset!.isNotEmpty) {
      image = Image.asset(
        item.coverAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    final seconds =
        item.durationSeconds ?? int.tryParse(_info?.duration ?? '');

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (widget.showDuration && seconds != null && seconds > 0)
          PositionedDirectional(
            bottom: 6,
            start: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                showcaseFormatDuration(seconds,
                    persianDigits: widget.lang == 'fa'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
