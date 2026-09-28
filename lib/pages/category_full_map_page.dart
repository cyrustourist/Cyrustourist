import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import '../config/carto_config.dart';
import '../core/language/menu_translations.dart';
import '../widgets/map_markers_layer.dart';
import '../widgets/map_place_details_sheet.dart';

/// نمایش تمام‌صفحه‌ی همان نقشه‌ی کوچک صفحه‌ی کلیدهای ۲ (سلامت)،
/// ۳ (جاذبه‌ها) و ۵ (اقامتگاه)، برای زوم و بررسی راحت‌تر
/// جاذبه‌های پیدا‌شده یا جستجو‌شده.
///
/// دکمه بازگشت بالای صفحه (leading) دقیقاً همان «بازگشت به حالت
/// اول» است: چون این صفحه فقط با Navigator.push باز شده، با زدن
/// دکمه بازگشت یا دکمه سیستم، بدون هیچ تغییری روی صفحه‌ی قبلی و
/// وضعیت آن (جستجو، شعاع، لیست) برمی‌گردیم.
/// نتیجه‌ی جستجوی پس‌زمینه برای [CategoryFullMapPage].
class CategorySearchResult {
  const CategorySearchResult({
    required this.places,
    required this.center,
    this.locationDenied = false,
  });

  final List<MapPlace> places;
  final LatLng center;

  /// اگر موقعیت کاربر در دسترس نبود و مرکز پیش‌فرض استفاده شد.
  final bool locationDenied;
}

class CategoryFullMapPage extends StatefulWidget {
  /// اگر داده شود، نقشه فوراً باز می‌شود و نتیجه‌ها در پس‌زمینه
  /// (با پیام «در حال جستجوی اطراف شما» و چرخنده) روی نقشه می‌آیند.
  final Future<CategorySearchResult> Function()? loader;
  final List<MapPlace> places;
  final LatLng initialCenter;
  final String title;
  final bool isRtl;
  final bool Function(MapPlace place) isFavorite;
  final void Function(MapPlace place) onFavorite;
  final void Function(MapPlace place) onRoute;

  const CategoryFullMapPage({
    super.key,
    this.loader,
    this.places = const [],
    required this.initialCenter,
    required this.title,
    required this.isRtl,
    required this.isFavorite,
    required this.onFavorite,
    required this.onRoute,
  });

  @override
  State<CategoryFullMapPage> createState() =>
      _CategoryFullMapPageState();
}

class _CategoryFullMapPageState
    extends State<CategoryFullMapPage> {
  final MapController _mapController = MapController();

  late List<MapPlace> _places = widget.places;
  late bool _loading = widget.loader != null;
  bool _failed = false;
  bool _empty = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    if (widget.loader != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _empty = false;
    });

    try {
      final result = await widget.loader!();

      if (!mounted) return;

      setState(() {
        _places = result.places;
        _loading = false;
        _empty = result.places.isEmpty;
        _locationDenied = result.locationDenied;
      });

      _mapController.move(result.center, 13);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _t(String key) {
    const texts = <String, Map<String, String>>{
      'searching': {
        'fa': 'در حال جستجوی اطراف شما…',
        'en': 'Searching around you…',
        'ar': 'جارٍ البحث حولك…',
        'tr': 'Çevrenizde aranıyor…',
        'ru': 'Идёт поиск рядом с вами…',
        'fr': 'Recherche autour de vous…',
        'de': 'Suche in Ihrer Umgebung…',
        'es': 'Buscando a tu alrededor…',
        'zh': '正在搜索您附近…',
        'it': 'Ricerca intorno a te…',
      },
      'failed': {
        'fa': 'دریافت اطلاعات انجام نشد. اینترنت را بررسی کنید.',
        'en': 'Could not load results. Check your connection.',
        'ar': 'تعذّر تحميل النتائج. تحقق من الاتصال.',
        'tr': 'Sonuçlar yüklenemedi. Bağlantınızı kontrol edin.',
        'ru': 'Не удалось загрузить. Проверьте соединение.',
        'fr': 'Chargement impossible. Vérifiez la connexion.',
        'de': 'Laden fehlgeschlagen. Verbindung prüfen.',
        'es': 'No se pudo cargar. Revisa tu conexión.',
        'zh': '加载失败，请检查网络。',
        'it': 'Caricamento non riuscito. Controlla la connessione.',
      },
      'empty': {
        'fa': 'نتیجه‌ای در این نزدیکی پیدا نشد.',
        'en': 'No results found nearby.',
        'ar': 'لم يتم العثور على نتائج قريبة.',
        'tr': 'Yakında sonuç bulunamadı.',
        'ru': 'Поблизости ничего не найдено.',
        'fr': 'Aucun résultat à proximité.',
        'de': 'Keine Ergebnisse in der Nähe.',
        'es': 'No hay resultados cerca.',
        'zh': '附近没有找到结果。',
        'it': 'Nessun risultato nelle vicinanze.',
      },
      'noLocation': {
        'fa': 'موقعیت شما در دسترس نبود؛ اطراف مرکز ایران نشان داده می‌شود.',
        'en': 'Your location is unavailable; showing central Iran.',
        'ar': 'موقعك غير متاح؛ يتم عرض وسط إيران.',
        'tr': 'Konumunuz alınamadı; İran merkezi gösteriliyor.',
        'ru': 'Местоположение недоступно; показан центр Ирана.',
        'fr': 'Position indisponible ; centre de l’Iran affiché.',
        'de': 'Standort nicht verfügbar; Zentrum des Iran angezeigt.',
        'es': 'Ubicación no disponible; se muestra el centro de Irán.',
        'zh': '无法获取位置，显示伊朗中部。',
        'it': 'Posizione non disponibile; mostrato il centro dell’Iran.',
      },
      'retry': {
        'fa': 'تلاش دوباره',
        'en': 'Retry',
        'ar': 'إعادة المحاولة',
        'tr': 'Tekrar dene',
        'ru': 'Повторить',
        'fr': 'Réessayer',
        'de': 'Erneut versuchen',
        'es': 'Reintentar',
        'zh': '重试',
        'it': 'Riprova',
      },
    };

    final byKey = texts[key]!;
    return byKey[MenuLanguage.current] ?? byKey['en']!;
  }

  Widget _statusCard() {
    final message = _loading
        ? _t('searching')
        : _failed
            ? _t('failed')
            : _empty
                ? _t('empty')
                : _locationDenied
                    ? _t('noLocation')
                    : '';

    if (message.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      top: 14,
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xee071722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffffd36a)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xffffd36a),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_failed && widget.loader != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _load,
                    child: Text(
                      _t('retry'),
                      style: const TextStyle(
                        color: Color(0xffffd36a),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onMarkerTap(MapPlace place) {
    MapPlaceDetailsSheet.show(
      context,
      place,
      isFavorite: widget.isFavorite(place),
      onFavorite: () {
        Navigator.pop(context);
        widget.onFavorite(place);
      },
      onRoute: () {
        Navigator.pop(context);
        widget.onRoute(place);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            tooltip: widget.isRtl
                ? 'بازگشت به حالت اول'
                : 'Back',
            icon: Icon(
              widget.isRtl
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  CartoConfig.tileUrlWithKey,
              userAgentPackageName: 'com.cyrustourist.app',
            ),
            MapMarkersLayer(
              places: _places,
              onTap: _onMarkerTap,
            ),
          ],
            ),
            _statusCard(),
          ],
        ),
      ),
    );
  }
}
