import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/language/menu_translations.dart';
import '../../services/file_transfer_service.dart' show PendingConn;
import '../../services/live_video_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _muted = Color(0xff8fa5b2);
const Color _red = Color(0xffc62f35);

/// تماس تصویری زنده آفلاین (آزمایشی). جدا از تماس تصویری آنلاین برنامه.
/// دو گوشی باید روی یک شبکهٔ محلی (یک وای‌فای یا هات‌اسپات) باشند؛ اینترنت لازم نیست.
class LiveVideoPage extends StatefulWidget {
  const LiveVideoPage({super.key});

  @override
  State<LiveVideoPage> createState() => _LiveVideoPageState();
}

class _LiveVideoPageState extends State<LiveVideoPage> {
  final LiveVideoService _svc = LiveVideoService.instance;
  bool _busy = false;
  bool _dlg = false;
  bool _stats = false;

  bool get _fa => MenuLanguage.current == 'fa';
  String _t(String fa, String en) => _fa ? fa : en;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.reset();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _svc.reset();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    final p = _svc.pending;
    if (p != null && !_dlg) _confirm(p);
  }

  Future<void> _confirm(PendingConn p) async {
    _dlg = true;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          title: Text(_t('تماس تصویری با «${p.name}»؟', 'Video call “${p.name}”?'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('این کد باید در هر دو گوشی یکی باشد. با قبول کردن، تماس شروع می‌شود:', 'This code must match on both phones. Accepting starts the call:'), style: const TextStyle(color: Colors.white70, height: 1.7)),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(p.token, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('رد', 'Decline'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_t('قبول', 'Accept'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
    _dlg = false;
    if (ok == true) {
      await _svc.accept();
    } else {
      await _svc.reject();
    }
  }

  Future<void> _start(bool wait) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = wait ? await _svc.startWaiting() : await _svc.startSearch();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _snack(_errText());
  }

  String _errText() {
    switch (_svc.error) {
      case 'perm':
        return _t('مجوزهای «مکان» و «دستگاه‌های نزدیک» را بدهید و GPS را روشن کنید', 'Allow Location and Nearby devices permissions and turn on location');
      case 'cam':
        return _t('مجوز دوربین و میکروفون لازم است', 'Camera and microphone permissions are required');
      case 'start':
        return _t('شروع نشد. بلوتوث، وای‌فای و GPS را روشن کنید و دوباره تلاش کنید', 'Could not start. Turn on Bluetooth, Wi‑Fi and location, then try again');
      case 'rejected':
        return _t('اتصال انجام نشد (رد شد یا کدها یکی نبود)', 'Connection was declined');
      case 'failed':
        return _t('اتصال برقرار نشد. دوباره تلاش کنید', 'Could not connect. Try again');
      case 'net':
        return _t('تصویر وصل نشد. هر دو گوشی باید به یک وای‌فای (یا هات‌اسپات یکی از دو گوشی) وصل باشند. اینترنت لازم نیست.\n${_svc.diagnostics}', 'Video did not connect. Both phones must be on the same Wi‑Fi (or one phone\'s hotspot). Internet is not needed.\n${_svc.diagnostics}');
      case 'media':
        return _t('دوربین یا میکروفون راه‌اندازی نشد (شاید برنامه‌ی دیگری از آن استفاده می‌کند)', 'Could not start the camera or microphone (another app may be using it)');
      default:
        return '';
    }
  }

  void _snack(String msg) {
    if (msg.isEmpty) return;
    final settings = _svc.error == 'perm' || _svc.error == 'cam';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(msg),
      action: settings ? SnackBarAction(label: _t('تنظیمات', 'Settings'), onPressed: openAppSettings) : null,
    ));
  }

  String _clock(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final inCall = _svc.stage == 'incall';
    return PopScope(
      canPop: !inCall,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && inCall) {
          await _svc.hangUp();
          if (mounted) Navigator.of(context).maybePop();
        }
      },
      child: Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: inCall ? Colors.black : _bg,
          appBar: inCall
              ? null
              : AppBar(
                  backgroundColor: _bg,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: const IconThemeData(color: _gold),
                  title: Text(_t('تماس تصویری زنده (آزمایشی)', 'Live video call (beta)'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
                ),
          body: inCall ? _incall() : SafeArea(child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_svc.stage) {
      case 'wait':
        return _center(
          icon: Icons.visibility_rounded,
          title: _t('گوشی شما دیده می‌شود', 'Your phone is visible'),
          text: _t('در گوشی مقابل همین صفحه را باز کنید و «پیدا کردن گوشی (برای تماس)» را بزنید.', 'On the other phone open this page and tap “Find a phone (to call)”.'),
          action: _outlined(_t('لغو', 'Cancel'), _svc.reset),
        );
      case 'search':
        return _search();
      case 'connecting':
        return _center(
          icon: Icons.sync_rounded,
          title: _t('در حال اتصال…', 'Connecting…'),
          text: _t('کد تأیید را در هر دو گوشی قبول کنید. بعد از آن تصویر راه‌اندازی می‌شود (تا ۳۰ ثانیه).', 'Accept the confirmation code on both phones. Video then starts (up to 30 s).'),
          spinner: true,
          action: _outlined(_t('لغو', 'Cancel'), _svc.reset),
        );
      case 'ended':
      case 'lost':
        final lost = _svc.stage == 'lost';
        return _center(
          icon: lost ? Icons.link_off_rounded : Icons.call_end_rounded,
          title: lost ? _t('ارتباط قطع شد', 'Connection lost') : _t('تماس پایان یافت', 'Call ended'),
          text: _svc.seconds > 0 ? _t('مدت تماس: ${_clock(_svc.seconds)}', 'Duration: ${_clock(_svc.seconds)}') : _errText(),
          action: _big(Icons.refresh_rounded, _t('بازگشت', 'Back'), _svc.reset),
        );
      default:
        return _home();
    }
  }

  Widget _home() {
    final err = _errText();
    final labels = <String>['360p', '480p', '720p'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _teal.withValues(alpha: 0.45))),
          child: Text(
            _t(
              'تماس تصویری مستقیم بین دو گوشی، بدون اینترنت. تصویر و صدا با WebRTC و رمزنگاری استاندارد آن (DTLS‑SRTP) مستقیم بین دو گوشی می‌رود. این بخش جدا از تماس تصویری آنلاین برنامه است و نسخهٔ آزمایشی است.',
              'Direct video call between two phones, no internet. Video and audio go straight between the phones via WebRTC with its standard encryption (DTLS‑SRTP). Separate from the online video call; this is a beta.',
            ),
            style: const TextStyle(color: Color(0xffc3d2db), height: 1.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.5))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wifi_rounded, color: _gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('شرط لازم: هر دو گوشی باید به یک وای‌فای وصل باشند (مودم بدون اینترنت هم کافی است) یا یکی هات‌اسپات بزند و دیگری به آن وصل شود.', 'Required: both phones on the same Wi‑Fi (a router without internet is fine), or one phone\'s hotspot with the other connected to it.'),
                  style: const TextStyle(color: Colors.white, height: 1.8, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_t('کیفیت تصویر', 'Video quality'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                label: Text(labels[i]),
                selected: _svc.quality == i,
                selectedColor: _gold,
                backgroundColor: _card,
                labelStyle: TextStyle(color: _svc.quality == i ? _bg : Colors.white, fontWeight: FontWeight.w800),
                onSelected: (_) => setState(() => _svc.quality = i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _step('۱', _t('در یک گوشی «دیده شدن» را بزنید.', 'On one phone tap “Be visible”.')),
        _step('۲', _t('در گوشی دیگر «پیدا کردن گوشی» را بزنید و نام اولی را انتخاب کنید.', 'On the other tap “Find a phone” and pick the first one.')),
        _step('۳', _t('کد را در هر دو گوشی قبول کنید؛ تماس خودکار شروع می‌شود.', 'Accept the code on both; the call starts automatically.')),
        const SizedBox(height: 16),
        if (err.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent, height: 1.7)),
          ),
        _big(Icons.visibility_rounded, _t('دیده شدن (برای دریافت تماس)', 'Be visible (to receive)'), _busy ? null : () => _start(true)),
        _big(Icons.search_rounded, _t('پیدا کردن گوشی (برای تماس)', 'Find a phone (to call)'), _busy ? null : () => _start(false)),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: CircularProgressIndicator(color: _gold))),
        const SizedBox(height: 12),
        Text(
          _t('با شروع این بخش، شبکه‌ی چت آفلاین خاموش می‌شود. بلوتوث، وای‌فای و GPS باید روشن باشند.', 'Starting this turns the offline chat network off. Bluetooth, Wi‑Fi and location must be on.'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.7),
        ),
      ],
    );
  }

  Widget _search() {
    final list = _svc.found.entries.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
            const SizedBox(width: 10),
            Expanded(child: Text(_t('در جستجوی گوشی‌های دیده‌شونده…', 'Looking for visible phones…'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(_t('هنوز گوشی‌ای پیدا نشد.\nدر گوشی مقابل «دیده شدن» را بزنید و نزدیک هم باشید.', 'No phone found yet.\nOn the other phone tap “Be visible” and stay close.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.8)),
          )
        else
          for (final e in list)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.25))),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: _teal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
                    onPressed: () => _svc.connectTo(e.key),
                    child: Text(_t('تماس', 'Call'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 10),
        _outlined(_t('لغو', 'Cancel'), _svc.reset),
      ],
    );
  }

  // ------------------------------------------------------------------ تماس

  Widget _incall() {
    final name = _svc.peerName;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    final rtt = _svc.rttMs;
    final loss = _svc.lossPct;
    Color qc;
    if (rtt == null) {
      qc = _muted;
    } else if (rtt < 150 && loss < 5) {
      qc = _teal;
    } else if (rtt < 400 && loss < 15) {
      qc = _gold;
    } else {
      qc = Colors.redAccent;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // تصویر مقابل
        if (_svc.remoteVideoOn)
          RTCVideoView(_svc.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
        else
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _card, shape: BoxShape.circle, border: Border.all(color: _gold, width: 3)),
              child: Text(initial, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 46)),
            ),
          ),
        // نوار بالا
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: qc, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(name.isEmpty ? '…' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Directionality(textDirection: TextDirection.ltr, child: Text(_clock(_svc.seconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: Icon(Icons.speed_rounded, color: _stats ? _gold : Colors.white),
                      onPressed: () => setState(() => _stats = !_stats),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // تصویر خودم
                  Container(
                    width: 92,
                    height: 128,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white54, width: 1.5), color: Colors.black),
                    clipBehavior: Clip.antiAlias,
                    child: _svc.cameraOff
                        ? const Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white54))
                        : RTCVideoView(_svc.localRenderer, mirror: _svc.frontCamera, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_stats)
          Positioned(
            left: 12,
            right: 12,
            top: 190,
            child: SafeArea(child: _statsPanel()),
          ),
        // دکمه‌ها
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _round(_svc.muted ? Icons.mic_off_rounded : Icons.mic_rounded, _svc.toggleMute, active: _svc.muted),
                  const SizedBox(width: 14),
                  _round(_svc.cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, _svc.toggleCamera, active: _svc.cameraOff),
                  const SizedBox(width: 14),
                  _round(Icons.call_end_rounded, _svc.hangUp, big: true, color: _red),
                  const SizedBox(width: 14),
                  _round(Icons.cameraswitch_rounded, _svc.switchCamera),
                  const SizedBox(width: 14),
                  _round(_svc.speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded, _svc.toggleSpeaker, active: _svc.speaker),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsPanel() {
    final rtt = _svc.rttMs;
    String fp(String s) => s.length > 17 ? s.substring(0, 17) : s;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(14)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RTT: ${rtt == null ? '—' : '$rtt ms'}    Loss: ${_svc.lossPct}%'),
              Text('Video: ${_svc.resolution.isEmpty ? '—' : _svc.resolution} @ ${_svc.fps} fps    ${_svc.rxKbps} kbps'),
              Text('Path: ${_svc.pathInfo.isEmpty ? '—' : _svc.pathInfo}'),
              Text('My DTLS: ${fp(_svc.myFp)}'),
              Text('Peer DTLS: ${fp(_svc.peerFp)}'),
              Text(_t('اگر اثر انگشت‌ها در دو گوشی برعکس هم یکی باشد، تماس رمزنگاری‌شده مستقیم است.', 'If the fingerprints match crosswise on both phones, the call is encrypted end to end.'), style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(IconData icon, VoidCallback onTap, {bool big = false, Color? color, bool active = false}) {
    final size = big ? 68.0 : 54.0;
    return Material(
      color: color ?? (active ? _gold : Colors.black54),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Icon(icon, color: active ? _bg : Colors.white, size: big ? 30 : 24)),
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, backgroundColor: _gold, child: Text(n, style: const TextStyle(color: _bg, fontWeight: FontWeight.w900, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.6))),
        ],
      ),
    );
  }

  Widget _big(IconData icon, String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg, disabledBackgroundColor: Colors.white12, padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _outlined(String text, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _center({required IconData icon, required String title, required String text, Widget? action, bool spinner = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _gold, size: 54),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8)),
            if (spinner) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator(color: _gold)),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 20), child: action),
          ],
        ),
      ),
    );
  }
}
