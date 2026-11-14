import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/call_audio.dart';
import '../groups/group_ui.dart';
import 'chess_engine.dart';
import 'game_fx.dart';
import 'game_texts.dart';

/// افزونه‌های شطرنج: مدل مهره و صفحه، تنظیمات، زنگ مسابقه، آمار و امتیاز.
/// همه‌چیز روی خود گوشی ذخیره می‌شود و به اینترنت نیازی ندارد.

// ------------------------------------------------------------------ مدل مهره و صفحه

class ChessStyle {
  const ChessStyle({
    required this.id,
    required this.fa,
    required this.en,
    required this.light,
    required this.dark,
    required this.wTop,
    required this.wBot,
    required this.bTop,
    required this.bBot,
    required this.wLine,
    required this.bLine,
    this.lineW = 2.6,
    this.shadow = true,
  });

  final String id;
  final String fa;
  final String en;
  final Color light;
  final Color dark;
  final Color wTop;
  final Color wBot;
  final Color bTop;
  final Color bBot;
  final Color wLine;
  final Color bLine;
  final double lineW;
  final bool shadow;

  String get name => GameT.fa ? fa : en;
}

/// شش مدل (الهام از مجموعه‌های معروف: استونتون کلاسیک، چوبی، تخت و مینیمال، فلزی، شیشه‌ای، جو‌دانه‌ای قرمز)
const List<ChessStyle> kChessStyles = <ChessStyle>[
  ChessStyle(
    id: 'classic',
    fa: 'کلاسیک',
    en: 'Classic',
    light: Color(0xfff0e4c8),
    dark: Color(0xff3f7f86),
    wTop: Color(0xffffffff),
    wBot: Color(0xffe9e9ee),
    bTop: Color(0xff34343d),
    bBot: Color(0xff17171c),
    wLine: Color(0xff000000),
    bLine: Color(0xccffffff),
  ),
  ChessStyle(
    id: 'wood',
    fa: 'چوبی',
    en: 'Wood',
    light: Color(0xffeed7a5),
    dark: Color(0xffa8743f),
    wTop: Color(0xfffbf0d2),
    wBot: Color(0xffd8bd86),
    bTop: Color(0xff6b4528),
    bBot: Color(0xff2b190c),
    wLine: Color(0xff4a2f17),
    bLine: Color(0xaaf0d9a8),
  ),
  ChessStyle(
    id: 'flat',
    fa: 'ساده و تخت',
    en: 'Flat',
    light: Color(0xffeeeed2),
    dark: Color(0xff769656),
    wTop: Color(0xfffafafa),
    wBot: Color(0xfffafafa),
    bTop: Color(0xff4a4a4f),
    bBot: Color(0xff4a4a4f),
    wLine: Color(0xff3a3a3a),
    bLine: Color(0xff111111),
    lineW: 1.8,
    shadow: false,
  ),
  ChessStyle(
    id: 'metal',
    fa: 'نقره و طلا',
    en: 'Silver & Gold',
    light: Color(0xff5a6b8f),
    dark: Color(0xff222f4d),
    wTop: Color(0xfff2f5fa),
    wBot: Color(0xff97a3b8),
    bTop: Color(0xfff6d77f),
    bBot: Color(0xffb8860b),
    wLine: Color(0xff4b5568),
    bLine: Color(0xff5a3d00),
  ),
  ChessStyle(
    id: 'glass',
    fa: 'شیشه‌ای',
    en: 'Glass',
    light: Color(0xff9fd6e8),
    dark: Color(0xff2b6f8e),
    wTop: Color(0xeeffffff),
    wBot: Color(0x99dff4ff),
    bTop: Color(0xdd1f5a7d),
    bBot: Color(0xee0a1d2e),
    wLine: Color(0xffffffff),
    bLine: Color(0xff7fd8ff),
    lineW: 2.2,
  ),
  ChessStyle(
    id: 'ruby',
    fa: 'عاجی و قرمز',
    en: 'Ivory & Red',
    light: Color(0xffe9d8b4),
    dark: Color(0xffb5653f),
    wTop: Color(0xfff7efd9),
    wBot: Color(0xffd6c598),
    bTop: Color(0xffc8362c),
    bBot: Color(0xff7a1410),
    wLine: Color(0xff4a3a1c),
    bLine: Color(0xff3b0d0a),
  ),
];

