import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'badge_service.dart';

/// آیتم ذخیره‌شده برای حالت آفلاین (گروه یا دوست).
class OfflineItem {
  const OfflineItem(this.id, this.name);
  final String id;
  final String name;
}

/// لیست گروه‌ها و دوستان را پس از هر بار موفق ذخیره می‌کند تا وقتی اینترنت قطع است
/// بتوان از طریق شبکه‌ی آفلاین (Nearby) در همان گروه یا با همان دوست گفتگو کرد.
class OfflineCache {
  OfflineCache._();

  static const String _kGroups = 'cyrus_off_groups';
  static const String _kFriends = 'cyrus_off_friends';

  static Future<void> _save(String key, Iterable<OfflineItem> items) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = items.map((e) => <String, String>{'i': e.id, 'n': e.name}).toList();
      await p.setString(key, jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<OfflineItem>> _load(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) return const <OfflineItem>[];
      final l = jsonDecode(raw) as List<dynamic>;
      return l
          .whereType<Map<String, dynamic>>()
          .map((m) => OfflineItem('${m['i']}', '${m['n']}'))
          .toList();
    } catch (_) {
      return const <OfflineItem>[];
    }
  }

  static Future<void> saveGroups(Iterable<OfflineItem> items) => _save(_kGroups, items);
  static Future<List<OfflineItem>> loadGroups() => _load(_kGroups);
  static Future<void> saveFriends(Iterable<OfflineItem> items) => _save(_kFriends, items);
  static Future<List<OfflineItem>> loadFriends() => _load(_kFriends);

  /// اتاق گروه.
  static String groupRoom(String groupId) => 'g$groupId';

  /// اتاق گفتگوی شخصی: برای هر دو طرف یکسان است (شناسه‌ها مرتب می‌شوند).
  static Future<String> dmRoom(String friendUid) async {
    final me = await BadgeService.userUid();
    final ids = <String>[me, friendUid]..sort();
    return 'd${ids.join('_')}';
  }
}
