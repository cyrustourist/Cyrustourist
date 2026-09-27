import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cyrus_advertisement.dart';
import '../services/advertisement_service.dart';

/// یک آیتم قابل‌نمایش در بنر تبلیغاتی — یا یک تبلیغ واقعی از دیتابیس
/// (تصویر شبکه + لینک قابل‌لمس) یا یک تصویر پیش‌فرض محلی (بدون لینک).
class _AdBannerItem {
  const _AdBannerItem({
    required this.imageProvider,
    this.linkUrl,
    required this.key,
  });

  final ImageProvider imageProvider;
  final String? linkUrl;
  final Object key;
}

/// بنر تبلیغاتی یک جایگاه (۱ یا ۲) — روی جعبه‌ی طلایی خالیِ از قبل در
/// تصویر صفحه‌ی اصلی قرار می‌گیرد.
///
/// اولویت با تبلیغ‌های فعالِ همان جایگاه در دیتابیس است (به ترتیب
/// `sort_order`)؛ اگر دیتابیس برای این جایگاه چیزی نداشت، به‌جای فضای
/// خالی، بین [defaultAssets] (دو عکس پیش‌فرض داخل خود اپ) می‌چرخد.
class CyrusAdBanner extends StatefulWidget {
  const CyrusAdBanner({
    super.key,
    required this.slot,
    this.borderRadius = 10,
    this.defaultAssets = const [],
  });

  /// جایگاه تبلیغ (۱، ۲ یا ۳).
  final int slot;

  final double borderRadius;

  /// مسیر عکس‌های پیش‌فرض محلی این جایگاه (وقتی دیتابیس خالی است).
  final List<String> defaultAssets;

  @override
  State<CyrusAdBanner> createState() => _CyrusAdBannerState();
}

class _CyrusAdBannerState extends State<CyrusAdBanner> {
  List<_AdBannerItem> _items = const [];
  int _index = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CyrusAdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot != widget.slot) {
      _rotationTimer?.cancel();
      _index = 0;
      _load();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final ads = await AdvertisementService.instance.fetchAds(widget.slot);

    if (!mounted) return;

    final items = ads.isNotEmpty
        ? ads
            .map(
              (ad) => _AdBannerItem(
                imageProvider: NetworkImage(ad.imageUrl),
                linkUrl: ad.linkUrl,
                key: 'db_${ad.id}',
              ),
            )
            .toList()
        : widget.defaultAssets
            .map(
              (path) => _AdBannerItem(
                imageProvider: AssetImage(path),
                linkUrl: null,
                key: path,
              ),
            )
            .toList();

    setState(() {
      _items = items;
      _index = 0;
    });

    _startRotationIfNeeded();
  }

  void _startRotationIfNeeded() {
    _rotationTimer?.cancel();

    if (_items.length < 2) {
      return;
    }

    _rotationTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;

      setState(() {
        _index = (_index + 1) % _items.length;
      });
    });
  }

  Future<void> _openCurrentLink() async {
    if (_items.isEmpty) return;

    final url = _items[_index].linkUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // بی‌سروصدا نادیده گرفته می‌شود؛ تبلیغ نباید باعث کرش اپ شود.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = _items[_index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.linkUrl == null ? null : _openCurrentLink,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Image(
              image: item.imageProvider,
              key: ValueKey(item.key),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
