import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../services/offline_mesh_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);

/// چت گروهی آفلاین گردشگران: بدون اینترنت، بین گوشی‌های نزدیک.
class OfflineChatPage extends StatefulWidget {
  const OfflineChatPage({super.key});

  @override
  State<OfflineChatPage> createState() => _OfflineChatPageState();
}

class _OfflineChatPageState extends State<OfflineChatPage> {
  final _svc = OfflineMeshService.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _starting = false;

  bool get _fa => MenuLanguage.current == 'fa';
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
      final msg = _svc.status == 'perm'
          ? _t('مجوز مکان و بلوتوث/وای‌فای نزدیک را بدهید و GPS را روشن کنید', 'Allow location and Bluetooth/Nearby Wi‑Fi permissions and turn on location')
          : _t('شبکه‌ی آفلاین روشن نشد. دوباره تلاش کنید', 'Could not start the offline network. Try again');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _send() {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    _ctrl.clear();
    _svc.send(t);
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
          title: Text(_t('شبکه‌ی آفلاین گردشگران', 'Offline Tourist Network'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
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
    if (!on && _svc.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _t(
              'وقتی اینترنت قطع است یا در سفر هستید، شبکه را روشن کنید تا با گوشی‌های نزدیک (چند ده متر) پیام گروهی رد و بدل کنید.\nهمه باید این صفحه را باز و شبکه را روشن کنند.',
              'When there is no internet, turn this on to chat with nearby phones (tens of meters).\nEveryone must open this page and start the network.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.7),
          ),
        ),
      );
    }
    if (_svc.messages.isEmpty) {
      return Center(child: Text(_t('در جستجوی گوشی‌های اطراف…', 'Looking for nearby phones…'), style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _svc.messages.length,
      itemBuilder: (_, i) {
        final m = _svc.messages[i];
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
                Text(m.text, style: const TextStyle(color: Colors.white, height: 1.5)),
                Text('$hh:$mm', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: _card,
      child: Row(
        children: [
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
                hintText: _t('پیام برای گروه…', 'Message the group…'),
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
