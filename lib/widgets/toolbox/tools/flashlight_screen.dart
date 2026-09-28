import 'package:flutter/material.dart';

import 'native_tools.dart';
import 'tool_ui.dart';

/// چراغ قوه‌ی گوشی (روشن/خاموش + حالت SOS).
class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  bool? _available;
  bool _on = false;
  bool _sos = false;
  int _sosRun = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await CyrusNativeTools.torchAvailable();
    if (!mounted) return;
    setState(() => _available = ok);
  }

  @override
  void dispose() {
    _sosRun++;
    _sos = false;
    // برای جلوگیری از فراموش شدن و مصرف باتری، هنگام خروج خاموش می‌شود.
    CyrusNativeTools.setTorch(false);
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_sos) {
      _sosRun++;
      _sos = false;
    }

    final next = !_on;
    final ok = await CyrusNativeTools.setTorch(next);

    if (!mounted) return;

    if (ok) {
      setState(() => _on = next);
    } else {
      showToolSnack(context, 'روشن کردن چراغ قوه ممکن نشد.');
    }
  }

  Future<void> _toggleSos() async {
    if (_sos) {
      _sosRun++;
      setState(() => _sos = false);
      await CyrusNativeTools.setTorch(false);
      if (mounted) setState(() => _on = false);
      return;
    }

    final run = ++_sosRun;
    setState(() => _sos = true);

    bool active() => mounted && _sos && run == _sosRun;
    Future<void> wait(int units) =>
        Future.delayed(Duration(milliseconds: units * 220));

    const letters = [
      [1, 1, 1],
      [3, 3, 3],
      [1, 1, 1],
    ];

    while (active()) {
      for (final letter in letters) {
        for (final units in letter) {
          if (!active()) return;

          await CyrusNativeTools.setTorch(true);
          if (mounted) setState(() => _on = true);
          await wait(units);

          await CyrusNativeTools.setTorch(false);
          if (mounted) setState(() => _on = false);
          await wait(1);
        }
        await wait(2);
      }
      await wait(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'چراغ قوه',
      body: _available == null
          ? const Center(child: CircularProgressIndicator(color: kToolGold))
          : _available == false
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'این دستگاه فلاش یا چراغ قوه‌ی قابل کنترل ندارد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                )
              : Column(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _on
                                ? const [Color(0xffffefb0), Color(0xffe0a020)]
                                : const [Color(0xff1f3f52), Color(0xff0e2230)],
                          ),
                          border: Border.all(color: kToolGold, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _on
                                  ? const Color(0xffffd76a).withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.4),
                              blurRadius: _on ? 60 : 16,
                              spreadRadius: _on ? 10 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _on
                              ? Icons.flashlight_on_rounded
                              : Icons.flashlight_off_rounded,
                          size: 84,
                          color: _on ? const Color(0xff16242c) : kToolGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      _sos
                          ? 'حالت SOS فعال است'
                          : (_on ? 'روشن' : 'خاموش — برای روشن شدن لمس کنید'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _toggleSos,
                          icon: const Icon(Icons.sos_rounded),
                          label: Text(_sos ? 'توقف SOS' : 'چشمک‌زن اضطراری (SOS)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _sos ? Colors.redAccent : kToolGold,
                            side: BorderSide(
                              color: _sos ? Colors.redAccent : kToolGold,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
