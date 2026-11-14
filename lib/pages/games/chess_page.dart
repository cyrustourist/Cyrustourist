import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'chess_engine.dart';
import 'chess_extras.dart';
import 'dice_games.dart' show sharedResultCard;
import 'game_api.dart';
import 'game_engine.dart' show BotLevel;
import 'game_fx.dart';
import 'game_p2p.dart';
import 'game_play_page.dart' show NearbyGameLink;
import 'game_texts.dart';
import 'game_widgets.dart';

/// شطرنج کامل: با ربات (سه سطح)، دو نفره روی یک گوشی، دو گوشی نزدیک (بدون اینترنت) و آنلاین (اتصال مستقیم).
/// قوانین کامل (کیش و مات، پات، قلعه، آنپاسان، ارتقا، تکرار سه‌باره، ۵۰ حرکت، کمبود مهره)،
/// ساعت ۱۰ دقیقه‌ای، چت، پیشنهاد مساوی، تسلیم و بازی دوباره با جابه‌جایی رنگ.
/// در حالت دو گوشی هر دو طرف وضعیت کامل را دارند و فهرست حرکت‌ها را برای هم می‌فرستند؛ ورکر فقط جفت‌یابی و ثبت نتیجه است.

enum ChMode { bot, local, nearby, online }

const List<String> _chGlyph = <String>['', '\u265F\uFE0E', '\u265E\uFE0E', '\u265D\uFE0E', '\u265C\uFE0E', '\u265B\uFE0E', '\u265A\uFE0E'];
const List<int> _chValue = <int>[0, 1, 3, 3, 5, 9, 0];
const List<int> _chInitial = <int>[0, 8, 2, 2, 2, 1, 1];

const Map<String, Map<String, String>> _cx = {
  'check': {'fa': 'کیش!', 'en': 'Check!'},
  'think': {'fa': 'ربات فکر می‌کند…', 'en': 'Robot is thinking…'},
  'mate': {'fa': 'کیش و مات', 'en': 'Checkmate'},
  'stalemate': {'fa': 'پات (مساوی)', 'en': 'Stalemate'},
  'insuff': {'fa': 'مهرهٔ کافی برای مات نیست', 'en': 'Insufficient material'},
  'fifty': {'fa': 'قانون ۵۰ حرکت', 'en': '50-move rule'},
  'rep': {'fa': 'تکرار سه‌باره', 'en': 'Threefold repetition'},
  'resign': {'fa': 'تسلیم شد', 'en': 'Resigned'},
  'flag': {'fa': 'وقت تمام شد', 'en': 'Out of time'},
  'agree': {'fa': 'مساوی با توافق', 'en': 'Draw by agreement'},
  'lost': {'fa': 'ارتباط با حریف قطع شد', 'en': 'Connection to the opponent was lost'},
  'btn_resign': {'fa': 'تسلیم', 'en': 'Resign'},
  'btn_draw': {'fa': 'پیشنهاد مساوی', 'en': 'Offer draw'},
  'btn_flip': {'fa': 'چرخش صفحه', 'en': 'Flip board'},
  'draw_sent': {'fa': 'پیشنهاد مساوی فرستاده شد', 'en': 'Draw offer sent'},
  'draw_in': {'fa': 'حریف مساوی پیشنهاد می‌کند', 'en': 'Your opponent offers a draw'},
  'accept': {'fa': 'قبول', 'en': 'Accept'},
  'decline': {'fa': 'رد', 'en': 'Decline'},
  'draw_no': {'fa': 'حریف مساوی را رد کرد', 'en': 'Draw offer declined'},
  'sure': {'fa': 'مطمئنید تسلیم شوید؟', 'en': 'Resign this game?'},
  'yes': {'fa': 'بله', 'en': 'Yes'},
  'no': {'fa': 'خیر', 'en': 'No'},
  'promo': {'fa': 'ارتقای پیاده به…', 'en': 'Promote pawn to…'},
  'white': {'fa': 'سفید', 'en': 'White'},
  'black': {'fa': 'سیاه', 'en': 'Black'},
  'host': {'fa': 'ساخت بازی (میزبان)', 'en': 'Host a game'},
  'join': {'fa': 'پیوستن به بازی', 'en': 'Join a game'},
  'join_short': {'fa': 'پیوستن', 'en': 'Join'},
  'wait_join': {'fa': 'منتظر پیوستن حریف…\nحریف باید «پیوستن به بازی» را بزند.\n(میزبان سفید بازی می‌کند)', 'en': 'Waiting for an opponent…\nThey must tap “Join a game”.\n(The host plays White)'},
  'wait_host': {'fa': 'پیوستید. منتظر شروع بازی…', 'en': 'Joined. Waiting for the game to start…'},
  'none': {'fa': 'بازی‌ای در اطراف پیدا نشد.\nمیزبان باید «ساخت بازی» را بزند و کنار هم باشید.', 'en': 'No game nearby.\nThe host must tap “Host a game” and you must be close.'},
  'note': {'fa': 'بدون اینترنت. هر دو گوشی باید شبکهٔ آفلاین را روشن کنند و نزدیک هم باشند.', 'en': 'No internet needed. Both phones must turn on the offline network and stay close.'},
  'fail': {'fa': 'اتصال مستقیم برقرار نشد. دوباره تلاش کنید.', 'en': 'Could not connect directly. Please try again.'},
  'retry': {'fa': 'تلاش دوباره', 'en': 'Try again'},
  'rule': {
    'fa': 'زمان هر بازیکن را از دکمهٔ ساعت بالای صفحه تنظیم کنید. برای حرکت، مهره را لمس کنید و بعد مقصد را. مات‌کردن شاه حریف = برد.',
    'en': 'Set each player\'s time with the clock button above. Tap a piece, then its destination. Checkmate the opposing king to win.'
  },
  'time': {'fa': 'زمان هر بازیکن', 'en': 'Time per player'},
  'noclock': {'fa': 'بدون ساعت', 'en': 'No clock'},
  'min': {'fa': 'دقیقه', 'en': 'min'},
  'time_locked': {'fa': 'زمان فقط قبل از شروع بازی (و توسط میزبان) قابل تغییر است', 'en': 'Time can only be changed before the game starts (by the host)'},
  'chat': {'fa': 'گفتگو با حریف', 'en': 'Chat with opponent'},
  'chat_hint': {'fa': 'پیام برای حریف…', 'en': 'Message…'},
  'rating': {'fa': 'امتیاز', 'en': 'Rating'},
  'score_now': {'fa': 'نتیجهٔ این نشست', 'en': 'Session score'},
  'btn_style': {'fa': 'مدل مهره و صفحه', 'en': 'Pieces & board'},
  'btn_stats': {'fa': 'آمار و امتیاز', 'en': 'Stats & rating'},
};

