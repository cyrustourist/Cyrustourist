import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_texts.dart';

/// طرح‌های صفحه‌ی تخته‌نرد (رنگ تخته، مثلث‌ها، مهره‌ها و نقش وسط) و تنظیمات ذخیره‌شده‌ی آن.

class BgTheme {
  const BgTheme({
    required this.name,
    required this.frame,
    required this.frameDark,
    required this.boardA,
    required this.boardB,
    required this.ptA,
    required this.ptB,
    required this.ptLine,
    required this.bar,
    required this.checkerA,
    required this.checkerB,
    required this.ringA,
    required this.ringB,
    this.motif = 0,
    this.motifColor = const Color(0x33000000),
    this.grain = 0.0,
    this.grooves = 0,
    this.nameKey,
  });

  final String name;

  /// کلید ترجمه‌ی نام طرح در GameT (اگر null باشد همان name نشان داده می‌شود)
  final String? nameKey;

  /// نام قابل‌نمایش بر اساس زبان برنامه
  String get label => nameKey == null ? name : GameT.t(nameKey!);
  final Color frame;
  final Color frameDark;
  final Color boardA;
  final Color boardB;
  final Color ptA;
  final Color ptB;
  final Color ptLine; // خط دور مثلث‌ها (شفاف = بدون خط)
  final Color bar;
  final Color checkerA;
  final Color checkerB;
  final Color ringA;
  final Color ringB;

  /// نقش وسط هر نیمه: ۰ ندارد، ۱ لوزی، ۲ ستاره، ۳ فروهر ساده، ۴ گل،
  /// ۵ آدم بال‌دار (نیمه‌ی چپ) + فروهر (نیمه‌ی راست)، ۶ فروهر بزرگ و کامل در هر دو نیمه
  final int motif;
  final Color motifColor;

  /// شدت رگه‌های چوب (۰ تا ۱)
  final double grain;

  /// تعداد شیار روی مهره‌ها
  final int grooves;
}

