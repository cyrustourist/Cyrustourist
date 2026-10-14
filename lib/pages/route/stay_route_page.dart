import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/location_manager.dart';
import '../../widgets/resilient_tile_layer.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _cardSoft = Color(0xff0e2f43);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

enum _Mode { car, bike, foot }

class _Step {
  _Step(this.text, this.road, this.meters, this.location);
  final String text;
  final String road;
  final double meters;
  final LatLng location;
}

class _Route {
  _Route(this.points, this.meters, this.seconds, this.steps);
  final List<LatLng> points;
  final double meters;
  final double seconds;
  final List<_Step> steps;
}

/// ===============================================================
/// مسیریابی پیشرفته‌ی داخل برنامه
/// ---------------------------------------------------------------
/// - موقعیت کاربر خودکار گرفته می‌شود (GPS) و مسیر تا اقامتگاه کشیده می‌شود
/// - چند مسیر پیشنهادی (حداکثر ۳)، فاصله، زمان سفر، ساعت حرکت و ساعت رسیدن
/// - حالت‌ها: خودرو / دوچرخه / پیاده
/// - فهرست مراحل مسیر (گام‌به‌گام)
/// - دکمه‌ی باز کردن در گوگل‌مپ / ویز / برنامه‌ی نقشه‌ی گوشی
/// داده‌ها: OSRM (رایگان و بدون کلید). اگر شبکه نبود، مسیر مستقیم و فاصله‌ی هوایی
/// نمایش داده می‌شود و دکمه‌های باز کردن برنامه‌ی مسیریاب فعال می‌مانند.
/// ===============================================================
class StayRoutePage extends StatefulWidget {
  const StayRoutePage({
    super.key,
    required this.destination,
    required this.destinationName,
    required this.lang,
  });

  final LatLng destination;
  final String destinationName;

  /// fa / en / ar
  final String lang;

  @override
  State<StayRoutePage> createState() => _StayRoutePageState();
}

class _StayRoutePageState extends State<StayRoutePage> {
  final MapController _map = MapController();

  LatLng? _me;
  bool _locating = true;
  bool _loading = false;
  String? _error;
  _Mode _mode = _Mode.car;
  List<_Route> _routes = [];
  int _sel = 0;
  bool _stepsOpen = false;
  late DateTime _departAt;

  String get _l => (widget.lang == 'fa' || widget.lang == 'ar') ? widget.lang : 'en';
  bool get _rtl => _l != 'en';

  String _tr(String fa, String en, String ar) => _l == 'fa' ? fa : (_l == 'ar' ? ar : en);

