import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'game_fx.dart';
import 'game_texts.dart';

/// یک خط گفتگو بین بازیکنان
class ChatLine {
  const ChatLine(this.name, this.text, this.mine);
  final String name;
  final String text;
  final bool mine;
}

/// دکمهٔ صدا/لرزش برای نوار بالای بازی
Widget gameFxAction(VoidCallback onChanged) {
  return IconButton(
    tooltip: GameT.fa ? 'صدا و لرزش' : 'Sound & vibration',
    onPressed: () async {
      await GameFx.toggle();
      onChanged();
    },
    icon: Icon(GameFx.on ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: GameFx.on ? gGold : gMuted),
  );
}

/// نوار زمان نوبت
class GameTimerBar extends StatelessWidget {
  const GameTimerBar({super.key, required this.left, required this.total});
  final int left;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = (left / total).clamp(0.0, 1.0);
    final low = f < 0.3;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, size: 16, color: low ? const Color(0xffff6b6b) : gMuted),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: f, minHeight: 6, backgroundColor: gLine, color: low ? const Color(0xffff6b6b) : gGold),
            ),
          ),
          const SizedBox(width: 8),
          Text('$left', style: TextStyle(color: low ? const Color(0xffff6b6b) : gMuted, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

/// چت بین بازیکنان: عبارت‌های آماده + پیام آزاد (فقط روی اتصال مستقیم بین گوشی‌ها؛ هیچ درخواستی به ورکر نمی‌رود)
class GameChatPanel extends StatefulWidget {
  const GameChatPanel({super.key, required this.lines, required this.onSend});
  final List<ChatLine> lines;
  final void Function(String text) onSend;

  @override
  State<GameChatPanel> createState() => _GameChatPanelState();
}

class _GameChatPanelState extends State<GameChatPanel> {
  final TextEditingController _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _send(String t) {
    widget.onSend(t);
    _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = GameT.fa
        ? <String>['👍 آفرین', '😅 اوه نه!', '⏳ زود باش', '🔥 بزن!', '🤝 بازی خوبی بود']
        : <String>['👍 Nice', '😅 Oh no!', '⏳ Hurry up', '🔥 Go!', '🤝 Good game'];
    final l = widget.lines;
    final last = l.length > 4 ? l.sublist(l.length - 4) : l;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(18), border: Border.all(color: gLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in last)
            Align(
              alignment: m.mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: m.mine ? const Color(0xff1b4d57) : gBg, borderRadius: BorderRadius.circular(12)),
                child: Text(m.mine ? m.text : '${m.name}: ${m.text}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in phrases)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ActionChip(
                      backgroundColor: gBg,
                      side: const BorderSide(color: gLine),
                      label: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                      onPressed: () => _send(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctl,
                  maxLength: 60,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    filled: true,
                    fillColor: gBg,
                    hintText: GameT.fa ? 'پیام برای حریف…' : 'Message…',
                    hintStyle: const TextStyle(color: gMuted, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gLine)),
                  ),
                ),
              ),
              IconButton(onPressed: () => _send(_ctl.text), icon: const Icon(Icons.send_rounded, color: gGold)),
            ],
          ),
        ],
      ),
    );
  }
}
