import 'package:flutter/material.dart';

/// دکمه‌ی نیم‌دایره‌ای طلایی که روی لبه‌ی بالای پنل «شعاع جستجو» می‌نشیند
/// و به صفحه‌ی «نمایش» (VIP) همان بخش می‌رود.
class ShowcaseDomeButton extends StatelessWidget {
  const ShowcaseDomeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _navy = Color(0xff071722);

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.elliptical(72, 36));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 34,
          constraints: const BoxConstraints(minWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffffe9ad), Color(0xffffd36a), Color(0xffe0a93a)],
            ),
            border: Border.all(color: const Color(0xffffe39a), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffffd36a).withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _navy, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
