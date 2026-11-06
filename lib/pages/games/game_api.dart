import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/badge_service.dart';

/// فراخوانی‌های /api/game/* (از همان مسیر امن BadgeService با X-Cyrus-Token).
class GameApi {
  GameApi._();

  static Future<Map<String, dynamic>?> get(String path, [Map<String, String>? q]) async {
    final uid = await BadgeService.userUid();
    return BadgeService.call(
      'GET',
      path,
      query: <String, String>{'user_uid': uid, ...?q},
      timeout: const Duration(seconds: 8),
    );
  }

  static Future<Map<String, dynamic>?> post(String path, [Map<String, dynamic>? b]) async {
    final uid = await BadgeService.userUid();
    return BadgeService.call(
      'POST',
      path,
      body: <String, dynamic>{'user_uid': uid, ...?b},
      timeout: const Duration(seconds: 8),
    );
  }
}

const Map<String, String> kGameIconEmoji = {
  'lion': '🦁',
  'camel': '🐪',
  'deer': '🦌',
  'boat': '⛵',
  'eagle': '🦅',
};

/// کیف سکه و سطح. منبع اصلی سرور است؛ آخرین نسخه برای نمایش آفلاین ذخیره می‌شود.
/// نتیجه‌ی بازی‌های آفلاین در صف می‌ماند و وقتی اینترنت بود (با سقف روزانه‌ی سرور) ثبت می‌شود.
class GameWallet extends ChangeNotifier {
  GameWallet._();
  static final GameWallet instance = GameWallet._();

  static const String _cacheKey = 'cyrus_game_wallet_v1';
  static const String _queueKey = 'cyrus_game_queue_v1';

  Map<String, dynamic> data = <String, dynamic>{};

  /// '' | 'net' | 'not_registered' | 'disabled' | کد خطای سرور
  String error = '';
  bool loaded = false;
  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];

  int _i(String k) => (data[k] as num?)?.toInt() ?? 0;
  int get coins => _i('coins');
  int get xp => _i('xp');
  int get level => data['level'] == null ? 1 : _i('level');
  int get streak => _i('streak');
  int get levelXp => _i('level_xp');
  int? get nextXp => (data['next_xp'] as num?)?.toInt();
  String get rank => (data['rank'] as String?) ?? 'traveler';
  bool get dailyReady => data['daily_ready'] == true;
  int get dailyNext => _i('daily_next');
  String get equippedIcon => (data['equipped_icon'] as String?) ?? 'lion';
  String get equippedTheme => (data['equipped_theme'] as String?) ?? 'classic';
  int get chatUntil => _i('chat_until');
  bool get chatOn => chatUntil > DateTime.now().millisecondsSinceEpoch;
  List<String> get owned =>
      ((data['owned'] as List?) ?? const <dynamic>[]).map((e) => '$e').toList();
  List<Map<String, dynamic>> get goals => ((data['goals'] as List?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  int get queued => _queue.fold<int>(0, (a, e) => a + ((e['n'] as num?)?.toInt() ?? 1));

  double get levelProgress {
    final n = nextXp;
    if (n == null) return 1;
    final span = n - levelXp;
    if (span <= 0) return 1;
    return ((xp - levelXp) / span).clamp(0.0, 1.0).toDouble();
  }

  Future<void> init() async {
    if (loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final c = p.getString(_cacheKey);
      if (c != null) {
        final m = jsonDecode(c);
        if (m is Map) data = Map<String, dynamic>.from(m);
      }
      final q = p.getString(_queueKey);
      if (q != null) {
        final l = jsonDecode(q);
        if (l is List) {
          for (final e in l) {
            if (e is Map) _queue.add(Map<String, dynamic>.from(e));
          }
        }
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(data));
      await p.setString(_queueKey, jsonEncode(_queue));
    } catch (_) {}
  }

  /// پاسخ سرور را اعمال می‌کند؛ true = موفق.
  bool _apply(Map<String, dynamic>? j) {
    if (j == null) {
      error = 'net';
      notifyListeners();
      return false;
    }
    final w = j['wallet'];
    if (w is Map) {
      data = Map<String, dynamic>.from(w);
      _save();
    }
    final ok = j['success'] == true;
    error = ok ? '' : ((j['error'] as String?) ?? 'fail');
    notifyListeners();
    return ok;
  }

  /// نتیجه‌ی بازی آنلاین که سرور برگردانده (برنده شدن و ...) را اعمال می‌کند.
  void applyWallet(Object? w) {
    if (w is Map) {
      data = Map<String, dynamic>.from(w);
      _save();
      notifyListeners();
    }
  }

  Future<bool> refresh() async {
    final ok = _apply(await GameApi.get('/api/game/wallet'));
    if (ok) await flushQueue();
    return ok;
  }

  /// true اگر جایزه گرفته شد. مقدار گرفته‌شده در [lastGain].
  int lastGain = 0;

  Future<bool> claimDaily() async {
    final j = await GameApi.post('/api/game/daily');
    final ok = _apply(j);
    lastGain = ok ? ((j?['gained'] as num?)?.toInt() ?? 0) : 0;
    return ok;
  }

  Future<bool> claimGoal(int id) async {
    final j = await GameApi.post('/api/game/goal', {'id': id});
    final ok = _apply(j);
    lastGain = ok ? ((j?['gained'] as num?)?.toInt() ?? 0) : 0;
    return ok;
  }

  /// '' = موفق، وگرنه کد خطا (level_low / no_coins / owned / net ...)
  Future<String> buy(String item) async {
    final j = await GameApi.post('/api/game/buy', {'item': item});
    if (_apply(j)) return '';
    return error;
  }

  Future<String> equip(String item) async {
    final j = await GameApi.post('/api/game/equip', {'item': item});
    if (_apply(j)) return '';
    return error;
  }

  /// ثبت نتیجه‌ی بازی آفلاین. result: win | draw | loss ؛ level: easy | normal | hard | local | nearby
  /// خروجی: سکه‌ی گرفته‌شده (۰ اگر در صف ماند یا سقف روزانه پر بود).
  Future<int> reportOffline(String result, String level) async {
    final j = await GameApi.post('/api/game/offline', {'result': result, 'level': level});
    if (j == null) {
      if (_queue.length < 40) {
        _queue.add(<String, dynamic>{'result': result, 'level': level, 'n': 1});
        await _save();
      }
      error = 'net';
      notifyListeners();
      return 0;
    }
    if (_apply(j)) return (j['gained'] as num?)?.toInt() ?? 0;
    return 0;
  }

  Future<void> flushQueue() async {
    if (_queue.isEmpty) return;
    final groups = <String, int>{};
    for (final e in _queue) {
      final k = '${e['result']}|${e['level']}';
      groups[k] = (groups[k] ?? 0) + ((e['n'] as num?)?.toInt() ?? 1);
    }
    for (final entry in groups.entries) {
      final parts = entry.key.split('|');
      var left = entry.value;
      while (left > 0) {
        final n = left > 5 ? 5 : left;
        final j = await GameApi.post('/api/game/offline', {'result': parts[0], 'level': parts[1], 'n': n});
        if (j == null) {
          await _save();
          return; // هنوز اینترنت نیست؛ صف می‌ماند
        }
        _apply(j);
        left -= n;
      }
    }
    _queue.clear();
    await _save();
    notifyListeners();
  }
}
