import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/api_config.dart';
import '../core/language/menu_translations.dart';
import 'badge_service.dart';
import 'group_texts.dart';
import 'public_link_service.dart';
import 'safe_prefs.dart';

int _i(Object? v) => int.tryParse('$v') ?? 0;

/// یک گروه (عمومی/خصوصی) یا یک گفتگوی شخصی (kind == dm).
class GroupInfo {
  const GroupInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.kind = 'public',
    this.username,
    this.memberCount = 0,
    this.retentionHours = 24,
    this.joinApproval = false,
    this.role,
    this.status,
    this.inviteCode,
    this.lastId = 0,
    this.peerUid,
    this.peerName = '',
    this.ttlOptions = const [],
    this.retentionLocked = false,
    this.photoV = 0,
    this.slowSecs = 0,
    this.onlyAdmins = false,
    this.pinnedId = 0,
  });

  final int id;
  final String name;
  final String description;
  final String kind; // public | private | dm
  final String? username;
  final int memberCount;
  final int retentionHours;
  final bool joinApproval;
  final String? role; // owner | admin | member
  final String? status; // active | pending
  final String? inviteCode;
  final int lastId;
  final String? peerUid;
  final String peerName;
  final List<int> ttlOptions;
  final bool retentionLocked;

  /// نسخهٔ عکس گروه (۰ = بدون عکس)؛ در آدرس عکس برای تازه‌شدن کش استفاده می‌شود.
  final int photoV;

  /// حالت آهسته (ثانیه بین دو پیام هر عضو؛ ۰ = خاموش) و «فقط مدیران پیام بدهند».
  final int slowSecs;
  final bool onlyAdmins;
  final int pinnedId;

  GroupInfo copyWith({int? photoV, int? memberCount, int? slowSecs, bool? onlyAdmins}) => GroupInfo(
        id: id,
        name: name,
        description: description,
        kind: kind,
        username: username,
        memberCount: memberCount ?? this.memberCount,
        retentionHours: retentionHours,
        joinApproval: joinApproval,
        role: role,
        status: status,
        inviteCode: inviteCode,
        lastId: lastId,
        peerUid: peerUid,
        peerName: peerName,
        ttlOptions: ttlOptions,
        retentionLocked: retentionLocked,
        photoV: photoV ?? this.photoV,
        slowSecs: slowSecs ?? this.slowSecs,
        onlyAdmins: onlyAdmins ?? this.onlyAdmins,
        pinnedId: pinnedId,
      );

  GroupInfo withPhoto(int v) => copyWith(photoV: v);

  bool get isDm => kind == 'dm';
  bool get isPublic => kind == 'public';
  bool get isOwner => role == 'owner';
  bool get isStaff => role == 'owner' || role == 'admin';
  bool get isMember => status == 'active';
  String get title => isDm ? (peerName.isEmpty ? '…' : peerName) : name;

  /// لینک دعوت (همان قالب لینک‌های عمومی سایروس توریست).
  String? get inviteUrl => (inviteCode == null || inviteCode!.isEmpty) ? null : '${PublicLinkService.baseUrl}/group/$inviteCode';

  factory GroupInfo.fromJson(Map<String, dynamic> j) {
    final r = _i(j['retention_hours']);
    return GroupInfo(
      id: _i(j['id']),
      name: '${j['name'] ?? ''}',
      description: '${j['description'] ?? ''}',
      kind: '${j['kind'] ?? 'public'}',
      username: j['username'] == null ? null : '${j['username']}',
      memberCount: _i(j['member_count']),
      retentionHours: r == 0 ? 24 : r,
      joinApproval: j['join_approval'] == true,
      role: j['role'] == null ? null : '${j['role']}',
      status: j['status'] == null ? null : '${j['status']}',
      inviteCode: j['invite_code'] == null ? null : '${j['invite_code']}',
      lastId: _i(j['last_id']),
      peerUid: j['peer_uid'] == null ? null : '${j['peer_uid']}',
      peerName: '${j['peer_name'] ?? ''}',
      ttlOptions: ((j['ttl_options'] as List?) ?? const []).map(_i).where((x) => x > 0).toList(),
      retentionLocked: j['retention_locked'] == true,
      photoV: _i(j['photo_v']),
      slowSecs: _i(j['slow_secs']),
      onlyAdmins: j['only_admins'] == true,
      pinnedId: _i(j['pinned_id']),
    );
  }
}

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.uid,
    required this.name,
    required this.text,
    required this.at,
    required this.mine,
    this.badge,
    this.replyId = 0,
    this.replyName = '',
    this.replyText = '',
    this.reactions = const {},
    this.myReaction = '',
  });

  final int id;
  final String uid;
  final String name;
  final String text;
  final DateTime? at;
  final bool mine;
  final String? badge; // blue | gold
  final int replyId;
  final String replyName;
  final String replyText;
  final Map<String, int> reactions; // emoji -> تعداد
  final String myReaction;

  GroupMessage copyWith({Map<String, int>? reactions, String? myReaction}) => GroupMessage(
        id: id,
        uid: uid,
        name: name,
        text: text,
        at: at,
        mine: mine,
        badge: badge,
        replyId: replyId,
        replyName: replyName,
        replyText: replyText,
        reactions: reactions ?? this.reactions,
        myReaction: myReaction ?? this.myReaction,
      );

  factory GroupMessage.fromJson(Map<String, dynamic> j) {
    final r = j['reply'];
    return GroupMessage(
      id: _i(j['id']),
      uid: '${j['uid'] ?? ''}',
      name: '${j['name'] ?? ''}',
      text: '${j['text'] ?? ''}',
      at: DateTime.tryParse('${j['at']}'.replaceFirst(' ', 'T') + 'Z')?.toLocal(),
      mine: j['mine'] == true,
      badge: j['badge'] == null ? null : '${j['badge']}',
      replyId: r is Map ? _i(r['id']) : 0,
      replyName: r is Map ? '${r['name'] ?? ''}' : '',
      replyText: r is Map ? '${r['text'] ?? ''}' : '',
    );
  }
}

