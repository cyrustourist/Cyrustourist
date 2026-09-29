import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// اطلاعات پشتیبانی — همان مقادیر سایت
class _Support {
  static const String whatsapp = 'https://wa.me/989153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
  static const String eitaa = 'https://eitaa.com/cyrustourist';
}

const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);

/// ارقام فارسی و عربی را به انگلیسی تبدیل می‌کند.
String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.writeCharCode(0x30 + (unit - 0x06F0));
    } else if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(0x30 + (unit - 0x0660));
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// درستی‌سنجی شماره موبایل ایران: فقط عدد، شروع با 09 و دقیقاً ۱۱ رقم.
String? validateIranMobile(String? value) {
  final digits = normalizeDigits(value ?? '').replaceAll(RegExp(r'\s'), '');
  if (digits.isEmpty) return 'شماره تماس را وارد کنید';
  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return 'فقط عدد وارد کنید';
  if (!digits.startsWith('09')) return 'شماره باید با 09 شروع شود';
  if (digits.length != 11) return 'شماره موبایل باید ۱۱ رقم باشد';
  return null;
}

class _DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = normalizeDigits(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// فقط عدد (ارقام فارسی به انگلیسی تبدیل می‌شود) و حداکثر ۱۱ رقم.
final List<TextInputFormatter> mobileInputFormatters = [
  _DigitsOnlyFormatter(),
  LengthLimitingTextInputFormatter(11),
];

/// پنجرهٔ انتخاب مقصد ارسال درخواست: واتساپ، تلگرام یا ایتا.
/// واتساپ متن آماده را مستقیم می‌گیرد؛ تلگرام و ایتا متن را از لینک نمی‌پذیرند،
/// پس پیام کپی می‌شود و کاربر در گفتگو Paste می‌کند.
/// اگر یکی از مقصدها باز شد `true` برمی‌گرداند.
Future<bool> showSendChooser(BuildContext context, String message) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ارسال درخواست از طریق',
                style: TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _option(ctx, 'wa', 'واتساپ', const [Color(0xff25d366), Color(0xff128c7e)]),
              const SizedBox(height: 10),
              _option(ctx, 'tg', 'تلگرام', const [Color(0xff229ed9), Color(0xff2aabee)]),
              const SizedBox(height: 10),
              _option(ctx, 'eitaa', 'ایتا', const [Color(0xff5fc9a8), Color(0xff0f9d78)]),
              const SizedBox(height: 10),
              Text(
                'در تلگرام و ایتا، پیام کپی می‌شود؛ در گفتگوی باز شده Paste و ارسال کنید.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (choice == null || !context.mounted) return false;

  String url;
  switch (choice) {
    case 'tg':
      await Clipboard.setData(ClipboardData(text: message));
      url = _Support.telegram;
      break;
    case 'eitaa':
      await Clipboard.setData(ClipboardData(text: message));
      url = _Support.eitaa;
      break;
    default:
      url = '${_Support.whatsapp}?text=${Uri.encodeComponent(message)}';
  }

  if (!context.mounted) return false;

  if (choice != 'wa') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('پیام کپی شد. در گفتگوی باز شده Paste کنید و ارسال بزنید.')),
    );
  }

  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد.')),
      );
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در باز کردن لینک.')),
      );
    }
    return false;
  }
}

Widget _option(BuildContext ctx, String value, String label, List<Color> gradient) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => Navigator.of(ctx).pop(value),
    child: Ink(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}
