import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/group_ui.dart';
import 'game_economy.dart';
import 'game_widgets.dart';
import 'game_wheel.dart' show wFa;

/// طرح‌های صفحه‌ی بازی‌ها (مار و پله، منچ، میوه‌چین) با قفل سکه‌ای.
/// انتخاب هر بازی روی گوشی ذخیره می‌شود و صفحه‌ی بازی خودش آن را می‌خواند.

class SkinStore {
  SkinStore._();
  static const String _k = 'cyrus_skins_v1';
  static final Map<String, int> _sel = <String, int>{};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) => _sel[k] = (v as num).toInt());
      }
    } catch (_) {}
    _loaded = true;
  }

  /// شماره‌ی طرح انتخاب‌شده (همیشه داخل بازه)
  static int idx(String game, int count) {
    final v = _sel[game] ?? 0;
    return v < 0 ? 0 : (v >= count ? 0 : v);
  }

  static Future<void> set(String game, int i) async {
    _sel[game] = i;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(_sel));
    } catch (_) {}
  }
}

/// پنجره‌ی انتخاب طرح: طرح‌های قفل با سکه باز می‌شوند.
Future<void> showSkinSheet(
  BuildContext context, {
  required String game,
  required String title,
  required List<String> names,
  required List<int> prices,
  required Widget Function(int i) preview,
  VoidCallback? onChanged,
}) async {
  await GameEconomy.load();
  await SkinStore.load();
  if (!context.mounted) return;
  int? pend; // طرحی که کاربر لمس کرده و هنوز تأیید نشده
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          final cur = SkinStore.idx(game, names.length);
          final pk = pend ?? cur;
          final pOwned = prices[pk] == 0 || GameEconomy.isOwned('skin_${game}_$pk');
          final need = prices[pk] - GameEconomy.balance;
          return Directionality(
            textDirection: gDir,
            child: Container(
              height: MediaQuery.of(ctx).size.height * .8,
              decoration: const BoxDecoration(color: gBg, borderRadius: BorderRadius.vertical(top: Radius.circular(26)), boxShadow: <BoxShadow>[BoxShadow(color: Colors.black87, blurRadius: 24)]),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 44, height: 5, decoration: BoxDecoration(color: gLine, borderRadius: BorderRadius.circular(3))),
                  Padding(padding: const EdgeInsets.only(top: 10), child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                  Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: Text('موجودی تو: ${wFa(GameEconomy.balance)} 🪙 · طرح‌های قفل را با سکه باز کن', style: const TextStyle(color: gMuted, fontSize: 12.5))),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: names.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .86),
                      itemBuilder: (_, i) {
                        final sel = pk == i;
                        final isCur = cur == i;
                        final owned = prices[i] == 0 || GameEconomy.isOwned('skin_${game}_$i');
                        return GestureDetector(
                          onTap: () => setS(() => pend = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: gPanel,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: sel ? gGold : gLine, width: sel ? 2.4 : 1),
                              boxShadow: sel ? const <BoxShadow>[BoxShadow(color: Color(0x66ffd36a), blurRadius: 14)] : const <BoxShadow>[BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: Column(
                              children: [
                                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 1, child: preview(i)))),
                                const SizedBox(height: 6),
                                Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? gGold : Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                const SizedBox(height: 2),
                                if (isCur)
                                  const Icon(Icons.check_circle, color: gGold, size: 18)
                                else if (!owned)
                                  Text('🔒 ${wFa(prices[i])} 🪙', style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, fontSize: 12.5))
                                else
                                  const Icon(Icons.lock_open_rounded, color: gMuted, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: (pk == cur || (!pOwned && need > 0))
                            ? null
                            : () async {
                                if (!pOwned) {
                                  final ok = await GameEconomy.buy(ctx, 'skin_${game}_$pk', prices[pk], 'طرح «${names[pk]}»');
                                  if (!ok) {
                                    setS(() {});
                                    return;
                                  }
                                }
                                await SkinStore.set(game, pk);
                                onChanged?.call();
                                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                                if (context.mounted) gToast(context, '✓ طرح «${names[pk]}» ذخیره شد');
                              },
                        child: Text(
                          pk == cur
                              ? 'این طرح فعال است'
                              : pOwned
                                  ? 'تأیید و ذخیره'
                                  : (need > 0 ? '${wFa(need)} 🪙 دیگر لازم است' : 'خرید و ذخیره · ${wFa(prices[pk])} 🪙'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// دکمه‌ی «طرح صفحه» برای نوار بالای بازی‌ها
Widget skinAction(VoidCallback onTap) => IconButton(tooltip: 'طرح صفحه', onPressed: onTap, icon: const Icon(Icons.palette_rounded, color: gGold));

// ---------------------------------------------------------------------------
// مار و پله

class SnakesSkin {
  const SnakesSkin(this.name, this.price, this.frameA, this.frameB, this.cellA, this.cellB, this.finish, this.num, this.rail, this.rung, this.snakes, {this.motif = 0});
  final String name;
  final int price;
  final Color frameA;
  final Color frameB;
  final Color cellA;
  final Color cellB;
  final Color finish;
  final Color num;
  final Color rail;
  final Color rung;
  final List<Color> snakes;

  /// نقش روی خانه‌ها: ۰ ندارد، ۱ لوزی، ۲ نقطه
  final int motif;
}

const List<SnakesSkin> kSnakesSkins = <SnakesSkin>[
  SnakesSkin('شب کلاسیک', 0, Color(0xff0f2f42), Color(0xff08202e), Color(0xff12394f), Color(0xff0d2a3b), Color(0xff8a6d1a), Color(0x88ffffff), Color(0xffd9a441), Color(0xffb8842c), <Color>[Color(0xff2ecc71), Color(0xffe74c3c), Color(0xffb36bdc), Color(0xfff39c12), Color(0xff1abc9c), Color(0xffff6fa5)]),
  SnakesSkin('جنگل', 0, Color(0xff5d4037), Color(0xff3e2723), Color(0xff2e7d32), Color(0xff256b2a), Color(0xffb58a1a), Color(0xaaffffff), Color(0xffe0b25a), Color(0xffa97a32), <Color>[Color(0xffffca28), Color(0xffff7043), Color(0xff8e24aa), Color(0xff26c6da), Color(0xffe53935), Color(0xffffee58)]),
  SnakesSkin('اقیانوس', 100, Color(0xff0d47a1), Color(0xff082c68), Color(0xff29b6f6), Color(0xff039be5), Color(0xffffc107), Color(0xccffffff), Color(0xffffffff), Color(0xffcfd8dc), <Color>[Color(0xffff7043), Color(0xfff06292), Color(0xffffd54f), Color(0xff7e57c2), Color(0xff66bb6a), Color(0xffef5350)]),
  SnakesSkin('کاخ پارسی', 150, Color(0xff8a5a2b), Color(0xff4a2c12), Color(0xff1c7c7d), Color(0xff0f5c63), Color(0xffd4a017), Color(0xccffe9a6), Color(0xfff2c14e), Color(0xffc89b3c), <Color>[Color(0xffd4a017), Color(0xffc0392b), Color(0xff2ecc71), Color(0xff7e57c2), Color(0xffe67e22), Color(0xffecf0f1)], motif: 1),
  SnakesSkin('شیرینی', 200, Color(0xffad1457), Color(0xff6a0e3a), Color(0xffffa8c5), Color(0xffff86b0), Color(0xffffd54f), Color(0xaa5d1034), Color(0xfff8f8f8), Color(0xffe0e0e0), <Color>[Color(0xff7e57c2), Color(0xff26a69a), Color(0xffff7043), Color(0xff42a5f5), Color(0xff9ccc65), Color(0xff5d4037)], motif: 2),
  SnakesSkin('کویر', 150, Color(0xff8d5a2b), Color(0xff5a3a12), Color(0xffe8c98a), Color(0xffd9b370), Color(0xffb86e1a), Color(0xaa5a3a12), Color(0xff6d4c41), Color(0xff4e342e), <Color>[Color(0xff6d4c41), Color(0xffbf360c), Color(0xff2e7d32), Color(0xff37474f), Color(0xff8d6e63), Color(0xff558b2f)]),
];

class _SnakesMini extends CustomPainter {
  const _SnakesMini(this.s);
  final SnakesSkin s;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 6;
    canvas.drawRect(Offset.zero & size, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[s.frameA, s.frameB]).createShader(Offset.zero & size));
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        canvas.drawRect(Rect.fromLTWH(c * u, r * u, u, u), Paint()..color = (r + c).isEven ? s.cellA : s.cellB);
      }
    }
    final a = Offset(u * 1.5, u * 5.5), b = Offset(u * 3.5, u * 0.7);
    canvas.drawLine(a + Offset(-u * .12, 0), b + Offset(-u * .12, 0), Paint()..color = s.rail..strokeWidth = u * .12..strokeCap = StrokeCap.round);
    canvas.drawLine(a + Offset(u * .12, 0), b + Offset(u * .12, 0), Paint()..color = s.rail..strokeWidth = u * .12..strokeCap = StrokeCap.round);
    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      final p = Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      canvas.drawLine(p + Offset(-u * .12, 0), p + Offset(u * .12, 0), Paint()..color = s.rung..strokeWidth = u * .08);
    }
    final path = Path()..moveTo(u * 4.6, u * 0.6);
    for (var i = 1; i <= 20; i++) {
      final t = i / 20;
      path.lineTo(u * 4.6 - u * 1.6 * t + sin(t * pi * 3) * u * .35, u * 0.6 + u * 4.4 * t);
    }
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = u * .32..strokeCap = StrokeCap.round..color = s.snakes[0]);
    canvas.drawCircle(Offset(u * 4.6, u * 0.6), u * .26, Paint()..color = s.snakes[0]);
  }

  @override
  bool shouldRepaint(covariant _SnakesMini old) => old.s != s;
}

