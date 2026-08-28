import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../map_place.dart';
import '../core/language/app_language.dart';
import '../services/location_manager.dart';
import '../services/category_nearby_service.dart';
import '../services/map_place_favorites_service.dart';
import '../widgets/map_markers_layer.dart';
import '../widgets/map_place_details_sheet.dart';
import '../widgets/map_search_bar.dart';
import 'map/tourist_map_category_config.dart';
import 'map/map_radius_selector.dart';
import 'map/tourist_places_list.dart';
import 'category_full_map_page.dart';

/// صفحه مشترک کلیدهای ۲ (سلامت)، ۳ (جاذبه‌ها) و ۵ (اقامتگاه).
///
/// مرحله ۱: مکان‌های اطراف موقعیت GPS کاربر روی نقشه و زیر نقشه لیست می‌شود.
/// مرحله ۲: اگر کاربر شهر/جاذبه‌ای را جستجو کند، نقشه و لیست حول همان
/// نقطه جستجو‌شده (نقطه مرجع جدید) بازسازی می‌شود و دکمه بازگشت به
/// موقعیت کاربر نمایش داده می‌شود.
///
/// نقطه مرجع مسیریابی:
/// - در حالت عادی = موقعیت واقعی GPS کاربر.
/// - در حالت جستجوی شهر/جاذبه = همان نقطه جستجو‌شده.
class CategoryExplorerPage extends StatefulWidget {
  final PlaceCategory initialCategory;

  const CategoryExplorerPage({
    super.key,
    required this.initialCategory,
  });

  @override
  State<CategoryExplorerPage> createState() =>
      _CategoryExplorerPageState();
}

