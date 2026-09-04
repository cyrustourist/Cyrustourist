class CartoConfig {
  // کلید واقعی CARTO را اینجا قرار بده
  static const String apiKey = 'YOUR_CARTO_API_KEY';

  static const String tileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static String get tileUrlWithKey =>
      '$tileUrl?key=$apiKey';

  static const String providerName = 'CARTO';
}
