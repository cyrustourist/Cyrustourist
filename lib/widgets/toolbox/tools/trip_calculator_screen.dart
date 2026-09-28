import 'package:flutter/material.dart';

import 'tool_ui.dart';

/// محاسبه‌گر سفر جاده‌ای: زمان، سوخت و هزینه‌ی تقریبی.
class TripCalculatorScreen extends StatefulWidget {
  const TripCalculatorScreen({super.key});

  @override
  State<TripCalculatorScreen> createState() => _TripCalculatorScreenState();
}

class _TripCalculatorScreenState extends State<TripCalculatorScreen> {
  final TextEditingController _distance = TextEditingController();
  final TextEditingController _speed = TextEditingController(text: '80');
  final TextEditingController _consumption = TextEditingController(text: '9');
  final TextEditingController _fuelPrice = TextEditingController();
  final TextEditingController _extra = TextEditingController();
  final TextEditingController _people = TextEditingController(text: '1');

  @override
  void dispose() {
    _distance.dispose();
    _speed.dispose();
    _consumption.dispose();
    _fuelPrice.dispose();
    _extra.dispose();
    _people.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: toolInputDecoration(label, suffix: suffix),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? Colors.white : Colors.white70,
                fontSize: strong ? 15 : 13.5,
                fontWeight: strong ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong ? kToolGold : Colors.white,
              fontSize: strong ? 18 : 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = parseNumber(_distance.text);
    final speed = parseNumber(_speed.text);
    final consumption = parseNumber(_consumption.text);
    final price = parseNumber(_fuelPrice.text) ?? 0;
    final extra = parseNumber(_extra.text) ?? 0;
    final people = (parseNumber(_people.text) ?? 1).clamp(1, 100).round();

    final hasResult =
        distance != null && distance > 0 && speed != null && speed > 0;

    String duration = '—';
    double liters = 0;
    double fuelCost = 0;
    double total = 0;

    if (distance != null && speed != null && hasResult) {
      final totalMinutes = (distance / speed * 60).round();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      duration = toPersianDigits(
        hours > 0 ? '$hours ساعت و $minutes دقیقه' : '$minutes دقیقه',
      );

      liters = distance * (consumption ?? 0) / 100;
      fuelCost = liters * price;
      total = fuelCost + extra;
    }

    return ToolScaffold(
      title: 'محاسبه‌گر سفر',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: toolCardDecoration(),
            child: Column(
              children: [
                _field(_distance, 'مسافت', suffix: 'کیلومتر'),
                _field(_speed, 'سرعت متوسط', suffix: 'کیلومتر/ساعت'),
                _field(_consumption, 'مصرف سوخت خودرو', suffix: 'لیتر/۱۰۰ کیلومتر'),
                _field(_fuelPrice, 'قیمت هر لیتر سوخت', suffix: 'تومان'),
                _field(_extra, 'هزینه‌های دیگر (عوارض، غذا...)', suffix: 'تومان'),
                _field(_people, 'تعداد مسافران'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: toolCardDecoration(border: Colors.greenAccent),
            child: hasResult
                ? Column(
                    children: [
                      _resultRow('زمان تقریبی رانندگی', duration),
                      _resultRow('سوخت مصرفی',
                          '${toPersianDigits(liters.toStringAsFixed(1))} لیتر'),
                      _resultRow(
                          'هزینه سوخت', '${formatThousands(fuelCost)} تومان'),
                      const Divider(color: Colors.white12),
                      _resultRow('هزینه کل', '${formatThousands(total)} تومان',
                          strong: true),
                      _resultRow('سهم هر نفر',
                          '${formatThousands(total / people)} تومان',
                          strong: true),
                    ],
                  )
                : const Text(
                    'مسافت و سرعت را وارد کنید تا نتیجه نمایش داده شود.',
                    style: TextStyle(color: Colors.white54, height: 1.8),
                  ),
          ),
          const SizedBox(height: 12),
          const Text(
            'محاسبه بر اساس مسافت مستقیم ورودی است؛ توقف‌ها و ترافیک در زمان لحاظ نشده است.',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.8),
          ),
        ],
      ),
    );
  }
}
