import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'game_play_page.dart' show NearbyGameLink;
import 'game_texts.dart';

class _EfRoom {
  _EfRoom(this.code, this.hostUid, this.hostName, this.count, this.cap, this.ts);
  final String code;
  final String hostUid;
  final String hostName;
  int count;
  int cap;
  int ts;
}

String _x(String fa, String en) => GameT.fa ? fa : en;

/// اسم و فامیل با چند گوشی نزدیک (Nearby، بدون اینترنت): ۲، ۳، ۴ یا ۶ نفره.
/// یک گوشی «میزبان» است و داور بازی (حرف، زمان، امتیاز) روی او اجرا می‌شود.
/// صفحهٔ بازی همان فایل assets/games/esmfamil.html است؛ این کلاس فقط لابی و انتقال پیام‌ها را انجام می‌دهد.
class EsmFamilNearbyPage extends StatefulWidget {
  const EsmFamilNearbyPage({super.key});

  @override
  State<EsmFamilNearbyPage> createState() => _EsmFamilNearbyPageState();
}

class _EsmFamilNearbyPageState extends State<EsmFamilNearbyPage> {
  static const List<int> _caps = <int>[2, 3, 4, 6];
  static const List<int> _times = <int>[30, 60, 90];

  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final Random _rnd = Random();
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _tick;
  Timer? _joinTick;
  bool _starting = false;

  String stage = 'menu'; // menu | host | join | play
  bool isHost = false;
  bool joined = false;
  String code = '';
  String hostUid = '';
  int cap = 4;
  int time = 60;
  final List<String> ids = <String>[];
  final List<String> pnames = <String>[];
  final Map<String, _EfRoom> rooms = <String, _EfRoom>{};

  // صفحهٔ بازی (WebView)
  WebViewController? _c;
  bool _ready = false;
  final List<String> _queue = <String>[];

  int get me => ids.indexOf(_mesh.myUid);

  @override
  void initState() {
    super.initState();
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
    _mesh.addListener(_onMesh);
    _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
  }

  @override
  void dispose() {
    if (stage == 'join' && joined && code.isNotEmpty) {
      _send(<String, dynamic>{'g': 'ef_leave', 'to': hostUid, 'code': code});
    }
    _tick?.cancel();
    _joinTick?.cancel();
    _sub?.cancel();
    _mesh.removeListener(_onMesh);
    NearbyGameLink.instance.detach();
    super.dispose();
  }

  void _send(Map<String, dynamic> m) => NearbyGameLink.instance.send(m);

  void _onMesh() {
    if (!mounted) return;
    setState(() {});
  }

  void _onTick() {
    if (!mounted || !_mesh.running) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (stage == 'host') {
      _send(<String, dynamic>{'g': 'ef_open', 'code': code, 'cnt': ids.length, 'cap': cap});
    } else if (stage == 'join') {
      rooms.removeWhere((k, v) => now - v.ts > 7000);
      if (code.isNotEmpty && !joined) {
        _send(<String, dynamic>{'g': 'ef_join', 'to': hostUid, 'code': code});
      }
      setState(() {});
    } else if (stage == 'play' && isHost) {
      // گوشی‌هایی که قطع شده‌اند به داور بازی خبر داده می‌شود (نوبتشان خودکار رد می‌شود)
      for (var i = 1; i < ids.length; i++) {
        final here = _mesh.people.any((p) => p.uid == ids[i]);
        _js('window.onGone($i,${here ? 0 : 1})');
      }
    }
  }

  Future<void> _toggleNet() async {
    if (_starting) return;
    if (_mesh.running) {
      await _mesh.stop();
      return;
    }
    setState(() => _starting = true);
    final ok = await _mesh.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (!ok) gToast(context, _mesh.lastError.isEmpty ? GameT.t('nearby_perm') : '${GameT.t('nearby_perm')}\n(${_mesh.lastError.length > 70 ? _mesh.lastError.substring(0, 70) : _mesh.lastError})');
  }

  // ---------------------------------------------------------------- پیام‌های شبکه