class _Shape {
  _Shape(this.body, this.detail, this.eye);
  final Path body;
  final Path detail;
  final Offset? eye;
}

Path _u(List<Path> parts) {
  var r = parts.first;
  for (var i = 1; i < parts.length; i++) {
    r = Path.combine(ui.PathOperation.union, r, parts[i]);
  }
  return r;
}

Path _rr(double l, double t, double r, double b, double rad) => Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));

Path _circle(double x, double y, double r) => Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

Path _base(double y) => _u(<Path>[_rr(26, y, 74, y + 8, 3), _rr(19, y + 7, 81, y + 15, 4)]);

final Map<int, _Shape> _shapes = <int, _Shape>{};

_Shape _shapeOf(int t) {
  return _shapes.putIfAbsent(t, () {
    switch (t) {
      case kPawn:
        {
          final body = Path()
            ..moveTo(42, 46)
            ..quadraticBezierTo(40, 64, 30, 78)
            ..lineTo(70, 78)
            ..quadraticBezierTo(60, 64, 58, 46)
            ..close();
          return _Shape(_u(<Path>[_circle(50, 28, 12.5), _rr(36, 40, 64, 47, 3), body, _base(77)]), Path(), null);
        }
      case kRook:
        {
          final top = Path()
            ..moveTo(26, 14)
            ..lineTo(41, 14)
            ..lineTo(41, 22)
            ..lineTo(45.5, 22)
            ..lineTo(45.5, 14)
            ..lineTo(54.5, 14)
            ..lineTo(54.5, 22)
            ..lineTo(59, 22)
            ..lineTo(59, 14)
            ..lineTo(74, 14)
            ..lineTo(74, 33)
            ..lineTo(26, 33)
            ..close();
          final body = Path()
            ..moveTo(32, 32)
            ..lineTo(68, 32)
            ..lineTo(71, 78)
            ..lineTo(29, 78)
            ..close();
          final det = Path()
            ..moveTo(33, 40)
            ..lineTo(67, 40);
          return _Shape(_u(<Path>[top, body, _base(77)]), det, null);
        }
      case kKnight:
        {
          final body = Path()
            ..moveTo(72, 78)
            ..cubicTo(73, 56, 72, 40, 62, 30)
            ..lineTo(60, 14)
            ..lineTo(50, 23)
            ..cubicTo(44, 24, 38, 28, 34, 36)
            ..lineTo(22, 48)
            ..cubicTo(19, 53, 24, 58, 29, 56)
            ..lineTo(37, 52)
            ..cubicTo(42, 50, 46, 46, 49, 44)
            ..cubicTo(40, 54, 31, 64, 29, 78)
            ..close();
          final det = Path()
            ..moveTo(62, 34)
            ..cubicTo(58, 46, 56, 58, 56, 70);
          return _Shape(_u(<Path>[body, _base(77)]), det, const Offset(45, 34));
        }
      case kBishop:
        {
          final mitre = Path()
            ..moveTo(50, 20)
            ..cubicTo(34, 30, 32, 48, 40, 58)
            ..lineTo(60, 58)
            ..cubicTo(68, 48, 66, 30, 50, 20)
            ..close();
          final stem = Path()
            ..moveTo(41, 64)
            ..lineTo(59, 64)
            ..lineTo(63, 78)
            ..lineTo(37, 78)
            ..close();
          final det = Path()
            ..moveTo(44, 34)
            ..lineTo(56, 47);
          return _Shape(_u(<Path>[_circle(50, 13, 5.5), mitre, _rr(35, 57, 65, 65, 3), stem, _base(77)]), det, null);
        }
      case kQueen:
        {
          final crown = Path()
            ..moveTo(24, 32)
            ..lineTo(33, 60)
            ..lineTo(37, 30)
            ..lineTo(44, 58)
            ..lineTo(50, 26)
            ..lineTo(56, 58)
            ..lineTo(63, 30)
            ..lineTo(67, 60)
            ..lineTo(76, 32)
            ..lineTo(71, 68)
            ..lineTo(29, 68)
            ..close();
          final neck = Path()
            ..moveTo(30, 67)
            ..lineTo(70, 67)
            ..lineTo(66, 78)
            ..lineTo(34, 78)
            ..close();
          return _Shape(
            _u(<Path>[crown, neck, _circle(24, 27, 4.2), _circle(37, 24, 4.2), _circle(50, 20, 4.2), _circle(63, 24, 4.2), _circle(76, 27, 4.2), _base(77)]),
            Path(),
            null,
          );
        }
      default:
        {
          final dome = Path()
            ..moveTo(50, 28)
            ..cubicTo(34, 28, 26, 38, 31, 52)
            ..lineTo(35, 68)
            ..lineTo(65, 68)
            ..lineTo(69, 52)
            ..cubicTo(74, 38, 66, 28, 50, 28)
            ..close();
          final neck = Path()
            ..moveTo(34, 72)
            ..lineTo(66, 72)
            ..lineTo(68, 78)
            ..lineTo(32, 78)
            ..close();
          return _Shape(
            _u(<Path>[_rr(46.5, 3, 53.5, 24, 2), _rr(40, 9, 60, 16, 2), dome, _rr(31, 66, 69, 73, 3), neck, _base(77)]),
            Path()
              ..moveTo(38, 50)
              ..lineTo(62, 50),
            null,
          );
        }
    }
  });
}

