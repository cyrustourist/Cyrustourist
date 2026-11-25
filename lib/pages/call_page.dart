import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/language/menu_translations.dart';
import '../services/call_service.dart';
import '../services/call_session.dart';
import '../services/call_texts.dart';
import '../services/friends_service.dart';
import '../widgets/call_widgets.dart';

enum _VMode { pip, split, full }

/// صفحهٔ تماس صوتی (خروجی و ورودی) با ظاهر شبیه تلگرام.
class CallPage extends StatefulWidget {
  const CallPage({super.key, required this.session, this.autoAccept = false});

  final CallSession session;

  /// وقتی کاربر از دکمهٔ «پاسخ» روی خود اعلان آمده، تماس بدون زنگ و بدون لمس دوباره پاسخ داده می‌شود.
  final bool autoAccept;

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
  bool _accepting = false;

  // چینش تماس تصویری: تصویر کوچک شناور / تقسیم صفحه (پیش‌فرض بالا ۳۰٪) / تمام‌صفحه
  _VMode _vmode = _VMode.pip;
  double _split = 0.30; // سهم بخش بالایی از ارتفاع صفحه
  bool _swap = false; // false: در تقسیم بالا «من» و پایین «مقابل»؛ در شناور، مقابل بزرگ
  int _pipSize = 1;
  Offset? _pipOff; // null = گوشهٔ بالا (پیش‌فرض)
  double _lastArea = -1;
  static const List<double> _pipW = [0.26, 0.36, 0.46];

