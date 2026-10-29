import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/call_service.dart';
import '../../services/call_texts.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../../widgets/linkified_text.dart';
import '../profile/public_profile_page.dart';
import 'group_info_page.dart';
import 'group_ui.dart';

/// چت یک گروه یا یک گفتگوی شخصی (kind == dm). پیام‌ها موقتی‌اند و ماندگاری را پنل تعیین می‌کند.
/// بروزرسانی: بیدارباش FCM (فوری) + یک poll کند فقط وقتی همین صفحه باز و اپ روشن است.
class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.group});

  final GroupInfo group;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with WidgetsBindingObserver {
  late GroupInfo _g;
  final List<GroupMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  StreamSubscription<Map<String, String>>? _wakeSub;
  bool _fetching = false;
  bool _sending = false;
  bool _loaded = false;
  int _lastId = 0;
  int _retention = 24;
  int _members = 0;
  String _role = 'member';
  String _phoneMode = 'verified';

  @override
  void initState() {
    super.initState();
    _g = widget.group;
    _retention = _g.retentionHours;
    _members = _g.memberCount;
    _role = _g.role ?? 'member';
    WidgetsBinding.instance.addObserver(this);
    GroupPush.activeGroupId = _g.id;
    CallService.instance.startWatch();
    _wakeSub = GroupPush.wakes.listen((d) {
      if (d['group_id'] == '${_g.id}') _poll();
    });
    _poll();
    _startTimer();
    GroupService.phoneMode().then((m) {
      if (mounted) setState(() => _phoneMode = m);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (GroupPush.activeGroupId == _g.id) GroupPush.activeGroupId = 0;
    CallService.instance.stopWatch();
    _wakeSub?.cancel();
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      _poll();
    } else {
      _timer?.cancel();
    }
  }

  // بیدارباش FCM اصلی است؛ این poll فقط پشتیبان است (اگر اعلان دیر برسد یا نرسد)
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final f = await GroupService.messages(_g.id, afterId: _lastId);
      if (!mounted) return;
      if (!f.ok) {
        if (f.error == 'g_not_member' || f.error == 'g_not_found') {
          gToast(context, f.message.isNotEmpty ? f.message : GT.err(f.error));
          Navigator.of(context).maybePop();
        }
        return;
      }
      final atBottom = !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 80;
      setState(() {
        _loaded = true;
        _retention = f.retentionHours;
        _members = f.memberCount;
        _role = f.role;
        if (f.messages.isNotEmpty) {
          _messages.addAll(f.messages);
          _lastId = f.messages.last.id;
          if (_messages.length > 150) _messages.removeRange(0, _messages.length - 150);
        }
      });
      if (_lastId > 0) GroupService.markSeen(_g.id, _lastId);
      if (atBottom && f.messages.isNotEmpty) _jumpToEnd();
    } finally {
      _fetching = false;
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final r = await GroupService.send(_g.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _input.clear();
      await _poll();
      _jumpToEnd();
      return;
    }
    if (r.error == 'no_name' || r.error == 'not_registered') {
      askGroupProfile(context);
      return;
    }
    gToast(context, r.text);
  }

  Future<void> _openInfo() async {
    if (_g.isDm) {
      final uid = _g.peerUid;
      if (uid != null && uid.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfilePage(uid: uid, name: _g.title)));
      }
      return;
    }
    final res = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => GroupInfoPage(group: _g)));
    if (!mounted) return;
    if (res == 'left' || res == 'deleted') {
      Navigator.of(context).pop();
      return;
    }
    // نام/عکس ممکن است در صفحهٔ اطلاعات عوض شده باشد
    final fresh = await GroupService.info(id: _g.id);
    final ng = fresh.group;
    if (mounted && fresh.ok && ng != null) setState(() => _g = ng);
  }

  Future<void> _messageMenu(GroupMessage m) async {
    final staff = _role == 'owner' || _role == 'admin';
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: gPanel,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!m.mine) ...[
              ListTile(
                leading: const Icon(Icons.person_rounded, color: gGold),
                title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                onTap: () => Navigator.of(ctx).pop('user'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Color(0xffff8f8f)),
                title: Text(GT.t('report_msg'), style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('report'),
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: gGold),
                title: Text(GT.t('block_user', {'name': m.name}), style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('block'),
              ),
            ],
            if (staff && !_g.isDm)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xffff8f8f)),
                title: Text(GT.t('hide_msg'), style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('hide'),
              ),
          ]),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'user') {
      await openUserProfile(context, m.uid, m.name);
    } else if (action == 'report') {
      final ok = await GroupService.report(_g.id, m.id);
      if (mounted) gToast(context, ok ? GT.t('report_done') : GT.t('report_fail'));
    } else if (action == 'block') {
      final ok = await ChatService.block(m.uid);
      if (!mounted) return;
      if (ok) {
        setState(() => _messages.removeWhere((x) => x.uid == m.uid));
        gToast(context, GT.t('block_done', {'name': m.name}));
      } else {
        gToast(context, GT.t('op_failed'));
      }
    } else if (action == 'hide') {
      final ok = await GroupService.hideMessage(_g.id, m.id);
      if (!mounted) return;
      if (ok) setState(() => _messages.removeWhere((x) => x.id == m.id));
    }
  }

  Widget _bubble(GroupMessage m) {
    final mine = m.mine;
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onLongPress: () => _messageMenu(m),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xff143a4a) : gPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gLine),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!mine && !_g.isDm)
              Row(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: () => openUserProfile(context, m.uid, m.name),
                  child: Text(m.name, style: const TextStyle(color: gGold, fontSize: 11.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                ),
                gTick(m.badge),
              ]),
            LinkifiedText(text: m.text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.8)),
            Text(gTime(m.at), style: const TextStyle(color: gMuted, fontSize: 10.5)),
          ]),
        ),
      ),
    );
  }

  String get _rules {
    final keep = GT.t(_g.isDm ? 'dm_retention' : 'retention_banner', {'h': GT.hours(_retention)});
    if (_g.isDm) return keep;
    final rule = _phoneMode == 'all' ? 'rules_all' : (_phoneMode == 'verified' ? 'rules_verified' : 'rules_group');
    return '${GT.t(rule)}\n$keep';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _g.isDm ? '' : GT.t('members_n', {'n': '$_members'});
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: gGold),
          titleSpacing: 0,
          title: InkWell(
            onTap: _openInfo,
            child: Row(children: [
              GroupAvatar(name: _g.title, isGroup: !_g.isDm, size: 36, group: _g),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_g.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                  if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: gMuted, fontSize: 11.5)),
                ]),
              ),
            ]),
          ),
          actions: [
            if (!_g.isDm)
              IconButton(onPressed: _openInfo, icon: const Icon(Icons.info_outline_rounded, color: gGold)),
            if (_g.isDm && _g.peerUid != null)
              IconButton(
                tooltip: CT.t('profile_call'),
                onPressed: () => CallService.instance.startOutgoing(toUid: _g.peerUid!, name: _g.title),
                icon: const Icon(Icons.call_rounded, color: gGold),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Text(_rules, textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 11)),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator(color: gGold))
                  : _messages.isEmpty
                      ? Center(child: Text(GT.t('no_msgs'), style: const TextStyle(color: gMuted, fontSize: 13)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _bubble(_messages[i]),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 1000,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: GT.t('type_msg'),
                      hintStyle: const TextStyle(color: gMuted),
                      counterText: '',
                      filled: true,
                      fillColor: gPanel,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(GT.t('send'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
