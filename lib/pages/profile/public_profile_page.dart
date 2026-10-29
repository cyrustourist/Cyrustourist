import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/badge_service.dart';
import '../../services/call_service.dart';
import '../../services/call_session.dart';
import '../../services/call_texts.dart';
import '../../services/chat_service.dart';
import '../../services/friends_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../groups/group_ui.dart' show openDm;
import '../../services/public_profile_service.dart';
import '../../widgets/linkified_text.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _sky = Color(0xff66d9ff);
const Color _green = Color(0xff2fb36a);
const Color _pink = Color(0xffff5fb0);
const Color _red = Color(0xffff8f8f);

/// پروفایل کاربران (مثل تلگرام): عکس بزرگ، نام، آخرین بازدید، دکمه‌های پیام/تماس/ویدیو/بی‌صدا،
/// افزودن به دوستان، شناسه و توضیحات و بخش لینک‌ها. از لمس نام یا عکس کاربر در همه‌جا باز می‌شود.
/// «همگانی» دیده می‌شود، «دوستان» و «هیچ‌کس» بسته است.
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  PublicProfile? _p;
  bool _loading = true;
  String _me = '';
  bool _isFriend = false;
  bool _addingFriend = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    unawaited(CallSession.prefetchIce());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await PublicProfileService.fetch(widget.uid);
    final me = await BadgeService.userUid();
    final friend = me == widget.uid ? false : await FriendsService.isFriend(widget.uid);
    final muted = await GroupPush.isMuted(widget.uid);
    if (!mounted) return;
    setState(() {
      _p = p;
      _me = me;
      _isFriend = friend;
      _muted = muted;
      _loading = false;
    });
  }

  String get _name => _p?.name.isNotEmpty == true ? _p!.name : widget.name;
  bool get _isOther => _me.isNotEmpty && _me != widget.uid;

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addFriend() async {
    if (_addingFriend) return;
    setState(() => _addingFriend = true);
    final r = await FriendsService.add(friendUid: widget.uid);
    if (!mounted) return;
    setState(() {
      _addingFriend = false;
      if (r.ok) _isFriend = true;
    });
    if (r.ok) {
      _toast(CT.t(r.raw?['already'] == true ? 'friend_exists' : 'friend_added', {'name': _name}));
    } else {
      _toast(r.needsProfile ? CT.t('need_profile') : r.text);
    }
  }

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          content: Text(text, style: const TextStyle(color: Colors.white, height: 1.8)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(GT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(GT.t('confirm')),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _removeFriend() async {
    if (!await _confirm(GT.t('pp_remove_confirm', {'name': _name}))) return;
    final r = await FriendsService.remove(widget.uid);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _isFriend = false);
      _toast(CT.t('friend_removed'));
    } else {
      _toast(r.text);
    }
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await GroupPush.setMuted(widget.uid, next);
    if (!mounted) return;
    setState(() => _muted = next);
    _toast(GT.t(next ? 'pp_muted_done' : 'pp_unmuted_done', {'name': _name}));
  }

  Future<void> _blockInChat() async {
    if (!await _confirm(GT.t('pp_block_confirm', {'name': _name}))) return;
    final ok = await ChatService.block(widget.uid);
    if (!mounted) return;
    _toast(ok ? GT.t('pp_block_done', {'name': _name}) : GT.t('op_failed'));
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast(GT.t('pp_copied'));
  }

  void _viewPhoto(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(child: Center(child: Image.memory(bytes, fit: BoxFit.contain))),
        ),
      ),
    );
  }

  // ---------- اجزای صفحه ----------
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String first(String s) => String.fromCharCode(s.runes.first);
    if (parts.length == 1) return first(parts[0]).toUpperCase();
    return (first(parts[0]) + first(parts[1])).toUpperCase();
  }

  Widget _avatar(PublicProfile p, Uint8List? photo) {
    const size = 124.0;
    final has = p.visible && photo != null;
    final Widget core = has
        ? Image.memory(photo!, fit: BoxFit.cover, width: size, height: size)
        : Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xff4aa8ff), Color(0xff2f6fc0)]),
            ),
            child: Text(_initials(p.name), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800)),
          );
    return GestureDetector(
      onTap: has ? () => _viewPhoto(photo!) : null,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gold, width: 2),
          boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 26)],
        ),
        child: ClipOval(child: core),
      ),
    );
  }

  Widget _tick(String? b) => b == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: Icon(Icons.verified_rounded, size: 22, color: b == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
        );

  String? _lastSeenText(PublicProfile p) {
    switch (p.lastSeen) {
      case 'recently':
        return GT.t('ls_recently');
      case 'week':
        return GT.t('ls_week');
      case 'month':
        return GT.t('ls_month');
      case 'long':
        return GT.t('ls_long');
      default:
        return null;
    }
  }

  /// کاشی عمل (مثل تلگرام): آیکن بالا، نوشته پایین. کاشی اصلی (پیام) پر رنگ است.
  Widget _tile(IconData icon, String label, Color color, VoidCallback? onTap, {bool filled = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: filled ? _gold : _card,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: filled ? _gold : color.withValues(alpha: 0.35)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: filled ? _bg : color, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: filled ? _bg : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions() => Row(children: [
        _tile(Icons.chat_bubble_rounded, GT.t('dm_btn'), _pink, () => openDm(context, widget.uid), filled: true),
        _tile(Icons.call_rounded, CT.t('profile_call'), _green, () {
          CallService.instance.startOutgoing(toUid: widget.uid, name: _name, isFriend: _isFriend);
        }),
        _tile(Icons.videocam_rounded, CT.t('profile_video'), _sky, () {
          CallService.instance.startOutgoing(toUid: widget.uid, name: _name, isFriend: _isFriend, video: true);
        }),
        _tile(_muted ? Icons.notifications_off_rounded : Icons.notifications_rounded, GT.t(_muted ? 'pp_unmute' : 'pp_mute'), _gold, _toggleMute),
      ]);

  Widget _friendRow() {
    final Widget row = _isFriend
        ? Row(children: [
            const Icon(Icons.check_circle_rounded, color: _teal),
            const SizedBox(width: 12),
            Expanded(child: Text(CT.t('in_friends'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            TextButton(onPressed: _removeFriend, child: Text(CT.t('remove_friend'), style: const TextStyle(color: _red))),
          ])
        : Row(children: [
            _addingFriend
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                : const Icon(Icons.person_add_alt_1_rounded, color: _gold),
            const SizedBox(width: 12),
            Expanded(child: Text(CT.t('add_to_friends'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ]);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _isFriend ? _teal.withValues(alpha: 0.35) : _gold.withValues(alpha: 0.3))),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isFriend || _addingFriend ? null : _addFriend,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: row),
      ),
    );
  }

  /// یک ردیف اطلاعات: عنوان کوچک بالا، مقدار پایین (مثل کارت شمارهٔ تلگرام).
  Widget _infoRow(IconData icon, Color color, String label, Widget value, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                value,
                const SizedBox(height: 3),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      );

  Widget _infoCard(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) children.add(const Divider(height: 1, color: Colors.white10, indent: 50));
      children.add(rows[i]);
    }
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold.withValues(alpha: 0.18))),
      child: Column(children: children),
    );
  }

  Widget _linksSection(PublicProfile p) => Column(children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(color: _gold.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold.withValues(alpha: 0.4))),
          child: Text(GT.t('pp_links'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold.withValues(alpha: 0.18))),
          child: p.videoLink.isEmpty
              ? Center(child: Text(GT.t('pp_no_links'), style: const TextStyle(color: Colors.white38)))
              : Row(children: [
                  const Icon(Icons.play_circle_fill_rounded, color: _teal),
                  const SizedBox(width: 10),
                  Expanded(child: LinkifiedText(text: p.videoLink, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  IconButton(
                    tooltip: NT.t('copy_link'),
                    icon: const Icon(Icons.copy_rounded, color: _teal, size: 20),
                    onPressed: () => _copy(p.videoLink),
                  ),
                ]),
        ),
      ]);

  Widget _closed(String text) => Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(children: [
          Icon(Icons.lock_rounded, size: 46, color: _gold.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8)),
        ]),
      );

  Widget _body() {
    final p = _p;
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (p == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(NT.t('pp_fail'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _load, child: Text(NT.t('retry'), style: const TextStyle(color: _gold))),
        ]),
      );
    }
    Uint8List? photo;
    if (p.photoData.isNotEmpty) {
      try {
        photo = base64Decode(p.photoData);
      } catch (_) {}
    }
    final seen = p.visible ? _lastSeenText(p) : null;
    final infoRows = <Widget>[
      if (p.username.isNotEmpty)
        _infoRow(Icons.alternate_email_rounded, _teal, GT.t('pp_id'), Text('@${p.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 15.5)), onTap: () => _copy(p.username)),
      if (p.bio.isNotEmpty)
        _infoRow(Icons.info_outline_rounded, _gold, NT.t('about'), Text(p.bio, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.7))),
      if (p.city.isNotEmpty)
        _infoRow(Icons.location_city_rounded, _sky, NT.t('city'), Text(p.city, style: const TextStyle(color: Colors.white, fontSize: 14.5))),
    ];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 56, 16, 32), children: [
      Center(child: _avatar(p, photo)),
      const SizedBox(height: 14),
      Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(p.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
          _tick(p.badge),
        ]),
      ),
      if (seen != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(child: Text(seen, style: const TextStyle(color: Colors.white54, fontSize: 13.5))),
        ),
      if (_isOther) ...[
        const SizedBox(height: 20),
        _actions(),
        _friendRow(),
      ],
      if (!p.visible)
        _closed(p.visibility == 'friends' ? NT.t('pp_friends') : NT.t('pp_none'))
      else ...[
        if (infoRows.isNotEmpty) _infoCard(infoRows),
        _linksSection(p),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: _gold),
          actions: [
            if (p != null && _isOther)
              PopupMenuButton<String>(
                color: _card,
                iconColor: _gold,
                onSelected: (v) {
                  if (v == 'copy' && p.username.isNotEmpty) _copy(p.username);
                  if (v == 'block') _blockInChat();
                },
                itemBuilder: (_) => [
                  if (p.visible && p.username.isNotEmpty)
                    PopupMenuItem<String>(value: 'copy', child: Text(GT.t('pp_copy_id'), style: const TextStyle(color: Colors.white))),
                  PopupMenuItem<String>(value: 'block', child: Text(GT.t('pp_block_chat'), style: const TextStyle(color: _red))),
                ],
              ),
          ],
        ),
        body: Stack(children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xff123a50), _bg]),
            ),
          ),
          SafeArea(child: _body()),
        ]),
      ),
    );
  }
}