/// نقاشی مهره با مسیرهای برداری؛ به فونت وابسته نیست و رنگ سفید/سیاه همیشه درست است.
class ChessPiecePainter extends CustomPainter {
  const ChessPiecePainter(this.type, this.white, this.style);
  final int type;
  final bool white;
  final ChessStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final sh = _shapeOf(type);
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    if (style.shadow) {
      canvas.drawPath(
        sh.body.shift(const Offset(1.4, 2.4)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }
    final top = white ? style.wTop : style.bTop;
    final bot = white ? style.wBot : style.bBot;
    final line = white ? style.wLine : style.bLine;
    canvas.drawPath(
      sh.body,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(const Offset(0, 8), const Offset(0, 92), <Color>[top, bot]),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineW
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = line;
    canvas.drawPath(sh.body, stroke);
    if (type != kPawn) {
      canvas.drawPath(sh.detail, stroke..strokeWidth = style.lineW * 0.85);
    }
    final eye = sh.eye;
    if (eye != null) {
      canvas.drawCircle(eye, 2.6, Paint()..color = line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChessPiecePainter old) => old.type != type || old.white != white || old.style.id != style.id;
}

Widget chessPiece(int type, bool white, ChessStyle style, double size) {
  return CustomPaint(size: Size(size, size), painter: ChessPiecePainter(type, white, style));
}

// ------------------------------------------------------------------ تنظیمات

class ChessPrefs {
  ChessPrefs._();

  static const String _kStyle = 'cyrus_chess_style';
  static const String _kAlarm = 'cyrus_chess_alarm';
  static const String _kTime = 'cyrus_chess_minutes';

  static int styleIndex = 0;
  static bool alarmOn = true;

  /// دقیقهٔ هر بازیکن؛ ۰ = بدون ساعت
  static int minutes = 10;
  static bool _loaded = false;

  static ChessStyle get style => kChessStyles[styleIndex.clamp(0, kChessStyles.length - 1)];

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString(_kStyle) ?? 'classic';
      final i = kChessStyles.indexWhere((s) => s.id == id);
      styleIndex = i < 0 ? 0 : i;
      alarmOn = p.getBool(_kAlarm) ?? true;
      minutes = p.getInt(_kTime) ?? 10;
      _loaded = true;
    } catch (_) {}
  }

  static Future<void> setStyle(int i) async {
    styleIndex = i;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kStyle, kChessStyles[i].id);
    } catch (_) {}
  }

