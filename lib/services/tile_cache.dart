// کش خودکار کاشی‌های نقشه روی حافظهٔ گوشی (بدون وابستگی جدید).
//
// ترتیب کار برای هر کاشی:
//   ۱) اگر در کش بود، فوراً از روی دیسک نمایش داده می‌شود (حتی بدون اینترنت)
//   ۲) اگر کش از «maxAge» قدیمی‌تر بود، همان لحظه نمایش داده می‌شود و در پس‌زمینه
//      با «درخواست شرطی» (If-None-Match / ETag، طبق سیاست OpenStreetMap) بررسی می‌شود:
//      اگر سرور 304 بدهد فقط تاریخ کش تمدید می‌شود (بدون دانلود دوباره)،
//      اگر 200 بدهد کاشی جدید جایگزین می‌شود و دفعهٔ بعد تازه دیده می‌شود
//   ۳) اگر در کش نبود، از اینترنت گرفته، ذخیره و نمایش داده می‌شود
// کش در پوشهٔ دائمی داده‌های اپ است (نه پوشهٔ cache که اندروید یا «پاک کردن کش» حذفش کند)؛
// سقف حجم حدود ۴۰۰ مگابایت و فقط قدیمی‌ترین‌ها حذف می‌شوند.
// وقتی اینترنت قطع است، به‌جای منتظر ماندن برای هر کاشی، چند ثانیه حالت «آفلاین» فعال می‌شود.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

import 'offline_tiles.dart';

class TileDiskCache {
  TileDiskCache._();

  static const int maxBytes = 400 * 1024 * 1024;
  static const int trimTo = 300 * 1024 * 1024;
  static bool _trimScheduled = false;

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..idleTimeout = const Duration(seconds: 30)
    ..maxConnectionsPerHost = 8;

  // ---------- پوشهٔ دائمی ----------
  static Directory? _root;
  static Future<void>? _initF;

  static Future<void> init() => _initF ??= _doInit();

  static Future<void> _doInit() async {
    try {
      final d = await getApplicationSupportDirectory();
      final r = Directory('${d.path}/tilecache');
      await r.create(recursive: true);
      _root = r;
    } catch (_) {
      _root = Directory('${Directory.systemTemp.path}/tilecache');
    }
  }

  static Future<File> fileFor(String layerId, int z, int x, int y) async {
    await init();
    return File('${_root!.path}/$layerId/${z}_${x}_$y.t');
  }

  // ---------- حالت آفلاین سریع ----------
  // چند خطای شبکه‌ی پیاپی = اینترنت نیست؛ ۲۰ ثانیه درخواست شبکه نمی‌فرستیم
  // تا کاشی‌های ذخیره‌شده بدون معطلی (۵ تا ۸ ثانیه برای هر کاشی) نمایش داده شوند.
  static int _fails = 0;
  static DateTime _downUntil = DateTime.fromMillisecondsSinceEpoch(0);
  static bool get isDown => DateTime.now().isBefore(_downUntil);

  static void _netOk() {
    _fails = 0;
    _downUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }

  static void _netBad() {
    if (++_fails >= 6) {
      _fails = 0;
      _downUntil = DateTime.now().add(const Duration(seconds: 20));
    }
  }

  /// دانلود یک کاشی؛ در صورت هر مشکلی null (هیچ‌وقت صفحهٔ خطا در کش ذخیره نمی‌شود)
  static File _etagFile(File file) => File('${file.path}.etag');

  static Future<String?> readEtag(File file) async {
    try {
      final f = _etagFile(file);
      if (await f.exists()) {
        final t = (await f.readAsString()).trim();
        return t.isEmpty ? null : t;
      }
    } catch (_) {}
    return null;
  }

  /// [etag] داده شود: درخواست شرطی؛ 304 یعنی بدون تغییر (تاریخ کش تمدید می‌شود و null برمی‌گردد)
  static Future<Uint8List?> download(
      String url, Map<String, String> headers, File file,
      {String? etag}) async {
    if (isDown) return null;
    try {
      final req = await _client.getUrl(Uri.parse(url));
      headers.forEach(req.headers.set);
      if (etag != null && etag.isNotEmpty) {
        req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      final res = await req.close().timeout(const Duration(seconds: 8));
      _netOk(); // سرور جواب داد = اینترنت هست
      if (res.statusCode == 304) {
        await res.drain<void>();
        try {
          await file.setLastModified(DateTime.now());
        } catch (_) {}
        return null;
      }
      if (res.statusCode != 200) {
        await res.drain<void>();
        return null;
      }
      final newEtag = res.headers.value(HttpHeaders.etagHeader);
      final ct = res.headers.contentType?.mimeType ?? '';
      if (ct.isNotEmpty && !ct.startsWith('image/')) {
        await res.drain<void>();
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in res.timeout(const Duration(seconds: 8))) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.length < 80) return null;
      try {
        await file.parent.create(recursive: true);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsBytes(bytes, flush: false);
        await tmp.rename(file.path);
        final ef = _etagFile(file);
        if (newEtag != null && newEtag.isNotEmpty) {
          await ef.writeAsString(newEtag);
        } else if (await ef.exists()) {
          await ef.delete();
        }
      } catch (_) {}
      return bytes;
    } catch (_) {
      _netBad();
      return null;
    }
  }

