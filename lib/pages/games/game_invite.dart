import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/badge_service.dart';
import '../../services/public_link_service.dart';
import '../groups/group_ui.dart';
import 'game_wheel.dart';

/// معرفی به دوستان: لینک بازارِ سایروس توریست با کد معرف شخصی (ساخته‌شده از شناسه‌ی کاربر).
class InviteStore extends ChangeNotifier {
  InviteStore._();
  static final InviteStore instance = InviteStore._();
  static const String _k = 'cyrus_invite_v1';

  bool loaded = false;
  String code = '';
  int shares = 0;
  String rewardDay = '';
  int todayCount = 0; // اشتراک‌گذاری‌های پاداش‌گرفته‌ی امروز
  int earned = 0; // مجموع سکه‌ی گرفته‌شده از معرفی

  /// پاداش هر بار ارسال لینک و سقف روزانه (برای جلوگیری از سوءاستفاده)
  static const int rewardCoins = 20;
  static const int dailyCap = 5;
  String friendCode = '';

  /// لینک بازار با کد معرف (همان لینک بازار برنامه، با شناسه‌ی کاربر)
  String get link {
    final base = PublicLinkService.bazaarUrl;
    final c = code.isEmpty ? 'share' : code;
    return base.contains('ref=') ? base.replaceFirst(RegExp(r'ref=[^&]*'), 'ref=$c') : '$base&ref=$c';
  }

  String get shareText => 'سایروس توریست را نصب کن؛ سفر، بازی و گروه‌های گردشگری در یک برنامه 🎲♟️\nدانلود از بازار:\n$link\nکد معرف من: $code';

  bool get rewardReady => rewardDay != WheelStore.dayKey(DateTime.now()) || todayCount < dailyCap;

