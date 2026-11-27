import 'dart:async';

import 'package:flutter/material.dart';

import '../pages/games/game_wheel.dart' show wFa;
import '../pages/groups/group_ui.dart';
import '../services/offline_mesh_service.dart';
import 'gg_net.dart';
import 'gg_prefs.dart';
import 'gg_settings_sheet.dart';
import 'gg_types.dart';
import 'golf_page.dart';
import 'hockey_page.dart';

enum _St { choose, host, joining, wait, error }

/// لابی مشترک هاکی و مینی‌گلف: تک‌نفره با ربات، یا ۲ تا ۴ نفر با گوشی‌های اطراف (بدون اینترنت).
class GgLobbyPage extends StatefulWidget {
  const GgLobbyPage({super.key, required this.game});
  final String game; // 'hockey' | 'golf'

  @override
  State<GgLobbyPage> createState() => _GgLobbyPageState();
}

class _GgLobbyPageState extends State<GgLobbyPage> {
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();
  GgNet? _net;
  _St _st = _St.choose;
  String _err = '';
  bool _busy = false;
  bool _opened = false;
  bool _fillBots = false;
  int _level = 1;
  int _lives = 5;
  int _holes = 9;
  Timer? _joinTimeout;

  static const List<String> _botNames = <String>['داریوش', 'میترا', 'کتایون', 'آرش', 'آناهیتا', 'مهرداد'];
  bool get _hockey => widget.game == 'hockey';

  @override
  void initState() {
    super.initState();
    GgPrefs.instance.load().then((_) {
      if (mounted) setState(() => _name.text = GgPrefs.instance.name);
    });
  }

  @override
  void dispose() {
    _joinTimeout?.cancel();
    _code.dispose();
    _name.dispose();
    if (!_opened) _net?.close();
    super.dispose();
  }

  void _saveName() {
    final n = _name.text.trim();
    GgPrefs.instance.name = n.isEmpty ? 'بازیکن' : (n.length > 14 ? n.substring(0, 14) : n);
    GgPrefs.instance.save();
  }

  Future<bool> _ensureMesh() async {
    if (_mesh.running) return true;
    final ok = await _mesh.start();
    if (!ok && mounted) _fail('دسترسی‌های شبکه‌ی نزدیک (بلوتوث، مکان و وای‌فای) داده نشد.');
    return ok;
  }

  void _fail(String e) {
    _net?.close(notify: false);
    _net = null;
    setState(() {
      _st = _St.error;
      _err = e;
      _busy = false;
    });
  }

  Widget _gamePage(GgConfig cfg, GgNet? net, int me) => _hockey ? GgHockeyPage(cfg: cfg, net: net, me: me) : GgGolfPage(cfg: cfg, net: net, me: me);