String _ct(String key) {
  final m = _cx[key];
  if (m == null) return key;
  return m[GameT.fa ? 'fa' : 'en'] ?? m['en'] ?? key;
}

/// اجرای ربات در Isolate تا صفحه قفل نشود
Future<String?> _runBot(List<String> list, int level, int seed) => Isolate.run(() => chessBotPick(list, level, seed));

class _ChRoom {
  _ChRoom(this.code, this.hostUid, this.hostName, this.ts);
  final String code;
  final String hostUid;
  final String hostName;
  int ts;
}

class ChessPage extends StatefulWidget {
  const ChessPage({super.key, required this.mode, this.level = BotLevel.normal});
  final ChMode mode;
  final BotLevel level;

  @override
  State<ChessPage> createState() => _ChessPageState();
}

class _ChessPageState extends State<ChessPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  final ScrollController _mvCtl = ScrollController();

  ChMode get mode => widget.mode;

  ChessPos pos = ChessPos.start();
  List<String> mvs = <String>[];
  List<String> sans = <String>[];
  List<String> keys = <String>[];
  List<CMove> legal = <CMove>[];
  int? sel;
  int lastFrom = -1;
  int lastTo = -1;
  int winner = -1; // ۰ سفید، ۱ سیاه، ۲ مساوی
  String endKey = '';
  String stage = 'play'; // play | menu | host | join | search | connect
  bool started = false;
  bool thinking = false;
  bool lost = false;
  int myIdx = 0; // ۰ = سفید، ۱ = سیاه
  bool isHost = true;
  bool flipLocal = false;
  List<String> pnames = <String>['', ''];
  int gained = 0;
  bool reported = false;
  bool resultReady = false;
  int _gen = 0;
  int _lastRecv = 0;
  int gameNo = 0; // شمارندهٔ بازی (برای نادیده‌گرفتن پیام‌های بازی قبلی بعد از «بازی دوباره»)

  // شبکه
  String code = '';
  String peerUid = '';
  bool _starting = false;
  bool _gotAny = false;
  Timer? _tick;
  Timer? _clock;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final Map<String, _ChRoom> rooms = <String, _ChRoom>{};
  String roomId = '';
  int myMark = 1;
  int version = 0;
  String onlineErr = '';
  GameP2p? _p2p;
  Timer? _poll;
  Timer? _p2pTimeout;
  bool _polling = false;
  bool _onlineDone = false;

  // چت، ساعت، مساوی، بازی دوباره
  bool chatOn = true;
  final List<ChatLine> chat = <ChatLine>[];
  int _lastChatMs = 0;
  List<int> clk = <int>[600000, 600000];
  int tcMin = 10; // دقیقهٔ هر بازیکن (۰ = بدون ساعت)
  final List<bool> _warned = <bool>[false, false];
  final ValueNotifier<int> _chatTick = ValueNotifier<int>(0);
  final TextEditingController _chatCtl = TextEditingController();
  bool _chatOpen = false;
  int unread = 0;
  String _bubble = '';
  bool _bubbleMine = false;
  Timer? _bubbleTimer;
  int sesMine = 0;
  int sesTheirs = 0;
  int sesDraws = 0;
  int ratingDelta = 0;
  bool _ready = false;
  int clkAt = 0;
  bool rmMine = false;
  bool rmPeer = false;
  bool drawSent = false;
  bool drawIn = false;

  bool get _isNet => mode == ChMode.nearby || mode == ChMode.online;
  int get _tcMs => tcMin * 60 * 1000;
  bool get _timed => tcMin > 0;
  int get _meIdx => mode == ChMode.bot || mode == ChMode.local ? 0 : myIdx;
  int get _turnIdx => pos.white ? 0 : 1;
  bool get _flip => mode == ChMode.local ? flipLocal : (mode == ChMode.bot ? false : myIdx == 1);
  bool get _canAct {
    if (!started || winner >= 0 || lost || thinking || stage != 'play') return false;
    switch (mode) {
      case ChMode.local:
        return true;
      case ChMode.bot:
        return pos.white;
      default:
        return _turnIdx == myIdx;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.wait<void>(<Future<void>>[GameFx.load(), ChessPrefs.load(), ChessStats.load()]).then((_) {
      if (!mounted) return;
      tcMin = mode == ChMode.online ? 10 : ChessPrefs.minutes;
      _ready = true;
      if (started && mvs.isEmpty && winner < 0) _applyTc();
      setState(() {});
      if (mode == ChMode.bot || mode == ChMode.local) ChessAlarm.start();
    });
    switch (mode) {
      case ChMode.bot:
        pnames = <String>[GameT.t('you'), GameT.t('robot')];
        _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
        _newGame();
        break;
      case ChMode.local:
        pnames = <String>[GameT.t('player1'), GameT.t('player2')];
        _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
        _newGame();
        break;
      case ChMode.nearby:
        stage = 'menu';
        _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
        NearbyGameLink.instance.attach();
        _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
        _mesh.addListener(_onMesh);
        _tick = Timer.periodic(const Duration(seconds: 2), (_) => _onTick());
        break;
      case ChMode.online:
        stage = 'search';
        _clock = Timer.periodic(const Duration(seconds: 1), (_) => _clockTick());
        _tick = Timer.periodic(const Duration(seconds: 3), (_) => _onTick());
        WidgetsBinding.instance.addPostFrameCallback((_) => _startOnline());
        break;
    }
  }

  @override
  void dispose() {
    _gen++;
    _clock?.cancel();
    _tick?.cancel();
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _sub?.cancel();
    _mvCtl.dispose();
    _chatCtl.dispose();
    _chatTick.dispose();
    _bubbleTimer?.cancel();
    if (mode == ChMode.nearby) {
      _mesh.removeListener(_onMesh);
      NearbyGameLink.instance.detach();
    }
    _p2p?.close();
    if (mode == ChMode.online && roomId.isNotEmpty && !reported) {
      GameApi.post('/api/game/resign', <String, dynamic>{'room_id': roomId});
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- منطق بازی

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void _newGame() {
    _gen++;
    gameNo++;
    pos = ChessPos.start();
    mvs = <String>[];
    sans = <String>[];
    keys = <String>[pos.key];
    legal = chLegal(pos);
    sel = null;
    lastFrom = -1;
    lastTo = -1;
    winner = -1;
    endKey = '';
    started = true;
    thinking = false;
    lost = false;
    reported = false;
    resultReady = false;
    gained = 0;
    rmMine = false;
    rmPeer = false;
    drawSent = false;
    drawIn = false;
    clk = <int>[_tcMs, _tcMs];
    _warned[0] = false;
    _warned[1] = false;
    ratingDelta = 0;
    clkAt = _now();
    _lastRecv = _now();
    if (mounted) setState(() {});
    if (_ready) ChessAlarm.start();
  }

  /// تغییر زمان قبل از اولین حرکت: ساعت‌ها از نو تنظیم می‌شوند.
  void _applyTc() {
    clk = <int>[_tcMs, _tcMs];
    _warned[0] = false;
    _warned[1] = false;
    clkAt = _now();
  }

  int _remaining(int idx) {
    if (!_timed) return 1 << 30;
    final running = started && winner < 0 && idx == _turnIdx;
    final v = clk[idx] - (running ? _now() - clkAt : 0);
    return v < 0 ? 0 : v;
  }

  void _scrollMoves() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mvCtl.hasClients) _mvCtl.jumpTo(_mvCtl.position.maxScrollExtent);
    });
  }

  void _playMove(CMove m, {bool fromPeer = false}) {
    final san = chSan(pos, m, legal);
    final capture = pos.b[m.to] != 0 || m.ep;
    if (_timed && !fromPeer) clk[_turnIdx] = _remaining(_turnIdx);
    pos = chApply(pos, m);
    mvs.add(m.uci);
    sans.add(san);
    keys.add(pos.key);
    lastFrom = m.from;
    lastTo = m.to;
    sel = null;
    clkAt = _now();
    drawIn = false;
    if (capture) {
      GameFx.hit();
    } else {
      GameFx.move();
    }
    _checkEnd();
    if (_isNet && !fromPeer) _sendMv();
    setState(() {});
    _scrollMoves();
    if (mode == ChMode.bot && winner < 0 && !pos.white) _botMove();
  }

  void _checkEnd() {
    if (winner >= 0) return;
    legal = chLegal(pos);
    var w = -1;
    var k = '';
    if (legal.isEmpty) {
      if (chInCheck(pos)) {
        w = pos.white ? 1 : 0;
        k = 'mate';
      } else {
        w = 2;
        k = 'stalemate';
      }
    } else if (chInsufficient(pos)) {
      w = 2;
      k = 'insuff';
    } else if (pos.half >= 100) {
      w = 2;
      k = 'fifty';
    } else if (keys.where((x) => x == pos.key).length >= 3) {
      w = 2;
      k = 'rep';
    }
    if (w >= 0) _setEnd(w, k);
  }

  void _setEnd(int w, String k) {
    if (winner >= 0) return;
    winner = w;
    endKey = k;
    if (w == 2) {
      sesDraws++;
    } else if (w == _meIdx) {
      sesMine++;
    } else {
      sesTheirs++;
    }
    sel = null;
    thinking = false;
    _gen++;
    if (mounted) setState(() {});
    GameFx.win();
    ChessAlarm.end();
    _finish();
  }

  Future<void> _botMove() async {
    if (thinking || winner >= 0) return;
    final gen = _gen;
    thinking = true;
    setState(() {});
    final list = List<String>.of(mvs);
    final lvl = widget.level == BotLevel.easy ? 0 : (widget.level == BotLevel.normal ? 1 : 2);
    final t0 = _now();
    String? u;
    try {
      u = await _runBot(list, lvl, _rnd.nextInt(1 << 30));
    } catch (_) {
      u = chessBotPick(list, lvl, _rnd.nextInt(1 << 30));
    }
    final wait = 500 - (_now() - t0);
    if (wait > 0) await Future<void>.delayed(Duration(milliseconds: wait));
    if (!mounted || gen != _gen) return;
    thinking = false;
    final m = u == null ? null : chFind(pos, u);
    if (m == null) {
      setState(() {});
      return;
    }
    _playMove(m);
  }

  Future<int?> _askPromo() {
    final white = pos.white;
    return showDialog<int>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          title: Text(_ct('promo'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
          content: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              for (final pc in const <int>[kQueen, kRook, kBishop, kKnight])
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(pc),
                  child: Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: ChessPrefs.style.dark, borderRadius: BorderRadius.circular(12), border: Border.all(color: gGold)),
                    child: chessPiece(pc, white, ChessPrefs.style, 46),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tap(int idx) async {
    if (!_canAct) return;
    final p = pos.b[idx];
    final own = pos.white ? p > 0 : p < 0;
    final s0 = sel;
    if (s0 != null) {
      final cand = legal.where((m) => m.from == s0 && m.to == idx).toList();
      if (cand.isNotEmpty) {
        var m = cand.first;
        if (cand.length > 1) {
          final pc = await _askPromo();
          if (pc == null || !mounted) return;
          m = cand.firstWhere((x) => x.promo == pc, orElse: () => cand.first);
        }
        if (!_canAct) return;
        _playMove(m);
        return;
      }
    }
    setState(() => sel = (own && sel != idx && legal.any((m) => m.from == idx)) ? idx : null);
  }

  // ---------------------------------------------------------------- پایان و سکه

  Future<void> _finish() async {
    if (reported) return;
    reported = true;
    final res = winner == 2 ? 'draw' : (winner == (mode == ChMode.bot ? 0 : myIdx) ? 'win' : 'loss');
    final modeKey = mode == ChMode.bot ? 'bot_${widget.level.name}' : mode.name;
    final oppName = (mode == ChMode.nearby || mode == ChMode.online) ? pnames[1 - myIdx] : '';
    final d = await ChessStats.record(mode: modeKey, opp: oppName, result: res, moves: mvs.length);
    if (mounted) setState(() => ratingDelta = d);
    if (mode == ChMode.online) {
      if (_onlineDone) {
        if (mounted) setState(() => resultReady = true);
        return;
      }
      _onlineDone = true;
      await _reportOnline(res);
      return;
    }
    final String result;
    final String level;
    switch (mode) {
      case ChMode.bot:
        result = res;
        level = widget.level.name;
        break;
      case ChMode.local:
        result = 'win';
        level = 'local';
        break;
      default:
        result = res;
        level = 'nearby';
    }
    final g = await _w.reportOffline(result, level);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  Future<void> _reportOnline(String result) async {
    for (var i = 0; i < 4; i++) {
      final j = await GameApi.post('/api/game/p2p_result', <String, dynamic>{'room_id': roomId, 'result': result});
      if (!mounted) return;
      if (j != null) {
        _w.applyWallet(j['wallet']);
        final settled = j['settled'] == true;
        setState(() {
          gained = settled ? ((j['gained'] as num?)?.toInt() ?? 0) : 0;
          resultReady = true;
        });
        if (settled || j['success'] != true) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
    }
    if (mounted) setState(() => resultReady = true);
  }

  // ---------------------------------------------------------------- پیام‌های شبکه

  void _sendNet(Map<String, dynamic> m) {
    if (mode == ChMode.nearby) {
      NearbyGameLink.instance.send(<String, dynamic>{...m, 'to': peerUid, 'code': code});
    } else if (mode == ChMode.online) {
      _p2p?.send(m);
    }
  }

  void _sendMv() {
    _sendNet(<String, dynamic>{'g': 'ch_mv', 'gn': gameNo, 'mvs': mvs.join(' '), 'c0': clk[0], 'c1': clk[1]});
  }

  void _sendEnd(int w, String r) {
    _sendNet(<String, dynamic>{'g': 'ch_end', 'gn': gameNo, 'w': w, 'r': r});
  }

  void _sendStart() {
    _sendNet(<String, dynamic>{'g': 'ch_st', 'names': pnames, 'tc': tcMin});
  }

  /// بازسازی کامل از فهرست حرکت‌ها (پیام حریف)
  bool _rebuild(List<String> list) {
    var p = ChessPos.start();
    final ks = <String>[p.key];
    final ss = <String>[];
    var lf = -1;
    var lt = -1;
    for (final u in list) {
      final m = chFind(p, u);
      if (m == null) return false;
      ss.add(chSan(p, m, chLegal(p)));
      p = chApply(p, m);
      ks.add(p.key);
      lf = m.from;
      lt = m.to;
    }
    pos = p;
    mvs = List<String>.of(list);
    sans = ss;
    keys = ks;
    lastFrom = lf;
    lastTo = lt;
    sel = null;
    legal = chLegal(pos);
    return true;
  }

  void _adopt(Map<String, dynamic> m) {
    final s = '${m['mvs']}'.trim();
    final list = s.isEmpty ? <String>[] : s.split(' ');
    if (list.length <= mvs.length || winner >= 0) return;
    final cap = list.isNotEmpty && pos.b[chParseSq(list.last.substring(2, 4))] != 0;
    if (!_rebuild(list)) return;
    clk = <int>[(m['c0'] as num?)?.toInt() ?? clk[0], (m['c1'] as num?)?.toInt() ?? clk[1]];
    clkAt = _now();
    drawIn = false;
    if (cap) {
      GameFx.hit();
    } else {
      GameFx.move();
    }
    _checkEnd();
    setState(() {});
    _scrollMoves();
  }

  void _onGameMsg(Map<String, dynamic> m) {
    _lastRecv = _now();
    if (lost) setState(() => lost = false);
    switch ('${m['g']}') {
      case 'ch_st':
        if (!isHost) {
          final nm = m['names'];
          if (nm is List && nm.length == 2) pnames = <String>['${nm[0]}', '${nm[1]}'];
          final first = !started;
          final tc = (m['tc'] as num?)?.toInt();
          if (tc != null && tc >= 0 && tc <= 60) tcMin = tc;
          stage = 'play';
          if (first) {
            _newGame();
            _sendMv();
          }
        }
        break;
      case 'ch_mv':
        if ((m['gn'] as num?)?.toInt() != gameNo) break;
        _gotAny = true;
        if (started) _adopt(m);
        break;
      case 'ch_end':
        {
          if ((m['gn'] as num?)?.toInt() != gameNo) break;
          final w = (m['w'] as num?)?.toInt() ?? -1;
          if (w >= 0 && w <= 2 && started) _setEnd(w, '${m['r']}');
        }
        break;
      case 'ch_dr':
        if (winner < 0) setState(() => drawIn = true);
        break;
      case 'ch_da':
        if (winner < 0 && drawSent) _setEnd(2, 'agree');
        break;
      case 'ch_dn':
        setState(() => drawSent = false);
        if (mounted) gToast(context, _ct('draw_no'));
        break;
      case 'ch_chat':
        {
          final txt = '${m['t']}';
          if (chatOn && txt.isNotEmpty && txt.length <= 80) {
            setState(() {
              chat.add(ChatLine(pnames[1 - myIdx], txt, false));
              if (chat.length > 30) chat.removeAt(0);
              if (!_chatOpen) unread++;
            });
            _chatTick.value++;
            _showBubble(txt, false);
            GameFx.move();
          }
        }
        break;
      case 'ch_rm':
        rmPeer = true;
        if (rmMine && winner >= 0) {
          _swapAndNew();
        } else {
          setState(() {});
        }
        break;
    }
  }

  // ---------------------------------------------------------------- گوشی‌های نزدیک

  void _onMesh() {
    if (mounted) setState(() {});
  }

  void _onTick() {
    if (!mounted) return;
    final now = _now();
    if (mode == ChMode.nearby) {
      if (!_mesh.running) return;
      if (stage == 'host') {
        NearbyGameLink.instance.send(<String, dynamic>{'g': 'ch_open', 'code': code});
        return;
      }
      if (stage == 'join') {
        rooms.removeWhere((k, v) => now - v.ts > 7000);
        if (code.isNotEmpty && !started) {
          NearbyGameLink.instance.send(<String, dynamic>{'g': 'ch_join', 'to': peerUid, 'code': code});
        }
        setState(() {});
        return;
      }
    }
    if (stage == 'play' && started && _isNet) {
      if (isHost && !_gotAny) {
        _sendStart();
      } else {
        _sendMv();
      }
      if (!lost && winner < 0 && now - _lastRecv > 25000) setState(() => lost = true);
    }
  }

  void _onEvent(Map<String, dynamic> m) {
    if (!mounted) return;
    final g = '${m['g']}';
    if (!g.startsWith('ch_')) return;
    final from = '${m['u']}';
    final toMe = '${m['to']}' == _mesh.myUid;
    switch (g) {
      case 'ch_open':
        if (stage == 'join') {
          final c = '${m['code']}';
          setState(() => rooms[c] = _ChRoom(c, from, '${m['n']}', _now()));
        }
        break;
      case 'ch_join':
        if (stage == 'host' && toMe && '${m['code']}' == code) {
          peerUid = from;
          pnames = <String>[_mesh.myName, '${m['n']}'];
          stage = 'play';
          _gotAny = false;
          _newGame();
          _sendStart();
        }
        break;
      default:
        if (toMe && '${m['code']}' == code && from == peerUid && stage != 'menu') _onGameMsg(m);
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

  void _createNearby() {
    if (!_mesh.running) return;
    code = '${1000 + _rnd.nextInt(9000)}';
    isHost = true;
    myIdx = 0;
    started = false;
    setState(() => stage = 'host');
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'ch_open', 'code': code});
  }

  void _openJoin() {
    isHost = false;
    myIdx = 1;
    started = false;
    code = '';
    setState(() => stage = 'join');
  }

  void _joinRoom(_ChRoom r) {
    setState(() {
      code = r.code;
      peerUid = r.hostUid;
    });
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'ch_join', 'to': peerUid, 'code': code});
  }

  // ---------------------------------------------------------------- آنلاین

  void _failOnline(String msg) {
    if (!mounted) return;
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _p2p?.close();
    _p2p = null;
    setState(() {
      onlineErr = msg;
      stage = 'search';
    });
  }

  Future<void> _startOnline() async {
    _poll?.cancel();
    _p2pTimeout?.cancel();
    _p2p?.close();
    _p2p = null;
    started = false;
    roomId = '';
    setState(() {
      stage = 'search';
      onlineErr = '';
    });
    final j = await GameApi.post('/api/game/quick', <String, dynamic>{'game': 'chess'});
    if (!mounted) return;
    if (j == null) {
      _failOnline(GameT.t('net_err'));
      return;
    }
    if (j['success'] != true || j['room'] is! Map) {
      final e = j['error'];
      _failOnline(e == 'not_registered' || e == 'no_name' || e == 'auth_required'
          ? GameT.t('need_profile')
          : (e == 'disabled' ? '${j['message'] ?? GameT.t('disabled')}' : GameT.t('net_err')));
      return;
    }
    _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
    if (stage != 'connect') {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollTick());
    }
  }

  void _applyRoom(Map<String, dynamic> r) {
    roomId = '${r['id']}';
    myMark = (r['my_mark'] as num?)?.toInt() ?? 1;
    version = (r['version'] as num?)?.toInt() ?? 0;
    myIdx = myMark - 1;
    isHost = myMark == 1;
    final host = r['host'] is Map ? '${(r['host'] as Map)['name']}' : '';
    final guest = r['guest'] is Map ? '${(r['guest'] as Map)['name']}' : '';
    pnames = <String>[host, guest];
    final st = '${r['status']}';
    if (st == 'playing' && stage != 'connect' && stage != 'play') _connectP2p();
  }

  Future<void> _pollTick() async {
    if (!mounted || _polling || roomId.isEmpty || stage != 'search') return;
    _polling = true;
    try {
      final j = await GameApi.get('/api/game/state', <String, String>{'room_id': roomId, 'since': '$version'});
      if (!mounted || j == null) return;
      if (j['success'] != true) {
        if (j['error'] == 'room_gone') _failOnline(GameT.t('net_err'));
        return;
      }
      if (j['changed'] == true && j['room'] is Map) {
        _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
        if (stage == 'connect') _poll?.cancel();
      }
    } finally {
      _polling = false;
    }
  }

  void _connectP2p() {
    setState(() => stage = 'connect');
    _poll?.cancel();
    final p = GameP2p(
      roomId: roomId,
      isHost: myMark == 1,
      onConfirmed: _onP2pOk,
      onMessage: (m) {
        if (mounted && '${m['g']}'.startsWith('ch_')) _onGameMsg(m);
      },
      onClosed: () {
        if (mounted && stage == 'play' && winner < 0) setState(() => lost = true);
      },
    );
    _p2p = p;
    p.start();
    _p2pTimeout?.cancel();
    _p2pTimeout = Timer(const Duration(seconds: 25), () {
      if (stage == 'connect') _failOnline(_ct('fail'));
    });
  }

  void _onP2pOk() {
    if (!mounted || stage == 'play') return;
    _p2pTimeout?.cancel();
    stage = 'play';
    _gotAny = false;
    if (isHost) {
      _newGame();
      _sendStart();
    } else {
      started = false;
      setState(() {});
    }
  }

  // ---------------------------------------------------------------- ساعت، چت، مساوی، تسلیم، بازی دوباره

  void _clockTick() {
    if (!mounted || stage != 'play' || !started) return;
    if (winner < 0 && _timed) {
      final t = _turnIdx;
      final rem = _remaining(t);
      if (rem > 0 && rem <= 30000 && !_warned[t] && (mode == ChMode.local || t == _meIdx)) {
        _warned[t] = true;
        ChessAlarm.warn();
      }
      if (rem <= 0) {
        if (!_isNet) {
          _setEnd(1 - t, 'flag');
          return;
        }
        if (t == myIdx) {
          _sendEnd(1 - myIdx, 'flag');
          _setEnd(1 - myIdx, 'flag');
          return;
        } else if (_now() - clkAt - clk[t] > 8000) {
          _sendEnd(myIdx, 'flag');
          _setEnd(myIdx, 'flag');
          return;
        }
      }
    }
    setState(() {});
  }

  void _sendChat(String raw) {
    final t = raw.trim();
    final now = _now();
    if (!chatOn || t.isEmpty || t.length > 60 || now - _lastChatMs < 1000) return;
    _lastChatMs = now;
    _sendNet(<String, dynamic>{'g': 'ch_chat', 't': t});
    setState(() {
      chat.add(ChatLine(pnames[myIdx], t, true));
      if (chat.length > 30) chat.removeAt(0);
    });
    _chatTick.value++;
    _showBubble(t, true);
  }

  void _showBubble(String t, bool mine) {
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = t;
      _bubbleMine = mine;
    });
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bubble = '');
    });
  }

  List<String> _phrases() => GameT.fa
      ? <String>['سلام 👋', 'موفق باشی 🍀', 'آفرین 👏', 'حرکت خوبی بود 👍', 'اوه نه! 😅', 'زود باش ⏳', 'کمی فکر کن 🤔', 'کیش! ♚', 'مراقب باش 😎', 'یک لحظه صبر کن', 'مساوی؟ 🤝', 'بازی دوباره؟ 🔁', 'تبریک 🎉', 'بازی خوبی بود']
      : <String>['Hello 👋', 'Good luck 🍀', 'Well played 👏', 'Nice move 👍', 'Oh no! 😅', 'Hurry up ⏳', 'Think a bit 🤔', 'Check! ♚', 'Careful 😎', 'One moment', 'Draw? 🤝', 'Rematch? 🔁', 'Congrats 🎉', 'Good game'];

  Future<void> _openChat() async {
    setState(() {
      _chatOpen = true;
      unread = 0;
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _chatTick,
              builder: (_, __) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_ct('chat'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: ListView(
                        reverse: true,
                        shrinkWrap: true,
                        children: [
                          for (final m in chat.reversed)
                            Align(
                              alignment: m.mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(color: m.mine ? const Color(0xff1b4d57) : gBg, borderRadius: BorderRadius.circular(13)),
                                child: Text(m.mine ? m.text : '${m.name}: ${m.text}', style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        for (final p in _phrases())
                          ActionChip(
                            backgroundColor: gBg,
                            side: const BorderSide(color: gLine),
                            label: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                            onPressed: () => _sendChat(p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatCtl,
                            maxLength: 60,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (v) {
                              _sendChat(v);
                              _chatCtl.clear();
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              filled: true,
                              fillColor: gBg,
                              hintText: _ct('chat_hint'),
                              hintStyle: const TextStyle(color: gMuted, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gLine)),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _sendChat(_chatCtl.text);
                            _chatCtl.clear();
                          },
                          icon: const Icon(Icons.send_rounded, color: gGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _chatOpen = false);
  }

  /// ردیف عبارت‌های آماده زیر صفحه (همیشه دیده می‌شود)
  Widget _quickChat() {
    final ph = _phrases();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            InkWell(
              onTap: _openChat,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: gGold, shape: BoxShape.circle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, color: gBg, size: 20),
                    if (unread > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xffe53935), borderRadius: BorderRadius.circular(9)),
                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in ph)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ActionChip(
                        backgroundColor: gPanel,
                        side: const BorderSide(color: gLine),
                        visualDensity: VisualDensity.compact,
                        label: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                        onPressed: () => _sendChat(p),
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

  void _offerDraw() {
    if (!_isNet || winner >= 0 || drawSent) return;
    setState(() => drawSent = true);
    _sendNet(<String, dynamic>{'g': 'ch_dr'});
    gToast(context, _ct('draw_sent'));
  }

  void _answerDraw(bool ok) {
    setState(() => drawIn = false);
    if (ok) {
      _sendNet(<String, dynamic>{'g': 'ch_da'});
      drawSent = true;
      _setEnd(2, 'agree');
    } else {
      _sendNet(<String, dynamic>{'g': 'ch_dn'});
    }
  }

  Future<void> _resign() async {
    if (winner >= 0 || mode == ChMode.local) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          content: Text(_ct('sure'), style: const TextStyle(color: Colors.white, height: 1.8)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_ct('no'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_ct('yes'), style: const TextStyle(color: gGold))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted || winner >= 0) return;
    final me = mode == ChMode.bot ? 0 : myIdx;
    if (_isNet) _sendEnd(1 - me, 'resign');
    _setEnd(1 - me, 'resign');
  }

  bool get _canPickTime {
    if (mode == ChMode.online) return false;
    if (mode == ChMode.nearby) return stage == 'menu' || stage == 'host';
    return winner >= 0 || mvs.isEmpty;
  }

  Future<void> _pickTime() async {
    if (!_canPickTime) {
      gToast(context, _ct('time_locked'));
      return;
    }
    final m = await showChessTimeSheet(context, current: tcMin);
    if (m == null || !mounted) return;
    await ChessPrefs.setMinutes(m);
    setState(() {
      tcMin = m;
      if (started && mvs.isEmpty && winner < 0) _applyTc();
    });
  }

  void _swapAndNew() {
    myIdx = 1 - myIdx;
    pnames = <String>[pnames[1], pnames[0]];
    _newGame();
  }

  void _rematch() {
    if (!_isNet) {
      _newGame();
      return;
    }
    if (rmMine) return;
    rmMine = true;
    _sendNet(<String, dynamic>{'g': 'ch_rm'});
    if (rmPeer) {
      _swapAndNew();
      return;
    }
    setState(() {});
  }

  // ---------------------------------------------------------------- رابط

  String _status() {
    if (winner >= 0) {
      final why = _ct(endKey);
      String head;
      if (winner == 2) {
        head = GameT.t('draw');
      } else if (mode == ChMode.local) {
        head = GameT.t('wins', <String, String>{'n': pnames[winner]});
      } else {
        head = winner == (mode == ChMode.bot ? 0 : myIdx) ? GameT.t('you_win') : GameT.t('you_lose');
      }
      return endKey.isEmpty || why == endKey ? head : '$head · $why';
    }
    if (lost) return _ct('lost');
    final chk = chInCheck(pos) ? ' · ${_ct('check')}' : '';
    if (mode == ChMode.bot) return pos.white ? '${GameT.t('your_turn')}$chk' : (thinking ? _ct('think') : GameT.t('opp_turn'));
    if (mode == ChMode.local) return '${GameT.t('turn_of', <String, String>{'n': pnames[_turnIdx]})}$chk';
    return _turnIdx == myIdx ? '${GameT.t('your_turn')}$chk' : '${GameT.t('turn_of', <String, String>{'n': pnames[_turnIdx]})}$chk';
  }

  String _fmt(int ms) {
    final s = (ms / 1000).ceil();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  /// مهره‌های زده‌شده توسط [idx] (۰ سفید زده‌ها = مهره‌های سیاه که حذف شده‌اند) و برتری مادی
  ({String text, int adv}) _captured(int idx) {
    final counts = List<int>.filled(7, 0);
    final sign = idx == 0 ? -1 : 1; // سفید مهره‌های سیاه را می‌زند
    for (final v in pos.b) {
      if (v != 0 && (v * sign) > 0) counts[v.abs()]++;
    }
    final sb = StringBuffer();
    for (final t in const <int>[kQueen, kRook, kBishop, kKnight, kPawn]) {
      for (var i = 0; i < _chInitial[t] - counts[t]; i++) {
        sb.write(t == kPawn ? '\u2659' : _chGlyph[t]);
      }
    }
    var mine = 0;
    var theirs = 0;
    for (final t in const <int>[kPawn, kKnight, kBishop, kRook, kQueen]) {
      final lostByBlack = _chInitial[t] - _countOf(t, false);
      final lostByWhite = _chInitial[t] - _countOf(t, true);
      mine += lostByBlack * _chValue[t];
      theirs += lostByWhite * _chValue[t];
    }
    return (text: sb.toString(), adv: idx == 0 ? mine - theirs : theirs - mine);
  }

  int _countOf(int type, bool white) {
    var n = 0;
    for (final v in pos.b) {
      if (v.abs() == type && (v > 0) == white) n++;
    }
    return n;
  }

  Widget _playerBar(int idx) {
    final active = winner < 0 && _turnIdx == idx && started;
    final cap = _captured(idx);
    final showClock = _timed;
    final low = showClock && _remaining(idx) < 30000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? gGold : gLine, width: active ? 2 : 1)),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: idx == 0 ? Colors.white : const Color(0xff1b1b1b), shape: BoxShape.circle, border: Border.all(color: gMuted))),
          const SizedBox(width: 8),
          Flexible(child: Text(pnames[idx].isEmpty ? _ct(idx == 0 ? 'white' : 'black') : pnames[idx], overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text('${cap.text}${cap.adv > 0 ? ' +${cap.adv}' : ''}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: gMuted, fontSize: 13)),
            ),
          ),
          if (showClock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: active ? (low ? const Color(0xffb3261e) : gGold) : gBg, borderRadius: BorderRadius.circular(9)),
              child: Text(_fmt(_remaining(idx)), style: TextStyle(color: active ? (low ? Colors.white : gBg) : gMuted, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget _board(double w) {
    final sz = w / 8;
    final dests = <int>{};
    final s0 = sel;
    if (s0 != null && _canAct) {
      for (final m in legal) {
        if (m.from == s0) dests.add(m.to);
      }
    }
    final kingSq = chInCheck(pos) ? chKingSq(pos.b, pos.white) : -1;
    final flip = _flip;
    final st = ChessPrefs.style;
    Widget square(int idx) {
      final f = idx % 8, r = idx ~/ 8;
      var col = (f + r) % 2 == 1 ? st.dark : st.light;
      if (idx == lastFrom || idx == lastTo) col = Color.alphaBlend(const Color(0x77ffe066), col);
      if (idx == sel) col = Color.alphaBlend(const Color(0xaaffd36a), col);
      if (idx == kingSq) col = Color.alphaBlend(const Color(0xbbff3b3b), col);
      final piece = pos.b[idx];
      final isDest = dests.contains(idx);
      final onDark = (f + r) % 2 == 1;
      final lblColor = onDark ? st.light : st.dark;
      final bottomRow = flip ? r == 0 : r == 7;
      final leftCol = flip ? f == 7 : f == 0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(idx),
        child: Container(
          width: sz,
          height: sz,
          color: col,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (leftCol) Positioned(top: 1, left: 2, child: Text('${8 - r}', style: TextStyle(fontSize: sz * 0.2, color: lblColor, fontWeight: FontWeight.w800))),
              if (bottomRow) Positioned(bottom: 0, right: 2, child: Text('abcdefgh'[f], style: TextStyle(fontSize: sz * 0.2, color: lblColor, fontWeight: FontWeight.w800))),
              if (isDest && piece == 0) Container(width: sz * 0.3, height: sz * 0.3, decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle)),
              if (isDest && piece != 0) Container(width: sz * 0.92, height: sz * 0.92, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x88000000), width: 3))),
              if (piece != 0) chessPiece(piece.abs(), piece > 0, st, sz * 0.94),
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var rr = 0; rr < 8; rr++) {
      final r = flip ? 7 - rr : rr;
      final cells = <Widget>[];
      for (var cc = 0; cc < 8; cc++) {
        final f = flip ? 7 - cc : cc;
        cells.add(square(r * 8 + f));
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: gGold, width: 2), borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ),
    );
  }

  Widget _movesRow() {
    final items = <String>[];
    for (var i = 0; i < sans.length; i += 2) {
      items.add('${i ~/ 2 + 1}. ${sans[i]}${i + 1 < sans.length ? ' ${sans[i + 1]}' : ''}');
    }
    return SizedBox(
      height: 34,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          controller: _mvCtl,
          scrollDirection: Axis.horizontal,
          children: [
            for (final t in items)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(9), border: Border.all(color: gLine)),
                child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _netCard() {
    final on = _mesh.running;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: on ? gPanel : gGold, foregroundColor: on ? gGold : gBg, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _toggleNet,
        icon: _starting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
        label: Text(on ? '${GameT.t('nearby_stop')} · ${_mesh.peers.length}' : GameT.t('nearby_start'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _big(IconData icon, String text, VoidCallback? onTap) {
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

  Widget _center(List<Widget> children) => Padding(padding: const EdgeInsets.only(top: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  Widget _body(double w) {
    switch (stage) {
      case 'menu':
        return _center(<Widget>[
          _netCard(),
          if (_mesh.running) ...<Widget>[
            _big(Icons.timer_rounded, '${_ct('time')}: ${tcMin == 0 ? _ct('noclock') : '$tcMin ${_ct('min')}'}', _pickTime),
            _big(Icons.add_circle_rounded, _ct('host'), _createNearby),
            _big(Icons.login_rounded, _ct('join'), _openJoin),
          ],
          const SizedBox(height: 8),
          Text(_ct('note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12, height: 1.8)),
        ]);
      case 'host':
        return _center(<Widget>[
          _netCard(),
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: gGold)),
          const SizedBox(height: 16),
          Text(_ct('wait_join'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.9)),
        ]);
      case 'join':
        final list = rooms.values.toList();
        return _center(<Widget>[
          _netCard(),
          if (code.isNotEmpty)
            Text(_ct('wait_host'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, height: 1.8))
          else if (list.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(_ct('none'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)))
          else
            for (final r in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
                child: Row(children: [
                  const Icon(Icons.phone_android_rounded, color: gTeal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg), onPressed: () => _joinRoom(r), child: Text(_ct('join_short'), style: const TextStyle(fontWeight: FontWeight.w900))),
                ]),
              ),
        ]);
      case 'search':
      case 'connect':
        final failed = onlineErr.isNotEmpty;
        return _center(<Widget>[
          const SizedBox(height: 40),
          if (!failed) const Center(child: CircularProgressIndicator(color: gGold)),
          const SizedBox(height: 18),
          Text(failed ? onlineErr : (stage == 'connect' ? GameT.t('connecting') : GameT.t('searching')), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, fontSize: 15, height: 1.8)),
          const SizedBox(height: 18),
          if (failed) _big(Icons.refresh_rounded, _ct('retry'), _startOnline),
        ]);
      default:
        return _play(w);
    }
  }

  Widget _play(double w) {
    if (!started) {
      return _center(<Widget>[const SizedBox(height: 40), const Center(child: CircularProgressIndicator(color: gGold)), const SizedBox(height: 16), Text(GameT.t('connecting'), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w800))]);
    }
    final bottomIdx = _flip ? 1 : 0;
    final topIdx = 1 - bottomIdx;
    final over = winner >= 0;
    return Column(
      children: [
        _playerBar(topIdx),
        const SizedBox(height: 8),
        Text(_status(), textAlign: TextAlign.center, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15.5)),
        if (sesMine + sesTheirs + sesDraws > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${_ct('score_now')}: ${pnames[_meIdx].isEmpty ? _ct(_meIdx == 0 ? 'white' : 'black') : pnames[_meIdx]} $sesMine - $sesTheirs ${pnames[1 - _meIdx].isEmpty ? _ct(_meIdx == 0 ? 'black' : 'white') : pnames[1 - _meIdx]}${sesDraws > 0 ? ' · ${GameT.t('draw')} $sesDraws' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: gMuted, fontSize: 11.5),
            ),
          ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            _board(w),
            if (_bubble.isNotEmpty)
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: IgnorePointer(
                  child: Align(
                    alignment: _bubbleMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _bubbleMine ? const Color(0xee1b4d57) : const Color(0xeef5f5f5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 8)],
                      ),
                      child: Text(_bubble, style: TextStyle(color: _bubbleMine ? Colors.white : const Color(0xff111111), fontWeight: FontWeight.w800, fontSize: 14.5)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _playerBar(bottomIdx),
        if (_isNet && chatOn) _quickChat(),
        const SizedBox(height: 8),
        _movesRow(),
        const SizedBox(height: 8),
        if (drawIn && !over)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: gSky)),
            child: Row(children: [
              Expanded(child: Text(_ct('draw_in'), style: const TextStyle(color: gSky, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => _answerDraw(false), child: Text(_ct('decline'), style: const TextStyle(color: Colors.white70))),
              FilledButton(style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg), onPressed: () => _answerDraw(true), child: Text(_ct('accept'), style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ),
        if (!over)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (mode == ChMode.local) OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)), onPressed: () => setState(() => flipLocal = !flipLocal), icon: const Icon(Icons.swap_vert_rounded, size: 18), label: Text(_ct('btn_flip'))),
              if (mode != ChMode.local) OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)), onPressed: _resign, icon: const Icon(Icons.flag_rounded, size: 18), label: Text(_ct('btn_resign'))),
              if (_isNet) OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)), onPressed: drawSent ? null : _offerDraw, icon: const Icon(Icons.handshake_rounded, size: 18), label: Text(_ct('btn_draw'))),
            ],
          ),
        if (over && resultReady) ...<Widget>[
          const SizedBox(height: 8),
          sharedResultCard(title: _status(), gained: gained, onAgain: _rematch, onBack: () => Navigator.of(context).pop()),
          if (mode != ChMode.local)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_ct('rating')}: ${ChessStats.rating}${ratingDelta == 0 ? '' : (ratingDelta > 0 ? '  (+$ratingDelta)' : '  ($ratingDelta)')}',
                textAlign: TextAlign.center,
                style: TextStyle(color: ratingDelta < 0 ? const Color(0xffff6b6b) : gTeal, fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          if (_isNet && (rmPeer || rmMine))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                rmMine ? (GameT.fa ? 'درخواست بازی دوباره ارسال شد؛ منتظر حریف…' : 'Rematch requested; waiting…') : (GameT.fa ? 'حریف بازی دوباره می‌خواهد (رنگ‌ها عوض می‌شود)' : 'Your opponent wants a rematch (colors swap)'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: gSky, fontSize: 12.5),
              ),
            ),
        ],
        const SizedBox(height: 14),
        Text(_ct('rule'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GameT.t('chess'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          actions: [
            gameFxAction(() => setState(() {})),
            IconButton(
              tooltip: _ct('btn_style'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showChessStyleSheet(context, () {
                if (mounted) setState(() {});
              }),
              icon: const Icon(Icons.palette_rounded, color: gGold),
            ),
            IconButton(
              tooltip: _ct('btn_stats'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showChessStatsSheet(context),
              icon: const Icon(Icons.emoji_events_rounded, color: gGold),
            ),
            IconButton(
              tooltip: _ct('time'),
              visualDensity: VisualDensity.compact,
              onPressed: _pickTime,
              icon: Icon(Icons.timer_rounded, color: _canPickTime ? gGold : gMuted),
            ),
            if (_isNet && stage == 'play')
              IconButton(
                tooltip: _ct('chat'),
                visualDensity: VisualDensity.compact,
                onPressed: _openChat,
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble_rounded, color: gGold),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, cons) {
              final avail = min(cons.maxWidth - 8, 760.0);
              final w = ((avail - 4) / 8).floorToDouble() * 8;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 20),
                child: Center(child: SizedBox(width: avail, child: _body(w))),
              );
            },
          ),
        ),
      ),
    );
  }
}
