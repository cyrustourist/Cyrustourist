import 'package:flutter/material.dart';

import 'game_api.dart';
import 'game_engine.dart';

/// رنگ‌های پوسته‌ی صفحه‌ی بازی (پوسته‌ها با سکه باز می‌شوند).
class GameTheme {
  const GameTheme(this.bg, this.board, this.line, this.p1, this.p2, this.accent);
  final Color bg;
  final Color board;
  final Color line;
  final Color p1;
  final Color p2;
  final Color accent;

  static GameTheme byCode(String code) {
    switch (code) {
      case 'persepolis':
        return const GameTheme(Color(0xff2a2118), Color(0xff4a3a28), Color(0xffc9a35f), Color(0xffe8c36a), Color(0xff9fd6c9), Color(0xffe8c36a));
      case 'desert':
        return const GameTheme(Color(0xff3a2610), Color(0xff6b4421), Color(0xffe0a84a), Color(0xffffd36a), Color(0xffff8a5c), Color(0xffffd36a));
      case 'forest':
        return const GameTheme(Color(0xff0b1f14), Color(0xff1b4a2c), Color(0xff5fbf7f), Color(0xffffd36a), Color(0xff9be8b8), Color(0xff5fbf7f));
      case 'caspian':
        return const GameTheme(Color(0xff04202c), Color(0xff0f4a63), Color(0xff4fc3e8), Color(0xffffd36a), Color(0xffc9f0ff), Color(0xff4fc3e8));
      default:
        return const GameTheme(Color(0xff06121d), Color(0xff12384d), Color(0xffffd36a), Color(0xffffd36a), Color(0xff29e0ad), Color(0xffffd36a));
    }
  }
}

/// صفحه‌ی بازی: دوز (۳×۳) و چهار در ردیف (۷×۶). فقط نمایش و لمس؛ منطق در GameEngine.
class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.kind,
    required this.board,
    required this.line,
    required this.theme,
    required this.icon1,
    required this.icon2,
    required this.enabled,
    required this.onMove,
  });

  final GameKind kind;
  final List<int> board;
  final List<int> line;
  final GameTheme theme;
  final String icon1;
  final String icon2;
  final bool enabled;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final ratio = kind.cols / kind.rows;
    return AspectRatio(
      aspectRatio: ratio,
      child: LayoutBuilder(
        builder: (context, box) {
          final cw = box.maxWidth / kind.cols;
          final ch = box.maxHeight / kind.rows;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: !enabled
                ? null
                : (d) {
                    final c = (d.localPosition.dx / cw).floor().clamp(0, kind.cols - 1).toInt();
                    final r = (d.localPosition.dy / ch).floor().clamp(0, kind.rows - 1).toInt();
                    onMove(kind == GameKind.ttt ? r * 3 + c : c);
                  },
            child: CustomPaint(
              painter: _BoardPainter(kind, board, line, theme, kGameIconEmoji[icon1] ?? '🦁', kGameIconEmoji[icon2] ?? '🐪'),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.kind, this.board, this.line, this.theme, this.e1, this.e2);
  final GameKind kind;
  final List<int> board;
  final List<int> line;
  final GameTheme theme;
  final String e1;
  final String e2;

  void _emoji(Canvas canvas, String s, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cols = kind.cols;
    final rows = kind.rows;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    canvas.drawRRect(rrect, Paint()..color = theme.board);

    if (kind == GameKind.ttt) {
      final lp = Paint()
        ..color = theme.line
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < 3; i++) {
        canvas.drawLine(Offset(cw * i, 14), Offset(cw * i, size.height - 14), lp);
        canvas.drawLine(Offset(14, ch * i), Offset(size.width - 14, ch * i), lp);
      }
      for (var i = 0; i < 9; i++) {
        final v = board[i];
        if (v == 0) continue;
        final c = Offset((i % 3) * cw + cw / 2, (i ~/ 3) * ch + ch / 2);
        _emoji(canvas, v == 1 ? e1 : e2, c, cw * 0.55);
      }
    } else {
      final hole = Paint()..color = theme.bg;
      final r = (cw < ch ? cw : ch) * 0.40;
      for (var i = 0; i < 42; i++) {
        final c = Offset((i % 7) * cw + cw / 2, (i ~/ 7) * ch + ch / 2);
        final v = board[i];
        canvas.drawCircle(c, r, hole);
        if (v != 0) {
          canvas.drawCircle(c, r, Paint()..color = v == 1 ? theme.p1 : theme.p2);
          _emoji(canvas, v == 1 ? e1 : e2, c, r * 1.15);
        }
      }
    }

    if (line.isNotEmpty) {
      final hp = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      for (final i in line) {
        final c = Offset((i % cols) * cw + cw / 2, (i ~/ cols) * ch + ch / 2);
        canvas.drawCircle(c, (cw < ch ? cw : ch) * 0.44, hp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
