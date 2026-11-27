import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hokm_engine.dart' show HCard, kSuitChar;
import 'hokm_match.dart';
import 'hokm_net.dart';
import 'hokm_prefs.dart';
import 'hokm_settings.dart';
import 'hokm_widgets.dart';

/// میز «حکم»: همه‌ی بازی‌ها (آفلاین با ربات و چهار گوشی) از همین صفحه رد می‌شوند.
/// صفحه فقط «نمای» بازی را می‌گیرد و رسم می‌کند؛ قوانین در [HokmMatch] روی گوشی میزبان است.
class HokmTablePage extends StatefulWidget {
  const HokmTablePage({super.key, this.net, this.firstView, this.resume = false});

  /// بازی چهار گوشی؛ null یعنی آفلاین با ربات
  final HokmNet? net;
  final Map<String, dynamic>? firstView;
  final bool resume;

  static const String saveKey = 'hokm4_save';

  static Future<bool> hasSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString(saveKey) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  State<HokmTablePage> createState() => _HokmTablePageState();
}

int _n(dynamic x) => (x as num).toInt();
HCard _card(dynamic id) => HCard(_n(id) ~/ 20, _n(id) % 20);
int _team(int s) => s % 2;
const List<String> _kindName = <String>['', 'نرس', 'سرس', 'تک نرس'];
const List<String> _suitName = <String>['پیک', 'دل', 'خشت', 'گشنیز'];
const List<String> _quick = <String>['سلام 👋', 'آفرین! 👏', 'دمت گرم', 'زود باش ⏰', 'حکمت چیه؟', 'کوتش می‌کنیم!', 'ببخشید 🙏', '😂', '😎', '😡', 'بازی قشنگی بود'];
const List<String> _botSay = <String>['سلام 👋', 'آفرین! 👏', 'دمت گرم', 'زود باش ⏰', '😂', '😎', 'بازی قشنگیه', 'ببخشید 🙏'];

class _HokmTablePageState extends State<HokmTablePage> {
  final HokmPrefs _pr = HokmPrefs.instance;
  final Random _rnd = Random();
  HokmMatch? _match;
  HokmNet? _net;
  Map<String, dynamic>? _v;
  Map<String, dynamic>? _p;
  bool _pend = false;
  bool _pulse = false;
  bool _overShown = false;
  bool _chatOpen = false;
  bool _unread = false;
  String _toast = '';
  String _banner = '';
  String _hl = '';
  String _hlSub = '';
  bool _hlOurs = true;
  final Map<int, String> _bubbles = <int, String>{};
  final List<_Chat> _chat = <_Chat>[];
  final TextEditingController _chatCtl = TextEditingController();
  final List<Timer> _timers = <Timer>[];
  int _confetti = 0;

  int get _seat => _v == null ? 0 : _n(_v!['seat']);

  @override
  void initState() {
    super.initState();
    _pr.addListener(_onPrefs);
    _pr.load();
    _net = widget.net;
    final net = _net;
    if (net != null) {
      net.onView = _apply;
      net.onChat = _onChat;
      net.onClosed = (r) {
        if (!mounted) return;
        _showToast(r);
        Navigator.of(context).maybePop();
      };
      net.onError = (e) {
        if (mounted && e != _banner) setState(() => _banner = e);
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.firstView != null) {
          _apply(widget.firstView!);
        } else if (net.isHost && net.match == null) {
          net.hostStart();
        } else if (net.match != null) {
          _apply(net.match!.view(0));
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startOffline());
    }
  }

  @override
  void dispose() {
    _pr.removeListener(_onPrefs);
    for (final t in _timers) {
      t.cancel();
    }
    _chatCtl.dispose();
    _match?.destroy();
    _net?.close();
    super.dispose();
  }

  void _onPrefs() {
    if (mounted) setState(() {});
  }

  Timer _after(int ms, VoidCallback f) {
    final t = Timer(Duration(milliseconds: ms), () {
      if (mounted) f();
    });
    _timers.add(t);
    return t;
  }

  // ------------------------------------------------------------ شروع آفلاین
  Future<void> _startOffline() async {
    await _pr.load();
    HokmMatch? m;
    if (widget.resume) {
      try {
        final sp = await SharedPreferences.getInstance();
        final raw = sp.getString(HokmTablePage.saveKey);
        if (raw != null) {
          final s = jsonDecode(raw) as Map<String, dynamic>;
          final pl = (s['pl'] as List).map((e) => HokmPlayer(name: '${e['n']}', avatar: '${e['a']}', bot: e['b'] == true)).toList();
          pl[0]
            ..name = _pr.name
            ..avatar = _pr.avatar;
          m = HokmMatch(players: pl, target: _n(s['target']), saved: s);
        }
      } catch (_) {
        m = null;
      }
    }
    final fresh = m == null;
    m ??= HokmMatch(
      players: <HokmPlayer>[
        HokmPlayer(name: _pr.name, avatar: _pr.avatar),
        ..._botPlayers(),
      ],
      target: _pr.target,
    );
    m.speedPercent = _pr.speed;
    m.onChange = () {
      if (!mounted) return;
      _apply(m!.view(0));
      _save(m!);
    };
    _match = m;
    if (fresh) {
      m.start();
    } else {
      m.resume();
    }
  }

