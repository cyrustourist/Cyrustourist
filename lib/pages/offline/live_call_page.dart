import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/language/menu_translations.dart';
import '../../services/file_transfer_service.dart' show PendingConn;
import '../../services/live_call_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _sky = Color(0xff66d9ff);
const Color _muted = Color(0xff8fa5b2);
const Color _red = Color(0xffc62f35);

/// تماس صوتی زنده آفلاین (آزمایشی): یک گوشی «دیده می‌شود»، گوشی دیگر او را پیدا و تماس می‌گیرد.
/// بعد از تأیید کد در هر دو گوشی، تماس شروع می‌شود. کیفیت اتصال (RTT، افت بسته، لرزش) نمایش داده می‌شود.
class LiveCallPage extends StatefulWidget {
  const LiveCallPage({super.key});

  @override
  State<LiveCallPage> createState() => _LiveCallPageState();
}

class _LiveCallPageState extends State<LiveCallPage> {
  final LiveCallService _svc = LiveCallService.instance;
  bool _busy = false;
  bool _dlg = false;

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
          title: Text(_t('تماس با «${p.name}»؟', 'Call “${p.name}”?'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
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
      case 'mic':
        return _t('مجوز میکروفون لازم است', 'Microphone permission is required');
      case 'start':
        return _t('شروع نشد. بلوتوث، وای‌فای و GPS را روشن کنید و دوباره تلاش کنید (اینترنت لازم نیست)', 'Could not start. Turn on Bluetooth, Wi‑Fi and location, then try again (no internet needed)');
      case 'rejected':
        return _t('اتصال انجام نشد (رد شد یا کدها یکی نبود)', 'Connection was declined');
      case 'failed':
        return _t('اتصال برقرار نشد. دوباره تلاش کنید', 'Could not connect. Try again');
      case 'audio':
        return _t('میکروفون یا بلندگو راه‌اندازی نشد (شاید برنامه‌ی دیگری از آن استفاده می‌کند)', 'Could not start the microphone or speaker (another app may be using it)');
      default:
        return '';
    }
  }

  void _snack(String msg) {
    if (msg.isEmpty) return;
    final settings = _svc.error == 'perm' || _svc.error == 'mic';
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
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: _gold),
            title: Text(_t('تماس صوتی زنده (آزمایشی)', 'Live voice call (beta)'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
          ),
          body: SafeArea(child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_svc.stage) {
      case 'incall':
        return _incall();
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
          text: _t('کد تأیید را در هر دو گوشی قبول کنید.', 'Accept the confirmation code on both phones.'),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _sky.withValues(alpha: 0.45))),
          child: Text(
            _t(
              'تماس صوتی مستقیم بین دو گوشی از راه وای‌فای، بدون اینترنت. این بخش جدا از تماس صوتی و تصویری معمول برنامه است. نسخهٔ آزمایشی است و برای سنجش کیفیت ساخته شده.',
              'Direct voice call between two phones over Wi‑Fi, no internet. Separate from the regular voice/video calls. This is a beta made to measure quality.',
            ),
            style: const TextStyle(color: Color(0xffc3d2db), height: 1.8),
          ),
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
          _t('برای جلوگیری از اکو، گوشی را کنار گوش بگیرید یا هدفون بزنید. با شروع این بخش، شبکه‌ی چت آفلاین خاموش می‌شود. بلوتوث، وای‌فای و GPS باید روشن باشند.', 'To avoid echo hold the phone to your ear or use headphones. Starting this turns the offline chat network off. Bluetooth, Wi‑Fi and location must be on.'),
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

  Widget _incall() {
    final rtt = _svc.rttMs;
    final loss = _svc.lossPct;
    String q;
    Color qc;
    if (rtt == null) {
      q = _t('در حال سنجش…', 'Measuring…');
      qc = _muted;
    } else if (rtt < 250 && loss < 5) {
      q = _t('اتصال خوب', 'Good connection');
      qc = _teal;
    } else if (rtt < 600 && loss < 15) {
      q = _t('اتصال متوسط', 'Fair connection');
      qc = _gold;
    } else {
      q = _t('اتصال ضعیف', 'Weak connection');
      qc = Colors.redAccent;
    }
    final name = _svc.peerName;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return Column(
      children: [
        const SizedBox(height: 28),
        Text(_t('تماس آفلاین از راه وای‌فای', 'Offline call over Wi‑Fi'), style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _card, shape: BoxShape.circle, border: Border.all(color: _gold, width: 3)),
          child: Text(initial, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 50)),
        ),
        const SizedBox(height: 16),
        Text(name.isEmpty ? '…' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xff1d3a4d))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: qc, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(q, style: TextStyle(color: qc, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(_clock(_svc.seconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 38, letterSpacing: 2)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(child: _metric(_t('تأخیر رفت‌وبرگشت', 'Round trip'), rtt == null ? '—' : '$rtt ms')),
              const SizedBox(width: 8),
              Expanded(child: _metric(_t('بستهٔ گم‌شده', 'Packet loss'), '$loss%')),
              const SizedBox(width: 8),
              Expanded(child: _metric(_t('لرزش', 'Jitter'), '${_svc.jitterMs} ms')),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _round(_svc.muted ? Icons.mic_off_rounded : Icons.mic_rounded, _t('بی‌صدا', 'Mute'), _svc.toggleMute, active: _svc.muted),
              const SizedBox(width: 28),
              _round(Icons.call_end_rounded, _t('پایان', 'End'), _svc.hangUp, big: true, color: _red),
              const SizedBox(width: 28),
              _round(_svc.speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded, _t('بلندگو', 'Speaker'), _svc.toggleSpeaker, active: _svc.speaker),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          Directionality(textDirection: TextDirection.ltr, child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _round(IconData icon, String label, VoidCallback onTap, {bool big = false, Color? color, bool active = false}) {
    final size = big ? 76.0 : 64.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? (active ? _gold : _card),
          shape: CircleBorder(side: BorderSide(color: color == null ? const Color(0xff1d3a4d) : Colors.transparent)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: size, height: size, child: Icon(icon, color: active ? _bg : Colors.white, size: big ? 32 : 26)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xffc3d2db), fontSize: 12.5)),
      ],
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
