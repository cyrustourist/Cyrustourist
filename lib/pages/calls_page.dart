import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/language/menu_translations.dart';
import '../services/call_audio.dart';
import '../services/call_service.dart';
import '../services/call_session.dart';
import '../services/call_texts.dart';
import '../services/friends_service.dart';
import '../widgets/call_widgets.dart';
import 'add_friend_page.dart';
import 'profile/my_profile_page.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _green = Color(0xff2fb36a);
const Color _red = Color(0xffff8f8f);

/// صفحهٔ «تماس‌ها»: تماس صوتی/تصویری، لیست دوستان، تاریخچهٔ تماس و مسدودشده‌ها.
class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  bool _loading = true;
  bool _needProfile = false;
  String? _error;
  List<FriendItem> _friends = const [];
  List<CallLogItem> _log = const [];
  List<BlockedItem> _blocked = const [];

  // حافظهٔ محلی: صفحه فوراً با آخرین داده باز می‌شود و سرور در پس‌زمینه تازه‌اش می‌کند.
  static const String _cacheKey = 'calls_cache_v1';
  static const String _hiddenKey = 'calls_hidden_ids_v1';
  static const String _clearedAtKey = 'calls_cleared_at_v1';
  Set<String> _hiddenIds = <String>{};
  int _clearedAtMs = 0;

  @override
  void initState() {
    super.initState();
    unawaited(CallSession.prefetchIce());
    unawaited(_boot());
    // اول مجوز «اعلان تمام‌صفحه»، بعد مجوز میکروفن (دو پنجره روی هم نیایند)
    unawaited(_askFullScreenOnce().then((_) async {
      if (mounted) await CallService.instance.promptMicOnce(context);
    }));
  }

  Future<void> _boot() async {
    await _readCache();
    if (!mounted) return;
    // اگر داده‌ای در حافظه بود، بدون اسپینر نمایش بده و بی‌صدا تازه کن
    await _load(silent: !_loading);
  }

  Future<void> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hiddenIds = (prefs.getStringList(_hiddenKey) ?? const <String>[]).toSet();
      _clearedAtMs = prefs.getInt(_clearedAtKey) ?? 0;
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final m = jsonDecode(raw);
      if (m is! Map) return;
      List<T> items<T>(dynamic l, T? Function(dynamic) f) => [
            if (l is List)
              for (final e in l)
                if (f(e) != null) f(e) as T,
          ];
      final fr = items<FriendItem>(m['friends'], FriendItem.fromJson);
      final lg = items<CallLogItem>(m['log'], CallLogItem.fromJson);
      final bl = items<BlockedItem>(m['blocked'], BlockedItem.fromJson);
      if (!mounted) return;
      setState(() {
        _friends = fr;
        _log = lg;
        _blocked = bl;
        _loading = false;
      });
    } catch (_) {}
  }

  Future<void> _saveCache(List<dynamic> friendsRaw, List<dynamic> logRaw, List<dynamic> blockedRaw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({'friends': friendsRaw, 'log': logRaw, 'blocked': blockedRaw}));
    } catch (_) {}
  }

  List<CallLogItem> get _visibleLog =>
      _log.where((c) => c.atMs > _clearedAtMs && !_hiddenIds.contains(c.id)).toList();

  Future<void> _hideOne(CallLogItem c) async {
    setState(() => _hiddenIds = {..._hiddenIds, c.id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenKey, _hiddenIds.toList());
    unawaited(FriendsService.deleteCalls(ids: [c.id]));
    _toast(CT.t('deleted_one'));
  }

  Future<void> _hideAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          content: Text(CT.t('delete_all_confirm'), style: const TextStyle(color: Colors.white, height: 1.7)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(CT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(CT.t('delete_all'), style: const TextStyle(color: _red))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() => _clearedAtMs = now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_clearedAtKey, now);
    unawaited(FriendsService.deleteCalls(all: true));
    _toast(CT.t('deleted_all'));
  }

  /// اندروید ۱۴ به بالا: برای زنگ خوردن روی قفل گوشی کاربر باید «اعلان تمام‌صفحه» را دستی روشن کند.
  /// فقط یک‌بار و با توضیح نشان داده می‌شود.
  Future<void> _askFullScreenOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('call_fsi_asked_v1') == true) return;
      if (await CallAudio.canFullScreen()) return;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(CT.t('fsi_title')),
            content: Text(CT.t('fsi_body')),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(CT.t('fsi_later'))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(CT.t('fsi_open'))),
            ],
          ),
        ),
      );
      await prefs.setBool('call_fsi_asked_v1', true);
      if (go == true) await CallAudio.openFullScreenSettings();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _needProfile = false;
      });
    }
    // سه درخواست هم‌زمان (قبلاً پشت‌سرهم بودند)
    final frF = FriendsService.list();
    final histF = FriendsService.history();
    final blockF = FriendsService.blocked();
    final fr = await frF;
    final hist = await histF;
    final blk = await blockF;
    if (!mounted) return;
    if (!fr.ok) {
      // اگر داده‌ی محلی داریم، خطای شبکه صفحه را خراب نکند
      final hasLocal = _friends.isNotEmpty || _log.isNotEmpty || _blocked.isNotEmpty;
      setState(() {
        _loading = false;
        _needProfile = fr.needsProfile;
        _error = (fr.needsProfile || hasLocal) ? null : fr.text;
      });
      return;
    }
    setState(() {
      _loading = false;
      _needProfile = false;
      _error = null;
      _friends = fr.data ?? const [];
      _log = hist.data ?? _log;
      _blocked = blk.data ?? _blocked;
    });
    unawaited(_saveCache(
      _friends.map(_friendJson).toList(),
      _log.map(_logJson).toList(),
      _blocked.map(_blockedJson).toList(),
    ));
  }

  Map<String, dynamic> _friendJson(FriendItem f) =>
      {'uid': f.uid, 'name': f.name, 'username': f.username, 'has_photo': f.hasPhoto, 'badge': f.badge};

  Map<String, dynamic> _logJson(CallLogItem c) => {
        'id': c.id,
        'peer_uid': c.peerUid,
        'peer_name': c.peerName,
        'peer_username': c.peerUsername,
        'has_photo': c.hasPhoto,
        'direction': c.outgoing ? 'out' : 'in',
        'status': c.status,
        'at': c.atMs,
        'duration_s': c.durationS,
        'msg': c.msgKey,
        'is_friend': c.isFriend,
      };

  Map<String, dynamic> _blockedJson(BlockedItem b) =>
      {'uid': b.uid, 'name': b.name, 'username': b.username, 'has_photo': b.hasPhoto, 'until_at': b.untilMs};

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFriendPage()));
    if (mounted) unawaited(_load(silent: true));
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
    if (mounted) unawaited(_load());
  }

  Future<void> _call(String uid, String name, {bool hasPhoto = true}) async {
    await CallService.instance.startOutgoing(
      toUid: uid,
      name: name,
      isFriend: FriendsService.isFriendCached(uid),
      hasPhoto: hasPhoto,
    );
    if (mounted) unawaited(_load(silent: true));
  }

  void _videoSoon() => _toast(CT.t('video_soon'));

  Future<void> _pickAndCall() async {
    if (_friends.isEmpty) {
      _toast(CT.t('friends_empty'));
      _tabs.animateTo(0);
      return;
    }
    final f = await showModalBottomSheet<FriendItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _FriendPickerSheet(friends: _friends),
    );
    if (f != null && mounted) {
      await _call(f.uid, f.name, hasPhoto: f.hasPhoto);
    }
  }

  Future<void> _removeFriend(FriendItem f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          content: Text(CT.t('remove_confirm', {'name': f.name}), style: const TextStyle(color: Colors.white, height: 1.7)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(CT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(CT.t('delete'), style: const TextStyle(color: _red))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final r = await FriendsService.remove(f.uid);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _friends = _friends.where((x) => x.uid != f.uid).toList());
      _toast(CT.t('friend_removed'));
    } else {
      _toast(r.text);
    }
  }

  Future<void> _blockCalls(String uid, String name) async {
    final hours = await showBlockDurationSheet(context, name);
    if (hours == null || !mounted) return;
    final r = await FriendsService.blockCalls(uid, hours);
    if (!mounted) return;
    if (r.ok) {
      _toast(CT.t('blocked_done', {'name': name}));
      unawaited(_load(silent: true));
    } else {
      _toast(r.text);
    }
  }

  Future<void> _unblock(BlockedItem b) async {
    final r = await FriendsService.unblockCalls(b.uid);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _blocked = _blocked.where((x) => x.uid != b.uid).toList());
      _toast(CT.t('unblocked_done'));
    } else {
      _toast(r.text);
    }
  }

  Future<void> _addFromLog(CallLogItem c) async {
    final r = await FriendsService.add(friendUid: c.peerUid);
    if (!mounted) return;
    if (r.ok) {
      _toast(CT.t('friend_added', {'name': c.peerName}));
      unawaited(_load(silent: true));
    } else {
      _toast(r.needsProfile ? CT.t('need_profile') : r.text);
    }
  }

  // ------------------------------------------------------------------
  // ساخت صفحه
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: _gold));
    } else if (_needProfile) {
      body = _message(Icons.account_circle_rounded, CT.t('need_profile'), CT.t('go_profile'), _openProfile);
    } else if (_error != null) {
      body = _message(Icons.cloud_off_rounded, _error!, CT.t('retry'), _load);
    } else {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(child: _bigAction(Icons.call_rounded, CT.t('voice_call'), const [Color(0xff2fb36a), Color(0xff1e8f52)], _pickAndCall)),
                const SizedBox(width: 12),
                Expanded(child: _bigAction(Icons.videocam_rounded, CT.t('video_call'), const [Color(0xff4a6fd0), Color(0xff3a55a8)], _videoSoon)),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: _gold,
            unselectedLabelColor: Colors.white54,
            indicatorColor: _gold,
            dividerColor: Colors.white12,
            tabs: [
              Tab(text: CT.t('tab_friends')),
              Tab(text: CT.t('tab_recent')),
              Tab(text: CT.t('tab_blocked')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_friendsTab(), _recentTab(), _blockedTab()],
            ),
          ),
        ],
      );
    }

    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(CT.t('calls_title'), style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [
            AnimatedBuilder(
              animation: _tabs,
              builder: (_, __) => (_tabs.index == 1 && _visibleLog.isNotEmpty)
                  ? IconButton(
                      tooltip: CT.t('delete_all'),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      onPressed: _hideAll,
                    )
                  : const SizedBox.shrink(),
            ),
            IconButton(
              tooltip: CT.t('add_friend'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: _openAdd,
            ),
          ],
        ),
        floatingActionButton: (_loading || _needProfile || _error != null)
            ? null
            : FloatingActionButton(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                tooltip: CT.t('add_friend'),
                onPressed: _openAdd,
                child: const Icon(Icons.add_rounded, size: 30),
              ),
        body: SafeArea(child: body),
      ),
    );
  }

  Widget _message(IconData icon, String text, String button, FutureOr<void> Function() onTap) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _gold.withValues(alpha: 0.8)),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => onTap(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: BorderSide(color: _gold.withValues(alpha: 0.7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigAction(IconData icon, String label, List<Color> colors, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tick(String? b) => b == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: 5),
          child: Icon(Icons.verified_rounded, size: 17, color: b == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
        );

  Widget _empty(IconData icon, String text, {String? hint, String? button, VoidCallback? onTap}) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 54, color: _gold.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 8, 30, 0),
            child: Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, height: 1.7, fontSize: 13)),
          ),
        if (button != null && onTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(button),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: BorderSide(color: _gold.withValues(alpha: 0.7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------- دوستان ----------------
  Widget _friendsTab() {
    if (_friends.isEmpty) {
      return _empty(Icons.group_add_rounded, CT.t('friends_empty'), hint: CT.t('friends_empty_hint'), button: CT.t('add_friend'), onTap: _openAdd);
    }
    return RefreshIndicator(
      color: _gold,
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _friends.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1, indent: 72),
        itemBuilder: (context, i) {
          final f = _friends[i];
          return ListTile(
            onTap: () => _call(f.uid, f.name, hasPhoto: f.hasPhoto),
            leading: CallAvatar(uid: f.uid, name: f.name, radius: 23, hasPhoto: f.hasPhoto),
            title: Row(children: [
              Flexible(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              _tick(f.badge),
            ]),
            subtitle: f.username.isEmpty
                ? null
                : Text('@${f.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: _teal, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: CT.t('voice_call'),
                  icon: const Icon(Icons.call_rounded, color: _green),
                  onPressed: () => _call(f.uid, f.name, hasPhoto: f.hasPhoto),
                ),
                IconButton(
                  tooltip: CT.t('video_call'),
                  icon: const Icon(Icons.videocam_rounded, color: Colors.white54),
                  onPressed: _videoSoon,
                ),
                PopupMenuButton<String>(
                  color: _card,
                  iconColor: Colors.white70,
                  onSelected: (v) {
                    if (v == 'block') _blockCalls(f.uid, f.name);
                    if (v == 'remove') _removeFriend(f);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'block', child: Text(CT.t('block_calls'), style: const TextStyle(color: Colors.white))),
                    PopupMenuItem(value: 'remove', child: Text(CT.t('remove_friend'), style: const TextStyle(color: _red))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- اخیر ----------------
  String _logLabel(CallLogItem c) {
    final dir = CT.t(c.outgoing ? 'dir_out' : 'dir_in');
    final when = CT.ago(c.atMs);
    String status;
    if (c.status == 'answered') {
      status = c.durationS > 0 ? '$dir ${CT.duration(c.durationS)}' : dir;
    } else if (c.isMissedForMe) {
      status = CT.t('st_missed');
    } else if (c.status == 'declined') {
      status = CT.t('st_declined');
    } else if (c.status == 'canceled') {
      status = CT.t('st_canceled');
    } else if (c.status == 'missed') {
      status = CT.t('st_missed');
    } else {
      status = dir;
    }
    var out = '$status  •  $when';
    final mk = c.msgKey;
    if (mk != null && mk.isNotEmpty) out += '\n«${CT.msg(mk)}»';
    return out;
  }

  Widget _recentTab() {
    final log = _visibleLog;
    if (log.isEmpty) return _empty(Icons.history_rounded, CT.t('recent_empty'));
    return RefreshIndicator(
      color: _gold,
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: log.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1, indent: 72),
        itemBuilder: (context, i) {
          final c = log[i];
          final bad = c.isMissedForMe || (!c.outgoing && c.status == 'declined');
          final IconData arrow = c.status == 'answered'
              ? (c.outgoing ? Icons.call_made_rounded : Icons.call_received_rounded)
              : (c.outgoing ? Icons.call_made_rounded : Icons.call_missed_rounded);
          final tile = ListTile(
            onTap: () => _call(c.peerUid, c.peerName, hasPhoto: c.hasPhoto),
            leading: CallAvatar(uid: c.peerUid, name: c.peerName, radius: 23, hasPhoto: c.hasPhoto),
            title: Text(c.peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: bad ? _red : Colors.white, fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(arrow, size: 15, color: bad ? _red : _green),
                  ),
                  const SizedBox(width: 5),
                  Expanded(child: Text(_logLabel(c), style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.5))),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!c.isFriend)
                  IconButton(
                    tooltip: CT.t('add_to_friends'),
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: _gold, size: 22),
                    onPressed: () => _addFromLog(c),
                  ),
                IconButton(
                  tooltip: CT.t('voice_call'),
                  icon: const Icon(Icons.call_rounded, color: _green),
                  onPressed: () => _call(c.peerUid, c.peerName, hasPhoto: c.hasPhoto),
                ),
                IconButton(
                  tooltip: CT.t('delete_one'),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 22),
                  onPressed: () => _hideOne(c),
                ),
              ],
            ),
          );
          return Dismissible(
            key: ValueKey('log_${c.id}_${c.atMs}'),
            background: Container(color: const Color(0x33ff5a5a)),
            onDismissed: (_) => _hideOne(c),
            child: tile,
          );
        },
      ),
    );
  }

  // ---------------- مسدودشده ----------------
  Widget _blockedTab() {
    if (_blocked.isEmpty) return _empty(Icons.block_rounded, CT.t('blocked_empty'));
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _blocked.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1, indent: 72),
      itemBuilder: (context, i) {
        final b = _blocked[i];
        return ListTile(
          leading: CallAvatar(uid: b.uid, name: b.name, radius: 23, hasPhoto: b.hasPhoto),
          title: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: Text(CT.remaining(b.untilMs), style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _unblock(b),
                child: Text(CT.t('back_btn'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () => _blockCalls(b.uid, b.name),
                child: Text(CT.t('block_btn'), style: const TextStyle(color: _red, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// انتخاب دوست برای تماس صوتی (با جستجو).
class _FriendPickerSheet extends StatefulWidget {
  const _FriendPickerSheet({required this.friends});

  final List<FriendItem> friends;

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.friends
        : widget.friends.where((f) => f.name.toLowerCase().contains(q) || f.username.toLowerCase().contains(q)).toList();
    final height = MediaQuery.of(context).size.height * 0.72;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Text(CT.t('pick_friend'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: CT.t('search_friend'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: _gold),
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(child: Text(CT.t('no_match'), style: const TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final f = list[i];
                          return ListTile(
                            onTap: () => Navigator.of(context).pop(f),
                            leading: CallAvatar(uid: f.uid, name: f.name, radius: 22, hasPhoto: f.hasPhoto),
                            title: Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: f.username.isEmpty
                                ? null
                                : Text('@${f.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: _teal, fontSize: 12)),
                            trailing: const Icon(Icons.call_rounded, color: _green),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
