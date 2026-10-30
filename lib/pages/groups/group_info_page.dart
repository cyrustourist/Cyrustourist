import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/friends_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import '../../widgets/share_sheet.dart';
import 'group_friend_picker.dart';
import 'group_photo.dart';
import 'group_ui.dart';

/// اطلاعات گروه، لینک دعوت، اعضا و مدیریت (مالک/مدیر). با pop مقدار 'left' یا 'deleted' برمی‌گرداند.
class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key, required this.group});

  final GroupInfo group;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late GroupInfo _g;
  GroupMembers _m = const GroupMembers(ok: false);
  bool _loading = true;
  bool _saving = false;
  bool _photoBusy = false;

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _user;
  bool _approval = false;
  int _slow = 0;
  bool _onlyAdmins = false;
  bool _public = true;
  int _retention = 24;

  @override
  void initState() {
    super.initState();
    _g = widget.group;
    _name = TextEditingController(text: _g.name);
    _desc = TextEditingController(text: _g.description);
    _user = TextEditingController(text: _g.username ?? '');
    _approval = _g.joinApproval;
    _slow = _g.slowSecs;
    _onlyAdmins = _g.onlyAdmins;
    _public = _g.isPublic;
    _retention = _g.retentionHours;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _user.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([GroupService.info(id: _g.id), GroupService.members(_g.id)]);
    if (!mounted) return;
    final info = results[0] as GroupResult;
    final mem = results[1] as GroupMembers;
    setState(() {
      final ng = info.group;
      if (info.ok && ng != null) {
        _g = ng;
        _approval = ng.joinApproval;
        _slow = ng.slowSecs;
        _onlyAdmins = ng.onlyAdmins;
        _public = ng.isPublic;
        _retention = ng.retentionHours;
      }
      _m = mem;
      _loading = false;
    });
  }

  Future<void> _changePhoto() async {
    if (_photoBusy) return;
    final b64 = await pickGroupPhoto(context);
    if (!mounted) return;
    if (b64 == null) {
      gToast(context, GT.t('photo_bad'));
      return;
    }
    setState(() => _photoBusy = true);
    final r = await GroupService.setPhoto(_g.id, b64);
    if (!mounted) return;
    final v = int.tryParse('${r.raw?['photo_v']}') ?? 0;
    setState(() {
      _photoBusy = false;
      if (r.ok && v > 0) _g = _g.withPhoto(v);
    });
    gToast(context, r.ok ? GT.t('saved') : r.text);
  }

  Future<void> _removePhoto() async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    final r = await GroupService.removePhoto(_g.id);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (r.ok) _g = _g.withPhoto(0);
    });
    gToast(context, r.ok ? GT.t('saved') : r.text);
  }

  Future<void> _photoMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: gPanel,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: gGold),
              title: Text(GT.t('photo_change'), style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop('change'),
            ),
            if (_g.photoV > 0)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xffff8f8f)),
                title: Text(GT.t('photo_remove'), style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
          ]),
        ),
      ),
    );
    if (action == 'change') {
      await _changePhoto();
    } else if (action == 'remove') {
      await _removePhoto();
    }
  }

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          content: Text(text, style: const TextStyle(color: Colors.white, height: 1.8)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(GT.t('cancel'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(GT.t('confirm')),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final r = await GroupService.update(
      _g.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      joinApproval: _approval,
      slowSecs: _slow,
      onlyAdmins: _onlyAdmins,
      kind: _g.isOwner ? (_public ? 'public' : 'private') : null,
      username: _g.isOwner && _public ? _user.text.trim() : null,
      retentionHours: _g.isOwner && !_g.retentionLocked ? _retention : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    gToast(context, r.ok ? GT.t('saved') : r.text);
    if (r.ok) _load();
  }

  Future<void> _addMembers() async {
    final exclude = <String>{..._m.members.map((x) => x.uid), ..._m.pending.map((x) => x.uid)};
    final picked = await Navigator.of(context).push<List<FriendItem>>(
      MaterialPageRoute(builder: (_) => GroupFriendPicker(excludeUids: exclude)),
    );
    if (!mounted || picked == null || picked.isEmpty) return;
    final r = await GroupService.addMembers(_g.id, picked.map((f) => f.uid).toList());
    if (!mounted) return;
    if (!r.ok) {
      gToast(context, r.text);
      return;
    }
    final added = int.tryParse('${r.raw?['added']}') ?? 0;
    final skipped = int.tryParse('${r.raw?['skipped']}') ?? 0;
    if (added == 0) {
      gToast(context, GT.t('members_none'));
    } else {
      final base = GT.t('members_added', {'n': '$added'});
      gToast(context, skipped > 0 ? '$base\n${GT.t('members_skipped')}' : base);
    }
    _load();
  }

  String _slowLabel(int s) {
    if (s <= 0) return GT.t('slow_off');
    if (s < 60) return GT.t('slow_n_sec', {'n': '$s'});
    return GT.t('slow_n_min', {'n': '${s ~/ 60}'});
  }

  Widget _addMembersButton() => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _addMembers,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(GT.t('add_members'), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );

  Future<void> _resetInvite() async {
    if (!await _confirm(GT.t('reset_link_confirm'))) return;
    final code = await GroupService.resetInvite(_g.id);
    if (!mounted) return;
    if (code == null) {
      gToast(context, GT.t('op_failed'));
      return;
    }
    _load();
  }

  Future<void> _manage(GroupMember m, String action) async {
    final r = await GroupService.manage(_g.id, m.uid, action);
    if (!mounted) return;
    if (!r.ok) gToast(context, r.text);
    _load();
  }

  Future<void> _leave() async {
    if (!await _confirm(GT.t('leave_confirm'))) return;
    final r = await GroupService.leave(_g.id);
    if (!mounted) return;
    if (r.ok) {
      gToast(context, GT.t('left_ok'));
      Navigator.of(context).pop('left');
    } else {
      gToast(context, r.text);
    }
  }

  Future<void> _delete() async {
    if (!await _confirm(GT.t('delete_confirm'))) return;
    final r = await GroupService.deleteGroup(_g.id);
    if (!mounted) return;
    if (r.ok) {
      gToast(context, GT.t('group_deleted'));
      Navigator.of(context).pop('deleted');
    } else {
      gToast(context, r.text);
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: gMuted),
        hintStyle: const TextStyle(color: gMuted, fontSize: 12),
        filled: true,
        fillColor: gPanel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gLine)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gLine)),
      );

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: gPanel.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18), border: Border.all(color: gLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 10),
          ...children,
        ]),
      );

  Widget _inviteSection() {
    final url = _g.inviteUrl;
    if (url == null) return const SizedBox.shrink();
    return _section(GT.t('invite_link'), [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: gLine)),
        child: SelectableText(url, textDirection: TextDirection.ltr, style: const TextStyle(color: gSky, fontSize: 12.5)),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (mounted) gToast(context, GT.t('link_copied'));
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(GT.t('copy_link')),
        ),
        OutlinedButton.icon(
          onPressed: () => ShareSheet.showLink(
            context,
            url: url,
            title: _g.name,
            heading: GT.t('invite_link'),
            shareText: GT.t('invite_share_text', {'name': _g.name, 'url': url}),
          ),
          icon: const Icon(Icons.share_rounded, size: 18),
          label: Text(GT.t('share_link')),
        ),
        OutlinedButton.icon(onPressed: _resetInvite, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(GT.t('reset_link'))),
      ]),
    ]);
  }

  Widget _editSection() {
    final owner = _g.isOwner;
    final options = _g.ttlOptions.isNotEmpty ? _g.ttlOptions : <int>[_retention];
    final value = options.contains(_retention) ? _retention : options.last;
    return _section(GT.t('info_title'), [
      TextField(controller: _name, maxLength: 60, style: const TextStyle(color: Colors.white), decoration: _dec(GT.t('form_name'))),
      const SizedBox(height: 4),
      TextField(controller: _desc, maxLength: 200, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: _dec(GT.t('form_desc'))),
      if (owner) ...[
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(value: true, label: Text(GT.t('kind_public')), icon: const Icon(Icons.public_rounded)),
            ButtonSegment<bool>(value: false, label: Text(GT.t('kind_private')), icon: const Icon(Icons.lock_rounded)),
          ],
          selected: {_public},
          onSelectionChanged: (s) => setState(() => _public = s.first),
        ),
        const SizedBox(height: 4),
        Text(GT.t(_public ? 'kind_public_hint' : 'kind_private_hint'), style: const TextStyle(color: gMuted, fontSize: 12)),
        if (_public) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _user,
            maxLength: 32,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: _dec(GT.t('form_username'), hint: GT.t('form_username_hint')),
          ),
        ],
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: gGold,
        value: _approval,
        onChanged: (v) => setState(() => _approval = v),
        title: Text(GT.t('form_approval'), style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: gGold,
        value: _onlyAdmins,
        onChanged: (v) => setState(() => _onlyAdmins = v),
        title: Text(GT.t('admins_only'), style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      Row(children: [
        Expanded(child: Text(GT.t('slow_mode'), style: const TextStyle(color: Colors.white, fontSize: 14))),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: const [0, 10, 30, 60, 300, 900].contains(_slow) ? _slow : 0,
            dropdownColor: gPanel,
            iconEnabledColor: gGold,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            items: [for (final o in const [0, 10, 30, 60, 300, 900]) DropdownMenuItem<int>(value: o, child: Text(_slowLabel(o)))],
            onChanged: (v) => setState(() => _slow = v ?? 0),
          ),
        ),
      ]),
      if (owner)
        Row(children: [
          Expanded(child: Text(GT.t('form_retention'), style: const TextStyle(color: Colors.white, fontSize: 14))),
          if (_g.retentionLocked)
            Flexible(child: Text(GT.t('locked_retention'), style: const TextStyle(color: gMuted, fontSize: 11.5)))
          else
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                dropdownColor: gPanel,
                iconEnabledColor: gGold,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                items: [for (final o in options) DropdownMenuItem<int>(value: o, child: Text(GT.hours(o)))],
                onChanged: (v) => setState(() => _retention = v ?? _retention),
              ),
            ),
        ]),
      const SizedBox(height: 8),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(46)),
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(GT.t('form_save'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    ]);
  }

  Widget _pendingSection() {
    if (_m.pending.isEmpty) return const SizedBox.shrink();
    return _section(GT.t('pending_requests'), [
      for (final p in _m.pending)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GroupAvatar(name: p.name, size: 38),
          title: Text(p.name, style: const TextStyle(color: Colors.white)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(tooltip: GT.t('approve'), onPressed: () => _manage(p, 'approve'), icon: const Icon(Icons.check_circle_rounded, color: gTeal)),
            IconButton(tooltip: GT.t('reject'), onPressed: () => _manage(p, 'reject'), icon: const Icon(Icons.cancel_rounded, color: Color(0xffff8f8f))),
          ]),
        ),
    ]);
  }

  Widget _memberTile(GroupMember m) {
    final myRole = _g.role;
    final canManage = _g.isStaff && m.role != 'owner' && (myRole == 'owner' || m.role == 'member');
    final roleLabel = m.role == 'owner' ? GT.t('role_owner') : (m.role == 'admin' ? GT.t('role_admin') : '');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => openUserProfile(context, m.uid, m.name),
      leading: GroupAvatar(name: m.name, size: 38),
      title: Row(children: [
        Flexible(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white))),
        gTick(m.badge),
      ]),
      subtitle: roleLabel.isEmpty ? null : Text(roleLabel, style: const TextStyle(color: gGold, fontSize: 11.5)),
      trailing: canManage
          ? PopupMenuButton<String>(
              color: gPanel,
              iconColor: gMuted,
              onSelected: (a) => _manage(m, a),
              itemBuilder: (_) => [
                if (myRole == 'owner' && m.role == 'member')
                  PopupMenuItem<String>(value: 'promote', child: Text(GT.t('promote'), style: const TextStyle(color: Colors.white))),
                if (myRole == 'owner' && m.role == 'admin')
                  PopupMenuItem<String>(value: 'demote', child: Text(GT.t('demote'), style: const TextStyle(color: Colors.white))),
                PopupMenuItem<String>(value: 'kick', child: Text(GT.t('kick'), style: const TextStyle(color: Colors.white))),
                PopupMenuItem<String>(value: 'ban', child: Text(GT.t('ban'), style: const TextStyle(color: Color(0xffff8f8f)))),
              ],
            )
          : null,
    );
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
          title: Text(GT.t('info_title'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: gGold))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
                Column(children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _g.isStaff ? _photoMenu : null,
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      GroupAvatar(name: _g.name, isGroup: true, size: 84, group: _g),
                      if (_photoBusy)
                        const Positioned.fill(child: Padding(padding: EdgeInsets.all(26), child: CircularProgressIndicator(strokeWidth: 2, color: gGold)))
                      else if (_g.isStaff)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: gGold, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 15, color: gBg),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text(_g.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
                  if (_g.username != null && _g.username!.isNotEmpty)
                    Text('@${_g.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: gTeal, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${_g.isPublic ? GT.t('kind_public') : GT.t('kind_private')} · ${GT.t('members_n', {'n': '${_m.ok ? _m.memberCount : _g.memberCount}'})}',
                    style: const TextStyle(color: gMuted),
                  ),
                  if (_g.description.isNotEmpty && !_g.isStaff) ...[
                    const SizedBox(height: 8),
                    Text(_g.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.7)),
                  ],
                  const SizedBox(height: 4),
                  Text(GT.t('retention_banner', {'h': GT.hours(_g.retentionHours)}), style: const TextStyle(color: gMuted, fontSize: 12)),
                ]),
                if (_g.isStaff) _addMembersButton(),
                if (_g.isStaff) _inviteSection(),
                if (_g.isStaff) _editSection(),
                if (_g.isStaff) _pendingSection(),
                _section(GT.t('members_title'), [for (final m in _m.members) _memberTile(m)]),
                const SizedBox(height: 18),
                if (_g.isOwner)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xffff8f8f), side: const BorderSide(color: Color(0xffff8f8f)), minimumSize: const Size.fromHeight(46)),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(GT.t('delete_group')),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xffff8f8f), side: const BorderSide(color: Color(0xffff8f8f)), minimumSize: const Size.fromHeight(46)),
                    onPressed: _leave,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: Text(GT.t('leave')),
                  ),
              ]),
      ),
    );
  }
}