Widget snakesPreview(int i) => CustomPaint(painter: _SnakesMini(kSnakesSkins[i]));

// ---------------------------------------------------------------------------
// منچ

class LudoSkin {
  const LudoSkin(this.name, this.price, this.frameA, this.frameB, this.rim, this.plateA, this.plateB, this.hole);
  final String name;
  final int price;
  final Color frameA;
  final Color frameB;
  final Color rim;
  final Color plateA;
  final Color plateB;
  final Color hole;
}

const List<LudoSkin> kLudoSkins = <LudoSkin>[
  LudoSkin('چوب کلاسیک', 0, Color(0xff8a4c2d), Color(0xff3b1d12), Color(0xfff0c36a), Color(0xfff7e6bd), Color(0xffdcb47a), Color(0xffc27a52)),
  LudoSkin('گردوی تیره', 0, Color(0xff5d3a26), Color(0xff2a1710), Color(0xffd4a24a), Color(0xffe8d3a6), Color(0xffc19a5f), Color(0xffa86a45)),
  LudoSkin('مرمر', 120, Color(0xff9aa5b1), Color(0xff5c6670), Color(0xffffffff), Color(0xfffafafa), Color(0xffd9dde2), Color(0xffb9c0c8)),
  LudoSkin('آبی شب', 150, Color(0xff1d3b6b), Color(0xff0b1a33), Color(0xff7fb2ff), Color(0xffcfe0ff), Color(0xff9bb8ea), Color(0xff6d8fc9)),
  LudoSkin('ارغوانی', 200, Color(0xff6a1b9a), Color(0xff2a0845), Color(0xffffd54f), Color(0xfff3e1ff), Color(0xffcfa8e8), Color(0xff9c6bc0)),
  LudoSkin('طلای ایرانی', 250, Color(0xffb7791f), Color(0xff5a3a08), Color(0xfffff0a8), Color(0xfffff4cf), Color(0xffe8c36a), Color(0xffd09a3f)),
  LudoSkin('نمد سبز', 300, Color(0xff1b5e20), Color(0xff0b3d12), Color(0xffffd54f), Color(0xff2e7d32), Color(0xff1b5e20), Color(0xff81c784)),
  LudoSkin('چوب موجی تیره', 350, Color(0xff4a2418), Color(0xff2a120a), Color(0xffe0b070), Color(0xffe3c08a), Color(0xffc89a5a), Color(0xff8a4b2e)),
  LudoSkin('مشکی مدرن', 400, Color(0xff1c1c1c), Color(0xff0a0a0a), Color(0xff9e9e9e), Color(0xff2e2e2e), Color(0xff1a1a1a), Color(0xfff2f2f2)),
  LudoSkin('اژدها رنگارنگ', 500, Color(0xffd8a868), Color(0xff9a6a35), Color(0xffe53935), Color(0xffffe082), Color(0xff81d4fa), Color(0xfff5f5f5)),
];

