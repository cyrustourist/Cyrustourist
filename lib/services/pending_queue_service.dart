import 'cache_service.dart';
import 'connection_status_service.dart';

/// یک عملیات در انتظار ارسال (مثلاً «ثبت علاقه‌مندی» موقع آفلاین بودن).
class PendingAction {
  const PendingAction({
    required this.id,
    required this.endpointPath,
    required this.method,
    required this.body,
    required this.createdAt,
  });

  /// شناسه‌ی یکتا — برای جلوگیری از ارسال دوباره‌ی یک عملیات.
  final String id;
  final String endpointPath;
  final String method; // POST / PUT / DELETE
  final Map<String, dynamic> body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpointPath': endpointPath,
        'method': method,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingAction.fromJson(Map<String, dynamic> j) => PendingAction(
        id: j['id'].toString(),
        endpointPath: j['endpointPath'].toString(),
        method: j['method'].toString(),
        body: Map<String, dynamic>.from(j['body'] as Map),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// ===============================================================
/// Cyrus Tourist — صف عملیات آفلاین
/// ---------------------------------------------------------------
/// وقتی اینترنت نیست، عملیات‌های نوشتنی (ثبت علاقه‌مندی، ارسال فرم)
/// اینجا نگه داشته می‌شوند و به‌محض برگشت اینترنت، sendPending() آن‌ها
/// را با ApiService ارسال و از صف حذف می‌کند. ارسال واقعی به سرور در
/// [sendPending] عمداً به تصمیم فراخواننده واگذار شده تا این فایل به
/// هیچ endpoint خاصی وابسته نباشد.
/// ===============================================================
class PendingQueueService {
  PendingQueueService._();
  static final PendingQueueService instance = PendingQueueService._();

  static const String _key = 'pending_actions_v1';

  Future<List<PendingAction>> _readAll() async {
    final raw = await CacheService.instance.getJson(_key);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PendingAction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writeAll(List<PendingAction> items) async {
    await CacheService.instance.setJson(_key, items.map((e) => e.toJson()).toList());
  }

  /// افزودن یک عملیات به صف (اگر همان id قبلاً بود، جایگزین می‌شود).
  Future<void> enqueue(PendingAction action) async {
    final items = await _readAll();
    items.removeWhere((e) => e.id == action.id);
    items.add(action);
    await _writeAll(items);
  }

  Future<List<PendingAction>> pending() => _readAll();

  Future<void> remove(String id) async {
    final items = await _readAll();
    items.removeWhere((e) => e.id == id);
    await _writeAll(items);
  }

  /// اگر اینترنت وصل بود، تلاش می‌کند هرکدام از عملیات‌های در انتظار را
  /// با [send] ارسال کند و در صورت موفقیت از صف حذف می‌کند. هرگز
  /// Exception بالا نمی‌دهد.
  Future<void> trySync(Future<bool> Function(PendingAction action) send) async {
    try {
      if (!await ConnectionStatusService.hasInternet()) return;
      for (final action in await _readAll()) {
        try {
          final ok = await send(action);
          if (ok) await remove(action.id);
        } catch (_) {
          // این یکی هنوز نتوانست برود؛ در صف می‌ماند برای دفعه‌ی بعد.
        }
      }
    } catch (_) {}
  }
}
