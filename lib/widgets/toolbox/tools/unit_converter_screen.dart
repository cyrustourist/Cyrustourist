import 'package:flutter/material.dart';

import 'tool_ui.dart';

class _Unit {
  const _Unit(this.id, this.name, this.factor);

  final String id;
  final String name;

  /// ضریب تبدیل به واحد پایه‌ی همان دسته.
  final double factor;
}

class _Category {
  const _Category(this.name, this.icon, this.units, {this.isTemperature = false});

  final String name;
  final IconData icon;
  final List<_Unit> units;
  final bool isTemperature;
}

/// تبدیل واحدها: مسافت، وزن، دما، حجم، سرعت.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const List<_Category> _categories = [
    _Category('مسافت', Icons.straighten_rounded, [
      _Unit('km', 'کیلومتر', 1000),
      _Unit('m', 'متر', 1),
      _Unit('mi', 'مایل', 1609.344),
      _Unit('ft', 'فوت', 0.3048),
      _Unit('in', 'اینچ', 0.0254),
    ]),
    _Category('وزن', Icons.scale_rounded, [
      _Unit('kg', 'کیلوگرم', 1),
      _Unit('g', 'گرم', 0.001),
      _Unit('lb', 'پوند', 0.45359237),
      _Unit('oz', 'اونس', 0.028349523125),
    ]),
    _Category('دما', Icons.thermostat_rounded, [
      _Unit('c', 'سانتی‌گراد', 1),
      _Unit('f', 'فارنهایت', 1),
      _Unit('k', 'کلوین', 1),
    ], isTemperature: true),
    _Category('حجم', Icons.local_drink_rounded, [
      _Unit('l', 'لیتر', 1),
      _Unit('ml', 'میلی‌لیتر', 0.001),
      _Unit('gal', 'گالن آمریکا', 3.785411784),
    ]),
    _Category('سرعت', Icons.speed_rounded, [
      _Unit('kmh', 'کیلومتر بر ساعت', 1),
      _Unit('mph', 'مایل بر ساعت', 1.609344),
      _Unit('ms', 'متر بر ثانیه', 3.6),
      _Unit('kn', 'گره دریایی', 1.852),
    ]),
  ];

  final TextEditingController _input = TextEditingController(text: '1');

  int _category = 0;
  int _from = 0;
  int _to = 1;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  double? _convert() {
    final value = parseNumber(_input.text);
    if (value == null) return null;

    final category = _categories[_category];
    final from = category.units[_from];
    final to = category.units[_to];

    if (category.isTemperature) {
      double celsius;
      switch (from.id) {
        case 'f':
          celsius = (value - 32) * 5 / 9;
          break;
        case 'k':
          celsius = value - 273.15;
          break;
        default:
          celsius = value;
      }

      switch (to.id) {
        case 'f':
          return celsius * 9 / 5 + 32;
        case 'k':
          return celsius + 273.15;
        default:
          return celsius;
      }
    }

    return value * from.factor / to.factor;
  }

  String _format(double value) {
    if (value == 0) return '۰';

    String text;
    if (value.abs() >= 1e9 || value.abs() < 1e-4) {
      text = value.toStringAsExponential(4);
    } else {
      text = value.toStringAsFixed(4);
      if (text.contains('.')) {
        text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    }
    return toPersianDigits(text);
  }

  Widget _unitDropdown(int selected, ValueChanged<int> onChanged) {
    final units = _categories[_category].units;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xff0b202c),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kToolGold.withValues(alpha: 0.30)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          isExpanded: true,
          dropdownColor: const Color(0xff102838),
          iconEnabledColor: kToolGold,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: [
            for (var i = 0; i < units.length; i++)
              DropdownMenuItem(value: i, child: Text(units[i].name)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _convert();
    final category = _categories[_category];

    return ToolScaffold(
      title: 'تبدیل واحدها',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _categories[index];
                final selected = index == _category;
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    item.icon,
                    size: 18,
                    color: selected ? const Color(0xff071722) : kToolGold,
                  ),
                  label: Text(item.name),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xff071722) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedColor: kToolGold,
                  backgroundColor: kToolCard,
                  side: BorderSide(color: kToolGold.withValues(alpha: 0.4)),
                  onSelected: (_) => setState(() {
                    _category = index;
                    _from = 0;
                    _to = 1;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: toolCardDecoration(),
            child: Column(
              children: [
                TextField(
                  controller: _input,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: toolInputDecoration('مقدار'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _unitDropdown(_from, (v) => setState(() => _from = v)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: IconButton(
                    onPressed: () => setState(() {
                      final tmp = _from;
                      _from = _to;
                      _to = tmp;
                    }),
                    icon: const Icon(Icons.swap_vert_rounded, color: kToolGold, size: 30),
                  ),
                ),
                _unitDropdown(_to, (v) => setState(() => _to = v)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: toolCardDecoration(border: Colors.greenAccent),
            child: Column(
              children: [
                Text(
                  category.units[_to].name,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  result == null ? '—' : _format(result),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
