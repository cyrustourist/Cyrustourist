import 'package:flutter/material.dart';

import '../main.dart' show LanguageManager, AppLanguage;
import '../map_place.dart';
import '../services/map_place_favorites_service.dart';
import '../widgets/map_place_details_sheet.dart';
import 'category_explorer_page.dart';

/// صفحه‌ی کلید ۱۰ — علاقه‌مندی‌ها.
///
/// فهرست تمام مکان‌هایی که کاربر از صفحه‌های سلامت/جاذبه/اقامتگاه
/// (کلید ۲، ۳، ۵) با ضربه روی قلب ذخیره کرده است را نشان می‌دهد.
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final favorites = await _favoritesService.loadFavorites();

    if (!mounted) return;

    setState(() {
      _favorites = favorites;
      _loading = false;
    });
  }

  Future<void> _remove(MapPlace place) async {
    final removedIndex = _favorites.indexWhere(
      (item) => item.id == place.id,
    );

    if (removedIndex == -1) return;

    setState(() {
      _favorites.removeAt(removedIndex);
    });

    await _favoritesService.toggleFavorite(place);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'از علاقه‌مندی‌ها حذف شد',
            'Removed from favorites',
            'تمت الإزالة من المفضلة',
          ),
        ),
        action: SnackBarAction(
          label: _text('بازگردانی', 'Undo', 'تراجع'),
          onPressed: () async {
            await _favoritesService.toggleFavorite(place);
            if (!mounted) return;
            setState(() {
              _favorites.insert(
                removedIndex.clamp(0, _favorites.length),
                place,
              );
            });
          },
        ),
      ),
    );
  }

  void _openPlace(MapPlace place) {
    MapPlaceDetailsSheet.show(
      context,
      place,
      isFavorite: true,
      onFavorite: () {
        Navigator.pop(context);
        _remove(place);
      },
      onRoute: () {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryExplorerPage(
              initialCategory: place.category,
            ),
          ),
        );
      },
    );
  }

  String _text(String fa, String en, String ar) {
    switch (LanguageManager.current) {
      case AppLanguage.english:
        return en;
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.persian:
        return fa;
    }
  }

  bool get _isRtl => LanguageManager.current != AppLanguage.english;

  String _categoryLabel(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.health:
        return _text('سلامت', 'Health', 'الصحة');
      case PlaceCategory.attraction:
        return _text('جاذبه', 'Attraction', 'معلم');
      case PlaceCategory.accommodation:
        return _text('اقامتگاه', 'Stay', 'إقامة');
      case PlaceCategory.restaurant:
        return _text('رستوران', 'Restaurant', 'مطعم');
      default:
        return _text('مکان', 'Place', 'مكان');
    }
  }

  IconData _iconFor(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.health:
        return Icons.local_hospital;
      case PlaceCategory.attraction:
        return Icons.photo_camera;
      case PlaceCategory.accommodation:
        return Icons.hotel;
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} ${_text('متر', 'm', 'م')}';
    }
    return '${(meters / 1000).toStringAsFixed(1)} ${_text('کیلومتر', 'km', 'كم')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl
