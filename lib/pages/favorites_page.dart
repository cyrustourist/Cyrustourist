import 'package:flutter/material.dart';

import '../core/language/app_language.dart';
import '../map_place.dart';
import '../services/map_place_favorites_service.dart';
import 'category_explorer_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() =>
      _FavoritesPageState();
}

class _FavoritesPageState
    extends State<FavoritesPage> {

  final MapPlaceFavoritesService _favoritesService =
      MapPlaceFavoritesService();

  List<MapPlace> _favorites = [];

  bool _loading = true;

  bool get _isRtl => LanguageManager.current != AppLanguage.english;

  String get _title {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'علاقه‌مندی‌ها';
      case AppLanguage.arabic:
        return 'المفضلة';
      case AppLanguage.english:
        return 'Favorites';
      default:
        return 'Favorites';
    }
  }

  String get _emptyMessage {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'مورد علاقه‌ای ذخیره نشده است';
      case AppLanguage.arabic:
        return 'لم يتم حفظ أي عنصر مفضل';
      case AppLanguage.english:
        return 'No favorites saved yet';
      default:
        return 'No favorites saved yet';
    }
  }


  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }


  Future<void> _loadFavorites() async {

    final items =
        await _favoritesService.loadFavorites();

    if (!mounted) return;

    setState(() {
      _favorites = items;
      _loading = false;
    });
  }


  Future<void> _removeFavorite(
      MapPlace place) async {

    await _favoritesService.toggleFavorite(place);

    await _loadFavorites();
  }


  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection:
          _isRtl
              ? TextDirection.rtl
              : TextDirection.ltr,

      child: Scaffold(

        appBar: AppBar(
          title: Text(
            _title,
          ),
          centerTitle: true,
        ),


        body: _loading

            ? const Center(
                child: CircularProgressIndicator(),
              )


            : _favorites.isEmpty

                ? Center(
                    child: Text(
                      _emptyMessage,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  )


                : ListView.builder(

                    itemCount:
                        _favorites.length,


                    itemBuilder:
                        (context, index) {


                      final place =
                          _favorites[index];


                      return Card(

                        margin:
                            const EdgeInsets.all(8),


                        child: ListTile(


                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),


                          title: Text(
                            place.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),


                          subtitle: Text(
                            place.category.name,
                          ),


                          trailing:
                              IconButton(

                            icon:
                                const Icon(
                              Icons.delete,
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

                                  initialCategory:
                                      place.category,

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
