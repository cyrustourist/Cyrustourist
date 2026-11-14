import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// بازی اسم و فامیل (کاملاً آفلاین): صفحهٔ HTML داخل خود برنامه باز می‌شود.
/// فایل بازی: assets/games/esmfamil.html
class EsmFamilPage extends StatefulWidget {
  const EsmFamilPage({super.key});

  @override
  State<EsmFamilPage> createState() => _EsmFamilPageState();
}

class _EsmFamilPageState extends State<EsmFamilPage> {
  static const Color _bg = Color(0xFF0E1A2B);
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..loadFlutterAsset('assets/games/esmfamil.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF15263D),
        foregroundColor: Colors.white,
        title: const Text('اسم و فامیل'),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
