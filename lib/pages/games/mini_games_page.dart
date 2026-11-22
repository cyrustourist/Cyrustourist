import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'game_texts.dart';

/// توپ و آجر و بلاک‌پازل (کاملاً آفلاین): صفحهٔ HTML داخل خود برنامه باز می‌شود.
/// فایل بازی: assets/games/minigames.html
/// [initial]: ۰ = توپ و آجر، ۱ = بلاک‌پازل. تنظیمات (مدل مکعب، پس‌زمینه، صدا، ملودی) در خود بازی با دکمهٔ ⚙️ است.
class MiniGamesPage extends StatefulWidget {
  const MiniGamesPage({super.key, this.initial = 0});
  final int initial;

  @override
  State<MiniGamesPage> createState() => _MiniGamesPageState();
}

class _MiniGamesPageState extends State<MiniGamesPage> {
  static const Color _bg = Color(0xFF0A0C1D);
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _c.runJavaScript("window.initGame('${GameT.fa ? 'fa' : 'en'}', ${widget.initial})");
          },
        ),
      )
      ..loadFlutterAsset('assets/games/minigames.html');
  }

  @override
  Widget build(BuildContext context) {
    final fa = GameT.fa;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF15263D),
        foregroundColor: Colors.white,
        title: Text(widget.initial == 0 ? (fa ? 'توپ و آجر' : 'Brick Ball') : (fa ? 'بلاک‌پازل' : 'Block Puzzle')),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
