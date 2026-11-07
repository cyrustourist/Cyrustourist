import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/language/menu_translations.dart';
import '../../services/offline_mesh_service.dart';

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

  bool get _fa => MenuLanguage.current == 'fa';
  List<OfflineMsg> get _msgs => _svc.messagesFor(widget.room);
  String _t(String fa, String en) => _fa ? fa : en;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
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
                  on ? _t('روشن است • $n گوشی متصل', 'On • $n device(s) connected') : _t('خاموش است', 'Off'),
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
          if (on && n > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _svc.peers.values
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

  Widget _list(bool on) {
    if (!on && _msgs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.room.isEmpty
                ? _t(
                    'وقتی اینترنت قطع است یا در سفر هستید، شبکه را روشن کنید تا با گوشی‌های نزدیک (چند ده متر) پیام گروهی رد و بدل کنید.\nهمه باید این صفحه را باز و شبکه را روشن کنند.',
                    'When there is no internet, turn this on to chat with nearby phones (tens of meters).\nEveryone must open this page and start the network.',
                  )
                : _t(
                    'شبکه را روشن کنید تا با گوشی‌های نزدیک گفتگو کنید.\nطرف مقابل هم باید همین گفتگو را باز و شبکه را روشن کند.',
                    'Turn the network on to chat with nearby phones.\nThe other person must open this chat and start the network too.',
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
                if (m.text.isNotEmpty) Text(m.text, style: const TextStyle(color: Colors.white, height: 1.5)),
                Text('$hh:$mm', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ارسال عکس با کیفیت بالا (حداکثر ۲۵۶۰ پیکسل) مستقیم به گوشی‌های نزدیک.
  Future<void> _sendPhoto() async {
    if (!_svc.running || _svc.peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('ابتدا شبکه را روشن کنید و منتظر وصل شدن گوشی‌ها بمانید', 'Start the network and wait for phones to connect first'))));
      return;
    }
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2560, maxHeight: 2560, imageQuality: 90);
      if (x == null) return;
      final ok = await _svc.sendImage(x.path, room: widget.room);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? _t('عکس در حال ارسال است؛ تا رسیدن کامل منتظر بمانید', 'Photo is being sent; it may take a moment') : _t('گوشی‌ای وصل نیست', 'No phone connected')),
      ));
    } catch (_) {}
  }

  void _openPhoto(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: InteractiveViewer(child: Image.file(File(path))),
      ),
    );
  }

  Widget _inputBar() {
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