const List<BgTheme> kBgThemes = <BgTheme>[
  BgTheme(
    name: 'کلاسیک',
    frame: Color(0xff5a3a28),
    frameDark: Color(0xff3a2418),
    boardA: Color(0xff0f2a33),
    boardB: Color(0xff0b1f26),
    ptA: Color(0xffd9b26f),
    ptB: Color(0xff2a8a8d),
    ptLine: Color(0x00000000),
    bar: Color(0xff5a3a28),
    checkerA: Color(0xfff4ead2),
    checkerB: Color(0xffc0392b),
    ringA: Color(0xffb89b5e),
    ringB: Color(0xff7a1d16),
  ),
  BgTheme(
    name: 'چرم مارپوش و نقش بابلی',
    frame: Color(0xff9c4a22),
    frameDark: Color(0xff5e2a12),
    boardA: Color(0xffe19a62),
    boardB: Color(0xffc9783f),
    ptA: Color(0xff1d2a24),
    ptB: Color(0xfff0b27a),
    ptLine: Color(0x661d2a24),
    bar: Color(0xff8a3f1c),
    checkerA: Color(0xffd9d4c8),
    checkerB: Color(0xff8c8984),
    ringA: Color(0xff9a9486),
    ringB: Color(0xff5b5955),
    motif: 3,
    motifColor: Color(0x55341a0a),
    grain: .25,
    grooves: 1,
  ),
  BgTheme(
    name: 'گردوی منبت لوزی',
    frame: Color(0xffc07a22),
    frameDark: Color(0xff7a4a12),
    boardA: Color(0xff7a3d1a),
    boardB: Color(0xff5c2b10),
    ptA: Color(0xff8c4a22),
    ptB: Color(0xff6a3216),
    ptLine: Color(0xffe7b04a),
    bar: Color(0xffa8681c),
    checkerA: Color(0xfff3e6c0),
    checkerB: Color(0xff4a2a1c),
    ringA: Color(0xffc8a860),
    ringB: Color(0xff2a160c),
    motif: 1,
    motifColor: Color(0xaaf0c070),
    grain: .5,
    grooves: 2,
  ),
  BgTheme(
    name: 'چوب فروهر',
    frame: Color(0xff7a4a22),
    frameDark: Color(0xff4a2a12),
    boardA: Color(0xff9a6232),
    boardB: Color(0xff7c4c24),
    ptA: Color(0xff2a1a10),
    ptB: Color(0xffb0804a),
    ptLine: Color(0x442a1a10),
    bar: Color(0xff6a3e1c),
    checkerA: Color(0xffe9dab4),
    checkerB: Color(0xff8b8782),
    ringA: Color(0xffb8a878),
    ringB: Color(0xff5c5a56),
    motif: 3,
    motifColor: Color(0x662a1a10),
    grain: .45,
    grooves: 1,
  ),
  BgTheme(
    name: 'گردوی ستاره',
    frame: Color(0xff9a4a1e),
    frameDark: Color(0xff5a2a10),
    boardA: Color(0xff7a4a2a),
    boardB: Color(0xff5c3418),
    ptA: Color(0xffe9cf92),
    ptB: Color(0xff8a5a2c),
    ptLine: Color(0x66e9cf92),
    bar: Color(0xff7a3a16),
    checkerA: Color(0xffe0c28a),
    checkerB: Color(0xff2a1a14),
    ringA: Color(0xffa8884a),
    ringB: Color(0xff120a06),
    motif: 2,
    motifColor: Color(0xccf0d8a0),
    grain: .5,
    grooves: 3,
  ),
  BgTheme(
    name: 'منبت طلایی',
    frame: Color(0xff6a2e18),
    frameDark: Color(0xff3a160a),
    boardA: Color(0xff5a2616),
    boardB: Color(0xff3e180c),
    ptA: Color(0xffc89b4e),
    ptB: Color(0xff8a5a30),
    ptLine: Color(0x88f0d090),
    bar: Color(0xff7a3a1a),
    checkerA: Color(0xffd4aa74),
    checkerB: Color(0xff6a3a22),
    ringA: Color(0xffa07a44),
    ringB: Color(0xff3a1c10),
    motif: 4,
    motifColor: Color(0x99f0d090),
    grain: .35,
    grooves: 2,
  ),
  BgTheme(
    name: 'چرم مارپوش، فروهر و آدم بال‌دار',
    nameKey: 'bgt_snake_faravahar',
    frame: Color(0xff9c4a22),
    frameDark: Color(0xff5e2a12),
    boardA: Color(0xffe8a56a),
    boardB: Color(0xffd0834a),
    ptA: Color(0xff1d2a24),
    ptB: Color(0xfff6c08a),
    ptLine: Color(0x881d2a24),
    bar: Color(0xff8a3f1c),
    checkerA: Color(0xffe6dfcf),
    checkerB: Color(0xff8c8984),
    ringA: Color(0xff9a9486),
    ringB: Color(0xff5b5955),
    motif: 5,
    motifColor: Color(0xcc2a160a),
    grain: .25,
    grooves: 1,
  ),
  BgTheme(
    name: 'گردوی منبت فروهر',
    nameKey: 'bgt_faravahar_big',
    frame: Color(0xff7a4a22),
    frameDark: Color(0xff4a2a12),
    boardA: Color(0xffb07038),
    boardB: Color(0xff94582a),
    ptA: Color(0xff1a120c),
    ptB: Color(0xffc8905a),
    ptLine: Color(0x661a120c),
    bar: Color(0xff6a3e1c),
    checkerA: Color(0xffe9dab4),
    checkerB: Color(0xff8b8782),
    ringA: Color(0xffb8a878),
    ringB: Color(0xff5c5a56),
    motif: 6,
    motifColor: Color(0xdd1a0f08),
    grain: .5,
    grooves: 2,
  ),
];

/// قیمت هر طرح صفحه (سکه)؛ ۰ = رایگان
const List<int> kBgThemePrice = <int>[0, 0, 150, 150, 200, 250, 250, 250];

/// تنظیمات تخته‌نرد: طرح صفحه، صدا، لرزش و طول مسابقه.
class BgPrefs extends ChangeNotifier {
  BgPrefs._();
  static final BgPrefs instance = BgPrefs._();
  static const String _k = 'bg_prefs_v1';

  int board = 0;
  bool mute = false;
  int vol = 80;
  bool vib = true;

  /// طول مسابقه: ۰ یعنی تک‌بازی بدون مسابقه
  int matchTo = 0;
  bool showPip = true;

