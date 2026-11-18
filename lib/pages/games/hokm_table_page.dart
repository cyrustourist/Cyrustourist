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

  Widget _tag(int s, Map<String, dynamic> v, {bool vertical = false}) {
    final pl = (v['pl'] as List)[s] as Map;
    final turn = (_n(v['turn']) == s && _n(v['ph']) == 2) || (_n(v['ph']) == 1 && _n(v['chooser']) == s);
    final conn = pl['c'] != false;
    final partner = s == (_seat + 2) % 4;
    final avatar = HokmAvatar(avatar: '${pl['a']}', size: 34, border: turn ? const Color(0xff27e6e6) : Colors.white70);
    final name = Text('${pl['n']}${partner ? ' (شریک)' : ''}${conn ? '' : ' ⚠'}', maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 12));
    final crown = _n(v['hakem']) == s ? const Text('👑', style: TextStyle(fontSize: 16)) : const SizedBox.shrink();
    final body = Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: EdgeInsets.symmetric(horizontal: vertical ? 6 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xd11e0e06),
        borderRadius: BorderRadius.circular(vertical ? 16 : 26),
        border: Border.all(color: turn ? const Color(0xff27e6e6) : const Color(0xff7a5a30), width: 2),
        boxShadow: <BoxShadow>[
          if (turn) const BoxShadow(color: Color(0xff27e6e6), blurRadius: 16),
          BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: [avatar, const SizedBox(height: 2), name, crown])
          : Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.rtl, children: [avatar, const SizedBox(width: 6), Flexible(child: name), const SizedBox(width: 4), crown]),
    );
    final b = _bubbles[s];
    return Opacity(
      opacity: conn ? 1 : .55,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          body,
          if (b != null)
            Positioned(
              top: -34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black45, blurRadius: 8)]),
                child: Text(b, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
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

  Widget _score(Map<String, dynamic> v) {
    final mt = _team(_seat);
    final sc = (v['scores'] as List).map(_n).toList();
    Widget lab(String t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 9), child: Text(t, style: const TextStyle(color: Color(0xffffe9a8), fontSize: 12, fontWeight: FontWeight.w700)));
    Widget numBox(int x, Color c) => Container(width: 34, alignment: Alignment.center, color: c, child: Text('$x', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)));
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xdd0a1530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe8bb55), width: 2),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(mainAxisSize: MainAxisSize.min, textDirection: TextDirection.ltr, children: [lab('حریف'), numBox(sc[1 - mt], const Color(0xffd23a4a)), numBox(sc[mt], const Color(0xff1f6fe0)), lab('ما')]),
      ),
    );
  }

  Widget _trumpBox(Map<String, dynamic> v) {
    final kind = _n(v['kind']);
    final decided = v['decided'] == true;
    final trump = _n(v['trump']);
    Widget content;
    if (!decided) {
      content = const Text('حکم : …', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 18));
    } else if (kind == 0) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Text(v['seven'] == true ? 'حکم (۷ یار) : ' : 'حکم : ', style: TextStyle(color: Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 18)),
          Text(kSuitChar[trump], style: TextStyle(color: (trump == 1 || trump == 2) ? const Color(0xffff4b4b) : Colors.white, fontSize: 32, height: 1, shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 3)])),
        ],
      );
    } else {
      content = Text('حکم : ${_kindName[kind]}', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xffffd84a), fontWeight: FontWeight.w900, fontSize: 18));
    }
    return AnimatedScale(
      scale: _pulse ? 1.18 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xd11e0e06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff27e6e6), width: 2.5),
          boxShadow: <BoxShadow>[const BoxShadow(color: Color(0x5527e6e6), blurRadius: 18), BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: content,
      ),
    );
  }

  Widget _info(Map<String, dynamic> v) {
    final mt = _team(_seat);
    final tr = (v['tricks'] as List).map(_n).toList();
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
        spans.add(TextSpan(text: ' ${kSuitChar[ls]} ', style: TextStyle(color: (ls == 1 || ls == 2) ? const Color(0xffff6b6b) : Colors.white, fontSize: 17, fontWeight: FontWeight.w900, backgroundColor: Colors.black54)));
        spans.add(const TextSpan(text: ' · '));
      }
      spans.add(TextSpan(text: 'دست‌ها: ما ${tr[mt]} · حریف ${tr[1 - mt]} · تا ${_n(v['target'])} امتیاز'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
      child: Text.rich(TextSpan(style: const TextStyle(color: Colors.white, fontSize: 11), children: spans), textDirection: TextDirection.rtl),
    );
  }

  Widget _chooser(Map<String, dynamic> v, double u) {
    final canPass = _seat == _n(v['hakem']);
    Widget suit(int s, String o) => GestureDetector(
          onTap: () {
            HokmSfx.play('click');
            _act(<String, dynamic>{'k': 'choose', 'o': o});
          },
          child: Text(kSuitChar[s], style: TextStyle(fontSize: 56, height: 1, color: (s == 1 || s == 2) ? const Color(0xffe53030) : const Color(0xfff4f4f4), shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
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
          child: HokmCardView(card: c, w: cw, ring: myTurn && ok ? ringColor : null, dim: myTurn && !ok),
        );
      },
    );
    // --- دست‌های دیگران
    final ow = 10.5 * u, och = ow * 1.4, oR = 22 * u;
    final rightCards = _fan(n: cnt[(seat + 1) % 4], pivot: Offset(W - 16 * u + oR + och, H * .52), base: -pi / 2, radius: oR, cw: ow, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: ow));
    final leftCards = _fan(n: cnt[(seat + 3) % 4], pivot: Offset(16 * u - oR - och, H * .52), base: pi / 2, radius: oR, cw: ow, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: ow));
    final tw = 11 * u, tch = tw * 1.4;
    final topCards = _fan(n: cnt[(seat + 2) % 4], pivot: Offset(W / 2, pad.top + 24 * u - oR - tch), base: pi, radius: oR, cw: tw, maxDeg: 64, stepDeg: 5.5, card: (i) => HokmBackView(w: tw));
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
        centered(_tag((seat + 2) % 4, v), top: pad.top + 28 * u),
        at(_tag((seat + 3) % 4, v, vertical: true), left: 14 * u, top: H * .52 + 16 * u),
        at(_tag((seat + 1) % 4, v, vertical: true), right: 14 * u, top: H * .52 + 16 * u),
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
        centered(_tag(seat, v), bottom: pad.bottom + 48 * u),
        // بالا
        at(const HokmLogo(size: 42), left: 10, top: pad.top + 6),
        Positioned(top: pad.top + 6, left: 60, right: 100, child: Center(child: _score(v))),
        at(Row(mainAxisSize: MainAxisSize.min, children: [_roundBtn(Icons.settings_rounded, () => showHokmSettings(context)), const SizedBox(width: 8), _roundBtn(Icons.power_settings_new_rounded, _exit)]), right: 8, top: pad.top + 4),
        centered(_trumpBox(v), top: pad.top + 15 * u + 8),
        centered(_info(v), top: pad.top + 38.5 * u),
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
        if (ph == 1 && _n(v['chooser']) == seat) Positioned(left: W * .04, right: W * .04, top: H * .27, child: _chooser(v, u)),
        if (_hl.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: H * .36,
            child: IgnorePointer(
              child: Column(
                children: [
                  Text(_hl, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xffffe24a), fontSize: 42, fontWeight: FontWeight.w900, shadows: <Shadow>[Shadow(color: Color(0xff7a2a00), offset: Offset(0, 3)), Shadow(color: Color(0xffff9a00), blurRadius: 24)])),
                  Text(_hlSub, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, shadows: <Shadow>[Shadow(color: Colors.black, blurRadius: 6)])),
                ],
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
