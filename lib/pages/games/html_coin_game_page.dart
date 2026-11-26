import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'game_economy.dart';
import 'game_texts.dart';
import 'game_wheel.dart';

/// صفحهٔ مشترک بازی‌های HTML که با کیف سکهٔ برنامه کار می‌کنند (سودوکو، گنج معبد).
/// پل جاوااسکریپت: کانال «Eco» با پیام‌های bal / spend / add / vib / exit
/// جایزه‌ها به کیف سکهٔ برنامه (WheelStore) اضافه و خرج‌ها از همان (GameEconomy) کم می‌شود.
class HtmlCoinGamePage extends StatefulWidget {
  const HtmlCoinGamePage({
    super.key,
    required this.asset,
    required this.titleFa,
    required this.titleEn,
    required this.prefKey,
    this.bg = const Color(0xFF101826),
    this.barColor = const Color(0xFF1B2A4A),
    this.dailyCap = 400,
  });

  /// مسیر فایل HTML، مثلاً assets/games/sudoku.html
  final String asset;
  final String titleFa;
  final String titleEn;

  /// پیشوند کلیدهای ذخیره‌ی سقف روزانه (برای هر بازی جدا)
  final String prefKey;
  final Color bg;
  final Color barColor;

  /// سقف سکهٔ روزانه‌ای که این بازی می‌تواند بدهد
  final int dailyCap;

  @override
  State<HtmlCoinGamePage> createState() => _HtmlCoinGamePageState();
}

class _HtmlCoinGamePageState extends State<HtmlCoinGamePage> {
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    GameEconomy.load();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.bg)
      ..addJavaScriptChannel('Eco', onMessageReceived: (m) => _fromWeb(m.message))
      ..loadFlutterAsset(widget.asset);
  }

  void _reply(int id, bool ok, int bal, [int extra = 0]) {
    if (id <= 0) return;
    _c.runJavaScript('window.__ecoRes($id,${ok ? 'true' : 'false'},$bal,$extra)');
  }

  Future<int> _grant(int n) async {
    final p = await SharedPreferences.getInstance();
    final today = WheelStore.dayKey(DateTime.now());
    final dayK = '${widget.prefKey}_day';
    final earnK = '${widget.prefKey}_earned';
    var earned = p.getString(dayK) == today ? (p.getInt(earnK) ?? 0) : 0;
    var g = n;
    if (earned + g > widget.dailyCap) g = widget.dailyCap - earned;
    if (g <= 0) return 0;
    earned += g;
    await WheelStore.instance.addCoins(g);
    await p.setString(dayK, today);
    await p.setInt(earnK, earned);
    return g;
  }

  Future<void> _fromWeb(String raw) async {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final id = (m['id'] as num?)?.toInt() ?? 0;
      final n = (m['n'] as num?)?.toInt() ?? 0;
      final what = '${m['w'] ?? ''}'.trim();
      await GameEconomy.load();
      if (!mounted) return;
      switch ('${m['a']}') {
        case 'bal':
          _reply(id, true, GameEconomy.balance);
          break;
        case 'spend':
          final ok = n > 0 && n <= 1000 && await GameEconomy.pay(context, n, what.isEmpty ? (GameT.fa ? widget.titleFa : widget.titleEn) : what);
          _reply(id, ok, GameEconomy.balance);
          break;
        case 'add':
          final g = (n > 0 && n <= 150) ? await _grant(n) : 0;
          _reply(id, true, GameEconomy.balance, g);
          break;
        case 'vib':
          HapticFeedback.lightImpact();
          break;
        case 'exit':
          Navigator.of(context).maybePop();
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bg,
      appBar: AppBar(
        backgroundColor: widget.barColor,
        foregroundColor: Colors.white,
        title: Text(GameT.fa ? widget.titleFa : widget.titleEn),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