  @override
  void initState() {
    super.initState();
    _departAt = DateTime.now();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final me = await LocationManager.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _me = me;
      _locating = false;
      _departAt = DateTime.now();
    });
    if (me == null) {
      setState(() => _error = _tr(
            'موقعیت شما دریافت نشد. GPS و دسترسی مکان را روشن کنید یا مسیر را در برنامه‌ی مسیریاب باز کنید.',
            'Could not get your location. Turn on GPS and location permission, or open the route in a navigation app.',
            'تعذر تحديد موقعك. فعّل GPS وإذن الموقع أو افتح المسار في تطبيق الملاحة.',
          ));
      try {
        _map.move(widget.destination, 14);
      } catch (_) {}
      return;
    }
    await _fetch();
  }

  String get _profileUrl {
    switch (_mode) {
      case _Mode.car:
        return 'https://routing.openstreetmap.de/routed-car/route/v1/driving/';
      case _Mode.bike:
        return 'https://routing.openstreetmap.de/routed-bike/route/v1/driving/';
      case _Mode.foot:
        return 'https://routing.openstreetmap.de/routed-foot/route/v1/driving/';
    }
  }

  Future<void> _fetch() async {
    final me = _me;
    if (me == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _routes = [];
      _sel = 0;
    });

    final d = widget.destination;
    final coords = '${me.longitude},${me.latitude};${d.longitude},${d.latitude}';
    final q = '?overview=full&geometries=geojson&steps=true&alternatives=true';
    final candidates = <String>[
      '$_profileUrl$coords$q',
      if (_mode == _Mode.car) 'https://router.project-osrm.org/route/v1/driving/$coords$q',
    ];

    List<_Route> found = [];
    for (final url in candidates) {
      found = await _request(url);
      if (found.isNotEmpty) break;
    }
    if (!mounted) return;

    if (found.isEmpty) {
      final straight = Geolocator.distanceBetween(me.latitude, me.longitude, d.latitude, d.longitude);
      setState(() {
        _loading = false;
        _routes = [
          _Route([me, d], straight, 0, const []),
        ];
        _error = _tr(
          'مسیر جاده‌ای دریافت نشد (اینترنت یا سرور مسیریابی). فاصله‌ی هوایی نمایش داده شد.',
          'Road route unavailable (network or routing server). Showing straight-line distance.',
          'تعذر الحصول على مسار الطريق. تم عرض المسافة الجوية.',
        );
      });
    } else {
      setState(() {
        _loading = false;
        _routes = found;
      });
    }
    _fitBounds();
  }

  Future<List<_Route>> _request(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      client.userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
      final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 10));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 12));
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(body);
      if (data is! Map || data['code'] != 'Ok' || data['routes'] is! List) return [];
      final out = <_Route>[];
      for (final r in (data['routes'] as List).take(3)) {
        if (r is! Map) continue;
        final g = r['geometry'];
        if (g is! Map || g['coordinates'] is! List) continue;
        final pts = <LatLng>[];
        for (final c in (g['coordinates'] as List)) {
          if (c is List && c.length >= 2) {
            final lon = double.tryParse('${c[0]}');
            final lat = double.tryParse('${c[1]}');
            if (lat != null && lon != null) pts.add(LatLng(lat, lon));
          }
        }
        if (pts.length < 2) continue;
        final steps = <_Step>[];
        final legs = r['legs'];
        if (legs is List) {
          for (final leg in legs) {
            final st = leg is Map ? leg['steps'] : null;
            if (st is! List) continue;
            for (final s in st) {
              if (s is! Map) continue;
              final m = s['maneuver'];
              if (m is! Map) continue;
              final loc = m['location'];
              LatLng at = pts.first;
              if (loc is List && loc.length >= 2) {
                at = LatLng(double.tryParse('${loc[1]}') ?? pts.first.latitude, double.tryParse('${loc[0]}') ?? pts.first.longitude);
              }
              steps.add(_Step(
                _maneuverText('${m['type'] ?? ''}', '${m['modifier'] ?? ''}', int.tryParse('${m['exit'] ?? ''}')),
                '${s['name'] ?? ''}',
                (s['distance'] as num?)?.toDouble() ?? 0,
                at,
              ));
            }
          }
        }
        out.add(_Route(
          pts,
          (r['distance'] as num?)?.toDouble() ?? 0,
          (r['duration'] as num?)?.toDouble() ?? 0,
          steps,
        ));
      }
      return out;
    } catch (_) {
      return [];
    } finally {
      client.close(force: true);
    }
  }

  String _maneuverText(String type, String mod, int? exit) {
    String dir(String fa, String en, String ar) => _tr(fa, en, ar);
    String side;
    switch (mod) {
      case 'left':
        side = dir('به چپ', 'left', 'يساراً');
        break;
      case 'right':
        side = dir('به راست', 'right', 'يميناً');
        break;
      case 'slight left':
        side = dir('کمی به چپ', 'slightly left', 'قليلاً يساراً');
        break;
      case 'slight right':
        side = dir('کمی به راست', 'slightly right', 'قليلاً يميناً');
        break;
      case 'sharp left':
        side = dir('تند به چپ', 'sharp left', 'حاداً يساراً');
        break;
      case 'sharp right':
        side = dir('تند به راست', 'sharp right', 'حاداً يميناً');
        break;
      case 'uturn':
        return dir('دور بزنید', 'Make a U-turn', 'قم بالالتفاف');
      default:
        side = '';
    }
    switch (type) {
      case 'depart':
        return dir('حرکت کنید', 'Start driving', 'ابدأ الحركة');
      case 'arrive':
        return dir('به مقصد رسیدید', 'You have arrived', 'وصلت إلى الوجهة');
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        return exit != null
            ? dir('وارد میدان شوید و از خروجی $exit خارج شوید', 'Enter the roundabout, take exit $exit', 'ادخل الدوار وخذ المخرج $exit')
            : dir('وارد میدان شوید', 'Enter the roundabout', 'ادخل الدوار');
      case 'merge':
        return dir('به مسیر اصلی بپیوندید', 'Merge', 'اندمج في الطريق');
      case 'on ramp':
        return dir('وارد رمپ شوید', 'Take the ramp', 'ادخل المنحدر');
      case 'off ramp':
        return dir('از رمپ خارج شوید', 'Take the exit ramp', 'اخرج من المنحدر');
      case 'fork':
        return side.isEmpty
            ? dir('در دوراهی ادامه دهید', 'Keep going at the fork', 'تابع عند التفرع')
            : dir('در دوراهی $side بروید', 'At the fork, keep $side', 'عند التفرع اتجه $side');
      case 'end of road':
        return side.isEmpty
            ? dir('در انتهای جاده بپیچید', 'Turn at the end of the road', 'انعطف في نهاية الطريق')
            : dir('در انتهای جاده $side بپیچید', 'At the end of the road, turn $side', 'في نهاية الطريق انعطف $side');
      case 'turn':
        return side.isEmpty
            ? dir('مستقیم ادامه دهید', 'Continue straight', 'استمر مباشرة')
            : dir('$side بپیچید', 'Turn $side', 'انعطف $side');
      default:
        return side.isEmpty
            ? dir('مستقیم ادامه دهید', 'Continue straight', 'استمر مباشرة')
            : dir('$side ادامه دهید', 'Continue $side', 'تابع $side');
    }
  }

  void _fitBounds() {
    final pts = <LatLng>[
      widget.destination,
      if (_me != null) _me!,
      if (_routes.isNotEmpty) ..._routes[_sel.clamp(0, _routes.length - 1)].points,
    ];
    if (pts.length < 2) return;
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
      ));
    } catch (_) {}
  }

  // ---------- قالب‌بندی ----------

  String _digits(String s) {
    if (_l == 'en') return s;
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final t = _l == 'fa' ? fa : ar;
    return s.replaceAllMapped(RegExp(r'\d'), (m) => t[int.parse(m[0]!)]);
  }

  String _fmtDist(double m) {
    if (m < 1000) return _digits('${m.round()} ${_tr('متر', 'm', 'م')}');
    final km = m / 1000;
    final v = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return _digits('$v ${_tr('کیلومتر', 'km', 'كم')}');
  }

  String _fmtDur(double sec) {
    final mins = (sec / 60).round();
    if (mins < 1) return _digits('< 1 ${_tr('دقیقه', 'min', 'د')}');
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return _digits('$m ${_tr('دقیقه', 'min', 'د')}');
    if (m == 0) return _digits('$h ${_tr('ساعت', 'h', 'س')}');
    return _digits('$h ${_tr('ساعت و', 'h', 'س و')} $m ${_tr('دقیقه', 'min', 'د')}');
  }

  String _fmtClock(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return _digits('$hh:$mm');
  }

  // ---------- باز کردن برنامه‌های بیرونی ----------

  Future<void> _open(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack(_tr('امکان باز کردن برنامه نبود.', 'Could not open the app.', 'تعذر فتح التطبيق.'));
    } catch (_) {
      if (mounted) _snack(_tr('امکان باز کردن برنامه نبود.', 'Could not open the app.', 'تعذر فتح التطبيق.'));
    }
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  String get _gmMode {
    switch (_mode) {
      case _Mode.car:
        return 'driving';
      case _Mode.bike:
        return 'bicycling';
      case _Mode.foot:
        return 'walking';
    }
  }

  void _openGoogle() {
    final d = widget.destination;
    final origin = _me != null ? '&origin=${_me!.latitude},${_me!.longitude}' : '';
    _open('https://www.google.com/maps/dir/?api=1$origin&destination=${d.latitude},${d.longitude}&travelmode=$_gmMode');
  }

  void _openWaze() {
    final d = widget.destination;
    _open('https://waze.com/ul?ll=${d.latitude},${d.longitude}&navigate=yes');
  }

  void _openGeo() {
    final d = widget.destination;
    _open('geo:${d.latitude},${d.longitude}?q=${d.latitude},${d.longitude}(${Uri.encodeComponent(widget.destinationName)})');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(
            _tr('مسیریابی هوشمند', 'Smart navigation', 'الملاحة الذكية'),
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          actions: [
            IconButton(
              tooltip: _tr('به‌روزرسانی موقعیت', 'Refresh location', 'تحديث الموقع'),
              onPressed: _locating || _loading ? null : _start,
              icon: const Icon(Icons.my_location_rounded, color: _gold),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(flex: 5, child: _mapView()),
            Expanded(flex: 6, child: _panel()),
          ],
        ),
      ),
    );
  }

  Widget _mapView() {
    final d = widget.destination;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: d, initialZoom: 13),
          children: [
            const ResilientTileLayer(maxZoom: 18),
            if (_routes.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (var i = 0; i < _routes.length; i++)
                    if (i != _sel)
                      Polyline(points: _routes[i].points, strokeWidth: 5, color: Colors.blueGrey.withValues(alpha: 0.7)),
                  Polyline(
                    points: _routes[_sel.clamp(0, _routes.length - 1)].points,
                    strokeWidth: 6,
                    color: const Color(0xff1fb58a),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(markers: [
              if (_me != null)
                Marker(
                  point: _me!,
                  width: 26,
                  height: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff2f80ed),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              Marker(
                point: d,
                width: 46,
                height: 46,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on_rounded, color: Color(0xffe5484d), size: 46),
              ),
            ]),
          ],
        ),
        if (_locating || _loading)
          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(color: _gold, backgroundColor: Colors.transparent)),
      ],
    );
  }

  Widget _panel() {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _modeBar(),
          const SizedBox(height: 10),
          if (_locating)
            _info(_tr('در حال دریافت موقعیت شما…', 'Getting your location…', 'جارٍ تحديد موقعك…'), loading: true)
          else if (_loading)
            _info(_tr('در حال محاسبه‌ی مسیر…', 'Calculating route…', 'جارٍ حساب المسار…'), loading: true),
          if (_error != null) _info(_error!, warn: true),
          if (_routes.isNotEmpty) ...[
            _routeChips(),
            const SizedBox(height: 10),
            _summary(_routes[_sel.clamp(0, _routes.length - 1)]),
            const SizedBox(height: 10),
            _stepsBox(_routes[_sel.clamp(0, _routes.length - 1)]),
          ],
          const SizedBox(height: 12),
          _externalButtons(),
        ],
      ),
    );
  }

  Widget _info(String text, {bool loading = false, bool warn = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? const Color(0x33ff8d85) : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warn ? const Color(0xffff8d85) : _gold.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        if (loading)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
        else
          Icon(warn ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded, color: warn ? const Color(0xffffb4a8) : _teal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.7))),
      ]),
    );
  }

  Widget _modeBar() {
    Widget chip(_Mode m, IconData icon, String label) {
      final on = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (_mode == m) return;
            setState(() => _mode = m);
            if (_me != null) _fetch();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: on ? _gold.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? _gold : Colors.white12, width: on ? 1.4 : 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: on ? _gold : Colors.white54, size: 19),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: on ? _goldBright : Colors.white60, fontSize: 12.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      chip(_Mode.car, Icons.directions_car_rounded, _tr('خودرو', 'Car', 'سيارة')),
      chip(_Mode.bike, Icons.directions_bike_rounded, _tr('دوچرخه', 'Bike', 'دراجة')),
      chip(_Mode.foot, Icons.directions_walk_rounded, _tr('پیاده', 'Walk', 'مشياً')),
    ]);
  }

  Widget _routeChips() {
    if (_routes.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _routes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = _routes[i];
          final on = i == _sel;
          return GestureDetector(
            onTap: () {
              setState(() => _sel = i);
              _fitBounds();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: on ? _teal.withValues(alpha: 0.15) : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? _teal : Colors.white12, width: on ? 1.5 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_tr('مسیر', 'Route', 'مسار')} ${_digits('${i + 1}')}${i == 0 ? ' • ${_tr('پیشنهادی', 'Best', 'الأفضل')}' : ''}',
                    style: TextStyle(color: on ? _teal : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text('${_fmtDist(r.meters)}  •  ${r.seconds > 0 ? _fmtDur(r.seconds) : '—'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _summary(_Route r) {
    final hasTime = r.seconds > 0;
    final arrive = _departAt.add(Duration(seconds: r.seconds.round()));
    Widget cell(IconData icon, String label, String value) {
      return Expanded(
        child: Column(children: [
          Icon(icon, color: _gold, size: 21),
          const SizedBox(height: 5),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_cardSoft, _card]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        cell(Icons.route_rounded, _tr('مسافت', 'Distance', 'المسافة'), _fmtDist(r.meters)),
        cell(Icons.timer_outlined, _tr('زمان سفر', 'Travel time', 'مدة الرحلة'), hasTime ? _fmtDur(r.seconds) : '—'),
        cell(Icons.play_circle_outline_rounded, _tr('ساعت حرکت', 'Depart', 'المغادرة'), _fmtClock(_departAt)),
        cell(Icons.flag_circle_outlined, _tr('ساعت رسیدن', 'Arrive', 'الوصول'), hasTime ? _fmtClock(arrive) : '—'),
      ]),
    );
  }

  Widget _stepsBox(_Route r) {
    if (r.steps.isEmpty) return const SizedBox.shrink();
    final shown = _stepsOpen ? r.steps : r.steps.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_tr('مراحل مسیر', 'Directions', 'خطوات المسار'),
            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final s in shown)
          InkWell(
            onTap: () => _map.move(s.location, 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.turn_right_rounded, color: _teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    if (s.road.isNotEmpty)
                      Text(s.road, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                  ]),
                ),
                Text(_fmtDist(s.meters), style: const TextStyle(color: _goldBright, fontSize: 11.5)),
              ]),
            ),
          ),
        if (r.steps.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _stepsOpen = !_stepsOpen),
              icon: Icon(_stepsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: _gold),
              label: Text(
                _stepsOpen
                    ? _tr('نمایش کمتر', 'Show less', 'عرض أقل')
                    : _tr('نمایش همه (${_digits('${r.steps.length}')})', 'Show all (${r.steps.length})', 'عرض الكل (${_digits('${r.steps.length}')})'),
                style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _externalButtons() {
    Widget btn(IconData icon, String label, VoidCallback onTap, {bool primary = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            height: 48,
            child: primary
                ? ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(icon, size: 19),
                    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: _bg,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onTap,
                    icon: Icon(icon, size: 18),
                    label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
          ),
        ),
      );
    }

    return Column(children: [
      Text(_tr('شروع مسیریابی صوتی در برنامه‌ی دیگر', 'Start turn-by-turn in another app', 'ابدأ الملاحة الصوتية في تطبيق آخر'),
          style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
      const SizedBox(height: 8),
      Row(children: [
        btn(Icons.navigation_rounded, 'Google Maps', _openGoogle, primary: true),
        btn(Icons.alt_route_rounded, 'Waze', _openWaze),
        btn(Icons.map_rounded, _tr('نقشه‌ی گوشی', 'Phone maps', 'خرائط الهاتف'), _openGeo),
      ]),
    ]);
  }
}