/// پیام سنجاق‌شده.
class GroupPinned {
  const GroupPinned({required this.id, required this.name, required this.text});
  final int id;
  final String name;
  final String text;
}

/// وضعیت زندهٔ گروه (فقط وقتی نسخه عوض شده از سرور می‌آید): واکنش‌ها، سنجاق و پیام‌های حذف‌شده.
class GroupState {
  const GroupState({required this.sv, this.minId = 0, this.hiddenIds = const {}, this.reactions = const {}, this.mine = const {}, this.pinned});
  final int sv;

  /// کوچک‌ترین شناسهٔ پنجرهٔ ۶۰ پیام آخر؛ فقط پیام‌های داخل این پنجره بروز می‌شوند.
  final int minId;
  final Set<int> hiddenIds;
  final Map<int, Map<String, int>> reactions;
  final Map<int, String> mine;
  final GroupPinned? pinned;

  factory GroupState.fromJson(Map<String, dynamic> j) {
    final rx = <int, Map<String, int>>{};
    final rawRx = j['reactions'];
    if (rawRx is Map) {
      rawRx.forEach((k, v) {
        if (v is Map) rx[_i(k)] = v.map((e, n) => MapEntry('$e', _i(n)));
      });
    }
    final mine = <int, String>{};
    final rawMine = j['mine'];
    if (rawMine is Map) rawMine.forEach((k, v) => mine[_i(k)] = '$v');
    final p = j['pinned'];
    return GroupState(
      sv: _i(j['sv']),
      minId: _i(j['min_id']),
      hiddenIds: ((j['hidden_ids'] as List?) ?? const []).map(_i).toSet(),
      reactions: rx,
      mine: mine,
      pinned: p is Map ? GroupPinned(id: _i(p['id']), name: '${p['name'] ?? ''}', text: '${p['text'] ?? ''}') : null,
    );
  }
}

