import 'dart:async';
import 'dart:convert';

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
/// تبلیغ‌های فعالِ پنل (به ترتیب `sort_order`) اول نمایش داده می‌شوند و
/// بعد از آن‌ها [defaultAssets] (عکس‌های پیش‌فرض داخل اپ) در همان چرخش
/// می‌آیند؛ اگر پنل چیزی نداشت یا جواب نداد، فوراً فقط عکس‌های داخلی.
///
/// برای این‌که در بازِ اول (پیش از پاسخ سرور) صفحه خالی/زشت دیده نشود،
/// عکس‌های پیش‌فرض همان لحظه‌ی اول (به‌صورت sync) نمایش داده می‌شوند؛
/// به‌محض رسیدن پاسخ سرور، در صورت وجود تبلیغ فعال، جای آن‌ها را
/// می‌گیرند (به ترتیب `sort_order`).
class CyrusAdBanner extends StatefulWidget {
  const CyrusAdBanner({
    super.key,
    required this.slot,
    this.borderRadius = 10,
    this.defaultAssets = const [],
    this.onDefaultTap,
  });

  /// جایگاه تبلیغ (۱، ۲ یا ۳).
  final int slot;

  final double borderRadius;

  /// مسیر عکس‌های پیش‌فرض محلی این جایگاه (وقتی دیتابیس خالی است).
  final List<String> defaultAssets;

  /// وقتی روی یکی از عکس‌های پیش‌فرض (بدون لینک از سرور) لمس می‌شود.
  /// برای هر ۴ عکس پیش‌فرض (۲تای جایگاه ۱ و ۲تای جایگاه ۲) باید به
  /// صفحه‌ی ثبت‌نام اقامتگاه هدایت شود، دقیقاً مثل بقیه‌ی نقاط ثبت‌نام.
  final VoidCallback? onDefaultTap;

  @override
  State<CyrusAdBanner> createState() => _CyrusAdBannerState();
}

class _CyrusAdBannerState extends State<CyrusAdBanner> {
  late List<_AdBannerItem> _items;
  int _index = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    // فوری، بدون معطلی برای پاسخ سرور: عکس‌های پیش‌فرض همین الان نمایش
    // داده می‌شوند تا فضای تبلیغ هرگز خالی/زشت دیده نشود.
    _items = _defaultItems();
    _startRotationIfNeeded();
    _load();
  }

  @override
  void didUpdateWidget(covariant CyrusAdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot != widget.slot) {
      _rotationTimer?.cancel();
      _index = 0;
      _items = _defaultItems();
      _startRotationIfNeeded();
      _load();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  List<_AdBannerItem> _defaultItems() => widget.defaultAssets
      .map(
        (path) => _AdBannerItem(
          imageProvider: AssetImage(path),
          linkUrl: null,
          key: path,
        ),
      )
      .toList();

  /// پنل تبلیغات عکس را گاهی به‌صورت data:image/webp;base64 در دیتابیس
  /// ذخیره می‌کند؛ NetworkImage این نوع آدرس را نمی‌خواند و بنر خالی
  /// می‌ماند، پس برای آن‌ها MemoryImage ساخته می‌شود.
  ImageProvider _providerFor(String url) {
    if (url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        return MemoryImage(base64Decode(url.substring(comma + 1)));
      } catch (_) {
        // داده خراب؛ در ادامه errorBuilder بنر را خالی می‌کند.
      }
    }
    return NetworkImage(url);
  }

  Future<void> _load() async {
    final ads = await AdvertisementService.instance.fetchAds(widget.slot);

    if (!mounted) return;

    // اگر سرور چیزی برای این جایگاه نداشت، همان عکس‌های پیش‌فرض که از
    // ابتدا نمایش داده شده‌اند باقی می‌مانند (نیازی به تغییر نیست).
    if (ads.isEmpty) return;

    final dbItems = ads
        .map(
          (ad) => _AdBannerItem(
            imageProvider: _providerFor(ad.imageUrl),
            linkUrl: ad.linkUrl,
            key: 'db_${ad.id}',
          ),
        )
        .toList();

    // ترکیبی: ابتدا تبلیغ‌های پنل (به ترتیب sort_order)، سپس عکس‌های
    // پیش‌فرض داخل اپ؛ هر دو گروه در یک چرخش پشت‌سرهم نمایش داده می‌شوند.
    setState(() {
      _items = [...dbItems, ..._defaultItems()];
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

  /// اگر عکس یک تبلیغ (لینک خراب/نبود اینترنت) بار نشد، از چرخش حذف می‌شود
  /// تا بنر خالی نماند و نوبت به مورد بعدی برسد.
  void _skipBrokenItem(Object key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _items.length < 2) return;
      final broken = _items.indexWhere((e) => e.key == key);
      if (broken == -1) return;
      setState(() {
        _items = List<_AdBannerItem>.of(_items)..removeAt(broken);
        _index = _index % _items.length;
      });
      _startRotationIfNeeded();
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
    final hasServerLink = item.linkUrl != null && item.linkUrl!.isNotEmpty;

    // عکس‌های پیش‌فرض لینک سرور ندارند؛ با لمس آن‌ها به صفحه‌ی ثبت‌نام
    // اقامتگاه هدایت می‌شویم (دقیقاً مثل بقیه‌ی نقاط ثبت‌نام در اپ).
    final VoidCallback? onTap = hasServerLink
        ? _openCurrentLink
        : widget.onDefaultTap;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Image(
              image: item.imageProvider,
              key: ValueKey(item.key),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                _skipBrokenItem(item.key);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
