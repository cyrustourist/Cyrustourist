import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/carto_config.dart';
import '../core/language/menu_translations.dart';
import '../services/tile_cache.dart';

/// آدرس کاشی ماهواره (خالی = گزینه‌های ماهواره در دکمهٔ لایه‌ها نمایش داده نمی‌شود).
/// Esri از ایران مسدود است. نمونه با Mapbox (توکن خودتان):
/// 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}?access_token=TOKEN'
/// هر سرویس دیگری که کاشی {z}/{x}/{y} بدهد و از ایران باز شود هم همین‌جا گذاشته می‌شود.
const String kSatelliteUrlTemplate = '';

bool get kHasSatellite => kSatelliteUrlTemplate.isNotEmpty;

/// نوع لایهٔ نقشه (انتخاب کاربر، ماندگار)
enum MapLayerKind { standard, terrain, satellite, hybrid }

class MapLayerPref {
  MapLayerPref._();

  static const String _key = 'cyrus_map_layer_kind';
  static final ValueNotifier<MapLayerKind> kind =
      ValueNotifier<MapLayerKind>(MapLayerKind.standard);
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final i = p.getInt(_key) ?? 0;
      if (i >= 0 && i < MapLayerKind.values.length) {
        final k = MapLayerKind.values[i];
        final needsSat = k == MapLayerKind.satellite || k == MapLayerKind.hybrid;
        kind.value = (needsSat && !kHasSatellite) ? MapLayerKind.standard : k;
      }
    } catch (_) {}
  }

  static Future<void> set(MapLayerKind k) async {
    kind.value = k;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_key, k.index);
    } catch (_) {}
  }
}

String _lt(String fa, String en, String ar) {
  switch (MenuLanguage.current) {
    case 'en':
      return en;
    case 'ar':
      return ar;
    default:
      return fa;
  }
}

/// کاشی‌های رایگان با کش دیسکی
const Duration _kStdAge = Duration(days: 8); // سیاست OSM: حداقل ۷ روز نگه‌داری
const Duration _kSatAge = Duration(days: 90);

TileLayer _cachedLayer({
  required String id,
  required String url,
  required Duration age,
  required double maxZoom,
  required int nativeZoom,
  void Function(TileImage, Object, StackTrace?)? onError,
}) {
  return TileLayer(
    key: ValueKey('tile-$id'),
    urlTemplate: url,
    tileProvider: CachedTileProvider(layerId: id, maxAge: age),
    maxNativeZoom: nativeZoom,
    maxZoom: maxZoom,
    errorTileCallback: onError ?? (_, __, ___) {},
  );
}

/// نمایش نام منبع نقشه (الزام حق نشر منابع رایگان)
class _MapAttribution extends StatelessWidget {
  const _MapAttribution(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6,
      bottom: 2,
      child: IgnorePointer(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 9,
            shadows: [Shadow(color: Colors.white, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

/// دکمهٔ تغییر لایهٔ نقشه (استاندارد / عوارض زمین / ماهواره / ماهواره + نام‌ها)
class MapLayerButton extends StatelessWidget {
  const MapLayerButton({super.key, this.mini = false});
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff0e2433),
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: _lt('لایه‌های نقشه', 'Map layers', 'طبقات الخريطة'),
        onPressed: () => showMapLayerSheet(context),
        icon: const Icon(Icons.layers_rounded, color: Color(0xffffd36a)),
      ),
    );
  }
}

Future<void> showMapLayerSheet(BuildContext context) {
  final items = <List<Object>>[
    [MapLayerKind.standard, Icons.map_rounded, _lt('نقشه استاندارد', 'Standard map', 'خريطة عادية'), _lt('جاده‌ها و نام مکان‌ها، سریع‌ترین', 'Roads and place names, fastest', 'الطرق وأسماء الأماكن')],
    [MapLayerKind.terrain, Icons.terrain_rounded, _lt('عوارض زمین', 'Terrain', 'التضاريس'), _lt('کوه، دره، خطوط ارتفاع و مسیرهای پیاده', 'Mountains, contours and trails', 'الجبال وخطوط الارتفاع')],
    [MapLayerKind.satellite, Icons.satellite_alt_rounded, _lt('ماهواره (دیدن خانه‌ها)', 'Satellite (see buildings)', 'القمر الصناعي'), _lt('عکس هوایی خانه‌ها و روستاها', 'Aerial imagery of houses and villages', 'صور جوية للمنازل والقرى')],
    [MapLayerKind.hybrid, Icons.layers_rounded, _lt('ماهواره + نام جاده‌ها', 'Satellite + labels', 'قمر صناعي + أسماء'), _lt('بهترین حالت برای پیدا کردن اقامتگاه', 'Best for locating a stay', 'الأفضل لتحديد الإقامة')],
  ];
  if (!kHasSatellite) {
    items.removeWhere((e) => e[0] == MapLayerKind.satellite || e[0] == MapLayerKind.hybrid);
  }
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xff0e2433),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) {
      final rtl = MenuLanguage.current != 'en';
      return Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: ValueListenableBuilder<MapLayerKind>(
            valueListenable: MapLayerPref.kind,
            builder: (_, cur, __) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_lt('لایه‌های نقشه', 'Map layers', 'طبقات الخريطة'),
                      style: const TextStyle(color: Color(0xffffe39a), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (final it in items)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        MapLayerPref.set(it[0] as MapLayerKind);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cur == it[0] ? const Color(0x3322e0ad) : const Color(0x14ffffff),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cur == it[0] ? const Color(0xff22e0ad) : Colors.white12),
                        ),
                        child: Row(children: [
                          Icon(it[1] as IconData, color: const Color(0xffffd36a)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(it[2] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(it[3] as String, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ]),
                          ),
                          if (cur == it[0]) const Icon(Icons.check_circle_rounded, color: Color(0xff22e0ad)),
                        ]),
                      ),
                    ),
                  Text('© OpenStreetMap · OpenTopoMap · CARTO',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// لایهٔ پایهٔ آفلاین: کاشی‌های کم‌زوم ایران که داخل خود اپ هستند
/// (assets/tiles/{z}_{x}_{y}.png ، زوم ۰ تا ۷).
/// فوری نمایش داده می‌شود تا صفحهٔ سفید/خاکستری دیده نشود؛ کاشی‌های آنلاین روی آن می‌نشینند.
/// اگر فایل کاشی‌ای در assets نباشد، همان نقطه خالی می‌ماند و خطایی به کاربر نشان داده نمی‌شود.
class OfflineBaseTileLayer extends StatelessWidget {
  const OfflineBaseTileLayer({super.key, this.maxZoom = 18});

  /// آخرین زومی که کاشی آفلاین دارد (بالاتر از آن، کاشی زوم ۷ کشیده می‌شود)
  static const int nativeMaxZoom = 7;

  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      key: const ValueKey('tile-offline-base'),
      urlTemplate: 'assets/tiles/{z}_{x}_{y}.png',
      tileProvider: AssetTileProvider(),
      maxNativeZoom: nativeMaxZoom,
      maxZoom: maxZoom,
      errorTileCallback: (_, __, ___) {},
    );
  }
}

