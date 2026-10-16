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
import '../../services/friends_service.dart';
import '../../services/public_profile_service.dart';
import '../../widgets/linkified_text.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _sky = Color(0xff66d9ff);

/// پروفایل دیگران؛ از لمس نام در چت همگانی/همسفر باز می‌شود.
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
    if (!mounted) return;
    setState(() {
      _p = p;
      _me = me;
      _isFriend = friend;
      _loading = false;
    });
  }

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
      _toast(CT.t(r.raw?['already'] == true ? 'friend_exists' : 'friend_added', {'name': widget.name}));
    } else {
      _toast(r.needsProfile ? CT.t('need_profile') : r.text);
    }
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback? onTap) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color.withValues(alpha: 0.16),
            shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.3)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: 56, height: 56, child: Icon(icon, color: color, size: 26)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  /// تماس صوتی، تماس تصویری (به‌زودی) و افزودن به دوستان
  Widget _actions() => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _action(Icons.call_rounded, CT.t('profile_call'), const Color(0xff2fb36a), () {
              CallService.instance.startOutgoing(toUid: widget.uid, name: widget.name, isFriend: _isFriend);
            }),
            _action(Icons.videocam_rounded, CT.t('profile_video'), _sky, () => _toast(CT.t('video_soon'))),
            _isFriend
                ? _action(Icons.check_circle_rounded, CT.t('in_friends'), _teal, null)
                : _action(Icons.person_add_alt_1_rounded, CT.t('add_to_friends'), _gold, _addingFriend ? null : _addFriend),
          ],
        ),
      );

  Widget _tick(String? b) => b == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: Icon(Icons.verified_rounded, size: 24, color: b == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
        );

  Widget _info(IconData icon, String title, Widget child, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.22)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              child,
            ]),
          ),
        ]),
      );

  Widget _closed(String text) => Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(children: [
          Icon(Icons.lock_rounded, size: 46, color: _gold.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = _p;
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: _gold));
    } else if (p == null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(NT.t('pp_fail'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _load, child: Text(NT.t('retry'), style: const TextStyle(color: _gold))),
        ]),
      );
    } else {
      Uint8List? photo;
      if (p.photoData.isNotEmpty) {
        try {
          photo = base64Decode(p.photoData);
        } catch (_) {}
      }
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xff102733),
              backgroundImage: (p.visible && photo != null) ? MemoryImage(photo) : null,
              child: (p.visible && photo != null) ? null : const Icon(Icons.person_rounded, size: 54, color: _gold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
            _tick(p.badge),
          ]),
        ),
        if (p.visible && p.username.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('@${p.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        if (_me.isNotEmpty && _me != widget.uid) _actions(),
        const SizedBox(height: 18),
        if (!p.visible)
          _closed(p.visibility == 'friends' ? NT.t('pp_friends') : NT.t('pp_none'))
        else ...[
          if (p.bio.isNotEmpty)
            _info(Icons.info_outline_rounded, NT.t('about'), Text(p.bio, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.7)), _gold),
          if (p.city.isNotEmpty)
            _info(Icons.location_city_rounded, NT.t('city'), Text(p.city, style: const TextStyle(color: Colors.white, fontSize: 14)), _sky),
          if (p.videoLink.isNotEmpty)
            _info(
              Icons.play_circle_fill_rounded,
              NT.t('video_title'),
              Row(children: [
                Expanded(child: LinkifiedText(text: p.videoLink, style: const TextStyle(color: Colors.white, fontSize: 13))),
                IconButton(
                  tooltip: NT.t('copy_link'),
                  icon: const Icon(Icons.copy_rounded, color: _teal, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: p.videoLink));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(NT.t('copied'))));
                  },
                ),
              ]),
              _teal,
            ),
          if (p.bio.isEmpty && p.city.isEmpty && p.videoLink.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(NT.t('pp_empty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            ),
        ],
      ]);
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
          title: Text(widget.name, style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(child: body),
      ),
    );
  }
}