  Future<void> load() async {
    if (loaded) return;
    try {
      final uid = await BadgeService.userUid();
      final clean = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      code = clean.length >= 8 ? clean.substring(0, 8) : clean.padRight(8, '0');
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        shares = (m['shares'] as num?)?.toInt() ?? 0;
        rewardDay = (m['day'] as String?) ?? '';
        todayCount = (m['cnt'] as num?)?.toInt() ?? 0;
        earned = (m['earned'] as num?)?.toInt() ?? 0;
        friendCode = (m['friend'] as String?) ?? '';
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(<String, dynamic>{'shares': shares, 'day': rewardDay, 'cnt': todayCount, 'earned': earned, 'friend': friendCode}));
    } catch (_) {}
  }

  /// بعد از هر ارسال لینک؛ true = پاداش داده شد
  Future<bool> shared() async {
    shares++;
    final today = WheelStore.dayKey(DateTime.now());
    if (rewardDay != today) {
      rewardDay = today;
      todayCount = 0;
    }
    var gift = false;
    if (todayCount < dailyCap) {
      todayCount++;
      earned += rewardCoins;
      await WheelStore.instance.load();
      await WheelStore.instance.addCoins(rewardCoins);
      gift = true;
    }
    await _save();
    return gift;
  }

  Future<void> setFriend(String c) async {
    friendCode = c.trim().toUpperCase();
    await _save();
  }
}

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final InviteStore st = InviteStore.instance;
  final TextEditingController _fc = TextEditingController();

  @override
  void initState() {
    super.initState();
    st.addListener(_u);
    st.load().then((_) {
      if (mounted) {
        _fc.text = st.friendCode;
        setState(() {});
      }
    });
  }

  void _u() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    st.removeListener(_u);
    _fc.dispose();
    super.dispose();
  }

  Future<void> _copy(String t, String what) async {
    await Clipboard.setData(ClipboardData(text: t));
    if (mounted) gToast(context, '$what کپی شد');
  }

  Future<void> _share() async {
    var sent = true;
    try {
      final r = await Share.shareWithResult(st.shareText, subject: 'سایروس توریست');
      sent = r.status != ShareResultStatus.dismissed;
    } catch (_) {}
    if (!sent) return;
    final gift = await st.shared();
    if (!mounted) return;
    gToast(context, gift ? '🎁 ${wFa(InviteStore.rewardCoins)} سکه به امتیازهایت اضافه شد' : 'سقف پاداش امروز پر شد؛ فردا دوباره');
  }

  void _qr() {
    showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: gDir,
        child: Dialog(
          backgroundColor: gPanel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: gGold, width: 1.6)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('دوستت این کد را اسکن کند', style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: st.link, size: 210, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 10),
                Text('کد معرف: ${st.code}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('بستن', style: TextStyle(color: gGold))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _box(String title, String value, VoidCallback onCopy, {bool ltr = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: gMuted, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: ltr ? TextDirection.ltr : null, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded, color: gGold)),
        ],
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
          title: const Text('معرفی به دوستان', style: TextStyle(color: gGold, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: gGold, width: 1.6),
                        gradient: const LinearGradient(colors: <Color>[Color(0xff0e3042), Color(0xff1b2a6b)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 46)),
                          const SizedBox(height: 6),
                          const Text('دوستانت را به سایروس توریست دعوت کن', textAlign: TextAlign.center, style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 6),
                          Text('لینک نصب از بازار با کد معرف مخصوص خودت ساخته شده است.\nهر بار لینک را برای دوستی بفرستی ${InviteStore.rewardCoins} سکه می‌گیری (تا ${InviteStore.dailyCap} بار در روز).', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 13, height: 1.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _box('کد معرف تو', st.code.isEmpty ? '…' : st.code, () => _copy(st.code, 'کد معرف')),
                    _box('لینک بازار', st.link, () => _copy(st.link, 'لینک'), ltr: true),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: st.loaded ? _share : null,
                      icon: const Icon(Icons.share_rounded),
                      label: Text(st.rewardReady ? 'ارسال برای دوستان  🎁 +${wFa(InviteStore.rewardCoins)} سکه' : 'ارسال برای دوستان', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: gLine), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: st.loaded ? _qr : null,
                      icon: const Icon(Icons.qr_code_2_rounded, color: gGold),
                      label: const Text('نمایش QR برای اسکن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: gLine)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('اشتراک‌گذاری', wFa(st.shares)),
                          _stat('پاداش امروز', '${wFa(st.todayCount)}/${wFa(InviteStore.dailyCap)}'),
                          _stat('سکه از معرفی', wFa(st.earned)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('کد معرف دوستت را داری؟', style: TextStyle(color: gGold, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fc,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 12,
                            style: const TextStyle(color: Colors.white, letterSpacing: 1.5),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'مثلاً A1B2C3D4',
                              hintStyle: const TextStyle(color: gMuted),
                              filled: true,
                              fillColor: gPanel,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gLine)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: gTeal, foregroundColor: gBg, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
                          onPressed: () async {
                            final v = _fc.text.trim().toUpperCase();
                            if (v == st.code) {
                              gToast(context, 'این کد خودت است');
                              return;
                            }
                            await st.setFriend(v);
                            if (mounted) gToast(context, v.isEmpty ? 'کد پاک شد' : 'کد معرف ذخیره شد');
                          },
                          child: const Text('ثبت', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String t, String v) => Column(
        children: [
          Text(v, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 2),
          Text(t, style: const TextStyle(color: gMuted, fontSize: 12)),
        ],
      );
}

/// کارت ورودی در صفحه‌ی بازی‌ها
class InviteEntryCard extends StatelessWidget {
  const InviteEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InvitePage())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gPanel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gGold, width: 1.6),
          boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: const [
            Text('👥', style: TextStyle(fontSize: 34)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('معرفی به دوستان', style: TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 3),
                  Text('هر بار لینک را بفرستی سکه می‌گیری', style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6)),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: gGold),
          ],
        ),
      ),
    );
  }
}
