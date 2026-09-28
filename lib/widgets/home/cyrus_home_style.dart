import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ==========================================================
/// Cyrus Tourist — تنظیمات ظاهری صفحه اصلی
/// (رنگ برنامه، حالت شب/روز، شدت انیمیشن، افکت صدای لمس)
/// ==========================================================
///
/// همان کلیدهای ذخیره‌سازی طرح HTML استفاده شده:
/// cyrusColorMode / cyrusDisplayMode / cyrusAnimationMode / cyrusSoundMode

enum CyrusColorMode { gold, blue, emerald, purple, red, cyan }

enum CyrusDisplayMode { night, day }

enum CyrusAnimationMode { smooth, low, off }

enum CyrusSoundMode { classic, soft, gold, silent }

class CyrusPalette {
  const CyrusPalette(this.accent, this.text);
  final Color accent;
  final Color text;
}

const Map<CyrusColorMode, CyrusPalette> kCyrusPalettes = {
  CyrusColorMode.gold: CyrusPalette(Color(0xfff2cf5b), Color(0xfff7f1d0)),
  CyrusColorMode.blue: CyrusPalette(Color(0xff55b9ff), Color(0xffe7f6ff)),
  CyrusColorMode.emerald: CyrusPalette(Color(0xff49d6a3), Color(0xffe6fff6)),
  CyrusColorMode.purple: CyrusPalette(Color(0xffc48cff), Color(0xfff7edff)),
  CyrusColorMode.red: CyrusPalette(Color(0xffff7777), Color(0xfffff0f0)),
  CyrusColorMode.cyan: CyrusPalette(Color(0xff4de7e7), Color(0xffe8ffff)),
};

class CyrusHomeStyle extends ChangeNotifier {
  CyrusHomeStyle._();

  static final CyrusHomeStyle instance = CyrusHomeStyle._();

  static const _kColor = 'cyrusColorMode';
  static const _kDisplay = 'cyrusDisplayMode';
  static const _kAnimation = 'cyrusAnimationMode';
  static const _kSound = 'cyrusSoundMode';

  CyrusColorMode color = CyrusColorMode.gold;
  CyrusDisplayMode display = CyrusDisplayMode.night;
  // پیش‌فرض طرح: «کم»
  CyrusAnimationMode animation = CyrusAnimationMode.low;
  CyrusSoundMode sound = CyrusSoundMode.classic;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      color = _byName(CyrusColorMode.values, p.getString(_kColor), color);
      display = _byName(CyrusDisplayMode.values, p.getString(_kDisplay), display);
      animation = _byName(CyrusAnimationMode.values, p.getString(_kAnimation), animation);
      sound = _byName(CyrusSoundMode.values, p.getString(_kSound), sound);
      notifyListeners();
    } catch (_) {
      // بدون ذخیره‌سازی هم برنامه با مقادیر پیش‌فرض کار می‌کند.
    }
  }

  T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Future<void> _save(String key, String value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, value);
    } catch (_) {}
  }

  void setColor(CyrusColorMode v) {
    color = v;
    _save(_kColor, v.name);
    notifyListeners();
  }

  void setDisplay(CyrusDisplayMode v) {
    display = v;
    _save(_kDisplay, v.name);
    notifyListeners();
  }

  void setAnimation(CyrusAnimationMode v) {
    animation = v;
    _save(_kAnimation, v.name);
    notifyListeners();
  }

  void setSound(CyrusSoundMode v) {
    sound = v;
    _save(_kSound, v.name);
    notifyListeners();
    playTap();
  }

  // ---------------- مقادیر مشتق‌شده ----------------

  bool get isDay => display == CyrusDisplayMode.day;

  Color get accent => kCyrusPalettes[color]!.accent;

  Color get accentText => kCyrusPalettes[color]!.text;

  Color get titleColor => isDay ? const Color(0xff16233a) : accentText;

  Color get labelColor => isDay ? const Color(0xff24364f) : const Color(0xfffff0c2);

  Color get mutedColor => isDay ? const Color(0xff52647c) : const Color(0xffaeb8cf);

  Color get bodyTextColor => isDay ? const Color(0xff24364f) : const Color(0xffc4cce0);

  Color get cardTextColor => isDay ? const Color(0xff24364f) : const Color(0xfffff0c7);

  List<Color> get pageGradient => isDay
      ? const [Color(0xfff7fbff), Color(0xffeaf2fa), Color(0xffdfe9f3)]
      : const [Color(0xff050b1b), Color(0xff07132c), Color(0xff040916)];

  List<Color> get cardGradient => isDay
      ? const [Color(0xffffffff), Color(0xffe8f0f8)]
      : const [Color(0xff112751), Color(0xff071329)];

  List<Color> get panelGradient => isDay
      ? const [Color(0xfff7fbff), Color(0xffdfeaf4)]
      : const [Color(0xff102751), Color(0xff050d1d)];

  List<Color> get carouselGradient => isDay
      ? const [Color(0xfff9fcff), Color(0xffdce9f5)]
      : const [Color(0xff15376f), Color(0xff09162f)];

  Color get noteBackground => isDay ? const Color(0xddffffff) : const Color(0xd907142b);

  Color get optionBackground => isDay ? const Color(0xffedf3f9) : const Color(0xff07142e);

  Color get optionText => isDay ? const Color(0xff334861) : const Color(0xffdfe6f5);

  Color get footerColor => isDay ? const Color(0xff65758b) : const Color(0xff7f8aa4);

  Color get shadowColor => isDay ? const Color(0x33718096) : const Color(0x99000000);

  Duration get sweepDuration => animation == CyrusAnimationMode.low
      ? const Duration(seconds: 14)
      : const Duration(seconds: 8);

  bool get sweepEnabled => animation != CyrusAnimationMode.off;

  Duration get slideFade => animation == CyrusAnimationMode.off
      ? Duration.zero
      : Duration(milliseconds: animation == CyrusAnimationMode.low ? 1000 : 650);

  // ---------------- افکت صدا/لمس ----------------
  // بدون افزودن پکیج صوتی جدید: از صدای سیستمی + لرزش سبک استفاده می‌شود.
  void playTap() {
    switch (sound) {
      case CyrusSoundMode.silent:
        return;
      case CyrusSoundMode.classic:
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.selectionClick();
        break;
      case CyrusSoundMode.soft:
        HapticFeedback.selectionClick();
        break;
      case CyrusSoundMode.gold:
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        break;
    }
  }
}
