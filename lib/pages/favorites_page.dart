import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';
import '../map_place.dart';
import '../services/map_place_favorites_service.dart';
import '../services/video_favorites_service.dart';
import 'category_explorer_page.dart';
import 'showcase/showcase_gallery_page.dart';
import 'showcase/showcase_kinds.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);

/// صفحه مرکزی «برگزیده‌ها».
///
/// مهم: این صفحه از همان ذخیره‌سازی‌های فعلی استفاده می‌کند تا علاقه‌مندی‌های
/// نقشه و فیلم‌های قبلی از بین نروند. Login/Notifications و Worker دست‌نخورده‌اند.
enum _FavCategory { all, accommodation, video, attraction, health, leader, agency }

const Map<String, Map<String, String>> _t = {
  'title': {'fa': 'برگزیده‌های من', 'en': 'My Favorites', 'ar': 'المفضلة لدي'},
  'subtitle': {
    'fa': 'همه علاقه‌مندی‌های شما در یک صفحه',
    'en': 'All your favorites in one place',
    'ar': 'كل المفضلات الخاصة بك في مكان واحد',
  },
  'all': {'fa': 'همه', 'en': 'All', 'ar': 'الكل'},
  'accommodation': {'fa': 'اقامتگاه', 'en': 'Stays', 'ar': 'الإقامة'},
  'video': {'fa': 'فیلم', 'en': 'Videos', 'ar': 'الفيديو'},
  'attraction': {'fa': 'جاذبه', 'en': 'Attractions', 'ar': 'المعالم'},
  'health': {'fa': 'سلامت', 'en': 'Health', 'ar': 'الصحة'},
  'leader': {'fa': 'لیدر', 'en': 'Leaders', 'ar': 'المرشدون'},
  'agency': {'fa': 'آژانس', 'en': 'Agencies', 'ar': 'الوكالات'},
  'empty': {'fa': 'هنوز موردی در این بخش ذخیره نشده است', 'en': 'No saved items in this section yet', 'ar': 'لا توجد عناصر محفوظة في هذا القسم بعد'},
  'open': {'fa': 'مشاهده', 'en': 'View', 'ar': 'عرض'},
  'maps': {'fa': 'مکان روی نقشه', 'en': 'Map place', 'ar': 'المكان على الخريطة'},
  'videoLabel': {'fa': 'فیلم گردشگری', 'en': 'Tourism video', 'ar': 'فيديو سياحي'},
};

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

  Future<void> _removePlace(MapPlace place) async {
    await _placeFavorites.toggleFavorite(place);
    await _loadAll();
  }

  Future<void> _removeVideo(Map<String, String> video) async {
    await _videoFavorites.toggleFavorite(video);
    await _loadAll();
  }

  String _videoText(Map<String, String> video, String key) {
    return video['${key}_$_lang'] ?? video['${key}_fa'] ?? video['${key}_en'] ?? '';
  }

  String _videoKind(Map<String, String> video) {
    final kind = (video['kind'] ?? '').toLowerCase().trim();
    if (kind.isNotEmpty) return kind;
    final text = '${video['category_fa'] ?? ''} ${video['category_en'] ?? ''} ${video['category_ar'] ?? ''}'.toLowerCase();
    if (text.contains('leader') || text.contains('لیدر') || text.contains('قائد')) return 'leader';
    if (text.contains('health') || text.contains('سلامت') || text.contains('صحة') || text.contains('علاج')) return 'health';
    if (text.contains('accommodation') || text.contains('اقامت') || text.contains('hotel') || text.contains('هتل')) return 'accommodation';
    if (text.contains('agency') || text.contains('آژانس')) return 'agency';
    if (text.contains('attraction') || text.contains('جاذبه') || text.contains('معلم')) return 'attraction';
    return 'video';
  }

  bool _placeMatches(MapPlace p, _FavCategory category) {
    switch (category) {
      case _FavCategory.all:
        return true;
      case _FavCategory.accommodation:
        return p.category == PlaceCategory.accommodation;
      case _FavCategory.attraction:
        return p.category == PlaceCategory.attraction;
      case _FavCategory.health:
        return p.category == PlaceCategory.health;
      default:
        return false;
    }
  }

  bool _videoMatches(Map<String, String> v, _FavCategory category) {
    final kind = _videoKind(v);
    switch (category) {
      case _FavCategory.all:
        return true;
      case _FavCategory.video:
        return kind == 'video';
      case _FavCategory.leader:
        return kind == 'leader';
      case _FavCategory.health:
        return kind == 'health';
      case _FavCategory.accommodation:
        return kind == 'accommodation';
      case _FavCategory.attraction:
        return kind == 'attraction';
      case _FavCategory.agency:
        return kind == 'agency';
    }
  }

  bool get _hasItems {
    if (_selected == _FavCategory.all) return _places.isNotEmpty || _videos.isNotEmpty;
    final placeHit = _places.any((p) => _placeMatches(p, _selected));
    final videoHit = _videos.any((v) => _videoMatches(v, _selected));
    return placeHit || videoHit;
  }

  @override
  Widget build(BuildContext context) {
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
                      _header(),
                      const SizedBox(height: 14),
                      Text(_tr('subtitle'), style: TextStyle(color: Colors.white.withValues(alpha: .68), fontSize: 13)),
                      const SizedBox(height: 16),
                      _categoryButtons(),
                      const SizedBox(height: 18),
                      if (!_hasItems) _emptyState() else ..._buildFilteredContent(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff123244), Color(0xff081722)]),
        border: Border.all(color: _gold.withValues(alpha: .42)),
        boxShadow: [BoxShadow(color: _gold.withValues(alpha: .08), blurRadius: 18)],
      ),
      child: Row(
        children: [
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
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_tr('title'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.favorite_rounded, color: _gold, size: 20),
                const SizedBox(width: 5),
                Text('${_places.length + _videos.length}', style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w800)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryButtons() {
    final buttons = <(_FavCategory, String)>[
      (_FavCategory.all, 'all'),
      (_FavCategory.accommodation, 'accommodation'),
      (_FavCategory.video, 'video'),
      (_FavCategory.attraction, 'attraction'),
      (_FavCategory.health, 'health'),
      (_FavCategory.leader, 'leader'),
      (_FavCategory.agency, 'agency'),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: buttons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final category = buttons[i].$1;
          final key = buttons[i].$2;
          final selected = _selected == category;
          return GestureDetector(
            onTap: () => setState(() => _selected = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: selected ? const LinearGradient(colors: [_gold, Color(0xffffe39a)]) : const LinearGradient(colors: [Color(0xff102b3a), Color(0xff0a1d29)]),
                border: Border.all(color: selected ? const Color(0xffffefb0) : _gold.withValues(alpha: .78), width: 1.4),
                boxShadow: [
                  BoxShadow(color: _gold.withValues(alpha: selected ? .35 : .18), blurRadius: selected ? 12 : 7, offset: const Offset(0, 3)),
                  BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 4, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(_tr(key), style: TextStyle(color: selected ? _bg : Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFilteredContent(BuildContext context) {
    final widgets = <Widget>[];
    final places = _places.where((p) => _placeMatches(p, _selected)).toList();
    final videos = _videos.where((v) => _videoMatches(v, _selected)).toList();

    if (places.isNotEmpty) {
      widgets.addAll(places.map((p) => _placeCard(context, p)));
    }
    if (videos.isNotEmpty) {
      widgets.addAll(videos.map((v) => _videoCard(context, v)));
    }
    return widgets;
  }

  Widget _placeCard(BuildContext context, MapPlace place) {
    final icon = place.category == PlaceCategory.health
        ? Icons.local_hospital_rounded
        : place.category == PlaceCategory.attraction
            ? Icons.landscape_rounded
            : Icons.hotel_rounded;
    return _cardShell(
      icon: icon,
      title: place.name,
      subtitle: place.address ?? _tr('maps'),
      onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryExplorerPage(initialCategory: place.category))),
      onRemove: () => _removePlace(place),
    );
  }

  Widget _videoCard(BuildContext context, Map<String, String> video) {
    final kind = _videoKind(video);
    final title = _videoText(video, 'title');
    final label = kind == 'leader'
        ? _tr('leader')
        : kind == 'health'
            ? _tr('health')
            : kind == 'accommodation'
                ? _tr('accommodation')
                : kind == 'attraction'
                    ? _tr('attraction')
                    : _tr('videoLabel');
    return _cardShell(
      icon: kind == 'leader' ? Icons.person_pin_circle_rounded : Icons.play_circle_fill_rounded,
      title: title.isEmpty ? label : title,
      subtitle: '${label}${_videoText(video, 'location').isNotEmpty ? ' • ${_videoText(video, 'location')}' : ''}',
      onOpen: () async {
        final url = video['url'] ?? '';
        if (url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShowcaseGalleryPage(kind: ShowcaseKind.video)));
        }
      },
      onRemove: () => _removeVideo(video),
    );
  }

  Widget _cardShell({required IconData icon, required String title, required String subtitle, required VoidCallback onOpen, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: .24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .24), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withValues(alpha: .12)), child: Icon(icon, color: _gold)),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 11)),
                ]),
              ),
            ),
          ),
          IconButton(onPressed: onRemove, tooltip: _tr('open'), icon: const Icon(Icons.favorite_rounded, color: Color(0xffff6b81))),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(children: [
        const Icon(Icons.favorite_border_rounded, size: 68, color: Color(0xff667581)),
        const SizedBox(height: 18),
        Text(_tr('empty'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
