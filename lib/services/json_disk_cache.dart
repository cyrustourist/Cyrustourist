import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// کش خودکار نتایج نقشه (جستجو و مکان‌های اطراف) روی حافظهٔ گوشی.
/// ترتیب استفاده در اپ: ۱) همین کش (فوری، حتی بدون اینترنت)  ۲) OpenStreetMap.
/// فقط متن پاسخ را نگه می‌دارد؛ پوشهٔ کش همان پوشهٔ cache اپ است (مثل کاشی‌های نقشه).
class DiskHit {
  const DiskHit(this.body, this.time);

  final String body;
  final DateTime time;

  Duration get age => DateTime.now().difference(time);
}

class JsonDiskCache {
  JsonDiskCache._();

  static const int maxFiles = 400;
  static bool _trimScheduled = false;

  static Directory get _dir => Directory('${Directory.systemTemp.path}/placecache');

  static String _name(String key) {
    // نام فایل امن + یکتا (FNV-1a روی کل کلید)
    var h = 0xcbf29ce484222325;
    for (final c in utf8.encode(key)) {
      h ^= c;
      h = (h * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return h.toRadixString(36);
  }

  static Future<DiskHit?> read(String key) async {
    try {
      final f = File('${_dir.path}/${_name(key)}.json');
      if (!await f.exists()) return null;
      final j = jsonDecode(await f.readAsString());
      if (j is! Map || j['k'] != key || j['b'] is! String) return null;
      return DiskHit(j['b'] as String, DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, String body) async {
    try {
      await _dir.create(recursive: true);
      final f = File('${_dir.path}/${_name(key)}.json');
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode({'k': key, 't': DateTime.now().millisecondsSinceEpoch, 'b': body}), flush: false);
      await tmp.rename(f.path);
      _scheduleTrim();
    } catch (_) {}
  }

  static void _scheduleTrim() {
    if (_trimScheduled) return;
    _trimScheduled = true;
    Timer(const Duration(seconds: 30), () async {
      _trimScheduled = false;
      try {
        final files = <File>[];
        await for (final e in _dir.list(followLinks: false)) {
          if (e is File && e.path.endsWith('.json')) files.add(e);
        }
        if (files.length <= maxFiles) return;
        final withTime = <MapEntry<File, DateTime>>[];
        for (final f in files) {
          withTime.add(MapEntry(f, await f.lastModified()));
        }
        withTime.sort((a, b) => a.value.compareTo(b.value));
        for (var i = 0; i < withTime.length - maxFiles; i++) {
          try {
            await withTime[i].key.delete();
          } catch (_) {}
        }
      } catch (_) {}
    });
  }
}
