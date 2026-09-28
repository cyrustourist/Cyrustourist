import 'package:flutter/material.dart';

const Color kToolBg = Color(0xff071722);
const Color kToolCard = Color(0xff102838);
const Color kToolGold = Color(0xffffd76a);

/// قالب مشترک صفحه‌ی ابزارها (راست‌به‌چپ، هم‌رنگ جعبه ابزار).
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kToolBg,
        appBar: AppBar(
          backgroundColor: kToolBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: kToolGold),
          actions: actions,
          title: Text(
            title,
            style: const TextStyle(
              color: kToolGold,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: body),
      ),
    );
  }
}

BoxDecoration toolCardDecoration({Color? border, double radius = 18}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff153447), Color(0xff0b202c)],
    ),
    border: Border.all(
      color: (border ?? kToolGold).withValues(alpha: 0.35),
    ),
  );
}

InputDecoration toolInputDecoration(String label, {String? suffix}) {
  return InputDecoration(
    labelText: label,
    suffixText: suffix,
    labelStyle: const TextStyle(color: Colors.white60),
    suffixStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: const Color(0xff0b202c),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: kToolGold.withValues(alpha: 0.30)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kToolGold, width: 1.6),
    ),
  );
}

/// تبدیل ارقام فارسی/عربی به انگلیسی برای پردازش ورودی کاربر.
String toEnglishDigits(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return out.replaceAll('٫', '.').replaceAll('،', '.').replaceAll(',', '.');
}

double? parseNumber(String text) {
  return double.tryParse(toEnglishDigits(text.trim()));
}

String toPersianDigits(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final digit = int.tryParse(ch);
    buffer.write(digit == null ? ch : fa[digit]);
  }
  return buffer.toString();
}

/// جداکننده‌ی هزارگان: 1234567 → ۱,۲۳۴,۵۶۷
String formatThousands(num value) {
  final text = value.round().toString();
  final grouped = text.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return toPersianDigits(grouped);
}

void showToolSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xff173747),
      behavior: SnackBarBehavior.floating,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ),
  );
}