class _CategoryExplorerPageState
    extends State<CategoryExplorerPage> {
  static const LatLng _fallbackCenter = LatLng(
    32.4279,
    53.6880,
  );

  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController();

  final CategoryNearbyService _service =
      CategoryNearbyService.instance;

  final MapPlaceFavoritesService _favoritesService =
      MapPlaceFavoritesService();

  LatLng? _userLocation;
  LatLng? _center;

  bool _isSearchedMode = false;

  double _radiusKm = 15;

  List<MapPlace> _places = [];
  Set<String> _favoriteIds = {};

  bool _loading = true;
  bool _searching = false;
  String? _locationWarning;

  TouristMapCategoryConfig get _config {
    switch (widget.initialCategory) {
      case PlaceCategory.health:
        return TouristMapCategories.health;

      case PlaceCategory.accommodation:
        return TouristMapCategories.accommodation;

      case PlaceCategory.attraction:
      default:
        return TouristMapCategories.attractions;
    }
  }

  String get _langCode {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
        return 'en';
    }
  }

  bool get _isRtl => _langCode != 'en';

  /// نقطه مرجع فعلی برای مسیریابی.
  ///
  /// در حالت جستجو، نقطه مرجع همان نتیجه جستجو است؛
  /// در حالت عادی، موقعیت واقعی GPS کاربر است.
  LatLng? get _referencePoint =>
      _isSearchedMode ? _center : (_userLocation ?? _center);

  String _text(
    String fa,
    String en,
    String ar,
  ) {
    switch (_langCode) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BOOTSTRAP
  // ============================================================

  Future<void> _bootstrap() async {
    await _loadFavoriteIds();

    final location =
        await LocationManager.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      setState(() {
        _locationWarning = _text(
          'برای نمایش مکان‌های اطراف، لطفاً GPS را فعال کنید.',
          'Please enable GPS to see nearby places.',
          'يرجى تفعيل GPS لعرض الأماكن القريبة.',
        );
        _center = _fallbackCenter;
      });
    } else {
      setState(() {
        _userLocation = location;
        _center = location;
      });
    }

    await _loadNearby();
  }

  Future<void> _loadFavoriteIds() async {
    final ids = await _favoritesService.loadFavoriteIds();

    if (!mounted) return;

    setState(() {
      _favoriteIds = ids;
    });
  }

  // ============================================================
  // LOAD NEARBY
  // ============================================================

  Future<void> _loadNearby() async {
    if (_center == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final results = await _service.nearby(
        category: widget.initialCategory,
        center: _center!,
        radiusMeters: _radiusKm * 1000,
        language: _langCode,
      );

      if (!mounted) return;

      setState(() {
        _places = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _loading = false;
      });

      _showSnack(
        _text(
          'دریافت اطلاعات با خطا مواجه شد. دوباره تلاش کنید.',
          'Failed to load places. Please try again.',
          'فشل تحميل الأماكن. حاول مرة أخرى.',
        ),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _searching = true;
    });

    List<SearchedLocation> results = [];

    try {
      results = await _service.searchPlaceOrCity(
        query,
        language: _langCode,
      );
    } catch (_) {
      results = [];
    }

    if (!mounted) return;

    setState(() {
      _searching = false;
    });

    if (results.isEmpty) {
      _showSnack(
        _text(
          'نتیجه‌ای برای این جستجو پیدا نشد.',
          'No results found for this search.',
          'لم يتم العثور على نتائج لهذا البحث.',
        ),
      );
      return;
    }

    final match = results.first;

    setState(() {
      _center = match.point;
      _isSearchedMode = true;
    });

    _mapController.move(match.point, 13);

    await _loadNearby();
  }

  Future<void> _backToMyLocation() async {
    final fallback = _userLocation ?? _fallbackCenter;

    setState(() {
      _center = fallback;
      _isSearchedMode = false;
      _searchController.clear();
    });

    _mapController.move(fallback, 12);

    await _loadNearby();
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _radiusKm = value;
    });

    _loadNearby();
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  bool _isFavorite(MapPlace place) =>
      _favoriteIds.contains(place.id);

  Future<void> _toggleFavorite(MapPlace place) async {
    final added =
        await _favoritesService.toggleFavorite(place);

    if (!mounted) return;

    setState(() {
      if (added) {
        _favoriteIds.add(place.id);
      } else {
        _favoriteIds.remove(place.id);
      }
    });

    _showSnack(
      added
          ? _text(
              'به علاقه‌مندی‌ها اضافه شد',
              'Added to favorites',
              'أضيف إلى المفضلة',
            )
          : _text(
              'از علاقه‌مندی‌ها حذف شد',
              'Removed from favorites',
              'أزيل من المفضلة',
            ),
    );
  }

  // ============================================================
  // ROUTE
  // ============================================================
  //
  // مبدأ مسیریابی به‌جای اینکه همیشه GPS واقعی باشد، از نقطه
  // مرجع فعلی (_referencePoint) خوانده می‌شود:
  // - حالت عادی → GPS واقعی کاربر
  // - حالت جستجوی شهر/جاذبه → همان نقطه جستجو‌شده

  Future<void> _openRoute(MapPlace place) async {
    final origin = _referencePoint;
    final lat = place.location.latitude;
    final lon = place.location.longitude;

    final url = origin != null
        ? 'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=$lat,$lon'
        : 'https://www.google.com/maps/search/?api=1'
            '&query=$lat,$lon';

    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showSnack(
          _text(
            'امکان باز کردن مسیریاب وجود ندارد.',
            'Could not open navigation.',
            'تعذر فتح خرائط الملاحة.',
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showSnack(
        _text(
          'امکان باز کردن مسیریاب وجود ندارد.',
          'Could not open navigation.',
          'تعذر فتح خرائط الملاحة.',
        ),
      );
    }
  }

  // ============================================================
  // MARKER TAP → نمایش اطلاعات مکان
  // ============================================================

  void _onMarkerTap(MapPlace place) {
    MapPlaceDetailsSheet.show(
      context,
      place,
      isFavorite: _isFavorite(place),
      onFavorite: () {
        Navigator.pop(context);
        _toggleFavorite(place);
      },
      onRoute: () {
        Navigator.pop(context);
        _openRoute(place);
      },
    );
  }

  // ============================================================
  // LIST ITEM TAP → تمرکز نقشه روی نشانگر همان مکان
  // سپس نمایش اطلاعات همان مکان
  // ============================================================

  void _onListItemTap(MapPlace place) {
    _mapController.move(place.location, 15);
    _onMarkerTap(place);
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // نقشه تمام‌صفحه (با لمس نقشه کوچک باز می‌شود)
  // ============================================================

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFullMapPage(
          places: _places,
          initialCenter: _center ?? _fallbackCenter,
          title: _config.title(_langCode),
          isRtl: _isRtl,
          isFavorite: _isFavorite,
          onFavorite: _toggleFavorite,
          onRoute: _openRoute,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final config = _config;

    final mapHeight =
        MediaQuery.of(context).size.height * 0.42;

    return Directionality(
      textDirection:
          _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            config.title(_langCode),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _center ?? _fallbackCenter,
                        initialZoom: 12,
                        minZoom: 3,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.cyrustourist.app',
                        ),
                        MapMarkersLayer(
                          places: _places,
                          onTap: _onMarkerTap,
                        ),
                      ],
                    ),

                    // لمس هر نقطه از نقشه کوچک، نقشه را تمام‌صفحه
                    // باز می‌کند تا بهتر بشود جاذبه‌ها را زوم کرد.
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _openFullMap,
                        child: Align(
                          alignment: _isRtl
                              ? Alignment.bottomLeft
                              : Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 64,
                              left: 10,
                              right: 10,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xff071722)
                                    .withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xffffd36a),
                                ),
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Color(0xffffd36a),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          MapSearchBar(
                            controller: _searchController,
                            hintText:
                                config.searchHint(_langCode),
                            onSearch: _onSearch,
                          ),

                          if (_isSearchedMode)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Align(
                                alignment: _isRtl
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                    onTap: _backToMyLocation,
                                    child: Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xff071722,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xffffd36a,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons
                                                .arrow_back_rounded,
                                            color: Color(
                                              0xffffd36a,
                                            ),
                                            size: 16,
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            _text(
                                              'بازگشت به موقعیت من',
                                              'Back to my location',
                                              'العودة إلى موقعي',
                                            ),
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MapRadiusSelector(
                        selectedRadius: _radiusKm,
                        onChanged: _onRadiusChanged,
                        language: _langCode,
                      ),
                    ),

                    if (_locationWarning != null &&
                        !_isSearchedMode)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 92,
                        child: Container(
                          padding:
                              const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff071722,
                            ).withValues(alpha: 0.95),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xffffd36a,
                              ),
                            ),
                          ),
                          child: Text(
                            _locationWarning!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    if (_loading || _searching)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xffffd36a),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  color: const Color(0xffedf4f7),
                  child: SingleChildScrollView(
                    child: TouristPlacesList(
                      places: _places,
                      language: _langCode,
                      category: widget.initialCategory,
                      onPlaceTap: _onListItemTap,
                      onRouteTap: _openRoute,
                      isFavorite: _isFavorite,
                      onFavoriteTap: _toggleFavorite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
