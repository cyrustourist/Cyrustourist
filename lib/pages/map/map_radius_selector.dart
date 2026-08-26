import 'package:flutter/material.dart';

class MapRadiusSelector extends StatelessWidget {
  const MapRadiusSelector({
    super.key,
    required this.selectedRadius,
    required this.onChanged,
    this.language = 'fa',
  });

  final double selectedRadius;
  final ValueChanged<double> onChanged;
  final String language;

  static const List<double> radiuses = [
    5,
    10,
    15,
    25,
    50,
    100,
  ];

  String _title() {
    switch (language) {
      case 'en':
        return 'Search radius';
      case 'ar':
        return 'نطاق البحث';
      default:
        return 'شعاع جستجو';
    }
  }

  String _nearbyText() {
    switch (language) {
      case 'en':
        return 'Nearby places';
      case 'ar':
        return 'الأماكن القريبة';
      default:
        return 'مکان‌های اطراف';
    }
  }

  String _kmText(double value) {
    if (language == 'en') {
      return '${value.toInt()} km';
    }

    if (language == 'ar') {
      return '${value.toInt()} كم';
    }

    return '${value.toInt()} کیلومتر';
  }

  @override
  Widget build(BuildContext context) {
    final rtl = language != 'en';

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        padding: const EdgeInsets.fromLTRB(
          10,
          9,
          10,
          10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff071722)
              .withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xffffd36a)
                .withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.40,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xffffd36a)
                  .withValues(alpha: 0.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: Color(0xffffd36a),
                  size: 22,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _title(),
                    style: const TextStyle(
                      color: Color(0xffffe39a),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffffd36a)
                        .withValues(alpha: 0.13),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    _kmText(selectedRadius),
                    style: const TextStyle(
                      color: Color(0xffffe39a),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            SizedBox(
              height: 43,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics:
                    const BouncingScrollPhysics(),
                itemCount: radiuses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 7),
                itemBuilder: (
                  context,
                  index,
                ) {
                  final radius =
                      radiuses[index];

                  final active =
                      radius == selectedRadius;

                  return _RadiusButton(
                    title: _kmText(radius),
                    active: active,
                    onTap: () {
                      onChanged(radius);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 3),

            Row(
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 14,
                  color: Colors.white.withValues(
                    alpha: 0.55,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _nearbyText(),
                  style: TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusButton extends StatefulWidget {
  const _RadiusButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RadiusButton> createState() =>
      _RadiusButtonState();
}

class _RadiusButtonState
    extends State<_RadiusButton> {
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
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 130),
        width: 72,
        transform: Matrix4.identity()
          ..scale(pressed ? 0.94 : 1.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(13),
          gradient: widget.active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xffffe39a),
                    Color(0xffffc84d),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff12374a),
                    Color(0xff09202d),
                  ],
                ),
          border: Border.all(
            color: widget.active
                ? gold
                : gold.withValues(
                    alpha: 0.28,
                  ),
            width:
                widget.active ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.42,
              ),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: gold.withValues(
                alpha: widget.active
                    ? 0.42
                    : 0.08,
              ),
              blurRadius:
                  widget.active ? 12 : 6,
            ),
          ],
        ),
        child: Text(
          widget.title,
          style: TextStyle(
            color: widget.active
                ? const Color(0xff071722)
                : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