  /// یک بار در هر اجرا (با تأخیر) حجم کش را کنترل می‌کند
  static void scheduleTrim() {
    if (_trimScheduled) return;
    _trimScheduled = true;
    Timer(const Duration(seconds: 25), () async {
      try {
        await init();
        final root = _root!;
        if (!await root.exists()) return;
        final files = <File>[];
        var total = 0;
        await for (final e in root.list(recursive: true, followLinks: false)) {
          if (e is File) {
            files.add(e);
            total += await e.length();
          }
        }
        if (total <= maxBytes) return;
        final withTime = <MapEntry<File, DateTime>>[];
        for (final f in files) {
          withTime.add(MapEntry(f, await f.lastModified()));
        }
        withTime.sort((a, b) => a.value.compareTo(b.value));
        for (final e in withTime) {
          if (total <= trimTo) break;
          try {
            total -= await e.key.length();
            await e.key.delete();
          } catch (_) {}
        }
      } catch (_) {}
    });
  }
}

/// TileProvider با کش دیسکی (جایگزین NetworkTileProvider)
class CachedTileProvider extends TileProvider {
  CachedTileProvider({
    required this.layerId,
    required this.maxAge,
    String userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)',
  }) : super(headers: {'User-Agent': userAgent}) {
    TileDiskCache.scheduleTrim();
    OfflineTiles.init();
    TileDiskCache.init();
  }

  final String layerId;
  final Duration maxAge;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _CachedTileImage(url, layerId, coordinates.z, coordinates.x, coordinates.y,
        Map<String, String>.of(headers), maxAge);
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage(this.url, this.layerId, this.z, this.x, this.y, this.headers, this.maxAge);

  final String url;
  final String layerId;
  final int z, x, y;
  final Map<String, String> headers;
  final Duration maxAge;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_CachedTileImage>(this);

  @override
  ImageStreamCompleter loadImage(
      _CachedTileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: 1.0,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _load(_CachedTileImage key, ImageDecoderCallback decode) async {
    // ۱) نقشهٔ آفلاینِ دانلودشده (بدون اینترنت، بدون صفحهٔ سفید).
    //    قبلاً اگر پوشه هنوز آماده نشده بود این مرحله رد می‌شد؛ حالا صبر می‌کنیم تا آماده شود.
    if (key.layerId == 'osm' || key.layerId == 'carto') {
      try {
        final off = await OfflineTiles.fileForAsync(key.z, key.x, key.y);
        if (off != null && await off.exists()) {
          final ob = await off.readAsBytes();
          if (ob.isNotEmpty) {
            return await decode(await ui.ImmutableBuffer.fromUint8List(ob));
          }
        }
      } catch (_) {}
    }

    // ۲) کش دائمی (کاشی‌هایی که قبلاً دیده شده‌اند؛ برای همهٔ لایه‌ها)
    final file = await TileDiskCache.fileFor(key.layerId, key.z, key.x, key.y);
    Uint8List? bytes;
    var stale = false;
    try {
      if (await file.exists()) {
        bytes = await file.readAsBytes();
        final age = DateTime.now().difference(await file.lastModified());
        stale = age > key.maxAge;
      }
    } catch (_) {
      bytes = null;
    }

    // اگر کش همین لایه خالی بود، کش لایهٔ هم‌خانواده (osm ↔ carto) را امتحان می‌کنیم؛
    // وقتی اینترنت قطع است و برنامه از OSM به CARTO سوئیچ کرده، کاشی‌های قبلاً دیده‌شده خالی نمانند.
    if ((bytes == null || bytes.isEmpty) && TileDiskCache.isDown &&
        (key.layerId == 'osm' || key.layerId == 'carto')) {
      try {
        final other = key.layerId == 'osm' ? 'carto' : 'osm';
        final of = await TileDiskCache.fileFor(other, key.z, key.x, key.y);
        if (await of.exists()) {
          final ob = await of.readAsBytes();
          if (ob.isNotEmpty) {
            return await decode(await ui.ImmutableBuffer.fromUint8List(ob));
          }
        }
      } catch (_) {}
    }

    if (bytes != null && bytes.isNotEmpty) {
      try {
        final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        if (stale && !TileDiskCache.isDown) {
          // نمایش فوری نسخهٔ قبلی؛ نسخهٔ تازه در پس‌زمینه جایگزین می‌شود
          final et = await TileDiskCache.readEtag(file);
          unawaited(TileDiskCache.download(key.url, key.headers, file, etag: et));
        }
        return codec;
      } catch (_) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    // ۳) اینترنت
    final fresh = await TileDiskCache.download(key.url, key.headers, file);
    if (fresh == null) {
      throw StateError('tile unavailable: ${key.url}');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(fresh));
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
