import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/app_language.dart';
import '../services/badge_service.dart';
import '../services/user_profile_service.dart';
import 'profile/my_profile_page.dart';
import 'stay_registration_page.dart' show showStayCaptcha;
import 'support_page.dart';

const Color _bg = Color(0xff06121d);
const Color _panel = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _line = Color(0xff1d3a4d);

String _tr(String fa, String en, String ar) {
  switch (LanguageManager.current) {
    case AppLanguage.persian:
      return fa;
    case AppLanguage.arabic:
      return ar;
    default:
      return en;
  }
}

class _Msg {
  _Msg(this.id, this.fromAdmin, this.name, this.text, this.at);
  final int id;
  final bool fromAdmin;
  final String name;
  final String text;
  final DateTime? at;
}

/// «چت آنلاین» پشتیبانی: صفحهٔ گفتگو مثل چت‌روم، متصل به ورکر (`/api/support/*`).
/// - هر حساب ثبت‌شده یک گفتگوی اختصاصی دارد و پاسخ‌ها از «پنل مدیریت › چت» می‌آید.
/// - قبل از اولین پیام (و هر ۱۲ ساعت) پازل ضد ربات حل می‌شود.
/// - پایین صفحه: راه‌های جایگزین (واتساپ، تلگرام، ایتا) بدون نیاز به کپی متن.
class SupportOnlineChatPage extends StatefulWidget {
  const SupportOnlineChatPage({super.key});

  @override
  State<SupportOnlineChatPage> createState() => _SupportOnlineChatPageState();
}

class _SupportOnlineChatPageState extends State<SupportOnlineChatPage> with WidgetsBindingObserver {
  final List<_Msg> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  bool _loading = true;
  bool _failed = false;
  bool _hasName = true;
  bool _verified = false;
  bool _sending = false;
  bool _fetching = false;
  bool _open = true;
  List<List<int>> _windows = const [];
  String _closedMessage = '';
  int _retention = 7;
  String _name = '';
  int _lastId = 0;

