import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'dice_games.dart';
import 'game_api.dart';
import 'game_engine.dart';
import 'game_play_page.dart';
import 'game_shop_sheet.dart';
import 'game_texts.dart';
import 'nearby_duel_page.dart';

/// صفحه‌ی «بازی و سرگرمی»: کیف سکه و سطح، جایزه‌ی روزانه، هدف‌ها، انتخاب بازی و حالت.
class GamesHubPage extends StatefulWidget {
  const GamesHubPage({super.key});

  @override
  State<GamesHubPage> createState() => _GamesHubPageState();
}

class _GamesHubPageState extends State<GamesHubPage> {
  final GameWallet _w = GameWallet.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _w.addListener(_onChange);
    _boot();
  }

  @override
  void dispose() {
    _w.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _boot() async {
    await _w.init();
    await _w.refresh();
    if (mounted) setState(() => _loading = false);
  }

  String _errText() {
    switch (_w.error) {
      case 'not_registered':
      case 'no_name':
      case 'auth_required':
        return GameT.t('need_profile');
      case 'disabled':
        return GameT.t('disabled');
      case 'net':
        return _w.data.isEmpty ? GameT.t('net_err') : '';
      default:
        return '';
    }
  }

  Future<void> _claimDaily() async {
    final ok = await _w.claimDaily();
    if (!mounted) return;
    if (ok) gToast(context, '🎁 ${GameT.t('gained', <String, String>{'n': '${_w.lastGain}'})}');
  }

  Future<void> _claimGoal(int id) async {
    final ok = await _w.claimGoal(id);
    if (!mounted) return;
    if (ok) gToast(context, '🎯 ${GameT.t('gained', <String, String>{'n': '${_w.lastGain}'})}');
  }

  void _openMode(GameKind kind) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${GameT.t(kind.code)} · ${GameT.t('choose_mode')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                _modeTile(Icons.smart_toy_rounded, GameT.t('mode_bot'), GameT.t('mode_bot_sub'), () {
                  Navigator.of(ctx).pop();
                  _pickLevel(kind);
                }),
                _modeTile(Icons.people_alt_rounded, GameT.t('mode_local'), GameT.t('mode_local_sub'), () {
                  Navigator.of(ctx).pop();
                  _push(GamePlayPage(kind: kind, mode: PlayMode.local));
                }),
                _modeTile(Icons.wifi_tethering_rounded, GameT.t('mode_nearby'), GameT.t('mode_nearby_sub'), () {
                  Navigator.of(ctx).pop();
                  _push(NearbyDuelPage(kind: kind));
                }),
                _modeTile(Icons.public_rounded, GameT.t('mode_online'), GameT.t('mode_online_sub'), () {
                  Navigator.of(ctx).pop();
                  _push(GamePlayPage(kind: kind, mode: PlayMode.online));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// مار و پله و منچ: ربات یا دو نفره روی یک گوشی (بدون اینترنت).
  void _openDiceMode(DiceKind kind) {
    final snakes = kind == DiceKind.snakes;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${GameT.t(snakes ? 'snakes' : 'ludo')} · ${GameT.t('choose_mode')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                _modeTile(Icons.smart_toy_rounded, GameT.t('mode_bot'), GameT.t('mode_bot_sub'), () {
                  Navigator.of(ctx).pop();
                  if (snakes) {
                    _push(const SnakesPage(mode: DiceMode.bot));
                  } else {
                    _pickLudoLevel();
                  }
                }),
                _modeTile(Icons.people_alt_rounded, GameT.t('mode_local'), GameT.t('mode_local_sub'), () {
                  Navigator.of(ctx).pop();
                  _push(snakes ? const SnakesPage(mode: DiceMode.local) : const LudoPage(mode: DiceMode.local));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickLudoLevel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in BotLevel.values)
                  _modeTile(
                    l == BotLevel.easy ? Icons.sentiment_satisfied_rounded : (l == BotLevel.normal ? Icons.sentiment_neutral_rounded : Icons.local_fire_department_rounded),
                    GameT.t('lvl_${l.name}'),
                    '',
                    () {
                      Navigator.of(ctx).pop();
                      _push(LudoPage(mode: DiceMode.bot, level: l));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickLevel(GameKind kind) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in BotLevel.values)
                  _modeTile(
                    l == BotLevel.easy ? Icons.sentiment_satisfied_rounded : (l == BotLevel.normal ? Icons.sentiment_neutral_rounded : Icons.local_fire_department_rounded),
                    GameT.t('lvl_${l.name}'),
                    '',
                    () {
                      Navigator.of(ctx).pop();
                      _push(GamePlayPage(kind: kind, mode: PlayMode.bot, level: l));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _w.refresh();
  }

  Widget _modeTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: gBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
            child: Row(
              children: [
                Icon(icon, color: gGold, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                      if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: gMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
                Icon(gDir == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: gMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTop() async {
    final j = await GameApi.get('/api/game/top');
    if (!mounted) return;
    final list = (j?['top'] as List?) ?? const <dynamic>[];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: gPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏆 ${GameT.t('leaderboard')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(GameT.t('net_err'), style: const TextStyle(color: gMuted))))
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in list.whereType<Map>())
                          Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: gBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: e['me'] == true ? gGold : gLine),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 28, child: Text('${e['rank']}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900))),
                                Expanded(child: Text('${e['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                                Text('${GameT.t('level', <String, String>{'n': '${e['level']}'})} · ${e['xp']} XP', style: const TextStyle(color: gMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ بخش‌ها

  Widget _walletCard() {
    final err = _errText();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gGold, width: 1.6),
        gradient: const LinearGradient(colors: [Color(0xff0e3042), Color(0xff0a2130)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🪙 ${_w.coins}', style: const TextStyle(color: gGold, fontSize: 30, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: gLine)),
                child: Text(
                  '${GameT.t('level', <String, String>{'n': '${_w.level}'})} · ${GameT.rank(_w.rank)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: _w.levelProgress, minHeight: 8, backgroundColor: gBg, color: gTeal),
          ),
          const SizedBox(height: 4),
          Text(_w.nextXp == null ? '${_w.xp} XP' : '${_w.xp} / ${_w.nextXp} XP', style: const TextStyle(color: gMuted, fontSize: 11.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎁 ${GameT.t('daily')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    if (_w.streak > 0) Text(GameT.t('daily_streak', <String, String>{'n': '${_w.streak}'}), style: const TextStyle(color: gMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              if (_w.data.isNotEmpty && _w.dailyReady)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                  onPressed: _claimDaily,
                  child: Text('${GameT.t('claim')}  +${_w.dailyNext}', style: const TextStyle(fontWeight: FontWeight.w900)),
                )
              else if (_w.data.isNotEmpty)
                Text('✓ ${GameT.t('claimed')}', style: const TextStyle(color: gTeal, fontWeight: FontWeight.w800)),
            ],
          ),
          if (err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(err, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, height: 1.7)),
            ),
          if (_w.queued > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(GameT.t('queued', <String, String>{'n': '${_w.queued}'}), style: const TextStyle(color: gMuted, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }

  Widget _goalsCard() {
    final goals = _w.goals;
    if (goals.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: gLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 ${GameT.t('goals')}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 8),
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(GameT.t('goal_${g['key']}'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (((g['progress'] as num?) ?? 0) / ((g['need'] as num?) ?? 1)).clamp(0.0, 1.0).toDouble(),
                            minHeight: 6,
                            backgroundColor: gBg,
                            color: gSky,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (g['claimed'] == true)
                    const Icon(Icons.check_circle_rounded, color: gTeal)
                  else if (((g['progress'] as num?) ?? 0) >= ((g['need'] as num?) ?? 1))
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, padding: const EdgeInsets.symmetric(horizontal: 12)),
                      onPressed: () => _claimGoal((g['id'] as num).toInt()),
                      child: Text('+${g['coins']}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    )
                  else
                    Text('🪙 ${g['coins']}', style: const TextStyle(color: gMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gameCard(String emoji, String title, VoidCallback? onTap) {
    final soon = onTap == null;
    return Opacity(
      opacity: soon ? 0.5 : 1,
      child: Material(
        color: gPanel,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: soon ? gLine : gGold, width: soon ? 1 : 1.5)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(height: 6),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                if (soon) Text(GameT.t('soon'), style: const TextStyle(color: gMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ),
      ),
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
          title: Text(GameT.t('title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          actions: [
            IconButton(tooltip: GameT.t('leaderboard'), icon: const Icon(Icons.emoji_events_rounded, color: gGold), onPressed: _showTop),
            IconButton(tooltip: GameT.t('shop'), icon: const Icon(Icons.storefront_rounded, color: gGold), onPressed: () => showGameShop(context)),
          ],
        ),
        body: RefreshIndicator(
          color: gGold,
          onRefresh: _w.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              if (_loading && _w.data.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: gGold)))
              else ...[
                _walletCard(),
                _goalsCard(),
                const SizedBox(height: 18),
                Text(GameT.t('games'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _gameCard('⭕❌', GameT.t('ttt'), () => _openMode(GameKind.ttt)),
                    _gameCard('🔴🟡', GameT.t('c4'), () => _openMode(GameKind.c4)),
                    _gameCard('🐍', GameT.t('snakes'), () => _openDiceMode(DiceKind.snakes)),
                    _gameCard('🎲', GameT.t('ludo'), () => _openDiceMode(DiceKind.ludo)),
                    _gameCard('♟️', GameT.t('chess'), null),
                    _gameCard('🎯', GameT.t('backgammon'), null),
                  ],
                ),
                const SizedBox(height: 14),
                Text(GameT.t('offline_note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
