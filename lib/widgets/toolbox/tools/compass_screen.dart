import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/location_manager.dart';
import 'native_tools.dart';
import 'tool_ui.dart';

/// قطب‌نمای واقعی (حسگر گوشی) + جهت قبله بر اساس موقعیت کاربر.
class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription<double>? _subscription;

  double _heading = 0;
  bool _hasReading = false;
  bool _noSensor = false;

  double? _qibla;
  bool _showQibla = false;
  bool _qiblaLoading = false;

  @override
  void initState() {
    super.initState();
    _subscription = CyrusNativeTools.compassStream().listen(
      _onHeading,
      onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onHeading(double raw) {
    if (!mounted) return;

    if (!_hasReading) {
      _heading = raw;
    } else {
      var delta = raw - _heading;
      while (delta > 180) {
        delta -= 360;
      }
      while (delta < -180) {
        delta += 360;
      }
      // میانگین‌گیری برای نرم شدن حرکت عقربه
      _heading = (_heading + delta * 0.2 + 360) % 360;
    }

    setState(() => _hasReading = true);
  }

  Future<void> _toggleQibla() async {
    if (_showQibla) {
      setState(() => _showQibla = false);
      return;
    }

    setState(() => _qiblaLoading = true);

    final location = await LocationManager.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      setState(() => _qiblaLoading = false);
      showToolSnack(
        context,
        'موقعیت شما در دسترس نیست. GPS و دسترسی موقعیت را روشن کنید.',
      );
      return;
    }

    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;

    final phi1 = location.latitude * math.pi / 180;
    final phi2 = kaabaLat * math.pi / 180;
    final deltaLambda = (kaabaLng - location.longitude) * math.pi / 180;

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360;

    setState(() {
      _qibla = bearing;
      _showQibla = true;
      _qiblaLoading = false;
    });
  }

  String _directionName(double degrees) {
    const names = [
      'شمال',
      'شمال‌شرقی',
      'شرق',
      'جنوب‌شرقی',
      'جنوب',
      'جنوب‌غربی',
      'غرب',
      'شمال‌غربی',
    ];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return names[index];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialSize = math.min(width - 48, 340.0);

    return ToolScaffold(
      title: 'قطب نما',
      body: _noSensor
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'این گوشی حسگر قطب‌نما ندارد یا حسگر در دسترس نیست.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.8),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        _hasReading
                            ? toPersianDigits('${_heading.round()}°')
                            : '--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasReading ? _directionName(_heading) : 'در حال خواندن حسگر…',
                        style: const TextStyle(
                          color: kToolGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: CustomPaint(
                      painter: _CompassPainter(
                        heading: _heading,
                        qibla: _showQibla ? _qibla : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _qiblaLoading ? null : _toggleQibla,
                    icon: _qiblaLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff071722),
                            ),
                          )
                        : const Text('🕋', style: TextStyle(fontSize: 18)),
                    label: Text(_showQibla ? 'پنهان کردن قبله' : 'نمایش جهت قبله'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kToolGold,
                      foregroundColor: const Color(0xff071722),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_showQibla && _qibla != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: toolCardDecoration(border: Colors.greenAccent),
                    child: Text(
                      'قبله در ${toPersianDigits('${_qibla!.round()}°')} (${_directionName(_qibla!)}) است. '
                      'گوشی را بچرخانید تا نشانگر 🕋 زیر فلش قرمز بالای صفحه قرار بگیرد.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'شمال نشان‌داده‌شده «شمال مغناطیسی» است. برای دقت بیشتر گوشی را صاف نگه دارید، '
                  'از فلز و آهن‌ربا دور کنید و در صورت نیاز آن را چند بار به شکل عدد ۸ حرکت دهید.',
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.8),
                ),
              ],
            ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({required this.heading, required this.qibla});

  final double heading;
  final double? qibla;

  static const List<String> _labels = ['N', 'E', 'S', 'W'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xff1a4056), Color(0xff0a1c28)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = kToolGold,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);

    final tick = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < 72; i++) {
      final deg = i * 5;
      final angle = deg * math.pi / 180;
      final isMajor = deg % 90 == 0;
      final length = isMajor ? 18.0 : (deg % 15 == 0 ? 12.0 : 7.0);

      tick
        ..strokeWidth = isMajor ? 3 : 1.5
        ..color = isMajor ? kToolGold : Colors.white54;

      final outer = radius - 10;
      final inner = outer - length;

      canvas.drawLine(
        Offset(math.sin(angle) * outer, -math.cos(angle) * outer),
        Offset(math.sin(angle) * inner, -math.cos(angle) * inner),
        tick,
      );
    }

    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final position = Offset(
        math.sin(angle) * (radius - 48),
        -math.cos(angle) * (radius - 48),
      );

      final painter = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: TextStyle(
            color: i == 0 ? Colors.redAccent : Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }

    final qiblaAngle = qibla;
    if (qiblaAngle != null) {
      final angle = qiblaAngle * math.pi / 180;
      final markerRadius = radius - 84;
      final marker = Offset(
        math.sin(angle) * markerRadius,
        -math.cos(angle) * markerRadius,
      );

      canvas.drawLine(
        Offset.zero,
        marker,
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );

      canvas.drawCircle(marker, 17, Paint()..color = const Color(0xff0f6b3a));
      canvas.drawCircle(
        marker,
        17,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.greenAccent,
      );

      final kaaba = TextPainter(
        text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 18)),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(marker.dx, marker.dy);
      canvas.rotate(angle);
      kaaba.paint(canvas, Offset(-kaaba.width / 2, -kaaba.height / 2));
      canvas.restore();
    }

    canvas.restore();

    // فلش قرمز ثابت: جهتی که بالای گوشی به آن اشاره می‌کند
    final pointer = Path()
      ..moveTo(center.dx, center.dy - radius + 2)
      ..lineTo(center.dx - 11, center.dy - radius + 26)
      ..lineTo(center.dx + 11, center.dy - radius + 26)
      ..close();

    canvas.drawPath(pointer, Paint()..color = Colors.redAccent);

    canvas.drawCircle(center, 6, Paint()..color = kToolGold);
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xff071722));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.qibla != qibla;
  }
}