  static Future<void> setAlarm(bool on) async {
    alarmOn = on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kAlarm, on);
    } catch (_) {}
  }

  static Future<void> setMinutes(int m) async {
    minutes = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kTime, m);
    } catch (_) {}
  }
}

// ------------------------------------------------------------------ زنگ مسابقه

/// زنگ تک‌ضربه مثل مسابقهٔ واقعی. اگر صدای بازی یا «زنگ» خاموش باشد فقط لرزش می‌دهد.
class ChessAlarm {
  ChessAlarm._();

  static void _ring(bool warn, {bool haptic = true}) {
    if (!GameFx.on) return;
    if (ChessPrefs.alarmOn) {
      if (warn) {
        CallAudio.warn();
      } else {
        CallAudio.gong();
      }
    }
    if (haptic) HapticFeedback.heavyImpact();
  }

  /// شروع بازی
  static void start() => _ring(false);

  /// ۳۰ ثانیهٔ آخر ساعت
  static void warn() => _ring(true);

  /// پایان بازی
  static void end() => _ring(false, haptic: false);
}

// ------------------------------------------------------------------ آمار و امتیاز

class ChessGameRec {
  ChessGameRec(this.ts, this.mode, this.opp, this.result, this.moves, this.delta);
  final int ts;
  final String mode; // bot_easy | bot_normal | bot_hard | local | nearby | online
  final String opp;
  final String result; // win | draw | loss
  final int moves;
  final int delta;

  Map<String, dynamic> toJson() => <String, dynamic>{'t': ts, 'm': mode, 'o': opp, 'r': result, 'n': moves, 'd': delta};

