import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'bg_theme.dart';
import 'game_fx.dart';

/// صدای تخته‌نرد: تاس (قل خوردن و نشستن)، حرکت مهره، زدن مهره، خروج مهره، برد و باخت و پیام چت.
/// موج‌ها در خود برنامه ساخته می‌شوند و نیازی به فایل صوتی نیست.
class BgSfx {
  BgSfx._();

  static const int _rate = 22050;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static int _next = 0;

  static bool get _on => GameFx.on && !BgPrefs.instance.mute;

  static void _play(String key) {
    if (!_on) return;
    final w = _cache.putIfAbsent(key, () => _build(key));
    _go(w);
  }

  static Future<void> _go(Uint8List wav) async {
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        }
      }
      final p = _pool[_next++ % _pool.length];
      await p.setVolume(BgPrefs.instance.vol / 100);
      await p.play(BytesSource(wav));
    } catch (_) {}
  }

  static void _haptic(bool heavy) {
    if (!_on || !BgPrefs.instance.vib) return;
    if (heavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// تاس در حال قل خوردن (هنگام انداختن)
  static void diceRoll() {
    _play('roll');
    _haptic(false);
  }

  /// تاس نشست
  static void diceLand() {
    _play('land');
    _haptic(true);
  }

  static void move() {
    _play('move');
    _haptic(false);
  }

  static void hit() {
    _play('hit');
    _haptic(true);
  }

  static void bearOff() {
    _play('off');
    _haptic(false);
  }

  static void win() {
    _play('win');
    _haptic(true);
  }

  static void lose() => _play('lose');

  static void chat() => _play('chat');

  static void click() => _play('click');

  // ------------------------------------------------------------------ ساخت موج

  static Uint8List _build(String key) {
    final ev = <_E>[];
    final r = Random(key.hashCode);
    void tock(double t, double f, double v, [double d = .07]) => ev.add(_E(t, d, f, v, false));
    void rattle(double t, double d, double v) => ev.add(_E(t, d, 0, v, true));
    switch (key) {
      case 'roll':
        // تاس‌ها در دست و روی چوب: ضربه‌های ریز پشت سر هم با فاصله‌ی نامنظم
        var t = 0.0;
        for (var i = 0; i < 16; i++) {
          rattle(t, .035, .5 + r.nextDouble() * .3);
          tock(t, 600 + r.nextDouble() * 500, .25, .03);
          t += .035 + r.nextDouble() * .03 + i * .002;
        }
        break;
      case 'land':
        tock(0, 190, .6, .09);
        rattle(0, .05, .5);
        tock(.11, 240, .35, .07);
        rattle(.11, .04, .35);
        tock(.2, 300, .2, .05);
        break;
      case 'move':
        tock(0, 150, .55, .07);
        rattle(0, .03, .45);
        break;
      case 'hit':
        tock(0, 120, .7, .1);
        rattle(0, .06, .6);
        tock(.1, 95, .5, .12);
        break;
      case 'off':
        tock(0, 260, .45, .06);
        tock(.07, 340, .4, .06);
        break;
      case 'win':
        for (var i = 0; i < 4; i++) {
          ev.add(_E(i * .11, .22, const <double>[523, 659, 784, 1047][i], .45, false, tone: true));
        }
        break;
      case 'lose':
        ev.add(_E(0, .35, 300, .45, false, tone: true, f2: 190));
        break;
      case 'chat':
        ev.add(_E(0, .08, 900, .3, false, tone: true));
        ev.add(_E(.09, .1, 1200, .3, false, tone: true));
        break;
      default:
        tock(0, 700, .3, .03);
    }
    return _wav(ev, r);
  }

  static Uint8List _wav(List<_E> ev, Random rnd) {
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
        final env = (i < 60 ? i / 60 : 1.0) * pow(1 - x, e.tone ? 1.8 : 3.2);
        double s;
        if (e.rattle) {
          lp += .45 * ((rnd.nextDouble() * 2 - 1) - lp);
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
  _E(this.t, this.d, this.f, this.v, this.rattle, {this.tone = false, this.f2});
  final double t;
  final double d;
  final double f;
  final double v;
  final bool rattle;
  final bool tone;
  final double? f2;
}
