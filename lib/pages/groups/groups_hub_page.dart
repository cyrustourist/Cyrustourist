import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import 'create_group_page.dart';
import 'group_chat_page.dart';
import 'group_ui.dart';

/// گروه‌های گردشگری: «گروه‌های من» + «جستجوی گروه‌های عمومی» + ساخت گروه.
class GroupsHubPage extends StatefulWidget {
  const GroupsHubPage({super.key});

  @override
  State<GroupsHubPage> createState() => _GroupsHubPageState();
}

class _GroupsHubPageState extends State<GroupsHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  GroupMine? _mine;
  bool _loading = true;
  final Map<int, int> _seen = {};

  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  List<GroupInfo> _results = const [];
  bool _searching = false;
  bool _searched = false;
  StreamSubscription<Map<String, String>>? _wakeSub;
  Timer? _wakeDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _wakeSub = GroupPush.wakes.listen((_) {
      _wakeDebounce?.cancel();
      _wakeDebounce = Timer(const Duration(seconds: 2), () => _load(silent: true));
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _q.dispose();
    _debounce?.cancel();
    _wakeDebounce?.cancel();
    _wakeSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final m = await GroupService.mine();
    final seen = <int, int>{};
    if (m.ok) {
      for (final g in m.chats) {
        seen[g.id] = await GroupService.seenId(g.id);
      }
      unawaited(GroupPush.syncTopics(force: true));
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

  Future<void> _create() async {
    final m = _mine;
    final created = await Navigator.of(context).push<GroupInfo>(
      MaterialPageRoute(builder: (_) => CreateGroupPage(limits: m?.limits ?? const GroupLimits())),
    );
    if (!mounted || created == null) return;
    await _load(silent: true);
    if (mounted) _open(created);
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _searching = true);
      final r = await GroupService.search(q);
      if (!mounted || _q.text.trim() != q) return;
      setState(() {
        _results = r;
        _searching = false;
        _searched = true;
      });
    });
  }

  Future<void> _join(GroupInfo g) async {
    final r = await GroupService.join(id: g.id);
    if (!mounted) return;
    if (!r.ok) {
      if (r.error == 'no_name' || r.error == 'not_registered') {
        askGroupProfile(context);
      } else {
        gToast(context, r.text);
      }
      return;
    }
    if (r.status == 'pending') {
      gToast(context, GT.t('pending_wait'));
      _onQuery(_q.text);
      return;
    }
    gToast(context, GT.t('joined_ok'));
    final joined = r.group ?? g;
    await _load(silent: true);
    if (mounted) _open(joined);
  }

  Widget _mineTab() {
    final m = _mine;
    if (_loading) return const Center(child: CircularProgressIndicator(color: gGold));
    if (m == null || !m.ok) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(m?.message.isNotEmpty == true ? m!.message : GT.t('net'), style: const TextStyle(color: gMuted)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _load, child: Text(GT.t('retry'))),
        ]),
      );
    }
    if (!m.enabled) return Center(child: Text(GT.t('disabled'), style: const TextStyle(color: gMuted)));
    final list = m.chats;
    return RefreshIndicator(
      color: gGold,
      onRefresh: () => _load(silent: true),
      child: list.isEmpty
          ? ListView(children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(GT.t('no_groups'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final g = list[i];
                final pending = g.status == 'pending';
                return GroupTile(
                  group: g,
                  unread: !pending && g.lastId > (_seen[g.id] ?? 0),
                  trailing: pending ? Text(GT.t('pending_wait'), style: const TextStyle(color: gMuted, fontSize: 11)) : null,
                  onTap: pending ? () => gToast(context, GT.t('pending_wait')) : () => _open(g),
                );
              },
            ),
    );
  }

  Widget _searchTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: TextField(
          controller: _q,
          onChanged: _onQuery,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: GT.t('search_hint'),
            hintStyle: const TextStyle(color: gMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: gGold),
            filled: true,
            fillColor: gPanel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
          ),
        ),
      ),
      if (_searching) const LinearProgressIndicator(color: gGold, backgroundColor: gBg, minHeight: 2),
      Expanded(
        child: _results.isEmpty
            ? Center(
                child: Text(_searched ? GT.t('no_results') : GT.t('search_min'), style: const TextStyle(color: gMuted)),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final g = _results[i];
                  final isMember = g.status == 'active';
                  final pending = g.status == 'pending';
                  return GroupTile(
                    group: g,
                    onTap: isMember ? () => _open(g) : () => _join(g),
                    trailing: pending
                        ? Text(GT.t('pending_wait'), style: const TextStyle(color: gMuted, fontSize: 11))
                        : FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, visualDensity: VisualDensity.compact),
                            onPressed: isMember ? () => _open(g) : () => _join(g),
                            child: Text(isMember ? GT.t('open') : GT.t('join'), style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                  );
                },
              ),
      ),
    ]);
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
          title: Text(GT.t('menu_groups'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: gGold,
            labelColor: gGold,
            unselectedLabelColor: gMuted,
            tabs: [Tab(text: GT.t('tab_mine')), Tab(text: GT.t('tab_search'))],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: gGold,
          foregroundColor: gBg,
          onPressed: _create,
          icon: const Icon(Icons.group_add_rounded),
          label: Text(GT.t('create_group'), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: TabBarView(controller: _tabs, children: [_mineTab(), _searchTab()]),
      ),
    );
  }
}
