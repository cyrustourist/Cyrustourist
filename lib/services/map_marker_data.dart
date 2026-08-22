import 'package:latlong2/latlong.dart';

class MapMarkerData {
  final String id;
  final String title;
  final String category;
  final String description;
  final LatLng position;

  const MapMarkerData({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.position,
  });
}


class TourismMarkers {

  static const List<MapMarkerData> places = [

    MapMarkerData(
      id: 'mashhad',
      title: 'مشهد',
      category: 'جاذبه گردشگری',
      description: 'شهر زیارتی و گردشگری ایران',
      position: LatLng(
        36.2605,
        59.6168,
      ),
    ),


    MapMarkerData(
      id: 'tehran',
      title: 'تهران',
      category: 'شهر گردشگری',
      description: 'پایتخت ایران و مرکز فرهنگی',
      position: LatLng(
        35.6892,
        51.3890,
      ),
    ),


    MapMarkerData(
      id: 'caspian',
      title: 'دریای کاسپین',
      category: 'طبیعت',
      description: 'سواحل شمال ایران',
      position: LatLng(
        37.5000,
        49.5000,
      ),
    ),


    MapMarkerData(
      id: 'ramsar',
      title: 'رامسر',
      category: 'طبیعت گردی',
      description: 'عروس شهرهای شمال ایران',
      position: LatLng(
        36.9039,
        50.6583,
      ),
    ),


    MapMarkerData(
      id: 'shiraz',
      title: 'شیراز',
      category: 'تاریخی',
      description: 'شهر شعر و باغ‌های ایرانی',
      position: LatLng(
        29.5918,
        52.5837,
      ),
    ),

  ];


  static List<MapMarkerData> byCategory(String category) {

    return places
        .where(
          (item) =>
              item.category == category,
        )
        .toList();

  }

}
