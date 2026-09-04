class CartoConfig {
  // کلید واقعی CARTO
  static const String apiKey = 'cb1_2whu_1_535e0db3c38cb9e2b233253a';

  static const String tileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static String get tileUrlWithKey =>
      '$tileUrl?key=$apiKey';

  static const String providerName = 'CARTO';
}
