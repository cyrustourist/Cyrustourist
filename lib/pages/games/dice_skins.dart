import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شکل کلی تاس
enum DiceStyle { classic, glossy, glass, wood, gem, neon }

/// شکل نقطه‌های روی تاس
enum PipShape { circle, ring, square, diamond }

/// ظاهر تاس. خرید با سکه از فروشگاه (سرور فهرست «dice_*» را نگه می‌دارد)، انتخاب روی همین گوشی ذخیره می‌شود.
/// تاس‌های رایگان (قیمت ۰) بدون سرور و بدون اینترنت قابل انتخاب‌اند.
class DiceSkin {
  const DiceSkin(
    this.key,
    this.code,
    this.price,
    this.level,
    this.faName,
    this.enName,
    this.face,
    this.pip,
    this.edge, {
    this.face2,
    this.style = DiceStyle.classic,
    this.pipShape = PipShape.circle,
    this.glow = false,
  });
  final String key;
  final String code;
  final int price;
  final int level;
  final String faName;
  final String enName;
  final Color face;
  final Color pip;
  final Color edge;

  /// رنگ دوم برای سایه‌روشن (اختیاری)
  final Color? face2;
  final DiceStyle style;
  final PipShape pipShape;

  /// درخشش نئونی دور تاس و نقطه‌ها
  final bool glow;
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
    // ---- مدل‌های تازه (رایگان) ----
    DiceSkin('dice_ocean', 'ocean', 0, 1, 'اقیانوس', 'Ocean', Color(0xff2b95f0), Color(0xffffffff), Color(0xff0b3a7a),
        face2: Color(0xff0d47a1), style: DiceStyle.glossy),
    DiceSkin('dice_sakura', 'sakura', 0, 1, 'شکوفه', 'Sakura', Color(0xffffb3d1), Color(0xffffffff), Color(0xffb8386f),
        face2: Color(0xffe0558f), style: DiceStyle.glossy, pipShape: PipShape.ring),
    DiceSkin('dice_sunset', 'sunset', 0, 1, 'غروب', 'Sunset', Color(0xffffa63d), Color(0xffffffff), Color(0xffb3123f),
        face2: Color(0xffe0245e), style: DiceStyle.glossy),
    DiceSkin('dice_mint', 'mint', 0, 1, 'نعنایی', 'Mint', Color(0xff86e8cc), Color(0xff0b4a3a), Color(0xff1c8a6c),
        face2: Color(0xff2bb38f), style: DiceStyle.glossy, pipShape: PipShape.square),
    DiceSkin('dice_ice', 'ice', 0, 1, 'یخی', 'Ice', Color(0xffe6f7ff), Color(0xff1565c0), Color(0xff6bb8e8),
        face2: Color(0xff8fd0ff), style: DiceStyle.glossy, pipShape: PipShape.diamond),
    DiceSkin('dice_walnut', 'walnut', 0, 1, 'چوب گردو', 'Walnut', Color(0xffc08040), Color(0xfffff3da), Color(0xff4a2a10),
        face2: Color(0xff7a4720), style: DiceStyle.wood),
    DiceSkin('dice_royal', 'royal', 0, 1, 'شاهانه', 'Royal', Color(0xff6a2fb8), Color(0xffffd54a), Color(0xffffc400),
        face2: Color(0xff2d1060), style: DiceStyle.gem, pipShape: PipShape.diamond),
    DiceSkin('dice_crystal', 'crystal', 0, 1, 'بلور', 'Crystal', Color(0x88aee6ff), Color(0xff12507a), Color(0xddffffff),
        face2: Color(0x88ffffff), style: DiceStyle.glass),
    DiceSkin('dice_neon', 'neon', 0, 1, 'نئون', 'Neon', Color(0xff0a1030), Color(0xff39f0ff), Color(0xff00d4ff),
        style: DiceStyle.neon, glow: true),
    DiceSkin('dice_lava', 'lava', 0, 1, 'گدازه', 'Lava', Color(0xff2b0a0a), Color(0xffff8a2a), Color(0xffff3d00),
        style: DiceStyle.neon, pipShape: PipShape.ring, glow: true),
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
