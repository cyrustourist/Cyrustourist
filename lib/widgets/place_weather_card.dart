import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/language/app_language.dart';
import '../services/weather_service.dart';
import 'toolbox/tools/weather_screen.dart';

/// ===============================================================
/// کارت آب‌وهوای «همین مکان»
/// ---------------------------------------------------------------
/// مختصات همان طول/عرض جغرافیایی است که در پنل مدیریت برای مسیریابی
/// وارد می‌شود (اقامتگاه، گردشگری سلامت، لیدر، جاذبه، فیلم).
/// - دمای فعلی و وضعیت هوا را همان‌جا نشان می‌دهد
/// - با لمس، صفحه‌ی آب‌وهوا (چند روز پیش‌رو + جستجوی شهر در بالا) باز می‌شود
/// - داده‌ها رایگان و بدون کلید؛ اگر Open-Meteo در شبکه‌ی کاربر باز نشد،
///   خودکار از MET Norway گرفته می‌شود.
/// ===============================================================
class PlaceWeatherCard extends StatefulWidget {
  const PlaceWeatherCard({
    super.key,
    required this.lat,
    required this.lon,
    this.placeName = '',
  });

  final double lat;
  final double lon;
  final String placeName;

  @override
  State<PlaceWeatherCard> createState() => _PlaceWeatherCardState();
}

class _PlaceWeatherCardState extends State<PlaceWeatherCard> {
  static const Color _gold = Color(0xffffd36a);
  static const Color _goldBright = Color(0xffffe39a);

  WeatherResult? _weather;
  bool _loading = true;
  bool _failed = false;

  String get _lang {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      default:
        return 'en';
    }
  }

  String _tr(String fa, String en, String ar) {
    switch (_lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PlaceWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final w = await WeatherService.fetchWeather(
        placeName: widget.placeName,
        lat: widget.lat,
        lon: widget.lon,
      );
      if (!mounted) return;
      setState(() {
        _weather = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _openWeatherPage() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeatherScreen(
          initialPlace: WeatherPlace(
            name: widget.placeName.isNotEmpty
                ? widget.placeName
                : _tr('این مکان', 'This place', 'هذا المكان'),
            country: '',
            lat: widget.lat,
            lon: widget.lon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _weather;

    Widget trailing;
    if (_loading) {
      trailing = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
      );
    } else if (w != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(WeatherService.emoji(w.weatherCode),
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '${w.currentTemp.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      );
    } else {
      trailing = Text(
        _failed ? _tr('مشاهده', 'View', 'عرض') : '',
        style: const TextStyle(color: _goldBright, fontSize: 12.5),
      );
    }

    final subtitle = w != null
        ? '${WeatherService.label(w.weatherCode, _lang)}'
            '${w.daily.isNotEmpty ? '  •  ${w.daily.first.tempMin.round()}° / ${w.daily.first.tempMax.round()}°' : ''}'
        : _tr('پیش‌بینی چند روز پیش رو', 'Forecast for the coming days',
            'توقعات الأيام القادمة');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openWeatherPage,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff103b50), Color(0xff0d2432)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_cloudy_rounded, color: _goldBright, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('آب‌وهوای این مکان', 'Weather at this place',
                          'طقس هذا المكان'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
              const SizedBox(width: 4),
              Icon(
                _lang == 'en'
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: _gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