class GroupMember {
  const GroupMember({required this.uid, required this.name, this.username = '', this.role = 'member', this.badge});
  final String uid;
  final String name;
  final String username;
  final String role;
  final String? badge;

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        uid: '${j['uid'] ?? ''}',
        name: '${j['name'] ?? ''}',
        username: '${j['username'] ?? ''}',
        role: '${j['role'] ?? 'member'}',
        badge: j['badge'] == null ? null : '${j['badge']}',
      );
}

class GroupLimits {
  const GroupLimits({this.maxGroups = 3, this.maxRetentionHours = 24, this.options = const [1, 6, 12, 24], this.defaultRetentionHours = 24});
  final int maxGroups;
  final int maxRetentionHours;
  final List<int> options;
  final int defaultRetentionHours;
}

class GroupMine {
  const GroupMine({
    required this.ok,
    this.error = '',
    this.message = '',
    this.enabled = true,
    this.dmEnabled = true,
    this.phoneMode = 'verified',
    this.limits = const GroupLimits(),
    this.groups = const [],
  });
  final bool ok;
  final String error;
  final String message;
  final bool enabled;
  final bool dmEnabled;
  final String phoneMode;
  final GroupLimits limits;
  final List<GroupInfo> groups;

  List<GroupInfo> get chats => groups.where((g) => !g.isDm).toList();
  List<GroupInfo> get dms => groups.where((g) => g.isDm).toList();
}

class GroupResult {
  const GroupResult({required this.ok, this.error = '', this.message = '', this.group, this.status = '', this.raw});
  final bool ok;
  final String error;
  final String message;
  final GroupInfo? group;
  final String status; // active | pending
  final Map<String, dynamic>? raw;

  /// متن مناسب نمایش (پیام سرور یا متن محلی).
  String get text => message.isNotEmpty ? message : (error.isNotEmpty ? GT.err(error) : GT.t('op_failed'));
}

class GroupFetch {
  const GroupFetch({
    required this.ok,
    this.error = '',
    this.message = '',
    this.messages = const [],
    this.retentionHours = 24,
    this.memberCount = 0,
    this.role = 'member',
    this.slowSecs = 0,
    this.onlyAdmins = false,
    this.state,
  });
  final bool ok;
  final String error;
  final String message;
  final List<GroupMessage> messages;
  final int slowSecs;
  final bool onlyAdmins;
  final GroupState? state;
  final int retentionHours;
  final int memberCount;
  final String role;
}

class GroupMembers {
  const GroupMembers({required this.ok, this.members = const [], this.pending = const [], this.memberCount = 0});
  final bool ok;
  final List<GroupMember> members;
  final List<GroupMember> pending;
  final int memberCount;
}

/// ارتباط با API گروه‌ها و چت شخصی (Worker پنل). پیام‌ها موقتی‌اند و سمت سرور پاک می‌شوند.
class GroupService {
  GroupService._();

  static const String _base = ApiConfig.panelBaseUrl;

  // شناسه و توکن آخرین فراخوانی؛ برای بارگذاری عکس گروه خصوصی با Image.network (هدر توکن)
  static String _cachedUid = '';
  static String _cachedToken = '';

  static Map<String, String> get imageHeaders => _cachedToken.isEmpty ? const <String, String>{} : {'X-Cyrus-Token': _cachedToken};

  /// آدرس عکس گروه (با نسخه برای کش).
  static String photoUrl(GroupInfo g) => '$_base/api/groups/photo?group_id=${g.id}&v=${g.photoV}&user_uid=$_cachedUid';

  // زبان‌هایی که ورکر پیام‌شان را دارد؛ بقیه انگلیسی
  static String _lang() {
    const ok = ['fa', 'en', 'ar', 'tr', 'ru'];
    final l = MenuLanguage.current;
    return ok.contains(l) ? l : 'en';
  }

