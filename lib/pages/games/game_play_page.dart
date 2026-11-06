import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'game_api.dart';
import 'game_board.dart';
import 'game_engine.dart';
import 'game_texts.dart';

enum PlayMode { bot, local, nearby, online }

/// پیام‌های بازی بین دو گوشی نزدیک (روی همان شبکه‌ی Nearby چت آفلاین).
class NearbyGameLink {
  NearbyGameLink._();
  static final NearbyGameLink instance = NearbyGameLink._();

  final StreamController<Map<String, dynamic>> events = StreamController<Map<String, dynamic>>.broadcast();
  int _users = 0;

  void attach() {
    _users++;
    OfflineMeshService.instance.gameHandler = (m) => events.add(m);
  }

  void detach() {
    if (_users > 0) _users--;
    if (_users == 0) OfflineMeshService.instance.gameHandler = null;
  }

  void send(Map<String, dynamic> m) => OfflineMeshService.instance.sendGame(m);
}

class GamePlayPage extends StatefulWidget {
  const GamePlayPage({
    super.key,
    required this.kind,
    required this.mode,
    this.level = BotLevel.normal,
    this.peerUid = '',
    this.peerName = '',
    this.nearbyFirst = true,
  });

  final GameKind kind;
  final PlayMode mode;
  final BotLevel level;
  final String peerUid;
  final String peerName;

  /// نزدیک: آیا این گوشی بازیکن اول (دعوت‌کننده) است؟
  final bool nearbyFirst;

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  final GameWallet _w = GameWallet.instance;
  final Random _rnd = Random();

  late List<int> board;
  int turn = 1;
  int winner = 0;
  bool draw = false;
  List<int> line = const <int>[];
  int myMark = 1;
  bool botThinking = false;
  int gained = 0;
  bool resultReady = false;
  String endReason = '';

  String icon1 = 'lion';
  String icon2 = 'camel';
  String name1 = '';
  String name2 = '';
  late GameTheme theme;

  // آنلاین
  bool searching = false;
  String onlineError = '';
  String roomId = '';
  int version = 0;
  String status = 'waiting';
  bool oppOnline = true;
  int turnMsLeft = 1;
  List<Map<String, dynamic>> chat = <Map<String, dynamic>>[];
  bool busy = false;
  int _coinsBefore = 0;
  Timer? _poll;
  int _tick = 0;
  bool _polling = false;
  final TextEditingController _chatCtrl = TextEditingController();

  // نزدیک
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool myRematch = false;
  bool peerRematch = false;
  bool peerGone = false;

  bool get finished => winner != 0 || draw || status == 'done';
  GameKind get kind => widget.kind;
  PlayMode get mode => widget.mode;

