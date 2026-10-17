import 'dart:async';

import 'package:flutter/material.dart';

import '../services/badge_service.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import '../services/user_profile_service.dart';
import '../core/language/menu_translations.dart';
import '../core/language/new_texts.dart';
import '../widgets/linkified_text.dart';
import 'profile/my_profile_page.dart';
import 'profile/public_profile_page.dart';

const Color _bg = Color(0xff06121d);
const Color _panel = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _line = Color(0xff1d3a4d);

/// چت‌روم همگانی هر شهر + حالت «همسفر».
/// پیام‌ها موقتی‌اند (سمت سرور بعد از مدتی پاک می‌شوند) و فقط در ساعت‌های تعیین‌شده باز است.
class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with WidgetsBindingObserver {
  List<ChatRoom> _rooms = const [];
  String _city = '';
  bool _companion = false;
  bool _loadingRooms = true;
  bool _roomsFailed = false;

  final List<ChatMessage> _messages = [];
  bool _open = true;
  List<List<int>> _windows = const [];
  double? _nextOpen;
  int _lastId = 0;
  bool _sending = false;
  bool _hasName = true;

  List<CompanionPost> _posts = const [];

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  bool _fetching = false;

  ChatRoom? get _room {
    for (final r in _rooms) {
      if (r.city == _city && r.kind == (_companion ? 'companion' : 'public')) return r;
    }
    return null;
  }

