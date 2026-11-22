import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'hokm_engine.dart' show HCard, kSuitChar;
import 'hokm_prefs.dart';

/// اجزای تصویری «حکم»: کارت، پشت کارت، زمینه، آواتار.

const List<List<double>> _pip2 = <List<double>>[];

int hokmClamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

/// جای خال‌ها روی کارت (درصد عرض و ارتفاع)
const Map<int, List<List<double>>> _pips = <int, List<List<double>>>{
  2: [[50, 18], [50, 82]],
  3: [[50, 18], [50, 50], [50, 82]],
  4: [[30, 18], [70, 18], [30, 82], [70, 82]],
  5: [[30, 18], [70, 18], [50, 50], [30, 82], [70, 82]],
  6: [[30, 18], [70, 18], [30, 50], [70, 50], [30, 82], [70, 82]],
  7: [[30, 18], [70, 18], [50, 34], [30, 50], [70, 50], [30, 82], [70, 82]],
  8: [[30, 18], [70, 18], [50, 34], [30, 50], [70, 50], [50, 66], [30, 82], [70, 82]],
  9: [[30, 18], [70, 18], [30, 39], [70, 39], [30, 61], [70, 61], [30, 82], [70, 82], [50, 50]],
  10: [[30, 18], [70, 18], [50, 29], [30, 39], [70, 39], [30, 61], [70, 61], [50, 71], [30, 82], [70, 82]],
};

class _FaceStyle {
  const _FaceStyle(this.bg, this.border, this.ink, this.black, this.heart, this.diamond, this.club, {this.radius = 0.09, this.single = false, this.bg2, this.frame});
  final Color bg;
  final Color border;
  final Color ink;
  final Color black;
  final Color heart;
  final Color diamond;
  final Color club;
  final double radius;

  /// چیدمان «تک‌نماد»: یک نماد بزرگ در وسط و عدد درشت در گوشه (به‌جای چند خال)
  final bool single;

  /// رنگ دوم پس‌زمینه (اگر باشد کارت گرادیان می‌شود)
  final Color? bg2;

  /// رنگ قاب تزئینی داخل کارت
  final Color? frame;
  Color suit(int s) => s == 0 ? black : (s == 1 ? heart : (s == 2 ? diamond : club));
}

const List<_FaceStyle> _faces = <_FaceStyle>[
  _FaceStyle(Color(0xffffffff), Color(0xffbbbbbb), Color(0xff111111), Color(0xff111111), Color(0xffd62828), Color(0xffd62828), Color(0xff111111)),
  _FaceStyle(Color(0xffffffff), Color(0xffbbbbbb), Color(0xff111111), Color(0xff111111), Color(0xffd62828), Color(0xff1f5fd6), Color(0xff16883a)),
  _FaceStyle(Color(0xff1b2133), Color(0xff46537a), Color(0xffe8ecf5), Color(0xffe8ecf5), Color(0xffff6b6b), Color(0xffffb454), Color(0xff7ee0a5)),
  _FaceStyle(Color(0xfff6ecd0), Color(0xffbda35c), Color(0xff2b2118), Color(0xff2b2118), Color(0xffa8222b), Color(0xffa8222b), Color(0xff2b2118), radius: 0.05),
  _FaceStyle(Color(0xffeef2ff), Color(0xff9fb0e8), Color(0xff1f2a44), Color(0xff1f2a44), Color(0xffe5484d), Color(0xfff08a24), Color(0xff2a9d6a), radius: 0.13),
  // ۵: تک‌نماد رنگی (پیک سرمه‌ای، دل قرمز، خشت نارنجی، خاج سبزآبی)
  _FaceStyle(Color(0xfffdfdfb), Color(0xffc9ced8), Color(0xff1f2a44), Color(0xff1f2a44), Color(0xffe5484d), Color(0xfff08a24), Color(0xff1f9d8a), radius: 0.1, single: true),
  // ۶: طلایی
  _FaceStyle(Color(0xfffff3c4), Color(0xffa8741a), Color(0xff3a2410), Color(0xff2b1a0c), Color(0xff9c1c1c), Color(0xffb8450f), Color(0xff1f5a3a), radius: 0.1, single: true, bg2: Color(0xffe9c45f), frame: Color(0xffa8741a)),
  // ۷: مشکی-طلایی
  _FaceStyle(Color(0xff1d1d24), Color(0xffd4a83a), Color(0xfff1d98a), Color(0xfff4efe2), Color(0xffff5a5f), Color(0xffff9f43), Color(0xffe8c15a), radius: 0.1, single: true, bg2: Color(0xff0b0b0f), frame: Color(0xffd4a83a)),
];

/// رنگ هر خال با توجه به طرح روی کارت (برای نوشته‌ها و نشان‌ها)
Color hokmSuitColor(int suit, [int? face]) => _faces[hokmClamp(face ?? HokmPrefs.instance.face, 0, _faces.length - 1)].suit(suit);

/// کارت رو شده. عرض = [w]، ارتفاع = ۱٫۴ برابر.
/// [trump] برای کارت‌های خال حکم: قاب طلایی ملایم.
class HokmCardView extends StatelessWidget {
  const HokmCardView({super.key, required this.card, required this.w, this.face, this.ring, this.dim = false, this.trump = false});
  final HCard card;
  final double w;
  final int? face;
  final Color? ring;
  final bool dim;
  final bool trump;

  @override
  Widget build(BuildContext context) {
    final st = _faces[hokmClamp(face ?? HokmPrefs.instance.face, 0, _faces.length - 1)];
    final h = w * 1.4;
    final y = kSuitChar[card.suit];
    final col = st.suit(card.suit);
    final r = card.rank;
    final label = card.rankLabel;
    final List<Widget> kids = st.single ? _singleKids(st, col, y, r, label) : _classicKids(st, col, y, r, label);
    final borderCol = ring ?? (trump ? const Color(0xffffc83d) : st.border);
    final borderW = ring != null ? w * .045 : (trump ? w * .03 : w * .012);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: st.bg2 == null ? st.bg : null,
        gradient: st.bg2 == null ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[st.bg, st.bg2!]),
        borderRadius: BorderRadius.circular(w * st.radius),
        border: Border.all(color: borderCol, width: borderW),
        boxShadow: <BoxShadow>[
          if (ring != null) BoxShadow(color: ring!.withOpacity(.65), blurRadius: w * .2, spreadRadius: w * .02),
          if (ring == null && trump) BoxShadow(color: const Color(0xffffc83d).withOpacity(.45), blurRadius: w * .16),
          BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: w * .09, offset: Offset(0, w * .03)),
        ],
      ),
      child: Stack(
        children: [
          ...kids,
          if (dim) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withOpacity(.45), borderRadius: BorderRadius.circular(w * st.radius)))),
        ],
      ),
    );
  }

  /// چیدمان قدیمی (خال‌های سنتی)
  List<Widget> _classicKids(_FaceStyle st, Color col, String y, int r, String label) {
    Widget mid;
    if (r >= 11) {
      mid = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * .5, height: 1)),
            HokmSuit(card.suit, w * .313, col),
          ],
        ),
      );
    } else if (r == 14) {
      mid = Center(child: HokmSuit(card.suit, w * .570, col));
    } else {
      mid = Stack(
        children: [
          for (final p in _pips[r] ?? _pip2)
            Align(
              alignment: Alignment(p[0] / 50 - 1, p[1] / 50 - 1),
              child: Transform.rotate(angle: p[1] > 50 ? pi : 0, child: HokmSuit(card.suit, w * .248, col)),
            ),
        ],
      );
    }
    Widget corner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * .26, height: 1)),
            HokmSuit(card.suit, w * .202, col),
          ],
        );
    return <Widget>[
      Padding(padding: EdgeInsets.symmetric(horizontal: w * .1, vertical: w * .22), child: mid),
      Positioned(left: w * .06, top: w * .04, child: corner()),
      Positioned(right: w * .06, bottom: w * .04, child: Transform.rotate(angle: pi, child: corner())),
    ];
  }

  /// چیدمان «تک‌نماد»: یک نماد بزرگ وسط کارت، عدد و نماد درشت در گوشه (در بادبزن دست هم خوانا می‌ماند)
  List<Widget> _singleKids(_FaceStyle st, Color col, String y, int r, String label) {
    Widget corner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: label.length > 1 ? w * .27 : w * .33, height: 1)),
            HokmSuit(card.suit, w * .239, col),
          ],
        );
    final accent = st.frame ?? col;
    Widget center;
    if (r == 14) {
      center = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: w * .68,
            height: w * .68,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent.withOpacity(.75), width: w * .016)),
          ),
          HokmSuit(card.suit, w * .552, col),
        ],
      );
    } else if (r >= 11) {
      center = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: w * .38, height: w * .2, child: CustomPaint(painter: _CrownPainter(r, accent))),
          Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * .4, height: 1)),
          HokmSuit(card.suit, w * .276, col),
        ],
      );
    } else {
      center = HokmSuit(card.suit, w * .644, col);
    }
    return <Widget>[
      if (st.frame != null)
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(w * .035),
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(w * .06), border: Border.all(color: st.frame!.withOpacity(.8), width: w * .01)),
            ),
          ),
        ),
      Center(child: center),
      Positioned(left: w * .07, top: w * .045, child: corner()),
      Positioned(right: w * .07, bottom: w * .045, child: Transform.rotate(angle: pi, child: corner())),
    ];
  }
}