  void _onEvent(Map<String, dynamic> m) {
    if (!mounted) return;
    final g = '${m['g']}';
    if (!g.startsWith('ef_')) return;
    final from = '${m['u']}';
    final fromName = '${m['n']}';
    final toMe = '${m['to']}' == _mesh.myUid;
    switch (g) {
      case 'ef_open':
        if (stage == 'join') {
          final c = '${m['code']}';
          setState(() {
            rooms[c] = _EfRoom(c, from, fromName, (m['cnt'] as num?)?.toInt() ?? 1, (m['cap'] as num?)?.toInt() ?? 4, DateTime.now().millisecondsSinceEpoch);
          });
        }
        break;
      case 'ef_join':
        if (stage == 'host' && toMe && '${m['code']}' == code) {
          if (!ids.contains(from) && ids.length < cap) {
            setState(() {
              ids.add(from);
              pnames.add(fromName);
            });
            _sendRoster();
          } else if (ids.contains(from)) {
            _sendRoster();
          }
        } else if (stage == 'play' && isHost && toMe && ids.contains(from)) {
          _sendRoster(go: true); // بازیکنی که پیام شروع را از دست داده
        }
        break;
      case 'ef_leave':
        if (stage == 'host' && toMe && '${m['code']}' == code && ids.contains(from) && from != _mesh.myUid) {
          final k = ids.indexOf(from);
          setState(() {
            ids.removeAt(k);
            pnames.removeAt(k);
          });
          _sendRoster();
        }
        break;
      case 'ef_ros':
        if (stage == 'join' && '${m['code']}' == code) {
          final l = (m['ids'] as List<dynamic>).map((e) => '$e').toList();
          final n = (m['names'] as List<dynamic>).map((e) => '$e').toList();
          if (l.contains(_mesh.myUid)) {
            setState(() {
              ids
                ..clear()
                ..addAll(l);
              pnames
                ..clear()
                ..addAll(n);
              joined = true;
              cap = (m['cap'] as num?)?.toInt() ?? cap;
              time = (m['tm'] as num?)?.toInt() ?? time;
            });
            if (m['go'] == true) _openGame();
          }
        }
        break;
      case 'ef_g':
        if (stage == 'play' && '${m['code']}' == code && ids.contains(from)) {
          final idx = ids.indexOf(from);
          if (isHost) {
            if (toMe) _toWeb(idx, '${m['p']}');
          } else if (from == hostUid && '${m['to']}' == '*') {
            _toWeb(idx, '${m['p']}');
          }
        }
        break;
    }
  }

  void _sendRoster({bool go = false}) {
    _send(<String, dynamic>{'g': 'ef_ros', 'code': code, 'ids': ids, 'names': pnames, 'cap': cap, 'tm': time, 'go': go});
  }

  // ---------------------------------------------------------------- لابی

  void _createGame() {
    if (!_mesh.running) return;
    code = '${1000 + _rnd.nextInt(9000)}';
    isHost = true;
    joined = true;
    hostUid = _mesh.myUid;
    ids
      ..clear()
      ..add(_mesh.myUid);
    pnames
      ..clear()
      ..add(_mesh.myName);
    setState(() => stage = 'host');
    _send(<String, dynamic>{'g': 'ef_open', 'code': code, 'cnt': 1, 'cap': cap});
  }

  void _openJoin() {
    isHost = false;
    joined = false;
    code = '';
    ids.clear();
    pnames.clear();
    setState(() => stage = 'join');
  }

