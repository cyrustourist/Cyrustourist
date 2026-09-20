import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';
import '../map_place.dart';
import '../services/map_place_favorites_service.dart';
import '../services/video_favorites_service.dart';
import 'category_explorer_page.dart';
import 'video_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

enum _FavCategory { all, accommodation, video, attraction, health, leader }

/// ------------------------------------------------------------
/// متن‌های صفحه «برگزیده‌ها» — هر ۱۰ زبان اپ.
/// ------------------------------------------------------------
const Map<String, Map<String, String>> _t = {
  'title': {
    'fa': 'برگزیده‌ها',
    'en': 'Selected',
    'ar': 'المختارة',
    'tr': 'Seçilenler',
    'ru': 'Избранное',
    'fr': 'Sélectionnés',
    'de': 'Ausgewählte',
    'es': 'Seleccionados',
    'zh': '精选',
    'it': 'Selezionati',
  },
  'subtitle': {
    'fa': 'فیلم‌های گردشگری و اقامتگاه‌هایی که به علاقه‌مندی‌ها اضافه کرده‌اید',
    'en': "Tourism videos and accommodations you've added to your favorites",
    'ar': 'مقاطع الفيديو السياحية وأماكن الإقامة التي أضفتها إلى المفضلة',
    'tr': 'Favorilerinize eklediğiniz turizm videoları ve konaklama yerleri',
    'ru': 'Туристические видео и места проживания, добавленные в избранное',
    'fr': 'Vidéos touristiques et hébergements ajoutés à vos favoris',
    'de': 'Tourismusvideos und Unterkünfte, die Sie zu Ihren Favoriten hinzugefügt haben',
    'es': 'Vídeos turísticos y alojamientos que has añadido a tus favoritos',
    'zh': '您添加到收藏夹的旅游视频和住宿',
    'it': 'Video turistici e alloggi che hai aggiunto ai preferiti',
  },
  'chipAccommodation': {
    'fa': 'اقامتگاه‌ها 🏡',
    'en': 'Accommodations 🏡',
    'ar': 'أماكن الإقامة 🏡',
    'tr': 'Konaklamalar 🏡',
    'ru': 'Жильё 🏡',
    'fr': 'Hébergements 🏡',
    'de': 'Unterkünfte 🏡',
    'es': 'Alojamientos 🏡',
    'zh': '住宿 🏡',
    'it': 'Alloggi 🏡',
  },
  'chipVideos': {
    'fa': 'فیلم‌های گردشگری 🎬',
    'en': 'Tourism Videos 🎬',
    'ar': 'مقاطع الفيديو السياحية 🎬',
    'tr': 'Turizm Videoları 🎬',
    'ru': 'Туристические видео 🎬',
    'fr': 'Vidéos touristiques 🎬',
    'de': 'Tourismusvideos 🎬',
    'es': 'Vídeos turísticos 🎬',
    'zh': '旅游视频 🎬',
    'it': 'Video turistici 🎬',
  },
  'emptyAccommodation': {
    'fa': 'هنوز اقامتگاهی به علاقه‌مندی‌ها اضافه نکرده‌اید',
    'en': "You haven't added any accommodation to favorites yet",
    'ar': 'لم تقم بإضافة أي مكان إقامة إلى المفضلة بعد',
    'tr': 'Henüz favorilere bir konaklama eklemediniz',
    'ru': 'Вы ещё не добавили жильё в избранное',
    'fr': "Vous n'avez pas encore ajouté d'hébergement aux favoris",
    'de': 'Sie haben noch keine Unterkunft zu den Favoriten hinzugefügt',
    'es': 'Aún no has añadido ningún alojamiento a favoritos',
    'zh': '您还没有将任何住宿添加到收藏夹',
    'it': 'Non hai ancora aggiunto alcun alloggio ai preferiti',
  },
  'emptyVideos': {
    'fa': 'هنوز فیلم گردشگری به علاقه‌مندی‌ها اضافه نکرده‌اید',
    'en': "You haven't added any tourism video to favorites yet",
    'ar': 'لم تقم بإضافة أي مقطع فيديو سياحي إلى المفضلة بعد',
    'tr': 'Henüz favorilere bir turizm videosu eklemediniz',
    'ru': 'Вы ещё не добавили туристическое видео в избранное',
    'fr': "Vous n'avez pas encore ajouté de vidéo touristique aux favoris",
    'de': 'Sie haben noch kein Tourismusvideo zu den Favoriten hinzugefügt',
    'es': 'Aún no has añadido ningún vídeo turístico a favoritos',
    'zh': '您还没有将任何旅游视频添加到收藏夹',
    'it': 'Non hai ancora aggiunto alcun video turistico ai preferiti',
  },
  'ctaAccommodation': {
    'fa': 'مشاهده اقامتگاه‌ها',
    'en': 'View Accommodations',
    'ar': 'مشاهدة أماكن الإقامة',
    'tr': 'Konaklamaları Görüntüle',
    'ru': 'Смотреть жильё',
    'fr': 'Voir les hébergements',
    'de': 'Unterkünfte ansehen',
    'es': 'Ver alojamientos',
    'zh': '查看住宿',
    'it': 'Vedi alloggi',
  },
  'ctaVideos': {
    'fa': 'مشاهده فیلم‌های گردشگری',
    'en': 'View Tourism Videos',
    'ar': 'مشاهدة مقاطع الفيديو السياحية',
    'tr': 'Turizm Videolarını Görüntüle',
    'ru': 'Смотреть туристические видео',
    'fr': 'Voir les vidéos touristiques',
    'de': 'Tourismusvideos ansehen',
    'es': 'Ver vídeos turísticos',
    'zh': '查看旅游视频',
    'it': 'Guarda i video turistici',
  },
};

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MapPlaceFavoritesService _placeFavorites = MapPlaceFavoritesService();
  final VideoFavoritesService _videoFavorites = VideoFavoritesService();

  List<MapPlace> _favoritePlaces = [];
  List<Map<String, String>> _favoriteVideos = [];

  bool _loading = true;
  _FavCategory _selected = _FavCategory.all;

  String get _lang => MenuLanguage.current;
  bool get _isRtl => MenuLanguage.isRtl;

  String _tr(String key) => _t[key]?[_lang] ?? _t[key]?['fa'] ?? '';

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
      _favoritePlaces = places;
      _favoriteVideos = videos;
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

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _videoText(Map<String, String> video, String key) {
    return video['${key}_$_lang'] ??
        video['${key}_fa'] ??
        video['${key}_en'] ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _headerBanner(context),
                    const SizedBox(height: 14),
                    Text(
                      _tr('subtitle'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _categoryChips(),
                    const SizedBox(height: 20),
                    _favoritesContent(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _headerBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff123244), Color(0xff081722)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold, _gold.withValues(alpha: 0.15)],
                ),
                boxShadow: [
                  BoxShadow(color: _gold.withValues(alpha: 0.55), blurRadius: 18),
                ],
              ),
              child: Icon(
                _isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                color: const Color(0xff06121d),
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _tr('title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.favorite_rounded, color: _gold, size: 26),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    final chips = <(_FavCategory, String)>[
      (_FavCategory.all, 'همه'),
      (_FavCategory.accommodation, 'اقامتگاه‌ها 🏡'),
      (_FavCategory.video, 'فیلم‌ها 🎬'),
      (_FavCategory.attraction, 'جاذبه‌ها 📍'),
      (_FavCategory.health, 'سلامت 🏥'),
      (_FavCategory.leader, 'لیدرها 🧭'),
    ];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (category, label) = chips[i];
          return _chip(
            label: label,
            selected: _selected == category,
            onTap: () => setState(() => _selected = category),
          );
        },
      ),
    );
  }

  Widget _favoritesContent(BuildContext context) {
    final places = _selected == _FavCategory.all
        ? _favoritePlaces
        : _favoritePlaces.where((p) => _placeCategoryMatches(p, _selected)).toList();
    final videos = _selected == _FavCategory.all || _selected == _FavCategory.video
        ? _favoriteVideos
        : _favoriteVideos.where((v) => _videoCategoryMatches(v, _selected)).toList();

    final showPlaces = _selected == _FavCategory.all ||
        _selected == _FavCategory.accommodation ||
        _selected == _FavCategory.attraction ||
        _selected == _FavCategory.health;
    final showVideos = _selected == _FavCategory.all ||
        _selected == _FavCategory.video ||
        _selected == _FavCategory.accommodation ||
        _selected == _FavCategory.attraction ||
        _selected == _FavCategory.health ||
        _selected == _FavCategory.leader;

    if ((!showPlaces || places.isEmpty) && (!showVideos || videos.isEmpty)) {
      return _emptyState(
        message: 'هنوز موردی در این دسته به برگزیده‌ها اضافه نشده است',
        ctaLabel: _tr('ctaVideos'),
        onCta: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VideoPage()),
        ),
      );
    }

    return Column(
      children: [
        if (showPlaces && places.isNotEmpty)
          ...places.map((place) => _placeFavoriteCard(context, place)),
        if (showVideos && videos.isNotEmpty)
          ...videos.map((video) => _videoFavoriteCard(context, video)),
      ],
    );
  }

  bool _placeCategoryMatches(MapPlace place, _FavCategory category) {
    switch (category) {
      case _FavCategory.accommodation:
        return place.category == PlaceCategory.accommodation;
      case _FavCategory.attraction:
        return place.category == PlaceCategory.attraction;
      case _FavCategory.health:
        return place.category == PlaceCategory.health;
      default:
        return false;
    }
  }

  bool _videoCategoryMatches(Map<String, String> video, _FavCategory category) {
    final kind = (video['kind'] ?? '').toLowerCase();
    switch (category) {
      case _FavCategory.accommodation:
        return kind == 'accommodation';
      case _FavCategory.attraction:
        return kind == 'attraction';
      case _FavCategory.health:
        return kind == 'health';
      case _FavCategory.leader:
        return kind == 'leader';
      case _FavCategory.video:
        return kind == 'video' || kind.isEmpty;
      default:
        return false;
    }
  }

  Widget _placeFavoriteCard(BuildContext context, MapPlace place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withValues(alpha: 0.12)),
            child: Icon(
              place.category == PlaceCategory.health
                  ? Icons.health_and_safety_rounded
                  : place.category == PlaceCategory.attraction
                      ? Icons.landscape_rounded
                      : Icons.home_work_rounded,
              color: _gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(place.name, style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 14))),
          IconButton(
            onPressed: () => _removePlace(place),
            icon: const Icon(Icons.favorite_rounded, color: Color(0xffff6b81)),
          ),
        ],
      ),
    );
  }

  Widget _videoFavoriteCard(BuildContext context, Map<String, String> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withValues(alpha: 0.12)),
            child: Icon(
              (video['kind'] ?? '') == 'leader' ? Icons.groups_2_rounded :
              (video['kind'] ?? '') == 'health' ? Icons.health_and_safety_rounded :
              (video['kind'] ?? '') == 'accommodation' ? Icons.home_work_rounded :
              (video['kind'] ?? '') == 'attraction' ? Icons.landscape_rounded : Icons.play_circle_fill_rounded,
              color: _gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openVideo(video['url'] ?? ''),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_videoText(video, 'title'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (_videoText(video, 'location').isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(_videoText(video, 'location'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11))),
                ],
              ),
            ),
          ),
          IconButton(onPressed: () => _removeVideo(video), icon: const Icon(Icons.favorite_rounded, color: Color(0xffff6b81))),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? const LinearGradient(colors: [_teal, Color(0xff3ff0a8)])
              : null,
          color: selected ? null : _card,
          border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xff06121d) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // لیست‌های قدیمی برای سازگاری داخلی؛ رندر اصلی اکنون در _favoritesContent انجام می‌شود.
  Widget _accommodationList(BuildContext context) => _favoritesContent(context);
  Widget _videoList(BuildContext context) => _favoritesContent(context);

  // ---------------------------------------------------------
  // حالت خالی مشترک
  // ---------------------------------------------------------

  Widget _emptyState({
    required String message,
    required String ctaLabel,
    required VoidCallback onCta,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded, size: 64, color: Color(0xff5a6672)),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCta,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: const Color(0xff06121d),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(ctaLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