/// نشان بالای حرف کارت‌های تصویری: تاج شاه، تاج بی‌بی، پَر کلاه سرباز
class _CrownPainter extends CustomPainter {
  _CrownPainter(this.rank, this.col);
  final int rank;
  final Color col;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final fill = Paint()..color = col;
    if (rank == 13) {
      final p = Path()
        ..moveTo(0, h)
        ..lineTo(0, h * .35)
        ..lineTo(w * .25, h * .65)
        ..lineTo(w * .5, 0)
        ..lineTo(w * .75, h * .65)
        ..lineTo(w, h * .35)
        ..lineTo(w, h)
        ..close();
      c.drawPath(p, fill);
      c.drawCircle(Offset(w * .5, h * .06), h * .09, fill);
    } else if (rank == 12) {
      final p = Path()
        ..moveTo(w * .08, h)
        ..lineTo(0, h * .45)
        ..lineTo(w * .3, h * .7)
        ..lineTo(w * .5, h * .25)
        ..lineTo(w * .7, h * .7)
        ..lineTo(w, h * .45)
        ..lineTo(w * .92, h)
        ..close();
      c.drawPath(p, fill);
      c.drawCircle(Offset(0, h * .38), h * .08, fill);
      c.drawCircle(Offset(w * .5, h * .12), h * .08, fill);
      c.drawCircle(Offset(w, h * .38), h * .08, fill);
    } else {
      final st = Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .14
        ..strokeCap = StrokeCap.round;
      for (var i = -2; i <= 2; i++) {
        c.drawLine(Offset(w * .5 + i * w * .1, h * .95), Offset(w * .5 + i * w * .22, h * .15 + i.abs() * h * .1), st);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrownPainter o) => o.rank != rank || o.col != col;
}

class _BackColors {
  const _BackColors(this.a, this.b, this.kind);
  final Color a;
  final Color b;
  final int kind; // 0 پرتو، ۱ راه‌راه مورب، ۲ لوزی، ۳ نقطه
}

const List<_BackColors> _backs = <_BackColors>[
  _BackColors(Color(0xff17407a), Color(0xff2c6cb8), 0),
  _BackColors(Color(0xff8b1a1a), Color(0xffb13030), 1),
  _BackColors(Color(0xff0f5a34), Color(0xff1a8250), 0),
  _BackColors(Color(0xff2a2112), Color(0xffd9a93f), 2),
  _BackColors(Color(0xff4a1f7a), Color(0xffecc9ff), 3),
  _BackColors(Color(0xff15151c), Color(0xff3a3a48), 2),
  _BackColors(Color(0xff0a5159), Color(0xff0e7c86), 1),
];

class _BackPainter extends CustomPainter {
  _BackPainter(this.i);
  final int i;

  @override
  void paint(Canvas c, Size s) {
    if (i >= _backs.length) {
      _paintArt(c, s, _art[hokmClamp(i - _backs.length, 0, _art.length - 1)]);
      return;
    }
    final b = _backs[hokmClamp(i, 0, _backs.length - 1)];
    final r = Rect.fromLTWH(0, 0, s.width, s.height);
    c.drawRect(r, Paint()..color = b.a);
    final p = Paint()
      ..color = b.b
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .05;
    final step = s.width * .16;
    switch (b.kind) {
      case 0:
        final cen = r.center;
        for (var k = 0; k < 24; k += 2) {
          final a0 = k * pi / 12;
          c.drawArc(Rect.fromCircle(center: cen, radius: s.height), a0, pi / 12, true, Paint()..color = b.b);
        }
        break;
      case 1:
        for (var x = -s.height; x < s.width + s.height; x += step) {
          c.drawLine(Offset(x, 0), Offset(x + s.height, s.height), p);
        }
        break;
      case 2:
        for (var x = -s.height; x < s.width + s.height; x += step * 1.4) {
          c.drawLine(Offset(x, 0), Offset(x + s.height, s.height), p..strokeWidth = s.width * .02);
          c.drawLine(Offset(x + s.height, 0), Offset(x, s.height), p);
        }
        break;
      default:
        final d = Paint()..color = b.b;
        for (var y = step / 2; y < s.height; y += step) {
          for (var x = step / 2; x < s.width; x += step) {
            c.drawCircle(Offset(x, y), s.width * .03, d);
          }
        }
    }
    c.drawCircle(r.center, s.width * .1, Paint()..color = const Color(0xffe8c880));
    c.drawRect(r.deflate(s.width * .06), Paint()
      ..color = const Color(0xccf3e6c4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .016);
  }

  @override
  bool shouldRepaint(covariant _BackPainter o) => o.i != i;
}

class HokmBackView extends StatelessWidget {
  const HokmBackView({super.key, required this.w, this.back});
  final double w;
  final int? back;

  @override
  Widget build(BuildContext context) {
    final i = back ?? HokmPrefs.instance.back;
    return Container(
      width: w,
      height: w * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w * .09),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: w * .08, offset: Offset(0, w * .03))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(w * .09), child: RepaintBoundary(child: CustomPaint(painter: _BackPainter(i)))),
    );
  }
}

// ------------------------------------------------------------------ زمینه

