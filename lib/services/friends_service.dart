import 'badge_service.dart';
import 'call_texts.dart';

/// نتیجهٔ یک درخواست به سرور (دوستان/تاریخچهٔ تماس).
class ApiResult<T> {
  const ApiResult({required this.ok, this.code = '', this.message = '', this.data, this.raw});

  final bool ok;
  final String code;
  final String message;
  final T? data;
  final Map<String, dynamic>? raw;

  /// کاربر هنوز پروفایل (با نام) روی سرور ندارد.
  bool get needsProfile => code == 'not_registered' || code == 'no_name';

  String get text {
    if (message.isNotEmpty) return message;
    return code == 'net' ? CT.t('net_error') : CT.t('op_failed');
  }
}

class FriendItem {
  const FriendItem({
    required this.uid,
    required this.name,
    this.username = '',
    this.hasPhoto = true,
    this.badge,
  });

  final String uid;
  final String name;
  final String username;
  final bool hasPhoto;
  final String? badge;

  static FriendItem? fromJson(dynamic j) {
    if (j is! Map) return null;
    final uid = '${j['uid'] ?? ''}';
    if (uid.isEmpty) return null;
    return FriendItem(
      uid: uid,
      name: '${j['name'] ?? 'کاربر'}',
      username: '${j['username'] ?? ''}',
      hasPhoto: j['has_photo'] != false,
      badge: j['badge'] == null ? null : '${j['badge']}',
    );
  }
}

class BlockedItem {
  const BlockedItem({
    required this.uid,
    required this.name,
    this.username = '',
    this.hasPhoto = true,
    this.untilMs,
  });

  final String uid;
  final String name;
  final String username;
  final bool hasPhoto;

  /// null = تا وقتی کاربر خودش بردارد
  final int? untilMs;

  static BlockedItem? fromJson(dynamic j) {
    if (j is! Map) return null;
    final uid = '${j['uid'] ?? ''}';
    if (uid.isEmpty) return null;
    final until = j['until_at'];
    return BlockedItem(
      uid: uid,
      name: '${j['name'] ?? 'کاربر'}',
      username: '${j['username'] ?? ''}',
      hasPhoto: j['has_photo'] != false,
      untilMs: until is num ? until.toInt() : null,
    );
  }
}

class CallLogItem {
  const CallLogItem({
    required this.id,
    required this.peerUid,
    required this.peerName,
    required this.outgoing,
    required this.status,
    required this.atMs,
    this.peerUsername = '',
    this.hasPhoto = true,
    this.durationS = 0,
    this.msgKey,
    this.isFriend = false,
  });

  final String id;
  final String peerUid;
  final String peerName;
  final String peerUsername;
  final bool hasPhoto;
  final bool outgoing;

  /// answered | missed | declined | canceled
  final String status;
  final int atMs;
  final int durationS;
  final String? msgKey;
  final bool isFriend;

  /// تماس ورودیِ بی‌پاسخ (یا لغوشده توسط تماس‌گیرنده) برای گیرنده «از دست رفته» است.
  bool get isMissedForMe => !outgoing && (status == 'missed' || status == 'canceled');

  static CallLogItem? fromJson(dynamic j) {
    if (j is! Map) return null;
    final peer = '${j['peer_uid'] ?? ''}';
    if (peer.isEmpty) return null;
    final at = j['at'];
    final dur = j['duration_s'];
    return CallLogItem(
      id: '${j['id'] ?? ''}',
      peerUid: peer,
      peerName: '${j['peer_name'] ?? 'کاربر'}',
      peerUsername: '${j['peer_username'] ?? ''}',
      hasPhoto: j['has_photo'] != false,
      outgoing: '${j['direction']}' == 'out',
      status: '${j['status'] ?? ''}',
      atMs: at is num ? at.toInt() : 0,
      durationS: dur is num ? dur.toInt() : 0,
      msgKey: j['msg'] == null ? null : '${j['msg']}',
      isFriend: j['is_friend'] == true,
    );
  }
}

/// دوستان، بلاک موقت تماس و تاریخچهٔ تماس (همه روی ورکر).
class FriendsService {
  FriendsService._();

  static final Set<String> _friendUids = <String>{};
  static bool _loaded = false;

  static bool isFriendCached(String uid) => _friendUids.contains(uid);

  static ApiResult<T> _parse<T>(Map<String, dynamic>? j, T Function(Map<String, dynamic>) build) {
    if (j == null) return ApiResult<T>(ok: false, code: 'net', message: CT.t('net_error'));
    if (j['success'] == true) {
      return ApiResult<T>(ok: true, data: build(j), raw: j);
    }
    return ApiResult<T>(ok: false, code: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}', raw: j);
  }

  static List<T> _items<T>(dynamic raw, T? Function(dynamic) f) {
    final out = <T>[];
    if (raw is List) {
      for (final e in raw) {
        final v = f(e);
        if (v != null) out.add(v);
      }
    }
    return out;
  }

  static Future<ApiResult<List<FriendItem>>> list() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/friends/list', query: {'user_uid': uid});
    final r = _parse<List<FriendItem>>(j, (m) => _items<FriendItem>(m['items'], FriendItem.fromJson));
    if (r.ok) {
      _friendUids
        ..clear()
        ..addAll(r.data!.map((e) => e.uid));
      _loaded = true;
    }
    return r;
  }

  /// آیا این کاربر در دوستان من است؟ (اگر لازم باشد یک‌بار لیست را می‌گیرد)
  static Future<bool> isFriend(String uid) async {
    if (!_loaded) await list();
    return _friendUids.contains(uid);
  }

  /// افزودن مستقیم. یا friendUid (از پروفایل/تماس) یا identifier (جی‌میل/شماره/نام کاربری).
  static Future<ApiResult<FriendItem?>> add({String? friendUid, String? identifier}) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/friends/add', body: {
      'user_uid': uid,
      if (friendUid != null) 'friend_uid': friendUid,
      if (identifier != null) 'identifier': identifier,
    });
    final r = _parse<FriendItem?>(j, (m) => FriendItem.fromJson(m['friend']));
    if (r.ok) {
      final id = r.data?.uid ?? friendUid;
      if (id != null && id.isNotEmpty) _friendUids.add(id);
    }
    return r;
  }

  static Future<ApiResult<void>> remove(String friendUid) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/friends/remove', body: {'user_uid': uid, 'friend_uid': friendUid});
    final r = _parse<void>(j, (m) {});
    if (r.ok) _friendUids.remove(friendUid);
    return r;
  }

  /// بلاک موقت تماس. hours: 1، 24، 168 یا 0 (تا وقتی خودم بردارم).
  static Future<ApiResult<void>> blockCalls(String blockedUid, int hours) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/friends/block', body: {
      'user_uid': uid,
      'blocked_uid': blockedUid,
      'hours': hours,
    });
    return _parse<void>(j, (m) {});
  }

  static Future<ApiResult<void>> unblockCalls(String blockedUid) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/friends/unblock', body: {'user_uid': uid, 'blocked_uid': blockedUid});
    return _parse<void>(j, (m) {});
  }

  static Future<ApiResult<List<BlockedItem>>> blocked() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/friends/blocked', query: {'user_uid': uid});
    return _parse<List<BlockedItem>>(j, (m) => _items<BlockedItem>(m['items'], BlockedItem.fromJson));
  }

  static Future<ApiResult<List<CallLogItem>>> history() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/call/history', query: {'user_uid': uid});
    return _parse<List<CallLogItem>>(j, (m) => _items<CallLogItem>(m['items'], CallLogItem.fromJson));
  }
}