  List<HokmPlayer> _botPlayers() {
    const names = <String>['داریوش', 'میترا', 'کتایون', 'آرش', 'آناهیتا'];
    const av = <String, String>{'داریوش': '2', 'میترا': '1', 'کتایون': '3', 'آرش': '0', 'آناهیتا': '1'};
    final list = names.where((n) => n != _pr.name).take(3).toList();
    return list.map((n) => HokmPlayer(name: n, avatar: av[n] ?? '0', bot: true)).toList();
  }

  Future<void> _save(HokmMatch m) async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (m.phase == HokmPhase.over) {
        await sp.remove(HokmTablePage.saveKey);
      } else if (m.phase == HokmPhase.play || m.phase == HokmPhase.choose) {
        await sp.setString(HokmTablePage.saveKey, jsonEncode(m.save()));
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------ دریافت نما
  void _apply(Map<String, dynamic> v) {
    if (!mounted) return;
    final p = _v;
    setState(() {
      _p = p;
      _v = v;
      _pend = false;
      if (_banner.isNotEmpty && _net == null) _banner = '';
    });
    _events(p, v);
  }

  void _events(Map<String, dynamic>? p, Map<String, dynamic> v) {
    final seat = _n(v['seat']), ph = _n(v['ph']);
    final newHand = p == null || _n(p['no']) != _n(v['no']);
    final pl = v['pl'] as List;
    if (newHand && ph == 1) {
      HokmSfx.play('deal');
      _showToast('دست ${_n(v['no'])} · حاکم: ${pl[_n(v['hakem'])]['n']}', 2200);
    } else if (p != null && (p['hand'] as List).length < (v['hand'] as List).length) {
      HokmSfx.play('deal');
    }
    if (p != null && !newHand && (v['trick'] as List).length > (p['trick'] as List).length) HokmSfx.play('play');
    final lw = v['last'] == null ? -1 : _n((v['last'] as Map)['w']);
    final lk = v['last'] == null ? '' : jsonEncode((v['last'] as Map)['c']);
    final pk = p == null || p['last'] == null ? '' : jsonEncode((p['last'] as Map)['c']);
    if (p != null && !newHand && lk != pk && lw >= 0 && _team(lw) == _team(seat)) HokmSfx.play('win');
    if (p != null && p['decided'] != true && v['decided'] == true) {
      HokmSfx.play('pick');
      setState(() => _pulse = true);
      _after(1800, () => setState(() => _pulse = false));
    }
    bool turnOf(Map<String, dynamic>? x) => x != null && ((_n(x['ph']) == 2 && _n(x['turn']) == seat) || (_n(x['ph']) == 1 && _n(x['chooser']) == seat));
    if (turnOf(v) && !(turnOf(p) && _n(p!['no']) == _n(v['no']) && _n(p['ph']) == ph)) {
      HokmSfx.play('turn');
      HokmSfx.vibrate();
    }
    if (ph == 5 && (p == null || _n(p['ph']) != 5) && v['res'] != null) {
      final r = v['res'] as Map;
      final ours = _team(seat) == _n(r['t']);
      HokmSfx.play(ours ? 'hand' : 'lose');
      final pts = _n(r['p']);
      setState(() {
        _hl = r['k'] == true ? (ours ? 'کوت!' : 'کوت شدیم!') : (r['hk'] == true ? (ours ? 'حاکم کوت!' : 'حاکم کوت شدیم!') : (ours ? 'دست را بردیم' : 'دست را باختیم'));
        _hlSub = '$pts امتیاز برای ${ours ? 'ما' : 'حریف'}';
        _hlOurs = ours;
      });
      _after(1900, () => setState(() => _hl = ''));
      if (_match != null && _rnd.nextInt(2) == 0) _botTalk();
    }
    if (ph == 6 && (p == null || _n(p['ph']) != 6) && !_overShown) {
      _overShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _endDialog());
    }
    if (ph != 6) _overShown = false;
  }

  void _showToast(String t, [int ms = 1800]) {
    if (!mounted) return;
    setState(() => _toast = t);
    _after(ms, () {
      if (_toast == t) setState(() => _toast = '');
    });
  }

  // ------------------------------------------------------------ عمل بازیکن
  void _act(Map<String, dynamic> m) {
    if (_pend) return;
    _pend = true;
    _after(1200, () => _pend = false);
    final net = _net;
    if (net != null) {
      net.act(m);
    } else {
      _match?.act(0, m);
    }
  }

