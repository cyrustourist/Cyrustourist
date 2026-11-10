import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/language/menu_translations.dart';
import '../../services/file_transfer_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

/// جابه‌جایی عکس، فیلم و فایل بین دو گوشی بدون اینترنت (کیفیت اصلی، بدون فشرده‌سازی).
/// یک گوشی «دیده می‌شود» و گوشی دیگر او را پیدا می‌کند؛ بعد از تأیید کد، هر دو می‌توانند بفرستند و بگیرند.
class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key, this.target = ''});

  /// نام گوشی مقصد (وقتی از فهرست «افراد نزدیک» می‌آید)؛ در فهرست جستجو برجسته می‌شود.
  final String target;

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  final FileTransferService _svc = FileTransferService.instance;
  bool _busy = false;
  bool _dlg = false;

  bool get _fa => MenuLanguage.current == 'fa';
  String _t(String fa, String en) => _fa ? fa : en;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.reset();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _svc.close();
    try {
      FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    final p = _svc.pending;
    if (p != null && !_dlg) _confirm(p);
  }

  Future<void> _confirm(PendingConn p) async {
    _dlg = true;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          title: Text(_t('اتصال به «${p.name}»؟', 'Connect to “${p.name}”?'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('این کد باید در هر دو گوشی یکی باشد:', 'This code must be the same on both phones:'), style: const TextStyle(color: Colors.white70, height: 1.7)),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(p.token, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 4)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('رد', 'Decline'), style: const TextStyle(color: Colors.white70))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_t('قبول', 'Accept'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
    _dlg = false;
    if (ok == true) {
      await _svc.accept();
    } else {
      await _svc.reject();
    }
  }

  Future<void> _start(bool wait) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = wait ? await _svc.startWaiting() : await _svc.startSearch();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _snack(_errText());
  }

  String _errText() {
    switch (_svc.error) {
      case 'perm':
        return _t('مجوزهای «مکان» و «دستگاه‌های نزدیک» را بدهید و GPS را روشن کنید', 'Allow Location and Nearby devices permissions and turn on location');
      case 'start':
        return _t('شروع نشد. بلوتوث، وای‌فای و GPS را روشن کنید و دوباره تلاش کنید (اینترنت لازم نیست)', 'Could not start. Turn on Bluetooth, Wi‑Fi and location, then try again (no internet needed)');
      case 'rejected':
        return _t('اتصال انجام نشد (رد شد یا کدها یکی نبود)', 'Connection was declined');
      case 'failed':
        return _t('اتصال برقرار نشد. دوباره تلاش کنید', 'Could not connect. Try again');
      default:
        return '';
    }
  }

  void _snack(String msg, {bool settings = false}) {
    if (msg.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(msg),
      action: settings || _svc.error == 'perm' ? SnackBarAction(label: _t('تنظیمات', 'Settings'), onPressed: openAppSettings) : null,
    ));
  }

  Future<void> _pick(FileType type) async {
    try {
      final r = await FilePicker.platform.pickFiles(type: type, allowMultiple: true, withData: false, withReadStream: false);
      if (r == null || !mounted) return;
      var sent = 0;
      for (final f in r.files) {
        final path = f.path;
        if (path == null) continue;
        if (await _svc.sendFile(path, f.name, f.size)) sent++;
      }
      if (!mounted) return;
      if (sent == 0) {
        _snack(_t('ارسال نشد. اتصال را بررسی کنید', 'Could not send. Check the connection'));
      }
    } catch (_) {
      if (mounted) _snack(_t('انتخاب فایل انجام نشد', 'Could not pick files'));
    }
  }

  String _size(int b) {
    if (b <= 0) return '';
    if (b < 1024 * 1024) return '${(b / 1024).ceil()} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(_t('جابه‌جایی فایل بدون اینترنت', 'Offline file transfer'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    switch (_svc.stage) {
      case 'linked':
        return _linked();
      case 'wait':
        return _center(
          icon: Icons.visibility_rounded,
          title: _t('گوشی شما دیده می‌شود', 'Your phone is visible'),
          text: _t('در گوشی مقابل همین صفحه را باز کنید و «پیدا کردن گوشی (برای ارسال)» را بزنید.', 'On the other phone open this page and tap “Find a phone (to send)”.'),
          action: _outlined(_t('لغو', 'Cancel'), _svc.reset),
        );
      case 'search':
        return _search();
      case 'connecting':
        return _center(
          icon: Icons.sync_rounded,
          title: _t('در حال اتصال…', 'Connecting…'),
          text: _t('کد تأیید را در هر دو گوشی قبول کنید.', 'Accept the confirmation code on both phones.'),
          spinner: true,
          action: _outlined(_t('لغو', 'Cancel'), _svc.reset),
        );
      case 'lost':
        return _center(
          icon: Icons.link_off_rounded,
          title: _t('ارتباط قطع شد', 'Connection lost'),
          text: _t('دو گوشی را نزدیک هم نگه دارید و دوباره وصل شوید.', 'Keep the phones close and connect again.'),
          action: _big(Icons.refresh_rounded, _t('بازگشت', 'Back'), _svc.reset),
        );
      default:
        return _home();
    }
  }

  Widget _home() {
    final err = _errText();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.35))),
          child: Text(
            _t(
              'عکس، فیلم و فایل را مستقیم از گوشی به گوشی بفرستید؛ بدون اینترنت، بدون فشرده‌سازی و با کیفیت اصلی. فایل دریافتی خودکار در گالری (عکس و فیلم) یا پوشهٔ Download ذخیره می‌شود.',
              'Send photos, videos and files phone to phone: no internet, no compression, original quality. Received files are saved automatically to the gallery (photos & videos) or the Downloads folder.',
            ),
            style: const TextStyle(color: Colors.white70, height: 1.8),
          ),
        ),
        const SizedBox(height: 18),
        if (widget.target.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _teal.withValues(alpha: 0.6))),
            child: Text(
              _t('ارسال برای «${widget.target}»: از او بخواهید «دیده شدن» را بزند و شما «پیدا کردن گوشی» را بزنید.', 'Sending to “${widget.target}”: ask them to tap “Be visible”, then tap “Find a phone”.'),
              style: const TextStyle(color: Colors.white, height: 1.8),
            ),
          ),
        _step('۱', _t('در یک گوشی «دیده شدن» را بزنید.', 'On one phone tap “Be visible”.')),
        _step('۲', _t('در گوشی دیگر «پیدا کردن گوشی» را بزنید و نام اولی را انتخاب کنید.', 'On the other tap “Find a phone” and pick the first one.')),
        _step('۳', _t('کد را در هر دو گوشی قبول کنید و فایل‌ها را بفرستید.', 'Accept the code on both and send files.')),
        const SizedBox(height: 18),
        if (err.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent, height: 1.7)),
          ),
        _big(Icons.visibility_rounded, _t('دیده شدن (برای دریافت)', 'Be visible (to receive)'), _busy ? null : () => _start(true)),
        _big(Icons.search_rounded, _t('پیدا کردن گوشی (برای ارسال)', 'Find a phone (to send)'), _busy ? null : () => _start(false)),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: CircularProgressIndicator(color: _gold))),
        const SizedBox(height: 12),
        Text(
          _t('با شروع این بخش، شبکهٔ چت آفلاین خاموش می‌شود. بلوتوث، وای‌فای و GPS باید روشن باشند.', 'Starting this turns the offline chat network off. Bluetooth, Wi‑Fi and location must be on.'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.7),
        ),
      ],
    );
  }

  Widget _search() {
    final list = _svc.found.entries.toList();
    if (widget.target.isNotEmpty) {
      list.sort((a, b) => (b.value == widget.target ? 1 : 0).compareTo(a.value == widget.target ? 1 : 0));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
            const SizedBox(width: 10),
            Expanded(child: Text(_t('در جستجوی گوشی‌های دیده‌شونده…', 'Looking for visible phones…'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(_t('هنوز گوشی‌ای پیدا نشد.\nدر گوشی مقابل «دیده شدن» را بزنید و نزدیک هم باشید.', 'No phone found yet.\nOn the other phone tap “Be visible” and stay close.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.8)),
          )
        else
          for (final e in list)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: e.value == widget.target ? _teal : _gold.withValues(alpha: 0.25), width: e.value == widget.target ? 2 : 1)),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: _teal),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
                    onPressed: () => _svc.connectTo(e.key),
                    child: Text(_t('اتصال', 'Connect'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 10),
        _outlined(_t('لغو', 'Cancel'), _svc.reset),
      ],
    );
  }

  Widget _linked() {
    final items = _svc.items;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _teal.withValues(alpha: 0.6))),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: _teal, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(_t('متصل به ${_svc.peerName}', 'Connected to ${_svc.peerName}'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              TextButton(
                onPressed: _svc.reset,
                child: Text(_t('قطع', 'Disconnect'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(child: _pickBtn(Icons.photo_library_rounded, _t('عکس و ویدیو', 'Photos & videos'), () => _pick(FileType.media))),
              const SizedBox(width: 10),
              Expanded(child: _pickBtn(Icons.insert_drive_file_rounded, _t('فایل', 'Files'), () => _pick(FileType.any))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_t('فایلی انتخاب نشده.\nتا پایان انتقال این صفحه را باز نگه دارید.', 'Nothing sent yet.\nKeep this page open until transfers finish.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.8))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _row(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _row(TransferItem it) {
    String status;
    Color color = Colors.white60;
    switch (it.state) {
      case 'done':
        if (it.mine) {
          status = _t('ارسال شد', 'Sent');
        } else {
          status = it.saved == 'gallery' ? _t('ذخیره شد در گالری (پوشهٔ Cyrustourist)', 'Saved to gallery (Cyrustourist)') : _t('ذخیره شد در Download/Cyrustourist', 'Saved to Download/Cyrustourist');
        }
        color = _teal;
        break;
      case 'saving':
        status = _t('در حال ذخیره…', 'Saving…');
        break;
      case 'failed':
        status = _t('ناموفق', 'Failed');
        color = Colors.redAccent;
        break;
      default:
        status = it.mine ? _t('در حال ارسال…', 'Sending…') : _t('در حال دریافت…', 'Receiving…');
    }
    final sz = _size(it.size);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          Icon(it.mine ? Icons.north_east_rounded : Icons.south_west_rounded, color: it.mine ? _gold : _teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name.isEmpty ? '…' : it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(sz.isEmpty ? status : '$status · $sz', style: TextStyle(color: color, fontSize: 12)),
                if (it.state == 'run' && it.size > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: it.progress, minHeight: 5, backgroundColor: Colors.white12, color: _gold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickBtn(IconData icon, String text, VoidCallback onTap) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg, padding: const EdgeInsets.symmetric(vertical: 14)),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, backgroundColor: _gold, child: Text(n, style: const TextStyle(color: _bg, fontWeight: FontWeight.w900, fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.6))),
        ],
      ),
    );
  }

  Widget _big(IconData icon, String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg, disabledBackgroundColor: Colors.white12, padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }

  Widget _outlined(String text, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12)),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _center({required IconData icon, required String title, required String text, Widget? action, bool spinner = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _gold, size: 54),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.8)),
            if (spinner) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator(color: _gold)),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 20), child: action),
          ],
        ),
      ),
    );
  }
}
