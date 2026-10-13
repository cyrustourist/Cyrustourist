import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/language/menu_translations.dart';
import '../widgets/resilient_tile_layer.dart';

const Color _bg = Color(0xff0b1a24);
const Color _bar = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _red = Color(0xffe5484d);

/// حداقل زوم لازم برای ثبت مسیریابی دقیق (حدود سطح خیابان/ساختمان)
const double kPickMinZoom = 17;
const double _maxZoom = 19;

/// نتیجهٔ انتخاب موقعیت از روی نقشه
class PickedLocation {
  const PickedLocation({required this.lat, required this.lng, required this.zoom, required this.address, this.state = '', this.city = ''});
  final double lat;
  final double lng;
  final double zoom;
  final String address;

  /// نام استان و شهر خام از سرویس نقشه (برای پر کردن خودکار فرم)
  final String state;
  final String city;
}

const Map<String, Map<String, String>> _tx = {
  'fa': {
    'title': 'انتخاب موقعیت روی نقشه',
    'search': 'جستجوی آدرس، محله یا مکان…',
    'tip': 'برای ثبت مسیریابی دقیق، تا بیشترین حد زوم کنید و نقطهٔ قرمز را روی ورودی ساختمان بگذارید.',
    'addr': 'آدرس (قابل ویرایش)',
    'zoom': 'زوم',
    'zoomNeed': 'نزدیک‌تر زوم کنید تا تأیید فعال شود',
    'confirm': 'تأیید موقعیت',
    'zoomIn': 'رفتن به دقیق‌ترین حالت',
    'loading': 'در حال یافتن آدرس…',
    'noRes': 'نتیجه‌ای پیدا نشد',
    'gps': 'موقعیت من',
    'gpsOff': 'دسترسی به موقعیت مکانی ممکن نشد.',
    'netErr': 'ارتباط با سرویس نقشه برقرار نشد.',
    'layerSwitch': 'لایهٔ نقشه عوض شد',
    'layerBtn': 'تغییر لایهٔ نقشه',
  },
  'en': {
    'title': 'Pick location on map',
    'search': 'Search address, district or place…',
    'tip': 'For accurate routing, zoom in to the maximum and place the red pin on the building entrance.',
    'addr': 'Address (editable)',
    'zoom': 'Zoom',
    'zoomNeed': 'Zoom in closer to enable confirm',
    'confirm': 'Confirm location',
    'zoomIn': 'Zoom to most precise',
    'loading': 'Finding address…',
    'noRes': 'No results',
    'gps': 'My location',
    'gpsOff': 'Could not access your location.',
    'netErr': 'Could not reach the map service.',
    'layerSwitch': 'Map layer changed',
    'layerBtn': 'Switch map layer',
  },
  'ar': {
    'title': 'اختيار الموقع على الخريطة',
    'search': 'ابحث عن عنوان أو حي أو مكان…',
    'tip': 'لتوجيه دقيق، قرّب إلى أقصى حد وضع الدبوس الأحمر على مدخل المبنى.',
    'addr': 'العنوان (قابل للتعديل)',
    'zoom': 'التكبير',
    'zoomNeed': 'قرّب أكثر لتفعيل التأكيد',
    'confirm': 'تأكيد الموقع',
    'zoomIn': 'الانتقال إلى أدق مستوى',
    'loading': 'جارٍ إيجاد العنوان…',
    'noRes': 'لا توجد نتائج',
    'gps': 'موقعي',
    'gpsOff': 'تعذر الوصول إلى موقعك.',
    'netErr': 'تعذر الاتصال بخدمة الخرائط.',
    'layerSwitch': 'تم تغيير طبقة الخريطة',
    'layerBtn': 'تغيير طبقة الخريطة',
  },
};

String _t(String k) {
  final m = _tx[MenuLanguage.current] ?? _tx['en']!;
  return m[k] ?? _tx['en']![k] ?? k;
}

