import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';
import '../map_place.dart';
import '../models/showcase_item.dart';
import '../services/map_place_favorites_service.dart';
import '../services/video_favorites_service.dart';
import '../models/leader.dart';
import 'category_explorer_page.dart';
import 'leaders/leader_profile_page.dart';
import 'showcase/showcase_gallery_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _pink = Color(0xffff6b81);

/// صفحه مرکزی «برگزیده‌ها».
///
/// مهم: این صفحه از همان ذخیره‌سازی‌های فعلی استفاده می‌کند تا علاقه‌مندی‌های
/// نقشه و نمایش‌ها از بین نروند. Login/Notifications و Worker دست‌نخورده‌اند.
///
/// هر کارت یک «منبع» دارد:
///  - 📍 ذخیره از نقشه (برای مسیریابی)
///  - ▶ ذخیره از نمایش (فیلم، اقامتگاه، سلامت، لیدر، آژانس، جاذبه)
enum _FavCategory { all, accommodation, video, attraction, health, leader, agency }

const Map<String, Map<String, String>> _t = {
  'title': {'fa': 'برگزیده‌های من', 'en': 'My Favorites', 'ar': 'المفضلة لدي'},
  'subtitle': {
    'fa': 'همه‌ی علاقه‌مندی‌های شما، در یک صفحه — با فیلتر و شمارش هر بخش',
    'en': 'All your favorites in one place — filter and count per section',
    'ar': 'كل مفضلاتك في مكان واحد — مع تصفية وعدد لكل قسم',
  },
  'all': {'fa': 'همه', 'en': 'All', 'ar': 'الكل'},
  'accommodation': {'fa': 'اقامتگاه', 'en': 'Stays', 'ar': 'الإقامة'},
  'video': {'fa': 'فیلم', 'en': 'Videos', 'ar': 'الفيديو'},
  'attraction': {'fa': 'جاذبه', 'en': 'Attractions', 'ar': 'المعالم'},
  'health': {'fa': 'سلامت', 'en': 'Health', 'ar': 'الصحة'},
  'leader': {'fa': 'لیدر', 'en': 'Leaders', 'ar': 'المرشدون'},
  'agency': {'fa': 'آژانس', 'en': 'Agencies', 'ar': 'الوكالات'},
  'empty': {
    'fa': 'هنوز موردی در این بخش ذخیره نشده است',
    'en': 'No saved items in this section yet',
    'ar': 'لا توجد عناصر محفوظة في هذا القسم بعد',
  },
  'open': {'fa': 'مشاهده', 'en': 'View', 'ar': 'عرض'},
  'maps': {'fa': 'مکان روی نقشه', 'en': 'Map place', 'ar': 'المكان على الخريطة'},
  'videoLabel': {'fa': 'فیلم گردشگری', 'en': 'Tourism video', 'ar': 'فيديو سياحي'},
  'fromMap': {'fa': 'ذخیره از نقشه — برای مسیریابی', 'en': 'Saved from map — for navigation', 'ar': 'محفوظ من الخريطة — للتنقل'},
  'fromShowcase': {'fa': 'ذخیره از نمایش فیلم', 'en': 'Saved from showcase', 'ar': 'محفوظ من العرض'},
  'removed': {'fa': 'از برگزیده‌ها حذف شد', 'en': 'Removed from favorites', 'ar': 'تمت الإزالة من المفضلة'},
  'undo': {'fa': 'بازگرداندن', 'en': 'Undo', 'ar': 'تراجع'},
  'tagHealth': {'fa': 'گردشگری سلامت', 'en': 'Health tourism', 'ar': 'السياحة العلاجية'},
  'tagAttraction': {'fa': 'جاذبه گردشگری', 'en': 'Tourist attraction', 'ar': 'معلم سياحي'},
  'tagStay': {'fa': 'اقامتگاه', 'en': 'Accommodation', 'ar': 'إقامة'},
  'tagLeader': {'fa': 'لیدر گردشگری', 'en': 'Tour leader', 'ar': 'مرشد سياحي'},
  'tagAgency': {'fa': 'آژانس مسافرتی', 'en': 'Travel agency', 'ar': 'وكالة سفر'},
};

/// یک ردیف یکپارچه‌ی برگزیده (چه از نقشه، چه از نمایش)
class _FavEntry {
  _FavEntry({
    required this.category,
    required this.fromMap,
    required this.title,
    required this.tag,
    required this.image,
    this.place,
    this.video,
  });

