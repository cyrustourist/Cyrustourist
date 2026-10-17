import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/carto_config.dart';

/// پیشرفت دانلود نقشهٔ آفلاین
class OfflineProgress {
  const OfflineProgress(this.done, this.total, {this.finished = false, this.failed = false});

  final int done;
  final int total;
  final bool finished;
  final bool failed;
}

/// نقشهٔ آفلاین دانلودی: کاربر یک محدوده را یک‌بار دانلود می‌کند و بعد بدون آنتن هم نمایش داده می‌شود.
/// کاشی‌ها در پوشهٔ دائمی داده‌های اپ ذخیره می‌شوند (نه پوشهٔ کش که سیستم یا اپ پاکش کند).
/// ترتیب نمایش هر کاشی: ۱) دانلود آفلاین  ۲) کش خودکار  ۳) OpenStreetMap  ۴) CARTO
class OfflineTiles {
  OfflineTiles._();

  /// سقف تعداد کاشی در هر دانلود (حدود ۷۰ مگابایت)؛ برای احترام به سرویس نقشه و حجم گوشی
  static const int maxTilesPerDownload = 4000;
  static const int approxTileBytes = 18 * 1024;

  static Directory? _root;
  static Future<void>? _initF;

  static Future<void> init() => _initF ??= _doInit();

  static Future<void> _doInit() async {
    try {
      final d = await getApplicationSupportDirectory();
      final r = Directory('${d.path}/offline_tiles');
      await r.create(recursive: true);
      _root = r;
    } catch (_) {
      _root = null;
      _initF = null; // دفعهٔ بعد دوباره تلاش شود
    }
  }

  /// فایل کاشی (بدون بررسی وجود)؛ null اگر هنوز آماده نیست
  static File? fileFor(int z, int x, int y) {
    final r = _root;
    if (r == null) return null;
    return File('${r.path}/$z/${x}_$y.t');
  }

  static final ValueNotifier<OfflineProgress?> progress = ValueNotifier<OfflineProgress?>(null);
  static bool _cancel = false;
  static bool get running => progress.value != null && !(progress.value!.finished || progress.value!.failed);

  static void cancel() => _cancel = true;

  // ---------- محاسبهٔ کاشی‌ها ----------
  static int _tx(double lon, int z) {
    final n = 1 << z;
    return (((lon + 180) / 360) * n).floor().clamp(0, n - 1);
  }

  static int _ty(double lat, int z) {
    final n = 1 << z;
    final l = lat.clamp(-85.0511, 85.0511) * math.pi / 180;
    final v = (1 - math.log(math.tan(l) + 1 / math.cos(l)) / math.pi) / 2 * n;
    return v.floor().clamp(0, n - 1);
  }

  static int count(double south, double west, double north, double east, int z0, int z1) {
    var total = 0;
    for (var z = z0; z <= z1; z++) {
      final x0 = _tx(west, z), x1 = _tx(east, z);
      final y0 = _ty(north, z), y1 = _ty(south, z);
      total += (x1 - x0 + 1) * (y1 - y0 + 1);
    }
    return total;
  }

  /// حجم فعلی نقشه‌های دانلودشده (بایت)
  static Future<int> usedBytes() async {
    await init();
    final r = _root;
    if (r == null || !await r.exists()) return 0;
    var total = 0;
    try {
      await for (final e in r.list(recursive: true, followLinks: false)) {
        if (e is File) total += await e.length();
      }
    } catch (_) {}
    return total;
  }

  static Future<void> clearAll() async {
    await init();
    final r = _root;
    if (r == null) return;
    try {
      if (await r.exists()) await r.delete(recursive: true);
      await r.create(recursive: true);
    } catch (_) {}
  }

  // ---------- دانلود ----------
  static Future<bool> download({
    required double south,
    required double west,
    required double north,
    required double east,
    required int z0,
    required int z1,
  }) async {
    if (running) return false;
    progress.value = const OfflineProgress(0, 0); // دیالوگ پیشرفت بلافاصله باز بماند
    await init();
    final root = _root;
    if (root == null) {
      progress.value = null;
      return false;
    }

    final todo = <List<int>>[];
    for (var z = z0; z <= z1; z++) {
      final x0 = _tx(west, z), x1 = _tx(east, z);
      final y0 = _ty(north, z), y1 = _ty(south, z);
      for (var x = x0; x <= x1; x++) {
        for (var y = y0; y <= y1; y++) {
          final f = fileFor(z, x, y)!;
          if (!await f.exists()) todo.add([z, x, y]);
        }
      }
    }

    _cancel = false;
    final total = todo.length;
    var done = 0;
    var consecutiveFails = 0;
    var aborted = false;
    progress.value = OfflineProgress(0, total);

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
    var next = 0;

    Future<void> worker() async {
      while (!_cancel && !aborted) {
        if (next >= todo.length) return;
        final t = todo[next++];
        final f = fileFor(t[0], t[1], t[2])!;
        var ok = false;
        try {
          final url = CartoConfig.tileUrlWithKey
              .replaceAll('{z}', '${t[0]}')
              .replaceAll('{x}', '${t[1]}')
              .replaceAll('{y}', '${t[2]}');
          final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
          final res = await req.close().timeout(const Duration(seconds: 8));
          final ct = res.headers.contentType?.mimeType ?? '';
          if (res.statusCode == 200 && ct.startsWith('image/')) {
            final b = BytesBuilder(copy: false);
            await for (final c in res.timeout(const Duration(seconds: 8))) {
              b.add(c);
            }
            final bytes = b.takeBytes();
            if (bytes.length > 80) {
              await f.parent.create(recursive: true);
              final tmp = File('${f.path}.tmp');
              await tmp.writeAsBytes(bytes, flush: false);
              await tmp.rename(f.path);
              ok = true;
            }
          } else {
            await res.drain<void>();
          }
        } catch (_) {}
        if (ok) {
          consecutiveFails = 0;
        } else if (++consecutiveFails >= 40) {
          aborted = true; // اینترنت/سرویس در دسترس نیست
        }
        done++;
        progress.value = OfflineProgress(done, total);
      }
    }

    try {
      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    } finally {
      client.close(force: true);
    }

    final okAll = !aborted && !_cancel;
    progress.value = OfflineProgress(done, total, finished: okAll, failed: !okAll);
    Timer(const Duration(seconds: 2), () => progress.value = null);
    return okAll;
  }
}