class _Hit {
  _Hit(this.title, this.sub, this.lat, this.lng);
  final String title;
  final String sub;
  final double lat;
  final double lng;
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial, this.initialZoom, this.initialAddress = ''});

  final LatLng? initial;
  final double? initialZoom;
  final String initialAddress;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _iran = LatLng(32.4279, 53.6880);

  final MapController _map = MapController();
  final TextEditingController _q = TextEditingController();
  final TextEditingController _addr = TextEditingController();
  final FocusNode _qFocus = FocusNode();

  late LatLng _center;
  late double _zoom;
  List<_Hit> _hits = [];
  bool _searching = false;
  bool _noRes = false;
  bool _geoBusy = false;
  String _state = '';
  String _city = '';
  Timer? _searchDeb;
  Timer? _revDeb;
  int _searchSeq = 0;
  int _revSeq = 0;
  bool _addrTouched = false;

  // لایهٔ نقشه از ResilientTileLayer می‌آید (استاندارد / عوارض / ماهواره / ماهواره+نام‌ها + کش دیسکی)
  Widget _tileLayer() => const ResilientTileLayer(maxZoom: _maxZoom);

  /// مکان‌نمای سریع: آخرین موقعیت شناخته‌شده فوراً (بدون پرسیدن مجوز و بدون انتظار GPS)
  Future<void> _quickLocate() async {
    if (widget.initial != null) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final last = await Geolocator.getLastKnownPosition();
      if (last == null || !mounted) return;
      _addrTouched = false;
      _map.move(LatLng(last.latitude, last.longitude), 15);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _iran;
    _zoom = widget.initialZoom ?? (widget.initial == null ? 5.2 : 17);
    _addr.text = widget.initialAddress;
    _addrTouched = widget.initialAddress.trim().isNotEmpty;
    _addr.addListener(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _quickLocate());
  }

  @override
  void dispose() {
    _searchDeb?.cancel();
    _revDeb?.cancel();
    _q.dispose();
    _addr.dispose();
    _qFocus.dispose();
    super.dispose();
  }

  // ---------- شبکه (Nominatim / OpenStreetMap) ----------

  Future<dynamic> _get(Uri uri) async {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      c.userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
      final req = await c.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(await res.transform(utf8.decoder).join());
    } catch (_) {
      return null;
    } finally {
      c.close(force: true);
    }
  }

  String _lang() => MenuLanguage.current == 'ar' ? 'ar' : (MenuLanguage.current == 'en' ? 'en' : 'fa');

  void _onQuery(String v) {
    _searchDeb?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _hits = [];
        _noRes = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDeb = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_searchSeq;
    final j = await _get(Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'limit': '8',
      'addressdetails': '1',
      'countrycodes': 'ir',
      'accept-language': _lang(),
    }));
    if (!mounted || seq != _searchSeq) return;
    final hits = <_Hit>[];
    if (j is List) {
      for (final e in j) {
        if (e is! Map) continue;
        final lat = double.tryParse('${e['lat']}');
        final lng = double.tryParse('${e['lon']}');
        if (lat == null || lng == null) continue;
        final name = '${e['name'] ?? ''}'.trim();
        final disp = '${e['display_name'] ?? ''}';
        final parts = disp.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
        final title = name.isNotEmpty ? name : (parts.isNotEmpty ? parts.first : disp);
        final sub = parts.skip(name.isNotEmpty ? 1 : 1).take(3).join('، ');
        hits.add(_Hit(title, sub, lat, lng));
      }
    }
    setState(() {
      _hits = hits;
      _searching = false;
      _noRes = j != null && hits.isEmpty;
    });
  }

  void _pickHit(_Hit h) {
    _qFocus.unfocus();
    setState(() {
      _hits = [];
      _q.text = h.title;
      _addrTouched = false;
    });
    _map.move(LatLng(h.lat, h.lng), kPickMinZoom);
  }

  void _scheduleReverse() {
    _revDeb?.cancel();
    _revDeb = Timer(const Duration(milliseconds: 700), _reverse);
  }

  Future<void> _reverse() async {
    if (_zoom < 14) return;
    final seq = ++_revSeq;
    final p = _center;
    final j = await _get(Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': p.latitude.toStringAsFixed(6),
      'lon': p.longitude.toStringAsFixed(6),
      'format': 'jsonv2',
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': _lang(),
    }));
    if (!mounted || seq != _revSeq || j is! Map) return;
    final a = j['address'] is Map ? Map<String, dynamic>.from(j['address'] as Map) : <String, dynamic>{};
    String g(List<String> ks) {
      for (final k in ks) {
        final v = '${a[k] ?? ''}'.trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final road = g(['road', 'pedestrian', 'footway', 'residential']);
    final house = g(['house_number']);
    final hood = g(['neighbourhood', 'suburb', 'quarter', 'city_district']);
    final city = g(['city', 'town', 'village', 'municipality', 'county']);
    final state = g(['state', 'province']);
    final built = [state, city, hood, road, house].where((x) => x.isNotEmpty).toList();
    var text = built.join('، ');
    if (text.isEmpty) {
      text = '${j['display_name'] ?? ''}'.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).take(5).join('، ');
    }
    setState(() {
      _state = state;
      _city = city;
      if (!_addrTouched) _addr.text = text;
    });
  }

  Future<void> _gps() async {
    if (_geoBusy) return;
    setState(() => _geoBusy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw Exception('perm');
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)));
      _addrTouched = false;
      _map.move(LatLng(pos.latitude, pos.longitude), kPickMinZoom + 1);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('gpsOff'))));
    } finally {
      if (mounted) setState(() => _geoBusy = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(PickedLocation(
      lat: _center.latitude,
      lng: _center.longitude,
      zoom: _zoom,
      address: _addr.text.trim(),
      state: _state,
      city: _city,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ok = _zoom >= kPickMinZoom;
    final prog = ((_zoom - 4) / (_maxZoom - 4)).clamp(0.0, 1.0);
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: _zoom,
                minZoom: 4,
                maxZoom: _maxZoom,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                // با یک ضربه روی نقشه، آن نقطه زیر سنجاق قرمز می‌آید (طول و عرض همان نقطه ثبت می‌شود)
                onTap: (tapPos, point) {
                  _addrTouched = false;
                  _map.move(point, _zoom);
                },
                onPositionChanged: (cam, hasGesture) {
                  final z = cam.zoom;
                  final c = cam.center;
                  if ((z - _zoom).abs() > 0.01 || c != _center) {
                    setState(() {
                      _zoom = z;
                      _center = c;
                    });
                    if (hasGesture) _addrTouched = false;
                    _scheduleReverse();
                  }
                },
              ),
              children: [
                _tileLayer(),
              ],
            ),
          ),
          // سنجاق ثابت وسط نقشه (مثل دیوار): نقشه حرکت می‌کند، سنجاق ثابت است
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 46),
                child: Icon(Icons.location_on_rounded, color: ok ? _red : const Color(0xffff9aa0), size: 52, shadows: const [Shadow(color: Colors.black45, blurRadius: 8)]),
              ),
            ),
          ),
          // نوار جستجو
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: _bar,
                  child: Row(children: [
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        focusNode: _qFocus,
                        onChanged: _onQuery,
                        style: const TextStyle(color: Colors.white, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: _t('search'),
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searching)
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)))
                    else if (_q.text.isNotEmpty)
                      IconButton(
                        onPressed: () => setState(() {
                          _q.clear();
                          _hits = [];
                          _noRes = false;
                        }),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      )
                    else
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search_rounded, color: _gold)),
                  ]),
                ),
                if (_hits.isNotEmpty || _noRes)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(color: _bar, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)]),
                    child: _noRes
                        ? Padding(padding: const EdgeInsets.all(16), child: Text(_t('noRes'), style: const TextStyle(color: Colors.white60)))
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _hits.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                            itemBuilder: (_, i) {
                              final h = _hits[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined, color: _gold),
                                title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                subtitle: Text(h.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                                onTap: () => _pickHit(h),
                              );
                            },
                          ),
                  ),
              ]),
            ),
          ),
          // دکمه‌های کنار نقشه
          PositionedDirectional(
            end: 12,
            bottom: 292,
            child: Column(children: [
              _fab(Icons.add_rounded, () => _map.move(_center, (_zoom + 1).clamp(4, _maxZoom).toDouble())),
              const SizedBox(height: 8),
              _fab(Icons.remove_rounded, () => _map.move(_center, (_zoom - 1).clamp(4, _maxZoom).toDouble())),
              const SizedBox(height: 8),
              _fab(_geoBusy ? Icons.hourglass_top_rounded : Icons.my_location_rounded, _gps, tooltip: _t('gps')),
              const SizedBox(height: 8),
              _fab(Icons.layers_rounded, () => showMapLayerSheet(context), tooltip: _t('layerBtn')),
            ]),
          ),
          // کارت پایین
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: _bar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
              ),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    const Icon(Icons.zoom_in_map_rounded, color: _gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_t('tip'), style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.7))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('${_t('zoom')} ${_zoom.toStringAsFixed(1)}', style: TextStyle(color: ok ? _teal : _gold, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: prog, minHeight: 6, backgroundColor: Colors.white12, color: ok ? _teal : _gold),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addr,
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) => _addrTouched = true,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: _t('addr'),
                      labelStyle: const TextStyle(color: Colors.white54),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gold.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: ok ? _confirm : () => _map.move(_center, kPickMinZoom + 1),
                      icon: Icon(ok ? Icons.check_circle_rounded : Icons.zoom_in_rounded),
                      label: Text(ok ? _t('confirm') : '${_t('zoomNeed')} — ${_t('zoomIn')}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ok ? _teal : const Color(0xff2a4658),
                        foregroundColor: ok ? const Color(0xff06121d) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fab(IconData i, VoidCallback f, {String? tooltip}) {
    return Material(
      color: _bar,
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(onPressed: f, tooltip: tooltip, icon: Icon(i, color: _gold)),
    );
  }
}
