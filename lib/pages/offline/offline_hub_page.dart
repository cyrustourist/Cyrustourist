import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../services/offline_mesh_service.dart';
import 'file_transfer_page.dart';
import 'live_call_page.dart';
import 'live_video_page.dart';
import 'offline_chat_page.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _sky = Color(0xff66d9ff);
const Color _muted = Color(0xff8fa5b2);

/// منوی «شبکه‌ی آفلاین گردشگران»: چت گروهی/شخصی، ارسال عکس و فیلم و فایل، تماس صوتی زنده.
/// هر بخش اتصال جداگانهٔ خودش را دارد.
class OfflineHubPage extends StatefulWidget {
  const OfflineHubPage({super.key});

  @override
  State<OfflineHubPage> createState() => _OfflineHubPageState();
}

class _OfflineHubPageState extends State<OfflineHubPage> {
  final OfflineMeshService _svc = OfflineMeshService.instance;

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
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OfflineChatPage()));
    if (mounted) setState(() {});
  }

  /// شبکهٔ چت و بخش‌های دیگر هم‌زمان نمی‌توانند فعال باشند؛ قبل از رفتن به آن‌ها چت خاموش می‌شود.
  Future<bool> _stopChatFor(String fa, String en) async {
    if (!_svc.running) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: _card,
          content: Text(_t('برای $fa، شبکه‌ی چت آفلاین خاموش می‌شود. ادامه می‌دهید؟', 'The offline chat network will be turned off for $en. Continue?'), style: const TextStyle(color: Colors.white, height: 1.7)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('خیر', 'No'), style: const TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('بله', 'Yes'), style: const TextStyle(color: _gold))),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return false;
    await _svc.stop();
    return mounted;
  }

  Future<void> _openFiles() async {
    if (!await _stopChatFor('جابه‌جایی فایل', 'file transfer')) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FileTransferPage()));
    if (mounted) setState(() {});
  }

  Future<void> _openCall() async {
    if (!await _stopChatFor('تماس صوتی', 'the voice call')) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveCallPage()));
    if (mounted) setState(() {});
  }

  Future<void> _openVideo() async {
    if (!await _stopChatFor('تماس تصویری', 'the video call')) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LiveVideoPage()));
    if (mounted) setState(() {});
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
          title: Text(_t('شبکه‌ی آفلاین گردشگران', 'Offline Tourist Network'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 17)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _statusCard(),
              const SizedBox(height: 18),
              Text(_t('چه کاری می‌خواهید انجام دهید؟', 'What would you like to do?'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 10),
              _tile(
                icon: Icons.chat_rounded,
                color: _gold,
                title: _t('چت گروهی و شخصی', 'Group & private chat'),
                sub: _t('پیام به همه‌ی گوشی‌های نزدیک، یا گفتگوی دونفره', 'Message everyone nearby, or chat one-to-one'),
                onTap: _openChat,
              ),
              _tile(
                icon: Icons.swap_horiz_rounded,
                color: _teal,
                title: _t('ارسال عکس، فیلم و فایل', 'Send photos, videos & files'),
                sub: _t('با کیفیت اصلی و بدون فشرده‌سازی؛ ذخیره‌ی خودکار در گالری', 'Original quality, no compression; saved to the gallery automatically'),
                onTap: _openFiles,
              ),
              _tile(
                icon: Icons.call_rounded,
                color: _sky,
                title: _t('تماس صوتی زنده', 'Live voice call'),
                sub: _t('تماس مستقیم از راه وای‌فای، بدون اینترنت', 'Direct call over Wi‑Fi, no internet'),
                badge: _t('آزمایشی', 'Beta'),
                onTap: _openCall,
              ),
              _tile(
                icon: Icons.videocam_rounded,
                color: _teal,
                title: _t('تماس تصویری زنده', 'Live video call'),
                sub: _t('تصویر و صدا مستقیم بین دو گوشی روی یک وای‌فای، بدون اینترنت', 'Video and audio straight between two phones on the same Wi‑Fi, no internet'),
                badge: _t('آزمایشی', 'Beta'),
                onTap: _openVideo,
              ),
              const SizedBox(height: 14),
              Text(
                _t('بلوتوث، وای‌فای و GPS باید روشن باشند؛ اینترنت لازم نیست. هر بخش اتصال جداگانه‌ای دارد.', 'Bluetooth, Wi‑Fi and location must be on; no internet needed. Each section uses its own connection.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    final on = _svc.running;
    final n = _svc.peers.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold.withValues(alpha: 0.35))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: (on ? _teal : Colors.white54).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(on ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded, color: on ? _teal : Colors.white54, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(on ? _t('شبکه‌ی چت روشن است', 'Chat network is on') : _t('شبکه‌ی چت خاموش است', 'Chat network is off'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(on ? _t('$n گوشی متصل', '$n device(s) connected') : _t('برای چت، وارد «چت» شوید و روشن کنید', 'To chat, open “Chat” and start it'), style: const TextStyle(color: _muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onTap, String? badge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: badge == null ? const Color(0xff1d3a4d) : color.withValues(alpha: 0.5), width: badge == null ? 1 : 1.5)),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(999)),
                              child: Text(badge, style: const TextStyle(color: _bg, fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.8)),
                    ],
                  ),
                ),
                Icon(MenuLanguage.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