class _LudoMini extends CustomPainter {
  const _LudoMini(this.s);
  final LudoSkin s;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * .08));
    canvas.drawRRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[s.frameA, s.frameB]).createShader(Offset.zero & size));
    final u = size.width / 15;
    const cols = <Color>[Color(0xffe8453c), Color(0xff3fae49), Color(0xfff6c445), Color(0xff2f8fe8)];
    final o = <Offset>[Offset(.8 * u, .8 * u), Offset(8.6 * u, .8 * u), Offset(8.6 * u, 8.6 * u), Offset(.8 * u, 8.6 * u)];
    for (var k = 0; k < 4; k++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o[k].dx, o[k].dy, 5.6 * u, 5.6 * u), Radius.circular(u)), Paint()..color = cols[k]);
    }
    final plate = Paint()..shader = LinearGradient(colors: <Color>[s.plateA, s.plateB]).createShader(Offset.zero & size);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(.5 * u, 6 * u, 14 * u, 3 * u), Radius.circular(u * .5)), plate);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6 * u, .5 * u, 3 * u, 14 * u), Radius.circular(u * .5)), plate);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(Offset((1.2 + i * 2.2) * u, 7.5 * u), u * .5, Paint()..color = s.hole);
    }
    canvas.drawRRect(r.deflate(size.width * .02), Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * .012..color = s.rim);
  }

  @override
  bool shouldRepaint(covariant _LudoMini old) => old.s != s;
}