/// لایهٔ کاشی نقشه: پایهٔ آفلاین + آنلاین با جایگزین خودکار (بدون نیاز به کلید یا تمدید).
/// ترتیب آنلاین: ۰ = OpenStreetMap ، ۱ = CARTO.
/// اگر چند کاشی پیاپی خطا بدهد (فیلتر شدن یا قطعی سرویس)، خودکار به لایهٔ بعدی می‌رود.
class ResilientTileLayer extends StatefulWidget {
  const ResilientTileLayer({
    super.key,
    this.maxZoom = 18,
    this.userAgentPackageName = 'com.cyrustourist.app',
  });

  final double maxZoom;
  final String userAgentPackageName;

  @override
  State<ResilientTileLayer> createState() => _ResilientTileLayerState();
}

class _ResilientTileLayerState extends State<ResilientTileLayer> {
  static const int _steps = 2;
  int _step = 0;
  int _errors = 0;
  int _switches = 0;

  void _onError(int step) {
    if (!mounted || step != _step) return;
    _errors++;
    if (_errors >= 4 && _switches < _steps - 1) {
      _switches++;
      // خارج از فاز ساخت ویجت تغییر وضعیت می‌دهیم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _step = (_step + 1) % _steps;
          _errors = 0;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    MapLayerPref.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MapLayerKind>(
      valueListenable: MapLayerPref.kind,
      builder: (_, kind, __) => _buildFor(kind),
    );
  }

  Widget _labels() => _cachedLayer(
        id: 'carto-labels',
        url: 'https://basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png?key=${CartoConfig.apiKey}',
        age: _kStdAge,
        maxZoom: widget.maxZoom,
        nativeZoom: 19,
      );

  Widget _satellite() => _cachedLayer(
        id: 'sat',
        url: kSatelliteUrlTemplate,
        age: _kSatAge,
        maxZoom: widget.maxZoom,
        nativeZoom: 18,
      );

  Widget _buildFor(MapLayerKind kind) {
    switch (kind) {
      case MapLayerKind.terrain:
        return Stack(fit: StackFit.expand, children: [
          OfflineBaseTileLayer(maxZoom: widget.maxZoom),
          _cachedLayer(
            id: 'topo',
            url: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
            age: _kSatAge,
            maxZoom: widget.maxZoom,
            nativeZoom: 17,
          ),
          const _MapAttribution('© OpenStreetMap, SRTM | © OpenTopoMap (CC-BY-SA)'),
        ]);
      case MapLayerKind.satellite:
        if (!kHasSatellite) break;
        return Stack(fit: StackFit.expand, children: [
          _satellite(),
          const _MapAttribution('Satellite imagery'),
        ]);
      case MapLayerKind.hybrid:
        if (!kHasSatellite) break;
        return Stack(fit: StackFit.expand, children: [
          _satellite(),
          _labels(),
          const _MapAttribution('Satellite imagery | Labels © CARTO, OpenStreetMap'),
        ]);
      case MapLayerKind.standard:
        break;
    }
    final Widget online = _step == 1
        ? _cachedLayer(
            id: 'carto',
            url: CartoConfig.tileUrlWithKey,
            age: _kStdAge,
            maxZoom: widget.maxZoom,
            nativeZoom: 19,
            onError: (_, __, ___) => _onError(1),
          )
        : _cachedLayer(
            id: 'osm',
            url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            age: _kStdAge,
            maxZoom: widget.maxZoom,
            nativeZoom: 19,
            onError: (_, __, ___) => _onError(0),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        OfflineBaseTileLayer(maxZoom: widget.maxZoom),
        online,
        const _MapAttribution('© OpenStreetMap contributors'),
      ],
    );
  }
}
