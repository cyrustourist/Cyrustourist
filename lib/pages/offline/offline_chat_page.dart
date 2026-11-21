import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/language/menu_translations.dart';
import '../../services/offline_mesh_service.dart';
import 'file_transfer_page.dart';
import '../groups/chat_media_save.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);

/// چت گروهی آفلاین گردشگران: بدون اینترنت، بین گوشی‌های نزدیک.
/// با [room] و [title] برای یک گروه یا گفتگوی شخصی مشخص هم استفاده می‌شود.
class OfflineChatPage extends StatefulWidget {
  const OfflineChatPage({super.key, this.room = '', this.title});
  final String room;
  final String? title;

  @override
  State<OfflineChatPage> createState() => _OfflineChatPageState();
}

class _OfflineChatPageState extends State<OfflineChatPage> {
  final _svc = OfflineMeshService.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _starting = false;

  // پیام صوتی: ضبط با یک لمس شروع و با لمس دوم ارسال می‌شود (حداکثر ۳۰ ثانیه)
  static const int _maxRecSecs = 30;
  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playSub;
  Timer? _recTimer;
  bool _recording = false;
  int _recSecs = 0;
  String? _recPath;
  String? _playingId;

  bool get _fa => MenuLanguage.current == 'fa';
  List<OfflineMsg> get _msgs => _svc.messagesFor(widget.room);
  String _t(String fa, String en) => _fa ? fa : en;

