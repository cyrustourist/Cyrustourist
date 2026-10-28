import 'package:flutter/material.dart';

import '../../main.dart' show navigatorKey;
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import 'group_chat_page.dart';
import 'group_ui.dart';

/// ورودی‌های بیرونی به گروه‌ها: لینک دعوت (cyrustourist.ir/group/<کد>) و لمس اعلان پیام شخصی.
class GroupInvite {
  GroupInvite._();

  /// لینک دعوت: اطلاعات گروه را نشان می‌دهد و با تأیید کاربر عضو می‌کند.
  static Future<void> openInvite(String code) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final r = await GroupService.info(invite: code);
    final c2 = navigatorKey.currentContext;
    if (c2 == null || !c2.mounted) return;
    final g = r.group;
    if (!r.ok || g == null) {
      gToast(c2, r.error == 'net' ? GT.t('net') : GT.t('invite_bad'));
      return;
    }
    if (g.isMember) {
      Navigator.of(c2).push(MaterialPageRoute(builder: (_) => GroupChatPage(group: g)));
      return;
    }
    await showModalBottomSheet<void>(
      context: c2,
      backgroundColor: gPanel,
      showDragHandle: true,
      builder: (sheet) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(GT.t('invite_title'), style: const TextStyle(color: gMuted, fontSize: 12.5)),
              const SizedBox(height: 10),
              GroupAvatar(name: g.name, isGroup: true, size: 64),
              const SizedBox(height: 8),
              Text(g.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                '${g.isPublic ? GT.t('kind_public') : GT.t('kind_private')} · ${GT.t('members_n', {'n': '${g.memberCount}'})}',
                style: const TextStyle(color: gMuted),
              ),
              if (g.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(g.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.7)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  Navigator.of(sheet).pop();
                  final j = await GroupService.join(invite: code);
                  final c3 = navigatorKey.currentContext;
                  if (c3 == null || !c3.mounted) return;
                  if (!j.ok) {
                    if (j.error == 'no_name' || j.error == 'not_registered') {
                      askGroupProfile(c3);
                    } else {
                      gToast(c3, j.text);
                    }
                    return;
                  }
                  if (j.status == 'pending') {
                    gToast(c3, GT.t('pending_wait'));
                    return;
                  }
                  gToast(c3, GT.t('joined_ok'));
                  Navigator.of(c3).push(MaterialPageRoute(builder: (_) => GroupChatPage(group: j.group ?? g)));
                },
                child: Text(GT.t('join'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// لمس اعلان پیام شخصی (یا بیدارباش گروه): گفتگو را با شناسه باز می‌کند.
  static Future<void> openById(int groupId) async {
    if (groupId <= 0) return;
    final m = await GroupService.mine();
    final ctx = navigatorKey.currentContext;
    if (!m.ok || ctx == null || !ctx.mounted) return;
    for (final g in m.groups) {
      if (g.id == groupId) {
        Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => GroupChatPage(group: g)));
        return;
      }
    }
  }
}
