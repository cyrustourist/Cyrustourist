import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/offline_mesh_service.dart';
import '../groups/group_ui.dart';
import 'game_engine.dart';
import 'game_play_page.dart';
import 'game_texts.dart';

/// بازی دو نفره بین دو گوشی نزدیک، بدون اینترنت (Nearby Connections؛ همان شبکه‌ی چت آفلاین).
class NearbyDuelPage extends StatefulWidget {
  const NearbyDuelPage({super.key, required this.kind});
  final GameKind kind;

  @override
  State<NearbyDuelPage> createState() => _NearbyDuelPageState();
}

class _NearbyDuelPageState extends State<NearbyDuelPage> {
  final OfflineMeshService _mesh = OfflineMeshService.instance;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _starting = false;
  bool _inGame = false;
  bool _asking = false;
  String _invited = '';

  @override
  void initState() {
    super.initState();
    NearbyGameLink.instance.attach();
    _sub = NearbyGameLink.instance.events.stream.listen(_onEvent);
    _mesh.addListener(_onMesh);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mesh.removeListener(_onMesh);
    NearbyGameLink.instance.detach();
    super.dispose();
  }

  void _onMesh() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_starting) return;
    if (_mesh.running) {
      await _mesh.stop();
      return;
    }
    setState(() => _starting = true);
    final ok = await _mesh.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (!ok) gToast(context, GameT.t('nearby_perm'));
  }

  Future<void> _openGame(GameKind kind, String uid, String name, bool first) async {
    _inGame = true;
    _invited = '';
    if (mounted) setState(() {});
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePlayPage(kind: kind, mode: PlayMode.nearby, peerUid: uid, peerName: name, nearbyFirst: first),
      ),
    );
    _inGame = false;
    if (mounted) setState(() {});
  }

  Future<void> _onEvent(Map<String, dynamic> m) async {
    if (!mounted || m['to'] != _mesh.myUid) return;
    final from = '${m['u']}';
    final fromName = '${m['n']}';
    switch (m['g']) {
      case 'inv':
        if (_inGame || _asking) {
          NearbyGameLink.instance.send(<String, dynamic>{'g': 'dec', 'to': from});
          return;
        }
        final kind = GameKindX.parse('${m['game']}') ?? widget.kind;
        _asking = true;
        final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Directionality(
            textDirection: gDir,
            child: AlertDialog(
              backgroundColor: gPanel,
              title: Text(GameT.t(kind.code), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
              content: Text(GameT.t('nearby_incoming', <String, String>{'n': fromName}), style: const TextStyle(color: Colors.white, height: 1.8)),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(GameT.t('decline'), style: const TextStyle(color: Colors.white70))),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(GameT.t('accept'), style: const TextStyle(color: gGold))),
              ],
            ),
          ),
        );
        _asking = false;
        if (!mounted) return;
        if (ok == true) {
          NearbyGameLink.instance.send(<String, dynamic>{'g': 'acc', 'to': from, 'game': kind.code});
          await _openGame(kind, from, fromName, false);
        } else {
          NearbyGameLink.instance.send(<String, dynamic>{'g': 'dec', 'to': from});
        }
        break;
      case 'acc':
        if (_invited == from && !_inGame) await _openGame(widget.kind, from, fromName, true);
        break;
      case 'dec':
        if (_invited == from) {
          setState(() => _invited = '');
          gToast(context, GameT.t('decline'));
        }
        break;
    }
  }

  void _invite(OfflinePeer p) {
    setState(() => _invited = p.uid);
    NearbyGameLink.instance.send(<String, dynamic>{'g': 'inv', 'to': p.uid, 'game': widget.kind.code});
  }

  @override
  Widget build(BuildContext context) {
    final on = _mesh.running;
    final peers = _mesh.peers.values.toList();
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text('${GameT.t('nearby_title')} · ${GameT.t(widget.kind.code)}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: on ? gPanel : gGold, foregroundColor: on ? gGold : gBg, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _toggle,
              icon: _starting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(on ? Icons.wifi_tethering_off_rounded : Icons.wifi_tethering_rounded),
              label: Text(on ? GameT.t('nearby_stop') : GameT.t('nearby_start'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 16),
            if (on && peers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(GameT.t('nearby_none'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)),
              ),
            for (final p in peers)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: gTeal),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    _invited == p.uid
                        ? Text(GameT.t('nearby_wait'), style: const TextStyle(color: gMuted, fontSize: 12))
                        : FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
                            onPressed: () => _invite(p),
                            child: Text(GameT.t('nearby_invite'), style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(GameT.t('offline_note'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11.5, height: 1.7)),
          ],
        ),
      ),
    );
  }
}
