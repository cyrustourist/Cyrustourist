import 'package:flutter/material.dart';

class MapQuickTool {
  final String id;
  final String fa;
  final String en;
  final String ar;
  final IconData icon;

  const MapQuickTool({
    required this.id,
    required this.fa,
    required this.en,
    required this.ar,
    required this.icon,
  });

  String title(String language) {
    switch (language) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }
}

class MapQuickTools extends StatefulWidget {
  const MapQuickTools({
    super.key,
    required this.language,
    required this.onSelected,
  });

  final String language;
  final ValueChanged<String> onSelected;

  @override
  State<MapQuickTools> createState() => _MapQuickToolsState();
}

class _MapQuickToolsState extends State<MapQuickTools> {
  String? selectedId;

  static const Color background = Color(0xff071722);
  static const Color gold = Color(0xffffd36a);
  static const Color goldBright = Color(0xffffe39a);

  static const List<MapQuickTool> tools = [
    MapQuickTool(
      id: 'fuel',
      fa: 'پمپ بنزین',
      en: 'Fuel',
      ar: 'محطة وقود',
      icon: Icons.local_gas_station_rounded,
    ),
    MapQuickTool(
      id: 'atm',
      fa: 'خودپرداز',
      en: 'ATM',
      ar: 'صراف آلي',
      icon: Icons.atm_rounded,
    ),
    MapQuickTool(
      id: 'medical',
      fa: 'درمان',
      en: 'Medical',
      ar: 'الرعاية الصحية',
      icon: Icons.local_hospital_rounded,
    ),
    MapQuickTool(
      id: 'food',
      fa: 'غذا',
      en: 'Food',
      ar: 'طعام',
      icon: Icons.restaurant_rounded,
    ),
    MapQuickTool(
      id: 'parking',
      fa: 'پارکینگ',
      en: 'Parking',
      ar: 'موقف سيارات',
      icon: Icons.local_parking_rounded,
    ),
    MapQuickTool(
      id: 'shopping',
      fa: 'خرید',
      en: 'Shopping',
      ar: 'التسوق',
      icon: Icons.shopping_bag_rounded,
    ),
    MapQuickTool(
      id: 'toilet',
      fa: 'سرویس',
      en: 'Restroom',
      ar: 'دورة مياه',
      icon: Icons.wc_rounded,
    ),
    MapQuickTool(
      id: 'emergency',
      fa: 'ضروری',
      en: 'Emergency',
      ar: 'طوارئ',
      icon: Icons.emergency_rounded,
    ),
  ];

  void _tap(MapQuickTool tool) {
    setState(() {
      selectedId = selectedId == tool.id ? null : tool.id;
    });

    widget.onSelected(tool.id);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = widget.language != 'en';

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: gold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: gold.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: gold,
                    size: 22,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      widget.language == 'en'
                          ? 'Tourist Services'
                          : widget.language == 'ar'
                              ? 'خدمات السائح'
                              : 'خدمات ضروری گردشگر',
                      style: const TextStyle(
                        color: goldBright,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    widget.language == 'en'
                        ? 'Nearby'
                        : widget.language == 'ar'
                            ? 'بالقرب منك'
                            : 'اطراف من',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.65,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 91,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: tools.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  final active =
                      selectedId == tool.id;

                  return _QuickToolButton(
                    tool: tool,
                    title:
                        tool.title(widget.language),
                    active: active,
                    onTap: () => _tap(tool),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickToolButton extends StatefulWidget {
  const _QuickToolButton({
    required this.tool,
    required this.title,
    required this.active,
    required this.onTap,
  });

  final MapQuickTool tool;
  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_QuickToolButton> createState() =>
      _QuickToolButtonState();
}

class _QuickToolButtonState
    extends State<_QuickToolButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final gold =
        const Color(0xffffd36a);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) async {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 82,
        transform: Matrix4.identity()
          ..scale(pressed ? 0.94 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.active
                ? const [
                    Color(0xffffe39a),
                    Color(0xffffc84d),
                  ]
                : const [
                    Color(0xff12374a),
                    Color(0xff09202d),
                  ],
          ),
          border: Border.all(
            color: widget.active
                ? gold
                : gold.withValues(alpha: 0.32),
            width: widget.active ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.42,
              ),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: gold.withValues(
                alpha: widget.active
                    ? 0.55
                    : pressed
                        ? 0.38
                        : 0.10,
              ),
              blurRadius:
                  widget.active ? 15 : 8,
              spreadRadius:
                  widget.active ? 1.2 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                widget.tool.icon,
                size: 29,
                color: widget.active
                    ? const Color(0xff071722)
                    : gold,
              ),
              const SizedBox(height: 5),
              Text(
                widget.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.active
                      ? const Color(0xff071722)
                      : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
