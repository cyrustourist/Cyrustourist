import 'dart:async';

import 'package:flutter/material.dart';

import '../services/call_service.dart';
import '../services/call_session.dart';

/// صفحهٔ تماس صوتی (خروجی و ورودی).
class CallPage extends StatefulWidget {
  const CallPage({super.key, required this.session});

  final CallSession session;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  static const Color _bg = Color(0xff0f1a17);
  static const Color _gold = Color(0xffe0b84c);

  CallSession get s => widget.session;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    CallService.instance.markPage(true);
    s.addListener(_onChange);
    if (s.isCaller) {
      unawaited(s.startOutgoing());
    }
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (s.phase == CallPhase.ended && _closeTimer == null) {
      _closeTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    s.removeListener(_onChange);
    s.disposeSession();
    CallService.instance.markPage(false);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$sec' : '$m:$sec';
  }

  String get _title {
    if (s.phase == CallPhase.connected) return _fmt(s.elapsed);
    if (s.phase == CallPhase.ringing && !s.isCaller) return 'تماس صوتی ورودی';
    return s.statusText;
  }

  @override
  Widget build(BuildContext context) {
    final incomingRinging = !s.isCaller && s.phase == CallPhase.ringing;
    final ended = s.phase == CallPhase.ended;
    final initial = s.peerName.trim().isEmpty ? '؟' : s.peerName.trim().characters.first;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xff1f3a32),
                child: Text(initial, style: const TextStyle(color: _gold, fontSize: 44, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  s.peerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ended ? const Color(0xffff8f8f) : Colors.white70, fontSize: 16),
                ),
              ),
              const Spacer(flex: 3),
              if (incomingRinging)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _round(Icons.call_end_rounded, const Color(0xffd94545), 'رد', s.decline),
                    _round(Icons.call_rounded, const Color(0xff2fa866), 'پاسخ', s.acceptIncoming),
                  ],
                )
              else if (!ended)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _round(
                      s.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      s.muted ? _gold : const Color(0xff2a3a35),
                      s.muted ? 'بی‌صدا' : 'میکروفن',
                      s.toggleMute,
                      dark: !s.muted,
                    ),
                    _round(Icons.call_end_rounded, const Color(0xffd94545), 'پایان', s.hangUp),
                    _round(
                      s.speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      s.speaker ? _gold : const Color(0xff2a3a35),
                      'بلندگو',
                      s.toggleSpeaker,
                      dark: !s.speaker,
                    ),
                  ],
                ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(IconData icon, Color color, String label, FutureOr<void> Function() onTap, {bool dark = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onTap(),
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: dark ? Colors.white : (color == _gold ? Colors.black : Colors.white), size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
