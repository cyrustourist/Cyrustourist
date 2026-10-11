import '../widgets/resilient_tile_layer.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/carto_config.dart';
import '../map_place.dart';
import '../core/language/app_language.dart';
import '../services/location_manager.dart';
import '../services/category_nearby_service.dart';
import '../services/map_place_favorites_service.dart';
import '../widgets/map_markers_layer.dart';
import '../widgets/map_place_details_sheet.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/showcase_film_banner.dart';
import '../models/showcase_item.dart';
import 'showcase/showcase_gallery_page.dart';
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

  double _radiusKm = 5;

  // شماره‌ی آخرین درخواست؛ پاسخ‌های قدیمی و کندتر نادیده گرفته می‌شوند.
  int _loadSeq = 0;

  // یک بار تلاش خودکار بعد از نتیجه‌ی خالی/خطا؛ با تغییر شعاع/جستجو دوباره فعال می‌شود.
  bool _autoRetried = false;

  // چرخش دکمه‌ی «تلاش دوباره» (هر لمس یک دور کامل)
  double _retryTurns = 0;

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
      default:
        return 'en';
    }
  }

  /// کد زبان برای بنر فیلم (هر ۱۰ زبان)
  String get _bannerLang {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.italian:
        return 'it';
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.chinese:
        return 'zh';
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
    _radiusDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BOOTSTRAP
  // ============================================================

  Future<void> _bootstrap() async {
    _loadFavoriteIds();

    // آخرین موقعیت ثبت‌شده فوری خوانده می‌شود و جستجو بلافاصله شروع
    // می‌شود؛ منتظر GPS تازه نمی‌مانیم.
    final quick = await LocationManager.getLastKnownLocation();
    if (mounted && quick != null) {
      setState(() {
        _userLocation = quick;
        _center = quick;
        _locationWarning = null;
      });
      _safeMove(quick, 13);
      unawaited(_loadNearby());
    }

    final location =
        await LocationManager.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      if (quick == null) {
        setState(() {
          _locationWarning = _text(
            'برای نمایش مکان‌های اطراف، لطفاً GPS را فعال کنید.',
            'Please enable GPS to see nearby places.',
            'يرجى تفعيل GPS لعرض الأماكن القريبة.',
          );
          _center = _fallbackCenter;
        });
        await _loadNearby();
      }
      return;
    }

    // فقط اگر موقعیت تازه با موقعیت اولیه بیش از ۵۰۰ متر فرق دارد
    // دوباره جستجو می‌کنیم.
    final moved = quick == null ||
        const Distance().as(LengthUnit.Meter, quick, location) > 500;

    setState(() {
      _userLocation = location;
      _locationWarning = null;
      if (!_isSearchedMode) _center = location;
    });

    if (moved && !_isSearchedMode) {
      _safeMove(location, 13);
      await _loadNearby();
    }
  }

  /// جابه‌جایی نقشه؛ اگر نقشه هنوز ساخته نشده بود بی‌سروصدا نادیده گرفته می‌شود.
  void _safeMove(LatLng point, double zoom) {
    try {
      _mapController.move(point, zoom);
    } catch (_) {
      // نقشه هنوز آماده نیست؛ مرکز در ساخت بعدی اعمال می‌شود.
    }
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

    final seq = ++_loadSeq;

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

      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _places = results;
        _loading = false;
      });

      if (results.isEmpty) _scheduleAutoRetry(seq);
    } catch (_) {
      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _places = [];
        _loading = false;
      });

      _scheduleAutoRetry(seq);

      _showSnack(
        _text(
          'دریافت اطلاعات با خطا مواجه شد. دوباره تلاش کنید.',
          'Failed to load places. Please try again.',
          'فشل تحميل الأماكن. حاول مرة أخرى.',
        ),
      );
    }
  }

  /// اگر نتیجه خالی بود یا خطا آمد، یک بار بعد از ۳ ثانیه خودکار دوباره تلاش می‌کند
  /// (سرورهای نقشه گاهی اولین بار جواب نمی‌دهند). بعد از آن فقط با دکمه‌ی «تلاش دوباره».
  void _scheduleAutoRetry(int seq) {
    if (_autoRetried) return;
    _autoRetried = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || seq != _loadSeq || _loading) return;
      _loadNearby();
    });
  }

  /// دکمه‌ی چرخشی «تلاش دوباره»: اگر GPS هنوز نیامده بود دوباره موقعیت را می‌گیرد،
  /// وگرنه همان جستجوی فعلی را از نو اجرا می‌کند.
  Future<void> _retry() async {
    if (_loading || _searching) return;

    setState(() {
      _retryTurns += 1;
      _autoRetried = false;
    });

    if (_userLocation == null && !_isSearchedMode) {
      await _bootstrap();
      return;
    }

    _center ??= _userLocation ?? _fallbackCenter;
    await _loadNearby();
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

    _autoRetried = false;
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

    _autoRetried = false;
    await _loadNearby();
  }

  Timer? _radiusDebounce;

  void _onRadiusChanged(double value) {
    _autoRetried = false;

    setState(() {
      _radiusKm = value;
    });

    // چند لمس پشت‌سرهم فقط یک جستجو می‌سازد (به‌جای یک جستجوی کامل برای هر لمس)
    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadNearby();
    });
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
  // دکمه‌ی نیم‌دایره‌ی «نمایش» (VIP) — روی لبه‌ی بالای پنل شعاع جستجو
  // سلامت + جاذبه‌ها → نمایش جاذبه‌ها (سلامت با فیلتر مخصوص خودش)
  // اقامتگاه → نمایش اقامتگاه‌ها
  // ============================================================

  void _openShowcase() {
    final category = widget.initialCategory;

    // اقامتگاه → گالری اقامتگاه‌ها؛ سلامت → گالری گردشگری سلامت (مثل اقامتگاه،
    // با کلید آسانسوریِ «نوع سلامت»)؛ جاذبه‌ها → «فیلم‌های ویژه»ی کلید ۶
    // صفحه‌ی اصلی (با بنر هاب چهار کلید بالای صفحه).
    final Widget page = category == PlaceCategory.accommodation
        ? const ShowcaseGalleryPage(kind: ShowcaseKind.accommodation)
        : (category == PlaceCategory.health
            ? const ShowcaseGalleryPage(kind: ShowcaseKind.health)
            : const ShowcaseGalleryPage(kind: ShowcaseKind.video, showHubBanner: true));

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
                        initialZoom: 13,
                        minZoom: 3,
                        maxZoom: 18,
                      ),
                      children: [
                        const ResilientTileLayer(maxZoom: 18),
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

                    // دکمه‌ی چرخشی «تلاش دوباره» (روی لبه‌ی مخالف دکمه‌ی تمام‌صفحه)
                    PositionedDirectional(
                      start: 10,
                      bottom: 64,
                      child: Tooltip(
                        message: _text(
                          'تلاش دوباره',
                          'Try again',
                          'حاول مرة أخرى',
                        ),
                        child: Material(
                          color: const Color(0xff071722)
                              .withValues(alpha: 0.85),
                          shape: const CircleBorder(
                            side: BorderSide(color: Color(0xffffd36a)),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _retry,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: AnimatedRotation(
                                turns: _retryTurns,
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeInOut,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xffffd36a),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xee071722),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xffffd36a),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xffffd36a),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _text(
                                    'در حال جستجوی اطراف شما…',
                                    'Searching around you…',
                                    'جارٍ البحث حولك…',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // بنر فیلم VIP: در حال بارگذاری یا لیست خالی، بزرگ‌تر
                        ShowcaseFilmBanner(
                          category: widget.initialCategory,
                          language: _bannerLang,
                          onTap: _openShowcase,
                          large: _loading || _searching || _places.isEmpty,
                        ),
                        TouristPlacesList(
                          places: _places,
                          language: _langCode,
                          category: widget.initialCategory,
                          onPlaceTap: _onListItemTap,
                          onRouteTap: _openRoute,
                          isFavorite: _isFavorite,
                          onFavoriteTap: _toggleFavorite,
                          onRetry: _retry,
                        ),
                      ],
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
