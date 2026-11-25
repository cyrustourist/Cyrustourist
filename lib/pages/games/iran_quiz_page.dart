import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'game_texts.dart';

/// ایران‌شناسی: مسابقهٔ اطلاعات عمومی دربارهٔ ایران (کاملاً آفلاین).
/// صفحهٔ بازی داخل خود برنامه باز می‌شود: assets/games/iran_quiz.html
/// تک‌نفره (۱۰ سؤال، ۱۵ ثانیه برای هر سؤال) و دو نفره نوبتی روی یک گوشی.
class IranQuizPage extends StatefulWidget {
  const IranQuizPage({super.key});

  @override
  State<IranQuizPage> createState() => _IranQuizPageState();
}

class _IranQuizPageState extends State<IranQuizPage> {
  static const Color _bg = Color(0xFF050D1A);
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..loadFlutterAsset('assets/games/iran_quiz.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2236),
        foregroundColor: Colors.white,
        title: Text(GameT.fa ? 'ایران‌شناسی' : 'Know Iran'),
      ),
      body: SafeArea(child: WebViewWidget(controller: _c)),
    );
  }
}
