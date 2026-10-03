import 'dart:convert';
import 'dart:io';

/// ===============================================================
/// Cyrus Tourist — سرویس آب‌وهوای هوشمند مقصد
/// ---------------------------------------------------------------
/// منبع داده: Open-Meteo
/// - کاملاً رایگان، بدون نیاز به کلید (API Key)
/// - پوشش جهانی، شامل ایران
/// - سقف درخواست بالا و مناسب برای اپلیکیشن‌های همگانی
/// ===============================================================

class WeatherPlace {
  final String name;
  final String country;
  final double lat;
  final double lon;

  WeatherPlace({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
  });
}

class WeatherResult {
  final String placeName;
  final double currentTemp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final double uvIndex;
  final String sunrise;
  final String sunset;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final String bestTimeHint;

  /// کد وضعیت (استاندارد WMO) برای آیکون/توضیح — 0 = صاف
  final int weatherCode;

  /// منبعی که داده از آن آمده (open-meteo یا met.no)
  final String source;

  WeatherResult({
    required this.placeName,
    required this.currentTemp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.daily,
    required this.bestTimeHint,
    this.weatherCode = 0,
    this.source = 'open-meteo',
  });
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final double precipitationProb;
  HourlyWeather(this.time, this.temp, this.precipitationProb);
}

class DailyWeather {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationProb;
  DailyWeather(this.date, this.tempMax, this.tempMin, this.precipitationProb);
}

