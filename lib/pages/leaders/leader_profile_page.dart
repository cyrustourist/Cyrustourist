import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/leader.dart';
import '../../services/public_link_service.dart';
import '../../widgets/share_sheet.dart';
import '../../services/video_favorites_service.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);
const Color _pink = Color(0xffff6b81);

/// صفحه‌ی پروفایل لیدر: هدر، امتیاز، معرفی، ویدئوی آپارات (داخل صفحه)،
/// راه‌های تماس، خدمات، و جدول «مشخصات کامل».
///
/// قلب علاقه‌مندی همان ذخیره‌سازی گالری «نمایش» را می‌خواند/می‌نویسد
/// (VideoFavoritesService)، پس در «برگزیده‌ها» زیر تب «لیدر» دیده می‌شود.
class LeaderProfilePage extends StatefulWidget {
  const LeaderProfilePage({super.key, required this.leader});

  final Leader leader;

  @override
  State<LeaderProfilePage> createState() => _LeaderProfilePageState();
}

class _LeaderProfilePageState extends State<LeaderProfilePage> {
  final VideoFavoritesService _favService = VideoFavoritesService();
  bool _isFav = false;

  Leader get leader => widget.leader;

  /// شماره‌ی لیدر در فهرست تأییدشده‌ها؛ ۰ یعنی نمونه‌ی معرفی (بدون قلب)
  int get _code => leaderCodeOf(leader);
  bool get _canFav => _code > 0;

