import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../pages/profile/badge_page.dart';
import '../../services/story_service.dart';
import '../../services/user_profile_service.dart';
import 'story_composer_page.dart';
import 'story_viewer_page.dart';

const Color _gold = Color(0xffffd36a);

/// ردیف استوری بالای جستجوی صفحهٔ اصلی (مثل واتساپ).
/// همه می‌بینند؛ فقط دارندگان تیک آبی/طلایی می‌توانند استوری بگذارند.
/// اگر ارتباط با سرور نباشد، این ردیف نمایش داده نمی‌شود.
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<StoryGroup>? _groups;
  StoryMe? _me;
  Set<int> _seen = {};
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      StoryService.fetch(),
      StoryService.me(),
      StoryService.seen(),
      UserProfileService.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _groups = results[0] as List<StoryGroup>?;
      _me = results[1] as StoryMe?;
      _seen = results[2] as Set<int>;
      _profile = results[3] as UserProfile?;
    });
  }

  List<Color> _ring(StoryGroup g) {
    if (g.stories.every((s) => _seen.contains(s.id))) return const [Color(0xff3a4a57), Color(0xff3a4a57)];
    return g.badge == 'gold'
        ? const [Color(0xffffc233), Color(0xffff8a3d)]
        : const [Color(0xff2a8cff), Color(0xff66d9ff)];
  }

  Future<void> _open(List<StoryGroup> list, int index) async {
    final changed = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (c, a, b) => FadeTransition(opacity: a, child: StoryViewerPage(groups: list, initial: index)),
      ),
    );
    if (changed == true || mounted) _load();
  }

  Future<void> _compose() async {
    final me = _me;
    if (me == null || !me.canPost) {
      _needBadge();
      return;
    }
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const StoryComposerPage()));
    if (ok == true) _load();
  }

  void _needBadge() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff0e2433),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_rounded, color: Color(0xff2a8cff), size: 44),
            const SizedBox(height: 10),
            Text(NT.t('st_need_title'), textAlign: TextAlign.center, style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(NT.t('st_need_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: const Color(0xff06121d), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgePage()));
                },
                child: Text(NT.t('st_get_badge'), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _avatar(ImageProvider? img, double r) => CircleAvatar(
        radius: r,
        backgroundColor: const Color(0xff102733),
        backgroundImage: img,
        child: img == null ? Icon(Icons.person_rounded, color: _gold, size: r) : null,
      );

  Widget _item({required Widget avatar, required String label, required List<Color> ring, required VoidCallback onTap, Widget? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ring)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                child: avatar,
              ),
            ),
            if (badge != null) PositionedDirectional(end: -2, bottom: -2, child: badge),
          ]),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups == null) return const SizedBox.shrink();
    StoryGroup? mine;
    for (final g in groups) {
      if (g.mine) mine = g;
    }
    final others = groups.where((g) => !g.mine).toList();
    final ordered = [if (mine != null) mine, ...others];

    ImageProvider? myPhoto;
    final pb = _profile?.photoBase64 ?? '';
    if (pb.isNotEmpty) {
      try {
        myPhoto = MemoryImage(base64Decode(pb));
      } catch (_) {}
    }

    final plus = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _gold, border: Border.all(color: Colors.black, width: 2)),
      child: const Icon(Icons.add_rounded, size: 16, color: Color(0xff06121d)),
    );

    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          children: [
            _item(
              avatar: _avatar(myPhoto, 26),
              label: NT.t('st_you'),
              ring: mine != null ? _ring(mine) : const [Color(0xff3a4a57), Color(0xff3a4a57)],
              badge: GestureDetector(onTap: _compose, child: plus),
              onTap: () => mine != null ? _open(ordered, 0) : _compose(),
            ),
            for (var i = 0; i < others.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: _item(
                  avatar: _avatar(others[i].hasPhoto ? NetworkImage(StoryService.photoUrl(others[i].uid)) : null, 26),
                  label: others[i].name,
                  ring: _ring(others[i]),
                  badge: others[i].badge == null
                      ? null
                      : Icon(Icons.verified_rounded, size: 19, color: others[i].badge == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
                  onTap: () => _open(ordered, (mine != null ? 1 : 0) + i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
