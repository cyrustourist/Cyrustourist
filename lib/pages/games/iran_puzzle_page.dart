import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'game_economy.dart';
import 'game_texts.dart';
import 'game_wheel.dart';

/// پازل ایران‌گردی: جورچین تصویری (جابه‌جایی تکه‌ها) با ۹۴ مرحله (۴۷ تصویر × روز و غروب) از آثار تاریخی، طبیعت و خوراک ایران (کاملاً آفلاین).
/// صفحهٔ بازی: assets/games/iran_puzzle.html
/// سکه: جایزهٔ هر مرحله به کیف پول سکهٔ برنامه (GameEconomy / WheelStore) اضافه می‌شود و راهنما از همان کم می‌کند.
class IranPuzzlePage extends StatefulWidget {
  const IranPuzzlePage({super.key});

  @override
  State<IranPuzzlePage> createState() => _IranPuzzlePageState();
}

class _IranPuzzlePageState extends State<IranPuzzlePage> {
  static const Color _bg = Color(0xFF050D1A);
  static const int _dailyCap = 300; // سقف سکهٔ روزانه از این بازی
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    GameEconomy.load();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..addJavaScriptChannel('Eco', onMessageReceived: (m) => _fromWeb(m.message))
      ..loadFlutterAsset('assets/games/iran_puzzle.html');
  }

  void _reply(int id, bool ok, int bal, [int extra = 0]) {
    if (id <= 0) return;
    _c.runJavaScript('window.__ecoRes($id,${ok ? 'true' : 'false'},$bal,$extra)');
  }

  Future<int> _grant(int n) async {
    final p = await SharedPreferences.getInstance();
    final today = WheelStore.dayKey(DateTime.now());
    var earned = p.getString('pz_day') == today ? (p.getInt('pz_earned') ?? 0) : 0;
    var g = n;
    if (earned + g > _dailyCap) g = _dailyCap - earned;
    if (g <= 0) return 0;
    earned += g;
    await WheelStore.instance.addCoins(g);
    await p.setString('pz_day', today);
    await p.setInt('pz_earned', earned);
    return g;
  }

  Future<void> _fromWeb(String raw) async {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final id = (m['id'] as num?)?.toInt() ?? 0;
      final n = (m['n'] as num?)?.toInt() ?? 0;
      await GameEconomy.load();
      switch ('${m['a']}') {
        case 'bal':
          _reply(id, true, GameEconomy.balance);
          break;
        case 'spend':
          final ok = n > 0 && n <= 100 && await GameEconomy.pay(context, n, 'راهنما');
          _reply(id, ok, GameEconomy.balance);
          break;
        case 'add':
          final g = (n > 0 && n <= 60) ? await _grant(n) : 0;
          _reply(id, true, GameEconomy.balance, g);
          break;
        case 'vib':
          HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2236),
        foregroundColor: Colors.white,
        title: Text(GameT.fa ? 'پازل ایران‌گردی' : 'Iran Jigsaw'),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