  static Future<Map<String, dynamic>?> _call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uid = await BadgeService.userUid();
    _cachedUid = uid;
    final q = <String, String>{'lang': _lang()};
    if (method == 'GET') q['user_uid'] = uid;
    if (query != null) q.addAll(query);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: q);
      final req = await client.openUrl(method, uri).timeout(const Duration(seconds: 10));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = await BadgeService.deviceToken();
      _cachedToken = token;
      req.headers.set('X-Cyrus-Token', token);
      if (body != null) {
        final b = <String, dynamic>{'user_uid': uid, 'lang': _lang()};
        b.addAll(body);
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(b)));
      }
      final res = await req.close().timeout(const Duration(seconds: 10));
      final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (e) {
      debugPrint('GroupService $path: ${e.runtimeType}');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static GroupResult _result(Map<String, dynamic>? j) {
    if (j == null) return GroupResult(ok: false, error: 'net', message: GT.t('net'));
    final g = j['group'];
    return GroupResult(
      ok: j['success'] == true,
      error: '${j['error'] ?? ''}',
      message: '${j['message'] ?? ''}',
      group: g is Map<String, dynamic> ? GroupInfo.fromJson(g) : null,
      status: '${j['status'] ?? ''}',
      raw: j,
    );
  }

  static List<GroupInfo> _groups(Object? data) =>
      ((data as List?) ?? const []).whereType<Map<String, dynamic>>().map(GroupInfo.fromJson).toList();

  // ---------- فهرست‌ها ----------
  static Future<GroupMine> mine() async {
    final j = await _call('GET', '/api/groups/mine');
    if (j == null) return GroupMine(ok: false, error: 'net', message: GT.t('net'));
    if (j['success'] != true) return GroupMine(ok: false, error: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
    final l = j['limits'];
    var limits = const GroupLimits();
    if (l is Map<String, dynamic>) {
      limits = GroupLimits(
        maxGroups: _i(l['max_groups']),
        maxRetentionHours: _i(l['max_retention_hours']) == 0 ? 24 : _i(l['max_retention_hours']),
        options: ((l['options'] as List?) ?? const []).map(_i).where((x) => x > 0).toList(),
        defaultRetentionHours: _i(l['default_retention_hours']) == 0 ? 24 : _i(l['default_retention_hours']),
      );
    }
    return GroupMine(
      ok: true,
      enabled: j['enabled'] != false,
      dmEnabled: j['dm_enabled'] != false,
      phoneMode: '${j['phone_mode'] ?? 'verified'}',
      limits: limits,
      groups: _groups(j['data']),
    );
  }

  static Future<List<GroupInfo>> search(String q) async {
    final j = await _call('GET', '/api/groups/search', query: {'q': q});
    if (j == null || j['success'] != true) return const [];
    return _groups(j['data']);
  }

  // ---------- ساخت / اطلاعات / پیوستن ----------
  static Future<GroupResult> create({
    required String name,
    String description = '',
    required String kind,
    String username = '',
    int? retentionHours,
    bool joinApproval = false,
  }) async {
    final j = await _call('POST', '/api/groups/create', body: {
      'name': name,
      'description': description,
      'kind': kind,
      'username': username,
      if (retentionHours != null) 'retention_hours': retentionHours,
      'join_approval': joinApproval,
    });
    final r = _result(j);
    if (r.ok) unawaited(GroupPush.syncTopics(force: true));
    return r;
  }

  static Future<GroupResult> info({int? id, String? invite, String? username}) async {
    final j = await _call('GET', '/api/groups/info', query: {
      if (id != null) 'group_id': '$id',
      if (invite != null) 'invite': invite,
      if (username != null) 'username': username,
    });
    return _result(j);
  }

  static Future<GroupResult> join({int? id, String? invite, String? username}) async {
    final j = await _call('POST', '/api/groups/join', body: {
      if (id != null) 'group_id': id,
      if (invite != null) 'invite_code': invite,
      if (username != null) 'username': username,
    });
    final r = _result(j);
    if (r.ok) unawaited(GroupPush.syncTopics(force: true));
    return r;
  }

  static Future<GroupResult> leave(int id) async {
    final r = _result(await _call('POST', '/api/groups/leave', body: {'group_id': id}));
    if (r.ok) unawaited(GroupPush.syncTopics(force: true));
    return r;
  }

  static Future<GroupResult> deleteGroup(int id) async {
    final r = _result(await _call('POST', '/api/groups/delete', body: {'group_id': id}));
    if (r.ok) unawaited(GroupPush.syncTopics(force: true));
    return r;
  }

  static Future<GroupResult> update(
    int id, {
    String? name,
    String? description,
    String? kind,
    String? username,
    int? retentionHours,
    bool? joinApproval,
    int? slowSecs,
    bool? onlyAdmins,
  }) async {
    final j = await _call('POST', '/api/groups/update', body: {
      'group_id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (kind != null) 'kind': kind,
      if (username != null) 'username': username,
      if (retentionHours != null) 'retention_hours': retentionHours,
      if (joinApproval != null) 'join_approval': joinApproval,
      if (slowSecs != null) 'slow_secs': slowSecs,
      if (onlyAdmins != null) 'only_admins': onlyAdmins,
    });
    return _result(j);
  }

  /// لینک دعوت تازه؛ کد جدید را برمی‌گرداند (یا null).
  static Future<String?> resetInvite(int id) async {
    final j = await _call('POST', '/api/groups/invite/reset', body: {'group_id': id});
    if (j == null || j['success'] != true) return null;
    return '${j['invite_code']}';
  }

  /// عکس گروه (base64 فشرده‌شده). نسخهٔ تازهٔ عکس در raw['photo_v'] برمی‌گردد.
  static Future<GroupResult> setPhoto(int id, String base64Jpeg) async {
    return _result(await _call('POST', '/api/groups/photo/set', body: {'group_id': id, 'data': base64Jpeg}));
  }

  static Future<GroupResult> removePhoto(int id) async {
    return _result(await _call('POST', '/api/groups/photo/remove', body: {'group_id': id}));
  }

  // ---------- اعضا ----------
  static Future<GroupMembers> members(int id) async {
    final j = await _call('GET', '/api/groups/members', query: {'group_id': '$id'});
    if (j == null || j['success'] != true) return const GroupMembers(ok: false);
    List<GroupMember> parse(Object? v) =>
        ((v as List?) ?? const []).whereType<Map<String, dynamic>>().map(GroupMember.fromJson).toList();
    return GroupMembers(ok: true, members: parse(j['members']), pending: parse(j['pending']), memberCount: _i(j['member_count']));
  }

  /// action: kick | ban | unban | promote | demote | approve | reject
  static Future<GroupResult> manage(int id, String targetUid, String action) async {
    return _result(await _call('POST', '/api/groups/members/manage', body: {'group_id': id, 'target_uid': targetUid, 'action': action}));
  }

  // ---------- پیام‌ها ----------
  static Future<GroupFetch> messages(int id, {int afterId = 0, int? sv}) async {
    final j = await _call('GET', '/api/groups/messages', query: {'group_id': '$id', 'after_id': '$afterId', if (sv != null) 'sv': '$sv'});
    if (j == null) return GroupFetch(ok: false, error: 'net', message: GT.t('net'));
    if (j['success'] != true) return GroupFetch(ok: false, error: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
    return GroupFetch(
      ok: true,
      retentionHours: _i(j['retention_hours']) == 0 ? 24 : _i(j['retention_hours']),
      memberCount: _i(j['member_count']),
      role: '${j['role'] ?? 'member'}',
      slowSecs: _i(j['slow_secs']),
      onlyAdmins: j['only_admins'] == true,
      messages: ((j['messages'] as List?) ?? const []).whereType<Map<String, dynamic>>().map(GroupMessage.fromJson).toList(),
      state: j['state'] is Map<String, dynamic> ? GroupState.fromJson(j['state'] as Map<String, dynamic>) : null,
    );
  }

  static Future<GroupResult> send(int id, String text, {int replyTo = 0}) async {
    return _result(await _call('POST', '/api/groups/send', body: {'group_id': id, 'body': text, if (replyTo > 0) 'reply_to': replyTo}));
  }

  /// واکنش ایموجی به پیام (دوباره زدن همان ایموجی = برداشتن). raw['my'] = واکنش فعلی من.
  static Future<GroupResult> react(int groupId, int messageId, String emoji) async {
    return _result(await _call('POST', '/api/groups/react', body: {'group_id': groupId, 'message_id': messageId, 'emoji': emoji}));
  }

  /// سنجاق پیام (messageId = 0 یعنی برداشتن سنجاق).
  static Future<GroupResult> pin(int groupId, int messageId) async {
    return _result(await _call('POST', '/api/groups/pin', body: {'group_id': groupId, 'message_id': messageId}));
  }

  /// افزودن دوستان به گروه (مالک/مدیر). raw: added، skipped، member_count.
  static Future<GroupResult> addMembers(int groupId, List<String> uids) async {
    return _result(await _call('POST', '/api/groups/members/add', body: {'group_id': groupId, 'target_uids': uids}));
  }

  static Future<bool> report(int groupId, int messageId, {String reason = ''}) async {
    final j = await _call('POST', '/api/groups/report', body: {'group_id': groupId, 'message_id': messageId, 'reason': reason});
    return j != null && j['success'] == true;
  }

  static Future<bool> hideMessage(int groupId, int messageId) async {
    final j = await _call('POST', '/api/groups/messages/hide', body: {'group_id': groupId, 'message_id': messageId});
    return j != null && j['success'] == true;
  }

  /// بازکردن (یا ساخت) گفتگوی شخصی با یک کاربر.
  static Future<GroupResult> dmOpen(String targetUid) async {
    return _result(await _call('POST', '/api/groups/dm/open', body: {'target_uid': targetUid}));
  }

  // ---------- خوانده‌نشده‌ها (محلی) ----------
  static Future<int> seenId(int groupId) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt('grp_seen_$groupId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markSeen(int groupId, int lastId) async {
    if (lastId <= 0) return;
    try {
      final p = await SharedPreferences.getInstance();
      if ((p.getInt('grp_seen_$groupId') ?? 0) < lastId) await p.setInt('grp_seen_$groupId', lastId);
    } catch (_) {}
  }

  // ---------- حالت شمارهٔ تلفن در چت‌ها (off | verified | all) ----------
  static String _phoneMode = 'verified';
  static DateTime? _phoneAt;

  static Future<String> phoneMode() async {
    final at = _phoneAt;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 10)) return _phoneMode;
    final j = await _call('GET', '/api/app/flags');
    if (j != null && j['success'] == true) {
      final m = '${j['chat_phone_mode'] ?? 'verified'}';
      if (m == 'off' || m == 'verified' || m == 'all') _phoneMode = m;
      _phoneAt = DateTime.now();
    }
    return _phoneMode;
  }
}