class _BgPainter extends CustomPainter {
  _BgPainter(this.i);
  final int i;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    Paint radial(Color a, Color b) => Paint()..shader = RadialGradient(center: const Alignment(0, -.2), radius: 1.1, colors: [a, b]).createShader(r);
    switch (i) {
      case 0: // چوب
        c.drawRect(r, Paint()..color = const Color(0xffc98a4b));
        final w = s.width / 7;
        for (var k = 0; k < 7; k++) {
          c.drawRect(Rect.fromLTWH(k * w, 0, w, s.height), Paint()..color = k.isEven ? const Color(0xffcf9356) : const Color(0xffbd7d41));
          c.drawRect(Rect.fromLTWH(k * w, 0, 1.5, s.height), Paint()..color = const Color(0x33000000));
        }
        break;
      case 1:
        c.drawRect(r, radial(const Color(0xff23903f), const Color(0xff0b4a22)));
        break;
      case 2:
        c.drawRect(r, radial(const Color(0xff2a6fc0), const Color(0xff0a2a58)));
        break;
      case 3: // فرش قرمز
        c.drawRect(r, Paint()..color = const Color(0xff8a1426));
        for (var k = 1; k < 14; k++) {
          c.drawCircle(
            r.center,
            k * s.height / 22,
            Paint()
              ..color = k % 3 == 0 ? const Color(0xffb08a35) : (k.isEven ? const Color(0xff6d0e1e) : const Color(0xff8a1426))
              ..style = PaintingStyle.stroke
              ..strokeWidth = k % 3 == 0 ? 2 : s.height / 30,
          );
        }
        break;
      case 4: // مشکی و طلایی
        c.drawRect(r, radial(const Color(0xff2a2314), const Color(0xff0b0905)));
        final p = Paint()
          ..color = const Color(0x33d6a93a)
          ..strokeWidth = 1;
        for (var x = -s.height; x < s.width + s.height; x += 18) {
          c.drawLine(Offset(x, 0), Offset(x + s.height, s.height), p);
        }
        break;
      case 5:
        c.drawRect(r, radial(const Color(0xff7a34a6), const Color(0xff2a0f45)));
        break;
      case 6:
        c.drawRect(r, radial(const Color(0xff14a0a0), const Color(0xff06353f)));
        break;
      case 8: // کازینوی نئونی
        c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff5b1f9a), Color(0xff1a0b3d)]).createShader(r));
        _glowAt(c, Offset(s.width * .95, s.height * .05), s.height * .5, const Color(0x99ff8a2a));
        _glowAt(c, Offset(s.width * .05, s.height * .95), s.height * .5, const Color(0x88e0309a));
        _bokeh(c, s, const [Color(0xffffb347), Color(0xffff5fa2), Color(0xffa070ff)], 26, 8);
        _suitMark(c, kSuitChar[3], Offset(s.width * .14, s.height * .9), s.width * .55, Colors.white.withOpacity(.07), -.3);
        _suitMark(c, kSuitChar[1], Offset(s.width * .9, s.height * .55), s.width * .45, Colors.white.withOpacity(.07), .25);
        _suitMark(c, kSuitChar[0], Offset(s.width * .2, s.height * .12), s.width * .4, Colors.white.withOpacity(.06), .2);
        break;
      case 9: // زمرد شاهانه
        c.drawRect(r, radial(const Color(0xff1f9a58), const Color(0xff083d22)));
        final lp = Paint()
          ..color = Colors.white.withOpacity(.07)
          ..strokeWidth = 1.2;
        for (var x = -s.height; x < s.width + s.height; x += 38) {
          c.drawLine(Offset(x, 0), Offset(x + s.height, s.height), lp);
          c.drawLine(Offset(x + s.height, 0), Offset(x, s.height), lp);
        }
        _suitMark(c, kSuitChar[2], Offset(s.width * .5, s.height * .5), s.width * .9, Colors.white.withOpacity(.05), 0);
        break;
      case 10: // شب ستاره‌باران
        c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xff0a1240), Color(0xff2d1f73)]).createShader(r));
        _glowAt(c, Offset(s.width * .8, s.height * .12), s.height * .35, const Color(0x55b9a6ff));
        final rn = Random(10);
        for (var k = 0; k < 80; k++) {
          c.drawCircle(Offset(rn.nextDouble() * s.width, rn.nextDouble() * s.height), .6 + rn.nextDouble() * 1.8, Paint()..color = Colors.white.withOpacity(.35 + rn.nextDouble() * .55));
        }
        _suitMark(c, kSuitChar[0], Offset(s.width * .85, s.height * .88), s.width * .6, Colors.white.withOpacity(.05), .3);
        break;
      case 11: // یاقوت
        c.drawRect(r, radial(const Color(0xffc21a38), const Color(0xff3a0612)));
        _bokeh(c, s, const [Color(0xffffd36b), Color(0xffff8a8a)], 22, 11);
        final gp = Paint()
          ..color = const Color(0x22ffd36b)
          ..strokeWidth = 1;
        for (var y = 0.0; y < s.height; y += 26) {
          c.drawLine(Offset(0, y), Offset(s.width, y), gp);
        }
        _suitMark(c, kSuitChar[1], Offset(s.width * .5, s.height * .55), s.width * .85, Colors.white.withOpacity(.05), 0);
        break;
      case 12: // تخت جمشید: سنگ ماسه‌ای با نقش گل‌های رزت
        c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xffdcc79f), Color(0xff9c8157)]).createShader(r));
        final rp = Paint()..color = const Color(0x2a4a3520);
        const step = 64.0;
        for (var y = step / 2; y < s.height + step; y += step) {
          final shift = ((y / step).floor() % 2 == 0) ? 0.0 : step / 2;
          for (var x = step / 2 + shift; x < s.width + step; x += step) {
            for (var k = 0; k < 8; k++) {
              c.save();
              c.translate(x, y);
              c.rotate(k * pi / 4);
              c.drawOval(Rect.fromCenter(center: const Offset(0, -10), width: 8, height: 18), rp);
              c.restore();
            }
            c.drawCircle(Offset(x, y), 3, rp);
          }
        }
        break;
      case 13: // فیروزه‌ی نیشابور: الگوی دایره‌های درهم
        c.drawRect(r, radial(const Color(0xff1cc0b8), const Color(0xff04414c)));
        final tp = Paint()
          ..color = const Color(0x22ffffff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        const rad = 28.0;
        var row = 0;
        for (var y = 0.0; y < s.height + rad; y += rad * .87) {
          for (var x = row.isOdd ? rad / 2 : 0.0; x < s.width + rad; x += rad) {
            c.drawCircle(Offset(x, y), rad, tp);
          }
          row++;
        }
        break;
      default:
        c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffd9ccac), Color(0xff9b8d6e)]).createShader(r));
    }
    c.drawRect(r, Paint()..shader = RadialGradient(radius: 1.0, colors: [Colors.transparent, Colors.black.withOpacity(.42)], stops: const [.55, 1]).createShader(r));
  }

  void _glowAt(Canvas c, Offset o, double rad, Color col) {
    c.drawCircle(o, rad, Paint()..shader = RadialGradient(colors: [col, col.withOpacity(0)]).createShader(Rect.fromCircle(center: o, radius: rad)));
  }

  void _bokeh(Canvas c, Size s, List<Color> cols, int n, int seed) {
    final rnd = Random(seed);
    for (var k = 0; k < n; k++) {
      final x = rnd.nextDouble() * s.width;
      final y = rnd.nextDouble() * s.height;
      final rad = s.width * (.02 + rnd.nextDouble() * .07);
      c.drawCircle(Offset(x, y), rad, Paint()..color = cols[rnd.nextInt(cols.length)].withOpacity(.1 + rnd.nextDouble() * .12));
    }
  }

  void _suitMark(Canvas c, String ch, Offset at, double size, Color col, double rot) {
    final idx = kSuitChar.indexOf(ch);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(rot);
    c.drawPath(hokmSuitPath(idx < 0 ? 0 : idx, size).shift(Offset(-size / 2, -size / 2)), Paint()..color = col);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _BgPainter o) => o.i != i;
}