  static ChessGameRec? fromJson(dynamic j) {
    if (j is! Map) return null;
    return ChessGameRec(
      (j['t'] as num?)?.toInt() ?? 0,
      '${j['m']}',
      '${j['o']}',
      '${j['r']}',
      (j['n'] as num?)?.toInt() ?? 0,
      (j['d'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChessStats {
  ChessStats._();

  static const String _k = 'cyrus_chess_stats_v1';

  static int rating = 1000;
  static int wins = 0;
  static int draws = 0;
  static int losses = 0;
  static int streak = 0;
  static int best = 0;
  static int localGames = 0;
  static List<ChessGameRec> history = <ChessGameRec>[];
  static bool _loaded = false;

  static int get games => wins + draws + losses;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final j = jsonDecode(raw);
        if (j is Map) {
          rating = (j['rt'] as num?)?.toInt() ?? 1000;
          wins = (j['w'] as num?)?.toInt() ?? 0;
          draws = (j['d'] as num?)?.toInt() ?? 0;
          losses = (j['l'] as num?)?.toInt() ?? 0;
          streak = (j['s'] as num?)?.toInt() ?? 0;
          best = (j['b'] as num?)?.toInt() ?? 0;
          localGames = (j['lg'] as num?)?.toInt() ?? 0;
          final h = j['h'];
          if (h is List) {
            history = h.map(ChessGameRec.fromJson).whereType<ChessGameRec>().toList();
          }
        }
      }
      _loaded = true;
    } catch (_) {}
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode(<String, dynamic>{
          'rt': rating,
          'w': wins,
          'd': draws,
          'l': losses,
          's': streak,
          'b': best,
          'lg': localGames,
          'h': history.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  static int _delta(String mode, String result) {
    int w, d, l;
    switch (mode) {
      case 'bot_easy':
        w = 6;
        d = 1;
        l = -4;
        break;
      case 'bot_hard':
        w = 16;
        d = 4;
        l = -8;
        break;
      case 'bot_normal':
        w = 10;
        d = 2;
        l = -6;
        break;
      default:
        w = 14;
        d = 2;
        l = -9;
    }
    return result == 'win' ? w : (result == 'draw' ? d : l);
  }

  /// ثبت یک بازی تمام‌شده. بازی دو نفره روی یک گوشی امتیاز نمی‌گیرد (فقط شمارش می‌شود).
  static Future<int> record({required String mode, required String opp, required String result, required int moves}) async {
    await load();
    if (mode == 'local') {
      localGames++;
      await _save();
      return 0;
    }
    final d = _delta(mode, result);
    rating = (rating + d).clamp(100, 4000);
    if (result == 'win') {
      wins++;
      streak++;
      if (streak > best) best = streak;
    } else if (result == 'draw') {
      draws++;
    } else {
      losses++;
      streak = 0;
    }
    history.insert(0, ChessGameRec(DateTime.now().millisecondsSinceEpoch, mode, opp, result, moves, d));
    if (history.length > 30) history = history.sublist(0, 30);
    await _save();
    return d;
  }

  static Future<void> reset() async {
    rating = 1000;
    wins = 0;
    draws = 0;
    losses = 0;
    streak = 0;
    best = 0;
    localGames = 0;
    history = <ChessGameRec>[];
    await _save();
  }
}

// ------------------------------------------------------------------ پنجره‌ها

String _ex(String fa, String en) => GameT.fa ? fa : en;

/// پنجرهٔ انتخاب مدل مهره و صفحه + زنگ هشدار
Future<void> showChessStyleSheet(BuildContext context, VoidCallback onChanged) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: gPanel,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          return Directionality(
            textDirection: gDir,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_ex('مدل مهره و صفحه', 'Pieces & board'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < kChessStyles.length; i++)
                      _stylePreview(i, ChessPrefs.styleIndex == i, () async {
                        await ChessPrefs.setStyle(i);
                        setS(() {});
                        onChanged();
                      }),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: gGold,
                      title: Text(_ex('زنگ مسابقه و هشدار ساعت', 'Match bell & clock warning'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: Text(_ex('یک زنگ در شروع و پایان، یک زنگ هشدار در ۳۰ ثانیهٔ آخر', 'One bell at start & end, one warning at 30 seconds left'), style: const TextStyle(color: gMuted, fontSize: 11.5)),
                      value: ChessPrefs.alarmOn,
                      onChanged: (v) async {
                        await ChessPrefs.setAlarm(v);
                        setS(() {});
                        if (v) ChessAlarm.warn();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _stylePreview(int i, bool sel, VoidCallback onTap) {
  final st = kChessStyles[i];
  Widget cell(int type, bool white, bool light) => Container(
        width: 50,
        height: 50,
        color: light ? st.light : st.dark,
        alignment: Alignment.center,
        child: chessPiece(type, white, st, 44),
      );
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? gGold : gLine, width: sel ? 2 : 1)),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(children: [cell(kKing, true, true), cell(kKnight, false, false), cell(kQueen, true, true), cell(kBishop, false, false)]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(st.name, style: TextStyle(color: sel ? gGold : Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5))),
          if (sel) const Icon(Icons.check_circle_rounded, color: gGold),
        ],
      ),
    ),
  );
}

/// انتخاب زمان هر بازیکن
Future<int?> showChessTimeSheet(BuildContext context, {required int current}) {
  const options = <int>[0, 3, 5, 10, 15, 30];
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: gPanel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => Directionality(
      textDirection: gDir,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_ex('زمان هر بازیکن', 'Time per player'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in options)
                    ChoiceChip(
                      selected: current == m,
                      selectedColor: gGold,
                      backgroundColor: gBg,
                      side: const BorderSide(color: gLine),
                      label: Text(m == 0 ? _ex('بدون ساعت', 'No clock') : _ex('$m دقیقه', '$m min'), style: TextStyle(color: current == m ? gBg : Colors.white, fontWeight: FontWeight.w800)),
                      onSelected: (_) => Navigator.of(ctx).pop(m),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _modeName(String m) {
  switch (m) {
    case 'bot_easy':
      return _ex('ربات آسان', 'Robot · easy');
    case 'bot_normal':
      return _ex('ربات متوسط', 'Robot · normal');
    case 'bot_hard':
      return _ex('ربات سخت', 'Robot · hard');
    case 'nearby':
      return _ex('دو گوشی (آفلاین)', 'Two phones (offline)');
    case 'online':
      return _ex('آنلاین', 'Online');
    default:
      return _ex('دو نفره', 'Two players');
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// پنجرهٔ آمار و امتیاز
Future<void> showChessStatsSheet(BuildContext context) async {
  await ChessStats.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: gPanel,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Widget box(String title, String value, Color c) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: gLine)),
                child: Column(children: [
                  Text(value, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 19)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(color: gMuted, fontSize: 11.5)),
                ]),
              ),
            );
        final h = ChessStats.history;
        return Directionality(
          textDirection: gDir,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.82),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_ex('آمار و امتیاز شطرنج', 'Chess stats & rating'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(children: [
                      box(_ex('امتیاز', 'Rating'), '${ChessStats.rating}', gGold),
                      box(_ex('برد', 'Wins'), '${ChessStats.wins}', gTeal),
                      box(_ex('مساوی', 'Draws'), '${ChessStats.draws}', gSky),
                      box(_ex('باخت', 'Losses'), '${ChessStats.losses}', const Color(0xffff6b6b)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      box(_ex('برد پشت‌سرهم', 'Win streak'), '${ChessStats.streak}', Colors.white),
                      box(_ex('بهترین رکورد', 'Best streak'), '${ChessStats.best}', Colors.white),
                      box(_ex('کل بازی‌ها', 'Games'), '${ChessStats.games + ChessStats.localGames}', Colors.white),
                    ]),
                    const SizedBox(height: 12),
                    Text(_ex('آخرین بازی‌ها', 'Recent games'), style: const TextStyle(color: gMuted, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Flexible(
                      child: h.isEmpty
                          ? Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Text(_ex('هنوز بازی ثبت نشده است.', 'No games recorded yet.'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: h.length,
                              itemBuilder: (_, i) {
                                final g = h[i];
                                final d = DateTime.fromMillisecondsSinceEpoch(g.ts);
                                final c = g.result == 'win' ? gTeal : (g.result == 'draw' ? gSky : const Color(0xffff6b6b));
                                final label = g.result == 'win' ? _ex('برد', 'Win') : (g.result == 'draw' ? _ex('مساوی', 'Draw') : _ex('باخت', 'Loss'));
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: gLine)),
                                  child: Row(children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('$label · ${g.opp.isEmpty ? _modeName(g.mode) : g.opp}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                        Text('${_modeName(g.mode)} · ${g.moves ~/ 2 + g.moves % 2} ${_ex('حرکت', 'moves')} · ${d.year}/${_two(d.month)}/${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}', style: const TextStyle(color: gMuted, fontSize: 11)),
                                      ]),
                                    ),
                                    Directionality(textDirection: TextDirection.ltr, child: Text(g.delta > 0 ? '+${g.delta}' : '${g.delta}', style: TextStyle(color: c, fontWeight: FontWeight.w900))),
                                  ]),
                                );
                              },
                            ),
                    ),
                    if (ChessStats.games + ChessStats.localGames > 0)
                      TextButton(
                        onPressed: () async {
                          await ChessStats.reset();
                          setS(() {});
                        },
                        child: Text(_ex('پاک‌کردن آمار', 'Reset stats'), style: const TextStyle(color: gMuted)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
