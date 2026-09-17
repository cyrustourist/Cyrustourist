import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// ذخیره‌سازی علاقه‌مندی‌های ویدئوهای گردشگری (نمایش فیلم).
///
/// مستقل از MapPlaceFavoritesService است چون مدل ویدئو یک
/// Map<String,String> ساده (همان ساختار video_page.dart) است،
/// نه یک مدل کلاس اختصاصی.
class VideoFavoritesService {
  static const _storageKey = 'cyrus_video_favorites';

  Future<List<Map<String, String>>> loadFavorites() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList(_storageKey) ?? [];

    return raw.map(_decode).whereType<Map<String, String>>().toList();
  }

  Future<Set<String>> loadFavoriteIds() async {
    final favorites = await loadFavorites();
    return favorites.map(_idOf).toSet();
  }

  Future<bool> isFavorite(String videoId) async {
    final ids = await loadFavoriteIds();
    return ids.contains(videoId);
  }

  /// اضافه یا حذف یک ویدئو از علاقه‌مندی‌ها.
  /// خروجی: true یعنی اضافه شد، false یعنی حذف شد.
  Future<bool> toggleFavorite(Map<String, String> video) async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getStringList(_storageKey) ?? [];

    final list = raw.map(_decode).whereType<Map<String, String>>().toList();

    final id = _idOf(video);
    final exists = list.any((item) => _idOf(item) == id);

    if (exists) {
      list.removeWhere((item) => _idOf(item) == id);
    } else {
      list.add(video);
    }

    await pref.setStringList(
      _storageKey,
      list.map((item) => jsonEncode(item)).toList(),
    );

    return !exists;
  }

  String _idOf(Map<String, String> video) => video['url'] ?? video['title_fa'] ?? '';

  Map<String, String>? _decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return null;
    }
  }
}