  final _FavCategory category;
  final bool fromMap;
  final String title;
  final String tag;
  final String? image;
  final MapPlace? place;
  final Map<String, String>? video;
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MapPlaceFavoritesService _placeFavorites = MapPlaceFavoritesService();
  final VideoFavoritesService _videoFavorites = VideoFavoritesService();

  List<MapPlace> _places = [];
  List<Map<String, String>> _videos = [];
  bool _loading = true;
  _FavCategory _selected = _FavCategory.all;

  String get _lang => MenuLanguage.current;
  bool get _rtl => MenuLanguage.isRtl;

  String _tr(String key) {
    final map = _t[key] ?? const {};
    return map[_lang] ?? map['en'] ?? map['fa'] ?? '';
  }

  /// ارقام فارسی/عربی برای شمارنده‌ها
  String _num(int n) {
    final s = '$n';
    if (_lang == 'fa') {
      const d = '۰۱۲۳۴۵۶۷۸۹';
      return s.split('').map((c) => d[int.parse(c)]).join();
    }
    if (_lang == 'ar') {
      const d = '٠١٢٣٤٥٦٧٨٩';
      return s.split('').map((c) => d[int.parse(c)]).join();
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final places = await _placeFavorites.loadFavorites();
    final videos = await _videoFavorites.loadFavorites();
    if (!mounted) return;
    setState(() {
      _places = places;
      _videos = videos;
      _loading = false;
    });
  }

  // ------------------------------------------------------------
  // حذف با امکان بازگرداندن
  // ------------------------------------------------------------

  Future<void> _remove(_FavEntry e) async {
    if (e.place != null) {
      await _placeFavorites.toggleFavorite(e.place!);
    } else if (e.video != null) {
      await _videoFavorites.toggleFavorite(e.video!);
    }
    await _loadAll();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff13364b),
        behavior: SnackBarBehavior.floating,
        content: Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Text(_tr('removed'), style: const TextStyle(color: Colors.white)),
        ),
        action: SnackBarAction(
          label: _tr('undo'),
          textColor: _gold,
          onPressed: () async {
            // toggle دوباره = برگرداندن
            if (e.place != null) {
              await _placeFavorites.toggleFavorite(e.place!);
            } else if (e.video != null) {
              await _videoFavorites.toggleFavorite(e.video!);
            }
            await _loadAll();
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // تبدیل داده‌ها به ردیف‌های یکپارچه
  // ------------------------------------------------------------

  String _videoText(Map<String, String> video, String key) {
    final v = video['${key}_$_lang'];
    if (v != null && v.isNotEmpty) return v;
    return video['${key}_fa'] ?? video['${key}_en'] ?? '';
  }

  String _videoKind(Map<String, String> video) {
    final kind = (video['kind'] ?? '').toLowerCase().trim();
    if (kind.isNotEmpty) return kind;
    final text =
        '${video['category_fa'] ?? ''} ${video['category_en'] ?? ''} ${video['category_ar'] ?? ''}'.toLowerCase();
    if (text.contains('leader') || text.contains('لیدر') || text.contains('قائد')) return 'leader';
    if (text.contains('health') || text.contains('سلامت') || text.contains('صحة') || text.contains('علاج')) return 'health';
    if (text.contains('accommodation') || text.contains('اقامت') || text.contains('hotel') || text.contains('هتل')) return 'accommodation';
    if (text.contains('agency') || text.contains('آژانس')) return 'agency';
    if (text.contains('attraction') || text.contains('جاذبه') || text.contains('معلم')) return 'attraction';
    return 'video';
  }

  _FavCategory _categoryOfKind(String kind) {
    switch (kind) {
      case 'leader':
        return _FavCategory.leader;
      case 'health':
        return _FavCategory.health;
      case 'accommodation':
        return _FavCategory.accommodation;
      case 'attraction':
        return _FavCategory.attraction;
      case 'agency':
        return _FavCategory.agency;
      default:
        return _FavCategory.video;
    }
  }

  _FavCategory _categoryOfPlace(MapPlace p) {
    switch (p.category) {
      case PlaceCategory.health:
        return _FavCategory.health;
      case PlaceCategory.attraction:
        return _FavCategory.attraction;
      case PlaceCategory.accommodation:
        return _FavCategory.accommodation;
      default:
        // رستوران/فرهنگ/خدمات/... فقط در «همه» دیده می‌شوند
        return _FavCategory.all;
    }
  }

  String _tagOf(_FavCategory c) {
    switch (c) {
      case _FavCategory.health:
        return _tr('tagHealth');
      case _FavCategory.attraction:
        return _tr('tagAttraction');
      case _FavCategory.accommodation:
        return _tr('tagStay');
      case _FavCategory.leader:
        return _tr('tagLeader');
      case _FavCategory.agency:
        return _tr('tagAgency');
      default:
        return _tr('videoLabel');
    }
  }

  List<_FavEntry> get _entries {
    final list = <_FavEntry>[];
    for (final p in _places) {
      final c = _categoryOfPlace(p);
      list.add(_FavEntry(
        category: c,
        fromMap: true,
        title: p.name,
        tag: c == _FavCategory.all ? _tr('maps') : _tagOf(c),
        image: p.imageUrl,
        place: p,
      ));
    }
    for (final v in _videos) {
      final c = _categoryOfKind(_videoKind(v));
      final title = _videoText(v, 'title');
      list.add(_FavEntry(
        category: c,
        fromMap: false,
        title: title.isEmpty ? _tagOf(c) : title,
        tag: _tagOf(c),
        image: v['image'],
        video: v,
      ));
    }
    return list;
  }

  int _countOf(List<_FavEntry> all, _FavCategory c) =>
      c == _FavCategory.all ? all.length : all.where((e) => e.category == c).length;

  // ------------------------------------------------------------
  // ظاهر هر دسته: رنگ و آیکون
  // ------------------------------------------------------------

  Color _accent(_FavCategory c) {
    switch (c) {
      case _FavCategory.accommodation:
        return const Color(0xff29e0ad);
      case _FavCategory.video:
        return const Color(0xffa78bfa);
      case _FavCategory.attraction:
        return const Color(0xffffb84d);
      case _FavCategory.health:
        return const Color(0xff4ade80);
      case _FavCategory.leader:
        return const Color(0xff60a5fa);
      case _FavCategory.agency:
        return const Color(0xfff472b6);
      case _FavCategory.all:
        return _gold;
    }
  }

  IconData _icon(_FavCategory c) {
    switch (c) {
      case _FavCategory.accommodation:
        return Icons.hotel_rounded;
      case _FavCategory.video:
        return Icons.movie_creation_rounded;
      case _FavCategory.attraction:
        return Icons.landscape_rounded;
      case _FavCategory.health:
        return Icons.local_hospital_rounded;
      case _FavCategory.leader:
        return Icons.explore_rounded;
      case _FavCategory.agency:
        return Icons.business_rounded;
      case _FavCategory.all:
        return Icons.place_rounded;
    }
  }

  String _label(_FavCategory c) {
    switch (c) {
      case _FavCategory.all:
        return _tr('all');
      case _FavCategory.accommodation:
        return _tr('accommodation');
      case _FavCategory.video:
        return _tr('video');
      case _FavCategory.attraction:
        return _tr('attraction');
      case _FavCategory.health:
        return _tr('health');
      case _FavCategory.leader:
        return _tr('leader');
      case _FavCategory.agency:
        return _tr('agency');
    }
  }

  // ------------------------------------------------------------
  // باز کردن هر مورد
  // ------------------------------------------------------------

  ShowcaseKind _showcaseKindOf(_FavCategory c) {
    switch (c) {
      case _FavCategory.leader:
        return ShowcaseKind.leader;
      case _FavCategory.health:
        return ShowcaseKind.health;
      case _FavCategory.accommodation:
        return ShowcaseKind.accommodation;
      case _FavCategory.attraction:
        return ShowcaseKind.attraction;
      case _FavCategory.agency:
        return ShowcaseKind.agency;
      default:
        return ShowcaseKind.video;
    }
  }

  Future<void> _open(_FavEntry e) async {
    if (e.place != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryExplorerPage(initialCategory: e.place!.category)),
      );
      return;
    }
    // لیدر ذخیره‌شده → مستقیم پروفایل همان لیدر (کد = شماره در فهرست تأییدشده‌ها)
    if (e.category == _FavCategory.leader) {
      final code = int.tryParse(e.video?['code'] ?? '') ?? 0;
      if (code >= 1 && code <= approvedLeaders.length) {
        final leader = approvedLeaders[code - 1];
        final favId = leader.introVideoUrl ?? 'leader:$code';
        if ((e.video?['url'] ?? '') == favId) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeaderProfilePage(leader: leader)),
          );
          return;
        }
      }
    }

    final url = e.video?['url'] ?? '';
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    // مورد بدون لینک مستقیم → صفحه‌ی نمایشِ همان بخش
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShowcaseGalleryPage(kind: _showcaseKindOf(e.category))),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final all = _entries;
    final rows = _selected == _FavCategory.all
        ? all
        : all.where((e) => e.category == _selected).toList();

    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : RefreshIndicator(
                  color: _gold,
                  backgroundColor: _card,
                  onRefresh: _loadAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _header(all.length),
                      const SizedBox(height: 14),
                      Text(
                        _tr('subtitle'),
                        style: TextStyle(color: Colors.white.withValues(alpha: .68), fontSize: 13, height: 1.8),
                      ),
                      const SizedBox(height: 14),
                      _categoryButtons(all),
                      const SizedBox(height: 14),
                      if (rows.isEmpty) _emptyState() else ...rows.map(_entryCard),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff123244), Color(0xff081722)],
        ),
        border: Border.all(color: _gold.withValues(alpha: .42)),
        boxShadow: [BoxShadow(color: _gold.withValues(alpha: .08), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr('title'),
                  style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.favorite_rounded, color: _gold, size: 20),
                const SizedBox(width: 6),
                Text(_num(total),
                    style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [_gold, Color(0xff6e5520)]),
                boxShadow: [BoxShadow(color: _gold.withValues(alpha: .42), blurRadius: 15)],
              ),
              child: Icon(_rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: _bg, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryButtons(List<_FavEntry> all) {
    const cats = _FavCategory.values;
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = cats[i];
          final selected = _selected == c;
          final count = _countOf(all, c);
          return GestureDetector(
            onTap: () => setState(() => _selected = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: selected
                    ? const LinearGradient(colors: [_gold, _goldBright])
                    : const LinearGradient(colors: [Color(0xff102b3a), Color(0xff0a1d29)]),
                border: Border.all(
                  color: selected ? const Color(0xffffefb0) : _gold.withValues(alpha: .78),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: selected ? .35 : .18),
                    blurRadius: selected ? 12 : 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(c),
                    style: TextStyle(color: selected ? _bg : Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: selected ? _bg.withValues(alpha: .22) : Colors.white.withValues(alpha: .12),
                    ),
                    child: Text(
                      _num(count),
                      style: TextStyle(color: selected ? _bg : Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _thumb(_FavEntry e) {
    final accent = _accent(e.category);
    final img = e.image;
    final iconBlock = Icon(_icon(e.category), color: Colors.white, size: 40);

    Widget? photo;
    if (img != null && img.isNotEmpty) {
      photo = img.startsWith('http')
          ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
          : Image.asset(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }

    return Container(
      width: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .45), accent.withValues(alpha: .10)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null) Positioned.fill(child: photo),
          if (photo != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: .05), Colors.black.withValues(alpha: .55)],
                  ),
                ),
              ),
            ),
          if (photo == null) Center(child: iconBlock),
          // منبع: 📍 نقشه  |  ▶ نمایش
          PositionedDirectional(
            top: 8,
            start: 8,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: .55),
                border: Border.all(color: Colors.white.withValues(alpha: .25)),
              ),
              child: Icon(
                e.fromMap ? Icons.place_rounded : Icons.play_arrow_rounded,
                color: e.fromMap ? const Color(0xffff5c5c) : Colors.white,
                size: 17,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 8,
            start: 8,
            end: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: accent.withValues(alpha: .55)),
              ),
              child: Text(
                e.category == _FavCategory.all ? _tr('maps') : _label(e.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(_FavEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _open(e),
          child: Container(
            clipBehavior: Clip.antiAlias,
            constraints: const BoxConstraints(minHeight: 132),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff0c2b3e), Color(0xff081b29)],
              ),
              border: Border.all(color: _gold.withValues(alpha: .22)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _thumb(e),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w900, fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.fromMap ? _tr('fromMap') : _tr('fromShowcase'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(colors: [_gold, Color(0xffffc94d)]),
                            ),
                            child: Text(
                              e.tag,
                              style: const TextStyle(color: Color(0xff3a2a00), fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _remove(e),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _pink.withValues(alpha: .14),
                              border: Border.all(color: _pink.withValues(alpha: .5), width: 1.4),
                            ),
                            child: const Icon(Icons.favorite_rounded, color: _pink, size: 22),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: .35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(children: [
        const Icon(Icons.favorite_border_rounded, size: 68, color: Color(0xff667581)),
        const SizedBox(height: 18),
        Text(
          _tr('empty'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
