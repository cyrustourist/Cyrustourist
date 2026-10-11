import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config/carto_config.dart';

/// لایهٔ پایهٔ آفلاین: کاشی‌های کم‌زوم ایران که داخل خود اپ هستند
/// (assets/tiles/{z}_{x}_{y}.png ، زوم ۰ تا ۷).
/// فوری نمایش داده می‌شود تا صفحهٔ سفید/خاکستری دیده نشود؛ کاشی‌های آنلاین روی آن می‌نشینند.
/// اگر فایل کاشی‌ای در assets نباشد، همان نقطه خالی می‌ماند و خطایی به کاربر نشان داده نمی‌شود.
class OfflineBaseTileLayer extends StatelessWidget {
  const OfflineBaseTileLayer({super.key, this.maxZoom = 18});

  /// آخرین زومی که کاشی آفلاین دارد (بالاتر از آن، کاشی زوم ۷ کشیده می‌شود)
  static const int nativeMaxZoom = 7;

  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      key: const ValueKey('tile-offline-base'),
      urlTemplate: 'assets/tiles/{z}_{x}_{y}.png',
      tileProvider: AssetTileProvider(),
      maxNativeZoom: nativeMaxZoom,
      maxZoom: maxZoom,
      errorTileCallback: (_, __, ___) {},
    );
  }
}

/// لایهٔ کاشی نقشه: پایهٔ آفلاین + آنلاین با جایگزین خودکار (بدون نیاز به کلید یا تمدید).
/// ترتیب آنلاین: ۰ = OpenStreetMap ، ۱ = CARTO.
/// اگر چند کاشی پیاپی خطا بدهد (فیلتر شدن یا قطعی سرویس)، خودکار به لایهٔ بعدی می‌رود.
class ResilientTileLayer extends StatefulWidget {
  const ResilientTileLayer({
    super.key,
    this.maxZoom = 18,
    this.userAgentPackageName = 'com.cyrustourist.app',
  });

  final double maxZoom;
  final String userAgentPackageName;

  @override
  State<ResilientTileLayer> createState() => _ResilientTileLayerState();
}

class _ResilientTileLayerState extends State<ResilientTileLayer> {
  static const int _steps = 2;
  int _step = 0;
  int _errors = 0;
  int _switches = 0;

  void _onError(int step) {
    if (!mounted || step != _step) return;
    _errors++;
    if (_errors >= 4 && _switches < _steps - 1) {
      _switches++;
      // خارج از فاز ساخت ویجت تغییر وضعیت می‌دهیم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _step = (_step + 1) % _steps;
          _errors = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget online = _step == 1
        ? TileLayer(
            key: const ValueKey('tile-carto'),
            urlTemplate: CartoConfig.tileUrlWithKey,
            userAgentPackageName: widget.userAgentPackageName,
            maxZoom: widget.maxZoom,
            errorTileCallback: (_, __, ___) => _onError(1),
          )
        : TileLayer(
            key: const ValueKey('tile-osm'),
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: widget.userAgentPackageName,
            maxZoom: widget.maxZoom,
            errorTileCallback: (_, __, ___) => _onError(0),
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        OfflineBaseTileLayer(maxZoom: widget.maxZoom),
        online,
      ],
    );
  }
}
