import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/call_texts.dart';
import '../../services/friends_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../../widgets/call_widgets.dart';
import 'group_chat_page.dart';
import 'group_ui.dart';

/// پیام‌های شخصی: تب «گفتگوها» (گفتگوهای باز) و تب «دوستان من» (لمس دوست = شروع گفتگو، دکمهٔ افزودن دوست).
class DmInboxPage extends StatefulWidget {
  const DmInboxPage({super.key});

  @override
  State<DmInboxPage> createState() => _DmInboxPageState();
}

class _DmInboxPageState extends State<DmInboxPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  GroupMine? _mine;
  bool _loading = true;
  final Map<int, int> _seen = {};
  StreamSubscription<Map<String, String>>? _wakeSub;

  List<FriendItem> _friends = const [];
  bool _friendsLoading = true;
  String _friendsError = '';
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _loadFriends();
    _wakeSub = GroupPush.wakes.listen((d) {
      if (d['type'] == 'dm_msg') _load(silent: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
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

  Future<void> _loadFriends({bool silent = false}) async {
    if (!silent) setState(() => _friendsLoading = true);
    final r = await FriendsService.list();
    if (!mounted) return;
    setState(() {
      _friendsLoading = false;
      if (r.ok) {
        _friends = r.data ?? const [];
        _friendsError = '';
      } else {
        _friendsError = r.needsProfile ? CT.t('need_profile') : r.text;
      }
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

  Future<void> _openFriend(FriendItem f) async {
    await openDm(context, f.uid);
    if (mounted) _load(silent: true);
  }

  // ---------- افزودن دوست (جی‌میل، شماره یا نام کاربری) ----------
  Future<void> _addFriend() async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          title: Text(CT.t('add_title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(CT.t('add_desc'), style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.8)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: CT.t('add_field'),
                hintStyle: const TextStyle(color: gMuted, fontSize: 12.5),
                filled: true,
                fillColor: gBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gLine)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gLine)),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(GT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: Text(CT.t('add_btn')),
            ),
          ],
        ),
      ),
    );
    if (!mounted || value == null) return;
    if (value.isEmpty) {
      gToast(context, CT.t('add_empty'));
      return;
    }
    setState(() => _adding = true);
    final r = await FriendsService.add(identifier: value);
    if (!mounted) return;
    setState(() => _adding = false);
    if (r.ok) {
      final name = r.data?.name ?? '';
      gToast(context, CT.t(r.raw?['already'] == true ? 'friend_exists' : 'friend_added', {'name': name}));
      _loadFriends(silent: true);
    } else {
      gToast(context, r.needsProfile ? CT.t('need_profile') : r.text);
    }
  }

  // ---------- تب گفتگوها ----------
  Widget _chatsTab() {
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
    if (!m.dmEnabled) return Center(child: Text(GT.t('disabled'), style: const TextStyle(color: gMuted)));
    final list = m.dms;
    return RefreshIndicator(
      color: gGold,
      onRefresh: () => _load(silent: true),
      child: list.isEmpty
          ? ListView(children: [
              const SizedBox(height: 110),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(GT.t('dm_empty'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.9)),
              ),
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _tabs.animateTo(1),
                  icon: const Icon(Icons.people_alt_rounded, color: gGold),
                  label: Text(GT.t('tab_friends'), style: const TextStyle(color: gGold)),
                ),
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

  // ---------- تب دوستان من ----------
  Widget _friendsTab() {
    Widget body;
    if (_friendsLoading) {
      body = const Center(child: CircularProgressIndicator(color: gGold));
    } else if (_friendsError.isNotEmpty) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(_friendsError, textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.8)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _loadFriends, child: Text(GT.t('retry'))),
        ]),
      );
    } else if (_friends.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 90),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            Text(CT.t('friends_empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(CT.t('friends_empty_hint'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.8)),
          ]),
        ),
      ]);
    } else {
      body = RefreshIndicator(
        color: gGold,
        onRefresh: () => _loadFriends(silent: true),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          itemCount: _friends.length,
          itemBuilder: (_, i) {
            final f = _friends[i];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
              child: ListTile(
                onTap: () => _openFriend(f),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: GestureDetector(
                  onTap: () => openUserProfile(context, f.uid, f.name),
                  child: CallAvatar(uid: f.uid, name: f.name, hasPhoto: f.hasPhoto, radius: 23),
                ),
                title: Row(children: [
                  Flexible(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  gTick(f.badge),
                ]),
                subtitle: f.username.isEmpty ? null : Text('@${f.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: gTeal, fontSize: 12)),
                trailing: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: gGold.withValues(alpha: 0.16), foregroundColor: gGold),
                  onPressed: () => _openFriend(f),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: Text(GT.t('friend_chat')),
                ),
              ),
            );
          },
        ),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _adding ? null : _addFriend,
            icon: _adding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(CT.t('add_friend'), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ),
      Expanded(child: body),
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
          title: Text(GT.t('dm_title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: gGold,
            labelColor: gGold,
            unselectedLabelColor: gMuted,
            tabs: [Tab(text: GT.t('tab_chats')), Tab(text: GT.t('tab_friends'))],
          ),
        ),
        body: TabBarView(controller: _tabs, children: [_chatsTab(), _friendsTab()]),
      ),
    );
  }
}
