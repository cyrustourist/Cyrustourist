import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/games/game_economy.dart';
import '../pages/games/game_wheel.dart';
import '../pages/games/hokm_prefs.dart';
import '../pages/groups/group_ui.dart';

/// تنظیمات، ارتقاها، سکه و صدای «مسابقات گروهی آفلاین» (هاکی و مینی‌گلف).
/// همه‌چیز روی همان گوشی ذخیره می‌شود و از کیف سکه‌ی موجود برنامه (GameEconomy) استفاده می‌کند.
class GgPrefs extends ChangeNotifier {
  GgPrefs._();
  static final GgPrefs instance = GgPrefs._();
  static const String _k = 'gg_prefs_v1';

  // ------------------------------------------------------------- رنگ‌ها و تم‌ها
  static const List<Color> palette = <Color>[
    Color(0xff29e0ad),
    Color(0xff66d9ff),
    Color(0xffffd36a),
    Color(0xffff5d73),
    Color(0xffb36bff),
    Color(0xffff8a3d),
    Color(0xff7dff4f),
    Color(0xffffffff),
  ];
  static const List<String> paletteNames = <String>['فیروزه‌ای', 'آبی یخی', 'طلایی', 'قرمز', 'بنفش', 'نارنجی', 'سبز لیمویی', 'سفید'];
  static const int freeColors = 4;
  static const int colorPrice = 60;
  static const int themePrice = 100;
  static const int freeThemes = 2;

  /// هاکی: [زمینه، دیواره‌ی ۱ تا ۴]
  static const List<String> hkThemeNames = <String>['نئون چهاررنگ', 'آبی یخی', 'سبز زمردی', 'بنفش شب', 'طلایی شاهانه', 'قرمز آتشین'];
  static const List<List<Color>> hkThemes = <List<Color>>[
    <Color>[Color(0xff02060c), Color(0xffffe03a), Color(0xff39ff5a), Color(0xff2bb5ff), Color(0xffff3b4e)],
    <Color>[Color(0xff03101e), Color(0xff66d9ff), Color(0xff9be7ff), Color(0xff4db8ff), Color(0xff7ee0ff)],
    <Color>[Color(0xff03140c), Color(0xff29e0ad), Color(0xff7dff4f), Color(0xff2bd68a), Color(0xffb5ff6b)],
    <Color>[Color(0xff0b0516), Color(0xffb36bff), Color(0xffff6bd6), Color(0xff7a6bff), Color(0xffd96bff)],
    <Color>[Color(0xff120d02), Color(0xffffd36a), Color(0xffffe9a8), Color(0xffffc233), Color(0xfff2b84a)],
    <Color>[Color(0xff140404), Color(0xffff5d73), Color(0xffff8a3d), Color(0xffff3b4e), Color(0xffffb347)],
  ];

  /// گلف: [چمن روشن، چمن تیره، دیواره]
  static const List<String> gfThemeNames = <String>['چمن کلاسیک', 'بیابان', 'شب', 'برفی', 'شکلاتی صورتی', 'شاهانه'];
  static const List<List<Color>> gfThemes = <List<Color>>[
    <Color>[Color(0xff2fa82f), Color(0xff278a27), Color(0xff8a4a22)],
    <Color>[Color(0xffe0b765), Color(0xffd1a24e), Color(0xff8a5a2b)],
    <Color>[Color(0xff1d6b5b), Color(0xff155449), Color(0xff2b3a55)],
    <Color>[Color(0xffeaf3f7), Color(0xffd5e5ee), Color(0xff6c8ea3)],
    <Color>[Color(0xffff9ecb), Color(0xffff7fb8), Color(0xff9a4bd1)],
    <Color>[Color(0xff4b3fa8), Color(0xff3b3190), Color(0xffffd36a)],
  ];

  // ------------------------------------------------------------- مقادیر ذخیره‌شده
  String name = '';
  int hkTheme = 0;
  int hkMallet = 0;
  int hkPuck = 1;
  bool hkTrail = true;
  bool hkFx = true;
  int hkSpeed = 1; // 0 کند، 1 معمولی، 2 تند
  int gfTheme = 0;
  int gfBall = 3;
  bool gfAim = true;
  int gfSens = 100;
  bool gfNames = true;
  int vol = 70;
  bool mute = false;
  bool vib = true;
  int quality = 1; // 0 کم، 1 بالا
  final Map<String, int> ups = <String, int>{};
  String _day = '';
  int _dayEarned = 0;
  bool _loaded = false;

