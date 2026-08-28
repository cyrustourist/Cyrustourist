import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map_place.dart';
import '../widgets/map_markers_layer.dart';
import '../widgets/map_place_details_sheet.dart';

/// نمایش تمام‌صفحه‌ی همان نقشه‌ی کوچک صفحه‌ی کلیدهای ۲ (سلامت)،
/// ۳ (جاذبه‌ها) و ۵ (اقامتگاه)، برای زوم و بررسی راحت‌تر
/// جاذبه‌های پیدا‌شده یا جستجو‌شده.
///
/// دکمه بازگشت بالای صفحه (leading) دقیقاً همان «بازگشت به حالت
/// اول» است: چون این صفحه فقط با Navigator.push باز شده، با زدن
/// دکمه بازگشت یا دکمه سیستم، بدون هیچ تغییری روی صفحه‌ی قبلی و
/// وضعیت آن (جستجو، شعاع، لیست) برمی‌گردیم.
class CategoryFullMapPage extends StatefulWidget {
  final List<MapPlace> places;
  final LatLng initialCenter;
  final String title;
  final bool isRtl;
  final bool Function(MapPlace place) isFavorite;
  final void Function(MapPlace place) onFavorite;
  final void Function(MapPlace place) onRoute;

  const CategoryFullMapPage({
    super.key,
    required this.places,
    required this.initialCenter,
    required this.title,
    required this.isRtl,
    required this.isFavorite,
    required this.onFavorite,
    required this.onRoute,
  });

  @override
  State<CategoryFullMapPage> createState() =>
      _CategoryFullMapPageState();
}

class _CategoryFullMapPageState
    extends State<CategoryFullMapPage> {
  final MapController _mapController = MapController();

  void _onMarkerTap(MapPlace place) {
    MapPlaceDetailsSheet.show(
      context,
      place,
      isFavorite: widget.isFavorite(place),
      onFavorite: () {
        Navigator.pop(context);
        widget.onFavorite(place);
      },
      onRoute: () {
        Navigator.pop(context);
        widget.onRoute(place);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            tooltip: widget.isRtl
                ? 'بازگشت به حالت اول'
                : 'Back',
            icon: Icon(
              widget.isRtl
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cyrustourist.app',
            ),
            MapMarkersLayer(
              places: widget.places,
              onTap: _onMarkerTap,
            ),
          ],
        ),
      ),
    );
  }
}
