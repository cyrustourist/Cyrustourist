import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import 'group_chat_page.dart';
import 'group_ui.dart';

/// صندوق پیام‌های شخصی (کنار «شناسه کاربری» در صفحهٔ حساب).
class DmInboxPage extends StatefulWidget {
  const DmInboxPage({super.key});

  @override
  State<DmInboxPage> createState() => _DmInboxPageState();
}

class _DmInboxPageState extends State<DmInboxPage> {
  GroupMine? _mine;
  bool _loading = true;
  final Map<int, int> _seen = {};
  StreamSubscription<Map<String, String>>? _wakeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _wakeSub = GroupPush.wakes.listen((d) {
      if (d['type'] == 'dm_msg') _load(silent: true);
    });
  }

  @override
  void dispose() {
    _wakeSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final m = await GroupService.mine();
    final seen = <int, int>{};
    if (m.ok) {
      for (final g in m.dms) {
        seen[g.id] = await GroupService.seenId(g.id);
      }
    }
    if (!mounted) return;
    setState(() {
      _mine = m;
      _seen
        ..clear()
        ..addAll(seen);
      _loading = false;
    });
  }

  Future<void> _open(GroupInfo g) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupChatPage(group: g)));
    if (mounted) _load(silent: true);
  }

  Future<void> _hide(GroupInfo g) async {
    final r = await GroupService.leave(g.id);
    if (!mounted) return;
    if (!r.ok) gToast(context, r.text);
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final m = _mine;
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: gGold));
    } else if (m == null || !m.ok) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(m?.message.isNotEmpty == true ? m!.message : GT.t('net'), style: const TextStyle(color: gMuted)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _load, child: Text(GT.t('retry'))),
        ]),
      );
    } else if (!m.dmEnabled) {
      body = Center(child: Text(GT.t('disabled'), style: const TextStyle(color: gMuted)));
    } else {
      final list = m.dms;
      body = RefreshIndicator(
        color: gGold,
        onRefresh: () => _load(silent: true),
        child: list.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(GT.t('dm_empty'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)),
                ),
              ])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final g = list[i];
                  return GroupTile(
                    group: g,
                    unread: g.lastId > (_seen[g.id] ?? 0),
                    onTap: () => _open(g),
                    trailing: PopupMenuButton<String>(
                      color: gPanel,
                      iconColor: gMuted,
                      onSelected: (_) => _hide(g),
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(value: 'hide', child: Text(GT.t('dm_hide'), style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                  );
                },
              ),
      );
    }
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GT.t('dm_title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: body,
      ),
    );
  }
}