  /// دقیقاً همان کلیدی که گالری «نمایش» برای این لیدر می‌سازد
  String get _favId => leader.introVideoUrl ?? 'leader:$_code';

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    if (!_canFav) return;
    try {
      final v = await _favService.isFavorite(_favId);
      if (mounted) setState(() => _isFav = v);
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (!_canFav) return;
    final image = leader.photoAsset ?? 'assets/images/showcase-hub.jpg';
    final added = await _favService.toggleFavorite({
      'title_fa': leader.name,
      'title_en': leader.name,
      'title_ar': leader.name,
      'location_fa': leader.city,
      'location_en': leader.city,
      'location_ar': leader.city,
      'category_fa': leader.specialty,
      'category_en': leader.specialty,
      'category_ar': leader.specialty,
      'kind': 'leader',
      'code': '$_code',
      'image': image,
      'url': _favId,
    });
    if (!mounted) return;
    setState(() => _isFav = added);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff13364b),
        behavior: SnackBarBehavior.floating,
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            added ? 'به برگزیده‌ها اضافه شد' : 'از برگزیده‌ها حذف شد',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(
            leader.name,
            style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_canFav)
              IconButton(
                tooltip: 'برگزیده‌ها',
                onPressed: _toggleFav,
                icon: Icon(
                  _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFav ? _pink : _gold,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: _gold.withValues(alpha: 0.15),
                      backgroundImage: leader.photoAsset != null ? AssetImage(leader.photoAsset!) : null,
                      child: leader.photoAsset == null
                          ? const Icon(Icons.person, color: _gold, size: 48)
                          : null,
                    ),
                    // آیکون اشتراک‌گذاری کنار عکس پروفایل → برگه‌ی گزینه‌ها
                    if (_canFav)
                      Positioned(
                        bottom: -2,
                        left: -6,
                        child: GestureDetector(
                          onTap: () => ShareSheet.show(
                            context,
                            entityType: PublicLinkService.guide,
                            entityId: '$_code',
                            title: leader.name,
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [_gold, _goldBright]),
                              border: Border.all(color: _bg, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.ios_share_rounded, color: Color(0xff3a2a00), size: 19),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  leader.name,
                  style: const TextStyle(color: _goldBright, fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              if (leader.title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    leader.title,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                  ),
                ),
              ],
              if (leader.code.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    leader.code,
                    style: TextStyle(
                      color: _gold.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (leader.isLocalLeader) _badge('لیدر محلی'),
                    if (leader.isLicensed) _badge('دارای مجوز'),
                    _statusBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_canFav) _favButton(),

              _sectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: _teal, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      leader.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${leader.reviewCount} نظر کاربران)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const Spacer(),
                    if (leader.experienceText.isNotEmpty)
                      Flexible(
                        child: Text(
                          leader.experienceText,
                          textAlign: TextAlign.left,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              if (leader.bio.isNotEmpty) _infoSection(title: 'معرفی لیدر', body: leader.bio),

              // ویدئوی معرفی: پخش داخل صفحه (آپارات)
              if (leader.aparatHash != null && leader.aparatHash!.isNotEmpty)
                _videoCard()
              else if (leader.introVideoUrl != null)
                _sectionCard(
                  child: InkWell(
                    onTap: () => _open(leader.introVideoUrl!),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: _teal, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'مشاهده ویدئوی معرفی',
                          style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              if (leader.regions.isNotEmpty)
                _chipsSection(
                  title: 'شهر و مناطق فعالیت',
                  icon: Icons.location_on_rounded,
                  items: leader.regions,
                ),

              if (leader.languages.isNotEmpty)
                _chipsSection(
                  title: 'زبان‌ها',
                  icon: Icons.language_rounded,
                  items: leader.languages,
                ),

              _infoSection(title: 'زمینه تخصصی', body: leader.specialty),

              _contactCard(),

              if (leader.services.isNotEmpty) _servicesCard(),

              if (leader.tours.isNotEmpty && leader.services.isEmpty) ..._toursList(),

              if (leader.fields.isNotEmpty) _fieldsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // بخش‌ها
  // ------------------------------------------------------------

  Widget _favButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggleFav,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _isFav ? _pink.withValues(alpha: 0.16) : _card,
              border: Border.all(color: _isFav ? _pink.withValues(alpha: 0.7) : _gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFav ? _pink : _gold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFav ? 'در برگزیده‌های شما' : 'افزودن به برگزیده‌ها',
                  style: TextStyle(
                    color: _isFav ? _pink : _goldBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: _teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'ویدئوی معرفی',
                  style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _AparatPlayer(hash: leader.aparatHash!),
          ),
        ],
      ),
    );
  }

  Widget _contactCard() {
    final items = <(IconData, String, VoidCallback)>[];
    final mobile = leader.mobile;
    if (mobile != null && mobile.isNotEmpty) {
      items.add((Icons.call_rounded, 'تماس با لیدر', () => _open('tel:$mobile')));
    }
    final email = leader.email;
    if (email != null && email.isNotEmpty) {
      items.add((Icons.email_rounded, 'ایمیل', () => _open('mailto:$email')));
    }
    if (leader.website != null && leader.website!.isNotEmpty) {
      items.add((Icons.language_rounded, 'وب‌سایت', () => _open(leader.website!)));
    }
    if (leader.instagram != null && leader.instagram!.isNotEmpty) {
      items.add((Icons.camera_alt_rounded, 'اینستاگرام', () => _open(leader.instagram!)));
    }
    if (leader.aparatChannel != null && leader.aparatChannel!.isNotEmpty) {
      items.add((Icons.ondemand_video_rounded, 'آپارات', () => _open(leader.aparatChannel!)));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone_rounded, color: _gold, size: 16),
              SizedBox(width: 6),
              Text(
                'ارتباط با لیدر',
                style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: e.$3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _gold.withValues(alpha: 0.10),
                        border: Border.all(color: _gold.withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(e.$1, color: _gold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            e.$2,
                            style: const TextStyle(color: _goldBright, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _servicesCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tour_rounded, color: _gold, size: 16),
              SizedBox(width: 6),
              Text(
                'خدمات و تورهای قابل ارائه',
                style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: leader.services
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: (s.available ? _teal : Colors.white).withValues(alpha: 0.10),
                      border: Border.all(
                        color: (s.available ? _teal : Colors.white).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          s.title,
                          style: TextStyle(
                            color: s.available ? Colors.white : Colors.white54,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (s.available) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_rounded, color: _teal, size: 14),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _toursList() {
    return [
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          'تورهای ارائه‌شده توسط این لیدر',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      ...leader.tours.map(
        (t) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tour_rounded, color: _gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (t.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          t.description,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _fieldsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          iconColor: _gold,
          collapsedIconColor: _gold,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: _gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'مشخصات کامل لیدر',
                style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(width: 8),
              Text(
                '(${leader.fields.length})',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            for (var i = 0; i < leader.fields.length; i++) _fieldRow(i + 1, leader.fields[i]),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(int index, LeaderField f) {
    final isLink = f.value.startsWith('http');
    final valueWidget = Text(
      f.value,
      textAlign: TextAlign.left,
      style: TextStyle(
        color: isLink ? _teal : Colors.white.withValues(alpha: 0.88),
        fontSize: 12,
        height: 1.5,
        decoration: isLink ? TextDecoration.underline : null,
        decorationColor: _teal,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              style: TextStyle(color: _gold.withValues(alpha: 0.6), fontSize: 10.5),
            ),
          ),
          Text(f.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          SizedBox(
            width: 112,
            child: Text(
              f.label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, height: 1.5),
            ),
          ),
          Expanded(
            child: isLink
                ? InkWell(onTap: () => _open(f.value), child: valueWidget)
                : valueWidget,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final status = leader.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.labelFa(),
            style: TextStyle(color: status.color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  Widget _infoSection({required String title, required String body}) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _chipsSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// پخش‌کننده‌ی آپارات داخل صفحه (همان آدرس embed که صفحه‌ی فیلم‌ها استفاده می‌کند)
class _AparatPlayer extends StatefulWidget {
  const _AparatPlayer({required this.hash});

  final String hash;

  @override
  State<_AparatPlayer> createState() => _AparatPlayerState();
}

class _AparatPlayerState extends State<_AparatPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.hash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() {
              _loading = true;
              _failed = false;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() {
              _loading = false;
              _failed = true;
            });
          },
          onNavigationRequest: (request) => request.url.contains('aparat.com')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
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
