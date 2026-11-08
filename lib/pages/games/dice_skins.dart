import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ظاهر تاس. خرید با سکه از فروشگاه (سرور فهرست «dice_*» را نگه می‌دارد)، انتخاب روی همین گوشی ذخیره می‌شود.
class DiceSkin {
  const DiceSkin(this.key, this.code, this.price, this.level, this.faName, this.enName, this.face, this.pip, this.edge);
  final String key;
  final String code;
  final int price;
  final int level;
  final String faName;
  final String enName;
  final Color face;
  final Color pip;
  final Color edge;
}

class DiceSkins {
  DiceSkins._();

  static const String _pref = 'cyrus_dice_skin';

  static const List<DiceSkin> all = <DiceSkin>[
    DiceSkin('dice_ivory', 'ivory', 0, 1, 'عاجی', 'Ivory', Color(0xfffffbf0), Color(0xff1b1b1b), Color(0xffcfc5a8)),
    DiceSkin('dice_ruby', 'ruby', 80, 1, 'یاقوت', 'Ruby', Color(0xffd62839), Color(0xffffffff), Color(0xff8f1420)),
    DiceSkin('dice_emerald', 'emerald', 150, 2, 'زمرد', 'Emerald', Color(0xff1f9d6a), Color(0xfff5fff9), Color(0xff0f6b45)),
    DiceSkin('dice_gold', 'gold', 300, 3, 'زرین', 'Gold', Color(0xfff2c14e), Color(0xff4a3200), Color(0xffb98a1a)),
    DiceSkin('dice_obsidian', 'obsidian', 450, 4, 'سنگ شب', 'Obsidian', Color(0xff23262f), Color(0xfff2d36b), Color(0xff0e1016)),
    DiceSkin('dice_aurora', 'aurora', 600, 5, 'شفق', 'Aurora', Color(0xff6b5bff), Color(0xffffffff), Color(0xff3e2fc9)),
  ];

  /// کد تاس انتخاب‌شده
  static final ValueNotifier<String> current = ValueNotifier<String>('ivory');

  static DiceSkin byCode(String code) => all.firstWhere((s) => s.code == code, orElse: () => all.first);
  static DiceSkin get skin => byCode(current.value);

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final c = p.getString(_pref);
      if (c != null && all.any((s) => s.code == c)) current.value = c;
    } catch (_) {}
  }

  static Future<void> select(String code) async {
    current.value = code;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_pref, code);
    } catch (_) {}
  }
}