  BgTheme get theme => kBgThemes[board.clamp(0, kBgThemes.length - 1).toInt()];

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        board = _ci(m['board'], 0, kBgThemes.length - 1, 0);
        mute = m['mute'] == true;
        vol = _ci(m['vol'], 0, 100, 80);
        vib = m['vib'] != false;
        matchTo = _ci(m['matchTo'], 0, 21, 0);
        showPip = m['showPip'] != false;
      }
    } catch (_) {}
    notifyListeners();
  }

  static int _ci(dynamic v, int lo, int hi, int d) {
    if (v is! num) return d;
    final i = v.toInt();
    return i < lo ? lo : (i > hi ? hi : i);
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(<String, dynamic>{'board': board, 'mute': mute, 'vol': vol, 'vib': vib, 'matchTo': matchTo, 'showPip': showPip}));
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// رسم زمینه

/// رسم قاب، تخته و نقش وسط. مثلث‌ها و مهره‌ها را صفحه‌ی بازی می‌کشد.
void paintBgBoard(Canvas canvas, Size size, BgTheme t, {required double pad}) {
  final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.045));
  canvas.drawRRect(
    outer,
    Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[t.frame, t.frameDark]).createShader(Offset.zero & size),
  );
  final inner = Rect.fromLTWH(pad * 0.55, pad * 0.55, size.width - pad * 1.1, size.height - pad * 1.1);
  final innerR = RRect.fromRectAndRadius(inner, Radius.circular(size.width * 0.03));
  canvas.drawRRect(innerR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[t.boardA, t.boardB]).createShader(inner));
  // رگه‌های چوب
  if (t.grain > 0) {
    final rnd = Random(11);
    canvas.save();
    canvas.clipRRect(innerR);
    for (var i = 0; i < 46; i++) {
      final x = inner.left + rnd.nextDouble() * inner.width;
      final w = 0.6 + rnd.nextDouble() * 1.4;
      canvas.drawLine(
        Offset(x, inner.top),
        Offset(x + (rnd.nextDouble() - .5) * 14, inner.bottom),
        Paint()
          ..strokeWidth = w
          ..color = (rnd.nextBool() ? Colors.black : Colors.white).withOpacity(.05 * t.grain + rnd.nextDouble() * .05 * t.grain),
      );
    }
    canvas.restore();
  }
  // نقش وسط هر نیمه
  if (t.motif != 0) {
    final laneW = (size.width - 2 * pad) / 2;
    for (var k = 0; k < 2; k++) {
      final c = Offset(pad + laneW * (k + 0.5), size.height / 2);
      _motif(canvas, c, laneW * 0.46, t, k);
    }
  }
  // لبه‌ی داخلی
  canvas.drawRRect(
    innerR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pad * 0.18
      ..color = Colors.black.withOpacity(.35),
  );
}

