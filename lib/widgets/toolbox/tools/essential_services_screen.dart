import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tool_ui.dart';

class _Service {
  const _Service(this.title, this.query, this.icon, this.color);

  final String title;
  final String query;
  final IconData icon;
  final Color color;
}

/// خدمات ضروری نزدیک من — جستجو در برنامه‌ی نقشه‌ی گوشی.
class EssentialServicesScreen extends StatelessWidget {
  const EssentialServicesScreen({super.key});

  static const List<_Service> _services = [
    _Service('بیمارستان', 'بیمارستان', Icons.local_hospital_rounded, Color(0xffff6262)),
    _Service('داروخانه', 'داروخانه', Icons.medication_rounded, Color(0xff75e0a0)),
    _Service('پلیس', 'پلیس', Icons.local_police_rounded, Color(0xff72d6ff)),
    _Service('خودپرداز', 'خودپرداز', Icons.atm_rounded, Color(0xffffd76a)),
    _Service('پمپ بنزین', 'پمپ بنزین', Icons.local_gas_station_rounded, Color(0xffffa24d)),
    _Service('دستشویی عمومی', 'سرویس بهداشتی عمومی', Icons.wc_rounded, Color(0xffc9a7ff)),
    _Service('مکانیکی', 'مکانیکی خودرو', Icons.car_repair_rounded, Color(0xff91c7ff)),
    _Service('سوپرمارکت', 'سوپرمارکت', Icons.storefront_rounded, Color(0xff9be27a)),
  ];

  Future<void> _search(BuildContext context, _Service service) async {
    final query = Uri.encodeComponent(service.query);

    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('geo:0,0?q=$query'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }

    if (!ok) {
      try {
        ok = await launchUrl(
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        ok = false;
      }
    }

    if (!ok && context.mounted) {
      showToolSnack(context, 'برنامه‌ی نقشه‌ای برای باز کردن پیدا نشد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'خدمات ضروری نزدیک من',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'یک گزینه را لمس کنید تا نزدیک‌ترین موارد در برنامه‌ی نقشه‌ی گوشی شما باز شود.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.8),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final service in _services)
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _search(context, service),
                  child: Container(
                    decoration: toolCardDecoration(border: service.color),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: service.color.withValues(alpha: 0.16),
                            border: Border.all(color: service.color),
                          ),
                          child: Icon(service.icon, color: service.color, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          service.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
