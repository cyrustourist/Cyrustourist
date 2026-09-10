import 'package:flutter/material.dart';
import '../../../services/weather_service.dart';

const _kBg = Color(0xff071722);
const _kCard1 = Color(0xff173747);
const _kCard2 = Color(0xff0b202c);
const _kGold = Color(0xffffd76a);

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<WeatherPlace> _suggestions = [];
  bool _searching = false;
  bool _loadingWeather = false;
  String? _error;
  WeatherResult? _weather;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await WeatherService.searchPlace(q);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  Future<void> _selectPlace(WeatherPlace place) async {
    setState(() {
      _suggestions = [];
      _searchCtrl.text = place.name;
      _loadingWeather = true;
      _error = null;
    });
    try {
      final result = await WeatherService.fetchWeather(
        placeName: '${place.name}${place.country.isNotEmpty ? '، ${place.country}' : ''}',
        lat: place.lat,
        lon: place.lon,
      );
      if (!mounted) return;
      setState(() {
        _weather = result;
        _loadingWeather = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطا در دریافت آب‌وهوا. اتصال اینترنت را بررسی کنید.';
        _loadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kGold),
          title: const Text(
            'آب‌وهوای هوشمند مقصد',
            style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'جستجوی شهر یا مقصد...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: _kGold),
                    filled: true,
                    fillColor: _kCard1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_searching)
                const LinearProgressIndicator(color: _kGold),
              if (_suggestions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        iconColor: _kGold,
                        leading: const Icon(Icons.location_city),
                        title: Text(s.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(s.country,
                            style: const TextStyle(color: Colors.white54)),
                        onTap: () => _selectPlace(s),
                      );
                    },
                  ),
                )
              else
                Expanded(child: _buildWeatherBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherBody() {
    if (_loadingWeather) {
      return const Center(
          child: CircularProgressIndicator(color: _kGold));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    final w = _weather;
    if (w == null) {
      return Center(
        child: Text(
          'برای شروع، نام یک شهر را جستجو کنید',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(
            children: [
              Text(w.placeName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '${w.currentTemp.round()}°',
                style: const TextStyle(
                    color: _kGold, fontSize: 46, fontWeight: FontWeight.bold),
              ),
              Text(
                'دمای احساس‌شده ${w.feelsLike.round()}°',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniStat(Icons.water_drop_rounded, '${w.humidity}%', 'رطوبت'),
                  _miniStat(Icons.air_rounded, '${w.windSpeed.round()} کمh', 'باد'),
                  _miniStat(Icons.wb_sunny_rounded, w.uvIndex.toStringAsFixed(1), 'UV'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniStat(Icons.wb_twilight_rounded, w.sunrise, 'طلوع'),
                  _miniStat(Icons.nightlight_round, w.sunset, 'غروب'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: _kGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  w.bestTimeHint,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('جدول ساعتی امروز',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: w.hourly.length,
                  itemBuilder: (context, i) {
                    final h = w.hourly[i];
                    return Container(
                      width: 62,
                      margin: const EdgeInsets.only(left: 8),
                      child: Column(
                        children: [
                          Text(
                            '${h.time.hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Text('${h.temp.round()}°',
                              style: const TextStyle(
                                  color: _kGold,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${h.precipitationProb.round()}%',
                            style: const TextStyle(
                                color: Colors.lightBlueAccent, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('پیش‌بینی چندروزه',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...w.daily.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${d.date.year}/${d.date.month}/${d.date.day}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Text('${d.precipitationProb.round()}%',
                          style: const TextStyle(
                              color: Colors.lightBlueAccent, fontSize: 12)),
                      const SizedBox(width: 14),
                      Text('${d.tempMin.round()}° / ${d.tempMax.round()}°',
                          style: const TextStyle(
                              color: _kGold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _kGold, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCard1, _kCard2],
        ),
        border: Border.all(color: _kGold.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}