void _motif(Canvas c, Offset o, double r, BgTheme t, [int lane = 0]) {
  final p = Paint()..color = t.motifColor;
  final st = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.2, r * 0.035)
    ..color = t.motifColor;
  switch (t.motif) {
    case 1: // لوزی چهارخانه
      final path = Path()
        ..moveTo(o.dx, o.dy - r * 1.2)
        ..lineTo(o.dx + r * 0.75, o.dy)
        ..lineTo(o.dx, o.dy + r * 1.2)
        ..lineTo(o.dx - r * 0.75, o.dy)
        ..close();
      c.drawPath(path, st);
      final in2 = Path()
        ..moveTo(o.dx, o.dy - r * 0.9)
        ..lineTo(o.dx + r * 0.56, o.dy)
        ..lineTo(o.dx, o.dy + r * 0.9)
        ..lineTo(o.dx - r * 0.56, o.dy)
        ..close();
      c.drawPath(in2, st);
      c.drawRect(Rect.fromCenter(center: o + Offset(r * 0.14, -r * 0.14), width: r * 0.28, height: r * 0.28), p);
      c.drawRect(Rect.fromCenter(center: o + Offset(-r * 0.14, r * 0.14), width: r * 0.28, height: r * 0.28), p);
      break;
    case 2: // ستاره‌ی هشت پر با دایره‌ی قرمز
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        final tip = o + Offset(cos(a), sin(a)) * r;
        final l = o + Offset(cos(a - 0.22), sin(a - 0.22)) * r * 0.34;
        final rr = o + Offset(cos(a + 0.22), sin(a + 0.22)) * r * 0.34;
        c.drawPath(
          Path()
            ..moveTo(l.dx, l.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(rr.dx, rr.dy)
            ..close(),
          p,
        );
      }
      c.drawCircle(o, r * 0.16, Paint()..color = const Color(0xffb02a2a));
      break;
    case 3: // فروهر ساده‌شده: دایره، بال‌ها و دم
      c.drawCircle(o + Offset(0, -r * 0.1), r * 0.16, st);
      c.drawCircle(o + Offset(0, -r * 0.1), r * 0.07, p);
      for (final s in <double>[-1, 1]) {
        for (var i = 0; i < 4; i++) {
          final y = o.dy - r * 0.2 + i * r * 0.1;
          c.drawLine(Offset(o.dx + s * r * 0.2, y), Offset(o.dx + s * r * (0.95 - i * 0.12), y - r * 0.18 + i * r * 0.05), st);
        }
      }
      c.drawLine(o + Offset(0, r * 0.05), o + Offset(0, r * 0.55), st);
      c.drawLine(o + Offset(0, r * 0.45), o + Offset(-r * 0.3, r * 0.8), st);
      c.drawLine(o + Offset(0, r * 0.45), o + Offset(r * 0.3, r * 0.8), st);
      c.drawLine(o + Offset(0, r * 0.55), o + Offset(-r * 0.18, r * 0.95), st);
      c.drawLine(o + Offset(0, r * 0.55), o + Offset(r * 0.18, r * 0.95), st);
      break;
    case 4: // گل و ترنج
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        c.drawCircle(o + Offset(cos(a), sin(a)) * r * 0.5, r * 0.2, st);
      }
      c.drawCircle(o, r * 0.28, st);
      c.drawCircle(o, r * 0.1, p);
      c.drawCircle(o, r * 0.95, st);
      break;
    case 5: // نیمه‌ی چپ: آدم بال‌دار هخامنشی، نیمه‌ی راست: فروهر
      if (lane == 0) {
        _wingedMan(c, o, r * 1.25, t.motifColor);
      } else {
        _faravahar(c, o, r * 1.25, t.motifColor);
      }
      break;
    case 6: // فروهر بزرگ و کامل در هر دو نیمه
      _faravahar(c, o, r * 1.35, t.motifColor);
      break;
    default:
      break;
  }
}

/// پرهای کوچک (خط‌های عمود) در امتداد یک منحنی؛ [dir] = ۱ یا ‎-۱ برای سمت پرها
void _feathers(Canvas c, Path path, double len, Paint st, int n, double dir) {
  for (final m in path.computeMetrics()) {
    for (var i = 1; i <= n; i++) {
      final tg = m.getTangentForOffset(m.length * i / (n + 1));
      if (tg == null) continue;
      final v = tg.vector;
      final nrm = Offset(-v.dy, v.dx) * dir;
      c.drawLine(tg.position, tg.position + nrm * len, st);
    }
  }
}

