import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart' show SmartMapPage;

// ===================== رنگ‌ها و برند =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);
const Color _tealBright = Color(0xff6df5cf);

const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];

Color _goldA(double a) => _gold.withValues(alpha: a);

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در باز کردن لینک.')),
      );
    }
  }
}

// ============================================================
// مدل داده‌ی اقامتگاه برای این صفحه
// ============================================================
//
// فیلدها هم‌راستا با residences-data.js سایت هستند تا وقتی
// سیستم واقعی اقامتگاه‌ها (id/name/type/province/city/...) به
// اپ وصل شد، همین مدل مستقیماً از آن داده پر شود.
//
// نکته درباره‌ی شماره‌ها: طبق قوانین بازار/دیوار، این صفحه هرگز
// مستقیماً تماس نمی‌گیرد (بدون CALL_PHONE) — فقط با tel: برنامه‌ی
// تلفن گوشی کاربر را با شماره‌ی از پیش پرشده باز می‌کند و خود
// کاربر باید دکمه‌ی تماس را در برنامه‌ی تلفن بزند؛ دقیقاً مانند
// بخش پشتیبانی فعلی (کلید ۹).

class ResidenceVideoData {
  const ResidenceVideoData({
    required this.name,
    required this.city,
    required this.description,
    required this.aparatHash,
    this.province,
    this.mobilePhone,
    this.landlinePhone,
    this.supportPhone,
    this.instagramUrl,
    this.websiteUrl,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
  });

  final String name;
  final String city;
  final String? province;
  final String description;

  /// هش ویدیوی آپارات (همان بخش بعد از videohash/ در لینک امبد)
  final String aparatHash;

  final String? mobilePhone;
  final String? landlinePhone;
  final String? supportPhone;

  final String? instagramUrl;
  final String? websiteUrl;

  /// مختصات برای مسیریابی مستقیم؛ اگر خالی باشد، دکمه‌ی
  /// «مسیریابی» نقشه‌ی عمومی اپ را باز می‌کند.
  final double? latitude;
  final double? longitude;

  /// امتیاز ۰ تا ۵ و تعداد رأی‌دهندگان (اختیاری، فقط نمایشی)
  final double? rating;
  final int? ratingCount;

  bool get hasAnyPhone =>
      mobilePhone != null || landlinePhone != null || supportPhone != null;
}

// ============================================================
// صفحه‌ی نمایش فیلم اقامتگاه
// ============================================================

class ResidenceVideoPage extends StatefulWidget {
  const ResidenceVideoPage({super.key, required this.data});

  final ResidenceVideoData data;

  @override
  State<ResidenceVideoPage> createState() => _ResidenceVideoPageState();
}

class _ResidenceVideoPageState extends State<ResidenceVideoPage> {
  ResidenceVideoData get _d => widget.data;

  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---------- نمایش فیلم ----------
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _AparatEmbedPlayer(aparatHash: _d.aparatHash),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleBlock(),
                  const SizedBox(height: 16),

                  // ---------- متن توضیحات (بیشتر/بازگشت) ----------
                  if (_d.description.trim().isNotEmpty) ...[
                    _descriptionBlock(),
                    const SizedBox(height: 22),
                  ],

