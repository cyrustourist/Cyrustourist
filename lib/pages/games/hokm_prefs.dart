import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تنظیمات ظاهری و صدای «حکم»؛ روی همان گوشی ذخیره می‌شود.
class HokmPrefs extends ChangeNotifier {
  HokmPrefs._();
  static final HokmPrefs instance = HokmPrefs._();

  static const String _k = 'hokm4_prefs';

  int bg = 0; // زمینه
  int face = 0; // روی کارت
  int back = 0; // پشت کارت
  int snd = 0; // مدل صدا
  int vol = 70;
  bool mute = false;
  bool vib = true;
  int speed = 50;
  int target = 7;
  String name = 'کوروش';
  String avatar = '0'; // اندیس آواتار یا عکس base64

  static const List<String> bgNames = <String>['چوب', 'سبز نمدی', 'آبی', 'فرش قرمز', 'مشکی و طلایی', 'بنفش', 'فیروزه‌ای', 'ماسه‌ای'];
  static const List<String> faceNames = <String>['کلاسیک', 'چهاررنگ', 'تیره', 'کرمی قدیمی', 'مدرن'];
  static const List<String> backNames = <String>['آبی گل‌دار', 'قرمز', 'سبز', 'طلایی هندسی', 'بنفش', 'مشکی لوزی', 'فیروزه‌ای'];
  static const List<String> sndNames = <String>['کلاسیک', 'چوبی', 'دیجیتال', 'زنگوله'];

  /// آواتارهای آماده: ایموجی و دو رنگ پس‌زمینه
  static const List<List<Object>> avatars = <List<Object>>[
    <Object>['🧔', Color(0xffe08a3c), Color(0xffa04a12)],
    <Object>['👩', Color(0xffe0508a), Color(0xff8a1a50)],
    <Object>['👨‍🦱', Color(0xff3c8ae0), Color(0xff124a8a)],
    <Object>['👩‍🦰', Color(0xffe0643c), Color(0xff8a2a12)],
    <Object>['🧑‍💼', Color(0xff3cb58a), Color(0xff126a4a)],
    <Object>['👴', Color(0xff8a8a9a), Color(0xff4a4a5a)],
    <Object>['👵', Color(0xffb07ad6), Color(0xff5a2a8a)],
    <Object>['🧕', Color(0xff3cc0c0), Color(0xff127070)],
    <Object>['🦁', Color(0xffe0b03c), Color(0xff8a6612)],
    <Object>['🐯', Color(0xffe08030), Color(0xff8a3a0a)],
    <Object>['🦊', Color(0xffe05a3c), Color(0xff8a200a)],
    <Object>['🐼', Color(0xff99aaaa), Color(0xff444455)],
  ];

  static int _ci(dynamic v, int lo, int hi, int d) {
    if (v is! num) return d;
    final i = v.toInt();
    return i < lo ? lo : (i > hi ? hi : i);
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        bg = _ci(m['bg'], 0, bgNames.length - 1, 0);
        face = _ci(m['face'], 0, faceNames.length - 1, 0);
        back = _ci(m['back'], 0, backNames.length - 1, 0);
        snd = _ci(m['snd'], 0, sndNames.length - 1, 0);
        vol = _ci(m['vol'], 0, 100, 70);
        mute = m['mute'] == true;
        vib = m['vib'] != false;
        speed = _ci(m['speed'], 10, 100, 50);
        target = _ci(m['target'], 3, 21, 7);
        name = (m['name'] as String?)?.trim().isNotEmpty == true ? m['name'] as String : 'کوروش';
        avatar = (m['avatar'] as String?) ?? '0';
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode(<String, dynamic>{
          'bg': bg,
          'face': face,
          'back': back,
          'snd': snd,
          'vol': vol,
          'mute': mute,
          'vib': vib,
          'speed': speed,
          'target': target,
          'name': name,
          'avatar': avatar,
        }),
      );
    } catch (_) {}
  }
}

// ----------------------------------------------------------------------------
// صدا: موج‌ها در خود برنامه ساخته می‌شوند (بدون فایل صوتی) و با audioplayers پخش می‌شوند.

