class CartoConfig {
  // کلید API مربوط به CARTO را اینجا قرار بده.
  //
  // مثال:
  // static const String apiKey = 'YOUR_CARTO_API_KEY';

  static const String apiKey = '';

  // آدرس پایه نقشه CARTO
  static const String tileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  // نام سرویس برای استفاده در سیستم Fallback
  static const String providerName = 'CARTO';
}