                  // ---------- مسیریابی ----------
                  SizedBox(
                    width: double.infinity,
                    child: _gradientButton(
                      icon: Icons.map_rounded,
                      label: 'مسیریابی سریع',
                      colors: const [_teal, _tealBright],
                      textColor: const Color(0xff03202a),
                      onTap: _openRoute,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---------- هواشناسی ----------
                  _ResidenceWeatherButton(
                    city: _d.city,
                    province: _d.province,
                  ),
                  const SizedBox(height: 12),

                  // ---------- تماس مستقیم ----------
                  if (_d.hasAnyPhone) ...[
                    SizedBox(
                      width: double.infinity,
                      child: _outlinedIconButton(
                        icon: Icons.call_rounded,
                        label: 'تماس مستقیم',
                        onTap: _openContactSheet,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ---------- اینستاگرام ----------
                  if (_d.instagramUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: _linkRow(
                        icon: Icons.camera_alt_rounded,
                        label: 'اینستاگرام',
                        onTap: () => _openUrl(context, _d.instagramUrl!),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ---------- وب‌سایت ----------
                  if (_d.websiteUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: _linkRow(
                        icon: Icons.public_rounded,
                        label: 'وب‌سایت',
                        onTap: () => _openUrl(context, _d.websiteUrl!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- عنوان + امتیاز ----------

  Widget _titleBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _d.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _goldBright, size: 15),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _d.province != null
                          ? '${_d.city}، ${_d.province}'
                          : _d.city,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _goldBright,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_d.rating != null) _ratingBadge(),
      ],
    );
  }

  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldA(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _gold, size: 16),
              const SizedBox(width: 3),
              Text(
                _d.rating!.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (_d.ratingCount != null) ...[
            const SizedBox(height: 2),
            Text(
              '${_d.ratingCount} رأی',
              style: const TextStyle(color: Colors.white38, fontSize: 9.5),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- توضیحات با بیشتر/بازگشت ----------

  Widget _descriptionBlock() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _d.description,
            maxLines: _descriptionExpanded ? null : 3,
            overflow: _descriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _descriptionExpanded = !_descriptionExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _descriptionExpanded
                        ? Icons.undo_rounded
                        : Icons.expand_more_rounded,
                    color: _gold,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _descriptionExpanded ? 'بازگشت' : 'بیشتر',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- مسیریابی ----------

  void _openRoute() {
    if (_d.latitude != null && _d.longitude != null) {
      HapticFeedback.selectionClick();
      final url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${_d.latitude},${_d.longitude}';
      _openUrl(context, url);
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmartMapPage()),
    );
  }

  // ---------- تماس مستقیم (فقط انتقال به برنامه‌ی تلفن) ----------

  void _openContactSheet() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                '📞 تماس مستقیم — یک شماره را انتخاب کنید',
                style: TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              if (_d.mobilePhone != null)
                _contactOption(
                  icon: Icons.smartphone_rounded,
                  label: 'تلفن همراه',
                  phone: _d.mobilePhone!,
                ),
              if (_d.landlinePhone != null)
                _contactOption(
                  icon: Icons.phone_rounded,
                  label: 'تلفن ثابت',
                  phone: _d.landlinePhone!,
                ),
              if (_d.supportPhone != null)
                _contactOption(
                  icon: Icons.support_agent_rounded,
                  label: 'تلفن پشتیبان',
                  phone: _d.supportPhone!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactOption({
    required IconData icon,
    required String label,
    required String phone,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        // فقط برنامه‌ی تلفن گوشی را با شماره باز می‌کند — تماس
        // خودکار برقرار نمی‌شود (بدون نیاز به مجوز CALL_PHONE)،
        // دقیقاً مطابق بخش پشتیبانی (کلید ۹).
        _openUrl(context, 'tel:$phone');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xff103b50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _brandGradient),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5)),
                  Text(phone,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  // ---------- ویجت‌های مشترک ----------

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinedIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13.5)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: _goldA(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldA(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 19),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13.5)),
            const Spacer(),
            const Icon(Icons.chevron_left_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// دکمه/آیکون هواشناسی — بر اساس نام شهر اقامتگاه (نه GPS کاربر)
// ============================================================
//
// با تپ روی دکمه، ابتدا نام شهر با Nominatim به مختصات تبدیل
// می‌شود (forward geocoding)، سپس آب‌وهوای همان مختصات از
// Open-Meteo گرفته می‌شود. نتیجه فقط یک‌بار کش می‌شود.

class _ResidenceWeatherButton extends StatefulWidget {
  const _ResidenceWeatherButton({required this.city, this.province});

  final String city;
  final String? province;

  @override
  State<_ResidenceWeatherButton> createState() =>
      _ResidenceWeatherButtonState();
}

class _ResidenceWeatherButtonState extends State<_ResidenceWeatherButton> {
  bool _expanded = false;
  bool _loading = false;
  bool _failed = false;
  bool _loaded = false;

  double? _temperature;
  int? _weatherCode;
  int? _humidity;
  double? _windSpeed;

  void _toggle() {
    HapticFeedback.selectionClick();

    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() => _expanded = true);

    if (!_loaded) _loadWeather();
  }

  void _retry() {
    setState(() {
      _loaded = false;
      _failed = false;
    });
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final coords = await _geocodeCity();

      if (coords == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
          _loaded = true;
        });
        return;
      }

      final weather = await _fetchWeather(coords[0], coords[1]);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loaded = true;
        _failed = weather == null;
        _temperature = (weather?['temperature'] as num?)?.toDouble();
        _weatherCode = (weather?['weathercode'] as num?)?.toInt();
        _humidity = (weather?['humidity'] as num?)?.toInt();
        _windSpeed = (weather?['windspeed'] as num?)?.toDouble();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _loaded = true;
      });
    }
  }

  Future<List<double>?> _geocodeCity() async {
    final query = widget.province != null
        ? '${widget.city}, ${widget.province}, ایران'
        : '${widget.city}, ایران';

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'accept-language': 'fa',
    });

    final client = HttpClient();
    try {
      client.userAgent = 'CyrusTourist/1.0 (cyrustourist.ir)';
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = jsonDecode(body);

      if (data is! List || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lon == null) return null;

      return [lat, lon];
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _fetchWeather(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(const Utf8Decoder()).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;

      if (current == null) return null;

      return {
        'temperature': current['temperature_2m'],
        'weathercode': current['weather_code'],
        'humidity': current['relative_humidity_2m'],
        'windspeed': current['wind_speed_10m'],
      };
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _weatherEmoji(int? code) {
    if (code == null) return '🌡️';
    if (code == 0) return '☀️';
    if (code == 1 || code == 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 57) return '🌦️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '🌨️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code == 85 || code == 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }

  String _weatherLabel(int? code) {
    if (code == null) return 'نامشخص';
    if (code == 0) return 'صاف';
    if (code == 1) return 'کمی ابری';
    if (code == 2) return 'نیمه‌ابری';
    if (code == 3) return 'ابری';
    if (code == 45 || code == 48) return 'مه‌آلود';
    if (code >= 51 && code <= 57) return 'نم‌نم باران';
    if (code >= 61 && code <= 67) return 'بارانی';
    if (code >= 71 && code <= 77) return 'برفی';
    if (code >= 80 && code <= 82) return 'رگبار';
    if (code == 85 || code == 86) return 'رگبار برف';
    if (code >= 95) return 'رعدوبرق';
    return 'نامشخص';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff103b50), Color(0xff0d2432)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldA(0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _goldBright, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'آب‌وهوای ${widget.city}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (_loaded && !_failed && _temperature != null) ...[
                    Text(_weatherEmoji(_weatherCode),
                        style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 4),
                    Text(
                      '${_temperature!.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _gold),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _weatherBody(),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _weatherBody() {
    if (_loading) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _gold),
          ),
          SizedBox(width: 10),
          Text('در حال دریافت آب‌وهوا…',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
    }

    if (_failed) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('دریافت آب‌وهوا ممکن نشد.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          TextButton(
            onPressed: _retry,
            child: const Text('تلاش دوباره', style: TextStyle(color: _gold)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _weatherLabel(_weatherCode),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        if (_humidity != null)
          Text('💧 $_humidity٪',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        if (_windSpeed != null) ...[
          const SizedBox(width: 10),
          Text('🌬️ ${_windSpeed!.round()} km/h',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        ],
      ],
    );
  }
}

// ============================================================
// پخش‌کننده‌ی عمومی آپارات — مخصوص این صفحه
// ============================================================

class _AparatEmbedPlayer extends StatefulWidget {
  const _AparatEmbedPlayer({required this.aparatHash});

  final String aparatHash;

  @override
  State<_AparatEmbedPlayer> createState() => _AparatEmbedPlayerState();
}

class _AparatEmbedPlayerState extends State<_AparatEmbedPlayer> {
  late WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant _AparatEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aparatHash != widget.aparatHash) {
      _createController();
    }
  }

  void _createController() {
    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.aparatHash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failed = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains('aparat.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: _gold),
          ),
        if (_failed)
          Container(
            color: _bg,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _gold, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'پخش ویدیو بارگذاری نشد',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _failed = false;
                      _loading = true;
                    });
                    _controller.reload();
                  },
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