  void _open(GgConfig cfg, GgNet? net, int me) {
    if (_opened || !mounted) return;
    _opened = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => _gamePage(cfg, net, me)));
  }

  // ---------------------------------------------------------------- تک‌نفره
  void _solo() {
    _saveName();
    final me = GgPlayer(name: GgPrefs.instance.name, col: GgPrefs.instance.hkMallet);
    final bot = GgPlayer(name: _botNames[DateTime.now().second % _botNames.length], col: (GgPrefs.instance.hkMallet + 3) % GgPrefs.palette.length, bot: true);
    final cfg = GgConfig(game: widget.game, players: <GgPlayer>[me, bot], level: _level, lives: _lives, holes: _holes, solo: true);
    _open(cfg, null, 0);
  }

  // ---------------------------------------------------------------- میزبان
  Future<void> _host() async {
    if (_busy) return;
    _saveName();
    setState(() => _busy = true);
    if (!await _ensureMesh()) return;
    final n = GgNet(isHost: true, room: GgNet.newCode(), game: widget.game);
    n.onLobby = () {
      if (mounted) setState(() {});
    };
    n.open();
    if (!mounted) return;
    setState(() {
      _net = n;
      _st = _St.host;
      _busy = false;
    });
  }

  void _hostStart() {
    final n = _net;
    if (n == null) return;
    final pl = <GgPlayer>[];
    for (final s in n.seats) {
      if (s != null) pl.add(GgPlayer(name: s['name'] ?? 'بازیکن', col: int.tryParse(s['col'] ?? '0') ?? 0, uid: s['uid'] ?? ''));
    }
    if (_fillBots) {
      var k = 0;
      while (pl.length < GgNet.maxPlayers) {
        pl.add(GgPlayer(name: _botNames[k % _botNames.length], col: (k * 2 + 3) % GgPrefs.palette.length, bot: true));
        k++;
      }
    }
    if (pl.length < 2) {
      gToast(context, 'حداقل دو بازیکن لازم است (یا ربات را روشن کنید)');
      return;
    }
    final cfg = GgConfig(game: widget.game, players: pl, level: _level, lives: _lives, holes: _holes);
    n.hostStart(cfg.toJson());
    _open(cfg, n, pl.indexWhere((p) => p.uid == n.myUid));
  }

  // ---------------------------------------------------------------- مهمان
  Future<void> _join() async {
    final c = _code.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(c)) {
      gToast(context, 'کد باید چهار رقم باشد');
      return;
    }
    if (_busy) return;
    _saveName();
    setState(() => _busy = true);
    if (!await _ensureMesh()) return;
    final n = GgNet(isHost: false, room: c, game: widget.game);
    n.onLobby = () {
      if (!mounted) return;
      if (_st == _St.joining) _joinTimeout?.cancel();
      setState(() => _st = _St.wait);
    };
    n.onStart = (m) {
      final cfg = GgConfig.fromJson(m);
      _open(cfg, n, cfg.players.indexWhere((p) => p.uid == n.myUid));
    };
    n.onClosed = (r) {
      if (mounted) _fail(r);
    };
    n.open();
    setState(() {
      _net = n;
      _st = _St.joining;
      _busy = false;
    });
    _joinTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted && _st == _St.joining) _fail('اتاقی با این کد پیدا نشد. کد را بررسی کنید و مطمئن شوید همه‌ی گوشی‌ها به شبکه‌ی نزدیک وصل هستند.');
    });
  }

  // ---------------------------------------------------------------- رابط
  Widget _chips(String title, List<String> labels, int cur, ValueChanged<int> on) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: gMuted, fontSize: 13)),
          const SizedBox(width: 10),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(
                label: Text(labels[i], style: TextStyle(color: cur == i ? gBg : Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                selected: cur == i,
                selectedColor: gGold,
                backgroundColor: gPanel,
                onSelected: (_) => on(i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _options() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chips('سختی ربات', const <String>['آسان', 'معمولی', 'سخت'], _level, (i) => setState(() => _level = i)),
        if (_hockey)
          _chips('جان هر بازیکن', const <String>['۳', '۵', '۷'], _lives == 3 ? 0 : (_lives == 5 ? 1 : 2), (i) => setState(() => _lives = <int>[3, 5, 7][i]))
        else
          _chips('تعداد حفره', const <String>['۳', '۶', '۹'], _holes == 3 ? 0 : (_holes == 6 ? 1 : 2), (i) => setState(() => _holes = <int>[3, 6, 9][i])),
      ],
    );
  }

  Widget _panel(Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: gLine)),
        child: child,
      );

  Widget _bigBtn(String t, IconData ic, VoidCallback? on, {bool gold = true}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: gold ? gGold : gTeal, foregroundColor: gBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: on,
        icon: Icon(ic),
        label: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _slots() {
    final n = _net!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < GgNet.maxPlayers; i++)
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: n.seats[i] == null ? Colors.white24 : GgPrefs.palette[int.tryParse(n.seats[i]!['col'] ?? '0') ?? 0], width: 2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: n.seats[i] == null ? Colors.white12 : GgPrefs.palette[int.tryParse(n.seats[i]!['col'] ?? '0') ?? 0],
                  child: Icon(n.seats[i] == null ? Icons.add_rounded : Icons.person_rounded, size: 16, color: n.seats[i] == null ? Colors.white54 : gBg),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    n.seats[i]?['name'] ?? (_st == _St.host && _fillBots ? 'ربات' : 'خالی'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: n.seats[i] == null ? Colors.white38 : Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                if (i == 0) const Icon(Icons.star_rounded, color: gGold, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _body() {
    switch (_st) {
      case _St.choose:
        return Column(
          children: [
            _panel(
              TextField(
                controller: _name,
                maxLength: 14,
                onChanged: (_) => _saveName(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(labelText: 'نام شما', labelStyle: TextStyle(color: gMuted), counterText: '', enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gLine))),
              ),
            ),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تک‌نفره با ربات', style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
                  _options(),
                  const SizedBox(height: 12),
                  _bigBtn('شروع بازی', Icons.smart_toy_rounded, _solo),
                ],
              ),
            ),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('۲ تا ۴ نفر با گوشی‌های اطراف (بدون اینترنت)', style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 12),
                  _bigBtn('ساخت اتاق (میزبان)', Icons.wifi_tethering_rounded, _busy ? null : _host, gold: false),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 6),
                          decoration: InputDecoration(
                            hintText: 'کد اتاق',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 0),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: gSky, foregroundColor: gBg, minimumSize: const Size(90, 52)),
                        onPressed: _busy ? null : _join,
                        child: const Text('ورود', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case _St.host:
        final n = _net!;
        return Column(
          children: [
            _panel(
              Column(
                children: [
                  const Text('کد اتاق را به بقیه بگویید', style: TextStyle(color: gMuted)),
                  const SizedBox(height: 6),
                  Text(wFa(n.room), style: const TextStyle(color: gGold, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 10)),
                  const SizedBox(height: 4),
                  const Text('همه‌ی گوشی‌ها باید «ورود با کد» را بزنند', style: TextStyle(color: gMuted, fontSize: 12)),
                ],
              ),
            ),
            _panel(Column(children: [_slots(), _options()])),
            SwitchListTile(
              value: _fillBots,
              onChanged: (v) => setState(() => _fillBots = v),
              activeColor: gGold,
              title: const Text('پر کردن جاهای خالی با ربات', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            _bigBtn('شروع مسابقه (${wFa(n.humanCount)} نفر)', Icons.play_arrow_rounded, _hostStart),
          ],
        );
      case _St.joining:
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Column(children: [CircularProgressIndicator(color: gGold), SizedBox(height: 16), Text('در حال پیدا کردن اتاق…', style: TextStyle(color: Colors.white))]),
        );
      case _St.wait:
        return Column(
          children: [
            _panel(Column(children: [_slots(), const SizedBox(height: 14), const Text('منتظر شروع مسابقه توسط میزبان…', style: TextStyle(color: gMuted))])),
          ],
        );
      case _St.error:
        return _panel(
          Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: gGold, size: 42),
              const SizedBox(height: 8),
              Text(_err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, height: 1.8)),
              const SizedBox(height: 14),
              _bigBtn('بازگشت', Icons.arrow_back_rounded, () => setState(() => _st = _St.choose)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          foregroundColor: Colors.white,
          title: Text(_hockey ? '🏒 هاکی روی میز' : '⛳ مینی‌گلف', style: const TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(icon: const Icon(Icons.tune_rounded, color: gGold), tooltip: 'تنظیمات و فروشگاه', onPressed: () => showGgSettings(context, widget.game)),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [_body()]),
      ),
    );
  }
}