  @override
  void initState() {
    super.initState();
    _svc.activeRoom = widget.room;
    _svc.unread.remove(widget.room);
    _svc.addListener(_onChange);
    _playSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _recTimer?.cancel();
    _playSub?.cancel();
    _rec.dispose();
    _player.dispose();
    if (_svc.activeRoom == widget.room) _svc.activeRoom = null;
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _toggle() async {
    if (_starting) return;
    if (_svc.running) {
      await _svc.stop();
      return;
    }
    setState(() => _starting = true);
    final ok = await _svc.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (!ok) {
      final e = _svc.lastError;
      final up = e.toUpperCase();
      String msg;
      if (_svc.status == 'perm') {
        msg = _t('مجوزهای برنامه را بدهید (مکان و دستگاه‌های نزدیک) و GPS را روشن کنید', 'Allow the app permissions (Location and Nearby devices) and turn on location');
      } else if (up.contains('PERMISSION')) {
        msg = _t('مجوز «دستگاه‌های نزدیک» و «مکان» را از تنظیمات برنامه فعال کنید', 'Enable “Nearby devices” and Location permissions in the app settings');
      } else if (up.contains('BLUETOOTH') || up.contains('WIFI')) {
        msg = _t('بلوتوث و وای‌فای گوشی را روشن کنید (نیازی به اینترنت نیست)', 'Turn on Bluetooth and Wi‑Fi (no internet needed)');
      } else {
        msg = _t('شبکه‌ی آفلاین روشن نشد. بلوتوث، وای‌فای و GPS را روشن کنید و دوباره تلاش کنید', 'Could not start. Turn on Bluetooth, Wi‑Fi and location, then try again');
      }
      if (e.isNotEmpty) msg = '$msg\n(${e.length > 70 ? e.substring(0, 70) : e})';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 7),
        content: Text(msg),
        action: SnackBarAction(label: _t('تنظیمات', 'Settings'), onPressed: openAppSettings),
      ));
    }
  }

  void _send() {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    _ctrl.clear();
    _svc.send(t, room: widget.room);
  }

  @override
  Widget build(BuildContext context) {
    final on = _svc.running;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(widget.title ?? _t('شبکه‌ی آفلاین گردشگران', 'Offline Tourist Network'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _statusCard(on),
              Expanded(child: _list(on)),
              if (on) _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(bool on) {
    final n = _svc.peers.length;
    final people = _svc.people;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.35))),
      child: Column(
        children: [
          Row(
            children: [
              Icon(on ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded, color: on ? Colors.greenAccent : Colors.white54, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  on ? _t('روشن است • $n گوشی متصل • ${people.length} نفر در شبکه', 'On • $n connected • ${people.length} in network') : _t('خاموش است', 'Off'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: on ? Colors.redAccent : _gold, foregroundColor: on ? Colors.white : const Color(0xff06121d)),
                onPressed: _toggle,
                child: _starting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(on ? _t('خاموش', 'Stop') : _t('روشن کردن', 'Start'), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (on && people.isNotEmpty && widget.room.isEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(_t('افراد شبکه', 'People in network'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [for (final p in people) _peerRow(p)],
              ),
            ),
          ],
          if (on && people.isNotEmpty && widget.room.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: people
                    .map((p) => Chip(
                          label: Text(p.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          backgroundColor: _bg,
                          side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ردیف یک نفر در شبکه: نام (و فاصله اگر از راه گوشی‌های واسط است) + کلید پیام + کلید فایل (فقط برای گوشی وصل مستقیم)
  Widget _peerRow(OfflinePerson p) {
    final initial = p.name.isEmpty ? '?' : String.fromCharCode(p.name.runes.first);
    final unread = _svc.unread[_svc.dmRoomWith(p.uid)] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: _bg, child: Text(initial, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                if (!p.direct)
                  Text(_t('از راه ${p.hops - 1} گوشی واسط', 'via ${p.hops - 1} relay phone(s)'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: _gold, visualDensity: VisualDensity.compact),
            onPressed: () => _openDm(p),
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_rounded, size: 18)),
            label: Text(_t('پیام', 'Message'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          if (p.direct)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xff29e0ad), visualDensity: VisualDensity.compact),
              onPressed: () => _sendFileTo(p),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(_t('فایل', 'File'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  /// گفتگوی دونفره با یک گوشی نزدیک؛ نام اتاق برای هر دو گوشی یکی است (شناسه‌ها مرتب می‌شوند).
  /// توجه: پیام‌ها مثل گروه‌ها روی همان شبکه پخش می‌شوند و رمزنگاری نشده‌اند.
  Future<void> _openDm(OfflinePerson p) async {
    final ids = <String>[_svc.myUid, p.uid]..sort();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OfflineChatPage(room: 'n${ids.join('_')}', title: p.name)));
    if (mounted) setState(() {});
  }

  /// ارسال فایل به یک گوشی نزدیک: شبکه‌ی چت خاموش می‌شود و صفحه‌ی انتقال فایل باز می‌شود.
  Future<void> _sendFileTo(OfflinePerson p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          content: Text(
            _t(
              'برای ارسال فایل به «${p.name}»، شبکه‌ی چت خاموش می‌شود. از او بخواهید در گوشی خودش «ارسال عکس، فیلم و فایل» را باز کند و «دیده شدن» را بزند. ادامه می‌دهید؟',
              'File transfer to “${p.name}” turns the chat network off. Ask them to open “Send photos, videos & files” and tap “Be visible”. Continue?',
            ),
            style: const TextStyle(color: Colors.white, height: 1.8),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('خیر', 'No'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('بله', 'Yes'), style: const TextStyle(color: _gold))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _svc.stop();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FileTransferPage(target: p.name)));
    if (mounted) setState(() {});
  }

  Widget _list(bool on) {
    if (!on && _msgs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.room.isEmpty
                ? _t(
                    'وقتی اینترنت قطع است یا در سفر هستید، شبکه را روشن کنید تا با گوشی‌های نزدیک (چند ده متر) پیام گروهی رد و بدل کنید.\nهر کس شبکه را روشن کند خودکار در فهرست افراد می‌آید و پیام‌ها از راه گوشی‌های دیگر هم رد می‌شوند.',
                    'When there is no internet, turn this on to chat with nearby phones (tens of meters).\nAnyone who starts the network is added to the list automatically, and messages hop through other phones.',
                  )
                : _t(
                    'شبکه را روشن کنید تا با گوشی‌های نزدیک گفتگو کنید.\nطرف مقابل هم باید شبکه را روشن کند؛ اگر دور باشد پیام از راه گوشی‌های دیگر می‌رسد.',
                    'Turn the network on to chat with nearby phones.\nThe other person must start the network too; if far away, messages hop through other phones.',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.7),
          ),
        ),
      );
    }
    if (_msgs.isEmpty) {
      return Center(child: Text(_t('در جستجوی گوشی‌های اطراف…', 'Looking for nearby phones…'), style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _msgs.length,
      itemBuilder: (_, i) {
        final m = _msgs[i];
        final t = DateTime.fromMillisecondsSinceEpoch(m.ts);
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        return Align(
          alignment: m.mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: m.mine ? const Color(0xff1b4a6b) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: m.mine ? 0.5 : 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!m.mine) Text(m.name, style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 12)),
                if (m.imagePath != null)
                  GestureDetector(
                    onTap: () => _openPhoto(m.imagePath!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(m.imagePath!), width: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 80, child: Icon(Icons.broken_image_rounded, color: Colors.white38))),
                      ),
                    ),
                  ),
                if (m.audioPath != null)
                  InkWell(
                    onTap: () => _togglePlay(m),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_playingId == m.id ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, color: _gold, size: 36),
                          const SizedBox(width: 8),
                          const Icon(Icons.graphic_eq_rounded, color: Colors.white38),
                          const SizedBox(width: 8),
                          Text(_fmt(m.audioSecs), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                if (m.text.isNotEmpty) Text(m.text, style: const TextStyle(color: Colors.white, height: 1.5)),
                Text('$hh:$mm', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ارسال عکس به شبکه (برای پخش چندپرشی تا ۱۲۸۰ پیکسل کوچک می‌شود؛ برای کیفیت کامل از «ارسال فایل» استفاده کنید).
  Future<void> _sendPhoto() async {
    if (!_svc.running) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('ابتدا شبکه را روشن کنید', 'Start the network first'))));
      return;
    }
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2560, maxHeight: 2560, imageQuality: 90);
      if (x == null) return;
      final ok = await _svc.sendImage(x.path, room: widget.room);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(!ok
            ? _t('شبکه روشن نیست', 'Network is off')
            : _svc.peers.isEmpty
                ? _t('هنوز گوشی‌ای وصل نیست؛ عکس به گوشی‌هایی که نزدیک شوند می‌رسد', 'No phone connected yet; the photo will reach phones that come near')
                : _t('عکس در حال ارسال است؛ تا رسیدن کامل منتظر بمانید', 'Photo is being sent; it may take a moment')),
      ));
    } catch (_) {}
  }

  String _fmt(int secs) => '${(secs ~/ 60)}:${(secs % 60).toString().padLeft(2, '0')}';

  void _snack(String fa, String en) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(fa, en))));
  }

  Future<void> _startRec() async {
    if (_recording) return;
    if (!_svc.running) {
      _snack('ابتدا شبکه را روشن کنید', 'Start the network first');
      return;
    }
    try {
      if (!await _rec.hasPermission()) {
        _snack('مجوز میکروفن را بدهید', 'Allow microphone permission');
        return;
      }
      await _player.stop();
      final path = '${Directory.systemTemp.path}/vm_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 24000, sampleRate: 16000, numChannels: 1), path: path);
      _recPath = path;
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recSecs = 0;
        _playingId = null;
      });
      _recTimer?.cancel();
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        setState(() => _recSecs++);
        if (_recSecs >= _maxRecSecs) _finishRec(send: true);
      });
    } catch (_) {
      _snack('ضبط صدا شروع نشد', 'Could not start recording');
    }
  }

  Future<void> _finishRec({required bool send}) async {
    if (!_recording) return;
    _recTimer?.cancel();
    _recTimer = null;
    final secs = _recSecs;
    String? path;
    try {
      path = await _rec.stop();
    } catch (_) {}
    path ??= _recPath;
    if (mounted) setState(() => _recording = false);
    if (path == null) return;
    if (!send || secs < 1) {
      try {
        await File(path).delete();
      } catch (_) {}
      return;
    }
    final ok = await _svc.sendAudio(path, secs, room: widget.room);
    if (!ok) {
      _snack('شبکه روشن نیست', 'Network is off');
    } else if (_svc.peers.isEmpty) {
      _snack('هنوز گوشی‌ای وصل نیست؛ پیام صوتی به گوشی‌هایی که نزدیک شوند می‌رسد', 'No phone connected yet; the voice message will reach phones that come near');
    }
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _togglePlay(OfflineMsg m) async {
    final path = m.audioPath;
    if (path == null) return;
    try {
      if (_playingId == m.id) {
        await _player.stop();
        if (mounted) setState(() => _playingId = null);
        return;
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _playingId = m.id);
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _savePhoto(String path) async {
    final ok = await saveLocalImageToGallery(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? _t('عکس در گالری (پوشهٔ Cyrustourist) ذخیره شد', 'Photo saved to gallery (Cyrustourist folder)') : _t('ذخیره نشد', 'Could not save')),
    ));
  }

  void _openPhoto(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.file(File(path))),
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                children: [
                  IconButton(
                    tooltip: _t('ذخیره در گالری', 'Save to gallery'),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => _savePhoto(path),
                    icon: const Icon(Icons.download_rounded, color: _gold),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: _card,
      child: Row(
        children: [
          IconButton(
            tooltip: _t('لغو', 'Cancel'),
            onPressed: () => _finishRec(send: false),
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
          ),
          const Icon(Icons.fiber_manual_record_rounded, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_t('در حال ضبط', 'Recording')}  ${_fmt(_recSecs)} / ${_fmt(_maxRecSecs)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          CircleAvatar(
            backgroundColor: _gold,
            child: IconButton(
              tooltip: _t('ارسال', 'Send'),
              onPressed: () => _finishRec(send: true),
              icon: const Icon(Icons.send_rounded, color: Color(0xff06121d), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    if (_recording) return _recordBar();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: _card,
      child: Row(
        children: [
          IconButton(
            onPressed: _sendPhoto,
            tooltip: _t('ارسال عکس', 'Send photo'),
            icon: const Icon(Icons.photo_rounded, color: _gold),
          ),
          IconButton(
            onPressed: _startRec,
            tooltip: _t('پیام صوتی', 'Voice message'),
            icon: const Icon(Icons.mic_rounded, color: _gold),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                counterText: '',
                hintText: widget.room.isEmpty ? _t('پیام برای گروه…', 'Message the group…') : _t('پیام…', 'Message…'),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _gold,
            child: IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded, color: Color(0xff06121d), size: 20)),
          ),
        ],
      ),
    );
  }
}
