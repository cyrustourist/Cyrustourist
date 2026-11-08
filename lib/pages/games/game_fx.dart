import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صدا و لرزش بازی‌ها (بدون فایل صوتی و بدون بسته‌ی اضافه؛ از صدای سیستم و لرزش گوشی استفاده می‌کند).
class GameFx {
  GameFx._();

  static const String _pref = 'cyrus_game_fx';
  static bool on = true;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      on = p.getBool(_pref) ?? true;
    } catch (_) {}
  }

  static Future<void> toggle() async {
    on = !on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_pref, on);
    } catch (_) {}
  }

  static void roll() {
    if (!on) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  static void move() {
    if (!on) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  static void hit() {
    if (!on) return;
    HapticFeedback.heavyImpact();
  }

  static void win() {
    if (!on) return;
    HapticFeedback.vibrate();
    Future<void>.delayed(const Duration(milliseconds: 220), HapticFeedback.heavyImpact);
  }
}
