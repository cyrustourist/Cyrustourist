import 'package:flutter/material.dart';

/// سرویس مرکزی مدیریت بازگشت در اپلیکیشن سایروس توریست.
class BackService {
  BackService._();

  /// بازگشت به صفحه قبلی.
  static Future<bool> handleBack(
    BuildContext context,
  ) async {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return false;
    }

    return false;
  }

  /// بازگشت مستقیم به صفحه اصلی سایروس توریست.
  static void backToHome(
    BuildContext context,
  ) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  /// بازگشت با نتیجه.
  static void backWithResult<T>(
    BuildContext context,
    T result,
  ) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  /// بررسی امکان بازگشت.
  static bool canGoBack(
    BuildContext context,
  ) {
    return Navigator.of(context).canPop();
  }
}