class HokmBackground extends StatelessWidget {
  const HokmBackground({super.key, this.index});
  final int? index;

  @override
  Widget build(BuildContext context) => SizedBox.expand(child: CustomPaint(painter: _BgPainter(index ?? HokmPrefs.instance.bg)));
}

// ------------------------------------------------------------------ آواتار

class HokmAvatar extends StatelessWidget {
  const HokmAvatar({super.key, required this.avatar, this.size = 40, this.border});
  final String avatar;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (avatar.length > 6 && int.tryParse(avatar) == null) {
      try {
        inner = Image.memory(base64Decode(avatar), fit: BoxFit.cover, width: size, height: size, gaplessPlayback: true);
      } catch (_) {
        inner = const SizedBox.shrink();
      }
    } else {
      final i = hokmClamp(int.tryParse(avatar) ?? 0, 0, HokmPrefs.avatars.length - 1);
      final a = HokmPrefs.avatars[i];
      inner = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a[1] as Color, a[2] as Color])),
        child: Text(a[0] as String, style: TextStyle(fontSize: size * .55)),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border ?? Colors.white70, width: 2)),
      child: ClipOval(child: inner),
    );
  }
}

// ------------------------------------------------------------------ دکمه‌ی طلایی با سایه

enum HokmBtnStyle { gold, dark, green, red }

class HokmButton extends StatefulWidget {
  const HokmButton({super.key, required this.title, this.sub, this.icon, this.onTap, this.style = HokmBtnStyle.gold});
  final String title;
  final String? sub;
  final IconData? icon;
  final VoidCallback? onTap;
  final HokmBtnStyle style;

  @override
  State<HokmButton> createState() => _HokmButtonState();
}

class _HokmButtonState extends State<HokmButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    late final List<Color> g;
    late final Color edge;
    late final Color fg;
    switch (widget.style) {
      case HokmBtnStyle.dark:
        g = const [Color(0xff5a2a47), Color(0xff3a1230)];
        edge = const Color(0xff1a0414);
        fg = const Color(0xffe8bb55);
        break;
      case HokmBtnStyle.green:
        g = const [Color(0xff35d69a), Color(0xff129063)];
        edge = const Color(0xff08573b);
        fg = Colors.white;
        break;
      case HokmBtnStyle.red:
        g = const [Color(0xffee6a5f), Color(0xffb82b22)];
        edge = const Color(0xff6e140f);
        fg = Colors.white;
        break;
      default:
        g = const [Color(0xfffff3cf), Color(0xffe9c777)];
        edge = const Color(0xff8a5d12);
        fg = const Color(0xff3a1a05);
    }
    final enabled = widget.onTap != null;
    final lift = _down ? 1.0 : 4.0;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, 4 - lift, 0),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: g),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(color: edge, offset: Offset(0, lift)),
              BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 16, offset: Offset(0, lift + 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 24), const SizedBox(width: 10)],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 17, height: 1.3)),
                    if (widget.sub != null) Text(widget.sub!, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: TextStyle(color: fg.withOpacity(.75), fontSize: 11.5, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// لوگوی سایروس توریست (گوشه‌ی بالا سمت چپ)
class HokmLogo extends StatelessWidget {
  const HokmLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xffe8bb55), width: 2),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipOval(child: Image.asset('assets/images/logo-new.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white))),
    );
  }
}

// ------------------------------------------------------------------ خال‌ها به‌صورت شکل برداری
// خال‌ها با Path کشیده می‌شوند، نه با نویسه‌ی متنی؛ چون روی بعضی گوشی‌ها پیک و خاج با فونت ایموجی
// (سیاه و بی‌توجه به رنگ) نشان داده می‌شدند و روی کارت تیره دیده نمی‌شدند.

/// مسیر خال در مربع [s]×[s]. ۰ پیک، ۱ دل، ۲ خشت، ۳ خاج.
Path hokmSuitPath(int suit, double s) {
  double x(double v) => v * s;
  switch (suit) {
    case 1:
      return Path()
        ..moveTo(x(.5), x(.92))
        ..cubicTo(x(.04), x(.60), x(0), x(.30), x(.22), x(.15))
        ..cubicTo(x(.36), x(.06), x(.5), x(.14), x(.5), x(.30))
        ..cubicTo(x(.5), x(.14), x(.64), x(.06), x(.78), x(.15))
        ..cubicTo(x(1), x(.30), x(.96), x(.60), x(.5), x(.92))
        ..close();
    case 2:
      return Path()
        ..moveTo(x(.5), x(.03))
        ..lineTo(x(.86), x(.5))
        ..lineTo(x(.5), x(.97))
        ..lineTo(x(.14), x(.5))
        ..close();
    case 0:
      return Path()
        ..moveTo(x(.5), x(.04))
        ..cubicTo(x(.96), x(.38), x(1), x(.66), x(.76), x(.76))
        ..cubicTo(x(.64), x(.81), x(.54), x(.76), x(.52), x(.68))
        ..lineTo(x(.62), x(.96))
        ..lineTo(x(.38), x(.96))
        ..lineTo(x(.48), x(.68))
        ..cubicTo(x(.46), x(.76), x(.36), x(.81), x(.24), x(.76))
        ..cubicTo(x(0), x(.66), x(.04), x(.38), x(.5), x(.04))
        ..close();
    default:
      Path u(Path a, Path b) => Path.combine(PathOperation.union, a, b);
      var p = Path()..addOval(Rect.fromCircle(center: Offset(x(.5), x(.27)), radius: x(.21)));
      p = u(p, Path()..addOval(Rect.fromCircle(center: Offset(x(.26), x(.58)), radius: x(.21))));
      p = u(p, Path()..addOval(Rect.fromCircle(center: Offset(x(.74), x(.58)), radius: x(.21))));
      p = u(p, Path()..addOval(Rect.fromCircle(center: Offset(x(.5), x(.5)), radius: x(.14))));
      p = u(p, Path()
        ..moveTo(x(.5), x(.52))
        ..lineTo(x(.62), x(.96))
        ..lineTo(x(.38), x(.96))
        ..close());
      return p;
  }
}

/// خال با رنگ دقیقاً مشخص (مستقل از فونت دستگاه). [shadow] سایه‌ی ملایم زیر خال می‌اندازد.
class HokmSuit extends StatelessWidget {
  const HokmSuit(this.suit, this.size, this.color, {super.key, this.shadow = false});
  final int suit;
  final double size;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _SuitPainter(suit, color, shadow)));
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color, this.shadow);
  final int suit;
  final Color color;
  final bool shadow;

  @override
  void paint(Canvas c, Size s) {
    final path = hokmSuitPath(suit, s.width);
    if (shadow) {
      c.drawPath(path.shift(Offset(0, s.width * .05)), Paint()..color = Colors.black.withOpacity(.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * .05));
    }
    c.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(covariant _SuitPainter o) => o.suit != suit || o.color != color || o.shadow != shadow;
}

