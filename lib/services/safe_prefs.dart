import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;

/// جایگزین SharedPreferences با همان نام و همان متدها.
///
/// روی بعضی گوشی‌ها SharedPreferences خطا می‌دهد یا false برمی‌گرداند و داده ذخیره نمی‌شود
/// (پروفایل، شناسهٔ کاربر، آخرین موقعیت، علاقه‌مندی‌ها...). این کلاس هر مقدار را در یک فایل
/// کوچک جدا (داخل پوشهٔ داده‌های اپ) نگه می‌دارد و همیشه در حافظه هم دارد؛ پس حتی اگر
/// SharedPreferences اصلی خراب باشد اپ درست کار می‌کند. داده‌های قدیمی SharedPreferences
/// در اولین اجرا خودکار منتقل می‌شوند.
///
/// برای استفاده فقط خط import در فایل‌ها عوض شده؛ بقیهٔ کد همان است.
class SharedPreferences {
  SharedPreferences._();

  static SharedPreferences? _inst;
  static Future<SharedPreferences>? _loading;

  /// آخرین خطای نوشتن روی فایل (برای نمایش در پیام‌های خطا)
  static String lastError = '';

  final Map<String, Object> _m = <String, Object>{};
  Directory? _dir;
  Future<void> _chain = Future<void>.value();

  static Future<SharedPreferences> getInstance() async {
    final i = _inst;
    if (i != null) return i;
    return _loading ??= _init();
  }

  static Future<SharedPreferences> _init() async {
    final s = SharedPreferences._();
    try {
      await s._load().timeout(const Duration(seconds: 6));
    } catch (e) {
      lastError = 'load:${e.runtimeType}';
    }
    if (s._dir == null) {
      // هنوز پوشهٔ ذخیره‌سازی آماده نبود (مثلاً پیش از آماده شدن پلاگین‌ها)؛ نمونهٔ موقت برمی‌گردد و دفعهٔ بعد دوباره تلاش می‌شود
      _loading = null;
      return s;
    }
    _inst = s;
    return s;
  }

  // ---------- فایل‌ها ----------
  static String _name(String key) {
    var h = 0xcbf29ce484222325;
    for (final c in utf8.encode(key)) {
      h ^= c;
      h = (h * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '${h.toRadixString(36)}.kv';
  }

  Future<Directory> _openDir() async {
    Directory base;
    try {
      base = await getApplicationSupportDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final d = Directory('${base.path}/prefs_v2');
    await d.create(recursive: true);
    return d;
  }

  Future<void> _load() async {
    final d = await _openDir();
    _dir = d;
    await for (final e in d.list(followLinks: false)) {
      if (e is! File || !e.path.endsWith('.kv')) continue;
      try {
        final j = jsonDecode(await e.readAsString());
        if (j is! Map) continue;
        final k = j['k'];
        final t = j['t'];
        final v = j['v'];
        if (k is! String) continue;
        switch (t) {
          case 's':
            if (v is String) _m[k] = v;
            break;
          case 'b':
            if (v is bool) _m[k] = v;
            break;
          case 'i':
            if (v is num) _m[k] = v.toInt();
            break;
          case 'd':
            if (v is num) _m[k] = v.toDouble();
            break;
          case 'l':
            if (v is List) _m[k] = v.map((x) => '$x').toList();
            break;
        }
      } catch (_) {}
    }
    await _migrateOld(d);
  }

  /// داده‌های قدیمی SharedPreferences اصلی (فقط یک‌بار، و فقط کلیدهایی که اینجا نیست)
  Future<void> _migrateOld(Directory d) async {
    final marker = File('${d.path}/.migrated');
    try {
      if (await marker.exists()) return;
      final real = await sp.SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      for (final k in real.getKeys()) {
        if (_m.containsKey(k)) continue;
        final v = real.get(k);
        if (v is String || v is bool || v is int || v is double) {
          _m[k] = v!;
          await _write(k);
        } else if (v is List) {
          _m[k] = v.map((x) => '$x').toList();
          await _write(k);
        }
      }
      await marker.writeAsString('1');
    } catch (_) {
      // SharedPreferences اصلی خراب است؛ چیزی برای انتقال نیست (دفعهٔ بعد دوباره تلاش می‌شود)
    }
  }

  Future<bool> _write(String key) {
    final c = Completer<bool>();
    _chain = _chain.then((_) async {
      try {
        final d = _dir;
        if (d == null) {
          c.complete(true); // فقط در حافظه
          return;
        }
        final v = _m[key];
        final f = File('${d.path}/${_name(key)}');
        if (v == null) {
          if (await f.exists()) await f.delete();
        } else {
          final t = v is String ? 's' : v is bool ? 'b' : v is int ? 'i' : v is double ? 'd' : 'l';
          final tmp = File('${f.path}.tmp');
          await tmp.writeAsString(jsonEncode({'k': key, 't': t, 'v': v}), flush: true);
          await tmp.rename(f.path);
        }
        c.complete(true);
      } catch (e) {
        lastError = 'write:${e.runtimeType}';
        c.complete(true); // مقدار در حافظهٔ اپ هست؛ خطا فقط در lastError
      }
    });
    return c.future;
  }

  // ---------- خواندن ----------
  Object? get(String key) => _m[key];
  String? getString(String key) {
    final v = _m[key];
    return v is String ? v : null;
  }

  bool? getBool(String key) {
    final v = _m[key];
    return v is bool ? v : null;
  }

  int? getInt(String key) {
    final v = _m[key];
    return v is int ? v : (v is double ? v.toInt() : null);
  }

  double? getDouble(String key) {
    final v = _m[key];
    return v is double ? v : (v is int ? v.toDouble() : null);
  }

  List<String>? getStringList(String key) {
    final v = _m[key];
    return v is List<String> ? List<String>.of(v) : null;
  }

  bool containsKey(String key) => _m.containsKey(key);
  Set<String> getKeys() => Set<String>.of(_m.keys);

  // ---------- نوشتن ----------
  Future<bool> setString(String key, String value) {
    _m[key] = value;
    return _write(key);
  }

  Future<bool> setBool(String key, bool value) {
    _m[key] = value;
    return _write(key);
  }

  Future<bool> setInt(String key, int value) {
    _m[key] = value;
    return _write(key);
  }

  Future<bool> setDouble(String key, double value) {
    _m[key] = value;
    return _write(key);
  }

  Future<bool> setStringList(String key, List<String> value) {
    _m[key] = List<String>.of(value);
    return _write(key);
  }

  Future<bool> remove(String key) {
    _m.remove(key);
    return _write(key);
  }

  Future<bool> clear() async {
    final keys = _m.keys.toList();
    _m.clear();
    for (final k in keys) {
      await _write(k);
    }
    return true;
  }

  Future<void> reload() async {}
}