class WeatherService {
  /// جستجوی شهر/مکان (Geocoding رایگان Open-Meteo)
  static Future<List<WeatherPlace>> searchPlace(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': query,
        'count': '8',
        'language': 'fa',
      },
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();

      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results == null) return [];

      return results
          .map(
            (r) => WeatherPlace(
              name: r['name']?.toString() ?? '',
              country: r['country']?.toString() ?? '',
              lat: (r['latitude'] as num).toDouble(),
              lon: (r['longitude'] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {
      // شبکه/فیلتر: به‌جای کرش، فهرست خالی برمی‌گردد
      return [];
    } finally {
      client.close(force: true);
    }
  }

  /// دریافت وضعیت آب‌وهوای کامل برای یک مختصات جغرافیایی.
  /// ابتدا Open-Meteo (رایگان، بدون کلید)؛ اگر در شبکه‌ی کاربر باز نشد
  /// (فیلتر/قطعی)، خودکار از MET Norway (رایگان، بدون کلید) استفاده می‌شود.
  static Future<WeatherResult> fetchWeather({
    required String placeName,
    required double lat,
    required double lon,
  }) async {
    try {
      return await _fetchOpenMeteo(placeName: placeName, lat: lat, lon: lon)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return await _fetchMetNo(placeName: placeName, lat: lat, lon: lon)
          .timeout(const Duration(seconds: 15));
    }
  }

  /// ایموجی وضعیت هوا از کد WMO
  static String emoji(int code) {
    if (code == 0) return '☀️';
    if (code == 1) return '🌤️';
    if (code == 2) return '⛅';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 57) return '🌦️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code == 85 || code == 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }

  /// توضیح کوتاه وضعیت هوا: lang = fa | en | ar
  static String label(int code, String lang) {
    String pick(String fa, String en, String ar) =>
        lang == 'fa' ? fa : (lang == 'ar' ? ar : en);
    if (code == 0) return pick('آسمان صاف', 'Clear sky', 'سماء صافية');
    if (code == 1 || code == 2) {
      return pick('نیمه‌ابری', 'Partly cloudy', 'غائم جزئياً');
    }
    if (code == 3) return pick('ابری', 'Cloudy', 'غائم');
    if (code == 45 || code == 48) return pick('مه‌آلود', 'Foggy', 'ضباب');
    if (code >= 51 && code <= 57) return pick('نم‌نم باران', 'Drizzle', 'رذاذ');
    if (code >= 61 && code <= 67) return pick('بارانی', 'Rain', 'مطر');
    if (code >= 71 && code <= 77) return pick('برفی', 'Snow', 'ثلج');
    if (code >= 80 && code <= 86) return pick('رگبار', 'Showers', 'زخات');
    if (code >= 95) return pick('رعد و برق', 'Thunderstorm', 'عاصفة رعدية');
    return pick('نامشخص', 'Unknown', 'غير معروف');
  }

  static Future<WeatherResult> _fetchOpenMeteo({
    required String placeName,
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current':
            'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,precipitation,uv_index,weather_code',
        'hourly': 'temperature_2m,precipitation_probability',
        'daily':
            'temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
        'forecast_days': '7',
        'timezone': 'auto',
      },
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('خطا در دریافت آب‌وهوا (${response.statusCode})');
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final current = data['current'] as Map<String, dynamic>;
      final hourlyRaw = data['hourly'] as Map<String, dynamic>;
      final dailyRaw = data['daily'] as Map<String, dynamic>;

      final hourlyTimes = (hourlyRaw['time'] as List).cast<String>();
      final hourlyTemps = (hourlyRaw['temperature_2m'] as List);
      final hourlyPrecip =
          (hourlyRaw['precipitation_probability'] as List);

      final now = DateTime.now();
      final hourly = <HourlyWeather>[];
      for (var i = 0; i < hourlyTimes.length; i++) {
        final t = DateTime.parse(hourlyTimes[i]);
        if (t.isBefore(now.subtract(const Duration(hours: 1)))) continue;
        hourly.add(
          HourlyWeather(
            t,
            (hourlyTemps[i] as num).toDouble(),
            (hourlyPrecip[i] as num).toDouble(),
          ),
        );
        if (hourly.length >= 24) break;
      }

      final dailyDates = (dailyRaw['time'] as List).cast<String>();
      final dailyMax = (dailyRaw['temperature_2m_max'] as List);
      final dailyMin = (dailyRaw['temperature_2m_min'] as List);
      final dailyPrecip =
          (dailyRaw['precipitation_probability_max'] as List);

      final daily = <DailyWeather>[
        for (var i = 0; i < dailyDates.length; i++)
          DailyWeather(
            DateTime.parse(dailyDates[i]),
            (dailyMax[i] as num).toDouble(),
            (dailyMin[i] as num).toDouble(),
            (dailyPrecip[i] as num).toDouble(),
          ),
      ];

      // پیشنهاد ساده «بهترین زمان گردش امروز»:
      // ساعتی با کمترین احتمال بارش و دمای معتدل‌تر بین ۸ صبح تا ۸ شب
      String bestTimeHint = '';
      HourlyWeather? best;
      for (final h in hourly) {
        if (h.time.hour < 8 || h.time.hour > 20) continue;
        if (h.precipitationProb > 30) continue;
        if (best == null ||
            (h.temp - 24).abs() < (best.temp - 24).abs()) {
          best = h;
        }
      }
      if (best != null) {
        final hh = best.time.hour.toString().padLeft(2, '0');
        bestTimeHint = 'ساعت $hh:۰۰ مناسب‌ترین زمان برای گردش امروز است';
      } else {
        bestTimeHint = 'امروز احتمال بارش بالاست؛ برنامه گردش را منعطف نگه دارید';
      }

      String fmtTime(String iso) {
        final t = DateTime.parse(iso);
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }

      return WeatherResult(
        placeName: placeName,
        currentTemp: (current['temperature_2m'] as num).toDouble(),
        feelsLike: (current['apparent_temperature'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toInt(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        precipitation: (current['precipitation'] as num).toDouble(),
        uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0,
        sunrise: fmtTime((dailyRaw['sunrise'] as List).first.toString()),
        sunset: fmtTime((dailyRaw['sunset'] as List).first.toString()),
        hourly: hourly,
        daily: daily,
        bestTimeHint: bestTimeHint,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        source: 'open-meteo',
      );
    } finally {
      client.close(force: true);
    }
  }

  // ------------------------------------------------------------
  // پشتیبان: MET Norway (api.met.no) — رایگان، بدون کلید، پوشش جهانی
  // ------------------------------------------------------------
  static int _metCode(String symbol) {
    final s = symbol.toLowerCase();
    if (s.contains('thunder')) return 95;
    if (s.contains('snow')) return 73;
    if (s.contains('sleet')) return 67;
    if (s.contains('rain')) return 63;
    if (s.contains('fog')) return 45;
    if (s.startsWith('clearsky')) return 0;
    if (s.startsWith('fair')) return 1;
    if (s.startsWith('partlycloudy')) return 2;
    if (s.startsWith('cloudy')) return 3;
    return 3;
  }

  static Future<WeatherResult> _fetchMetNo({
    required String placeName,
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.https(
      'api.met.no',
      '/weatherapi/locationforecast/2.0/compact',
      {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
      },
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // MET Norway شناسایی برنامه را در User-Agent الزامی می‌داند
      request.headers.set(HttpHeaders.userAgentHeader,
          'CyrusTourist/1.0 (https://cyrustourist-maker.github.io/Cyrustourist/)');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('خطا در دریافت آب‌وهوا (${response.statusCode})');
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final series =
          ((data['properties'] as Map<String, dynamic>)['timeseries'] as List)
              .cast<Map<String, dynamic>>();
      if (series.isEmpty) throw Exception('داده‌ای دریافت نشد');

      double? num0(dynamic v) => v is num ? v.toDouble() : null;

      Map<String, dynamic> instant(Map<String, dynamic> e) =>
          (((e['data'] as Map<String, dynamic>)['instant']
                  as Map<String, dynamic>)['details']
              as Map<String, dynamic>);

      double precipOf(Map<String, dynamic> e) {
        final d = e['data'] as Map<String, dynamic>;
        for (final k in const ['next_1_hours', 'next_6_hours']) {
          final n = d[k];
          if (n is Map<String, dynamic>) {
            final det = n['details'];
            if (det is Map<String, dynamic>) {
              return num0(det['precipitation_amount']) ?? 0;
            }
          }
        }
        return 0;
      }

      String symbolOf(Map<String, dynamic> e) {
        final d = e['data'] as Map<String, dynamic>;
        for (final k in const ['next_1_hours', 'next_6_hours', 'next_12_hours']) {
          final n = d[k];
          if (n is Map<String, dynamic>) {
            final sm = n['summary'];
            if (sm is Map<String, dynamic>) {
              return sm['symbol_code']?.toString() ?? '';
            }
          }
        }
        return '';
      }

      final first = series.first;
      final cur = instant(first);
      final temp = num0(cur['air_temperature']) ?? 0;

      final now = DateTime.now();
      final hourly = <HourlyWeather>[];
      for (final e in series) {
        final t = DateTime.parse(e['time'].toString()).toLocal();
        if (t.isBefore(now.subtract(const Duration(hours: 1)))) continue;
        final p = precipOf(e);
        hourly.add(HourlyWeather(
          t,
          num0(instant(e)['air_temperature']) ?? temp,
          p > 0 ? (p >= 1 ? 80.0 : 40.0) : 0.0,
        ));
        if (hourly.length >= 24) break;
      }

      // روزانه: گروه‌بندی بر اساس تاریخ محلی
      final byDay = <String, List<Map<String, dynamic>>>{};
      for (final e in series) {
        final t = DateTime.parse(e['time'].toString()).toLocal();
        final key = '${t.year}-${t.month}-${t.day}';
        byDay.putIfAbsent(key, () => []).add(e);
      }
      final daily = <DailyWeather>[];
      for (final entry in byDay.entries) {
        var mx = -1000.0;
        var mn = 1000.0;
        var rain = 0.0;
        DateTime? day;
        for (final e in entry.value) {
          final t = DateTime.parse(e['time'].toString()).toLocal();
          day ??= DateTime(t.year, t.month, t.day);
          final v = num0(instant(e)['air_temperature']);
          if (v != null) {
            if (v > mx) mx = v;
            if (v < mn) mn = v;
          }
          rain += precipOf(e);
        }
        if (day == null || mx < -999) continue;
        daily.add(DailyWeather(
            day, mx, mn, rain > 0 ? (rain >= 2 ? 80.0 : 40.0) : 0.0));
        if (daily.length >= 7) break;
      }

      String bestTimeHint;
      HourlyWeather? best;
      for (final h in hourly) {
        if (h.time.hour < 8 || h.time.hour > 20) continue;
        if (h.precipitationProb > 30) continue;
        if (best == null || (h.temp - 24).abs() < (best.temp - 24).abs()) {
          best = h;
        }
      }
      if (best != null) {
        final hh = best.time.hour.toString().padLeft(2, '0');
        bestTimeHint = 'ساعت $hh:۰۰ مناسب‌ترین زمان برای گردش امروز است';
      } else {
        bestTimeHint = 'احتمال بارش بالاست؛ برنامه گردش را منعطف نگه دارید';
      }

      return WeatherResult(
        placeName: placeName,
        currentTemp: temp,
        feelsLike: temp,
        humidity: (num0(cur['relative_humidity']) ?? 0).round(),
        windSpeed: (num0(cur['wind_speed']) ?? 0) * 3.6,
        precipitation: precipOf(first),
        uvIndex: num0(cur['ultraviolet_index_clear_sky']) ?? 0,
        sunrise: '--:--',
        sunset: '--:--',
        hourly: hourly,
        daily: daily,
        bestTimeHint: bestTimeHint,
        weatherCode: _metCode(symbolOf(first)),
        source: 'met.no',
      );
    } finally {
      client.close(force: true);
    }
  }
}
