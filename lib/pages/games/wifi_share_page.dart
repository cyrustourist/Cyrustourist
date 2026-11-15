import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/hotspot_service.dart';
import '../../services/local_game_server.dart';
import '../groups/group_ui.dart';
import 'game_texts.dart';

String _x(String fa, String en) => GameT.fa ? fa : en;

/// اشتراک وای‌فای بازی + QR هم‌زمان برای آیفون (بدون اینترنت).
/// QR اول: وصل شدن به وای‌فای (دوربین آیفون «Join» می‌زند).
/// QR دوم: باز کردن صفحه‌ی بازی که همین گوشی می‌دهد.
class WifiSharePage extends StatefulWidget {
  const WifiSharePage({super.key});

  @override
  State<WifiSharePage> createState() => _WifiSharePageState();
}

class _WifiSharePageState extends State<WifiSharePage> {
  final HotspotService _hs = HotspotService.instance;
  final LocalGameServer _srv = LocalGameServer.instance;

  bool _busy = false;
  bool _manual = false;
  HotspotInfo? _info;
  String _ip = '';
  String _error = '';
  final String _room = '${1000 + Random().nextInt(9000)}';
  final TextEditingController _ssid = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  bool get _on => _info != null && _srv.running && _ip.isNotEmpty;

  @override
  void dispose() {
    _ssid.dispose();
    _pass.dispose();
    _stopAll();
    super.dispose();
  }

  Future<void> _stopAll() async {
    await _srv.stop();
    await _hs.stop();
  }

  Future<void> _startAuto() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    final info = await _hs.start();
    if (info == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _hs.lastError == 'perm' || _hs.lastError == 'permission'
            ? _x('مجوز مکان / وای‌فای نزدیک را بدهید و GPS را روشن کنید.', 'Allow location / Nearby Wi‑Fi and turn on GPS.')
            : _x('وای‌فای بازی روشن نشد. وای‌فای و GPS را روشن کنید؛ اگر نشد، روش دستی را بزنید.', 'Could not start the hotspot. Turn on Wi‑Fi and GPS; otherwise use manual mode.');
      });
      return;
    }
    await _finish(info);
  }

  Future<void> _startManual() async {
    final s = _ssid.text.trim();
    if (s.isEmpty) {
      setState(() => _error = _x('نام وای‌فای را بنویسید.', 'Enter the Wi‑Fi name.'));
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    await _finish(HotspotInfo(s, _pass.text, _pass.text.isEmpty ? 0 : 1));
  }

  Future<void> _finish(HotspotInfo info) async {
    final okSrv = await _srv.start();
    final ip = await HotspotService.localIp() ?? '';
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!okSrv) {
        _error = _x('سرور بازی روشن نشد.', 'Could not start the game server.');
        return;
      }
      _info = info;
      _ip = ip;
      if (ip.isEmpty) _error = _x('آدرس این گوشی پیدا نشد؛ مطمئن شوید وای‌فای بازی روشن است.', 'Could not find this phone\'s address; make sure the hotspot is on.');
    });
  }

  Future<void> _stop() async {
    await _stopAll();
    if (!mounted) return;
    setState(() {
      _info = null;
      _ip = '';
    });
  }

  String get _gameUrl => 'http://$_ip:${_srv.port}/games.html#room=$_room';

  Future<void> _playHere() async {
    final ok = await launchUrl(Uri.parse('http://127.0.0.1:${_srv.port}/games.html#room=$_room'), mode: LaunchMode.externalApplication);
    if (!ok && mounted) gToast(context, _x('مرورگر باز نشد.', 'Could not open the browser.'));
  }

  Widget _qr(String title, String data) => Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: QrImageView(data: data, size: 210, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.M),
        ),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ]);

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Text('$k: ', style: const TextStyle(color: gMuted)),
          Expanded(child: SelectableText(v, textDirection: TextDirection.ltr, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(backgroundColor: gPanel, foregroundColor: Colors.white, title: Text(_x('وای‌فای بازی و QR آیفون', 'Game Wi‑Fi & iPhone QR'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(
            _x('آیفون نمی‌تواند مثل اندروید آفلاین به گوشی‌های اطراف وصل شود؛ برای همین این گوشی وای‌فای می‌دهد و آیفون با دوربین QR را می‌خواند. اینترنت لازم نیست.',
                'iPhones cannot join nearby Android games directly; this phone shares Wi‑Fi and the iPhone scans the QR with its camera. No internet needed.'),
            style: const TextStyle(color: gMuted, height: 1.8),
          ),
          const SizedBox(height: 14),
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent)),
              child: Text(_error, style: const TextStyle(color: Colors.white, height: 1.7)),
            ),
          if (!_on) ...[
            FilledButton.icon(
              onPressed: _busy ? null : _startAuto,
              icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_x('روشن کردن وای‌فای بازی و نمایش QR', 'Start game Wi‑Fi and show QR')),
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(() => _manual = !_manual), child: Text(_x('هات‌اسپات را خودم روشن کرده‌ام (روش دستی)', 'I turned the hotspot on myself (manual)'))),
            if (_manual) ...[
              TextField(controller: _ssid, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: _x('نام وای‌فای', 'Wi‑Fi name'), labelStyle: const TextStyle(color: gMuted))),
              TextField(controller: _pass, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: _x('رمز (خالی = بدون رمز)', 'Password (empty = none)'), labelStyle: const TextStyle(color: gMuted))),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _busy ? null : _startManual, child: Text(_x('ساخت QR', 'Create QR'))),
            ],
          ] else ...[
            _qr(_x('۱) آیفون با دوربین بخواند و «Join» بزند', '1) iPhone: scan with Camera, tap Join'), _info!.wifiQr),
            const SizedBox(height: 18),
            if (_ip.isNotEmpty) _qr(_x('۲) بعد از وصل شدن، این را بخواند تا بازی باز شود', '2) After joining, scan this to open the game'), _gameUrl),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _line(_x('وای‌فای', 'Wi‑Fi'), _info!.ssid),
                if (_info!.pass.isNotEmpty) _line(_x('رمز', 'Password'), _info!.pass),
                if (_ip.isNotEmpty) _line(_x('آدرس بازی', 'Game address'), '$_ip:${_srv.port}'),
                _line(_x('کد اتاق', 'Room code'), _room),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              _x('شما (اندروید) دکمه‌ی «بازی روی این گوشی» را بزنید و «ساخت اتاق» را انتخاب کنید؛ آیفون‌ها «پیوستن به اتاق» را می‌زنند. اگر iOS دربارهٔ شبکه‌ی محلی پرسید «Allow» بزنند.',
                  'On this phone tap “Play on this phone” and choose “Create room”; iPhones choose “Join room”. If iOS asks about the local network, tap Allow.'),
              style: const TextStyle(color: gMuted, height: 1.8),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _playHere,
              icon: const Icon(Icons.sports_esports_rounded),
              label: Text(_x('بازی روی این گوشی', 'Play on this phone')),
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _stop, child: Text(_x('خاموش کردن وای‌فای بازی', 'Stop game Wi‑Fi'))),
          ],
        ]),
      ),
    );
  }
}