  @override
  void initState() {
    super.initState();
    board = GameEngine.emptyBoard(kind);
    theme = GameTheme.byCode(_w.equippedTheme);
    icon1 = _w.equippedIcon;
    icon2 = icon1 == 'camel' ? 'deer' : 'camel';
    name1 = GameT.t('you');
    switch (mode) {
      case PlayMode.bot:
        name2 = GameT.t('robot');
        break;
      case PlayMode.local:
        name1 = GameT.t('player1');
        name2 = GameT.t('player2');
        break;
      case PlayMode.nearby:
        myMark = widget.nearbyFirst ? 1 : 2;
        name1 = widget.nearbyFirst ? GameT.t('you') : widget.peerName;
        name2 = widget.nearbyFirst ? widget.peerName : GameT.t('you');
        NearbyGameLink.instance.attach();
        _sub = NearbyGameLink.instance.events.stream.listen(_onNearby);
        OfflineMeshService.instance.addListener(_onMesh);
        break;
      case PlayMode.online:
        _coinsBefore = _w.coins;
        WidgetsBinding.instance.addPostFrameCallback((_) => _startOnline());
        break;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _chatCtrl.dispose();
    if (mode == PlayMode.nearby) {
      _sub?.cancel();
      OfflineMeshService.instance.removeListener(_onMesh);
      NearbyGameLink.instance.detach();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ منطق مشترک

  bool _applyLocal(int move) {
    final res = GameEngine.apply(kind, board, turn, move);
    if (res == null) return false;
    setState(() {
      board = res.board;
      line = res.line;
      if (res.winner != 0) {
        winner = res.winner;
      } else if (res.draw) {
        draw = true;
      } else {
        turn = turn == 1 ? 2 : 1;
      }
    });
    if (finished) _onFinishedOffline();
    return true;
  }

  Future<void> _onFinishedOffline() async {
    String result;
    String level;
    if (mode == PlayMode.bot) {
      result = draw ? 'draw' : (winner == myMark ? 'win' : 'loss');
      level = widget.level.name;
    } else if (mode == PlayMode.nearby) {
      result = draw ? 'draw' : (winner == myMark ? 'win' : 'loss');
      level = 'nearby';
    } else {
      result = 'win';
      level = 'local';
    }
    final g = await _w.reportOffline(result, level);
    if (!mounted) return;
    setState(() {
      gained = g;
      resultReady = true;
    });
  }

  void _onTap(int move) {
    if (finished || busy) return;
    switch (mode) {
      case PlayMode.bot:
        if (turn != myMark || botThinking) return;
        if (_applyLocal(move) && !finished) _botTurn();
        break;
      case PlayMode.local:
        _applyLocal(move);
        break;
      case PlayMode.nearby:
        if (turn != myMark || peerGone) return;
        if (_applyLocal(move)) {
          NearbyGameLink.instance.send(<String, dynamic>{'g': 'mv', 'to': widget.peerUid, 'mv': move});
        }
        break;
      case PlayMode.online:
        if (status != 'playing' || turn != myMark) return;
        _onlineMove(move);
        break;
    }
  }

  Future<void> _botTurn() async {
    setState(() => botThinking = true);
    await Future<void>.delayed(Duration(milliseconds: 380 + _rnd.nextInt(420)));
    if (!mounted) return;
    final botMark = myMark == 1 ? 2 : 1;
    final mv = GameEngine.bot(kind, board, botMark, widget.level);
    botThinking = false;
    if (mv >= 0) {
      _applyLocal(mv);
    } else {
      setState(() {});
    }
  }

  void _reset() {
    setState(() {
      board = GameEngine.emptyBoard(kind);
      turn = 1;
      winner = 0;
      draw = false;
      line = const <int>[];
      gained = 0;
      resultReady = false;
      botThinking = false;
      myRematch = false;
      peerRematch = false;
    });
  }

  void _playAgain() {
    switch (mode) {
      case PlayMode.bot:
        // بازیکن اول هر دست عوض می‌شود
        myMark = myMark == 1 ? 2 : 1;
        _reset();
        if (myMark == 2) _botTurn();
        break;
      case PlayMode.local:
        _reset();
        break;
      case PlayMode.nearby:
        myRematch = true;
        NearbyGameLink.instance.send(<String, dynamic>{'g': 'rm', 'to': widget.peerUid});
        if (peerRematch) {
          myMark = myMark == 1 ? 2 : 1;
          _swapNearbyNames();
          _reset();
        } else {
          setState(() {});
        }
        break;
      case PlayMode.online:
        _poll?.cancel();
        setState(() {
          board = GameEngine.emptyBoard(kind);
          turn = 1;
          winner = 0;
          draw = false;
          line = const <int>[];
          gained = 0;
          resultReady = false;
          status = 'waiting';
          endReason = '';
          chat = <Map<String, dynamic>>[];
        });
        _coinsBefore = _w.coins;
        _startOnline();
        break;
    }
  }

  void _swapNearbyNames() {
    final t = name1;
    name1 = name2;
    name2 = t;
  }

  // ------------------------------------------------------------ نزدیک

  void _onNearby(Map<String, dynamic> m) {
    if (!mounted) return;
    if (m['to'] != OfflineMeshService.instance.myUid || m['u'] != widget.peerUid) return;
    switch (m['g']) {
      case 'mv':
        final mv = (m['mv'] as num?)?.toInt();
        if (mv != null && !finished && turn != myMark) _applyLocal(mv);
        break;
      case 'bye':
        if (!finished) setState(() => peerGone = true);
        break;
      case 'rm':
        peerRematch = true;
        if (myRematch) {
          myMark = myMark == 1 ? 2 : 1;
          _swapNearbyNames();
          _reset();
        } else {
          setState(() {});
        }
        break;
    }
  }

  void _onMesh() {
    if (!mounted || mode != PlayMode.nearby) return;
    final here = OfflineMeshService.instance.peers.values.any((p) => p.uid == widget.peerUid);
    if (!here && !peerGone && !finished) setState(() => peerGone = true);
  }

  // ------------------------------------------------------------ آنلاین

  void _failOnline(String msg) {
    if (!mounted) return;
    setState(() {
      searching = false;
      onlineError = msg;
    });
  }

  Future<void> _startOnline() async {
    setState(() {
      searching = true;
      onlineError = '';
    });
    final j = await GameApi.post('/api/game/quick', <String, dynamic>{'game': kind.code});
    if (!mounted) return;
    if (j == null) {
      _failOnline(GameT.t('net_err'));
      return;
    }
    if (j['success'] != true || j['room'] is! Map) {
      final e = j['error'];
      _failOnline(e == 'not_registered' || e == 'no_name' || e == 'auth_required'
          ? GameT.t('need_profile')
          : (e == 'disabled' ? GameT.t('disabled') : GameT.t('net_err')));
      return;
    }
    _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
    _poll?.cancel();
    _tick = 0;
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _pollTick());
  }

  void _applyRoom(Map<String, dynamic> r) {
    final b = (r['board'] as List?)?.map((e) => (e as num).toInt()).toList();
    final host = r['host'] is Map ? Map<String, dynamic>.from(r['host'] as Map) : <String, dynamic>{};
    final guest = r['guest'] is Map ? Map<String, dynamic>.from(r['guest'] as Map) : null;
    final st = '${r['status']}';
    final win = (r['winner'] as num?)?.toInt() ?? 0;
    final reason = '${r['end_reason'] ?? ''}';
    final wasFinished = finished;
    setState(() {
      roomId = '${r['id']}';
      version = (r['version'] as num?)?.toInt() ?? version;
      status = st;
      myMark = (r['my_mark'] as num?)?.toInt() ?? myMark;
      turn = (r['turn'] as num?)?.toInt() ?? turn;
      if (b != null && b.length == kind.cells) board = b;
      line = (r['line'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const <int>[];
      winner = win;
      endReason = reason;
      draw = st == 'done' && win == 0 && reason == 'normal';
      searching = st == 'waiting';
      oppOnline = r['opp_online'] == true;
      turnMsLeft = (r['turn_ms_left'] as num?)?.toInt() ?? turnMsLeft;
      icon1 = '${host['icon'] ?? 'lion'}';
      name1 = '${host['name'] ?? ''}';
      if (guest != null) {
        icon2 = '${guest['icon'] ?? 'camel'}';
        name2 = '${guest['name'] ?? ''}';
      }
      chat = ((r['chat'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (st == 'done') _poll?.cancel();
    });
    if (st == 'done' && !wasFinished) {
      // سرور کیف پول را برای همین بازی همراه پاسخ می‌دهد؛ تفاوت سکه = جایزه
      Future<void>.delayed(const Duration(milliseconds: 250), () async {
        await _w.refresh();
        if (!mounted) return;
        setState(() {
          gained = (_w.coins - _coinsBefore).clamp(0, 100000).toInt();
          resultReady = true;
        });
      });
    }
  }

  Future<void> _pollTick() async {
    if (!mounted || _polling || roomId.isEmpty) return;
    _tick++;
    final myTurnNow = status == 'playing' && turn == myMark;
    if (myTurnNow && _tick % 4 != 0) return;
    _polling = true;
    try {
      final j = await GameApi.get('/api/game/state', <String, String>{'room_id': roomId, 'since': '$version'});
      if (!mounted || j == null) return;
      if (j['success'] != true) {
        if (j['error'] == 'room_gone') {
          _poll?.cancel();
          setState(() {
            status = 'done';
            endReason = 'abandoned';
            resultReady = true;
          });
        }
        return;
      }
      if (j['changed'] == true && j['room'] is Map) {
        _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
      } else {
        setState(() {
          oppOnline = j['opp_online'] == true;
          turnMsLeft = (j['turn_ms_left'] as num?)?.toInt() ?? turnMsLeft;
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _onlineMove(int m) async {
    setState(() => busy = true);
    final j = await GameApi.post('/api/game/move', <String, dynamic>{'room_id': roomId, 'move': m});
    if (!mounted) return;
    setState(() => busy = false);
    if (j == null) {
      gToast(context, GameT.t('net_err'));
      return;
    }
    if (j['room'] is Map) _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
    if (j['wallet'] != null) _w.applyWallet(j['wallet']);
  }

  Future<void> _claimTimeout() async {
    final j = await GameApi.post('/api/game/timeout', <String, dynamic>{'room_id': roomId});
    if (!mounted) return;
    if (j != null && j['room'] is Map) _applyRoom(Map<String, dynamic>.from(j['room'] as Map));
  }

  Future<void> _sendChat({String? phrase}) async {
    final text = _chatCtrl.text.trim();
    if (phrase == null && text.isEmpty) return;
    if (phrase == null) _chatCtrl.clear();
    final j = await GameApi.post('/api/game/chat', <String, dynamic>{
      'room_id': roomId,
      if (phrase != null) 'phrase': phrase else 'text': text,
    });
    if (!mounted) return;
    if (j != null && j['success'] == true) {
      _tick = 3; // نوبت بعدی تایمر حتماً state را بگیرد تا پیام همین حالا دیده شود
      version = 0;
    } else if (j != null && j['error'] == 'chat_locked') {
      gToast(context, GameT.t('chat_locked'));
    }
  }

  Future<void> _unlockChat() async {
    final e = await _w.buy('chat_1h');
    if (!mounted) return;
    if (e.isEmpty) {
      gToast(context, GameT.t('bought'));
      setState(() {});
    } else {
      gToast(context, e == 'no_coins' ? GameT.t('no_coins') : GameT.t('net_err'));
    }
  }

  // ------------------------------------------------------------ خروج

  Future<void> _leave() async {
    if (finished || (mode == PlayMode.online && status == 'waiting') || (mode == PlayMode.local && board.every((e) => e == 0))) {
      await _doLeave();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          title: Text(GameT.t('resign'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          content: Text(GameT.t('resign_q'), style: const TextStyle(color: Colors.white, height: 1.8)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(GameT.t('no'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(GameT.t('yes'), style: const TextStyle(color: gGold))),
          ],
        ),
      ),
    );
    if (ok == true) await _doLeave();
  }

  Future<void> _doLeave() async {
    if (mode == PlayMode.online && roomId.isNotEmpty && status != 'done') {
      GameApi.post('/api/game/resign', <String, dynamic>{'room_id': roomId});
    }
    if (mode == PlayMode.nearby && !finished) {
      NearbyGameLink.instance.send(<String, dynamic>{'g': 'bye', 'to': widget.peerUid});
    }
    _poll?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------ رابط

  bool _canTap() {
    if (finished || busy || botThinking) return false;
    if (mode == PlayMode.local) return true;
    if (mode == PlayMode.online) return status == 'playing' && turn == myMark;
    return turn == myMark && !peerGone;
  }

  String _chatText(Map<String, dynamic> m) {
    final who = (m['u'] as num?)?.toInt() == myMark ? GameT.t('you') : (myMark == 1 ? name2 : name1);
    final raw = '${m['m']}';
    final body = raw.startsWith('#') ? GameT.t('ph_${raw.substring(1)}') : raw;
    return '$who: $body';
  }

  Widget _playerChip(int mark) {
    final name = mark == 1 ? name1 : name2;
    final icon = kGameIconEmoji[mark == 1 ? icon1 : icon2] ?? '🦁';
    final active = !finished && status != 'waiting' && turn == mark;
    final mine = (mode == PlayMode.bot || mode == PlayMode.online || mode == PlayMode.nearby) && myMark == mark;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: gPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? theme.accent : gLine, width: active ? 2.2 : 1),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.isEmpty ? '…' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mine ? theme.accent : Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (mode == PlayMode.online && status == 'waiting') return GameT.t('searching');
    if (finished) {
      if (mode == PlayMode.online && endReason == 'resign') return winner == myMark ? GameT.t('opp_left') : GameT.t('you_lose');
      if (mode == PlayMode.online && endReason == 'timeout') return winner == myMark ? GameT.t('timeout_end') : GameT.t('you_lose');
      if (mode == PlayMode.online && endReason == 'abandoned') return GameT.t('opp_left');
      if (draw) return GameT.t('draw');
      if (mode == PlayMode.local) return GameT.t('wins', <String, String>{'n': winner == 1 ? name1 : name2});
      return winner == myMark ? GameT.t('you_win') : GameT.t('you_lose');
    }
    if (mode == PlayMode.local) return GameT.t('turn_of', <String, String>{'n': turn == 1 ? name1 : name2});
    return turn == myMark ? GameT.t('your_turn') : GameT.t('opp_turn');
  }

  Widget _resultCard() {
    final win = !draw && (mode == PlayMode.local || winner == myMark);
    final canAgain = !(mode == PlayMode.online && endReason == 'abandoned');
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: win ? gTeal : gLine),
      ),
      child: Column(
        children: [
          if (gained > 0)
            Text('🪙 ${GameT.t('gained', <String, String>{'n': '$gained'})}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 17))
          else if (resultReady && mode != PlayMode.local)
            Text(GameT.t('no_reward'), style: const TextStyle(color: gMuted, fontSize: 12.5)),
          if (mode != PlayMode.online && resultReady && _w.queued > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(GameT.t('queued', <String, String>{'n': '${_w.queued}'}), style: const TextStyle(color: gMuted, fontSize: 11.5)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: gLine)),
                  onPressed: _doLeave,
                  child: Text(GameT.t('back')),
                ),
              ),
              if (canAgain) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: theme.accent, foregroundColor: gBg),
                    onPressed: (mode == PlayMode.nearby && myRematch) || (mode == PlayMode.nearby && peerGone) ? null : _playAgain,
                    child: Text(GameT.t('play_again'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chatBox() {
    if (mode != PlayMode.online || status == 'waiting' || roomId.isEmpty) return const SizedBox.shrink();
    final phrases = const ['gl', 'gg', 'wow', 'oops', 'again', 'hurry', 'thanks', 'nice'];
    final last = chat.length > 4 ? chat.sublist(chat.length - 4) : chat;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in last)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                _chatText(m),
                style: TextStyle(color: (m['u'] as num?)?.toInt() == myMark ? theme.accent : Colors.white70, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in phrases)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ActionChip(
                      backgroundColor: gPanel,
                      side: const BorderSide(color: gLine),
                      label: Text(GameT.t('ph_$p'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () => _sendChat(phrase: p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_w.chatOn)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    maxLength: 80,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      hintText: GameT.t('chat_hint'),
                      hintStyle: const TextStyle(color: gMuted),
                      filled: true,
                      fillColor: gPanel,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendChat(),
                  ),
                ),
                IconButton(onPressed: _sendChat, icon: Icon(Icons.send_rounded, color: theme.accent)),
              ],
            )
          else
            TextButton.icon(
              onPressed: _unlockChat,
              icon: const Icon(Icons.lock_outline_rounded, size: 18, color: gMuted),
              label: Text('${GameT.t('chat_locked')} · 🪙 40', style: const TextStyle(color: gMuted, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }

  Widget _searchingBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: gLine)),
      child: Column(
        children: [
          if (onlineError.isEmpty) const CircularProgressIndicator(color: gGold),
          const SizedBox(height: 18),
          Text(
            onlineError.isEmpty ? GameT.t('searching') : onlineError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.8),
          ),
          if (onlineError.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(GameT.t('searching_sub'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12.5)),
            ),
          if (onlineError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                onPressed: _startOnline,
                child: Text(GameT.t('play_again')),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = mode == PlayMode.online;
    final waiting = online && (status == 'waiting' || roomId.isEmpty);
    final myTurnEnabled = _canTap();
    return Directionality(
      textDirection: gDir,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.bg,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: theme.accent),
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _leave),
            title: Text(GameT.t(kind.code), style: TextStyle(color: theme.accent, fontWeight: FontWeight.w900)),
            actions: [
              if (!finished && !waiting)
                TextButton(onPressed: _leave, child: Text(GameT.t('resign'), style: const TextStyle(color: gMuted, fontSize: 12.5))),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (waiting)
                  _searchingBox()
                else ...[
                  Row(children: [_playerChip(1), const SizedBox(width: 10), _playerChip(2)]),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _statusText(),
                      style: TextStyle(
                        color: finished ? (draw ? Colors.white : theme.accent) : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  if (online && !finished && turn != myMark && !oppOnline)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(child: Text(GameT.t('opp_offline'), style: const TextStyle(color: gMuted, fontSize: 12.5))),
                    ),
                  if (mode == PlayMode.nearby && peerGone && !finished)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(child: Text(GameT.t('nearby_lost'), style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
                    ),
                  const SizedBox(height: 12),
                  GameBoard(
                    kind: kind,
                    board: board,
                    line: line,
                    theme: theme,
                    icon1: icon1,
                    icon2: icon2,
                    enabled: myTurnEnabled,
                    onMove: _onTap,
                  ),
                  if (online && !finished && status == 'playing' && turn != myMark && turnMsLeft <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: theme.accent, side: BorderSide(color: theme.accent)),
                        onPressed: _claimTimeout,
                        child: Text('${GameT.t('opp_timeout')}  ·  ${GameT.t('end_game')}'),
                      ),
                    ),
                  if (finished && (resultReady || mode == PlayMode.local || (online && endReason != 'normal' && endReason.isNotEmpty))) _resultCard(),
                  if (!finished && mode != PlayMode.online && mode != PlayMode.local)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(GameT.t('offline_note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
                    ),
                  _chatBox(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
