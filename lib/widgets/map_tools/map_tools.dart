// ابزارهای رایگان نقشه: خط‌کش (فاصله)، محاسبهٔ مساحت زمین،
// نمایش/کپی/اشتراک مختصات (نگه داشتن انگشت روی نقشه) و نقطه‌های ذخیره‌شدهٔ شخصی.
//
// همه‌چیز روی خود گوشی محاسبه می‌شود (بدون اینترنت و بدون پکیج جدید).
// مساحت با فرمول کره‌ای محاسبه می‌شود و تقریبی است، نه نقشه‌برداری رسمی.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/safe_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/menu_translations.dart';

const Color _kDark = Color(0xff0e2433);
const Color _kGold = Color(0xffffd36a);
const Color _kTeal = Color(0xff22e0ad);

/// فارسی / عربی / برای بقیهٔ زبان‌ها انگلیسی
String _t(String fa, String en, String ar) {
  switch (MenuLanguage.current) {
    case 'fa':
      return fa;
    case 'ar':
      return ar;
    default:
      return en;
  }
}

TextDirection get _dir =>
    MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr;

// ============================================================
// محاسبات
// ============================================================

double _rad(double deg) => deg * math.pi / 180.0;

/// فاصلهٔ دو نقطه به متر (هاورساین)
double _haversine(LatLng a, LatLng b) {
  const r = 6371008.8;
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final sLat = math.sin(dLat / 2);
  final sLon = math.sin(dLon / 2);
  final h = sLat * sLat +
      math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * sLon * sLon;
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

/// مساحت چندضلعی روی کره به متر مربع (تقریبی؛ برای ضلع‌های متقاطع نادرست است)
double _polygonArea(List<LatLng> pts) {
  if (pts.length < 3) return 0;
  const r = 6378137.0;
  var sum = 0.0;
  for (var i = 0; i < pts.length; i++) {
    final p1 = pts[i];
    final p2 = pts[(i + 1) % pts.length];
    sum += (_rad(p2.longitude) - _rad(p1.longitude)) *
        (2 + math.sin(_rad(p1.latitude)) + math.sin(_rad(p2.latitude)));
  }
  return (sum * r * r / 2.0).abs();
}

String _group(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return v < 0 ? '-$b' : b.toString();
}

String formatDistance(double m) {
  if (m < 1000) {
    return '${m.toStringAsFixed(m < 10 ? 1 : 0)} ${_t('متر', 'm', 'م')}';
  }
  final km = m / 1000;
  return '${km.toStringAsFixed(km < 100 ? 2 : 1)} ${_t('کیلومتر', 'km', 'كم')}';
}

String formatArea(double sqm) {
  final parts = <String>[
    '${_group(sqm.round())} ${_t('متر مربع', 'm²', 'م²')}',
  ];
  if (sqm >= 1000) {
    final ha = sqm / 10000;
    parts.add('${ha.toStringAsFixed(ha < 10 ? 2 : 1)} ${_t('هکتار', 'ha', 'هكتار')}');
  }
  if (sqm >= 1000000) {
    parts.add('${(sqm / 1000000).toStringAsFixed(2)} ${_t('کیلومتر مربع', 'km²', 'كم²')}');
  }
  return parts.join('  •  ');
}

String _googleMapsUrl(double lat, double lng) =>
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

// ============================================================
// کنترلر خط‌کش / مساحت
// ============================================================

enum MeasureMode { none, distance, area }

class MapMeasureController extends ChangeNotifier {
  MeasureMode mode = MeasureMode.none;
  final List<LatLng> points = <LatLng>[];

  bool get active => mode != MeasureMode.none;

  void start(MeasureMode m) {
    mode = m;
    points.clear();
    notifyListeners();
  }

  void stop() {
    mode = MeasureMode.none;
    points.clear();
    notifyListeners();
  }

  void add(LatLng p) {
    if (!active) return;
    points.add(p);
    notifyListeners();
  }

  void undo() {
    if (points.isEmpty) return;
    points.removeLast();
    notifyListeners();
  }

  void clear() {
    if (points.isEmpty) return;
    points.clear();
    notifyListeners();
  }

  /// طول مسیر (در حالت مساحت: بدون ضلع بستن)
  double get lengthMeters {
    var t = 0.0;
    for (var i = 1; i < points.length; i++) {
      t += _haversine(points[i - 1], points[i]);
    }
    return t;
  }

  /// محیط (ضلع بستن هم حساب می‌شود)
  double get perimeterMeters {
    if (points.length < 3) return lengthMeters;
    return lengthMeters + _haversine(points.last, points.first);
  }

  double get areaSqm => _polygonArea(points);
}

// ============================================================
// نقطه‌های ذخیره‌شده
// ============================================================

class MapPin {
  const MapPin({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'lat': lat, 'lng': lng};

  static MapPin? fromJson(dynamic j) {
    try {
      final m = j as Map;
      return MapPin(
        id: m['id'].toString(),
        name: m['name'].toString(),
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class SavedPinsService {
  SavedPinsService._();

  static const String _key = 'cyrus_saved_map_pins';
  static final ValueNotifier<List<MapPin>> pins =
      ValueNotifier<List<MapPin>>(const <MapPin>[]);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      final out = <MapPin>[];
      for (final e in list) {
        final pin = MapPin.fromJson(e);
        if (pin != null) out.add(pin);
      }
      pins.value = out;
    } catch (_) {}
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _key, jsonEncode(pins.value.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> add(String name, LatLng point) async {
    final pin = MapPin(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      lat: point.latitude,
      lng: point.longitude,
    );
    pins.value = <MapPin>[...pins.value, pin];
    await _save();
  }

  static Future<void> remove(String id) async {
    pins.value = pins.value.where((e) => e.id != id).toList();
    await _save();
  }
}

// ============================================================
// لایه‌های روی نقشه (داخل children مربوط به FlutterMap)
// ============================================================

class MapMeasureLayers extends StatelessWidget {
  const MapMeasureLayers({
    super.key,
    required this.controller,
    required this.onPinTap,
  });

  final MapMeasureController controller;
  final void Function(MapPin pin) onPinTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, SavedPinsService.pins]),
      builder: (context, _) {
        final layers = <Widget>[];
        final pts = List<LatLng>.of(controller.points);
        final isArea = controller.mode == MeasureMode.area;

        if (isArea && pts.length >= 3) {
          layers.add(PolygonLayer(
            polygons: [
              Polygon(
                points: pts,
                color: const Color(0x3322e0ad),
                borderColor: _kTeal,
                borderStrokeWidth: 3,
              ),
            ],
          ));
        } else if (pts.length >= 2) {
          layers.add(PolylineLayer(
            polylines: [
              Polyline(points: pts, strokeWidth: 4, color: _kGold),
            ],
          ));
        }

        if (pts.isNotEmpty) {
          layers.add(MarkerLayer(
            markers: <Marker>[
              for (var i = 0; i < pts.length; i++)
                Marker(
                  point: pts[i],
                  width: 24,
                  height: 24,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isArea ? _kTeal : _kGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isArea
                        ? null
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff071722),
                            ),
                          ),
                  ),
                ),
            ],
          ));
        }

        final saved = SavedPinsService.pins.value;
        if (saved.isNotEmpty) {
          layers.add(MarkerLayer(
            markers: <Marker>[
              for (final pin in saved)
                Marker(
                  point: LatLng(pin.lat, pin.lng),
                  width: 44,
                  height: 44,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPinTap(pin),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xffff5252),
                      size: 40,
                    ),
                  ),
                ),
            ],
          ));
        }

        if (layers.isEmpty) return const SizedBox.shrink();
        return Stack(fit: StackFit.expand, children: layers);
      },
    );
  }
}