  List<String> get _cities {
    final seen = <String>[];
    for (final r in _rooms) {
      if (!seen.contains(r.city)) seen.add(r.city);
    }
    return seen;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CallService.instance.startWatch();
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CallService.instance.stopWatch();
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
    final p = await UserProfileService.load();
    _hasName = p.displayName.trim().isNotEmpty;
    if (_hasName) await BadgeService.registerUser();
    await _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsFailed = false;
    });
    final rooms = await ChatService.rooms();
    if (!mounted) return;
    if (rooms.isEmpty) {
      setState(() {
        _loadingRooms = false;
        _roomsFailed = true;
      });
      return;
    }
    _rooms = rooms;
    if (_city.isEmpty || !_cities.contains(_city)) {
      _city = _cities.contains('خراسان رضوی')
          ? 'خراسان رضوی'
          : (_cities.contains('مشهد') ? 'مشهد' : _cities.first);
    }
    setState(() => _loadingRooms = false);
    await _enterRoom();
  }

  Future<void> _enterRoom() async {
    _timer?.cancel();
    _messages.clear();
    _lastId = 0;
    _posts = const [];
    if (mounted) setState(() {});
    final room = _room;
    if (room == null) return;
    if (_companion) {
      final posts = await ChatService.posts(_city);
      if (mounted) setState(() => _posts = posts);
    }
    await _poll();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _poll());
  }

  Future<void> _poll() async {
    final room = _room;
    if (room == null || _fetching || !mounted) return;
    _fetching = true;
    try {
      final f = await ChatService.messages(room.id, afterId: _lastId);
      if (!mounted || !f.ok) return;
      final atBottom = !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 80;
      setState(() {
        _open = f.open;
        _windows = f.windows;
        _nextOpen = f.nextOpenHour;
        if (f.messages.isNotEmpty) {
          _messages.addAll(f.messages);
          _lastId = f.messages.last.id;
          if (_messages.length > 120) _messages.removeRange(0, _messages.length - 120);
        }
      });
      if (atBottom) _jumpToEnd();
    } finally {
      _fetching = false;
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  String _hh(double h) => '${h.floor().toString().padLeft(2, '0')}:00';

  Future<void> _send() async {
    final room = _room;
    final text = _input.text.trim();
    if (room == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final r = await ChatService.send(room.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _input.clear();
      await _poll();
      _jumpToEnd();
      return;
    }
    if (r.error == 'no_name' || r.error == 'not_registered') {
      _askProfile();
      return;
    }
    _toast(r.message);
    if (r.error == 'closed') _poll();
  }

  void _askProfile() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _panel,
          title: const Text('نام پروفایل لازم است', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
          content: const Text(
            'برای گفت‌وگو، یک نام در پروفایل خود ثبت کنید تا دیگران شما را بشناسند.',
            style: TextStyle(color: Colors.white, height: 1.9),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('بعداً', style: TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
                await _init();
              },
              child: const Text('رفتن به پروفایل'),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(String uid, String name) {
    if (uid.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublicProfilePage(uid: uid, name: name)));
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _callButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 56, height: 56, child: Icon(icon, color: Colors.white, size: 26)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Future<void> _messageMenu(ChatMessage m) async {
    if (m.mine) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _panel,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _callButton(Icons.call_rounded, 'تماس صوتی', const Color(0xff2fa866), () => Navigator.of(ctx).pop('voice')),
                    const SizedBox(width: 28),
                    _callButton(Icons.videocam_rounded, 'تماس تصویری', const Color(0xff3d5566), () => Navigator.of(ctx).pop('video')),
                  ],
                ),
              ),
              const Divider(color: _line, height: 16),
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Color(0xffff8f8f)),
                title: const Text('گزارش این پیام', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('report'),
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: _gold),
                title: Text('مسدود کردن ${m.name}', style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(ctx).pop('block'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'voice') {
      if (m.uid.isEmpty) {
        _toast('تماس با این کاربر ممکن نیست.');
        return;
      }
      await CallService.instance.startOutgoing(toUid: m.uid, name: m.name);
      return;
    }
    if (action == 'video') {
      _toast('تماس تصویری در بروزرسانی بعدی فعال می‌شود.');
      return;
    }
    if (action == 'report') {
      final ok = await ChatService.report(m.id);
      _toast(ok ? 'گزارش ثبت شد. ممنون.' : 'گزارش ثبت نشد.');
    } else if (action == 'block') {
      final ok = await ChatService.block(m.uid);
      if (ok) {
        setState(() => _messages.removeWhere((x) => x.uid == m.uid));
        _toast('${m.name} مسدود شد و پیام‌هایش دیده نمی‌شود.');
      } else {
        _toast('مسدودسازی انجام نشد.');
      }
    }
  }

  Future<void> _newPost() async {
    final origin = TextEditingController();
    final dest = TextEditingController();
    final title = TextEditingController();
    final details = TextEditingController();
    int? dayOffset;
    String? timeVal;
    var seats = 1;
    String? err;
    final days = List<int>.generate(30, (i) => i);
    final times = <String>[
      for (var h = 0; h < 24; h++) ...['${h.toString().padLeft(2, '0')}:00', '${h.toString().padLeft(2, '0')}:30'],
    ];
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('آگهی همسفر در $_city', style: const TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _field(origin, NT.t('cp_origin'), 60),
                const SizedBox(height: 8),
                _field(dest, NT.t('cp_dest'), 60),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _pickBox<int>(
                      hint: NT.t('cp_date'),
                      value: dayOffset,
                      items: [
                        for (final d in days)
                          DropdownMenuItem<int>(value: d, child: Text(_dayLabel(d), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setS(() => dayOffset = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickBox<String>(
                      hint: NT.t('cp_time'),
                      value: timeVal,
                      items: [for (final t in times) DropdownMenuItem<String>(value: t, child: Text(t))],
                      onChanged: (v) => setS(() => timeVal = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                _field(title, NT.t('cp_title_opt'), 80),
                const SizedBox(height: 8),
                _field(details, 'توضیح کوتاه (بدون لینک و شماره تلفن)', 300, lines: 3),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('تعداد همسفر مورد نیاز:', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(onPressed: () => setS(() => seats = seats > 1 ? seats - 1 : 1), icon: const Icon(Icons.remove_circle_outline, color: _gold)),
                  Text('$seats', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => setS(() => seats = seats < 20 ? seats + 1 : 20), icon: const Icon(Icons.add_circle_outline, color: _gold)),
                ]),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err!, style: const TextStyle(color: Color(0xffff8f8f), fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg, padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {
                    if (origin.text.trim().isEmpty || dest.text.trim().isEmpty) {
                      setS(() => err = NT.t('cp_need_route'));
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('ثبت آگهی', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final o = origin.text.trim();
    final dn = dest.text.trim();
    final t = title.text.trim();
    final d = details.text.trim();
    final dt = [if (dayOffset != null) _dayLabel(dayOffset!, short: true), if (timeVal != null) timeVal!].join(' ');
    origin.dispose();
    dest.dispose();
    title.dispose();
    details.dispose();
    if (ok != true || o.isEmpty || dn.isEmpty) return;
    final r = await ChatService.createPost(city: _city, origin: o, destination: dn, title: t, details: d, travelDate: dt, seats: seats);
    if (!mounted) return;
    if (r.ok) {
      _toast('آگهی ثبت شد.');
      final posts = await ChatService.posts(_city);
      if (mounted) setState(() => _posts = posts);
    } else if (r.error == 'no_name' || r.error == 'not_registered') {
      _askProfile();
    } else {
      _toast(r.message);
    }
  }

  /// برچسب روز: امروز / فردا / تاریخ (شمسی برای فارسی، میلادی برای بقیهٔ زبان‌ها)
  String _dayLabel(int offset, {bool short = false}) {
    final base = DateTime.now().add(Duration(days: offset));
    String date;
    if (MenuLanguage.current == 'fa') {
      final j = _gregorianToJalali(base.year, base.month, base.day);
      date = '${j[0]}/${j[1].toString().padLeft(2, '0')}/${j[2].toString().padLeft(2, '0')}';
    } else {
      date = '${base.year}-${base.month.toString().padLeft(2, '0')}-${base.day.toString().padLeft(2, '0')}';
    }
    if (short) return date;
    if (offset == 0) return '${NT.t('cp_today')} · $date';
    if (offset == 1) return '${NT.t('cp_tomorrow')} · $date';
    return date;
  }

  static List<int> _gregorianToJalali(int gy, int gm, int gd) {
    const gDm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var jy = gy > 1600 ? 979 : 0;
    gy -= gy > 1600 ? 1600 : 621;
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) - 80 + gd + gDm[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final jm = days < 186 ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    final jd = 1 + (days < 186 ? (days % 31) : ((days - 186) % 30));
    return [jy, jm, jd];
  }

  Widget _pickBox<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xff0a1c27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xff0e2433),
          iconEnabledColor: _gold,
          hint: Text(hint, style: const TextStyle(color: Color(0xff8fa5b2), fontSize: 13)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, int max, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLength: max,
      maxLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff8fa5b2)),
        counterText: '',
        filled: true,
        fillColor: const Color(0xff0a1c27),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
      ),
    );
  }

  Widget _tick(String? badge) {
    if (badge == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 3),
      child: Icon(Icons.verified_rounded, size: 14, color: badge == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
    );
  }

  Widget _statusBar() {
    final room = _room;
    final wins = _windows.isNotEmpty ? _windows : (room?.windows ?? const []);
    final color = _open ? const Color(0xff1fd1b0) : const Color(0xffff6b6b);
    final String text;
    if (_open) {
      text = 'اتاق باز است';
    } else if (_nextOpen != null) {
      text = 'اتاق بسته است · بازگشایی ساعت ${_hh(_nextOpen!)}';
    } else {
      text = 'اتاق فعلاً بسته است';
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))),
          if (wins.isNotEmpty)
            Text(
              wins.map((w) => '${w[0]}-${w[1]}').join('  ·  '),
              style: const TextStyle(color: Color(0xff8fa5b2), fontSize: 11.5),
              textDirection: TextDirection.ltr,
            ),
        ],
      ),
    );
  }

  Widget _postsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Text('آگهی‌های همسفر', style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: _newPost,
              icon: const Icon(Icons.add_rounded, color: _gold, size: 18),
              label: const Text('آگهی جدید', style: TextStyle(color: _gold, fontSize: 12.5)),
            ),
          ]),
          Flexible(
            child: _posts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('هنوز آگهی‌ای نیست. اولین نفر باشید.', style: TextStyle(color: Color(0xff8fa5b2), fontSize: 12.5)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final p = _posts[i];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [Color(0xff1b1740), Color(0xff2a1a4f)]),
                          border: Border.all(color: const Color(0xff5a3fa8)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              if (p.origin.isNotEmpty && p.title != '${p.origin} ➜ ${p.destination}')
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('${p.origin} ➜ ${p.destination}', style: const TextStyle(color: Color(0xffffd36a), fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              if (p.details.isNotEmpty)
                                LinkifiedText(text: p.details, linkColor: const Color(0xff66d9ff), style: const TextStyle(color: Color(0xffd6cdf3), fontSize: 12, height: 1.7)),
                              Row(children: [
                                Flexible(
                                  child: InkWell(
                                    onTap: () => _openProfile(p.uid, p.name),
                                    child: Text('${p.name}${p.travelDate.isEmpty ? '' : ' · ${p.travelDate}'} · ${p.seats} نفر', style: const TextStyle(color: Color(0xffb9a5ff), fontSize: 11.5, decoration: TextDecoration.underline)),
                                  ),
                                ),
                                _tick(p.badge),
                              ]),
                            ]),
                          ),
                          if (p.mine)
                            IconButton(
                              tooltip: 'بستن آگهی',
                              onPressed: () async {
                                await ChatService.closePost(p.id);
                                final posts = await ChatService.posts(_city);
                                if (mounted) setState(() => _posts = posts);
                              },
                              icon: const Icon(Icons.close_rounded, color: Color(0xffff8f8f)),
                            ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.mine;
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onLongPress: () => _messageMenu(m),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xff143a4a) : _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                    onTap: () => _openProfile(m.uid, m.name),
                    child: Text(m.name, style: const TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                  ),
                  _tick(m.badge),
                ]),
              LinkifiedText(text: m.text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.8)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_time(m.at), style: const TextStyle(color: Color(0xff8fa5b2), fontSize: 10.5)),
                if (!mine) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _messageMenu(m),
                    child: const Text('گزارش', style: TextStyle(color: Color(0xffff8f8f), fontSize: 10.5)),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: const Text('چت‌روم سایروس', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
          actions: [
            if (_cities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _city,
                    dropdownColor: _panel,
                    iconEnabledColor: _gold,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    items: [for (final c in _cities) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) {
                      if (v == null || v == _city) return;
                      setState(() => _city = v);
                      _enterRoom();
                    },
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _loadingRooms
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : _roomsFailed
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('دریافت اتاق‌ها ناموفق بود.', style: TextStyle(color: Colors.white70)),
                        if (BadgeService.lastError.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(BadgeService.lastError, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton(onPressed: _loadRooms, child: const Text('تلاش دوباره', style: TextStyle(color: _gold))),
                      ]),
                    )
                  : Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
                          child: Row(children: [
                            for (final e in [(false, '🌍 چت همگانی'), (true, '🤝 همسفر')])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_companion == e.$1) return;
                                    setState(() => _companion = e.$1);
                                    _enterRoom();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: _companion == e.$1
                                          ? LinearGradient(colors: e.$1
                                              ? const [Color(0xff8b6cff), Color(0xffff5fb0)]
                                              : const [Color(0xffffe08a), Color(0xffff8a3d)])
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      e.$2,
                                      style: TextStyle(
                                        color: _companion == e.$1 ? (e.$1 ? Colors.white : _bg) : const Color(0xff8fa5b2),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                        _statusBar(),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(NT.t('chat_rules'),
                              textAlign: TextAlign.center, style: TextStyle(color: Color(0xff8fa5b2), fontSize: 11)),
                        ),
                        if (_companion) _postsSection(),
                        Expanded(
                          child: _messages.isEmpty
                              ? Center(
                                  child: Text(
                                    _open ? 'هنوز پیامی نیست. شما شروع کنید 👋' : 'اتاق در ساعت‌های اعلام‌شده باز می‌شود.',
                                    style: const TextStyle(color: Color(0xff8fa5b2), fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  itemCount: _messages.length,
                                  itemBuilder: (_, i) => _bubble(_messages[i]),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: Opacity(
                            opacity: _open ? 1 : 0.5,
                            child: Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  enabled: _open,
                                  maxLength: 200,
                                  minLines: 1,
                                  maxLines: 3,
                                  onSubmitted: (_) => _send(),
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                  decoration: InputDecoration(
                                    hintText: _open ? 'پیام خود را بنویسید...' : 'اتاق بسته است',
                                    hintStyle: const TextStyle(color: Color(0xff8fa5b2)),
                                    counterText: '',
                                    filled: true,
                                    fillColor: _panel,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  onPressed: (_open && !_sending) ? _send : null,
                                  child: _sending
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('ارسال', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