/// بیدارباش FCM برای گروه‌ها و چت شخصی:
/// - هر عضو گروه به topic «grp_<id>» مشترک است (فقط {group_id,last_id}، بدون متن پیام)؛
/// - چت شخصی با پیام data-only به توکن‌های خود کاربر می‌رسد.
/// صفحهٔ باز با دریافت بیدارباش همان لحظه پیام تازه را می‌گیرد؛ پیام‌های شخصی اعلان هم دارند.
class GroupPush {
  GroupPush._();

  static final StreamController<Map<String, String>> _wake = StreamController<Map<String, String>>.broadcast();
  static Stream<Map<String, String>> get wakes => _wake.stream;

  /// شناسهٔ گروهی که الان صفحهٔ چتش باز است (برای اعلان نکردن همان گفتگو).
  static int activeGroupId = 0;

  static DateTime? _lastSync;
  static const String _topicsKey = 'grp_topics';
  static const String _mutedKey = 'dm_muted';

  // ---------- بی‌صدا کردن اعلان پیام‌های شخصی یک کاربر (محلی روی همین گوشی) ----------
  static Future<Set<String>> _mutedSet() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_mutedKey) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<bool> isMuted(String uid) async => (await _mutedSet()).contains(uid);

  static Future<void> setMuted(String uid, bool muted) async {
    try {
      final set = await _mutedSet();
      if (muted) {
        set.add(uid);
      } else {
        set.remove(uid);
      }
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_mutedKey, set.toList());
    } catch (_) {}
  }
  static const String _dmChannelId = 'cyrus_dm_v1';
  static const String _dmChannelName = 'پیام‌های شخصی';
  static const String _dmChannelDesc = 'اعلان پیام‌های شخصی';
  static const String _groupChannelId = 'cyrus_group_v1';
  static const String _groupChannelName = 'گروه‌ها';
  static const String _groupChannelDesc = 'اعلان افزوده‌شدن به گروه';

  static bool isGroupData(Map<String, dynamic> d) {
    final t = d['type'];
    return t == 'group_msg' || t == 'dm_msg' || t == 'group_added';
  }

  /// اپ باز است (onMessage).
  static void handleForeground(Map<String, dynamic> data, {bool notify = true}) {
    _wake.add(data.map((k, v) => MapEntry(k, '$v')));
    final gid = _i(data['group_id']);
    if (data['type'] == 'group_added') {
      unawaited(syncTopics(force: true));
      if (notify) unawaited(_showAdded(data, initialize: false));
      return;
    }
    if (notify && data['type'] == 'dm_msg' && gid != activeGroupId) {
      unawaited(_showDm(data, initialize: false));
    }
  }

  /// اپ در پس‌زمینه/بسته است (isolate پس‌زمینه).
  static Future<void> handleBackground(Map<String, dynamic> data) async {
    if (data['type'] == 'dm_msg') await _showDm(data, initialize: true);
    if (data['type'] == 'group_added') await _showAdded(data, initialize: true);
  }

  static Future<void> _showAdded(Map<String, dynamic> data, {required bool initialize}) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (initialize) {
        await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_notify')));
      }
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _groupChannelId,
        _groupChannelName,
        description: _groupChannelDesc,
        importance: Importance.high,
      ));
      final gid = _i(data['group_id']);
      await plugin.show(
        800000 + (gid % 100000),
        GT.t('added_notif_title'),
        GT.t('added_notif_body', {'name': '${data['sender_name'] ?? ''}', 'group': '${data['group_name'] ?? ''}'}),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _groupChannelId,
            _groupChannelName,
            channelDescription: _groupChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('group added notification error: $e');
    }
  }

  static Future<void> _showDm(Map<String, dynamic> data, {required bool initialize}) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (initialize) {
        await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_notify')));
      }
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _dmChannelId,
        _dmChannelName,
        description: _dmChannelDesc,
        importance: Importance.high,
      ));
      final senderUid = '${data['sender_uid'] ?? ''}';
      if (senderUid.isNotEmpty && await isMuted(senderUid)) return;
      final gid = _i(data['group_id']);
      await plugin.show(
        700000 + (gid % 100000),
        GT.t('dm_notif_title', {'name': '${data['sender_name'] ?? ''}'}),
        GT.t('dm_notif_body'),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dmChannelId,
            _dmChannelName,
            channelDescription: _dmChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('dm notification error: $e');
    }
  }

  /// اشتراک topic گروه‌های من را با لیست سرور هم‌گام می‌کند (حداکثر هر ۴ ساعت؛ force برای بعد از پیوستن/خروج).
  static Future<void> syncTopics({bool force = false}) async {
    final now = DateTime.now();
    final last = _lastSync;
    if (!force && last != null && now.difference(last) < const Duration(hours: 4)) return;
    _lastSync = now;
    try {
      final m = await GroupService.mine();
      if (!m.ok) return;
      final want = <String>{
        for (final g in m.groups)
          if (!g.isDm && g.status == 'active') 'grp_${g.id}',
      };
      final prefs = await SharedPreferences.getInstance();
      final have = (prefs.getStringList(_topicsKey) ?? const <String>[]).toSet();
      final fcm = FirebaseMessaging.instance;
      for (final t in want.difference(have)) {
        await fcm.subscribeToTopic(t);
      }
      for (final t in have.difference(want)) {
        await fcm.unsubscribeFromTopic(t);
      }
      await prefs.setStringList(_topicsKey, want.toList());
    } catch (e) {
      debugPrint('group topics sync: $e');
    }
  }
}
