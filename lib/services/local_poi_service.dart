import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import '../pages/map/map_places_service.dart';

/// پایگاه آفلاین مکان‌ها (جاذبه‌ها، اقامتگاه‌ها، مراکز سلامت) داخل خود اپ.
///
/// فایل assets/poi/iran_poi.bin را workflow «Build offline places database» از
/// OpenStreetMap می‌سازد. جستجو کاملاً روی گوشی انجام می‌شود (بدون اینترنت و بدون سرور).
/// اگر فایل خالی/ناموجود باشد، [search] مقدار null می‌دهد و برنامه به اینترنت برمی‌گردد.
class LocalPoiService {
  LocalPoiService._();
  static final LocalPoiService instance = LocalPoiService._();

  static const String _asset = 'assets/poi/iran_poi.bin';
  static const double _cell = 0.1; // درجه (حدود ۱۱ کیلومتر)

  Future<_PoiData?>? _loading;

  /// نوع‌هایی که در پایگاه آفلاین پوشش داده می‌شوند.
  static bool covers(MapPlaceType t) =>
      t == MapPlaceType.touristAttraction ||
      t == MapPlaceType.accommodation ||
      t == MapPlaceType.healthTourism ||
      t == MapPlaceType.historicalSite;

  /// بارگذاری پیش‌هنگام (اختیاری)؛ بدون خطا.
  Future<void> warmUp() async {
    try {
      await _data();
    } catch (_) {}
  }

  Future<_PoiData?> _data() {
    return _loading ??= _load();
  }

  Future<_PoiData?> _load() async {
    try {
      final bd = await rootBundle.load(_asset);
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      final rows = await compute(_decode, bytes);
      if (rows.isEmpty) return null;
      return _PoiData(rows);
    } catch (e) {
      debugPrint('LocalPoiService: ${e.runtimeType}');
      return null;
    }
  }

  /// null = پایگاه آفلاین در دسترس نیست (برنامه باید از اینترنت استفاده کند).
  Future<List<MapPlace>?> search({
    required LatLng center,
    required double radiusMeters,
    required MapPlaceType type,
    required List<String> tags,
    int limit = 200,
  }) async {
    if (!covers(type)) return null;
    final d = await _data();
    if (d == null) return null;
    return d.search(center, radiusMeters, type, tags, limit);
  }
}

List<List<dynamic>> _decode(Uint8List gz) {
  final text = utf8.decode(GZipCodec().decode(gz));
  final j = jsonDecode(text);
  if (j is! List) return const [];
  return [for (final r in j) if (r is List && r.length >= 8) r];
}

class _PoiData {
  _PoiData(this.rows) {
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final lat = (r[0] as num).toDouble();
      final lon = (r[1] as num).toDouble();
      _grid.putIfAbsent(_key(_ci(lat), _ci(lon)), () => <int>[]).add(i);
    }
  }

  final List<List<dynamic>> rows;
  final Map<int, List<int>> _grid = {};

  static int _ci(double v) => (v / LocalPoiService._cell).floor();
  static int _key(int la, int lo) => la * 100000 + lo;

  List<MapPlace> search(LatLng c, double radius, MapPlaceType type, List<String> tags, int limit) {
    final exact = <String>{};
    final bare = <String>{};
    for (final t in tags) {
      if (t.contains('=')) {
        exact.add(t);
      } else {
        bare.add(t);
      }
    }
    final dLat = radius / 111320.0;
    final dLon = radius / (111320.0 * math.max(0.2, math.cos(c.latitude * math.pi / 180)));
    final la0 = _ci(c.latitude - dLat), la1 = _ci(c.latitude + dLat);
    final lo0 = _ci(c.longitude - dLon), lo1 = _ci(c.longitude + dLon);

    final hits = <(double, int)>[];
    for (var la = la0; la <= la1; la++) {
      for (var lo = lo0; lo <= lo1; lo++) {
        final list = _grid[_key(la, lo)];
        if (list == null) continue;
        for (final i in list) {
          final r = rows[i];
          final kinds = (r[2] as String).split(';');
          var ok = false;
          for (final k in kinds) {
            if (exact.contains(k) || bare.contains(k.split('=').first)) {
              ok = true;
              break;
            }
          }
          if (!ok) continue;
          final lat = (r[0] as num).toDouble();
          final lon = (r[1] as num).toDouble();
          final dy = (lat - c.latitude) * 111320.0;
          final dx = (lon - c.longitude) * 111320.0 * math.cos(c.latitude * math.pi / 180);
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist <= radius) hits.add((dist, i));
        }
      }
    }
    hits.sort((a, b) => a.$1.compareTo(b.$1));

    final out = <MapPlace>[];
    for (final h in hits.take(limit)) {
      final r = rows[h.$2];
      final tagMap = <String, String>{};
      for (final k in (r[2] as String).split(';')) {
        final p = k.indexOf('=');
        if (p > 0) tagMap[k.substring(0, p)] = k.substring(p + 1);
      }
      final name = '${r[3]}';
      tagMap['name'] = name;
      if ('${r[4]}'.isNotEmpty) tagMap['name:en'] = '${r[4]}';
      if ('${r[5]}'.isNotEmpty) tagMap['phone'] = '${r[5]}';
      if ('${r[6]}'.isNotEmpty) tagMap['website'] = '${r[6]}';
      final oid = '${r[7]}';
      final prefix = oid.isNotEmpty ? oid[0] : 'n';
      final osmType = prefix == 'w' ? 'way' : (prefix == 'r' ? 'relation' : 'node');
      final osmId = oid.length > 1 ? oid.substring(1) : '${h.$2}';
      out.add(MapPlace(
        id: '$osmType:$osmId',
        name: name,
        point: LatLng((r[0] as num).toDouble(), (r[1] as num).toDouble()),
        type: type,
        tags: tagMap,
        osmType: osmType,
        osmId: osmId,
      ));
    }
    return out;
  }
}
