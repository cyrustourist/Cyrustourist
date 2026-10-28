import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../services/badge_service.dart';
import '../../services/call_service.dart';
import '../../services/call_texts.dart';
import '../../services/friends_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../profile/my_profile_page.dart';
import '../profile/public_profile_page.dart';
import 'group_chat_page.dart';

const Color gBg = Color(0xff06121d);
const Color gPanel = Color(0xff0b2636);
const Color gGold = Color(0xffffd36a);
const Color gLine = Color(0xff1d3a4d);
const Color gMuted = Color(0xff8fa5b2);
const Color gTeal = Color(0xff29e0ad);
const Color gSky = Color(0xff66d9ff);

/// جهت متن: فارسی و عربی راست‌به‌چپ، بقیه چپ‌به‌راست.
TextDirection get gDir => (MenuLanguage.current == 'fa' || MenuLanguage.current == 'ar') ? TextDirection.rtl : TextDirection.ltr;

void gToast(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Widget gTick(String? badge) {
  if (badge == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsetsDirectional.only(start: 3),
    child: Icon(Icons.verified_rounded, size: 14, color: badge == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
  );
}

String gTime(DateTime? t) {
  if (t == null) return '';
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// دایرهٔ حرف اول نام (گروه یا کاربر).
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.name, this.isGroup = false, this.size = 46});

  final String name;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final letter = t.isEmpty ? '?' : String.fromCharCode(t.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gGold.withValues(alpha: 0.14),
        border: Border.all(color: gGold.withValues(alpha: 0.6), width: 1.2),
      ),
      child: isGroup && t.isEmpty
          ? Icon(Icons.groups_rounded, color: gGold, size: size * 0.5)
          : Text(letter, style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: size * 0.42)),
    );
  }
}

/// ردیف یک گروه یا گفتگوی شخصی در لیست‌ها.
class GroupTile extends StatelessWidget {
  const GroupTile({super.key, required this.group, required this.onTap, this.unread = false, this.trailing});

  final GroupInfo group;
  final VoidCallback onTap;
  final bool unread;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final sub = g.isDm
        ? ''
        : '${g.isPublic ? GT.t('kind_public') : GT.t('kind_private')} · ${GT.t('members_n', {'n': '${g.memberCount}'})}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GroupAvatar(name: g.title, isGroup: !g.isDm),
        title: Row(children: [
          Flexible(child: Text(g.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          if (!g.isDm && !g.isPublic) const Padding(padding: EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.lock_rounded, size: 14, color: gMuted)),
        ]),
        subtitle: sub.isEmpty
            ? null
            : Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: gMuted, fontSize: 12)),
        trailing: trailing ??
            (unread
                ? Container(width: 11, height: 11, decoration: const BoxDecoration(color: gGold, shape: BoxShape.circle))
                : null),
      ),
    );
  }
}

/// برای ارسال پیام لازم است پروفایل نام داشته باشد.
void askGroupProfile(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: gPanel,
      title: Text(GT.t('need_profile_title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
      content: Text(GT.t('need_profile_body'), style: const TextStyle(color: Colors.white, height: 1.9)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(GT.t('later'), style: const TextStyle(color: Colors.white70))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
          },
          child: Text(GT.t('go_profile')),
        ),
      ],
    ),
  );
}

/// بازکردن (یا ساخت) گفتگوی شخصی با یک کاربر و رفتن به صفحهٔ چت.
Future<void> openDm(BuildContext context, String uid) async {
  final r = await GroupService.dmOpen(uid);
  if (!context.mounted) return;
  final g = r.group;
  if (!r.ok || g == null) {
    if (r.error == 'no_name' || r.error == 'not_registered') {
      askGroupProfile(context);
      return;
    }
    gToast(context, r.text);
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupChatPage(group: g)));
}

Widget _sheetAction(IconData icon, String label, Color color, VoidCallback? onTap) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withValues(alpha: 0.16),
          shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.3)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 54, height: 54, child: Icon(icon, color: color, size: 25)),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 74,
          child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ),
      ],
    );

/// با لمس نام یک کاربر در گروه: تماس صوتی، تماس تصویری، افزودن به دوستان و پیام شخصی.
Future<void> showUserSheet(
  BuildContext context, {
  required String uid,
  required String name,
  String? badge,
  bool allowMessage = true,
  List<Widget> extra = const [],
}) async {
  if (uid.isEmpty) return;
  final me = await BadgeService.userUid();
  if (me == uid || !context.mounted) return;
  var isFriend = await FriendsService.isFriend(uid);
  if (!context.mounted) return;
  var adding = false;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: gPanel,
    showDragHandle: true,
    builder: (ctx) => Directionality(
      textDirection: gDir,
      child: StatefulBuilder(
        builder: (ctx, setSt) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GroupAvatar(name: name, size: 60),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))),
                gTick(badge),
              ]),
              const SizedBox(height: 14),
              Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 12, children: [
                _sheetAction(Icons.call_rounded, CT.t('profile_call'), const Color(0xff2fb36a), () {
                  Navigator.of(ctx).pop();
                  CallService.instance.startOutgoing(toUid: uid, name: name, isFriend: isFriend);
                }),
                _sheetAction(Icons.videocam_rounded, CT.t('profile_video'), gSky, () {
                  Navigator.of(ctx).pop();
                  CallService.instance.startOutgoing(toUid: uid, name: name, isFriend: isFriend, video: true);
                }),
                isFriend
                    ? _sheetAction(Icons.check_circle_rounded, CT.t('in_friends'), gTeal, null)
                    : _sheetAction(Icons.person_add_alt_1_rounded, CT.t('add_to_friends'), gGold, adding
                        ? null
                        : () async {
                            setSt(() => adding = true);
                            final r = await FriendsService.add(friendUid: uid);
                            if (!ctx.mounted) return;
                            setSt(() {
                              adding = false;
                              if (r.ok) isFriend = true;
                            });
                            gToast(ctx, r.ok ? CT.t(r.raw?['already'] == true ? 'friend_exists' : 'friend_added', {'name': name}) : (r.needsProfile ? CT.t('need_profile') : r.text));
                          }),
                if (allowMessage)
                  _sheetAction(Icons.chat_bubble_rounded, GT.t('dm_btn'), const Color(0xffff5fb0), () {
                    Navigator.of(ctx).pop();
                    openDm(context, uid);
                  }),
              ]),
              const SizedBox(height: 6),
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_rounded, color: gGold),
                title: Text(GT.t('user_card_profile'), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfilePage(uid: uid, name: name)));
                },
              ),
              ...extra,
            ]),
          ),
        ),
      ),
    ),
  );
}
