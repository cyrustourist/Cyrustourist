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
  const _FaceStyle(this.bg, this.border, this.ink, this.black, this.heart, this.diamond, this.club, {this.radius = 0.09});
  final Color bg;
  final Color border;
  final Color ink;
  final Color black;
  final Color heart;
  final Color diamond;
  final Color club;
  final double radius;
  Color suit(int s) => s == 0 ? black : (s == 1 ? heart : (s == 2 ? diamond : club));
}

const List<_FaceStyle> _faces = <_FaceStyle>[
  _FaceStyle(Color(0xffffffff), Color(0xffbbbbbb), Color(0xff111111), Color(0xff111111), Color(0xffd62828), Color(0xffd62828), Color(0xff111111)),
  _FaceStyle(Color(0xffffffff), Color(0xffbbbbbb), Color(0xff111111), Color(0xff111111), Color(0xffd62828), Color(0xff1f5fd6), Color(0xff16883a)),
  _FaceStyle(Color(0xff1b2133), Color(0xff46537a), Color(0xffe8ecf5), Color(0xffe8ecf5), Color(0xffff6b6b), Color(0xffffb454), Color(0xff7ee0a5)),
  _FaceStyle(Color(0xfff6ecd0), Color(0xffbda35c), Color(0xff2b2118), Color(0xff2b2118), Color(0xffa8222b), Color(0xffa8222b), Color(0xff2b2118), radius: 0.05),
  _FaceStyle(Color(0xffeef2ff), Color(0xff9fb0e8), Color(0xff1f2a44), Color(0xff1f2a44), Color(0xffe5484d), Color(0xfff08a24), Color(0xff2a9d6a), radius: 0.13),
];

/// رنگ هر خال با توجه به طرح روی کارت (برای نوشته‌ها و نشان‌ها)
Color hokmSuitColor(int suit, [int? face]) => _faces[hokmClamp(face ?? HokmPrefs.instance.face, 0, _faces.length - 1)].suit(suit);

/// کارت رو شده. عرض = [w]، ارتفاع = ۱٫۴ برابر.
class HokmCardView extends StatelessWidget {
  const HokmCardView({super.key, required this.card, required this.w, this.face, this.ring, this.dim = false});
  final HCard card;
  final double w;
  final int? face;
  final Color? ring;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final st = _faces[hokmClamp(face ?? HokmPrefs.instance.face, 0, _faces.length - 1)];
    final h = w * 1.4;
    final y = kSuitChar[card.suit];
    final col = st.suit(card.suit);
    final r = card.rank;
    final label = card.rankLabel;
    Widget mid;
    if (r >= 11) {
      mid = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * .5, height: 1)),
            Text(y, style: TextStyle(color: col, fontSize: w * .34, height: 1)),
          ],
        ),
      );
    } else if (r == 14) {
      mid = Center(child: Text(y, style: TextStyle(color: col, fontSize: w * .62, height: 1)));
    } else {
      mid = Stack(
        children: [
          for (final p in _pips[r] ?? _pip2)
            Align(
              alignment: Alignment(p[0] / 50 - 1, p[1] / 50 - 1),
              child: Transform.rotate(angle: p[1] > 50 ? pi : 0, child: Text(y, style: TextStyle(color: col, fontSize: w * .27, height: 1))),
            ),
        ],
      );
    }
    Widget corner() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w900, fontSize: w * .26, height: 1)),
            Text(y, style: TextStyle(color: col, fontSize: w * .22, height: 1)),
          ],
        );
    final body = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(w * st.radius),
        border: Border.all(color: ring ?? st.border, width: ring != null ? w * .045 : w * .012),
        boxShadow: <BoxShadow>[
          if (ring != null) BoxShadow(color: ring!.withOpacity(.65), blurRadius: w * .2, spreadRadius: w * .02),
          BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: w * .09, offset: Offset(0, w * .03)),
        ],
      ),
      child: Stack(
        children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: w * .1, vertical: w * .22), child: mid),
          Positioned(left: w * .06, top: w * .04, child: corner()),
          Positioned(right: w * .06, bottom: w * .04, child: Transform.rotate(angle: pi, child: corner())),
          if (dim) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withOpacity(.45), borderRadius: BorderRadius.circular(w * st.radius)))),
        ],
      ),
    );
    return body;
  }
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
      child: ClipRRect(borderRadius: BorderRadius.circular(w * .09), child: CustomPaint(painter: _BackPainter(i))),
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
      default:
        c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffd9ccac), Color(0xff9b8d6e)]).createShader(r));
    }
    c.drawRect(r, Paint()..shader = RadialGradient(radius: 1.0, colors: [Colors.transparent, Colors.black.withOpacity(.42)], stops: const [.55, 1]).createShader(r));
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
