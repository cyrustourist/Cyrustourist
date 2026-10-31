import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/call_service.dart';
import '../../services/call_texts.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../../widgets/linkified_text.dart';
import '../profile/public_profile_page.dart';
import 'chat_photo.dart';
import 'group_info_page.dart';
import 'group_ui.dart';

const List<String> _kEmojis = ['👍', '❤️', '😂', '🔥', '😮', '🙏'];

/// چت یک گروه یا یک گفتگوی شخصی (kind == dm). پیام‌ها موقتی‌اند و ماندگاری را پنل تعیین می‌کند.
/// قابلیت‌ها: پاسخ به پیام، واکنش ایموجی (دوبار لمس = ❤️)، سنجاق پیام، حذف پیام خود، حالت آهسته،
/// «فقط مدیران پیام بدهند». بروزرسانی: بیدارباش FCM (فوری) + یک poll کند فقط وقتی همین صفحه باز است.
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
  Timer? _slowTimer;
  StreamSubscription<Map<String, String>>? _wakeSub;
  bool _fetching = false;
  bool _sending = false;
  bool _loaded = false;
  int _lastId = 0;
  int _retention = 24;
  int _members = 0;
  String _role = 'member';
  String _phoneMode = 'verified';

  int? _sv; // نسخهٔ وضعیت زنده (واکنش‌ها/سنجاق/حذف)
  GroupPinned? _pinned;
  GroupMessage? _replyTo;
  int _slowSecs = 0;
  bool _onlyAdmins = false;
  int _slowLeft = 0;
  bool _mediaOk = false;
  bool _photoSending = false;
  String _linksMode = 'own';

  bool get _isStaff => !_g.isDm && (_role == 'owner' || _role == 'admin');

  @override
  void initState() {
    super.initState();
    _g = widget.group;
    _retention = _g.retentionHours;
    _members = _g.memberCount;
    _role = _g.role ?? 'member';
    _slowSecs = _g.slowSecs;
    _onlyAdmins = _g.onlyAdmins;
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
    _slowTimer?.cancel();
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

  void _startSlow(int secs) {
    _slowTimer?.cancel();
    if (secs <= 0) return;
    setState(() => _slowLeft = secs);
    _slowTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _slowLeft = _slowLeft > 0 ? _slowLeft - 1 : 0);
      if (_slowLeft <= 0) t.cancel();
    });
  }

  /// واکنش‌ها، سنجاق و حذف‌ها را روی پیام‌های موجود اعمال می‌کند.
  void _applyState(GroupState st) {
    _sv = st.sv;
    _pinned = st.pinned;
    _messages.removeWhere((m) => st.hiddenIds.contains(m.id));
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.id < st.minId) continue; // خارج از پنجرهٔ سرور؛ دست نزن
      _messages[i] = m.copyWith(reactions: st.reactions[m.id] ?? const <String, int>{}, myReaction: st.mine[m.id] ?? '');
    }
    if (_replyTo != null && st.hiddenIds.contains(_replyTo!.id)) _replyTo = null;
  }

  Future<void> _poll({bool force = false}) async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final f = await GroupService.messages(_g.id, afterId: _lastId, sv: force ? null : _sv);
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
        _slowSecs = f.slowSecs;
        _onlyAdmins = f.onlyAdmins;
        _mediaOk = f.mediaOk;
        _linksMode = f.linksMode;
        if (f.messages.isNotEmpty) {
          _messages.addAll(f.messages);
          _lastId = f.messages.last.id;
          if (_messages.length > 150) _messages.removeRange(0, _messages.length - 150);
        }
        final st = f.state;
        if (st != null) _applyState(st);
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
    if (text.isEmpty || _sending || _slowLeft > 0) return;
    setState(() => _sending = true);
    final r = await GroupService.send(_g.id, text, replyTo: _replyTo?.id ?? 0);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _input.clear();
      setState(() => _replyTo = null);
      if (!_isStaff && !_g.isDm && _slowSecs > 0) _startSlow(_slowSecs);
      await _poll();
      _jumpToEnd();
      return;
    }
    if (r.error == 'g_slowmode') {
      _startSlow(int.tryParse('${r.raw?['wait']}') ?? _slowSecs);
    }
    if (r.error == 'no_name' || r.error == 'not_registered') {
      askGroupProfile(context);
      return;
    }
    gToast(context, r.text);
  }

  Future<void> _sendPhoto() async {
    if (_sending || _photoSending || _slowLeft > 0) return;
    final pick = await pickChatPhoto(context);
    if (pick == null || !mounted) return;
    setState(() => _photoSending = true);
    final r = await GroupService.send(_g.id, pick.caption, replyTo: _replyTo?.id ?? 0, media: pick.base64);
    if (!mounted) return;
    setState(() => _photoSending = false);
    if (r.ok) {
      setState(() => _replyTo = null);
      if (!_isStaff && !_g.isDm && _slowSecs > 0) _startSlow(_slowSecs);
      await _poll();
      _jumpToEnd();
      return;
    }
    if (r.error == 'g_slowmode') _startSlow(int.tryParse('${r.raw?['wait']}') ?? _slowSecs);
    if (r.error == 'no_name' || r.error == 'not_registered') {
      askGroupProfile(context);
      return;
    }
    gToast(context, r.text.isEmpty ? GT.t('photo_failed') : r.text);
  }

  void _viewImage(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: Center(child: Image.network(url, headers: GroupService.imageHeaders, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  Widget _imageView(GroupMessage m) {
    final url = GroupService.mediaUrl(_g.id, m.mediaId);
    final w = MediaQuery.of(context).size.width * 0.62;
    final h = w * 0.75;
    return GestureDetector(
      onTap: () => _viewImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          headers: GroupService.imageHeaders,
          width: w,
          height: h,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, p) => p == null ? child : SizedBox(width: w, height: h, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: gGold))),
          errorBuilder: (_, __, ___) => SizedBox(width: w, height: 80, child: const Center(child: Icon(Icons.broken_image_rounded, color: gMuted))),
        ),
      ),
    );
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
    // نام/عکس/تنظیمات ممکن است در صفحهٔ اطلاعات عوض شده باشد
    final fresh = await GroupService.info(id: _g.id);
    final ng = fresh.group;
    if (mounted && fresh.ok && ng != null) {
      setState(() {
        _g = ng;
        _slowSecs = ng.slowSecs;
        _onlyAdmins = ng.onlyAdmins;
      });
    }
  }

  // ---------- واکنش (خوش‌بینانه: اول روی صفحه، بعد سرور) ----------
  Future<void> _react(GroupMessage m, String emoji) async {
    final idx = _messages.indexWhere((x) => x.id == m.id);
    if (idx < 0) return;
    final cur = _messages[idx];
    final next = Map<String, int>.from(cur.reactions);
    void dec(String e) {
      final n = (next[e] ?? 0) - 1;
      if (n <= 0) {
        next.remove(e);
      } else {
        next[e] = n;
      }
    }

    var mine = cur.myReaction;
    if (mine == emoji) {
      dec(emoji);
      mine = '';
    } else {
      if (mine.isNotEmpty) dec(mine);
      next[emoji] = (next[emoji] ?? 0) + 1;
      mine = emoji;
    }
    setState(() => _messages[idx] = cur.copyWith(reactions: next, myReaction: mine));
    final r = await GroupService.react(_g.id, m.id, emoji);
    if (!mounted) return;
    if (!r.ok) {
      gToast(context, r.text);
      _poll(force: true);
    }
  }

  Future<void> _pin(GroupMessage? m) async {
    final r = await GroupService.pin(_g.id, m?.id ?? 0);
    if (!mounted) return;
    if (!r.ok) {
      gToast(context, r.text);
      return;
    }
    _poll(force: true);
  }

  Future<void> _deleteMessage(GroupMessage m) async {
    final ok = await GroupService.hideMessage(_g.id, m.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _messages.removeWhere((x) => x.id == m.id);
        if (_replyTo?.id == m.id) _replyTo = null;
        if (_pinned?.id == m.id) _pinned = null;
      });
    } else {
      gToast(context, GT.t('op_failed'));
    }
  }

  Future<void> _messageMenu(GroupMessage m) async {
    final canDelete = _g.isDm ? m.mine : (m.mine || _isStaff);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: gPanel,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final e in _kEmojis)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(ctx).pop('r:$e'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: m.myReaction == e ? gGold.withValues(alpha: 0.25) : Colors.transparent),
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                ]),
              ),
              const Divider(color: gLine, height: 12),
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: gGold),
                title: Text(GT.t('reply'), style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('reply'),
              ),
              if (m.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: gGold),
                  title: Text(GT.t('copy_text'), style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(ctx).pop('copy'),
                ),
              if (_isStaff)
                ListTile(
                  leading: const Icon(Icons.push_pin_rounded, color: gGold),
                  title: Text(GT.t(_pinned?.id == m.id ? 'unpin' : 'pin'), style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(ctx).pop(_pinned?.id == m.id ? 'unpin' : 'pin'),
                ),
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
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xffff8f8f)),
                  title: Text(GT.t('delete_msg'), style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(ctx).pop('delete'),
                ),
            ]),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action.startsWith('r:')) {
      await _react(m, action.substring(2));
    } else if (action == 'reply') {
      setState(() => _replyTo = m);
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.text));
      if (mounted) gToast(context, GT.t('copied'));
    } else if (action == 'pin') {
      await _pin(m);
    } else if (action == 'unpin') {
      await _pin(null);
    } else if (action == 'user') {
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
    } else if (action == 'delete') {
      await _deleteMessage(m);
    }
  }

  // ---------- اجزای صفحه ----------
  Widget _replyQuote(GroupMessage m) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: const BorderDirectional(start: BorderSide(color: gGold, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (m.replyName.isNotEmpty) Text(m.replyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: gGold, fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(
            m.replyText.isEmpty ? GT.t('reply_deleted') : m.replyText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ]),
      );

  Widget _reactionRow(GroupMessage m) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(spacing: 5, runSpacing: 5, children: [
          for (final e in m.reactions.entries)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _react(m, e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: m.myReaction == e.key ? gGold.withValues(alpha: 0.22) : Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: m.myReaction == e.key ? gGold : gLine),
                ),
                child: Text('${e.key} ${e.value}', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              ),
            ),
        ]),
      );

  Widget _bubble(GroupMessage m) {
    final mine = m.mine;
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onLongPress: () => _messageMenu(m),
        onDoubleTap: () => _react(m, '❤️'),
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
            if (m.replyId > 0) _replyQuote(m),
            if (m.isImage) _imageView(m),
            if (m.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: m.isImage ? 6 : 0),
                child: LinkifiedText(text: m.text, allowExternal: _linksMode == 'all', style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.8)),
              ),
            if (m.reactions.isNotEmpty) _reactionRow(m),
            Text(gTime(m.at), style: const TextStyle(color: gMuted, fontSize: 10.5)),
          ]),
        ),
      ),
    );
  }

  Widget _pinnedBanner() {
    final p = _pinned;
    if (p == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: gGold.withValues(alpha: 0.4))),
      child: Row(children: [
        const Icon(Icons.push_pin_rounded, color: gGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GT.t('pinned_label'), style: const TextStyle(color: gGold, fontSize: 11, fontWeight: FontWeight.w800)),
            Text('${p.name.isEmpty ? '' : '${p.name}: '}${p.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ]),
        ),
        if (_isStaff) IconButton(visualDensity: VisualDensity.compact, onPressed: () => _pin(null), icon: const Icon(Icons.close_rounded, color: gMuted, size: 18)),
      ]),
    );
  }

  Widget _replyBar() {
    final r = _replyTo;
    if (r == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: gPanel,
        borderRadius: BorderRadius.circular(12),
        border: const BorderDirectional(start: BorderSide(color: gGold, width: 3)),
      ),
      child: Row(children: [
        const Icon(Icons.reply_rounded, color: gGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(GT.t('replying_to', {'name': r.mine ? GT.t('you') : r.name}), style: const TextStyle(color: gGold, fontSize: 11.5, fontWeight: FontWeight.w800)),
            Text(r.text.isEmpty && r.isImage ? GT.t('photo_msg') : r.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ]),
        ),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() => _replyTo = null), icon: const Icon(Icons.close_rounded, color: gMuted, size: 18)),
      ]),
    );
  }

  String _slowText(int s) => s < 60 ? GT.t('slow_n_sec', {'n': '$s'}) : GT.t('slow_n_min', {'n': '${s ~/ 60}'});

  Widget _inputArea() {
    if (!_g.isDm && _onlyAdmins && !_isStaff) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
        child: Text(GT.t('admins_only_notice'), textAlign: TextAlign.center, style: const TextStyle(color: gMuted, fontSize: 12.5)),
      );
    }
    final slowOn = !_g.isDm && _slowSecs > 0 && !_isStaff;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _replyBar(),
      if (slowOn)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(GT.t('slow_hint', {'t': _slowText(_slowSecs)}), style: const TextStyle(color: gMuted, fontSize: 11)),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(children: [
          if (_mediaOk)
            _photoSending
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: gGold)))
                : IconButton(tooltip: GT.t('attach_photo'), onPressed: _slowLeft > 0 ? null : _sendPhoto, icon: const Icon(Icons.photo_camera_rounded, color: gGold)),
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
              onPressed: (_sending || _slowLeft > 0) ? null : _send,
              child: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_slowLeft > 0 ? '$_slowLeft' : GT.t('send'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    ]);
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
            if (!_g.isDm) IconButton(onPressed: _openInfo, icon: const Icon(Icons.info_outline_rounded, color: gGold)),
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
            _pinnedBanner(),
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
            _inputArea(),
          ]),
        ),
      ),
    );
  }
}
