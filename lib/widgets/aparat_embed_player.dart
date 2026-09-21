import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// پخش‌کننده‌ی آپارات داخل صفحه (فقط Embed؛ فایل ویدئو داخل APK نیست).
/// [hash] همان بخش آخر لینک است: aparat.com/v/`xvo5q9c`
class AparatEmbedPlayer extends StatefulWidget {
  const AparatEmbedPlayer({super.key, required this.hash});

  final String hash;

  @override
  State<AparatEmbedPlayer> createState() => _AparatEmbedPlayerState();
}

class _AparatEmbedPlayerState extends State<AparatEmbedPlayer> {
  static const Color _bg = Color(0xff06121d);
  static const Color _gold = Color(0xffffd36a);

  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final embedUrl = 'https://www.aparat.com/video/video/embed/videohash/'
        '${widget.hash}/vt/frame';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _failed = false;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
            });
          },
          onNavigationRequest: (request) => request.url.contains('aparat.com')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: _bg,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: _gold),
          ),
        if (_failed)
          Container(
            color: _bg,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _gold, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'پخش ویدیو بارگذاری نشد',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _failed = false;
                      _loading = true;
                    });
                    _controller.reload();
                  },
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
