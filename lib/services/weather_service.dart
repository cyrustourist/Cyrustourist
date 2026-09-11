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
    } finally {
      client.close(force: true);
    }
  }

  /// دریافت وضعیت آب‌وهوای کامل برای یک مختصات جغرافیایی
  static Future<WeatherResult> fetchWeather({
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
            'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,precipitation,uv_index',
        'hourly': 'temperature_2m,precipitation_probability',
        'daily':
            'temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
        'forecast_days': '5',
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
      );
    } finally {
      client.close(force: true);
    }
  }
}