// ============================================================
// پنل نتیجه (پایین صفحه، بیرون از FlutterMap)
// ============================================================

class MapMeasurePanel extends StatelessWidget {
  const MapMeasurePanel({super.key, required this.controller});

  final MapMeasureController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.active) return const SizedBox.shrink();

        final isArea = controller.mode == MeasureMode.area;
        final n = controller.points.length;

        var result = '';
        var extra = '';
        String hint;

        if (isArea) {
          if (n >= 3) {
            result = formatArea(controller.areaSqm);
            extra =
                '${_t('محیط', 'Perimeter', 'المحيط')}: ${formatDistance(controller.perimeterMeters)}';
            hint = _t('مساحت تقریبی است؛ برای دقت بیشتر زوم کنید و نقطه‌ها را دقیق‌تر بزنید',
                'Approximate area; zoom in for more accurate points',
                'مساحة تقريبية؛ قرّب الخريطة لدقة أكبر');
          } else {
            hint = _t('روی گوشه‌های زمین ضربه بزنید ($n از ۳ نقطهٔ لازم)',
                'Tap the corners of the land ($n of 3 points needed)',
                'اضغط على زوايا الأرض ($n من 3 نقاط)');
          }
        } else {
          if (n >= 2) {
            result = formatDistance(controller.lengthMeters);
            hint = _t('برای ادامهٔ مسیر نقطهٔ بعدی را بزنید',
                'Tap the next point to extend the path',
                'اضغط على النقطة التالية لمتابعة المسار');
          } else {
            hint = _t('روی نقشه ضربه بزنید تا نقطهٔ شروع و بعد نقطه‌های بعدی را بگذارید',
                'Tap the map to place the start point, then the next points',
                'اضغط على الخريطة لوضع نقطة البداية ثم النقاط التالية');
          }
        }

        final copyText = extra.isEmpty ? result : '$result\n$extra';

        return Directionality(
          textDirection: _dir,
          child: Material(
            color: const Color(0xee0e2433),
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isArea ? Icons.crop_square_rounded : Icons.straighten_rounded,
                        color: _kGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArea
                              ? _t('محاسبهٔ مساحت زمین', 'Land area', 'مساحة الأرض')
                              : _t('خط‌کش', 'Ruler', 'المسطرة'),
                          style: const TextStyle(
                            color: Color(0xffffe39a),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _t('بستن', 'Close', 'إغلاق'),
                        visualDensity: VisualDensity.compact,
                        onPressed: controller.stop,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  if (result.isNotEmpty)
                    Text(
                      result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (extra.isNotEmpty)
                    Text(extra, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(hint, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        tooltip: _t('برگشت یک نقطه', 'Undo', 'تراجع'),
                        onPressed: n > 0 ? controller.undo : null,
                        icon: const Icon(Icons.undo_rounded),
                        color: _kGold,
                        disabledColor: Colors.white24,
                      ),
                      IconButton(
                        tooltip: _t('پاک کردن نقطه‌ها', 'Clear', 'مسح'),
                        onPressed: n > 0 ? controller.clear : null,
                        icon: const Icon(Icons.delete_sweep_rounded),
                        color: _kGold,
                        disabledColor: Colors.white24,
                      ),
                      IconButton(
                        tooltip: _t('کپی نتیجه', 'Copy result', 'نسخ النتيجة'),
                        onPressed: result.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: copyText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_t('کپی شد', 'Copied', 'تم النسخ')),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.copy_rounded),
                        color: _kGold,
                        disabledColor: Colors.white24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// منوی ابزارها
// ============================================================

class _ToolItem {
  const _ToolItem(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

Future<void> showMapToolsSheet(
  BuildContext context, {
  required MapMeasureController controller,
  required void Function(LatLng point) onGoTo,
}) {
  final items = <_ToolItem>[
    _ToolItem(
      Icons.straighten_rounded,
      _t('خط‌کش (فاصله)', 'Ruler (distance)', 'المسطرة (المسافة)'),
      _t('چند نقطه روی نقشه بزنید و طول مسیر را ببینید',
          'Tap points on the map to measure a path',
          'اضغط نقاطًا على الخريطة لقياس المسار'),
      () => controller.start(MeasureMode.distance),
    ),
    _ToolItem(
      Icons.crop_square_rounded,
      _t('مساحت زمین', 'Land area', 'مساحة الأرض'),
      _t('گوشه‌های زمین را بزنید؛ مساحت به متر مربع و هکتار',
          'Tap the corners; area in m² and hectares',
          'اضغط الزوايا؛ المساحة بالمتر المربع والهكتار'),
      () => controller.start(MeasureMode.area),
    ),
    _ToolItem(
      Icons.bookmark_rounded,
      _t('نقطه‌های من', 'My saved pins', 'نقاطي'),
      _t('فهرست نقطه‌هایی که ذخیره کرده‌اید',
          'Places you saved on the map',
          'الأماكن التي حفظتها على الخريطة'),
      () => showSavedPinsSheet(context, onGoTo: onGoTo),
    ),
    _ToolItem(
      Icons.touch_app_rounded,
      _t('مختصات یک نقطه', 'Coordinates of a point', 'إحداثيات نقطة'),
      _t('انگشت را روی نقشه نگه دارید: مختصات، کپی، اشتراک و ذخیره',
          'Long-press the map: coordinates, copy, share and save',
          'اضغط مطولًا على الخريطة: الإحداثيات والنسخ والمشاركة والحفظ'),
      null,
    ),
  ];

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: _dir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t('ابزارهای نقشه', 'Map tools', 'أدوات الخريطة'),
                  style: const TextStyle(
                    color: Color(0xffffe39a),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                for (final it in items)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: it.onTap == null
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                            it.onTap!();
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x14ffffff),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Icon(it.icon, color: _kGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  it.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// فهرست نقطه‌های ذخیره‌شده
// ============================================================

Future<void> showSavedPinsSheet(
  BuildContext context, {
  required void Function(LatLng point) onGoTo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: _dir,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: ValueListenableBuilder<List<MapPin>>(
                valueListenable: SavedPinsService.pins,
                builder: (_, list, __) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t('نقطه‌های من', 'My saved pins', 'نقاطي'),
                        style: const TextStyle(
                          color: Color(0xffffe39a),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _t('هنوز نقطه‌ای ذخیره نکرده‌اید. انگشت را روی نقشه نگه دارید و «ذخیره» را بزنید.',
                                'No pins yet. Long-press the map and tap "Save".',
                                'لا توجد نقاط بعد. اضغط مطولًا على الخريطة ثم "حفظ".'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final pin = list[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xffff5252),
                                ),
                                title: Text(
                                  pin.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${pin.lat.toStringAsFixed(5)}, ${pin.lng.toStringAsFixed(5)}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  tooltip: _t('حذف', 'Delete', 'حذف'),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
                                  onPressed: () => SavedPinsService.remove(pin.id),
                                ),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  onGoTo(LatLng(pin.lat, pin.lng));
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// مختصات (نگه داشتن انگشت روی نقشه یا لمس یک نقطهٔ ذخیره‌شده)
// ============================================================

Future<void> showCoordinateSheet(
  BuildContext context,
  LatLng point, {
  MapPin? pin,
}) {
  final lat = point.latitude.toStringAsFixed(6);
  final lng = point.longitude.toStringAsFixed(6);
  final coords = '$lat, $lng';

  void toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: _dir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  pin != null ? pin.name : _t('مختصات این نقطه', 'Coordinates', 'إحداثيات النقطة'),
                  style: const TextStyle(
                    color: Color(0xffffe39a),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    coords,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: coords));
                        Navigator.of(ctx).pop();
                        toast(_t('مختصات کپی شد', 'Coordinates copied', 'تم نسخ الإحداثيات'));
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(_t('کپی', 'Copy', 'نسخ')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final title = pin?.name ?? '';
                        Share.share(
                          '${title.isEmpty ? '' : '$title\n'}$coords\n${_googleMapsUrl(point.latitude, point.longitude)}',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(_t('اشتراک', 'Share', 'مشاركة')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        var opened = false;
                        try {
                          opened = await launchUrl(
                            Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {}
                        if (!opened) {
                          try {
                            await launchUrl(
                              Uri.parse(_googleMapsUrl(point.latitude, point.longitude)),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(_t('باز کردن در نقشه', 'Open in maps', 'فتح في الخرائط')),
                    ),
                    if (pin == null)
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final name = await _askPinName(context);
                          if (name != null) {
                            await SavedPinsService.add(name, point);
                            toast(_t('ذخیره شد', 'Saved', 'تم الحفظ'));
                          }
                        },
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: Text(_t('ذخیره نقطه', 'Save pin', 'حفظ النقطة')),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await SavedPinsService.remove(pin.id);
                          toast(_t('حذف شد', 'Deleted', 'تم الحذف'));
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(_t('حذف نقطه', 'Delete pin', 'حذف النقطة')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> _askPinName(BuildContext context) {
  final c = TextEditingController(
    text: '${_t('نقطه', 'Pin', 'نقطة')} ${SavedPinsService.pins.value.length + 1}',
  );
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return Directionality(
        textDirection: _dir,
        child: AlertDialog(
          title: Text(_t('نام نقطه', 'Pin name', 'اسم النقطة')),
          content: TextField(controller: c, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_t('انصراف', 'Cancel', 'إلغاء')),
            ),
            TextButton(
              onPressed: () {
                final v = c.text.trim();
                Navigator.of(ctx).pop(v.isEmpty ? null : v);
              },
              child: Text(_t('ذخیره', 'Save', 'حفظ')),
            ),
          ],
        ),
      );
    },
  );
}