// ------------------------------------------------------------------ پشت کارت‌های ایرانی
// هر طرح فهرستی از دستورهای ساده است (مختصات بر حسب عرض کارت؛ ارتفاع = ۱٫۴).
// نوع: 0 پس‌زمینه‌ی گرادیان، 1 درخشش، 2 دایره، 3 بیضی چرخیده، 4 چندضلعی، 5 خط، 6 مسیر.

class _Op {
  const _Op(this.k, this.c, this.p, {this.c2 = 0, this.w = 0, this.f = true});
  final int k;
  final int c;
  final int c2;
  final List<double> p;
  final double w;
  final bool f;
}

void _paintArt(Canvas c, Size s, List<_Op> ops) {
  final w = s.width;
  Paint fill(int col) => Paint()
    ..color = Color(col)
    ..isAntiAlias = true;
  Paint stroke(int col, double sw) => Paint()
    ..color = Color(col)
    ..style = PaintingStyle.stroke
    ..strokeWidth = sw * w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  final full = Offset.zero & s;
  for (final o in ops) {
    final p = o.p;
    switch (o.k) {
      case 0:
        c.drawRect(full, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(o.c), Color(o.c2)]).createShader(full));
        break;
      case 1:
        final center = Offset(p[0] * w, p[1] * w);
        final base = Color(o.c);
        c.drawCircle(center, p[2] * w, Paint()..shader = RadialGradient(colors: <Color>[base.withOpacity(base.opacity * .6), base.withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: p[2] * w)));
        break;
      case 2:
        if (o.f) {
          c.drawCircle(Offset(p[0] * w, p[1] * w), p[2] * w, fill(o.c));
        } else {
          c.drawCircle(Offset(p[0] * w, p[1] * w), p[2] * w - o.w * w / 2, stroke(o.c, o.w));
        }
        break;
      case 3:
        c.save();
        c.translate(p[0] * w, p[1] * w);
        c.rotate(p[4] * pi / 180);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: p[2] * 2 * w, height: p[3] * 2 * w), fill(o.c));
        c.restore();
        break;
      case 4:
        final poly = Path()..moveTo(p[0] * w, p[1] * w);
        for (var j = 2; j + 1 < p.length; j += 2) {
          poly.lineTo(p[j] * w, p[j + 1] * w);
        }
        poly.close();
        c.drawPath(poly, o.f ? fill(o.c) : stroke(o.c, o.w));
        break;
      case 5:
        c.drawLine(Offset(p[0] * w, p[1] * w), Offset(p[2] * w, p[3] * w), stroke(o.c, o.w));
        break;
      default:
        final path = Path();
        var i = 0;
        while (i < p.length) {
          final cmd = p[i].toInt();
          i++;
          if (cmd == 0) {
            path.moveTo(p[i] * w, p[i + 1] * w);
            i += 2;
          } else if (cmd == 1) {
            path.lineTo(p[i] * w, p[i + 1] * w);
            i += 2;
          } else if (cmd == 2) {
            path.cubicTo(p[i] * w, p[i + 1] * w, p[i + 2] * w, p[i + 3] * w, p[i + 4] * w, p[i + 5] * w);
            i += 6;
          } else {
            path.close();
          }
        }
        c.drawPath(path, o.f ? fill(o.c) : stroke(o.c, o.w));
    }
  }
}

