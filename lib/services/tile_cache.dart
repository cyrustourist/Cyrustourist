// کش خودکار کاشی‌های نقشه روی حافظهٔ گوشی (بدون وابستگی جدید).
//
// ترتیب کار برای هر کاشی:
//   ۱) اگر در کش بود، فوراً از روی دیسک نمایش داده می‌شود (حتی بدون اینترنت)
//   ۲) اگر کش از «maxAge» قدیمی‌تر بود، همان لحظه نمایش داده می‌شود و در پس‌زمینه
//      با «درخواست شرطی» (If-None-Match / ETag، طبق سیاست OpenStreetMap) بررسی می‌شود:
//      اگر سرور 304 بدهد فقط تاریخ کش تمدید می‌شود (بدون دانلود دوباره)،
//      اگر 200 بدهد کاشی جدید جایگزین می‌شود و دفعهٔ بعد تازه دیده می‌شود
//   ۳) اگر در کش نبود، از اینترنت گرفته، ذخیره و نمایش داده می‌شود
// پوشهٔ کش همان پوشهٔ cache اپ است؛ سقف حجم حدود ۴۰۰ مگابایت و قدیمی‌ترین‌ها حذف می‌شوند.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

class TileDiskCache {
  TileDiskCache._();

  static const int maxBytes = 400 * 1024 * 1024;
  static const int trimTo = 300 * 1024 * 1024;
  static bool _trimScheduled = false;

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(seconds: 30)
    ..maxConnectionsPerHost = 8;

  static Directory dirFor(String layerId) =>
      Directory('${Directory.systemTemp.path}/tilecache/$layerId');

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
    try {
      final req = await _client.getUrl(Uri.parse(url));
      headers.forEach(req.headers.set);
      if (etag != null && etag.isNotEmpty) {
        req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      final res = await req.close().timeout(const Duration(seconds: 12));
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
      await for (final chunk in res.timeout(const Duration(seconds: 12))) {
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
      return null;
    }
  }

  /// یک بار در هر اجرا (با تأخیر) حجم کش را کنترل می‌کند
  static void scheduleTrim() {
    if (_trimScheduled) return;
    _trimScheduled = true;
    Timer(const Duration(seconds: 25), () async {
      try {
        final root = Directory('${Directory.systemTemp.path}/tilecache');
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
  }

  final String layerId;
  final Duration maxAge;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final file = File(
        '${TileDiskCache.dirFor(layerId).path}/${coordinates.z}_${coordinates.x}_${coordinates.y}.t');
    return _CachedTileImage(url, file, Map<String, String>.of(headers), maxAge);
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage(this.url, this.file, this.headers, this.maxAge);

  final String url;
  final File file;
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
    Uint8List? bytes;
    var stale = false;
    try {
      if (await key.file.exists()) {
        bytes = await key.file.readAsBytes();
        final age = DateTime.now().difference(await key.file.lastModified());
        stale = age > key.maxAge;
      }
    } catch (_) {
      bytes = null;
    }

    if (bytes != null && bytes.isNotEmpty) {
      try {
        final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        if (stale) {
          // نمایش فوری نسخهٔ قبلی؛ نسخهٔ تازه در پس‌زمینه جایگزین می‌شود
          final et = await TileDiskCache.readEtag(key.file);
          unawaited(TileDiskCache.download(key.url, key.headers, key.file, etag: et));
        }
        return codec;
      } catch (_) {
        try {
          await key.file.delete();
        } catch (_) {}
      }
    }

    final fresh = await TileDiskCache.download(key.url, key.headers, key.file);
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
