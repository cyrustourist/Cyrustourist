import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart' show SmartMapPage;

// ===================== رنگ‌ها و برند =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);
const Color _tealBright = Color(0xff6df5cf);

Color _goldA(double a) => _gold.withValues(alpha: a);

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در باز کردن لینک.')),
      );
    }
  }
}

// ============================================================
// مدل داده‌ی اقامتگاه برای این صفحه
// ============================================================
//
// فیلدها هم‌راستا با residences-data.js سایت هستند تا وقتی
// سیستم واقعی اقامتگاه‌ها (id/name/type/province/city/...) به
// اپ وصل شد، همین مدل مستقیماً از آن داده پر شود.

class ResidenceVideoData {
  const ResidenceVideoData({
    required this.name,
    required this.city,
    required this.description,
    required this.aparatHash,
    this.province,
    this.phone,
    this.instagramUrl,
    this.websiteUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
  });

  /// نام اقامتگاه
  final String name;

  /// شهر اقامتگاه
  final String city;

  /// استان (اختیاری)
  final String? province;

  /// توضیحات اقامتگاه
  final String description;

  /// هش ویدیوی آپارات (همان بخش بعد از videohash/ در لینک امبد)
  final String aparatHash;

  /// شماره تماس مستقیم (اگر فعال باشد)
  final String? phone;

  final String? instagramUrl;
  final String? websiteUrl;

  /// مختصات برای مسیریابی مستقیم؛ اگر خالی باشد، دکمه‌ی
  /// «مسیریابی» نقشه‌ی عمومی اپ را باز می‌کند.
  final double? latitude;
  final double? longitude;

  /// امتیاز ۰ تا ۵ و تعداد رأی‌دهندگان (اختیاری، فقط نمایشی)
  final double? rating;
  final int? ratingCount;
}

// ============================================================
// صفحه‌ی نمایش فیلم اقامتگاه
// ============================================================

class ResidenceVideoPage extends StatefulWidget {
  const ResidenceVideoPage({super.key, required this.data});

  final ResidenceVideoData data;

  @override
  State<ResidenceVideoPage> createState() => _ResidenceVideoPageState();
}

class _ResidenceVideoPageState extends State<ResidenceVideoPage> {
  ResidenceVideoData get _d => widget.data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _videoHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleBlock(),
                  const SizedBox(height: 18),
                  if (_d.description.trim().isNotEmpty) ...[
                    _sectionTitle('📝', 'درباره اقامتگاه'),
                    const SizedBox(height: 10),
                    Text(
                      _d.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.9,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _actionButtons(),
                  const SizedBox(height: 18),
                  if (_d.instagramUrl != null || _d.websiteUrl != null)
                    _linksRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- هدر ویدیو ----------

  Widget _videoHeader() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _AparatEmbedPlayer(aparatHash: _d.aparatHash),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, _bg.withValues(alpha: 0.9)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- عنوان + امتیاز ----------

  Widget _titleBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _d.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _goldBright, size: 15),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _d.province != null
                          ? '${_d.city}، ${_d.province}'
                          : _d.city,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _goldBright,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_d.rating != null) _ratingBadge(),
      ],
    );
  }

  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldA(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _gold, size: 16),
              const SizedBox(width: 3),
              Text(
                _d.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (_d.ratingCount != null) ...[
            const SizedBox(height: 2),
            Text(
              '${_d.ratingCount} رأی',
              style: const TextStyle(color: Colors.white38, fontSize: 9.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: _goldBright,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }

  // ---------- دکمه‌های عملیاتی ----------

  Widget _actionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _outlinedIconButton(
                icon: Icons.map_rounded,
                label: 'مسیریابی',
                onTap: _openRoute,
              ),
            ),
            if (_d.phone != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _outlinedIconButton(
                  icon: Icons.call_rounded,
                  label: 'تماس',
                  onTap: () => _openUrl(context, 'tel:${_d.phone}'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _openRoute() {
    if (_d.latitude != null && _d.longitude != null) {
      HapticFeedback.selectionClick();
      final url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${_d.latitude},${_d.longitude}';
      _openUrl(context, url);
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmartMapPage()),
    );
  }

  Widget _outlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: _goldA(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ---------- اینستاگرام / وب‌سایت ----------

  Widget _linksRow() {
    return Row(
      children: [
        if (_d.instagramUrl != null)
          Expanded(
            child: _linkChip(
              icon: Icons.camera_alt_rounded,
              label: 'اینستاگرام',
              onTap: () => _openUrl(context, _d.instagramUrl!),
            ),
          ),
        if (_d.instagramUrl != null && _d.websiteUrl != null)
          const SizedBox(width: 10),
        if (_d.websiteUrl != null)
          Expanded(
            child: _linkChip(
              icon: Icons.public_rounded,
              label: 'وب‌سایت',
              onTap: () => _openUrl(context, _d.websiteUrl!),
            ),
          ),
      ],
    );
  }

  Widget _linkChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _gold, size: 17),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// پخش‌کننده‌ی عمومی آپارات — مخصوص این صفحه (مستقل از VideoPage
// و از پخش‌کننده‌ی نمونه‌ی residence_register_page.dart)
// ============================================================

class _AparatEmbedPlayer extends StatefulWidget {
  const _AparatEmbedPlayer({required this.aparatHash});

  final String aparatHash;

  @override
  State<_AparatEmbedPlayer> createState() => _AparatEmbedPlayerState();
}

class _AparatEmbedPlayerState extends State<_AparatEmbedPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant _AparatEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aparatHash != widget.aparatHash) {
      _createController();
    }
  }

  void _createController() {
    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.aparatHash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('aparat.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: _gold),
          ),
        if (_failed)
          Container(
            color: _bg,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _gold, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'پخش ویدیو بارگذاری نشد',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _failed = false;
                      _loading = true;
                    });
                    _controller.reload();
                  },
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