class HokmSfx {
  HokmSfx._();
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static int _next = 0;
  static const int _rate = 22050;

  static Future<void> _player(Uint8List wav, double vol) async {
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        }
      }
      final p = _pool[_next++ % _pool.length];
      await p.setVolume(vol);
      await p.play(BytesSource(wav));
    } catch (_) {}
  }

  static void vibrate([int ms = 60]) {
    final pr = HokmPrefs.instance;
    if (pr.vib) HapticFeedback.mediumImpact();
  }

  /// ev: play, deal, win, lose, turn, pick, chat, hand, over, click
  static void play(String ev) {
    final pr = HokmPrefs.instance;
    if (pr.mute && ev != 'preview') return;
    final key = '${pr.snd}-$ev';
    final w = _cache.putIfAbsent(key, () => _build(pr.snd, ev));
    _player(w, pr.vol / 100);
  }

  static Uint8List _build(int model, String ev) {
    final notes = <_N>[];
    void tone(double f, double d, {String w = 'sine', double v = .5, double t = 0, double? f2}) => notes.add(_N(f, d, w, v, t, f2));
    void noise(double d, {double v = .4, double t = 0, double lp = 1}) => notes.add(_N(0, d, 'noise', v, t, null, lp));
    void bell(double f, {double d = .5, double v = .4, double t = 0}) {
      tone(f, d, v: v, t: t);
      tone(f * 2.76, d * .6, v: v * .4, t: t);
    }

    switch (model) {
      case 1: // چوبی
        switch (ev) {
          case 'play':
            noise(.09, v: .8, lp: .12);
            tone(150, .08, v: .6, f2: 70);
          case 'deal':
            for (var i = 0; i < 4; i++) {
              noise(.06, v: .5, t: i * .09, lp: .1);
            }
          case 'win':
            tone(196, .2, v: .6, f2: 150);
            tone(262, .3, t: .12, v: .5);
          case 'lose':
            tone(120, .4, v: .6, f2: 70);
          case 'turn':
            tone(330, .1, v: .4);
            tone(330, .1, v: .4, t: .14);
          case 'pick':
            tone(220, .12, v: .6, f2: 160);
            tone(330, .2, t: .1, v: .5);
          case 'chat':
            tone(500, .08, v: .3, f2: 420);
          case 'hand':
            tone(262, .25, v: .5);
            tone(330, .25, t: .15, v: .5);
            tone(392, .4, t: .3, v: .5);
          case 'over':
            tone(262, .3, v: .6);
            tone(330, .3, t: .18, v: .6);
            tone(392, .3, t: .36, v: .6);
            tone(523, .6, t: .54, v: .6);
          default:
            noise(.03, v: .5, lp: .1);
        }
      case 2: // دیجیتال
        switch (ev) {
          case 'play':
            tone(900, .04, w: 'sq', v: .25);
            tone(500, .05, w: 'sq', v: .25, t: .04);
          case 'deal':
            for (var i = 0; i < 4; i++) {
              tone(600.0 + i * 120, .04, w: 'sq', v: .2, t: i * .06);
            }
          case 'win':
            tone(520, .07, w: 'sq', v: .25);
            tone(780, .07, w: 'sq', v: .25, t: .07);
            tone(1040, .12, w: 'sq', v: .25, t: .14);
          case 'lose':
            tone(400, .25, w: 'saw', v: .25, f2: 120);
          case 'turn':
            tone(1200, .05, w: 'sq', v: .2);
            tone(1600, .07, w: 'sq', v: .2, t: .07);
          case 'pick':
            tone(700, .05, w: 'sq', v: .25);
            tone(1400, .1, w: 'sq', v: .25, t: .06);
          case 'chat':
            tone(1500, .04, w: 'sq', v: .15);
          case 'hand':
            for (var i = 0; i < 4; i++) {
              tone(const <double>[523, 659, 784, 1047][i], .08, w: 'sq', v: .22, t: i * .07);
            }
          case 'over':
            for (var i = 0; i < 8; i++) {
              tone(400.0 + i * 90, .09, w: 'sq', v: .22, t: i * .07);
            }
          default:
            tone(1000, .025, w: 'sq', v: .15);
        }
      case 3: // زنگوله
        switch (ev) {
          case 'play':
            noise(.05, v: .3, lp: .6);
            bell(1320, d: .25, v: .2);
          case 'deal':
            for (var i = 0; i < 4; i++) {
              bell(1568.0 + i * 90, d: .2, v: .15, t: i * .08);
            }
          case 'win':
            bell(784);
            bell(988, t: .12, v: .4);
          case 'lose':
            bell(392, d: .7, v: .35);
          case 'turn':
            bell(1175, d: .3, v: .3);
          case 'pick':
            bell(880, d: .4);
            bell(1319, d: .4, t: .1, v: .35);
          case 'chat':
            bell(1568, d: .2, v: .2);
          case 'hand':
            bell(659);
            bell(784, t: .15, v: .4);
            bell(988, d: .7, t: .3, v: .4);
          case 'over':
            for (var i = 0; i < 4; i++) {
              bell(const <double>[523, 659, 784, 1047][i], d: .9, v: .4, t: i * .16);
            }
          default:
            bell(1760, d: .12, v: .15);
        }
      default: // کلاسیک
        switch (ev) {
          case 'play':
            noise(.08, v: .7, lp: .5);
            tone(180, .05, v: .3);
          case 'deal':
            for (var i = 0; i < 5; i++) {
              noise(.05, v: .45, t: i * .07, lp: .6);
            }
          case 'win':
            tone(523, .14, w: 'tri', v: .5);
            tone(659, .14, w: 'tri', v: .5, t: .1);
            tone(784, .22, w: 'tri', v: .5, t: .2);
          case 'lose':
            tone(300, .3, w: 'tri', v: .5, f2: 200);
          case 'turn':
            tone(440, .12, v: .45);
            tone(587, .16, v: .45, t: .1);
          case 'pick':
            tone(784, .1, w: 'tri', v: .5);
            tone(1047, .18, w: 'tri', v: .5, t: .08);
          case 'chat':
            tone(900, .07, v: .3);
          case 'hand':
            for (var i = 0; i < 4; i++) {
              tone(const <double>[523, 659, 784, 1047][i], .18, w: 'tri', v: .5, t: i * .09);
            }
          case 'over':
            for (var i = 0; i < 6; i++) {
              tone(const <double>[523, 659, 784, 1047, 784, 1047][i], .25, w: 'tri', v: .55, t: i * .12);
            }
          default:
            tone(700, .04, w: 'sq', v: .15);
        }
    }
    return _wav(notes);
  }

  static Uint8List _wav(List<_N> notes) {
    var total = 0.0;
    for (final n in notes) {
      total = max(total, n.t + n.d);
    }
    final count = (total * _rate).ceil() + 200;
    final buf = List<double>.filled(count, 0);
    final rnd = Random(7);
    for (final n in notes) {
      final start = (n.t * _rate).round();
      final len = (n.d * _rate).round();
      var phase = 0.0;
      var lp = 0.0;
      for (var i = 0; i < len && start + i < count; i++) {
        final x = i / len;
        final env = (i < 200 ? i / 200 : 1.0) * pow(1 - x, 2.2);
        double s;
        if (n.w == 'noise') {
          lp += n.lp * ((rnd.nextDouble() * 2 - 1) - lp);
          s = lp;
        } else {
          final f = n.f2 == null ? n.f : n.f * pow(n.f2! / n.f, x);
          phase += 2 * pi * f / _rate;
          final sn = sin(phase);
          switch (n.w) {
            case 'sq':
              s = sn >= 0 ? 1 : -1;
            case 'saw':
              s = ((phase / (2 * pi)) % 1) * 2 - 1;
            case 'tri':
              s = asin(sn) * 2 / pi;
            default:
              s = sn;
          }
        }
        buf[start + i] += s * env * n.v;
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

class _N {
  _N(this.f, this.d, this.w, this.v, this.t, this.f2, [this.lp = 1]);
  final double f;
  final double d;
  final String w;
  final double v;
  final double t;
  final double? f2;
  final double lp;
}
