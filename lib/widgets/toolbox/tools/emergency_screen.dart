import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/location_manager.dart';
import 'tool_ui.dart';

class _EmergencyNumber {
  const _EmergencyNumber(this.number, this.title, this.subtitle, this.icon, this.color);

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

/// شماره‌های اضطراری ایران + ارسال موقعیت فعلی.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  static const List<_EmergencyNumber> _numbers = [
    _EmergencyNumber('115', 'اورژانس', 'حوادث و فوریت‌های پزشکی',
        Icons.medical_services_rounded, Color(0xffff6262)),
    _EmergencyNumber('110', 'پلیس', 'مرکز فوریت‌های پلیسی',
        Icons.local_police_rounded, Color(0xff72d6ff)),
    _EmergencyNumber('125', 'آتش‌نشانی', 'آتش‌سوزی و حوادث',
        Icons.fire_truck_rounded, Color(0xffffa24d)),
    _EmergencyNumber('112', 'هلال احمر', 'امداد و نجات',
        Icons.health_and_safety_rounded, Color(0xffff8585)),
    _EmergencyNumber('197', 'پلیس راهور', 'تصادف و اطلاعات ترافیک',
        Icons.traffic_rounded, Color(0xff75e0a0)),
  ];

  bool _sharing = false;

  Future<void> _call(String number) async {
    final ok = await launchUrl(
      Uri.parse('tel:$number'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      showToolSnack(context, 'امکان برقراری تماس وجود ندارد.');
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _sharing = true);

    final location = await LocationManager.getCurrentLocation();

    if (!mounted) return;
    setState(() => _sharing = false);

    if (location == null) {
      showToolSnack(
        context,
        'موقعیت شما در دسترس نیست. GPS و دسترسی موقعیت را روشن کنید.',
      );
      return;
    }

    final lat = location.latitude.toStringAsFixed(6);
    final lng = location.longitude.toStringAsFixed(6);

    await Share.share(
      'به کمک نیاز دارم. موقعیت من:\n'
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng\n'
      '($lat, $lng)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'کمک فوری در سفر',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          GestureDetector(
            onTap: _sharing ? null : _shareLocation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xffc62828), Color(0xff7f1616)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _sharing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_location_rounded,
                          color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ارسال موقعیت فعلی من',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'لینک نقشه را برای همراهان یا امدادگر بفرستید',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final item in _numbers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _call(item.number),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: toolCardDecoration(border: item.color),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color.withValues(alpha: 0.16),
                          border: Border.all(color: item.color),
                        ),
                        child: Icon(item.icon, color: item.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        toPersianDigits(item.number),
                        style: TextStyle(
                          color: item.color,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.call_rounded, color: item.color),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'این شماره‌ها مخصوص ایران است. در سفر به کشورهای دیگر شماره‌های اضطراری محلی متفاوت است.',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.8),
          ),
        ],
      ),
    );
  }
}