/// فروهر: حلقه، نیم‌تنه‌ی انسان، بال‌های سه‌ردیفه، دم سه‌شاخه و دو نوار پیچ‌خورده
void _faravahar(Canvas c, Offset o, double r, Color col) {
  final p = Paint()..color = col;
  final st = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.1, r * 0.03)
    ..strokeCap = StrokeCap.round
    ..color = col;
  final thin = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(0.8, r * 0.018)
    ..strokeCap = StrokeCap.round
    ..color = col;
  final ring = o + Offset(0, r * 0.02);
  // حلقه‌ی میانی
  c.drawCircle(ring, r * 0.17, st);
  c.drawCircle(ring, r * 0.12, thin);
  // نیم‌تنه‌ی انسان در حلقه
  c.drawCircle(ring + Offset(0, -r * 0.045), r * 0.045, p);
  c.drawPath(
    Path()
      ..moveTo(ring.dx - r * 0.07, ring.dy + r * 0.1)
      ..quadraticBezierTo(ring.dx, ring.dy - r * 0.04, ring.dx + r * 0.07, ring.dy + r * 0.1)
      ..close(),
    p,
  );
  // بال‌ها (سه ردیف در هر سمت)
  for (final s in <double>[-1, 1]) {
    for (var tier = 0; tier < 3; tier++) {
      final y = ring.dy - r * 0.07 + tier * r * 0.085;
      final x0 = ring.dx + s * r * 0.17;
      final reach = r * (1.0 - tier * 0.13);
      final path = Path()
        ..moveTo(x0, y)
        ..quadraticBezierTo(ring.dx + s * reach * 0.55, y - r * 0.22, ring.dx + s * reach, y - r * 0.12 + tier * r * 0.03);
      c.drawPath(path, st);
      _feathers(c, path, r * (0.16 - tier * 0.02), thin, 9 - tier, s);
    }
  }
  // بدنه و دم
  c.drawLine(ring + Offset(0, r * 0.17), ring + Offset(0, r * 0.5), st);
  for (final s in <double>[-1, 1]) {
    for (var i = 0; i < 3; i++) {
      c.drawLine(ring + Offset(s * r * 0.015 * i, r * 0.3), ring + Offset(s * r * (0.14 + i * 0.1), r * (0.62 + i * 0.09)), thin);
    }
    // نوار پیچ‌خورده‌ی کنار حلقه
    final rib = Path()
      ..moveTo(ring.dx + s * r * 0.15, ring.dy + r * 0.12)
      ..cubicTo(ring.dx + s * r * 0.45, ring.dy + r * 0.2, ring.dx + s * r * 0.55, ring.dy + r * 0.45, ring.dx + s * r * 0.4, ring.dy + r * 0.55);
    c.drawPath(rib, st);
    c.drawCircle(ring + Offset(s * r * 0.36, r * 0.55), r * 0.045, st);
  }
  c.drawLine(ring + Offset(0, r * 0.5), ring + Offset(0, r * 0.92), st);
  c.drawLine(ring + Offset(0, r * 0.5), ring + Offset(-r * 0.12, r * 0.9), thin);
  c.drawLine(ring + Offset(0, r * 0.5), ring + Offset(r * 0.12, r * 0.9), thin);
}

/// آدم بال‌دار هخامنشی: تاج پردار، جامه‌ی بلند، دست با گل و دو بال برافراشته
void _wingedMan(Canvas c, Offset o, double r, Color col) {
  final p = Paint()..color = col;
  final fill = Paint()..color = col.withOpacity(col.opacity * 0.35);
  final st = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.1, r * 0.03)
    ..strokeCap = StrokeCap.round
    ..color = col;
  final thin = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(0.8, r * 0.018)
    ..strokeCap = StrokeCap.round
    ..color = col;
  final head = o + Offset(0, -r * 0.55);
  // بال‌ها: دو ردیف رو به بالا و بیرون، یک ردیف رو به پایین
  for (final s in <double>[-1, 1]) {
    for (var tier = 0; tier < 3; tier++) {
      final y = o.dy - r * 0.42 + tier * r * 0.1;
      final path = Path()
        ..moveTo(o.dx + s * r * 0.12, y)
        ..quadraticBezierTo(o.dx + s * r * (0.55 - tier * 0.05), y - r * 0.34, o.dx + s * r * (0.92 - tier * 0.1), y - r * (0.5 - tier * 0.12));
      c.drawPath(path, st);
      _feathers(c, path, r * 0.17, thin, 8 - tier, -s);
    }
    final low = Path()
      ..moveTo(o.dx + s * r * 0.14, o.dy - r * 0.1)
      ..quadraticBezierTo(o.dx + s * r * 0.6, o.dy - r * 0.05, o.dx + s * r * 0.7, o.dy + r * 0.4);
    c.drawPath(low, st);
    _feathers(c, low, r * 0.15, thin, 7, s);
    // دست برافراشته با گل
    c.drawLine(o + Offset(s * r * 0.13, -r * 0.4), o + Offset(s * r * 0.3, -r * 0.18), st);
    c.drawCircle(o + Offset(s * r * 0.33, -r * 0.2), r * 0.045, st);
  }
  // جامه‌ی بلند
  final robe = Path()
    ..moveTo(o.dx - r * 0.13, o.dy - r * 0.44)
    ..lineTo(o.dx + r * 0.13, o.dy - r * 0.44)
    ..lineTo(o.dx + r * 0.22, o.dy + r * 0.78)
    ..lineTo(o.dx - r * 0.22, o.dy + r * 0.78)
    ..close();
  c.drawPath(robe, fill);
  c.drawPath(robe, st);
  for (var i = 0; i < 3; i++) {
    final y = o.dy + r * (0.52 + i * 0.09);
    c.drawLine(Offset(o.dx - r * 0.2, y), Offset(o.dx + r * 0.2, y), thin);
  }
  c.drawLine(o + Offset(0, -r * 0.3), o + Offset(0, r * 0.5), thin);
  // سر و تاج پردار
  c.drawCircle(head, r * 0.085, p);
  final crown = Path()
    ..moveTo(head.dx - r * 0.1, head.dy - r * 0.07)
    ..lineTo(head.dx - r * 0.13, head.dy - r * 0.2)
    ..lineTo(head.dx + r * 0.13, head.dy - r * 0.2)
    ..lineTo(head.dx + r * 0.1, head.dy - r * 0.07)
    ..close();
  c.drawPath(crown, st);
  for (var i = -2; i <= 2; i++) {
    c.drawLine(head + Offset(i * r * 0.05, -r * 0.2), head + Offset(i * r * 0.065, -r * 0.29), thin);
  }
  // پاها
  c.drawLine(o + Offset(-r * 0.1, r * 0.78), o + Offset(-r * 0.1, r * 0.9), st);
  c.drawLine(o + Offset(r * 0.1, r * 0.78), o + Offset(r * 0.1, r * 0.9), st);
}

