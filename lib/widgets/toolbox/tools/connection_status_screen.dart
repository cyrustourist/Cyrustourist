import 'package:flutter/material.dart';
import '../../../services/connection_status_service.dart';

const _kBg = Color(0xff071722);
const _kCard1 = Color(0xff173747);
const _kCard2 = Color(0xff0b202c);
const _kGold = Color(0xffffd76a);

class ConnectionStatusScreen extends StatefulWidget {
  const ConnectionStatusScreen({super.key});

  @override
  State<ConnectionStatusScreen> createState() =>
      _ConnectionStatusScreenState();
}

class _ConnectionStatusScreenState extends State<ConnectionStatusScreen> {
  bool? _online;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await ConnectionStatusService.hasInternet();
    if (!mounted) return;
    setState(() {
      _online = result;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final online = _online == true;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kGold),
          title: const Text(
            'وضعیت اتصال',
            style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kCard1, _kCard2],
                ),
                border: Border.all(
                  color: (_checking
                          ? _kGold
                          : online
                              ? Colors.greenAccent
                              : Colors.redAccent)
                      .withOpacity(0.5),
                  width: 1.4,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_checking)
                    const CircularProgressIndicator(color: _kGold)
                  else
                    Icon(
                      online
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      color: online ? Colors.greenAccent : Colors.redAccent,
                      size: 64,
                    ),
                  const SizedBox(height: 18),
                  Text(
                    _checking
                        ? 'در حال بررسی اتصال...'
                        : online
                            ? 'اینترنت متصل است'
                            : 'اتصال اینترنت برقرار نیست',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قابلیت‌های آنلاین مانند آب‌وهوا و تبدیل ارز به این اتصال نیاز دارند',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _checking ? null : _check,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('بررسی دوباره'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: _kBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