  bool get _rtl => LanguageManager.current != AppLanguage.english;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _poll();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _init() async {
    try {
      final p = await UserProfileService.load();
      _name = p.displayName.trim().isNotEmpty ? p.displayName.trim() : p.username.trim();
      _hasName = p.displayName.trim().isNotEmpty;
      if (_hasName) await BadgeService.registerUser();
    } catch (_) {}
    await _poll(first: true);
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  DateTime? _parse(String s) {
    if (s.isEmpty) return null;
    return DateTime.tryParse('${s.replaceFirst(' ', 'T')}Z')?.toLocal();
  }

  Future<void> _poll({bool first = false}) async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final uid = await BadgeService.userUid();
      final j = await BadgeService.call('GET', '/api/support/messages', query: {'user_uid': uid, 'after_id': '$_lastId'});
      if (!mounted) return;
      if (j == null || j['success'] != true) {
        if (first) setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      final atBottom = !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 90;
      final list = (j['messages'] as List?) ?? const [];
      setState(() {
        _loading = false;
        _failed = false;
        _open = j['open'] != false;
        _verified = j['verified'] == true;
        _closedMessage = '${j['closed_message'] ?? ''}';
        _retention = int.tryParse('${j['retention_days']}') ?? 7;
        _windows = ((j['windows'] as List?) ?? const [])
            .whereType<List>()
            .map((w) => [int.tryParse('${w[0]}') ?? 0, int.tryParse('${w[1]}') ?? 0])
            .toList();
        for (final m in list.whereType<Map>()) {
          final id = int.tryParse('${m['id']}') ?? 0;
          if (id <= _lastId) continue;
          _messages.add(_Msg(id, '${m['from']}' == 'admin', '${m['name'] ?? ''}', '${m['text'] ?? ''}', _parse('${m['at'] ?? ''}')));
          _lastId = id;
        }
        if (_messages.length > 200) _messages.removeRange(0, _messages.length - 200);
      });
      if (list.isNotEmpty && (atBottom || first)) _jumpToEnd();
    } finally {
      _fetching = false;
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// پازل ضد ربات؛ در صورت موفقیت ۱۲ ساعت اعتبار دارد.
  Future<bool> _verify() async {
    final cap = await showStayCaptcha(context);
    if (cap == null || !mounted) return false;
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/support/verify', body: {'user_uid': uid, ...cap});
    if (!mounted) return false;
    if (j == null) {
      _toast(_tr('ارتباط با سرور برقرار نشد.', 'Could not reach the server.', 'تعذر الاتصال بالخادم.'));
      return false;
    }
    if (j['success'] == true) {
      setState(() => _verified = true);
      return true;
    }
    final err = '${j['error'] ?? ''}';
    if (err == 'not_registered') {
      _askProfile();
    } else {
      _toast('${j['message'] ?? _tr('تأیید انسانی انجام نشد.', 'Human check failed.', 'فشل التحقق.')}');
    }
    return false;
  }

  Future<Map<String, dynamic>?> _post(String text) async {
    final uid = await BadgeService.userUid();
    return BadgeService.call('POST', '/api/support/send', body: {'user_uid': uid, 'body': text});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (!_hasName) {
      _askProfile();
      return;
    }
    setState(() => _sending = true);
    try {
      if (!_verified && !await _verify()) return;
      var j = await _post(text);
      if (j != null && '${j['error']}' == 'captcha_required') {
        if (mounted) setState(() => _verified = false);
        if (!await _verify()) return;
        j = await _post(text);
      }
      if (!mounted) return;
      if (j == null) {
        _toast(_tr('ارسال نشد؛ اینترنت را بررسی کنید.', 'Not sent; check your connection.', 'لم تُرسل؛ تحقق من الاتصال.'));
        return;
      }
      if (j['success'] == true) {
        _input.clear();
        await _poll();
        _jumpToEnd();
        return;
      }
      final err = '${j['error'] ?? ''}';
      if (err == 'not_registered') {
        final r = await BadgeService.registerUser();
        if (!mounted) return;
        if (!r.ok) {
          _askProfile();
          return;
        }
        _toast(_tr('حساب شما ثبت شد؛ دوباره ارسال کنید.', 'Your account is ready; send again.', 'تم تسجيل حسابك؛ أرسل مرة أخرى.'));
        return;
      }
      _toast('${j['message'] ?? _tr('ارسال نشد.', 'Not sent.', 'لم تُرسل.')}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _askProfile() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _panel,
          title: Text(_tr('نام پروفایل لازم است', 'Profile name required', 'اسم الملف الشخصي مطلوب'),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
          content: Text(
            _tr('برای چت با پشتیبانی، ابتدا حساب خود را در «شناسه کاربری» ثبت و تأیید کنید.',
                'To chat with support, first create and confirm your account in "User ID".',
                'للدردشة مع الدعم، سجّل حسابك وأكده أولاً في «معرّف المستخدم».'),
            style: const TextStyle(color: Colors.white, height: 1.9),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_tr('بعداً', 'Later', 'لاحقاً'), style: const TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
                if (mounted) await _init();
              },
              child: Text(_tr('رفتن به شناسه کاربری', 'Go to User ID', 'اذهب إلى المعرّف')),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- شبکه‌های اجتماعی (بدون کپی متن) ----------------
  Future<void> _open_(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(_tr('باز نشد.', 'Could not open.', 'تعذر الفتح.'));
    } catch (_) {
      _toast(_tr('باز نشد.', 'Could not open.', 'تعذر الفتح.'));
    }
  }

  String get _greet {
    final who = _name.isEmpty ? _tr('کاربر سایروس توریست', 'a Cyrus Tourist user', 'مستخدم سايروس توريست') : _name;
    return _tr('سلام، من «$who» هستم. لطفاً راهنمایی کنید.', 'Hello, I am "$who". Please help me.', 'مرحباً، أنا «$who». يرجى المساعدة.');
  }

  Future<void> _whatsapp() async {
    final number = SupportPage.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final intl = number.startsWith('0') ? '98${number.substring(1)}' : number;
    await _open_(Uri.https('wa.me', '/$intl', {'text': _greet}));
  }

  Future<void> _telegram() async {
    final user = SupportPage.telegramUsername.replaceAll('@', '');
    await _open_(Uri.https('t.me', '/$user', {'text': _greet}));
  }

  Future<void> _eitaa() => _open_(Uri.parse(SupportPage.eitaaUrl));

  Widget _social(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xff071722), size: 18),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Color(0xff071722), fontWeight: FontWeight.w900, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

  String get _hoursText => _windows.map((w) => '${_hh(w[0])}–${_hh(w[1])}').join(' ، ');

  Widget _banner() {
    if (_open) return const SizedBox.shrink();
    final base = _closedMessage.trim().isNotEmpty
        ? _closedMessage.trim()
        : _tr('پشتیبانی اکنون آفلاین است؛ پیام بگذارید، در اولین فرصت پاسخ می‌دهیم.',
            'Support is offline right now; leave a message and we will reply soon.',
            'الدعم غير متصل الآن؛ اترك رسالة وسنرد قريباً.');
    final hours = _windows.isEmpty ? '' : '\n${_tr('ساعت کاری', 'Working hours', 'ساعات العمل')}: $_hoursText';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff2b2210),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff9b6a19)),
      ),
      child: Text('$base$hours', style: const TextStyle(color: _gold, fontSize: 12.5, height: 1.8, fontWeight: FontWeight.w700)),
    );
  }

  Widget _bubble(_Msg m) {
    final mine = !m.fromAdmin;
    final t = m.at;
    final time = t == null ? '' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? const Color(0xff12425a) : const Color(0xff3a2f10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? const Color(0xff2e6f8f) : const Color(0xff9b6a19)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                m.name.isEmpty ? _tr('پشتیبانی', 'Support', 'الدعم') : m.name,
                style: const TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.w900),
              ),
            SelectableText(m.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.7)),
            if (time.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (_failed && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _tr('اتصال به پشتیبانی برقرار نشد. اینترنت را بررسی کنید.', 'Could not reach support. Check your connection.', 'تعذر الاتصال بالدعم. تحقق من الإنترنت.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.8),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _failed = false;
                  });
                  _init();
                },
                child: Text(_tr('تلاش دوباره', 'Retry', 'إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _tr('سلام! پیام خود را بنویسید؛ همکاران ما در پنل پشتیبانی پاسخ می‌دهند.',
                'Hi! Write your message; our team will answer from the support panel.',
                'مرحباً! اكتب رسالتك وسيرد فريقنا من لوحة الدعم.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.9),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _bg,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(_tr('چت آنلاین پشتیبانی', 'Online support chat', 'الدردشة المباشرة مع الدعم'),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _social(_tr('واتساپ', 'WhatsApp', 'واتساب'), Icons.chat_rounded, const Color(0xff3ddc84), _whatsapp),
                    const SizedBox(width: 8),
                    _social(_tr('تلگرام', 'Telegram', 'تيليجرام'), Icons.send_rounded, const Color(0xff4cc3ff), _telegram),
                    const SizedBox(width: 8),
                    _social(_tr('ایتا', 'Eitaa', 'إيتا'), Icons.forum_rounded, const Color(0xffffb347), _eitaa),
                  ],
                ),
              ),
              _banner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  _tr('گفتگوها پس از $_retention روز به‌صورت خودکار پاک می‌شوند.',
                      'Chats are deleted automatically after $_retention days.',
                      'تُحذف المحادثات تلقائياً بعد $_retention أيام.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              Expanded(child: _body()),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: const BoxDecoration(color: _panel, border: Border(top: BorderSide(color: _line))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _tr('پیام خود را بنویسید…', 'Type your message…', 'اكتب رسالتك…'),
                          hintStyle: const TextStyle(color: Color(0xff8fa5b2)),
                          filled: true,
                          fillColor: const Color(0xff071722),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _line)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _gold,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: _sending
                              ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2.5, color: _bg))
                              : Icon(Icons.send_rounded, color: _bg, size: 22, textDirection: TextDirection.ltr),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
