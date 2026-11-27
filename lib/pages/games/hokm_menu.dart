import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import 'hokm_net.dart';
import 'hokm_prefs.dart';
import 'hokm_settings.dart';
import 'hokm_table_page.dart';
import 'hokm_widgets.dart';

/// منوی اصلی «حکم»: آفلاین با ربات، آنلاین، بین چهار گوشی، تنظیمات و قوانین.
class HokmMenuPage extends StatefulWidget {
  const HokmMenuPage({super.key});

  @override
  State<HokmMenuPage> createState() => _HokmMenuPageState();
}

class _HokmMenuPageState extends State<HokmMenuPage> {
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    HokmPrefs.instance.load().then((_) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await HokmTablePage.hasSave();
    if (mounted) setState(() => _hasSave = s);
  }

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff3d0c28),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.6), radius: 1.2, colors: const [Color(0xff8b2260), Color(0xff3d0c28), Color(0xff1c0614)], stops: const [0, .6, 1])),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  const Positioned(top: 8, left: 12, child: HokmLogo(size: 44)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70)),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'حکم',
                              style: TextStyle(
                                color: Color(0xffe8bb55),
                                fontSize: 82,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                shadows: <Shadow>[Shadow(color: Color(0xff5a3a05), offset: Offset(0, 4)), Shadow(color: Colors.black87, blurRadius: 22, offset: Offset(0, 8))],
                              ),
                            ),
                            const Text('H O K M', style: TextStyle(color: Color(0xfff6e9c8), letterSpacing: 6, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 26),
                            HokmButton(title: 'بازی آفلاین', sub: 'با سه ربات، بدون اینترنت', icon: Icons.smart_toy_rounded, onTap: () => _go(const HokmTablePage())),
                            const SizedBox(height: 14),
                            HokmButton(title: 'بازی آنلاین', sub: 'به‌زودی؛ نیاز به سرور بازی دارد', icon: Icons.public_rounded, onTap: null),
                            const SizedBox(height: 14),
                            HokmButton(title: 'بازی بین چهار گوشی', sub: 'ساخت اتاق یا پیوستن با کد، بدون اینترنت', icon: Icons.wifi_tethering_rounded, onTap: () => _go(const HokmLobbyPage())),
                            const SizedBox(height: 14),
                            HokmButton(title: 'ادامه بازی قبلی', icon: Icons.play_circle_fill_rounded, style: HokmBtnStyle.dark, onTap: _hasSave ? () => _go(const HokmTablePage(resume: true)) : null),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: HokmButton(title: 'تنظیمات', icon: Icons.settings_rounded, style: HokmBtnStyle.dark, onTap: () => showHokmSettings(context))),
                                const SizedBox(width: 12),
                                Expanded(child: HokmButton(title: 'قوانین', icon: Icons.menu_book_rounded, style: HokmBtnStyle.dark, onTap: () => showHokmSettings(context, tab: 3))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// اتاق چهار گوشی

enum _LS { choose, join, joining, host, wait, error }

class HokmLobbyPage extends StatefulWidget {
  const HokmLobbyPage({super.key});

  @override
  State<HokmLobbyPage> createState() => _HokmLobbyPageState();
}

class _HokmLobbyPageState extends State<HokmLobbyPage> {
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final TextEditingController _code = TextEditingController();
  HokmNet? _net;
  _LS _st = _LS.choose;
  String _err = '';
  bool _busy = false;
  bool _opened = false;
  Timer? _joinTimeout;

  @override
  void dispose() {
    _joinTimeout?.cancel();
    _code.dispose();
    if (!_opened) _net?.close();
    super.dispose();
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
      _st = _LS.error;
      _err = e;
      _busy = false;
    });
  }

  Future<void> _host() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (!await _ensureMesh()) return;
    final n = HokmNet(isHost: true, room: HokmNet.newCode());
    n.onLobby = () {
      if (mounted) setState(() {});
    };
    n.open();
    if (!mounted) return;
    setState(() {
      _net = n;
      _st = _LS.host;
      _busy = false;
    });
  }

  Future<void> _join() async {
    final c = _code.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(c)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد باید چهار رقم باشد')));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    if (!await _ensureMesh()) return;
    final n = HokmNet(isHost: false, room: c);
    n.onLobby = () {
      if (!mounted) return;
      if (_st == _LS.joining) _joinTimeout?.cancel();
      setState(() => _st = _LS.wait);
    };
    n.onView = (v) {
      if (!mounted || _opened) return;
      _opened = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => HokmTablePage(net: n, firstView: v)));
    };
    n.onClosed = (r) {
      if (mounted) _fail(r);
    };
    n.open();
    setState(() {
      _net = n;
      _st = _LS.joining;
      _busy = false;
    });
    _joinTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted && _st == _LS.joining) _fail('اتاقی با این کد پیدا نشد. کد را بررسی کنید و مطمئن شوید همه‌ی گوشی‌ها به شبکه‌ی نزدیک وصل هستند.');
    });
  }

  void _start() {
    final n = _net;
    if (n == null) return;
    _opened = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => HokmTablePage(net: n)));
  }

  Widget _seat(int s, int mine) {
    final n = _net!;
    final r = (s - mine + 4) % 4;
    final st = n.seats[s];
    final tag = r == 0 ? 'شما' : (r == 2 ? 'هم‌تیمی شما' : 'حریف');
    final canTake = st == null && _st == _LS.wait;
    return GestureDetector(
      onTap: canTake ? () => n.wantSeat(s) : null,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: r == 0 ? const Color(0xffe8bb55) : Colors.white24, width: r == 0 ? 2 : 1),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            st == null
                ? Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12), child: const Icon(Icons.add_rounded, color: Colors.white70))
                : HokmAvatar(avatar: st['avatar'] ?? '0', size: 44),
            const SizedBox(height: 4),
            Text(st?['name'] ?? (_st == _LS.host ? 'ربات' : 'خالی'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(tag, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _seatMap() {
    final mine = _st == _LS.wait ? _net!.mySeat : 0;
    int at(int r) => (mine + r) % 4;
    return SizedBox(
      width: 330,
      height: 300,
      child: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: _seat(at(2), mine)),
          Align(alignment: Alignment.centerRight, child: _seat(at(1), mine)),
          Align(alignment: Alignment.centerLeft, child: _seat(at(3), mine)),
          Align(alignment: Alignment.bottomCenter, child: _seat(at(0), mine)),
          Center(child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff1a8f63).withOpacity(.55), border: Border.all(color: Colors.white24)), child: const Icon(Icons.style_rounded, color: Colors.white70, size: 34))),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_st) {
      case _LS.choose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Title('بازی بین چهار گوشی'),
            const _Sub('یک گوشی اتاق می‌سازد و سه گوشی دیگر با کد وارد می‌شوند. هم‌تیمی‌ها روبه‌روی هم می‌نشینند و جای خالی با ربات پر می‌شود.'),
            const SizedBox(height: 22),
            HokmButton(title: 'ساخت اتاق', sub: 'این گوشی میزبان است', icon: Icons.add_home_rounded, style: HokmBtnStyle.green, onTap: _busy ? null : _host),
            const SizedBox(height: 14),
            HokmButton(title: 'پیوستن به اتاق', sub: 'با کد چهار رقمی میزبان', icon: Icons.login_rounded, onTap: () => setState(() => _st = _LS.join)),
          ],
        );
      case _LS.join:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Title('پیوستن به اتاق'),
            const _Sub('کد چهار رقمی را از میزبان بگیرید.'),
            const SizedBox(height: 18),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 34, letterSpacing: 10, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black38,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff8a5a3a))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe8bb55), width: 2)),
              ),
            ),
            const SizedBox(height: 18),
            HokmButton(title: 'پیوستن', icon: Icons.login_rounded, style: HokmBtnStyle.green, onTap: _busy ? null : _join),
          ],
        );
      case _LS.joining:
        return const Column(mainAxisSize: MainAxisSize.min, children: [_Title('در حال اتصال…'), SizedBox(height: 18), CircularProgressIndicator(color: Color(0xffe8bb55))]);
      case _LS.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Title('اتصال انجام نشد'),
            _Sub(_err),
            const SizedBox(height: 18),
            HokmButton(title: 'تلاش دوباره', icon: Icons.refresh_rounded, onTap: () => setState(() => _st = _LS.choose)),
          ],
        );
      case _LS.host:
      case _LS.wait:
        final n = _net!;
        final count = n.seats.where((s) => s != null).length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Title(_st == _LS.host ? 'اتاق شما' : 'وارد اتاق شدید'),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffa8791f))),
              child: Text(n.room, textDirection: TextDirection.ltr, style: const TextStyle(color: Color(0xffe8bb55), fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 10)),
            ),
            _Sub(_st == _LS.host ? 'این کد را به سه نفر دیگر بدهید. بازیکن‌ها با لمس یک صندلی خالی می‌توانند جایشان را عوض کنند.' : 'منتظر شروع بازی توسط میزبان هستید. برای عوض کردن جا، یک صندلی خالی را لمس کنید.'),
            const SizedBox(height: 8),
            _seatMap(),
            const SizedBox(height: 10),
            if (_st == _LS.host) HokmButton(title: 'شروع بازی ($count نفر + ${4 - count} ربات)', icon: Icons.play_arrow_rounded, style: HokmBtnStyle.green, onTap: _start),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: const Color(0xff2c0a1f),
          body: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xff4a1235), Color(0xff14040e)])),
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned(top: 8, left: 12, child: HokmLogo(size: 44)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        if (_st == _LS.join || _st == _LS.error) {
                          setState(() => _st = _LS.choose);
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 70),
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: _body()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffe8bb55), fontSize: 26, fontWeight: FontWeight.w900, shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3))]));
}

class _Sub extends StatelessWidget {
  const _Sub(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8, fontSize: 13)));
}
