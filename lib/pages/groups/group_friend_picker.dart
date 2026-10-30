import 'package:flutter/material.dart';

import '../../services/call_texts.dart';
import '../../services/friends_service.dart';
import '../../services/group_texts.dart';
import '../../widgets/call_widgets.dart';
import 'group_ui.dart';

/// انتخاب چند دوست برای افزودن به گروه (هنگام ساخت گروه یا از صفحهٔ اطلاعات گروه).
/// با تأیید، فهرست FriendItem های انتخاب‌شده را برمی‌گرداند.
class GroupFriendPicker extends StatefulWidget {
  const GroupFriendPicker({super.key, this.excludeUids = const {}, this.initial = const []});

  /// کسانی که از قبل عضو هستند (در فهرست نمایش داده نمی‌شوند).
  final Set<String> excludeUids;

  /// انتخاب‌های قبلی (هنگام بازگشت به همین صفحه).
  final List<FriendItem> initial;

  @override
  State<GroupFriendPicker> createState() => _GroupFriendPickerState();
}

class _GroupFriendPickerState extends State<GroupFriendPicker> {
  final TextEditingController _q = TextEditingController();
  List<FriendItem> _friends = const [];
  final Map<String, FriendItem> _selected = {};
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    for (final f in widget.initial) {
      _selected[f.uid] = f;
    }
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await FriendsService.list();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _friends = (r.data ?? const <FriendItem>[]).where((f) => !widget.excludeUids.contains(f.uid)).toList();
      } else {
        _error = r.needsProfile ? CT.t('need_profile') : r.text;
      }
    });
  }

  List<FriendItem> get _filtered {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return _friends;
    return _friends.where((f) => f.name.toLowerCase().contains(q) || f.username.toLowerCase().contains(q)).toList();
  }

  void _toggle(FriendItem f) {
    setState(() {
      if (_selected.containsKey(f.uid)) {
        _selected.remove(f.uid);
      } else {
        _selected[f.uid] = f;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: gGold));
    } else if (_error.isNotEmpty) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: gMuted, height: 1.8))),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _load, child: Text(GT.t('retry'))),
        ]),
      );
    } else if (list.isEmpty) {
      body = Center(child: Text(GT.t('pick_none'), style: const TextStyle(color: gMuted)));
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final f = list[i];
          final on = _selected.containsKey(f.uid);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: on ? gGold.withValues(alpha: 0.10) : gPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: on ? gGold : gLine),
            ),
            child: ListTile(
              onTap: () => _toggle(f),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: CallAvatar(uid: f.uid, name: f.name, hasPhoto: f.hasPhoto, radius: 22),
              title: Row(children: [
                Flexible(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                gTick(f.badge),
              ]),
              subtitle: f.username.isEmpty ? null : Text('@${f.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: gTeal, fontSize: 12)),
              trailing: Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, color: on ? gGold : gMuted),
            ),
          );
        },
      );
    }
    return Directionality(
      textDirection: gDir,
      child: Scaffold(
        backgroundColor: gBg,
        appBar: AppBar(
          backgroundColor: gBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gGold),
          title: Text(GT.t('pick_friends'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: GT.t('pick_search'),
                hintStyle: const TextStyle(color: gMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: gGold),
                filled: true,
                fillColor: gPanel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gLine)),
              ),
            ),
          ),
          Expanded(child: body),
        ]),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => Navigator.of(context).pop(_selected.values.toList()),
              child: Text(GT.t('pick_confirm', {'n': '${_selected.length}'}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}