  void _onCardTap(HCard c, bool legal) {
    final v = _v;
    if (v == null) return;
    final myTurn = _n(v['ph']) == 2 && _n(v['turn']) == _seat;
    if (!myTurn) {
      if (_n(v['ph']) == 2) _showToast('نوبت شما نیست', 900);
      return;
    }
    if (!legal) {
      HokmSfx.vibrate();
      final tr = v['trick'] as List;
      _showToast(tr.isEmpty ? 'این کارت مجاز نیست' : 'باید «${_suitName[_card((tr.first as List)[1]).suit]}» بازی کنید', 1200);
      return;
    }
    _act(<String, dynamic>{'k': 'play', 'c': c.id});
  }

  // ------------------------------------------------------------ چت
  void _botTalk() {
    final m = _match;
    if (m == null) return;
    final bots = <int>[1, 2, 3].where((s) => m.players[s].bot).toList();
    if (bots.isEmpty) return;
    final s = bots[_rnd.nextInt(bots.length)];
    final t = _botSay[_rnd.nextInt(_botSay.length)];
    _after(500 + _rnd.nextInt(900), () => _onChat(s, t));
  }

  void _onChat(int seat, String text) {
    if (!mounted) return;
    final pl = _v == null ? null : (_v!['pl'] as List)[seat];
    setState(() {
      _chat.add(_Chat(seat, pl == null ? '' : '${pl['n']}', text, seat == _seat));
      if (_chat.length > 60) _chat.removeAt(0);
      _bubbles[seat] = text;
      if (seat != _seat && !_chatOpen) _unread = true;
    });
    if (seat != _seat) HokmSfx.play('chat');
    _after(3500, () {
      if (_bubbles[seat] == text) setState(() => _bubbles.remove(seat));
    });
  }

  void _sendChat(String t) {
    final s = t.trim();
    if (s.isEmpty) return;
    final net = _net;
    if (net != null) {
      net.chat(s);
    } else {
      _onChat(0, s);
      if (_rnd.nextInt(2) == 0) _botTalk();
    }
  }

  // ------------------------------------------------------------ خروج و پایان
  Future<void> _exit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروج از بازی؟'),
          content: Text(_net == null ? 'بازی آفلاین ذخیره می‌شود و بعداً می‌توانید ادامه دهید.' : 'با خروج شما، ربات جای شما را می‌گیرد.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ادامه بازی')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('خروج')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _endDialog() async {
    if (!mounted || _v == null) return;
    final v = _v!;
    final seat = _seat;
    final sc = (v['scores'] as List).map(_n).toList();
    final win = sc[_team(seat)] > sc[1 - _team(seat)];
    final pl = v['pl'] as List;
    String nm(int s) => '${pl[s % 4]['n']}';
    HokmSfx.play(win ? 'over' : 'lose');
    if (win) setState(() => _confetti++);
    final isHost = _net == null || _net!.isHost;
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(win ? '😊' : '😔', style: const TextStyle(fontSize: 54)),
                Text(win ? 'شما برنده شدید!' : 'این بار باختید', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 10),
                _line('${nm(seat)} و ${nm(seat + 2)}', sc[_team(seat)]),
                _line('${nm(seat + 1)} و ${nm(seat + 3)}', sc[1 - _team(seat)]),
                const SizedBox(height: 12),
                if (isHost) HokmButton(title: 'بازی دوباره', style: HokmBtnStyle.green, onTap: () => Navigator.of(ctx).pop(true)) else const Text('منتظر میزبان برای بازی دوباره…', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                HokmButton(title: 'بازگشت به منو', style: HokmBtnStyle.dark, onTap: () => Navigator.of(ctx).pop(false)),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (again == true) {
      _overShown = false;
      _act(<String, dynamic>{'k': 'again'});
    } else if (again == false) {
      Navigator.of(context).pop();
    }
  }

  Widget _line(String a, int s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(children: [Expanded(child: Text(a, style: const TextStyle(color: Colors.black87))), Text('$s', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87))]),
      );

