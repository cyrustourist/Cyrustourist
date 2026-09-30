import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// آیکون‌های SVG سبک (inline، بدون فایل asset) برای دکمه‌های پیام‌رسان.
/// هر آیکون یک شکل ساده در بوم ۲۴×۲۴ است و با [color] رنگ می‌شود.
/// برای استفاده از لوگوی رسمی، فقط رشتهٔ مربوطه را با SVG خودتان عوض کنید.
class BrandIcons {
  BrandIcons._();

  static const String telegram =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4.6 11.4 18.9 5.9c.7-.3 1.3.2 1.1 1.1l-2.4 11.4c-.2.8-.7 1-1.4.6l-3.7-2.7-1.8 1.7c-.2.2-.4.4-.8.4l.3-3.8 6.9-6.2c.3-.3-.1-.4-.5-.2l-8.6 5.4-3.7-1.2c-.8-.2-.8-.8.2-1.2z"/></svg>';

  static const String whatsapp =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" d="M12 3.2a8.8 8.8 0 0 0-7.6 13.2L3.2 20.8l4.5-1.2A8.8 8.8 0 1 0 12 3.2z"/><path d="M9.2 7.9c.3-.4.7-.3.9.1l.7 1.4c.1.3 0 .5-.2.8l-.4.5c.6 1.1 1.4 1.9 2.6 2.5l.5-.5c.2-.2.5-.3.8-.1l1.3.7c.4.2.5.6.2 1-.6.9-1.5 1.1-2.6.6-2.2-1-3.6-2.5-4.4-4.6-.4-1 .1-1.7.6-2.4z"/></svg>';

  static const String eitaa =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M5 4h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-6l-4.5 3.5V17H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM8 9.3a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4zm4 0a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4zm4 0a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4z"/></svg>';

  static const String phone =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M6.6 3.5c.6-.7 1.4-.6 1.8.2l1.4 2.7c.3.6.1 1.1-.4 1.6l-.9.9c1.2 2.3 2.9 4 5.2 5.2l.9-.9c.5-.5 1.1-.6 1.6-.4l2.7 1.4c.8.4.9 1.2.2 1.8-1.3 1.3-2.9 1.6-4.6.9C9.6 16.6 6.8 13.8 5.2 9.3c-.6-1.6-.4-3.3 1.4-5.8z"/></svg>';
}

class BrandIcon extends StatelessWidget {
  const BrandIcon(this.svg, {super.key, this.size = 26, this.color = Colors.white});

  final String svg;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