const List<List<_Op>> _art = <List<_Op>>[
  // سیمرغ
  <_Op>[
    const _Op(0, 0xff2a1450, [], c2: 0xff12082a),
    const _Op(1, 0xaa9a5cff, [0.5, 0.62, 0.55]),
    const _Op(6, 0xffe8c15a, [0.0, 0.04, 0.04, 1.0, 0.96, 0.04, 1.0, 0.96, 1.36, 1.0, 0.04, 1.36, 3.0], w: 0.014, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.07, 0.07, 1.0, 0.93, 0.07, 1.0, 0.93, 1.33, 1.0, 0.07, 1.33, 3.0], w: 0.005, f: false),
    const _Op(2, 0xffe8c15a, [0.1, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.1, 1.3, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 1.3, 0.016]),
    const _Op(3, 0xffe8c15a, [0.2, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.2, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 1.216, 0.012, 0.032, 38.0]),
    const _Op(6, 0xffe8c15a, [0.0, 0.47, 0.93, 2.0, 0.4, 1.03, 0.3, 1.06, 0.27, 1.14], w: 0.014, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.53, 0.93, 2.0, 0.6, 1.03, 0.7, 1.06, 0.73, 1.14], w: 0.014, f: false),
    const _Op(6, 0xffd9a93f, [0.0, 0.5, 0.94, 2.0, 0.5, 1.04, 0.45, 1.08, 0.43, 1.15], w: 0.012, f: false),
    const _Op(6, 0xffd9a93f, [0.0, 0.5, 0.94, 2.0, 0.5, 1.04, 0.55, 1.08, 0.57, 1.15], w: 0.012, f: false),
    const _Op(2, 0xffe8c15a, [0.27, 1.14, 0.014]),
    const _Op(2, 0xffe8c15a, [0.73, 1.14, 0.014]),
    const _Op(2, 0xffd9a93f, [0.43, 1.15, 0.012]),
    const _Op(2, 0xffd9a93f, [0.57, 1.15, 0.012]),
    const _Op(3, 0xffe8c15a, [0.2794, 0.7076, 0.04, 0.27, -52.0]),
    const _Op(3, 0xffd9a93f, [0.3394, 0.6506, 0.04, 0.27, -35.0]),
    const _Op(3, 0xffe8c15a, [0.4181, 0.6122, 0.04, 0.27, -17.0]),
    const _Op(3, 0xffd9a93f, [0.5, 0.6, 0.04, 0.27, 0.0]),
    const _Op(3, 0xffe8c15a, [0.5819, 0.6122, 0.04, 0.27, 17.0]),
    const _Op(3, 0xffd9a93f, [0.6606, 0.6506, 0.04, 0.27, 35.0]),
    const _Op(3, 0xffe8c15a, [0.7206, 0.7076, 0.04, 0.27, 52.0]),
    const _Op(2, 0xfffff1c9, [0.0745, 0.5475, 0.027]),
    const _Op(2, 0xff2a1450, [0.0745, 0.5475, 0.015]),
    const _Op(2, 0xfffff1c9, [0.0745, 0.5475, 0.006]),
    const _Op(2, 0xfffff1c9, [0.1903, 0.4377, 0.027]),
    const _Op(2, 0xff2a1450, [0.1903, 0.4377, 0.015]),
    const _Op(2, 0xfffff1c9, [0.1903, 0.4377, 0.006]),
    const _Op(2, 0xfffff1c9, [0.3421, 0.3636, 0.027]),
    const _Op(2, 0xff2a1450, [0.3421, 0.3636, 0.015]),
    const _Op(2, 0xfffff1c9, [0.3421, 0.3636, 0.006]),
    const _Op(2, 0xfffff1c9, [0.5, 0.34, 0.027]),
    const _Op(2, 0xff2a1450, [0.5, 0.34, 0.015]),
    const _Op(2, 0xfffff1c9, [0.5, 0.34, 0.006]),
    const _Op(2, 0xfffff1c9, [0.6579, 0.3636, 0.027]),
    const _Op(2, 0xff2a1450, [0.6579, 0.3636, 0.015]),
    const _Op(2, 0xfffff1c9, [0.6579, 0.3636, 0.006]),
    const _Op(2, 0xfffff1c9, [0.8097, 0.4377, 0.027]),
    const _Op(2, 0xff2a1450, [0.8097, 0.4377, 0.015]),
    const _Op(2, 0xfffff1c9, [0.8097, 0.4377, 0.006]),
    const _Op(2, 0xfffff1c9, [0.9255, 0.5475, 0.027]),
    const _Op(2, 0xff2a1450, [0.9255, 0.5475, 0.015]),
    const _Op(2, 0xfffff1c9, [0.9255, 0.5475, 0.006]),
    const _Op(3, 0xff9a6a14, [0.3819, 0.7577, 0.028, 0.15, -44.0]),
    const _Op(3, 0xff9a6a14, [0.4255, 0.7272, 0.028, 0.15, -26.0]),
    const _Op(3, 0xff9a6a14, [0.4734, 0.7121, 0.028, 0.15, -9.0]),
    const _Op(3, 0xff9a6a14, [0.5266, 0.7121, 0.028, 0.15, 9.0]),
    const _Op(3, 0xff9a6a14, [0.5745, 0.7272, 0.028, 0.15, 26.0]),
    const _Op(3, 0xff9a6a14, [0.6181, 0.7577, 0.028, 0.15, 44.0]),
    const _Op(3, 0xfffff1c9, [0.385, 0.79, 0.04, 0.12, 62.0]),
    const _Op(3, 0xffe8c15a, [0.395, 0.79, 0.028, 0.1, 62.0]),
    const _Op(3, 0xfffff1c9, [0.615, 0.79, 0.04, 0.12, -62.0]),
    const _Op(3, 0xffe8c15a, [0.605, 0.79, 0.028, 0.1, -62.0]),
    const _Op(3, 0xfffff1c9, [0.5, 0.83, 0.078, 0.108, 0.0]),
    const _Op(3, 0xffe8c15a, [0.5, 0.85, 0.052, 0.078, 0.0]),
    const _Op(3, 0xfffff1c9, [0.5, 0.705, 0.034, 0.075, 0.0]),
    const _Op(2, 0xfffff1c9, [0.5, 0.63, 0.043]),
    const _Op(4, 0xffd9a93f, [0.537, 0.622, 0.59, 0.64, 0.537, 0.651]),
    const _Op(2, 0xff2a1450, [0.517, 0.624, 0.006]),
    const _Op(6, 0xffe8c15a, [0.0, 0.49, 0.594, 2.0, 0.47, 0.56, 0.44, 0.55, 0.43, 0.51], w: 0.007, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.5, 0.59, 2.0, 0.5, 0.55, 0.48, 0.53, 0.48, 0.49], w: 0.007, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.51, 0.594, 2.0, 0.53, 0.56, 0.56, 0.55, 0.57, 0.52], w: 0.007, f: false),
    const _Op(2, 0xffe8c15a, [0.43, 0.51, 0.012]),
    const _Op(2, 0xffe8c15a, [0.48, 0.49, 0.012]),
    const _Op(2, 0xffe8c15a, [0.57, 0.52, 0.012]),
  ],
  // فروهر
  <_Op>[
    const _Op(0, 0xff0c3a52, [], c2: 0xff051c2b),
    const _Op(1, 0xaae8a33d, [0.5, 0.72, 0.5]),
    const _Op(6, 0xffe8c15a, [0.0, 0.04, 0.04, 1.0, 0.96, 0.04, 1.0, 0.96, 1.36, 1.0, 0.04, 1.36, 3.0], w: 0.014, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.07, 0.07, 1.0, 0.93, 0.07, 1.0, 0.93, 1.33, 1.0, 0.07, 1.33, 3.0], w: 0.005, f: false),
    const _Op(2, 0xffe8c15a, [0.1, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.1, 1.3, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 1.3, 0.016]),
    const _Op(3, 0xffe8c15a, [0.2, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.2, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 1.216, 0.012, 0.032, 38.0]),
    const _Op(6, 0xffe8c15a, [0.0, 0.565, 0.752, 2.0, 0.66, 0.734, 0.715, 0.739, 0.815, 0.719, 2.0, 0.755, 0.794, 0.7, 0.787, 0.565, 0.794, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.565, 0.794, 2.0, 0.7, 0.787, 0.755, 0.794, 0.815, 0.719], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.61, 0.7912, 0.627, 0.7547], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.66, 0.7827, 0.677, 0.7507], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.71, 0.7716, 0.727, 0.7441], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.76, 0.7579, 0.777, 0.7349], w: 0.004, f: false),
    const _Op(6, 0xffd9a93f, [0.0, 0.565, 0.712, 2.0, 0.66, 0.694, 0.78, 0.667, 0.88, 0.647, 2.0, 0.82, 0.722, 0.7, 0.747, 0.565, 0.754, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.565, 0.754, 2.0, 0.7, 0.747, 0.82, 0.722, 0.88, 0.647], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.623, 0.7499, 0.64, 0.7134], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.686, 0.7376, 0.703, 0.7056], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.749, 0.7201, 0.766, 0.6926], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.812, 0.6974, 0.829, 0.6744], w: 0.004, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.565, 0.672, 2.0, 0.66, 0.654, 0.845, 0.595, 0.945, 0.575, 2.0, 0.885, 0.65, 0.7, 0.707, 0.565, 0.714, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.565, 0.714, 2.0, 0.7, 0.707, 0.885, 0.65, 0.945, 0.575], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.636, 0.7086, 0.653, 0.6721], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.712, 0.6925, 0.729, 0.6605], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.788, 0.6686, 0.805, 0.6411], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.864, 0.6369, 0.881, 0.6139], w: 0.004, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.435, 0.752, 2.0, 0.34, 0.734, 0.285, 0.739, 0.185, 0.719, 2.0, 0.245, 0.794, 0.3, 0.787, 0.435, 0.794, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.435, 0.794, 2.0, 0.3, 0.787, 0.245, 0.794, 0.185, 0.719], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.39, 0.7912, 0.373, 0.7547], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.34, 0.7827, 0.323, 0.7507], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.29, 0.7716, 0.273, 0.7441], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.24, 0.7579, 0.223, 0.7349], w: 0.004, f: false),
    const _Op(6, 0xffd9a93f, [0.0, 0.435, 0.712, 2.0, 0.34, 0.694, 0.22, 0.667, 0.12, 0.647, 2.0, 0.18, 0.722, 0.3, 0.747, 0.435, 0.754, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.435, 0.754, 2.0, 0.3, 0.747, 0.18, 0.722, 0.12, 0.647], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.377, 0.7499, 0.36, 0.7134], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.314, 0.7376, 0.297, 0.7056], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.251, 0.7201, 0.234, 0.6926], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.188, 0.6974, 0.171, 0.6744], w: 0.004, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.435, 0.672, 2.0, 0.34, 0.654, 0.155, 0.595, 0.055, 0.575, 2.0, 0.115, 0.65, 0.3, 0.707, 0.435, 0.714, 3.0]),
    const _Op(6, 0xff9a6a14, [0.0, 0.435, 0.714, 2.0, 0.3, 0.707, 0.115, 0.65, 0.055, 0.575], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.364, 0.7086, 0.347, 0.6721], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.288, 0.6925, 0.271, 0.6605], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.212, 0.6686, 0.195, 0.6411], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.136, 0.6369, 0.119, 0.6139], w: 0.004, f: false),
    const _Op(3, 0xffe8c15a, [0.575, 0.885, 0.03, 0.1, -26.0]),
    const _Op(3, 0xffe8c15a, [0.425, 0.885, 0.03, 0.1, 26.0]),
    const _Op(4, 0xffe8c15a, [0.468, 0.79, 0.532, 0.79, 0.54, 0.93, 0.5, 0.99, 0.46, 0.93]),
    const _Op(5, 0xff9a6a14, [0.5, 0.81, 0.5, 0.95], w: 0.004, f: false),
    const _Op(2, 0xffe8c15a, [0.5, 0.72, 0.08], w: 0.024, f: false),
    const _Op(2, 0xffe8c15a, [0.5, 0.72, 0.034]),
    const _Op(2, 0xff051c2b, [0.5, 0.72, 0.016]),
    const _Op(4, 0xffe8c15a, [0.452, 0.6, 0.548, 0.6, 0.566, 0.672, 0.434, 0.672]),
    const _Op(2, 0xffe8c15a, [0.5, 0.553, 0.043]),
    const _Op(4, 0xffe8c15a, [0.466, 0.572, 0.534, 0.572, 0.5, 0.63]),
    const _Op(4, 0xffe8c15a, [0.46, 0.52, 0.54, 0.52, 0.53, 0.482, 0.47, 0.482]),
    const _Op(5, 0xff9a6a14, [0.478, 0.488, 0.478, 0.515], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.5, 0.485, 0.5, 0.515], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.522, 0.488, 0.522, 0.515], w: 0.004, f: false),
    const _Op(2, 0xff051c2b, [0.515, 0.55, 0.006]),
    const _Op(5, 0xffe8c15a, [0.545, 0.622, 0.66, 0.59], w: 0.02, f: false),
    const _Op(2, 0xffe8c15a, [0.69, 0.583, 0.022], w: 0.009, f: false),
    const _Op(5, 0xffe8c15a, [0.455, 0.622, 0.38, 0.648], w: 0.02, f: false),
  ],
  // تخت جمشید
  <_Op>[
    const _Op(0, 0xff14285a, [], c2: 0xff0a1636),
    const _Op(1, 0x884a74d8, [0.5, 0.7, 0.55]),
    const _Op(6, 0xffe8c15a, [0.0, 0.04, 0.04, 1.0, 0.96, 0.04, 1.0, 0.96, 1.36, 1.0, 0.04, 1.36, 3.0], w: 0.014, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.07, 0.07, 1.0, 0.93, 0.07, 1.0, 0.93, 1.33, 1.0, 0.07, 1.33, 3.0], w: 0.005, f: false),
    const _Op(2, 0xffe8c15a, [0.1, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.1, 1.3, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 1.3, 0.016]),
    const _Op(3, 0xffe8c15a, [0.2, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.2, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 1.216, 0.012, 0.032, 38.0]),
    const _Op(2, 0xffe8c15a, [0.5, 0.7, 0.36], w: 0.008, f: false),
    const _Op(2, 0xffe8c15a, [0.5, 0.7, 0.385], w: 0.004, f: false),
    const _Op(2, 0xfffff1c9, [0.5, 0.34, 0.008]),
    const _Op(2, 0xfffff1c9, [0.5932, 0.3523, 0.008]),
    const _Op(2, 0xfffff1c9, [0.68, 0.3882, 0.008]),
    const _Op(2, 0xfffff1c9, [0.7546, 0.4454, 0.008]),
    const _Op(2, 0xfffff1c9, [0.8118, 0.52, 0.008]),
    const _Op(2, 0xfffff1c9, [0.8477, 0.6068, 0.008]),
    const _Op(2, 0xfffff1c9, [0.86, 0.7, 0.008]),
    const _Op(2, 0xfffff1c9, [0.8477, 0.7932, 0.008]),
    const _Op(2, 0xfffff1c9, [0.8118, 0.88, 0.008]),
    const _Op(2, 0xfffff1c9, [0.7546, 0.9546, 0.008]),
    const _Op(2, 0xfffff1c9, [0.68, 1.0118, 0.008]),
    const _Op(2, 0xfffff1c9, [0.5932, 1.0477, 0.008]),
    const _Op(2, 0xfffff1c9, [0.5, 1.06, 0.008]),
    const _Op(2, 0xfffff1c9, [0.4068, 1.0477, 0.008]),
    const _Op(2, 0xfffff1c9, [0.32, 1.0118, 0.008]),
    const _Op(2, 0xfffff1c9, [0.2454, 0.9546, 0.008]),
    const _Op(2, 0xfffff1c9, [0.1882, 0.88, 0.008]),
    const _Op(2, 0xfffff1c9, [0.1523, 0.7932, 0.008]),
    const _Op(2, 0xfffff1c9, [0.14, 0.7, 0.008]),
    const _Op(2, 0xfffff1c9, [0.1523, 0.6068, 0.008]),
    const _Op(2, 0xfffff1c9, [0.1882, 0.52, 0.008]),
    const _Op(2, 0xfffff1c9, [0.2454, 0.4454, 0.008]),
    const _Op(2, 0xfffff1c9, [0.32, 0.3882, 0.008]),
    const _Op(2, 0xfffff1c9, [0.4068, 0.3523, 0.008]),
    const _Op(3, 0xffd9a93f, [0.5, 0.5, 0.042, 0.11, 0.0]),
    const _Op(3, 0xffd9a93f, [0.5765, 0.5152, 0.042, 0.11, 22.5]),
    const _Op(3, 0xffd9a93f, [0.6414, 0.5586, 0.042, 0.11, 45.0]),
    const _Op(3, 0xffd9a93f, [0.6848, 0.6235, 0.042, 0.11, 67.5]),
    const _Op(3, 0xffd9a93f, [0.7, 0.7, 0.042, 0.11, 90.0]),
    const _Op(3, 0xffd9a93f, [0.6848, 0.7765, 0.042, 0.11, 112.5]),
    const _Op(3, 0xffd9a93f, [0.6414, 0.8414, 0.042, 0.11, 135.0]),
    const _Op(3, 0xffd9a93f, [0.5765, 0.8848, 0.042, 0.11, 157.5]),
    const _Op(3, 0xffd9a93f, [0.5, 0.9, 0.042, 0.11, 180.0]),
    const _Op(3, 0xffd9a93f, [0.4235, 0.8848, 0.042, 0.11, 202.5]),
    const _Op(3, 0xffd9a93f, [0.3586, 0.8414, 0.042, 0.11, 225.0]),
    const _Op(3, 0xffd9a93f, [0.3152, 0.7765, 0.042, 0.11, 247.5]),
    const _Op(3, 0xffd9a93f, [0.3, 0.7, 0.042, 0.11, 270.0]),
    const _Op(3, 0xffd9a93f, [0.3152, 0.6235, 0.042, 0.11, 292.5]),
    const _Op(3, 0xffd9a93f, [0.3586, 0.5586, 0.042, 0.11, 315.0]),
    const _Op(3, 0xffd9a93f, [0.4235, 0.5152, 0.042, 0.11, 337.5]),
    const _Op(3, 0xfffff1c9, [0.5254, 0.5725, 0.028, 0.07, 11.25]),
    const _Op(3, 0xfffff1c9, [0.5722, 0.5919, 0.028, 0.07, 33.75]),
    const _Op(3, 0xfffff1c9, [0.6081, 0.6278, 0.028, 0.07, 56.25]),
    const _Op(3, 0xfffff1c9, [0.6275, 0.6746, 0.028, 0.07, 78.75]),
    const _Op(3, 0xfffff1c9, [0.6275, 0.7254, 0.028, 0.07, 101.25]),
    const _Op(3, 0xfffff1c9, [0.6081, 0.7722, 0.028, 0.07, 123.75]),
    const _Op(3, 0xfffff1c9, [0.5722, 0.8081, 0.028, 0.07, 146.25]),
    const _Op(3, 0xfffff1c9, [0.5254, 0.8275, 0.028, 0.07, 168.75]),
    const _Op(3, 0xfffff1c9, [0.4746, 0.8275, 0.028, 0.07, 191.25]),
    const _Op(3, 0xfffff1c9, [0.4278, 0.8081, 0.028, 0.07, 213.75]),
    const _Op(3, 0xfffff1c9, [0.3919, 0.7722, 0.028, 0.07, 236.25]),
    const _Op(3, 0xfffff1c9, [0.3725, 0.7254, 0.028, 0.07, 258.75]),
    const _Op(3, 0xfffff1c9, [0.3725, 0.6746, 0.028, 0.07, 281.25]),
    const _Op(3, 0xfffff1c9, [0.3919, 0.6278, 0.028, 0.07, 303.75]),
    const _Op(3, 0xfffff1c9, [0.4278, 0.5919, 0.028, 0.07, 326.25]),
    const _Op(3, 0xfffff1c9, [0.4746, 0.5725, 0.028, 0.07, 348.75]),
    const _Op(2, 0xff0a1636, [0.5, 0.7, 0.075]),
    const _Op(2, 0xffe8c15a, [0.5, 0.7, 0.062]),
    const _Op(2, 0xff0a1636, [0.5, 0.7, 0.038]),
    const _Op(2, 0xffe8c15a, [0.5, 0.7, 0.022]),
  ],
  // سرباز هخامنشی
  <_Op>[
    const _Op(0, 0xff3a1218, [], c2: 0xff1b070b),
    const _Op(6, 0xffe8c15a, [0.0, 0.04, 0.04, 1.0, 0.96, 0.04, 1.0, 0.96, 1.36, 1.0, 0.04, 1.36, 3.0], w: 0.014, f: false),
    const _Op(6, 0xffe8c15a, [0.0, 0.07, 0.07, 1.0, 0.93, 0.07, 1.0, 0.93, 1.33, 1.0, 0.07, 1.33, 3.0], w: 0.005, f: false),
    const _Op(2, 0xffe8c15a, [0.1, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 0.1, 0.016]),
    const _Op(2, 0xffe8c15a, [0.1, 1.3, 0.016]),
    const _Op(2, 0xffe8c15a, [0.9, 1.3, 0.016]),
    const _Op(3, 0xffe8c15a, [0.2, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 0.19, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 0.196, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 0.196, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.2, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.18, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.22, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.3, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.28, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.32, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.4, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.38, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.42, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.5, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.48, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.52, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.6, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.58, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.62, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.7, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.68, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.72, 1.216, 0.012, 0.032, 38.0]),
    const _Op(3, 0xffe8c15a, [0.8, 1.21, 0.014, 0.042, 0.0]),
    const _Op(3, 0xffe8c15a, [0.78, 1.216, 0.012, 0.032, -38.0]),
    const _Op(3, 0xffe8c15a, [0.82, 1.216, 0.012, 0.032, 38.0]),
    const _Op(6, 0xff552130, [0.0, 0.17, 1.1, 1.0, 0.17, 0.55, 2.0, 0.17, 0.3, 0.83, 0.3, 0.83, 0.55, 1.0, 0.83, 1.1, 3.0]),
    const _Op(6, 0xffe8c15a, [0.0, 0.17, 1.1, 1.0, 0.17, 0.55, 2.0, 0.17, 0.3, 0.83, 0.3, 0.83, 0.55, 1.0, 0.83, 1.1, 3.0], w: 0.01, f: false),
    const _Op(1, 0x66e8a33d, [0.5, 0.72, 0.4]),
    const _Op(6, 0xff9a6a14, [0.0, 0.33, 0.58, 2.0, 0.27, 0.74, 0.27, 0.88, 0.33, 1.02], w: 0.012, f: false),
    const _Op(5, 0xff9a6a14, [0.33, 0.58, 0.33, 1.02], w: 0.003, f: false),
    const _Op(5, 0xfffff1c9, [0.675, 0.34, 0.675, 1.07], w: 0.014, f: false),
    const _Op(4, 0xfffff1c9, [0.675, 0.24, 0.7, 0.34, 0.675, 0.325, 0.65, 0.34]),
    const _Op(2, 0xffe8c15a, [0.675, 1.09, 0.02]),
    const _Op(5, 0xffe8c15a, [0.655, 0.36, 0.695, 0.36], w: 0.008, f: false),
    const _Op(4, 0xffe8c15a, [0.405, 0.545, 0.595, 0.545, 0.615, 0.8, 0.65, 1.06, 0.35, 1.06, 0.385, 0.8]),
    const _Op(5, 0xff9a6a14, [0.43, 0.82, 0.4125, 1.05], w: 0.005, f: false),
    const _Op(5, 0xff9a6a14, [0.465, 0.82, 0.4563, 1.05], w: 0.005, f: false),
    const _Op(5, 0xff9a6a14, [0.5, 0.82, 0.5, 1.05], w: 0.005, f: false),
    const _Op(5, 0xff9a6a14, [0.535, 0.82, 0.5438, 1.05], w: 0.005, f: false),
    const _Op(5, 0xff9a6a14, [0.57, 0.82, 0.5875, 1.05], w: 0.005, f: false),
    const _Op(5, 0xff9a6a14, [0.4, 0.8, 0.6, 0.8], w: 0.008, f: false),
    const _Op(5, 0xff9a6a14, [0.385, 0.82, 0.615, 0.82], w: 0.004, f: false),
    const _Op(5, 0xffe8c15a, [0.58, 0.58, 0.655, 0.72], w: 0.036, f: false),
    const _Op(2, 0xffe8c15a, [0.665, 0.735, 0.022]),
    const _Op(4, 0xffe8c15a, [0.475, 0.495, 0.525, 0.495, 0.53, 0.55, 0.47, 0.55]),
    const _Op(3, 0xffe8c15a, [0.5, 0.445, 0.055, 0.066, 0.0]),
    const _Op(4, 0xffe8c15a, [0.515, 0.46, 0.56, 0.462, 0.565, 0.515, 0.53, 0.555, 0.5, 0.525]),
    const _Op(4, 0xffe8c15a, [0.548, 0.44, 0.575, 0.455, 0.548, 0.462]),
    const _Op(2, 0xff1b070b, [0.527, 0.435, 0.006]),
    const _Op(4, 0xffe8c15a, [0.445, 0.39, 0.555, 0.39, 0.565, 0.27, 0.435, 0.27]),
    const _Op(5, 0xff9a6a14, [0.465, 0.275, 0.468, 0.385], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.5, 0.275, 0.5, 0.385], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.535, 0.275, 0.532, 0.385], w: 0.004, f: false),
    const _Op(5, 0xff9a6a14, [0.435, 0.39, 0.565, 0.39], w: 0.006, f: false),
    const _Op(5, 0xff9a6a14, [0.44, 0.3, 0.56, 0.3], w: 0.004, f: false),
  ],
];
