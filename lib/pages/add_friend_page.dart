import 'package:flutter/material.dart';

import '../core/language/menu_translations.dart';
import '../services/call_texts.dart';
import '../services/friends_service.dart';
import '../widgets/call_widgets.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

/// افزودن دوست با جی‌میل تأییدشده، شمارهٔ تأییدشده یا نام کاربری.
/// دوست مستقیم (بدون نیاز به تأیید طرف مقابل) به لیست اضافه می‌شود.
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;
  FriendItem? _added;
  bool _already = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = CT.t('add_empty'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _added = null;
    });
    final r = await FriendsService.add(identifier: text);
    if (!mounted) return;
    if (r.ok) {
      _ctrl.clear();
      setState(() {
        _busy = false;
        _added = r.data;
        _already = r.raw?['already'] == true;
      });
    } else {
      setState(() {
        _busy = false;
        _error = r.needsProfile ? CT.t('need_profile') : r.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _added;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(CT.t('add_title'), style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              Text(CT.t('add_desc'), style: const TextStyle(color: Colors.white70, height: 1.8, fontSize: 13.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                enabled: !_busy,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: CT.t('add_field'),
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: _gold),
                  filled: true,
                  fillColor: _card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _gold, width: 1.4),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xffff8f8f), height: 1.7, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(CT.t('add_btn'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              if (a != null) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _teal.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    CallAvatar(uid: a.uid, name: a.name, radius: 26, hasPhoto: a.hasPhoto),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        if (a.username.isNotEmpty)
                          Text('@${a.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: _teal, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Text(
                          _already ? CT.t('friend_exists', {'name': a.name}) : CT.t('friend_added', {'name': a.name}),
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6),
                        ),
                      ]),
                    ),
                    const Icon(Icons.check_circle_rounded, color: _teal),
                  ]),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(CT.t('add_done')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