/// مهره با شیار و سایه؛ [pl] ۰ یا ۱
void paintBgChecker(Canvas canvas, Offset c, double r, int pl, BgTheme t) {
  final base = pl == 0 ? t.checkerA : t.checkerB;
  final ring = pl == 0 ? t.ringA : t.ringB;
  canvas.drawCircle(c + Offset(0, r * 0.14), r, Paint()..color = const Color(0x66000000));
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: <Color>[Color.lerp(base, Colors.white, 0.45) ?? base, base, Color.lerp(base, Colors.black, 0.28) ?? base],
        stops: const <double>[0, 0.6, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  for (var g = 1; g <= (t.grooves == 0 ? 1 : t.grooves); g++) {
    canvas.drawCircle(
      c,
      r * (1 - 0.22 * g),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, r * 0.07)
        ..color = Colors.black.withOpacity(t.grooves == 0 ? .2 : .26),
    );
  }
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, r * 0.08)
      ..color = ring,
  );
}

/// پیش‌نمایش کوچک یک طرح (برای برگه‌ی تنظیمات)
class BgBoardPreview extends StatelessWidget {
  const BgBoardPreview({super.key, required this.theme, this.width = 150});
  final BgTheme theme;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: width * 1.1, child: CustomPaint(painter: _PreviewPainter(theme)));
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.t);
  final BgTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = size.width * 0.04;
    paintBgBoard(canvas, size, t, pad: pad);
    final laneW = (size.width - 2 * pad) / 2;
    final rh = (size.height - 2 * pad) / 12.9;
    final barH = rh * 0.9;
    for (var i = 0; i < 24; i++) {
      final left = i < 12;
      final row = left ? 11 - i : i - 12;
      final top = pad + row * rh + (row >= 6 ? barH : 0);
      final col = (row + (left ? 0 : 1)).isEven ? t.ptA : t.ptB;
      final path = Path();
      if (left) {
        path
          ..moveTo(pad, top + 1)
          ..lineTo(pad, top + rh - 1)
          ..lineTo(pad + laneW * 0.94, top + rh / 2)
          ..close();
      } else {
        final r = pad + 2 * laneW;
        path
          ..moveTo(r, top + 1)
          ..lineTo(r, top + rh - 1)
          ..lineTo(r - laneW * 0.94, top + rh / 2)
          ..close();
      }
      canvas.drawPath(path, Paint()..color = col);
      if (t.ptLine.opacity > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = t.ptLine,
        );
      }
    }
    canvas.drawRect(Rect.fromLTWH(pad, pad + 6 * rh, size.width - 2 * pad, barH), Paint()..color = t.bar);
    final r = rh * 0.42;
    for (var k = 0; k < 4; k++) {
      paintBgChecker(canvas, Offset(pad + r + 1 + k * rh * 0.7, pad + rh * 11.5), r, 0, t);
      paintBgChecker(canvas, Offset(pad + 2 * laneW - r - 1 - k * rh * 0.7, pad + rh * 0.5), r, 1, t);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.t != t;
}
