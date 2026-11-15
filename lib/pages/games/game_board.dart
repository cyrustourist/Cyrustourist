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
    this.turn = 1,
  });

  final GameKind kind;
  final List<int> board;
  final List<int> line;
  final GameTheme theme;
  final String icon1;
  final String icon2;
  final bool enabled;
  final ValueChanged<int> onMove;

  /// علامت بازیکنی که حرکت بعدی را می‌زند (برای پیش‌نمایش مهره در چهار در ردیف)
  final int turn;

  @override
  Widget build(BuildContext context) {
    if (kind == GameKind.c4) {
      return _C4Board(board: board, line: line, theme: theme, icon1: icon1, icon2: icon2, enabled: enabled, onMove: onMove, turn: turn);
    }
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


// ============================================================ چهار در ردیف
// لمس = انتخاب ستون: با گذاشتن انگشت، مهرهٔ پیش‌نمایش بالای ستون و خانهٔ فرود مهره نشان داده می‌شود؛
// می‌توانید انگشت را روی ستون دیگر بکشید و فقط با برداشتن انگشت حرکت ثبت می‌شود. مهره با انیمیشن می‌افتد.

void _drawEmoji(Canvas canvas, String s, Offset center, double size) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

class _C4Board extends StatefulWidget {
  const _C4Board({
    required this.board,
    required this.line,
    required this.theme,
    required this.icon1,
    required this.icon2,
    required this.enabled,
    required this.onMove,
    required this.turn,
  });

  final List<int> board;
  final List<int> line;
  final GameTheme theme;
  final String icon1;
  final String icon2;
  final bool enabled;
  final ValueChanged<int> onMove;
  final int turn;

  @override
  State<_C4Board> createState() => _C4BoardState();
}

class _C4BoardState extends State<_C4Board> with SingleTickerProviderStateMixin {
  static const double _topK = 1.0; // ارتفاع ناحیهٔ پیش‌نمایش (نسبت به عرض یک ستون)
  static const double _cellK = 1.14; // ارتفاع هر خانه نسبت به عرضش
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  int? _pid;
  int? _hover;
  int _dropIdx = -1;

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _C4Board old) {
    super.didUpdateWidget(old);
    var added = -1;
    var n = 0;
    for (var i = 0; i < 42; i++) {
      if (old.board[i] == 0 && widget.board[i] != 0) {
        added = i;
        n++;
      }
    }
    if (n == 1) {
      _dropIdx = added;
      _ac.forward(from: 0);
    } else if (n == 0 && widget.board.every((e) => e == 0)) {
      _dropIdx = -1;
    }
    if (!widget.enabled && _hover != null) _hover = null;
  }

  int _colOf(double dx, double w) => (dx / (w / 7)).floor().clamp(0, 6).toInt();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final cw = w / 7;
        final h = cw * (_topK + 6 * _cellK);
        return SizedBox(
          width: w,
          height: h,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              if (!widget.enabled || _pid != null) return;
              _pid = e.pointer;
              setState(() => _hover = _colOf(e.localPosition.dx, w));
            },
            onPointerMove: (e) {
              if (e.pointer != _pid) return;
              final c = _colOf(e.localPosition.dx, w);
              if (c != _hover) setState(() => _hover = c);
            },
            onPointerUp: (e) {
              if (e.pointer != _pid) return;
              _pid = null;
              final c = _hover;
              setState(() => _hover = null);
              final inside = e.localPosition.dx >= -24 && e.localPosition.dx <= w + 24 && e.localPosition.dy >= -24 && e.localPosition.dy <= h + 24;
              if (widget.enabled && c != null && inside && widget.board[c] == 0) widget.onMove(c);
            },
            onPointerCancel: (e) {
              if (e.pointer != _pid) return;
              _pid = null;
              setState(() => _hover = null);
            },
            child: CustomPaint(
              size: Size(w, h),
              painter: _C4Painter(
                board: widget.board,
                line: widget.line,
                theme: widget.theme,
                e1: kGameIconEmoji[widget.icon1] ?? '🦁',
                e2: kGameIconEmoji[widget.icon2] ?? '🐪',
                hover: widget.enabled ? _hover : null,
                turn: widget.turn,
                dropIdx: _dropIdx,
                anim: _ac,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _C4Painter extends CustomPainter {
  _C4Painter({
    required this.board,
    required this.line,
    required this.theme,
    required this.e1,
    required this.e2,
    required this.hover,
    required this.turn,
    required this.dropIdx,
    required this.anim,
  }) : super(repaint: anim);

  final List<int> board;
  final List<int> line;
  final GameTheme theme;
  final String e1;
  final String e2;
  final int? hover;
  final int turn;
  final int dropIdx;
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / 7;
    final topH = cw * _C4BoardState._topK;
    final ch = (size.height - topH) / 6;
    final r = (cw < ch ? cw : ch) * 0.40;
    Offset cell(int i) => Offset((i % 7) * cw + cw / 2, topH + (i ~/ 7) * ch + ch / 2);
    final pc = turn == 1 ? theme.p1 : theme.p2;
    final em = turn == 1 ? e1 : e2;

    final area = Rect.fromLTWH(0, topH, size.width, size.height - topH);
    canvas.drawRRect(RRect.fromRectAndRadius(area, const Radius.circular(18)), Paint()..color = theme.board);

    final hc = hover;
    if (hc != null) {
      final col = Rect.fromLTWH(hc * cw + 2, topH + 4, cw - 4, size.height - topH - 8);
      canvas.drawRRect(RRect.fromRectAndRadius(col, const Radius.circular(14)), Paint()..color = theme.accent.withOpacity(0.13));
    }

    final hole = Paint()..color = theme.bg;
    for (var i = 0; i < 42; i++) {
      canvas.drawCircle(cell(i), r, hole);
    }

    // مهره‌ها (مهرهٔ تازه با انیمیشن افتادن)
    for (var i = 0; i < 42; i++) {
      final v = board[i];
      if (v == 0) continue;
      var c = cell(i);
      if (i == dropIdx && anim.value < 1) {
        final from = Offset(c.dx, topH / 2);
        c = Offset.lerp(from, c, Curves.bounceOut.transform(anim.value))!;
      }
      canvas.drawCircle(c, r, Paint()..color = v == 1 ? theme.p1 : theme.p2);
      _drawEmoji(canvas, v == 1 ? e1 : e2, c, r * 1.15);
    }

    // پیش‌نمایش: مهرهٔ بالای ستون + خانهٔ فرود
    if (hc != null) {
      final full = board[hc] != 0;
      final op = full ? 0.25 : 0.7;
      final top = Offset(hc * cw + cw / 2, topH / 2);
      canvas.drawCircle(top, r, Paint()..color = pc.withOpacity(op));
      final tp = TextPainter(text: TextSpan(text: em, style: TextStyle(fontSize: r * 1.15, color: Colors.white.withOpacity(op))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, top - Offset(tp.width / 2, tp.height / 2));
      if (!full) {
        var row = 5;
        while (row >= 0 && board[row * 7 + hc] != 0) {
          row--;
        }
        if (row >= 0) {
          final c = cell(row * 7 + hc);
          canvas.drawCircle(c, r, Paint()..color = pc.withOpacity(0.28));
          canvas.drawCircle(
            c,
            r,
            Paint()
              ..color = theme.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    }

    if (line.isNotEmpty) {
      final hp = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      for (final i in line) {
        canvas.drawCircle(cell(i), r * 1.1, hp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _C4Painter old) => true;
}
