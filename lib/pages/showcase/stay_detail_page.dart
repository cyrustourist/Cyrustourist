import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/carto_config.dart';
import '../../core/language/app_language.dart';
import '../../models/showcase_item.dart';
import '../../models/stay_details.dart';
import '../../services/public_link_service.dart';
import '../../services/video_favorites_service.dart';
import '../../widgets/aparat_embed_player.dart';
import '../../widgets/place_weather_card.dart';
import '../../widgets/brand_icons.dart';
import '../../widgets/share_sheet.dart';
import 'showcase_cover.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _cardSoft = Color(0xff0e2f43);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

/// ===============================================================
/// صفحه‌ی جزئیات اقامتگاه (نمایش ویژه)
/// ---------------------------------------------------------------
/// همه‌ی اطلاعات از ستون‌های جدول accommodations می‌آید:
///   نام/توضیح سه‌زبانه، نوع، ستاره، شهر، آدرس، مختصات، فیلم (آپارات)،
///   امکانات (۴۵ گزینه)، ساعت ورود/خروج، قوانین، تماس، رزرو مستقیم،
///   وب‌سایت‌ها و شبکه‌های اجتماعی.
/// بخشی که داده ندارد اصلاً نمایش داده نمی‌شود (صفحه‌ی خالی/ناقص نداریم).
/// ===============================================================
class StayDetailPage extends StatefulWidget {
  const StayDetailPage({super.key, required this.item});

  final ShowcaseItem item;

  @override
  State<StayDetailPage> createState() => _StayDetailPageState();
}

class _StayDetailPageState extends State<StayDetailPage> {
  final VideoFavoritesService _favService = VideoFavoritesService();
  bool _isFav = false;
  bool _playing = false;
  bool _descExpanded = false;
  bool _amenAll = false;

  ShowcaseItem get item => widget.item;

  /// همین صفحه برای «گردشگری سلامت» هم استفاده می‌شود؛ فقط عنوان‌ها عوض می‌شود.
  bool get _isHealth => item.kind == ShowcaseKind.health;
  StayDetails get stay => item.stay ?? const StayDetails();

