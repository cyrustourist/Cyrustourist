import 'dart:async';

import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../services/call_service.dart';
import '../services/call_session.dart';
import '../services/call_texts.dart';
import '../services/friends_service.dart';
import '../widgets/call_widgets.dart';

/// صفحهٔ تماس صوتی (خروجی و ورودی) با ظاهر شبیه تلگرام.
class CallPage extends StatefulWidget {
  const CallPage({super.key, required this.session});

  final CallSession session;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with SingleTickerProviderStateMixin {
  static const Color _red = Color(0xffed2d3d);
  static const Color _green = Color(0xff2fb36a);
  static const Color _violet = Color(0xff6a4fe0);

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  CallSession get s => widget.session;
  Timer? _closeTimer;
  bool _busyAction = false;

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
      final ms = s.peerMessageKey != null ? 2800 : 1700;
      _closeTimer = Timer(Duration(milliseconds: ms), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _pulse.dispose();
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
    if (s.phase == CallPhase.ringing && !s.isCaller) return CT.t('incoming');
    return s.statusText;
  }

  bool get _animatedDots =>
      s.phase == CallPhase.preparing ||
      s.phase == CallPhase.connecting ||
      (s.phase == CallPhase.ringing && s.isCaller);

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _addFriend() async {
    if (_busyAction || s.peerUid.isEmpty) return;
    _busyAction = true;
    final r = await FriendsService.add(friendUid: s.peerUid);
    _busyAction = false;
    if (!mounted) return;
    if (r.ok) {
      setState(() => s.isFriend = true);
      _toast(CT.t(r.raw?['already'] == true ? 'friend_exists' : 'friend_added', {'name': s.peerName}));
    } else {
      _toast(r.needsProfile ? CT.t('need_profile') : r.text);
    }
  }

  /// رد تماس + بلاک موقت تماس‌های این کاربر
  Future<void> _tempBlock() async {
    if (_busyAction || s.peerUid.isEmpty) return;
    final hours = await showBlockDurationSheet(context, s.peerName);
    if (hours == null || !mounted) return;
    _busyAction = true;
    final r = await FriendsService.blockCalls(s.peerUid, hours);
    _busyAction = false;
    if (!mounted) return;
    if (!r.ok) {
      _toast(r.text);
      return;
    }
    await s.decline(reason: CT.t('blocked_done', {'name': s.peerName}));
  }

  @override
  Widget build(BuildContext context) {
    final incomingRinging = !s.isCaller && s.phase == CallPhase.ringing;
    final ended = s.phase == CallPhase.ended;
    final showAddPill = !incomingRinging && !ended && !s.isFriend && s.peerUid.isNotEmpty && s.phase == CallPhase.connected;

    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff3b82e0),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff2a9bd8), Color(0xff3b82e0), Color(0xff6a63e6), Color(0xff7d57e3)],
              stops: [0.0, 0.38, 0.72, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _avatarWithHalo(),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    s.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final dots = _animatedDots ? '.' * ((DateTime.now().millisecondsSinceEpoch ~/ 450) % 4) : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '$_title$dots',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 17, height: 1.5),
                      ),
                    );
                  },
                ),
                if (showAddPill) ...[
                  const SizedBox(height: 14),
                  _pill(Icons.person_add_alt_1_rounded, CT.t('add_to_friends'), _addFriend),
                ],
                const Spacer(flex: 4),
                if (incomingRinging)
                  _incomingControls()
                else if (!ended)
                  _activeControls(),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarWithHalo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final animating = s.phase != CallPhase.connected && s.phase != CallPhase.ended;
        final t = animating ? Curves.easeInOut.transform(_pulse.value) : 0.0;
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 214 + 24 * t,
                height: 214 + 24 * t,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10 - 0.04 * t)),
              ),
              Container(
                width: 186 + 10 * t,
                height: 186 + 10 * t,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.14)),
              ),
              child!,
            ],
          ),
        );
      },
      child: CallAvatar(
        uid: s.peerUid,
        name: s.peerName,
        radius: 80,
        hasPhoto: s.hasPhoto,
        background: const Color(0xff4a6fd0),
        foreground: Colors.white,
      ),
    );
  }

  // ------------------------------------------------------------------
  // دکمه‌های تماس در حال انجام / خروجی: بلندگو، ویدیو، بی‌صدا، پایان
  // ------------------------------------------------------------------
  Widget _activeControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _round(
            icon: Icons.volume_up_rounded,
            label: CT.t('speaker'),
            active: s.speaker,
            onTap: s.toggleSpeaker,
          ),
          _round(
            icon: Icons.videocam_off_rounded,
            label: CT.t('video'),
            highlight: true,
            onTap: () => _toast(CT.t('video_soon')),
          ),
          _round(
            icon: s.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: CT.t('mute'),
            active: s.muted,
            onTap: s.toggleMute,
          ),
          _round(
            icon: Icons.call_end_rounded,
            label: CT.t('end_call'),
            color: _red,
            onTap: s.hangUp,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // تماس ورودی: پیام آماده، پاسخ + افزودن به دوستان، رد + بلاک موقت
  // ------------------------------------------------------------------
  Widget _incomingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _msgChip('later'),
              _msgChip('cant_talk'),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _round(icon: Icons.call_end_rounded, label: CT.t('decline'), color: _red, onTap: () => s.decline()),
                  const SizedBox(height: 14),
                  _pill(Icons.block_rounded, CT.t('temp_block'), _tempBlock),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _round(icon: Icons.call_rounded, label: CT.t('accept'), color: _green, onTap: s.acceptIncoming),
                  const SizedBox(height: 14),
                  s.isFriend
                      ? _pill(Icons.check_rounded, CT.t('in_friends'), null)
                      : _pill(Icons.person_add_alt_1_rounded, CT.t('add_to_friends'), _addFriend),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _msgChip(String key) {
    return Material(
      color: Colors.white.withValues(alpha: 0.20),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => s.decline(msgKey: key),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(CT.msg(key), style: const TextStyle(color: Colors.white, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, FutureOr<void> Function()? onTap) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.44),
      child: Material(
        color: Colors.white.withValues(alpha: onTap == null ? 0.12 : 0.20),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap == null ? null : () => onTap(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// دکمهٔ گرد. active = روشن (سفید با آیکون بنفش)، highlight = همیشه سفید، color = رنگ ثابت (قرمز/سبز)
  Widget _round({
    required IconData icon,
    required String label,
    required FutureOr<void> Function() onTap,
    bool active = false,
    bool highlight = false,
    Color? color,
  }) {
    final Color bg;
    final Color fg;
    if (color != null) {
      bg = color;
      fg = Colors.white;
    } else if (active || highlight) {
      bg = Colors.white;
      fg = _violet;
    } else {
      bg = Colors.white.withValues(alpha: 0.22);
      fg = Colors.white;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onTap(),
            child: SizedBox(width: 66, height: 66, child: Icon(icon, color: fg, size: 30)),
          ),
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}
