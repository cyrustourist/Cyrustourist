import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صدا و لرزش بازی‌ها. صداها در خود برنامه ساخته می‌شوند (بدون فایل صوتی).
/// هر دسته چند گزینه دارد و انتخاب کاربر روی گوشی ذخیره می‌شود.
class GameFx {
  GameFx._();

  static const String _pref = 'cyrus_game_fx';
  static const String _pDice = 'cyrus_fx_dice';
  static const String _pMove = 'cyrus_fx_move';
  static const String _pWin = 'cyrus_fx_win';
  static const String _pVol = 'cyrus_fx_vol';

  static bool on = true;
  static String dice = 'wood';
  static String moveSound = 'wood';
  static String winSound = 'fanfare';
  static int vol = 80;

  /// گزینه‌ها: کد و نام فارسی
  static const List<List<String>> diceOptions = <List<String>>[
    <String>['wood', 'تاس چوبی'],
    <String>['plastic', 'تاس پلاستیکی'],
    <String>['cup', 'تاس داخل لیوان'],
    <String>['off', 'بدون صدا'],
  ];
  static const List<List<String>> moveOptions = <List<String>>[
    <String>['wood', 'تق چوبی'],
    <String>['soft', 'نرم'],
    <String>['pop', 'پاپ'],
    <String>['off', 'بدون صدا'],
  ];
  static const List<List<String>> winOptions = <List<String>>[
    <String>['fanfare', 'فانفار'],
    <String>['applause', 'تشویق و کف‌زدن'],
    <String>['fireworks', 'آتش‌بازی'],
    <String>['off', 'بدون صدا'],
  ];

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      on = p.getBool(_pref) ?? true;
      dice = p.getString(_pDice) ?? 'wood';
      moveSound = p.getString(_pMove) ?? 'wood';
      winSound = p.getString(_pWin) ?? 'fanfare';
      vol = p.getInt(_pVol) ?? 80;
    } catch (_) {}
  }

  static Future<void> toggle() async {
    on = !on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_pref, on);
    } catch (_) {}
  }

  /// ذخیره‌ی انتخاب‌های صدا (از برگهٔ تنظیم صدا)
  static Future<void> saveSounds({required bool enabled, required String diceCode, required String moveCode, required String winCode, required int volume}) async {
    on = enabled;
    dice = diceCode;
    moveSound = moveCode;
    winSound = winCode;
    vol = volume;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_pref, on);
      await p.setString(_pDice, dice);
      await p.setString(_pMove, moveSound);
      await p.setString(_pWin, winSound);
      await p.setInt(_pVol, vol);
    } catch (_) {}
  }

  /// پیش‌نمایش یک صدا (حتی اگر صدا خاموش باشد)
  static void preview(String kind, String code) {
    if (code == 'off') return;
    _go(_wav('$kind:$code'));
  }

  static void roll() {
    if (!on) return;
    if (dice != 'off') _go(_wav('dice:$dice'));
    HapticFeedback.selectionClick();
  }

  static void move() {
    if (!on) return;
    if (moveSound != 'off') _go(_wav('move:$moveSound'));
    HapticFeedback.lightImpact();
  }

  static void hit() {
    if (!on) return;
    if (moveSound != 'off') _go(_wav('hit:$moveSound'));
    HapticFeedback.heavyImpact();
  }

  static void win() {
    if (!on) return;
    if (winSound != 'off') _go(_wav('win:$winSound'));
    HapticFeedback.vibrate();
    Future<void>.delayed(const Duration(milliseconds: 220), HapticFeedback.heavyImpact);
  }

  // ------------------------------------------------------------------ پخش

  static const int _rate = 22050;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static int _next = 0;

  static Uint8List _wav(String key) => _cache.putIfAbsent(key, () => _build(key));

  static Future<void> _go(Uint8List wav) async {
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        }
      }
      final p = _pool[_next++ % _pool.length];
      await p.setVolume(vol / 100);
      await p.play(BytesSource(wav));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  // ------------------------------------------------------------------ ساخت موج

  static Uint8List _build(String key) {
    final ev = <_E>[];
    final r = Random(key.hashCode);
    void tone(double t, double d, double f, double v, {double? f2}) => ev.add(_E(t, d, f, v, false, tone: true, f2: f2));
    void tock(double t, double f, double v, [double d = .07]) => ev.add(_E(t, d, f, v, false));
    void noise(double t, double d, double v, [double lp = .45]) => ev.add(_E(t, d, 0, v, true, lp: lp));
    switch (key) {
      // ---- تاس
      case 'dice:wood':
        var t = 0.0;
        for (var i = 0; i < 14; i++) {
          noise(t, .035, .5 + r.nextDouble() * .3);
          tock(t, 600 + r.nextDouble() * 500, .25, .03);
          t += .035 + r.nextDouble() * .03 + i * .002;
        }
        tock(t, 190, .6, .09);
        break;
      case 'dice:plastic':
        var t = 0.0;
        for (var i = 0; i < 12; i++) {
          tone(t, .03, 1800 + r.nextDouble() * 900, .28);
          noise(t, .02, .3, .8);
          t += .04 + r.nextDouble() * .03;
        }
        tone(t, .06, 900, .4);
        break;
      case 'dice:cup':
        var t = 0.0;
        for (var i = 0; i < 18; i++) {
          noise(t, .05, .55 + r.nextDouble() * .3, .25);
          tock(t, 300 + r.nextDouble() * 200, .3, .05);
          t += .05 + r.nextDouble() * .04;
        }
        tock(t + .05, 140, .6, .12);
        noise(t + .05, .08, .5, .2);
        break;
      // ---- حرکت مهره
      case 'move:wood':
        tock(0, 150, .55, .07);
        noise(0, .03, .45);
        break;
      case 'move:soft':
        tock(0, 220, .4, .09);
        break;
      case 'move:pop':
        tone(0, .09, 400, .5, f2: 900);
        break;
      // ---- زدن مهره
      case 'hit:wood':
        tock(0, 120, .7, .1);
        noise(0, .06, .6);
        tock(.1, 95, .5, .12);
        break;
      case 'hit:soft':
        tock(0, 110, .6, .14);
        tock(.1, 90, .4, .12);
        break;
      case 'hit:pop':
        tone(0, .14, 900, .5, f2: 200);
        break;
      // ---- برد
      case 'win:fanfare':
        const n = <double>[523, 659, 784, 1047, 784, 1047, 1319];
        for (var i = 0; i < n.length; i++) {
          tone(i * .12, i == n.length - 1 ? .5 : .2, n[i], .45);
          tone(i * .12, i == n.length - 1 ? .5 : .2, n[i] * 2, .12);
        }
        break;
      case 'win:applause':
        for (var i = 0; i < 70; i++) {
          noise(i * .03 + r.nextDouble() * .02, .02 + r.nextDouble() * .02, .25 + r.nextDouble() * .4, .9);
        }
        tone(.0, .3, 784, .25);
        tone(.15, .45, 1047, .25);
        break;
      case 'win:fireworks':
        tone(0, .5, 300, .35, f2: 1500);
        for (var k = 0; k < 3; k++) {
          final t0 = .55 + k * .35;
          noise(t0, .18, .7, .3);
          tone(t0, .3, 880 + k * 220, .3, f2: 440);
          for (var i = 0; i < 12; i++) {
            noise(t0 + .05 + i * .02, .02, .3, .9);
          }
        }
        break;
      default:
        tock(0, 700, .3, .03);
    }
    return _toWav(ev, r);
  }

  static Uint8List _toWav(List<_E> ev, Random rnd) {
    var total = 0.0;
    for (final e in ev) {
      total = max(total, e.t + e.d);
    }
    final count = (total * _rate).ceil() + 300;
    final buf = List<double>.filled(count, 0);
    for (final e in ev) {
      final start = (e.t * _rate).round();
      final len = (e.d * _rate).round();
      var phase = 0.0;
      var lp = 0.0;
      for (var i = 0; i < len && start + i < count; i++) {
        final x = i / len;
        final env = (i < 60 ? i / 60 : 1.0) * pow(1 - x, e.tone ? 1.6 : 3.2);
        double s;
        if (e.rattle) {
          lp += e.lp * ((rnd.nextDouble() * 2 - 1) - lp);
          s = lp;
        } else {
          final f = e.f2 == null ? e.f : e.f * pow(e.f2! / e.f, x);
          phase += 2 * pi * f / _rate;
          s = sin(phase);
        }
        buf[start + i] += s * env * e.v;
      }
    }
    final data = ByteData(44 + count * 2);
    void str(int o, String t) {
      for (var i = 0; i < t.length; i++) {
        data.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + count * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, count * 2, Endian.little);
    for (var i = 0; i < count; i++) {
      final v = (buf[i].clamp(-1.0, 1.0) * 30000).round();
      data.setInt16(44 + i * 2, v, Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

class _E {
  _E(this.t, this.d, this.f, this.v, this.rattle, {this.tone = false, this.f2, this.lp = .45});
  final double t;
  final double d;
  final double f;
  final double v;
  final bool rattle;
  final bool tone;
  final double? f2;
  final double lp;
}