  String get _lang {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      default:
        return 'en';
    }
  }

  bool get _rtl => _lang != 'en';

  String _tr(String fa, String en, String ar) {
    switch (_lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  /// متن اقامتگاه / متن سلامت
  String _ts(String fa, String en, String ar, String hFa, String hEn, String hAr) =>
      _isHealth ? _tr(hFa, hEn, hAr) : _tr(fa, en, ar);

  String get _favId => item.videoUrl ?? item.id;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    try {
      final ids = await _favService.loadFavoriteIds();
      if (!mounted) return;
      setState(() => _isFav = ids.contains(_favId));
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    try {
      final added = await _favService.toggleFavorite(item.toFavoriteMap());
      if (!mounted) return;
      setState(() => _isFav = added);
    } catch (_) {}
  }

  void _share() {
    ShareSheet.show(
      context,
      entityType: PublicLinkService.typeForShowcaseKind(item.kind),
      entityId: '${item.code}',
      title: item.title(_lang),
    );
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.contains(':')) u = 'https://$u';
    try {
      final ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
      if (!ok) _snack(_tr('امکان باز کردن لینک وجود ندارد.', 'Unable to open this link.', 'تعذر فتح هذا الرابط.'));
    } catch (_) {
      _snack(_tr('خطا در باز کردن لینک.', 'Error opening the link.', 'خطأ في فتح الرابط.'));
    }
  }

  String _digitsOnly(String p) => p.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _call(String phone) => _open('tel:${_digitsOnly(phone)}');

  void _callSheet() {
    final phones = stay.phones;
    if (phones.isEmpty) return;
    if (phones.length == 1) {
      _call(phones.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 14),
                Text(_ts('تماس با اقامتگاه', 'Call the property', 'الاتصال بالإقامة', 'تماس با مرکز', 'Call the center', 'الاتصال بالمركز'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                for (final p in phones)
                  ListTile(
                    leading: const Icon(Icons.call_rounded, color: _teal),
                    title: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 19),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: p));
                        _snack(_tr('کپی شد', 'Copied', 'تم النسخ'));
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _call(p);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRoute() {
    if (item.latitude != null && item.longitude != null) {
      _open('https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}');
    } else if ((stay.mapUrl ?? '').isNotEmpty) {
      _open(stay.mapUrl!);
    } else if ((stay.address ?? '').isNotEmpty) {
      _open('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(stay.address!)}');
    }
  }

  bool get _canRoute =>
      (item.latitude != null && item.longitude != null) ||
      (stay.mapUrl ?? '').isNotEmpty ||
      (stay.address ?? '').isNotEmpty;

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero(context)),
            SliverToBoxAdapter(child: _headerBlock()),
            SliverToBoxAdapter(child: _quickFacts()),
            SliverToBoxAdapter(child: _workDaysTable()),
            SliverToBoxAdapter(child: _description()),
            SliverToBoxAdapter(child: _socialSection()),
            SliverToBoxAdapter(child: _amenitiesSection()),
            SliverToBoxAdapter(child: _actions()),
            SliverToBoxAdapter(child: _rulesSection()),
            SliverToBoxAdapter(child: _mapSection()),
            SliverToBoxAdapter(child: _contactSection()),
            SliverToBoxAdapter(child: _bottomShare()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ---------------- هیرو: کاور یا فیلم ----------------

  Widget _hero(BuildContext context) {
    final hash = item.aparatHash;
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_playing && hash != null && hash.isNotEmpty)
                AparatEmbedPlayer(hash: hash)
              else
                ShowcaseCover(
                  item: item,
                  fallbackIcon: Icons.hotel_rounded,
                  lang: _lang,
                  showDuration: false,
                ),
              if (!_playing)
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x99000000), Color(0x00000000), Color(0xCC06121d)],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              if (!_playing && hash != null && hash.isNotEmpty)
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _playing = true),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(color: _gold, width: 1.6),
                        boxShadow: [
                          BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 22, spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: _gold, size: 42),
                    ),
                  ),
                ),
              if (!_playing && hash != null && hash.isNotEmpty)
                PositionedDirectional(
                  bottom: 12,
                  start: 14,
                  child: _pill(Icons.movie_rounded, _ts('فیلم اقامتگاه', 'Property film', 'فيلم الإقامة', 'فیلم معرفی مرکز', 'Center film', 'فيلم المركز')),
                ),
            ],
          ),
        ),
        PositionedDirectional(
          top: top + 6,
          start: 10,
          child: _roundBtn(Icons.arrow_back_rounded, () => Navigator.maybePop(context), flip: true),
        ),
        PositionedDirectional(
          top: top + 6,
          end: 10,
          child: Row(
            children: [
              _roundBtn(Icons.ios_share_rounded, _share),
              const SizedBox(width: 8),
              _roundBtn(
                _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                _toggleFav,
                color: _isFav ? const Color(0xffff6b81) : Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white, bool flip = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: _gold.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------- عنوان، ستاره، مکان، امتیاز ----------------

  Widget _starsRow(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 17,
            color: i < stars ? _gold : Colors.white24,
          ),
      ],
    );
  }

  Widget _headerBlock() {
    final title = item.title(_lang);
    final loc = item.location(_lang);
    final type = item.categoryLabel(_lang);
    final hasRating = item.rating != null && item.rating! > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((stay.ownerPhoto ?? '').isNotEmpty) ...[
            _ownerAvatar(),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type.isNotEmpty || item.tier != ShowcaseTier.normal)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (type.isNotEmpty) _tag(type, _teal),
                        if (item.tier == ShowcaseTier.vip) _tag('VIP', _gold),
                        if (item.tier == ShowcaseTier.sponsored)
                          _tag(_tr('ویژه', 'Featured', 'مميز'), _gold),
                      ],
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.4),
                ),
                if (stay.stars > 0) ...[
                  const SizedBox(height: 6),
                  _starsRow(stay.stars),
                ],
                if (loc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: _gold, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(loc,
                            style: const TextStyle(color: _goldBright, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasRating) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.rating!.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 3),
                      const Icon(Icons.star_rounded, color: _gold, size: 18),
                    ],
                  ),
                  if ((item.ratingCount ?? 0) > 0)
                    Text('${item.ratingCount} ${_tr('رأی', 'reviews', 'رأي')}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- عکس پروفایل مالک ----------------

  Widget _ownerAvatar() {
    final url = stay.ownerPhoto;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showOwnerPhoto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_goldBright, _gold, _teal],
                  ),
                  boxShadow: [
                    BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: _bg),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person_rounded, color: Colors.white38, size: 36),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                  ),
                  child: const Icon(Icons.verified_rounded, color: _bg, size: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tr('میزبان', 'Host', 'المضيف'),
          style: const TextStyle(color: _goldBright, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showOwnerPhoto() {
    final url = stay.ownerPhoto;
    if (url == null || url.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
    );
  }

  // ---------------- اطلاعات سریع: ورود، خروج، آسانسور، آدرس ----------------

  Widget _quickFacts() {
    final facts = <Widget>[
      if ((stay.checkIn ?? '').isNotEmpty)
        _fact(Icons.login_rounded, _ts('ساعت ورود', 'Check-in', 'وقت الدخول', 'ساعت کاری', 'Working hours', 'ساعات العمل'), stay.checkIn!),
      if (!_isHealth && (stay.checkOut ?? '').isNotEmpty)
        _fact(Icons.logout_rounded, _tr('ساعت خروج', 'Check-out', 'وقت الخروج'), stay.checkOut!),
      if (!_isHealth && stay.bedrooms > 0)
        _fact(Icons.bed_rounded, _tr('اتاق‌خواب', 'Bedrooms', 'غرف النوم'), '${stay.bedrooms}'),
      if (stay.hasElevator)
        _fact(Icons.elevator_rounded, _tr('آسانسور', 'Elevator', 'مصعد'), _tr('دارد', 'Yes', 'نعم')),
      if (stay.amenityKeys.isNotEmpty)
        _fact(Icons.checklist_rounded, _tr('امکانات', 'Amenities', 'المرافق'), '${stay.amenityKeys.length}'),
    ];

    final address = stay.address;
    if (facts.isEmpty && (address == null || address.isEmpty)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (facts.isNotEmpty)
            Wrap(spacing: 10, runSpacing: 10, children: facts),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_work_rounded, color: _gold, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(address,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.7)),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: address));
                      _snack(_tr('آدرس کپی شد', 'Address copied', 'تم نسخ العنوان'));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.copy_rounded, color: Colors.white38, size: 17),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fact(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_cardSoft, _card]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 21),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
        ],
      ),
    );
  }

  // ---------------- ساعت کاری و روزهای هفته (گردشگری سلامت) ----------------

  Widget _workDaysTable() {
    if (!_isHealth || stay.workDays.isEmpty) return const SizedBox.shrink();
    final hours = (stay.checkIn ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              Icons.event_available_rounded,
              _tr('روزها و ساعت کاری', 'Working days & hours', 'أيام وساعات العمل'),
            ),
            if (hours.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: _gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hours,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in StayWeekdays.all) _dayChip(d, stay.workDays.contains(d.key)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip(StayWeekday d, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: on ? _teal.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: on ? _teal.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: on ? _teal : Colors.white24,
          ),
          const SizedBox(width: 6),
          Text(
            d.label(_lang),
            style: TextStyle(
              color: on ? Colors.white : Colors.white38,
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- توضیحات ----------------

  Widget _description() {
    final desc = item.description(_lang);
    if (desc.isEmpty) return const SizedBox.shrink();
    final long = desc.length > 180;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.notes_rounded, _ts('درباره‌ی اقامتگاه', 'About this stay', 'عن الإقامة', 'درباره‌ی مرکز', 'About this center', 'عن المركز')),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: Text(
              desc,
              maxLines: _descExpanded || !long ? null : 4,
              overflow: _descExpanded || !long ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13.5, height: 1.9),
            ),
          ),
          if (long)
            InkWell(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _descExpanded ? _tr('کمتر', 'Less', 'أقل') : _tr('بیشتر', 'More', 'المزيد'),
                      style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Icon(_descExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: _gold, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _gold, size: 17),
        ),
        const SizedBox(width: 9),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ---------------- دکمه‌های اصلی ----------------

  Widget _actions() {
    final hasPhone = stay.phones.isNotEmpty;
    final hasBooking = (stay.bookingUrl ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          // آب‌وهوای همین مکان — بر اساس طول/عرض جغرافیایی پنل مدیریت (بالای مسیریابی)
          if (item.latitude != null && item.longitude != null) ...[
            PlaceWeatherCard(
              lat: item.latitude!,
              lon: item.longitude!,
              placeName: item.title(_lang),
            ),
            const SizedBox(height: 10),
          ],
          if (_canRoute)
            _primaryButton(
              icon: Icons.near_me_rounded,
              label: _tr('مسیریابی سریع', 'Quick route', 'المسار السريع'),
              onTap: _openRoute,
            ),
          if (hasBooking) ...[
            const SizedBox(height: 10),
            _goldButton(
              icon: Icons.event_available_rounded,
              label: _ts('رزرو مستقیم', 'Book directly', 'احجز مباشرة', 'نوبت‌دهی / رزرو', 'Book appointment', 'حجز موعد'),
              onTap: () => _open(stay.bookingUrl!),
            ),
          ],
          if (hasPhone) ...[
            const SizedBox(height: 10),
            _outlineButton(
              icon: Icons.call_rounded,
              label: _tr('تماس مستقیم', 'Call now', 'اتصال مباشر'),
              onTap: _callSheet,
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xff29e0ad), Color(0xff6df5cf)]),
        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _bg, size: 22),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: _bg, fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _goldButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 21),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _outlineButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: BorderSide(color: _gold.withValues(alpha: 0.65), width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  // ---------------- امکانات ----------------

  Widget _amenitiesSection() {
    final keys = stay.amenityKeys;
    final bedrooms = stay.bedrooms;
    if (keys.isEmpty && bedrooms <= 0) return const SizedBox.shrink();

    const limit = 8;
    final visible = (_amenAll || keys.length <= limit) ? keys : keys.take(limit).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.checklist_rounded, _ts('امکانات اقامتگاه', 'Amenities', 'مرافق الإقامة', 'امکانات و خدمات', 'Facilities & services', 'المرافق والخدمات')),
          const SizedBox(height: 12),
          if (!_isHealth && bedrooms > 0)
            _amenityRow(
              Icons.bed_rounded,
              _tr('تعداد اتاق‌خواب', 'Bedrooms', 'غرف النوم'),
              valueText: _tr('$bedrooms اتاق', '$bedrooms rooms', '$bedrooms غرف'),
            ),
          for (final k in visible)
            Builder(builder: (_) {
              final a = StayAmenities.resolve(k, panelLabels: stay.amenityLabels);
              return _amenityRow(a.icon, a.label(_lang));
            }),
          if (keys.length > limit)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _amenAll = !_amenAll),
                icon: Icon(_amenAll ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: _gold),
                label: Text(
                  _amenAll
                      ? _tr('نمایش کمتر', 'Show less', 'عرض أقل')
                      : _tr('نمایش همه (${keys.length})', 'Show all (${keys.length})', 'عرض الكل (${keys.length})'),
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amenityRow(IconData icon, String label, {String? valueText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_cardSoft, _card]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (valueText != null)
            Text(valueText, style: const TextStyle(color: _goldBright, fontSize: 14, fontWeight: FontWeight.w800))
          else
            const Icon(Icons.check_circle_rounded, color: _teal, size: 24),
        ],
      ),
    );
  }

  // ---------------- شبکه‌های اجتماعی و وب‌سایت ----------------

  Widget _socialSection() {
    final bubbles = <Widget>[];

    void add(String label, String? url, Widget icon, List<Color> colors) {
      if (url == null || url.trim().isEmpty) return;
      bubbles.add(_socialBubble(label, url, icon, colors));
    }

    const w = Colors.white;
    add('Instagram', item.instagramUrl, const Icon(Icons.camera_alt_rounded, color: w, size: 26),
        const [Color(0xfff58529), Color(0xffdd2a7b), Color(0xff8134af)]);
    add('Telegram', stay.telegram, const BrandIcon(BrandIcons.telegram, size: 27),
        const [Color(0xff2aabee), Color(0xff1d84c4)]);
    add('WhatsApp', stay.whatsapp, const BrandIcon(BrandIcons.whatsapp, size: 27),
        const [Color(0xff25d366), Color(0xff128c7e)]);
    add(_tr('ایتا', 'Eitaa', 'إيتا'), stay.eitaa, const BrandIcon(BrandIcons.eitaa, size: 27),
        const [Color(0xffffa000), Color(0xffe65100)]);
    add('YouTube', stay.youtube, const Icon(Icons.smart_display_rounded, color: w, size: 28),
        const [Color(0xffff3d3d), Color(0xffb30000)]);
    add(_tr('آپارات', 'Aparat', 'أباره'), stay.aparat, const Icon(Icons.ondemand_video_rounded, color: w, size: 26),
        const [Color(0xffed145b), Color(0xff8e0c36)]);
    add('TikTok', stay.tiktok, const Icon(Icons.music_note_rounded, color: w, size: 26),
        const [Color(0xff2b2b2b), Color(0xff000000)]);
    add(_tr('وب‌سایت', 'Website', 'الموقع'), item.websiteUrl, const Icon(Icons.language_rounded, color: _bg, size: 26),
        const [_teal, Color(0xff12a37f)]);
    add(_tr('وب‌سایت دوم', 'Website 2', 'الموقع 2'), stay.website2, const Icon(Icons.public_rounded, color: _bg, size: 26),
        const [_goldBright, _gold]);

    if (bubbles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.share_rounded, _tr('شبکه‌های اجتماعی', 'Social media', 'التواصل الاجتماعي')),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_cardSoft, _card],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _gold.withValues(alpha: 0.22)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: bubbles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialBubble(String label, String url, Widget icon, List<Color> colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _open(url),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(color: colors.first.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: icon,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- قوانین ----------------

  Widget _rulesSection() {
    final rules = stay.rules;
    if (rules == null || rules.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.gavel_rounded, _ts('قوانین اقامتگاه', 'House rules', 'قوانين الإقامة', 'قوانین و شرایط پذیرش', 'Terms & conditions', 'الشروط والأحكام')),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(rules,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.9)),
          ),
        ],
      ),
    );
  }

  // ---------------- نقشه ----------------

  Widget _mapSection() {
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null) return const SizedBox.shrink();
    final point = LatLng(lat, lng);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.map_rounded, _tr('موقعیت روی نقشه', 'Location', 'الموقع على الخريطة')),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 190,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 14.5,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: CartoConfig.tileUrlWithKey,
                        userAgentPackageName: 'com.cyrustourist.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 46,
                            height: 46,
                            child: const Icon(Icons.location_on_rounded, color: Color(0xffe5484d), size: 46),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: _openRoute),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 10,
                    end: 10,
                    child: _pill(Icons.near_me_rounded, _tr('مسیریابی', 'Directions', 'الاتجاهات')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- تماس و شبکه‌های اجتماعی ----------------

  Widget _contactSection() {
    final tiles = <Widget>[];

    void add(IconData icon, String label, String? value, VoidCallback onTap) {
      if (value == null || value.trim().isEmpty) return;
      tiles.add(_linkTile(icon, label, onTap));
    }

    add(Icons.mail_rounded, _tr('ایمیل', 'Email', 'البريد'), stay.email, () => _open('mailto:${stay.email}'));

    final phones = stay.phones;
    if (tiles.isEmpty && phones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.contacts_rounded, _tr('تماس و ارتباط', 'Contact', 'التواصل')),
          const SizedBox(height: 12),
          if (phones.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < phones.length; i++)
                    InkWell(
                      onTap: () => _call(phones[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              i == 0 ? Icons.smartphone_rounded : Icons.call_rounded,
                              color: _teal,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(phones[i],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const Icon(Icons.call_made_rounded, color: Colors.white30, size: 16),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (tiles.isNotEmpty)
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [for (final t in tiles) SizedBox(width: w, child: t)],
              );
            }),
        ],
      ),
    );
  }

  Widget _linkTile(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomShare() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: _goldButton(
        icon: Icons.ios_share_rounded,
        label: _tr('اشتراک‌گذاری', 'Share', 'مشاركة'),
        onTap: _share,
      ),
    );
  }
}
