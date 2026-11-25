import 'package:flutter/material.dart';

import '../pages/games/game_economy.dart';
import '../pages/games/game_wheel.dart' show wFa;
import '../pages/groups/group_ui.dart';
import 'gg_lobby_page.dart';
import 'gg_prefs.dart';
import 'gg_settings_sheet.dart';

/// Cyrus Tourist – مسابقات گروهی آفلاین
/// صفحه‌ی اصلی دو بازی: هاکی روی میز و مینی‌گلف.
class GgHubPage extends StatefulWidget {
  const GgHubPage({super.key});

  @override
  State<GgHubPage> createState() => _GgHubPageState();
}

class _GgHubPageState extends State<GgHubPage> {
  @override
  void initState() {
    super.initState();
    Future.wait<void>(<Future<void>>[GameEconomy.load(), GgPrefs.instance.load()]).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _open(String game) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GgLobbyPage(game: game)));
    if (mounted) setState(() {});
  }

  Widget _card(String emoji, String title, String sub, List<Color> cols, String game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _open(game),
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cols),
              border: Border.all(color: Colors.white24),
              boxShadow: <BoxShadow>[BoxShadow(color: cols.first.withOpacity(.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.7)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 30),
              ],
            ),
          ),
        ),
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
          foregroundColor: Colors.white,
          title: const Text('مسابقات گروهی آفلاین', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            Center(child: Padding(padding: const EdgeInsetsDirectional.only(end: 14), child: Text('${wFa(GameEconomy.balance)} 🪙', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)))),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gGold, width: 2), boxShadow: <BoxShadow>[BoxShadow(color: gGold.withOpacity(.3), blurRadius: 18)]),
                child: ClipOval(child: Image.asset('assets/images/logo-new.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.travel_explore_rounded, color: gGold, size: 48))),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Cyrus Tourist', textAlign: TextAlign.center, style: TextStyle(color: gGold, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Text('رقابت زنده با گوشی‌های اطراف، بدون اینترنت', textAlign: TextAlign.center, style: TextStyle(color: gMuted, fontSize: 13)),
            const SizedBox(height: 20),
            _card('🏒', 'هاکی روی میز', 'نئونی و سریع · تک‌نفره با ربات یا ۲ تا ۴ نفر', const <Color>[Color(0xff0c3b66), Color(0xff6b1fa0)], 'hockey'),
            _card('⛳', 'مینی‌گلف', '۹ حفره با مانع، شن و آب · ۲ تا ۴ نفر هم‌زمان', const <Color>[Color(0xff1f7a3a), Color(0xff0b4d5c)], 'golf'),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => showGgSettings(context, 'hockey').then((_) => mounted ? setState(() {}) : null),
                icon: const Icon(Icons.tune_rounded, color: gGold),
                label: const Text('تنظیمات، صدا و فروشگاه', style: TextStyle(color: gGold, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
