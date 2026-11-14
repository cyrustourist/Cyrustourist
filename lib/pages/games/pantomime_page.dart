import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// بازی پانتومیم سایروس (کاملاً آفلاین): صفحهٔ HTML داخل خود برنامه باز می‌شود.
/// فایل بازی: assets/games/pantomime.html
class PantomimePage extends StatefulWidget {
  const PantomimePage({super.key});

  @override
  State<PantomimePage> createState() => _PantomimePageState();
}

class _PantomimePageState extends State<PantomimePage> {
  static const Color _bg = Color(0xFF0E1A2B);
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..loadFlutterAsset('assets/games/pantomime.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF15263D),
        foregroundColor: Colors.white,
        title: const Text('پانتومیم سایروس'),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