  static const int dailyCap = 300;

  Future<void> load() async {
    if (_loaded) return;
    try {
      await HokmPrefs.instance.load();
    } catch (_) {}
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        int gi(String k, int d, int lo, int hi) => ((m[k] as num?)?.toInt() ?? d).clamp(lo, hi);
        name = (m['name'] as String?) ?? '';
        hkTheme = gi('hkTheme', 0, 0, hkThemes.length - 1);
        hkMallet = gi('hkMallet', 0, 0, palette.length - 1);
        hkPuck = gi('hkPuck', 1, 0, palette.length - 1);
        hkTrail = (m['hkTrail'] as bool?) ?? true;
        hkFx = (m['hkFx'] as bool?) ?? true;
        hkSpeed = gi('hkSpeed', 1, 0, 2);
        gfTheme = gi('gfTheme', 0, 0, gfThemes.length - 1);
        gfBall = gi('gfBall', 3, 0, palette.length - 1);
        gfAim = (m['gfAim'] as bool?) ?? true;
        gfSens = gi('gfSens', 100, 50, 150);
        gfNames = (m['gfNames'] as bool?) ?? true;
        vol = gi('vol', 70, 0, 100);
        mute = (m['mute'] as bool?) ?? false;
        vib = (m['vib'] as bool?) ?? true;
        quality = gi('quality', 1, 0, 1);
        _day = (m['day'] as String?) ?? '';
        _dayEarned = (m['earned'] as num?)?.toInt() ?? 0;
        ups.clear();
        final u = m['ups'];
        if (u is Map) u.forEach((k, v) => ups['$k'] = (v as num).toInt());
      }
    } catch (_) {}
    if (name.trim().isEmpty) name = HokmPrefs.instance.name;
    _loaded = true;
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode(<String, dynamic>{
          'name': name,
          'hkTheme': hkTheme,
          'hkMallet': hkMallet,
          'hkPuck': hkPuck,
          'hkTrail': hkTrail,
          'hkFx': hkFx,
          'hkSpeed': hkSpeed,
          'gfTheme': gfTheme,
          'gfBall': gfBall,
          'gfAim': gfAim,
          'gfSens': gfSens,
          'gfNames': gfNames,
          'vol': vol,
          'mute': mute,
          'vib': vib,
          'quality': quality,
          'day': _day,
          'earned': _dayEarned,
          'ups': ups,
        }),
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------- مالکیت (خرید با سکه)
  bool ownsColor(int i) => i < freeColors || GameEconomy.isOwned('gg_col_$i');
  bool ownsTheme(String game, int i) => i < freeThemes || GameEconomy.isOwned('gg_th_${game}_$i');

  Future<bool> buyColor(BuildContext c, int i) async {
    await GameEconomy.load();
    if (ownsColor(i)) return true;
    return GameEconomy.buy(c, 'gg_col_$i', colorPrice, 'رنگ ${paletteNames[i]}');
  }

  Future<bool> buyTheme(BuildContext c, String game, int i, String title) async {
    await GameEconomy.load();
    if (ownsTheme(game, i)) return true;
    return GameEconomy.buy(c, 'gg_th_${game}_$i', themePrice, 'تم $title');
  }

  // ------------------------------------------------------------- ارتقا (فقط حالت تک‌نفره)
  static const int maxLevel = 5;
  static const Map<String, String> upTitles = <String, String>{
    'hk_size': 'اندازه‌ی دسته (هاکی)',
    'hk_power': 'قدرت ضربه (هاکی)',
    'gf_power': 'قدرت ضربه (گلف)',
    'gf_aim': 'طول خط هدف (گلف)',
  };
  static const Map<String, String> upDescs = <String, String>{
    'hk_size': 'دسته‌ی بزرگ‌تر، دفاع راحت‌تر',
    'hk_power': 'ضربه‌های تندتر به توپ',
    'gf_power': 'ضربه‌ی بلندتر با همان کشیدن',
    'gf_aim': 'خط هدف‌گیری بلندتر',
  };

  int lvl(String k) => ups[k] ?? 0;
  int upCost(String k) => 40 * (lvl(k) + 1);

  Future<bool> upgrade(BuildContext c, String k) async {
    await GameEconomy.load();
    if (lvl(k) >= maxLevel) {
      gToast(c, 'به بالاترین سطح رسیده است');
      return false;
    }
    final ok = await GameEconomy.pay(c, upCost(k), upTitles[k] ?? k);
    if (!ok) return false;
    ups[k] = lvl(k) + 1;
    await save();
    return true;
  }

  // ------------------------------------------------------------- جایزه
  /// سکه‌ی جایزه با سقف روزانه‌ی ۳۰۰؛ خروجی: سکه‌ی واقعاً داده‌شده.
  Future<int> reward(int base) async {
    await GameEconomy.load();
    final today = WheelStore.dayKey(DateTime.now());
    if (_day != today) {
      _day = today;
      _dayEarned = 0;
    }
    var n = base;
    if (_dayEarned + n > dailyCap) n = dailyCap - _dayEarned;
    if (n <= 0) return 0;
    _dayEarned += n;
    await WheelStore.instance.addCoins(n);
    await save();
    return n;
  }
}