  void _showLast() {
    final v = _v;
    if (v == null) return;
    final l = v['last'] as Map?;
    final pl = v['pl'] as List;
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xff2a1228),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('آخرین دست', style: TextStyle(color: Color(0xffe8bb55), fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                if (l == null)
                  const Text('هنوز دستی بازی نشده است.', style: TextStyle(color: Colors.white70))
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in l['c'] as List)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: _n(e[0]) == _n(l['w']) ? BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xffe8bb55), blurRadius: 12, spreadRadius: 2)]) : null,
                              child: HokmCardView(card: _card(e[1]), w: 54),
                            ),
                            const SizedBox(height: 4),
                            Text('${pl[_n(e[0])]['n']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(height: 14),
                HokmButton(title: 'بستن', onTap: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ رسم
  /// چیدن بادبزنی کارت‌ها دور نقطه‌ی [pivot]؛ [base] زاویه‌ی جهت «بالای کارت» است.
  List<Widget> _fan({
    required int n,
    required Offset pivot,
    required double base,
    required double radius,
    required double cw,
    required double maxDeg,
    required double stepDeg,
    required Widget Function(int i) card,
    bool Function(int i)? lifted,
    double lift = 0,
  }) {
    final ch = cw * 1.4;
    final tot = n < 2 ? 0.0 : min(maxDeg, (n - 1) * stepDeg);
    final out = <Widget>[];
    for (var i = 0; i < n; i++) {
      final a = base + (n < 2 ? 0.0 : (-tot / 2 + tot * i / (n - 1)) * pi / 180);
      final rad = radius + ((lifted != null && lifted(i)) ? lift : 0.0);
      final c = pivot + Offset(sin(a), -cos(a)) * (rad + ch / 2);
      out.add(AnimatedPositioned(
        key: ValueKey<String>('f$base-$i-$n'),
        duration: const Duration(milliseconds: 160),
        left: c.dx - cw / 2,
        top: c.dy - ch / 2,
        width: cw,
        height: ch,
        child: Transform.rotate(angle: a, child: card(i)),
      ));
    }
    return out;
  }

  /// آواتار درشت بازیکن (مثل قاب طلایی میان حلقه‌ی ورق‌ها) + روبان نام + تعداد ورق + گفتگو زیر بازیکن.
  /// [side]: 0 وسط، 1 چپ، 2 راست (برای جهت باز شدن حباب گفتگو)؛ [bubbleAbove] فقط برای خودم (زیر من ورق‌هاست).
  Widget _tag(int s, Map<String, dynamic> v, double u, {double size = 14, int side = 0, bool bubbleAbove = false}) {
    final pl = (v['pl'] as List)[s] as Map;
    final turn = (_n(v['turn']) == s && _n(v['ph']) == 2) || (_n(v['ph']) == 1 && _n(v['chooser']) == s);
    final conn = pl['c'] != false;
    final partner = s == (_seat + 2) % 4;
    final cnt = _n((v['cnt'] as List)[s]);
    final d = size * u;
    final rbH = d * .4;
    final rbW = d * 1.55;
    final ring = d + 8;
    final total = ring + rbH * .62;
    final left0 = (rbW - ring) / 2;
    const cyan = Color(0xff27e6e6);
    final nm = '${pl['n']}${partner ? ' (یار)' : ''}${conn ? '' : ' ⚠'}';
    final avatar = Container(
      width: ring,
      height: ring,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xfffff0a8), Color(0xffd9a02c), Color(0xff8a5a10)]),
        boxShadow: <BoxShadow>[
          if (turn) const BoxShadow(color: cyan, blurRadius: 24, spreadRadius: 4),
          BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: HokmAvatar(avatar: '${pl['a']}', size: d, border: turn ? cyan : const Color(0xff3a2208)),
    );
    final ribbon = Container(
      height: rbH,
      width: rbW,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xffffe9a0), Color(0xffe0a92f), Color(0xffb87d14)]),
        borderRadius: BorderRadius.circular(rbH / 2.4),
        border: Border.all(color: const Color(0xff5a3a08), width: 1.5),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(nm, maxLines: 1, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xff3b2208), fontWeight: FontWeight.w900, fontSize: 12.5)),
      ),
    );
    final bd = d * .36;
    final badge = Container(
      width: bd,
      height: bd,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xff2f9c8f), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 4)]),
      child: Text('$cnt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: bd * .6)),
    );
    final b = _bubbles[s];
    Widget? bubble;
    if (b != null) {
      final box = Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black45, blurRadius: 8)]),
        child: Text(b, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.w800)),
      );
      final al = side == 1 ? Alignment.centerLeft : (side == 2 ? Alignment.centerRight : Alignment.center);
      final l = side == 2 ? -110.0 : (side == 1 ? 0.0 : -110.0);
      final r = side == 1 ? -110.0 : (side == 2 ? 0.0 : -110.0);
      bubble = Positioned(
        left: l,
        right: r,
        top: bubbleAbove ? null : total + 3,
        bottom: bubbleAbove ? total + 4 : null,
        child: Align(alignment: al, child: box),
      );
    }
    return IgnorePointer(
      child: Opacity(
        opacity: conn ? 1 : .55,
        child: SizedBox(
          width: rbW,
          height: total,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: 0, left: left0, child: avatar),
              Positioned(top: ring - rbH * .38, left: 0, child: ribbon),
              Positioned(top: 0, left: left0 - 3, child: badge),
              if (_n(v['hakem']) == s) Positioned(top: -d * .2, right: left0 - 2, child: Text('👑', style: TextStyle(fontSize: d * .4))),
              if (bubble != null) bubble,
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundBtn(IconData i, VoidCallback f, {Color? color, bool dot = false}) => GestureDetector(
        onTap: f,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? const Color(0x9e140a14),
                border: Border.all(color: Colors.white38, width: 1.5),
                boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(i, color: Colors.white, size: 21),
            ),
            if (dot) Positioned(top: -1, right: -1, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xffd9433b), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          ],
        ),
      );

  /// تابلوی نتیجه به سبک بازی فوتبال: امتیاز درشت هر تیم، شماره‌ی دست، و توپ‌های «دست‌های بردهشده» (۷ تایی).
  Widget _score(Map<String, dynamic> v) {
    final mt = _team(_seat);
    final sc = (v['scores'] as List).map(_n).toList();
    final tr = (v['tricks'] as List).map(_n).toList();
    Widget pips(int n, Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 7; i++)
              Container(
                width: 7.5,
                height: 7.5,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < n ? c : Colors.white12,
                  border: Border.all(color: i < n ? Colors.white : Colors.white24, width: 1),
                  boxShadow: i < n ? <BoxShadow>[BoxShadow(color: c.withOpacity(.85), blurRadius: 5)] : null,
                ),
              ),
          ],
        );
    Widget numW(int x) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: FadeTransition(opacity: a, child: c)),
          child: Text('$x', key: ValueKey<int>(x), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.05, shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))])),
        );
    Widget team(String name, int score, int tricks, List<Color> cols, Color pip) => Container(
          width: 76,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900)), const SizedBox(width: 6), numW(score)],
              ),
              const SizedBox(height: 3),
              pips(tricks, pip),
            ],
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xf00a1530),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe8bb55), width: 2),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.65), blurRadius: 12, offset: const Offset(0, 4)), const BoxShadow(color: Color(0x44e8bb55), blurRadius: 14)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            team('حریف', sc[1 - mt], tr[1 - mt], const <Color>[Color(0xffe0485a), Color(0xff9c1b2c)], const Color(0xffff6b78)),
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('دست', style: TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  Text('${_n(v['no'])}', style: const TextStyle(color: Color(0xffffd84a), fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                  Text('تا ${_n(v['target'])}', style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                ],
              ),
            ),
            team('ما', sc[mt], tr[mt], const <Color>[Color(0xff3b8cff), Color(0xff1550b8)], const Color(0xff7cc0ff)),
          ],
        ),
      ),
    );
  }

  Widget _trumpBox(Map<String, dynamic> v) {
    final kind = _n(v['kind']);
    final decided = v['decided'] == true;
    final trump = _n(v['trump']);
    const ts = TextStyle(color: Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 25, shadows: <Shadow>[Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2))]);
    Widget content;
    if (!decided) {
      content = const Text('حکم : …', textDirection: TextDirection.rtl, style: ts);
    } else if (kind == 0) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Text(v['seven'] == true ? 'حکم (۷ یار) : ' : 'حکم : ', style: ts),
          HokmSuit(trump, 46, (trump == 1 || trump == 2) ? const Color(0xffff4b4b) : Colors.white, shadow: true),
        ],
      );
    } else {
      content = Text('حکم : ${_kindName[kind]}', textDirection: TextDirection.rtl, style: ts);
    }
    return AnimatedScale(
      scale: _pulse ? 1.18 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xe61e0e06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xff27e6e6), width: 3),
          boxShadow: <BoxShadow>[const BoxShadow(color: Color(0x6627e6e6), blurRadius: 22), BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: content,
      ),
    );
  }

  Widget _info(Map<String, dynamic> v) {
    final pl = v['pl'] as List;
    final trick = v['trick'] as List;
    final choosing = _n(v['ph']) == 1;
    final spans = <InlineSpan>[];
    if (choosing) {
      spans.add(TextSpan(text: '${pl[_n(v['chooser'])]['n']} در حال حکم کردن…'));
    } else {
      if (trick.isNotEmpty) {
        final ls = _card((trick.first as List)[1]).suit;
        spans.add(const TextSpan(text: 'خال زمین '));
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(color: Colors.black54, padding: const EdgeInsets.symmetric(horizontal: 4), child: HokmSuit(ls, 17, (ls == 1 || ls == 2) ? const Color(0xffff6b6b) : Colors.white))));
        spans.add(const TextSpan(text: ' · '));
      }
      spans.add(TextSpan(text: 'بازی تا ${_n(v['target'])} امتیاز'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xcc000000), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
      child: Text.rich(TextSpan(style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700), children: spans), textDirection: TextDirection.rtl),
    );
  }

  Widget _chooser(Map<String, dynamic> v, double u) {
    final canPass = _seat == _n(v['hakem']);
    Widget suit(int s, String o) => GestureDetector(
          onTap: () {
            HokmSfx.play('click');
            _act(<String, dynamic>{'k': 'choose', 'o': o});
          },
          child: HokmSuit(s, 52, (s == 1 || s == 2) ? const Color(0xffe53030) : const Color(0xfff4f4f4), shadow: true),
        );
    Widget orb(String t, String o) => GestureDetector(
          onTap: () {
            HokmSfx.play('click');
            _act(<String, dynamic>{'k': 'choose', 'o': o});
          },
          child: Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xffff7b6d), Color(0xffb2140a)]),
              border: Border.all(color: const Color(0xffffd0c8), width: 3),
              boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ),
        );
    Widget lab(String t, {bool off = false}) => Text(t, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: off ? Colors.white30 : const Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 12.5, height: 1.3));
    Widget col(Widget a, Widget b, Widget c) => Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [a, const SizedBox(height: 6), b, const SizedBox(height: 6), c]));
    final pass = GestureDetector(
      onTap: canPass
          ? () {
              HokmSfx.play('click');
              _act(<String, dynamic>{'k': 'choose', 'o': 'pass'});
            }
          : null,
      child: Opacity(
        opacity: canPass ? 1 : .3,
        child: Container(width: 50, height: 50, alignment: Alignment.center, child: const Icon(Icons.style_rounded, color: Colors.white, size: 40)),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xf2281408),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff27e6e6), width: 3),
        boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10)), BoxShadow(color: Color(0x4427e6e6), blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('لطفا حکم کنید', style: TextStyle(color: Color(0xffffe24a), fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Container(height: 2, color: const Color(0xff27e6e6)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              col(suit(1, '1'), orb('A', 'tak'), lab('تک نرس')),
              col(suit(0, '0'), orb('N', 'nars'), lab('نرس')),
              col(suit(2, '2'), orb('S', 'sars'), lab('سرس')),
              col(suit(3, '3'), pass, lab('میان‌دست شریک', off: !canPass)),
            ],
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: canPass ? 1 : .35,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: HokmButton(
                title: '۷ یار',
                sub: 'حکم = خال ۷ شریک',
                onTap: canPass
                    ? () {
                        HokmSfx.play('click');
                        _act(<String, dynamic>{'k': 'choose', 'o': 'seven'});
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(canPass ? 'شما حاکم هستید؛ بعد از دیدن ۵ کارت اول، حکم را انتخاب کنید.' : 'حاکم انتخاب را به شما سپرد؛ حکم را شما تعیین کنید.', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.7)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: v == null
            ? const Stack(children: [HokmBackground(), Center(child: CircularProgressIndicator(color: Color(0xffe8bb55)))])
            : LayoutBuilder(builder: (ctx, box) => _table(v, box.maxWidth, box.maxHeight, MediaQuery.of(ctx).padding)),
      ),
    );
  }

  Widget _table(Map<String, dynamic> v, double W, double H, EdgeInsets pad) {
    final u = min(W / 100, H / 190);
    final seat = _seat;
    final ph = _n(v['ph']);
    final hand = (v['hand'] as List).map(_card).toList();
    final cnt = (v['cnt'] as List).map(_n).toList();
    final trick = v['trick'] as List;
    final myTurn = ph == 2 && _n(v['turn']) == seat;
    // خال حکم (فقط در حالت حکم؛ در نرس و سرس و تک‌نرس حکمی وجود ندارد)
    final trumpSuit = (_n(v['kind']) == 0 && v['decided'] == true) ? _n(v['trump']) : -1;
    final legalIds = <int>{};
    var ringColor = const Color(0xffffd84a);
    if (myTurn) {
      if (trick.isEmpty) {
        legalIds.addAll(hand.map((c) => c.id));
      } else {
        final ls = _card((trick.first as List)[1]).suit;
        final f = hand.where((c) => c.suit == ls).toList();
        legalIds.addAll((f.isNotEmpty ? f : hand).map((c) => c.id));
        if (f.isNotEmpty) ringColor = (ls == 1 || ls == 2) ? const Color(0xffff5252) : const Color(0xff6fd3ff);
      }
    }
    // --- دست من
    final cw = 19 * u, ch = cw * 1.4, R = 58 * u;
    final cardTop = H - 45 * u - pad.bottom;
    final myPivot = Offset(W / 2, cardTop + R + ch);
    final mine = _fan(
      n: hand.length,
      pivot: myPivot,
      base: 0,
      radius: R,
      cw: cw,
      maxDeg: 72,
      stepDeg: 6,
      lifted: (i) => legalIds.contains(hand[i].id),
      lift: 4.5 * u,
      card: (i) {
        final c = hand[i];
        final ok = legalIds.contains(c.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onCardTap(c, ok),
          child: HokmCardView(card: c, w: cw, ring: myTurn && ok ? ringColor : null, dim: myTurn && !ok, trump: c.suit == trumpSuit),
        );
      },
    );
    // --- دست‌های دیگران
    final ow = 10.5 * u, och = ow * 1.4, oR = 22 * u;
    final rightCards = _fan(n: cnt[(seat + 1) % 4], pivot: Offset(W - 16 * u + oR + och, H * .52), base: -pi / 2, radius: oR, cw: ow, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: ow));
    final leftCards = _fan(n: cnt[(seat + 3) % 4], pivot: Offset(16 * u - oR - och, H * .52), base: pi / 2, radius: oR, cw: ow, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: ow));
    final tw = 11 * u, tch = tw * 1.4;
    final topCards = _fan(n: cnt[(seat + 2) % 4], pivot: Offset(W / 2, pad.top + 36 * u - oR - tch), base: pi, radius: oR, cw: tw, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: tw));
    // --- میز
    final center = Offset(W / 2, H * .51);
    final trw = 17 * u, trh = trw * 1.4;
    final offs = <Offset>[Offset(0, 11 * u), Offset(13 * u, 0), Offset(0, -11 * u), Offset(-13 * u, 0)];
    final rots = <double>[-4, 6, 3, -7];
    final sweep = _n(v['sweep']);
    final trickW = <Widget>[];
    for (final e in trick) {
      final s = _n((e as List)[0]);
      final r = (s - seat + 4) % 4;
      var o = offs[r];
      if (sweep >= 0) {
        final sr = (sweep - seat + 4) % 4;
        o = <Offset>[Offset(0, 38 * u), Offset(42 * u, 0), Offset(0, -38 * u), Offset(-42 * u, 0)][sr];
      }
      trickW.add(AnimatedPositioned(
        key: ValueKey<int>(_n(e[1])),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeIn,
        left: center.dx + o.dx - trw / 2,
        top: center.dy + o.dy - trh / 2,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 380),
          opacity: sweep >= 0 ? 0 : 1,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (c, t, child) => Transform.scale(scale: .55 + .45 * t, child: Opacity(opacity: t.clamp(0.0, 1.0).toDouble(), child: child)),
            child: Transform.rotate(angle: rots[r] * pi / 180, child: HokmCardView(card: _card(e[1]), w: trw)),
          ),
        ),
      ));
    }
    Widget at(Widget w, {double? left, double? right, double? top, double? bottom}) => Positioned(left: left, right: right, top: top, bottom: bottom, child: w);
    Widget centered(Widget w, {double? top, double? bottom}) => Positioned(left: 0, right: 0, top: top, bottom: bottom, child: Center(child: w));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const HokmBackground(),
        ...topCards,
        ...rightCards,
        ...leftCards,
        centered(_tag((seat + 2) % 4, v, u, size: 16), top: pad.top + 22.5 * u),
        at(_tag((seat + 3) % 4, v, u, size: 13, side: 1), left: .75 * u, top: H * .52 - 11 * u),
        at(_tag((seat + 1) % 4, v, u, size: 13, side: 2), right: .75 * u, top: H * .52 - 11 * u),
        ...trickW,
        // پایین: دست من با کمی حالت سه‌بعدی
        Positioned.fill(
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0009)
              ..rotateX(0.17),
            child: Stack(clipBehavior: Clip.none, children: mine),
          ),
        ),
        centered(_tag(seat, v, u, size: 15, bubbleAbove: true), bottom: pad.bottom + 15.5 * u),
        // بالا
        at(const HokmLogo(size: 42), left: 10, top: pad.top + 6),
        Positioned(top: pad.top + 6, left: 60, right: 100, child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _score(v)))),
        at(Row(mainAxisSize: MainAxisSize.min, children: [_roundBtn(Icons.settings_rounded, () => showHokmSettings(context)), const SizedBox(width: 8), _roundBtn(Icons.power_settings_new_rounded, _exit)]), right: 8, top: pad.top + 4),
        centered(_trumpBox(v), top: pad.top + 44.5 * u),
        centered(_info(v), top: pad.top + 59 * u),
        // کنار
        at(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roundBtn(Icons.chat_bubble_rounded, () {
                HokmSfx.play('click');
                setState(() {
                  _chatOpen = true;
                  _unread = false;
                });
              }, dot: _unread),
              const SizedBox(height: 8),
              _roundBtn(Icons.skip_previous_rounded, () {
                HokmSfx.play('click');
                _showLast();
              }),
              const SizedBox(height: 8),
              _roundBtn(_pr.mute ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
                _pr.mute = !_pr.mute;
                _pr.save();
                HokmSfx.play('click');
              }, color: _pr.mute ? const Color(0x9e140a14) : const Color(0xff1a8f63)),
            ],
          ),
          right: 8,
          bottom: pad.bottom + 52 * u,
        ),
        if (_banner.isNotEmpty) Positioned(left: 0, right: 0, top: pad.top + 27 * u, child: Container(color: const Color(0xffd9433b), padding: const EdgeInsets.all(6), child: Text(_banner, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 12)))),
        if (ph == 1 && _n(v['chooser']) == seat) Positioned(left: W * .04, right: W * .04, top: H * .31, child: _chooser(v, u)),
        if (_hl.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: H * .37,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>('$_hl$_hlSub'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutBack,
                builder: (c, t, child) => Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(1.0, .4 + .6 * t, 1.0), child: Opacity(opacity: t.clamp(0.0, 1.0).toDouble(), child: child)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: <Color>[Colors.transparent, (_hlOurs ? const Color(0xff1550b8) : const Color(0xff9c1b2c)).withOpacity(.92), (_hlOurs ? const Color(0xff1550b8) : const Color(0xff9c1b2c)).withOpacity(.92), Colors.transparent], stops: const <double>[0, .18, .82, 1]),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_hlOurs ? '⚽  نتیجه‌ی دست  ⚽' : '🥅  نتیجه‌ی دست  🥅', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(_hl, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xffffe24a), fontSize: 40, fontWeight: FontWeight.w900, shadows: <Shadow>[Shadow(color: Color(0xff7a2a00), offset: Offset(0, 3)), Shadow(color: Color(0xffff9a00), blurRadius: 24)])),
                      Text(_hlSub, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, shadows: <Shadow>[Shadow(color: Colors.black, blurRadius: 6)])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_toast.isNotEmpty)
          Positioned(
            left: 20,
            right: 20,
            top: H * .33,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: Text(_toast, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ),
          ),
        if (_confetti > 0) Positioned.fill(child: IgnorePointer(child: _Confetti(key: ValueKey<int>(_confetti)))),
        if (_chatOpen) _chatPanel(H),
      ],
    );
  }

  Widget _chatPanel(double H) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: H * .62,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: const Color(0xff1a0d18),
          elevation: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    const Expanded(child: Text('گفتگو', style: TextStyle(color: Color(0xffe8bb55), fontWeight: FontWeight.w900, fontSize: 18))),
                    IconButton(onPressed: () => setState(() => _chatOpen = false), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: _chat.isEmpty
                    ? const Center(child: Text('پیامی نیست. یک جمله‌ی آماده بفرستید.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        itemCount: _chat.length,
                        itemBuilder: (_, i) {
                          final c = _chat[_chat.length - 1 - i];
                          return Align(
                            alignment: c.me ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              constraints: const BoxConstraints(maxWidth: 260),
                              decoration: BoxDecoration(color: c.me ? const Color(0x5517a673) : Colors.white12, borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c.me ? 'شما' : c.name, style: const TextStyle(color: Color(0xffe8bb55), fontSize: 11)),
                                  Text(c.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    for (final q in _quick)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ActionChip(label: Text(q), backgroundColor: Colors.white12, labelStyle: const TextStyle(color: Colors.white, fontSize: 12), onPressed: () => _sendChat(q)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 6, 10, 10 + MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatCtl,
                        maxLength: 60,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (t) {
                          _sendChat(t);
                          _chatCtl.clear();
                        },
                        decoration: InputDecoration(counterText: '', hintText: 'پیام…', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black38, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff17a673), foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                      onPressed: () {
                        _sendChat(_chatCtl.text);
                        _chatCtl.clear();
                      },
                      child: const Text('ارسال'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chat {
  _Chat(this.seat, this.name, this.text, this.me);
  final int seat;
  final String name;
  final String text;
  final bool me;
}

/// کاغذرنگی پایان بازی
class _Confetti extends StatefulWidget {
  const _Confetti({super.key});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..forward();
  final Random _r = Random();
  late final List<List<double>> _p = List<List<double>>.generate(110, (_) => <double>[_r.nextDouble(), _r.nextDouble() * .5, .15 + _r.nextDouble() * .25, 4 + _r.nextDouble() * 5, _r.nextDouble() * 6, _r.nextDouble()]);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cols = <Color>[Color(0xffe8bb55), Color(0xff27e6e6), Color(0xffff5a5a), Color(0xff7dff7d), Colors.white, Color(0xffb07ad6)];
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) => CustomPaint(painter: _ConfPainter(_c.value, _p, cols)),
    );
  }
}

class _ConfPainter extends CustomPainter {
  _ConfPainter(this.t, this.p, this.cols);
  final double t;
  final List<List<double>> p;
  final List<Color> cols;

  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < p.length; i++) {
      final e = p[i];
      final x = e[0] * s.width + sin(t * 8 + e[4]) * 14;
      final y = (-.1 * s.height) + (e[1] * s.height * -.3) + t * s.height * (1.15 + e[2]);
      c.save();
      c.translate(x, y);
      c.rotate(e[4] + t * 9);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: e[3], height: e[3] * .6), Paint()..color = cols[(e[5] * cols.length).floor() % cols.length].withOpacity((1 - t * .6).clamp(0.0, 1.0).toDouble()));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfPainter o) => o.t != t;
}
