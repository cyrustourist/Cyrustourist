import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/friends_service.dart';
import '../../services/group_service.dart';
import '../../services/group_texts.dart';
import 'group_friend_picker.dart';
import 'group_photo.dart';
import 'group_ui.dart';

final RegExp _userRe = RegExp(r'^[A-Za-z][A-Za-z0-9_]{4,31}$');

/// ساخت گروه با کلید عمومی/خصوصی و انتخاب ماندگاری (در سقف مجاز هر نوع کاربر).
/// با موفقیت، GroupInfo گروه تازه را برمی‌گرداند.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key, required this.limits});

  final GroupLimits limits;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _user = TextEditingController();
  bool _public = true;
  bool _approval = false;
  bool _busy = false;
  String? _photo; // base64 فشرده
  List<FriendItem> _friends = const [];
  late int _retention;

  List<int> get _options => widget.limits.options.isNotEmpty ? widget.limits.options : const [24];

  @override
  void initState() {
    super.initState();
    final def = widget.limits.defaultRetentionHours;
    _retention = _options.contains(def) ? def : _options.last;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _user.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final b64 = await pickGroupPhoto(context);
    if (!mounted) return;
    if (b64 == null) {
      gToast(context, GT.t('photo_bad'));
      return;
    }
    setState(() => _photo = b64);
  }

  Widget _photoPicker() {
    final photo = _photo;
    return Column(children: [
      InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : _pickPhoto,
        child: Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(shape: BoxShape.circle, color: gPanel, border: Border.all(color: gGold, width: 1.4)),
            child: ClipOval(
              child: photo != null
                  ? Image.memory(base64Decode(photo), width: 92, height: 92, fit: BoxFit.cover)
                  : const Icon(Icons.groups_rounded, color: gGold, size: 44),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: gGold, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, size: 16, color: gBg),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _busy ? null : (photo == null ? _pickPhoto : () => setState(() => _photo = null)),
        child: Text(GT.t(photo == null ? 'photo_add' : 'photo_remove'), style: const TextStyle(color: gGold)),
      ),
    ]);
  }

  Future<void> _pickFriends() async {
    final picked = await Navigator.of(context).push<List<FriendItem>>(
      MaterialPageRoute(builder: (_) => GroupFriendPicker(initial: _friends)),
    );
    if (!mounted || picked == null) return;
    setState(() => _friends = picked);
  }

  Widget _friendsSection() => Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: _busy ? null : _pickFriends,
            child: Row(children: [
              const Icon(Icons.group_add_rounded, color: gGold),
              const SizedBox(width: 10),
              Expanded(child: Text(GT.t('add_friends_opt'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              if (_friends.isNotEmpty) Text('${_friends.length}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
              const Icon(Icons.chevron_right_rounded, color: gMuted),
            ]),
          ),
          if (_friends.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final f in _friends)
                Chip(
                  backgroundColor: gBg,
                  side: const BorderSide(color: gLine),
                  label: Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  deleteIconColor: gMuted,
                  onDeleted: _busy ? null : () => setState(() => _friends = _friends.where((x) => x.uid != f.uid).toList()),
                ),
            ]),
          ],
        ]),
      );

  Future<void> _create() async {
    if (_busy) return;
    final name = _name.text.trim();
    final user = _user.text.trim().replaceFirst('@', '');
    if (name.length < 2) {
      gToast(context, GT.t('form_name'));
      return;
    }
    if (_public && !_userRe.hasMatch(user)) {
      gToast(context, GT.t('form_username_hint'));
      return;
    }
    if (!_public && user.isNotEmpty && !_userRe.hasMatch(user)) {
      gToast(context, GT.t('form_username_hint'));
      return;
    }
    setState(() => _busy = true);
    final r = await GroupService.create(
      name: name,
      description: _desc.text.trim(),
      kind: _public ? 'public' : 'private',
      username: _public ? user : '',
      retentionHours: _retention,
      joinApproval: _approval,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    var g = r.group;
    if (r.ok && g != null) {
      final photo = _photo;
      if (photo != null) {
        // عکس بعد از ساخت گروه آپلود می‌شود؛ شکست آن مانع ساخت گروه نیست
        final pr = await GroupService.setPhoto(g.id, photo);
        final v = int.tryParse('${pr.raw?['photo_v']}') ?? 0;
        if (pr.ok && v > 0) {
          g = g.withPhoto(v);
        } else if (mounted) {
          gToast(context, GT.t('photo_fail'));
        }
      }
      var note = GT.t('created_ok');
      if (_friends.isNotEmpty) {
        final ar = await GroupService.addMembers(g.id, _friends.map((f) => f.uid).toList());
        final added = int.tryParse('${ar.raw?['added']}') ?? 0;
        final total = int.tryParse('${ar.raw?['member_count']}') ?? 0;
        if (ar.ok && added > 0) {
          note = GT.t('members_added', {'n': '$added'});
          if (total > 0) g = g.copyWith(memberCount: total);
        }
      }
      if (!mounted) return;
      gToast(context, note);
      Navigator.of(context).pop(g);
      return;
    }
    if (r.error == 'no_name' || r.error == 'not_registered') {
      askGroupProfile(context);
      return;
    }
    gToast(context, r.text);
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

  Widget _kindCard(bool pub, IconData icon) {
    final selected = _public == pub;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _public = pub),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? gGold.withValues(alpha: 0.12) : gPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? gGold : gLine, width: selected ? 1.6 : 1),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? gGold : gMuted, size: 26),
            const SizedBox(height: 6),
            Text(GT.t(pub ? 'kind_public' : 'kind_private'), style: TextStyle(color: selected ? gGold : Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              GT.t(pub ? 'kind_public_hint' : 'kind_private_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: gMuted, fontSize: 11, height: 1.6),
            ),
          ]),
        ),
      ),
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
          title: Text(GT.t('create_group'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
          Center(child: _photoPicker()),
          const SizedBox(height: 8),
          TextField(controller: _name, maxLength: 60, style: const TextStyle(color: Colors.white), decoration: _dec(GT.t('form_name'))),
          const SizedBox(height: 4),
          TextField(controller: _desc, maxLength: 200, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: _dec(GT.t('form_desc'))),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kindCard(true, Icons.public_rounded),
            const SizedBox(width: 10),
            _kindCard(false, Icons.lock_rounded),
          ]),
          if (_public) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              maxLength: 32,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white),
              decoration: _dec(GT.t('form_username'), hint: GT.t('form_username_hint')),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: gGold,
            value: _approval,
            onChanged: (v) => setState(() => _approval = v),
            title: Text(GT.t('form_approval'), style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          _friendsSection(),
          Row(children: [
            Expanded(child: Text(GT.t('form_retention'), style: const TextStyle(color: Colors.white, fontSize: 14))),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _retention,
                dropdownColor: gPanel,
                iconEnabledColor: gGold,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                items: [for (final o in _options) DropdownMenuItem<int>(value: o, child: Text(GT.hours(o)))],
                onChanged: (v) => setState(() => _retention = v ?? _retention),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(GT.t('retention_banner', {'h': GT.hours(_retention)}), style: const TextStyle(color: gMuted, fontSize: 12)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(GT.t('form_create'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ]),
      ),
    );
  }
}