// ----------------------------------------------------------------------------
// صدا: موج‌ها در خود برنامه ساخته می‌شوند (بدون فایل صوتی) تا حجم بازی صفر بماند.

class GgSfx {
  GgSfx._();
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static int _next = 0;
  static const int _rate = 22050;

  static void buzz() {
    if (GgPrefs.instance.vib) HapticFeedback.lightImpact();
  }

  /// ev: hit, wall, goal, win, lose, click, putt, sink, splash, tick
  static void play(String ev) {
    final p = GgPrefs.instance;
    if (p.mute || p.vol <= 0) return;
    final w = _cache.putIfAbsent(ev, () => _build(ev));
    _player(w, p.vol / 100);
  }

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

  // هر نت: [شروع، مدت، فرکانس، فرکانس پایان، بلندی، نوع(0 سینوس،1 مربعی،2 نویز)]
  static Uint8List _build(String ev) {
    final List<List<double>> n;
    switch (ev) {
      case 'hit':
        n = <List<double>>[<double>[0, .07, 620, 320, .8, 0]];
        break;
      case 'wall':
        n = <List<double>>[<double>[0, .05, 260, 180, .5, 1]];
        break;
      case 'goal':
        n = <List<double>>[<double>[0, .12, 440, 440, .7, 0], <double>[.12, .12, 554, 554, .7, 0], <double>[.24, .25, 659, 659, .8, 0]];
        break;
      case 'win':
        n = <List<double>>[<double>[0, .12, 523, 523, .7, 0], <double>[.12, .12, 659, 659, .7, 0], <double>[.24, .12, 784, 784, .7, 0], <double>[.36, .3, 1047, 1047, .8, 0]];
        break;
      case 'lose':
        n = <List<double>>[<double>[0, .18, 392, 392, .6, 0], <double>[.18, .3, 294, 262, .6, 0]];
        break;
      case 'putt':
        n = <List<double>>[<double>[0, .05, 300, 150, .7, 0], <double>[0, .03, 0, 0, .3, 2]];
        break;
      case 'sink':
        n = <List<double>>[<double>[0, .08, 700, 500, .6, 0], <double>[.08, .2, 880, 880, .7, 0]];
        break;
      case 'splash':
        n = <List<double>>[<double>[0, .25, 0, 0, .5, 2]];
        break;
      case 'tick':
        n = <List<double>>[<double>[0, .03, 900, 900, .35, 1]];
        break;
      default:
        n = <List<double>>[<double>[0, .04, 700, 700, .35, 1]];
    }
    return _wav(n);
  }

  static Uint8List _wav(List<List<double>> notes) {
    var total = 0.0;
    for (final n in notes) {
      total = max(total, n[0] + n[1]);
    }
    final count = (total * _rate).ceil() + 200;
    final buf = List<double>.filled(count, 0);
    final rnd = Random(7);
    for (final n in notes) {
      final start = (n[0] * _rate).round();
      final len = (n[1] * _rate).round();
      var phase = 0.0;
      var lp = 0.0;
      for (var i = 0; i < len && start + i < count; i++) {
        final x = i / len;
        final env = (i < 150 ? i / 150 : 1.0) * pow(1 - x, 2.0);
        double s;
        if (n[5] == 2) {
          lp += .25 * ((rnd.nextDouble() * 2 - 1) - lp);
          s = lp * 2;
        } else {
          final f = n[2] + (n[3] - n[2]) * x;
          phase += 2 * pi * f / _rate;
          s = sin(phase);
          if (n[5] == 1) s = s >= 0 ? 1 : -1;
        }
        buf[start + i] += s * env * n[4] * .5;
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
      data.setInt16(44 + i * 2, (buf[i].clamp(-1.0, 1.0) * 32000).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
