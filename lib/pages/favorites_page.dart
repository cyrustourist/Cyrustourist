import 'package:flutter/material.dart';

import '../map_place.dart';
import '../services/map_place_favorites_service.dart';
import 'category_explorer_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final MapPlaceFavoritesService _favoritesService =
      MapPlaceFavoritesService();

  List<MapPlace> _favorites = [];
  bool _loading = true;
  bool _isRtl = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final items = await _favoritesService.loadFavorites();

    if (!mounted) return;

    setState(() {
      _favorites = items;
      _loading = false;
    });
  }

  Future<void> _removeFavorite(MapPlace place) async {
    await _favoritesService.toggleFavorite(place);
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'علاقه‌مندی‌ها',
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _favorites.isEmpty
                ? const Center(
                    child: Text(
                      'مورد علاقه‌ای ذخیره نشده است',
                    ),
                  )
                : ListView.builder(
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final place = _favorites[index];

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            place.name,
                          ),
                          subtitle: Text(
                            place.category ?? '',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.favorite,
                            ),
                            onPressed: () {
                              _removeFavorite(place);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryExplorerPage(
                                  category: place.category ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