Widget ludoPreview(int i) => CustomPaint(painter: _LudoMini(kLudoSkins[i]));

// ---------------------------------------------------------------------------
// میوه‌چین

class FruitSkin {
  const FruitSkin(this.name, this.price, this.a, this.b, this.border);
  final String name;
  final int price;
  final Color a;
  final Color b;
  final Color border;
}

const List<FruitSkin> kFruitSkins = <FruitSkin>[
  FruitSkin('آبی', 0, Color(0xff2b7fc0), Color(0xff2370ad), Color(0xff16384f)),
  FruitSkin('سبز نعنایی', 0, Color(0xff2e9e6b), Color(0xff268a5b), Color(0xff14543a)),
  FruitSkin('بنفش شب', 100, Color(0xff6a4cc0), Color(0xff5a3fae), Color(0xff34246e)),
  FruitSkin('نارنجی', 120, Color(0xfff08a3c), Color(0xffe07a2c), Color(0xff8a4a14)),
  FruitSkin('صورتی شیرین', 150, Color(0xffe2689a), Color(0xffd05488), Color(0xff8a2a56)),
  FruitSkin('تیره‌ی لوکس', 200, Color(0xff2b3340), Color(0xff222a35), Color(0xffc9a13a)),
  FruitSkin('طلایی', 250, Color(0xffc9a13a), Color(0xffb78f2c), Color(0xff6a4a0a)),
];

Widget fruitPreview(int i) {
  final s = kFruitSkins[i];
  const f = <String>['🍎', '🍊', '🍌', '🍇', '🍓', '🍏', '🍊', '🍎', '🍇'];
  return Container(
    decoration: BoxDecoration(border: Border.all(color: s.border, width: 3), borderRadius: BorderRadius.circular(10)),
    child: Column(
      children: [
        for (var r = 0; r < 3; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < 3; c++) Expanded(child: Container(color: (r + c).isEven ? s.a : s.b, alignment: Alignment.center, child: Text(f[r * 3 + c], style: const TextStyle(fontSize: 22)))),
              ],
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// چت با ربات (برای بازی‌هایی که حریف ربات دارند)

class BotChatBox extends StatefulWidget {
  const BotChatBox({super.key, required this.botName, this.me = 'من'});
  final String botName;
  final String me;

  @override
  State<BotChatBox> createState() => _BotChatBoxState();
}

class _BotChatBoxState extends State<BotChatBox> {
  final List<ChatLine> lines = <ChatLine>[];
  final Random _rnd = Random();
  int _last = 0;

  static const List<String> _phrases = <String>['👍 آفرین', '🎲 تاس خوبی آمد!', '😅 اوه نه!', '⏳ زود باش', '🔥 حالا نوبت منه', '🤝 بازی خوبی بود'];
  static const List<String> _replies = <String>['😄 دست خوبی بود', '🤔 بذار فکر کنم', '🔥 حالا نوبت منه', '😅 شانس آوردی', '👏 آفرین', '🎲 تاس‌ها با منه!'];

  void _send(String raw) {
    final t = raw.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (t.isEmpty || t.length > 60 || now - _last < 800) return;
    _last = now;
    setState(() => lines.add(ChatLine(widget.me, t, true)));
    Future<void>.delayed(Duration(milliseconds: 800 + _rnd.nextInt(1200)), () {
      if (!mounted) return;
      setState(() {
        lines.add(ChatLine(widget.botName, _replies[_rnd.nextInt(_replies.length)], false));
        if (lines.length > 20) lines.removeAt(0);
      });
    });
  }

  @override
  Widget build(BuildContext context) => GameChatPanel(lines: lines, onSend: _send, phrases: _phrases);
}
