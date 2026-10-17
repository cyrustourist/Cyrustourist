import 'package:flutter/material.dart';
import '../../../services/safe_prefs.dart';

import 'tool_ui.dart';

class _Group {
  const _Group(this.title, this.icon, this.items);

  final String title;
  final IconData icon;
  final List<String> items;
}

/// چک‌لیست سفر — با امکان افزودن مورد دلخواه؛ در گوشی ذخیره می‌شود.
class PackingChecklistScreen extends StatefulWidget {
  const PackingChecklistScreen({super.key});

  @override
  State<PackingChecklistScreen> createState() => _PackingChecklistScreenState();
}

class _PackingChecklistScreenState extends State<PackingChecklistScreen> {
  static const String _kChecked = 'cyrus_packing_checked';
  static const String _kCustom = 'cyrus_packing_custom';

  static const List<_Group> _groups = [
    _Group('مدارک و پول', Icons.badge_rounded, [
      'کارت ملی یا پاسپورت',
      'بلیت و رزرو اقامتگاه',
      'کارت بانکی و مقداری پول نقد',
      'بیمه مسافرتی',
      'شماره تماس‌های مهم',
    ]),
    _Group('سلامت', Icons.health_and_safety_rounded, [
      'داروهای شخصی',
      'کیت کمک‌های اولیه',
      'ماسک و ضدعفونی‌کننده',
      'کرم ضدآفتاب',
    ]),
    _Group('وسایل', Icons.backpack_rounded, [
      'شارژر و پاوربانک',
      'لباس مناسب هوای مقصد',
      'کفش راحت',
      'کیف کوچک روزانه',
      'بطری آب',
      'عینک آفتابی و کلاه',
    ]),
  ];

  final TextEditingController _newItem = TextEditingController();

  Set<String> _checked = {};
  List<String> _custom = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _checked = (prefs.getStringList(_kChecked) ?? const <String>[]).toSet();
      _custom = prefs.getStringList(_kCustom) ?? <String>[];
    } catch (_) {
      // بدون ذخیره‌سازی هم صفحه کار می‌کند.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kChecked, _checked.toList());
      await prefs.setStringList(_kCustom, _custom);
    } catch (_) {}
  }

  int get _total =>
      _groups.fold<int>(0, (sum, g) => sum + g.items.length) + _custom.length;

  int get _done {
    final all = <String>{
      for (final g in _groups) ...g.items,
      ..._custom,
    };
    return _checked.where(all.contains).length;
  }

  void _toggle(String item) {
    setState(() {
      if (!_checked.remove(item)) _checked.add(item);
    });
    _save();
  }

  void _addCustom() {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;

    final exists = _custom.contains(text) ||
        _groups.any((g) => g.items.contains(text));

    if (!exists) {
      setState(() => _custom.add(text));
      _save();
    }
    _newItem.clear();
  }

  void _removeCustom(String item) {
    setState(() {
      _custom.remove(item);
      _checked.remove(item);
    });
    _save();
  }

  void _resetChecks() {
    setState(() => _checked.clear());
    _save();
  }

  Widget _itemTile(String item, {bool removable = false}) {
    final checked = _checked.contains(item);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _toggle(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? const Color(0xff22e0ad) : Colors.transparent,
                border: Border.all(
                  color: checked ? const Color(0xff22e0ad) : Colors.white38,
                  width: 1.6,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xff03202a))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  color: checked ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (removable)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _removeCustom(item),
                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: toolCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kToolGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: kToolGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final done = _done;

    return ToolScaffold(
      title: 'چک‌لیست سفر',
      actions: [
        IconButton(
          tooltip: 'پاک کردن تیک‌ها',
          onPressed: _resetChecks,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: kToolGold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: toolCardDecoration(border: Colors.greenAccent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${toPersianDigits('$done')} از ${toPersianDigits('$total')} آماده است',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          color: const Color(0xff22e0ad),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final group in _groups)
                  _groupCard(
                    group.title,
                    group.icon,
                    [for (final item in group.items) _itemTile(item)],
                  ),
                _groupCard(
                  'مورد دلخواه من',
                  Icons.edit_note_rounded,
                  [
                    for (final item in _custom) _itemTile(item, removable: true),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newItem,
                              style: const TextStyle(color: Colors.white),
                              decoration: toolInputDecoration('مورد جدید'),
                              onSubmitted: (_) => _addCustom(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addCustom,
                            style: IconButton.styleFrom(
                              backgroundColor: kToolGold,
                              foregroundColor: const Color(0xff071722),
                            ),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