  void _joinRoom(_EfRoom r) {
    setState(() {
      code = r.code;
      hostUid = r.hostUid;
      cap = r.cap;
      joined = false;
    });
    _send(<String, dynamic>{'g': 'ef_join', 'to': hostUid, 'code': code});
    // تا وقتی میزبان فهرست بازیکنان را نفرستاده، هر ۰٫۶ ثانیه دوباره درخواست می‌دهیم
    _joinTick?.cancel();
    _joinTick = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted || joined || stage != 'join' || code.isEmpty) {
        t.cancel();
      } else {
        _send(<String, dynamic>{'g': 'ef_join', 'to': hostUid, 'code': code});
      }
    });
  }

  void _hostStart() {
    if (ids.length < 2) return;
    _sendRoster(go: true);
    // پیام شروع چند بار فرستاده می‌شود تا هیچ گوشی‌ای جا نماند
    for (final ms in <int>[500, 1500, 3000]) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (mounted && stage == 'play') _sendRoster(go: true);
      });
    }
    _openGame();
  }

  // ---------------------------------------------------------------- صفحهٔ بازی

  void _openGame() {
    if (stage == 'play') return;
    _ready = false;
    _queue.clear();
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1A2B))
      ..addJavaScriptChannel('NetCh', onMessageReceived: (m) => _fromWeb(m.message))
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => _webReady()))
      ..loadFlutterAsset('assets/games/esmfamil.html');
    setState(() {
      _c = c;
      stage = 'play';
    });
  }

  void _webReady() {
    if (_ready || !mounted) return;
    _ready = true;
    final init = jsonEncode(<String, dynamic>{'me': me < 0 ? 0 : me, 'host': isHost, 'names': pnames, 'time': time});
    _c?.runJavaScript('window.netInit($init)');
    for (final q in _queue) {
      _c?.runJavaScript(q);
    }
    _queue.clear();
  }

  void _js(String s) {
    if (stage != 'play' || _c == null) return;
    if (!_ready) {
      if (s.startsWith('window.onNet')) _queue.add(s);
      return;
    }
    _c!.runJavaScript(s);
  }

  void _toWeb(int idx, String payload) => _js('window.onNet($idx,${jsonEncode(payload)})');

  void _fromWeb(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['x'] == 'exit') {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final p = jsonEncode(m['p']);
      if (p.length > 30000) return; // سقف پیام Nearby
      if (m['to'] == '*') {
        if (isHost) _send(<String, dynamic>{'g': 'ef_g', 'code': code, 'to': '*', 'p': p});
      } else if (!isHost) {
        _send(<String, dynamic>{'g': 'ef_g', 'code': code, 'to': hostUid, 'p': p});
      }
    } catch (_) {}
  }

  Future<bool> _confirmExit() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          title: Text(_x('خروج از بازی؟', 'Leave the game?'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          content: Text(
            isHost ? _x('شما میزبان هستید؛ با خروج شما بازی برای همه تمام می‌شود.', 'You are the host; leaving ends the game for everyone.') : _x('بازی برای بقیه ادامه پیدا می‌کند.', 'The game continues for the others.'),
            style: const TextStyle(color: Colors.white70, height: 1.7),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_x('ادامه بازی', 'Stay'))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_x('خروج', 'Leave'), style: const TextStyle(color: Color(0xffff6b6b)))),
          ],
        ),
      ),
    );
    return r == true;
  }

  // ---------------------------------------------------------------- رابط

  Widget _netCard() {
    final on = _mesh.running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: on ? gPanel : gGold, foregroundColor: on ? gGold : gBg, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _toggleNet,
        icon: _starting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
        label: Text(on ? '${GameT.t('nearby_stop')} · ${_mesh.peers.length}' : GameT.t('nearby_start'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _bigButton(IconData icon, String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine, padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _row(String name, {Widget? trailing, bool empty = false, bool crown = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: empty ? gLine.withOpacity(0.5) : gLine)),
      child: Row(
        children: [
          Icon(crown ? Icons.workspace_premium_rounded : Icons.phone_android_rounded, color: empty ? gMuted : (crown ? gGold : gTeal)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: TextStyle(color: empty ? gMuted : Colors.white, fontWeight: FontWeight.w800))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _chips(String title, List<int> values, int cur, String Function(int) label, void Function(int) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(label(v), style: TextStyle(fontWeight: FontWeight.w900, color: v == cur ? gBg : Colors.white)),
                  selected: v == cur,
                  selectedColor: gGold,
                  backgroundColor: gPanel,
                  side: const BorderSide(color: gLine),
                  onSelected: (_) => onPick(v),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        if (_mesh.running) ...[
          _chips(_x('ظرفیت بازی', 'Players'), _caps, cap, (v) => _x('$v نفره', '$v players'), (v) => setState(() => cap = v)),
          _chips(_x('زمان هر دور', 'Time per round'), _times, time, (v) => _x('$v ثانیه', '$v s'), (v) => setState(() => time = v)),
          _bigButton(Icons.add_circle_rounded, _x('ساخت بازی (میزبان)', 'Host a game'), _createGame),
          _bigButton(Icons.login_rounded, _x('پیوستن به بازی', 'Join a game'), _openJoin),
        ],
        const SizedBox(height: 10),
        Text(
          _x(
            'بدون اینترنت. همهٔ گوشی‌ها باید شبکهٔ نزدیک را روشن کنند و کنار هم باشند. هر نفر روی گوشی خودش می‌نویسد؛ میزبان داور بازی است. ۲، ۳، ۴ یا ۶ نفره.',
            'No internet needed. Everyone turns on the nearby network and stays close. Each player writes on their own phone; the host referees. 2, 3, 4 or 6 players.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: gMuted, fontSize: 12, height: 1.8),
        ),
      ],
    );
  }

  Widget _hostBody() {
    final full = ids.length >= cap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        Text(_x('بازیکنان: ${ids.length} از $cap', 'Players: ${ids.length} of $cap'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 8),
        for (var i = 0; i < cap; i++)
          i < pnames.length ? _row(pnames[i], crown: i == 0) : _row(_x('منتظر بازیکن…', 'Waiting for a player…'), empty: true),
        const SizedBox(height: 6),
        Text(_x('کد بازی: $code · ${time} ثانیه برای هر دور', 'Game code: $code · $time s per round'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _bigButton(
          Icons.play_arrow_rounded,
          ids.length < 2 ? _x('حداقل ۲ بازیکن لازم است', 'At least 2 players needed') : (full ? _x('شروع بازی', 'Start game') : _x('شروع با ${ids.length} نفر', 'Start with ${ids.length} players')),
          ids.length < 2 ? null : _hostStart,
        ),
      ],
    );
  }

  Widget _joinBody() {
    final list = rooms.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _netCard(),
        if (code.isNotEmpty && joined) ...[
          Text(_x('پیوستید. منتظر شروع بازی توسط میزبان…', 'Joined. Waiting for the host to start…'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.8)),
          const SizedBox(height: 10),
          for (var i = 0; i < pnames.length; i++) _row(pnames[i], crown: i == 0),
        ] else ...[
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _x('بازی‌ای در اطراف پیدا نشد.\nمیزبان باید «ساخت بازی» را بزند و همه نزدیک هم باشند.', 'No game found nearby.\nThe host must tap “Host a game”, and everyone must be close.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: gMuted, height: 1.9),
              ),
            ),
          for (final r in list)
            _row(
              r.hostName,
              trailing: code == r.code
                  ? Text(GameT.t('nearby_wait'), style: const TextStyle(color: gMuted, fontSize: 12))
                  : FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, disabledBackgroundColor: gLine),
                      onPressed: r.count >= r.cap ? null : () => _joinRoom(r),
                      child: Text(r.count >= r.cap ? _x('پر است', 'Full') : _x('پیوستن · ${r.count} از ${r.cap}', 'Join · ${r.count}/${r.cap}'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final playing = stage == 'play' && _c != null;
    return PopScope(
      canPop: !playing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) Navigator.of(context).pop();
      },
      child: Directionality(
        textDirection: gDir,
        child: Scaffold(
          backgroundColor: playing ? const Color(0xFF0E1A2B) : gBg,
          appBar: AppBar(
            backgroundColor: playing ? const Color(0xFF15263D) : gBg,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: playing ? Colors.white : gGold),
            title: Text(
              playing ? _x('اسم و فامیل', 'Name · Family') : '${_x('اسم و فامیل', 'Name · Family')} · ${GameT.t('nearby_title')}',
              style: TextStyle(color: playing ? Colors.white : gGold, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          body: SafeArea(
            child: playing
                ? WebViewWidget(controller: _c!)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: stage == 'host' ? _hostBody() : (stage == 'join' ? _joinBody() : _menuBody()),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
