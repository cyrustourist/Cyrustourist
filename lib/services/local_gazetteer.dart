import 'package:latlong2/latlong.dart';

/// فهرست آفلاین شهرها و جاذبه‌های اصلی ایران (بدون نیاز به اینترنت/سرور).
/// وقتی جستجوی آنلاین (Nominatim) در دسترس نباشد یا نتیجه ندهد، از اینجا جواب داده می‌شود.
class LocalPlace {
  const LocalPlace(this.fa, this.en, this.lat, this.lng);
  final String fa;
  final String en;
  final double lat;
  final double lng;
  LatLng get point => LatLng(lat, lng);
}

class LocalGazetteer {
  LocalGazetteer._();

  static const List<LocalPlace> places = [
    LocalPlace('تهران', 'Tehran', 35.6892, 51.3890),
    LocalPlace('مشهد', 'Mashhad', 36.2605, 59.6168),
    LocalPlace('اصفهان', 'Isfahan', 32.6546, 51.6680),
    LocalPlace('شیراز', 'Shiraz', 29.5918, 52.5837),
    LocalPlace('تبریز', 'Tabriz', 38.0962, 46.2738),
    LocalPlace('کرج', 'Karaj', 35.8400, 50.9391),
    LocalPlace('اهواز', 'Ahvaz', 31.3183, 48.6706),
    LocalPlace('قم', 'Qom', 34.6399, 50.8759),
    LocalPlace('کرمانشاه', 'Kermanshah', 34.3277, 47.0778),
    LocalPlace('ارومیه', 'Urmia', 37.5527, 45.0761),
    LocalPlace('رشت', 'Rasht', 37.2808, 49.5832),
    LocalPlace('زاهدان', 'Zahedan', 29.4963, 60.8629),
    LocalPlace('کرمان', 'Kerman', 30.2839, 57.0834),
    LocalPlace('یزد', 'Yazd', 31.8974, 54.3569),
    LocalPlace('اردبیل', 'Ardabil', 38.2498, 48.2933),
    LocalPlace('بندرعباس', 'Bandar Abbas', 27.1832, 56.2666),
    LocalPlace('اراک', 'Arak', 34.0917, 49.6892),
    LocalPlace('همدان', 'Hamadan', 34.7983, 48.5148),
    LocalPlace('سنندج', 'Sanandaj', 35.3219, 46.9862),
    LocalPlace('قزوین', 'Qazvin', 36.2688, 50.0041),
    LocalPlace('زنجان', 'Zanjan', 36.6736, 48.4787),
    LocalPlace('گرگان', 'Gorgan', 36.8427, 54.4439),
    LocalPlace('ساری', 'Sari', 36.5633, 53.0601),
    LocalPlace('بوشهر', 'Bushehr', 28.9234, 50.8203),
    LocalPlace('بیرجند', 'Birjand', 32.8649, 59.2262),
    LocalPlace('بجنورد', 'Bojnord', 37.4747, 57.3290),
    LocalPlace('سمنان', 'Semnan', 35.5769, 53.3920),
    LocalPlace('خرم‌آباد', 'Khorramabad', 33.4878, 48.3558),
    LocalPlace('ایلام', 'Ilam', 33.6374, 46.4227),
    LocalPlace('یاسوج', 'Yasuj', 30.6682, 51.5880),
    LocalPlace('شهرکرد', 'Shahrekord', 32.3256, 50.8644),
    LocalPlace('جزیره کیش', 'Kish Island', 26.5579, 53.9800),
    LocalPlace('جزیره قشم', 'Qeshm Island', 26.9580, 56.2710),
    LocalPlace('چابهار', 'Chabahar', 25.2919, 60.6430),
    LocalPlace('آبادان', 'Abadan', 30.3392, 48.3043),
    LocalPlace('دزفول', 'Dezful', 32.3830, 48.4058),
    LocalPlace('کاشان', 'Kashan', 33.9850, 51.4100),
    LocalPlace('نیشابور', 'Neyshabur', 36.2133, 58.7958),
    LocalPlace('سبزوار', 'Sabzevar', 36.2126, 57.6819),
    LocalPlace('مراغه', 'Maragheh', 37.3891, 46.2387),
    LocalPlace('خوی', 'Khoy', 38.5503, 44.9521),
    LocalPlace('بم', 'Bam', 29.1060, 58.3570),
    LocalPlace('تخت جمشید', 'Persepolis', 29.9355, 52.8916),
    LocalPlace('پاسارگاد', 'Pasargadae', 30.1949, 53.1670),
    LocalPlace('چغازنبیل', 'Chogha Zanbil', 32.0094, 48.5211),
    LocalPlace('میدان نقش جهان', 'Naqsh-e Jahan Square', 32.6575, 51.6777),
    LocalPlace('برج آزادی', 'Azadi Tower', 35.6997, 51.3380),
    LocalPlace('برج میلاد', 'Milad Tower', 35.7448, 51.3753),
    LocalPlace('دماوند', 'Damavand', 35.9554, 52.1100),
    LocalPlace('ماسوله', 'Masuleh', 37.1566, 48.9910),
    LocalPlace('مریوان', 'Marivan', 35.5200, 46.1765),
  ];

  static String _norm(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ّ', '')
        .replaceAll('‌', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<LocalPlace> search(String query, {int limit = 6}) {
    final q = _norm(query);
    if (q.length < 2) return const [];
    final starts = <LocalPlace>[];
    final contains = <LocalPlace>[];
    for (final p in places) {
      final fa = _norm(p.fa);
      final en = _norm(p.en);
      if (fa.startsWith(q) || en.startsWith(q)) {
        starts.add(p);
      } else if (fa.contains(q) || en.contains(q) || q.contains(fa)) {
        contains.add(p);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }
}
