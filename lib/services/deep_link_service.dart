import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../main.dart' show navigatorKey;
import '../models/showcase_item.dart';
import '../models/tour.dart';
import '../pages/showcase/showcase_navigator.dart';
import '../pages/tours/tour_detail_page.dart';
import 'public_link_service.dart';
import 'showcase_service.dart';

/// ===============================================================
/// Deep Link / App Link — باز شدن مستقیم صفحه‌ی موجودیت از لینک عمومی
/// ---------------------------------------------------------------
///   https://cyrustourist.ir/<نوع>/<شناسه>
///   مثال: /tour/76 ، /video/1 ، /guide/1 ، /accommodation/3
///
/// - برنامه بسته باشد: اول Splash و صفحه‌ی اصلی بالا می‌آید، بعد همان
///   موجودیت روی صفحه‌ی اصلی باز می‌شود (دکمه‌ی برگشت به خانه می‌رود).
/// - برنامه باز باشد: همان لحظه صفحه‌ی موجودیت باز می‌شود.
/// - موجودیت پیدا نشد یا حذف شده بود: پیام کوتاه، بدون خطا و بدون Crash.
/// ===============================================================
class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static bool _started = false;
  static bool _ready = false;
  static Uri? _pending;
  static String? _lastKey;
  static DateTime? _lastAt;

  /// یک بار در main() صدا زده می‌شود.
  static Future<void> init() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _onUri(initial);
    } catch (_) {}

    try {
      _sub = _appLinks.uriLinkStream.listen(_onUri, onError: (_) {});
    } catch (_) {}
  }

  /// وقتی Splash تمام شد و صفحه‌ی اصلی آماده است صدا زده می‌شود؛
  /// لینکی که هنگام بالا آمدن برنامه رسیده بود، همین‌جا باز می‌شود.
  static void markReady() {
    _ready = true;
    final p = _pending;
    _pending = null;
    if (p != null) {
      Future.delayed(const Duration(milliseconds: 400), () => _open(p));
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  static void _onUri(Uri uri) {
    // بعضی نسخه‌ها یک لینک را دو بار می‌فرستند؛ تکراری‌ها نادیده گرفته می‌شوند.
    final key = uri.toString();
    final now = DateTime.now();
    if (_lastKey == key &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastKey = key;
    _lastAt = now;

    if (!_ready) {
      _pending = uri;
      return;
    }
    _open(uri);
  }

  static ({String type, String id})? _parse(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host != 'cyrustourist.ir' && host != 'www.cyrustourist.ir') return null;
    final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (seg.length < 2) return null;
    return (type: seg[0].toLowerCase(), id: seg[1]);
  }

  static ShowcaseKind? _kindOf(String type) {
    switch (type) {
      case PublicLinkService.video:
        return ShowcaseKind.video;
      case PublicLinkService.attraction:
        return ShowcaseKind.attraction;
      case PublicLinkService.accommodation:
        return ShowcaseKind.accommodation;
      case PublicLinkService.health:
        return ShowcaseKind.health;
      case PublicLinkService.guide:
        return ShowcaseKind.leader;
      case PublicLinkService.agency:
        return ShowcaseKind.agency;
    }
    return null;
  }

  static Future<void> _open(Uri uri) async {
    final p = _parse(uri);
    if (p == null) return;

    try {
      if (p.type == PublicLinkService.tour) {
        final id = int.tryParse(p.id);
        final result = await TourRepository.load();
        Tour? found;
        for (final t in result.tours) {
          if (t.id == id) found = t;
        }
        final nav = navigatorKey.currentState;
        if (found != null && nav != null) {
          final tour = found;
          nav.push(MaterialPageRoute(builder: (_) => TourDetailPage(tour: tour)));
          return;
        }
      } else {
        final kind = _kindOf(p.type);
        final code = int.tryParse(p.id);
        if (kind != null && code != null) {
          final load = await ShowcaseService.load(kind);
          ShowcaseItem? found;
          for (final i in load.items) {
            if (i.code == code) found = i;
          }
          final ctx = navigatorKey.currentContext;
          if (found != null && ctx != null && ctx.mounted) {
            ShowcaseNavigator.open(ctx, found);
            return;
          }
        }
      }
    } catch (_) {
      // خطا هرچه بود، برنامه خراب نمی‌شود؛ پیام کوتاه نشان می‌دهیم.
    }

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('این مورد پیدا نشد یا دیگر در دسترس نیست'),
          ),
        ),
      );
    }
  }
}