  String _l(String fa, String en, String ar) {
    switch (MenuLanguage.current) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  @override
  void initState() {
    super.initState();
    CallService.instance.markPage(true);
    s.addListener(_onChange);
    if (s.isCaller) {
      unawaited(s.startOutgoing());
    } else {
      s.startRingWatch(silent: widget.autoAccept);
      if (widget.autoAccept) unawaited(s.acceptIncoming());
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
    if (s.phase == CallPhase.ringing && !s.isCaller) return CT.t(s.isVideo ? 'incoming_video' : 'incoming');
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

  /// پاسخ به تماس؛ در تماس تصویری ابتدا مجوز دوربین/میکروفن را (با توضیح) می‌گیرد تا وسط اتصال پنجرهٔ سیستم معطل نکند.
  /// اگر کاربر مجوز نداد تماس هنوز در حال زنگ است و می‌تواند رد کند یا دوباره بپذیرد.
  Future<void> _accept() async {
    if (_accepting) return;
    _accepting = true;
    try {
      if (s.isVideo && !await CallService.instance.ensureCamForCall(context)) return;
      if (!mounted) return;
      await s.acceptIncoming();
    } finally {
      _accepting = false;
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
    if (s.isVideo && s.phase == CallPhase.connected && s.videoReady) return _videoScreen();

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

  void _reportArea(double area) {
    if ((area - _lastArea).abs() < 0.03) return;
    _lastArea = area;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) s.setViewArea(area);
    });
  }

  Widget _remoteContent(Rect r) {
    if (s.remoteVideoOn) {
      return RTCVideoView(s.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
    }
    return Container(
      color: const Color(0xff1b2a4a),
      alignment: Alignment.center,
      child: CallAvatar(
        uid: s.peerUid,
        name: s.peerName,
        radius: (r.shortestSide * 0.25).clamp(18.0, 64.0).toDouble(),
        hasPhoto: s.hasPhoto,
        background: const Color(0xff4a6fd0),
        foreground: Colors.white,
      ),
    );
  }

  Widget _localContent() {
    if (s.cameraOff) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 30),
      );
    }
    return RTCVideoView(
      s.localRenderer,
      mirror: s.frontCamera,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _tag(String text) => PositionedDirectional(
        top: 8,
        start: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
      );

  /// صفحهٔ تماس تصویری وصل‌شده با سه چینش: شناور، تقسیم صفحه (۳۰/۷۰ و قابل کشیدن)، تمام‌صفحه.
  /// اندازهٔ قاب تصویر مقابل به طرف مقابل گزارش می‌شود تا رزولوشن ارسالی را خودکار کوچک/بزرگ کند.
  Widget _videoScreen() {
    final pad = MediaQuery.of(context).padding;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final full = Rect.fromLTWH(0, 0, w, h);
            late Rect remoteR, localR;
            var pipRect = false;
            switch (_vmode) {
              case _VMode.split:
                final top = Rect.fromLTWH(0, 0, w, h * _split);
                final bot = Rect.fromLTWH(0, h * _split, w, h * (1 - _split));
                if (_swap) {
                  remoteR = top;
                  localR = bot;
                } else {
                  localR = top;
                  remoteR = bot;
                }
                break;
              case _VMode.full:
                remoteR = full;
                localR = Rect.zero;
                break;
              case _VMode.pip:
                pipRect = true;
                final pw = w * _pipW[_pipSize], ph = pw * 4 / 3;
                final off = _pipOff ?? Offset(w - pw - 14, pad.top + 78);
                final pip = Rect.fromLTWH(
                  off.dx.clamp(0.0, w - pw).toDouble(),
                  off.dy.clamp(0.0, h - ph).toDouble(),
                  pw,
                  ph,
                );
                if (_swap) {
                  localR = full;
                  remoteR = pip;
                } else {
                  remoteR = full;
                  localR = pip;
                }
                break;
            }
            _reportArea(remoteR.width * remoteR.height / (w * h));
            final showLocal = _vmode != _VMode.full;

            Widget tile(Rect r, Widget child, {bool pip = false}) {
              Widget t = child;
              if (pip) {
                t = GestureDetector(
                  onTap: () => setState(() => _swap = !_swap),
                  onPanUpdate: (d) => setState(() {
                    final cur = _pipOff ?? Offset(r.left, r.top);
                    _pipOff = cur + d.delta;
                  }),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(13), child: child),
                  ),
                );
              }
              return Positioned.fromRect(rect: r, child: t);
            }

            final remoteIsPip = pipRect && _swap;
            final remoteTile = tile(remoteR, _remoteContent(remoteR), pip: remoteIsPip);
            final localTile = tile(localR, _localContent(), pip: pipRect && !_swap);

            return Stack(
              children: [
                // اول تصویر بزرگ، بعد تصویر کوچک شناور (روی آن)
                if (pipRect && !_swap) ...[remoteTile, if (showLocal) localTile],
                if (pipRect && _swap) ...[if (showLocal) localTile, remoteTile],
                if (!pipRect) ...[remoteTile, if (showLocal) localTile],
                if (_vmode == _VMode.split) ...[
                  _tagFor(_swap ? remoteR : localR, _swap ? s.peerName : _l('من', 'Me', 'أنا')),
                  _tagFor(_swap ? localR : remoteR, _swap ? _l('من', 'Me', 'أنا') : s.peerName),
                  Positioned(
                    top: h * _split - 20,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (d) => setState(() {
                        _split = ((_split * h + d.delta.dy) / h).clamp(0.15, 0.85).toDouble();
                      }),
                      onVerticalDragEnd: (_) => setState(() {
                        for (final sn in const [0.3, 0.5, 0.7]) {
                          if ((_split - sn).abs() < 0.04) _split = sn;
                        }
                      }),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xaa000000), Color(0x00000000)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(64, 10, 64, 26),
                          child: Column(
                            children: [
                              Text(s.peerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_fmt(s.elapsed), style: const TextStyle(color: Colors.white70, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: pad.top + 6,
                  start: 6,
                  child: Column(
                    children: [
                      _miniBtn(
                        _vmode == _VMode.pip
                            ? Icons.picture_in_picture_alt_rounded
                            : (_vmode == _VMode.split ? Icons.horizontal_split_rounded : Icons.fullscreen_rounded),
                        _l('چینش تصویر', 'Layout', 'التخطيط'),
                        () => setState(() {
                          _vmode = _VMode.values[(_vmode.index + 1) % _VMode.values.length];
                        }),
                      ),
                      if (_vmode != _VMode.full) _miniBtn(Icons.swap_vert_rounded, _l('جابه‌جایی', 'Swap', 'تبديل'), () => setState(() => _swap = !_swap)),
                      if (_vmode == _VMode.pip) _miniBtn(Icons.open_in_full_rounded, _l('اندازهٔ تصویر کوچک', 'Preview size', 'حجم المعاينة'), () => setState(() => _pipSize = (_pipSize + 1) % _pipW.length)),
                      _miniBtn(Icons.tune_rounded, _l('کیفیت تصویر', 'Video quality', 'جودة الفيديو'), _qualitySheet),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xbb000000), Color(0x00000000)],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40, bottom: 24),
                        child: _activeControls(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tagFor(Rect r, String text) => Positioned.fromRect(
        rect: r,
        child: IgnorePointer(child: Stack(children: [_tag(text)])),
      );

  Widget _miniBtn(IconData icon, String tip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tip,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 22)),
          ),
        ),
      ),
    );
  }

  Future<void> _qualitySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff0e2433),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => ListenableBuilder(
        listenable: s,
        builder: (ctx, _) => SafeArea(
          child: Directionality(
            textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_l('کیفیت تصویر', 'Video quality', 'جودة الفيديو'),
                      style: const TextStyle(color: Color(0xffffe39a), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _l('«خودکار» رزولوشن را با اندازهٔ قاب کم و زیاد می‌کند؛ تصویر مستقیم بین دو گوشی می‌رود.',
                        'Auto adapts resolution to the frame size; video goes directly between the phones.',
                        'التلقائي يضبط الدقة حسب حجم الإطار.'),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in CallSession.qualityModes)
                        ChoiceChip(
                          label: Text(m == 'auto' ? _l('خودکار', 'Auto', 'تلقائي') : '${m}p'),
                          selected: s.qualityMode == m,
                          onSelected: (_) => s.setQualityMode(m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.weakDevice,
                    onChanged: s.setWeakDevice,
                    title: Text(_l('گوشی ضعیف (روان‌تر)', 'Weak phone (smoother)', 'هاتف ضعيف (أسلس)'),
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _l('سقف ۵۴۰p و ۱۵ فریم؛ فشار روی پردازنده و باتری کمتر می‌شود.',
                          'Caps at 540p and 15 fps to reduce CPU and battery use.',
                          'حد أقصى 540p و15 إطارًا.'),
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  if (s.sendInfo.isNotEmpty)
                    Text('${_l('ارسال فعلی', 'Sending now', 'الإرسال الحالي')}: ${s.sendInfo}',
                        textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
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
    final v = s.isVideo;
    final size = v ? 56.0 : 66.0;
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
            size: size,
            onTap: s.toggleSpeaker,
          ),
          if (v) ...[
            _round(
              icon: s.cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              label: CT.t('video'),
              active: !s.cameraOff,
              size: size,
              onTap: s.toggleCamera,
            ),
            _round(
              icon: Icons.cameraswitch_rounded,
              label: CT.t('flip_cam'),
              size: size,
              onTap: s.switchCamera,
            ),
          ] else
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
            size: size,
            onTap: s.toggleMute,
          ),
          _round(
            icon: Icons.call_end_rounded,
            label: CT.t('end_call'),
            color: _red,
            size: size,
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
                  _round(icon: s.isVideo ? Icons.videocam_rounded : Icons.call_rounded, label: CT.t('accept'), color: _green, onTap: _accept),
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
    double size = 66,
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
            child: SizedBox(width: size, height: size, child: Icon(icon, color: fg, size: size * 0.45)),
          ),
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}
