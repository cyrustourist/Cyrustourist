import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../map_place.dart';

/// ذخیره‌سازی علاقه‌مندی‌های نقشه.
///
/// این سرویس مستقل از FavoritesService قدیمی است
/// چون MapPlace مدل متفاوتی دارد.
class MapPlaceFavoritesService {
  static const _storageKey = 'cyrus_map_place_favorites';

  Future<List<MapPlace>> loadFavorites() async {
    final pref = await SharedPreferences.getInstance();

    final raw = pref.getStringList(_storageKey) ?? [];

    return raw
        .map(_decode)
        .whereType<MapPlace>()
        .toList();
  }

  Future<Set<String>> loadFavoriteIds() async {
    final favorites = await loadFavorites();

    return favorites.map((place) => place.id).toSet();
  }

  Future<bool> isFavorite(String placeId) async {
    final ids = await loadFavoriteIds();

    return ids.contains(placeId);
  }

  /// اضافه یا حذف یک مکان از علاقه‌مندی‌ها
  Future<bool> toggleFavorite(MapPlace place) async {
    final pref = await SharedPreferences.getInstance();

    final raw = pref.getStringList(_storageKey) ?? [];

    final list = raw
        .map(_decode)
        .whereType<MapPlace>()
        .toList();

    final exists = list.any(
      (item) => item.id == place.id,
    );

    if (exists) {
      list.removeWhere(
        (item) => item.id == place.id,
      );
    } else {
      list.add(
        place.copyWith(isFavorite: true),
      );
    }

    await pref.setStringList(
      _storageKey,
      list
          .map(
            (item) => jsonEncode(item.toJson()),
          )
          .toList(),
    );

    return !exists;
  }

  MapPlace? _decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MapPlace.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
