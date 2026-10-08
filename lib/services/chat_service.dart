import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import 'badge_service.dart';

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.city,
    required this.kind,
    required this.windows,
    required this.open,
    this.nextOpenHour,
  });

  final int id;
  final String city;
  final String kind; // public | companion
  final List<List<int>> windows;
  final bool open;
  final double? nextOpenHour;

  factory ChatRoom.fromJson(Map<String, dynamic> j) => ChatRoom(
        id: int.tryParse('${j['id']}') ?? 0,
        city: '${j['city']}',
        kind: '${j['kind']}',
        windows: ((j['windows'] as List?) ?? const [])
            .whereType<List>()
            .map((w) => [int.tryParse('${w[0]}') ?? 0, int.tryParse('${w[1]}') ?? 0])
            .toList(),
        open: j['open'] == true,
        nextOpenHour: j['next_open_hour'] == null ? null : double.tryParse('${j['next_open_hour']}'),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    required this.text,
    required this.at,
    required this.mine,
    this.badge,
  });

  final int id;
  final String uid;
  final String name;
  final String text;
  final DateTime? at;
  final bool mine;
  final String? badge; // blue | gold

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: int.tryParse('${j['id']}') ?? 0,
        uid: '${j['uid'] ?? ''}',
        name: '${j['name'] ?? 'کاربر'}',
        text: '${j['text'] ?? ''}',
        at: DateTime.tryParse('${j['at']}'.replaceFirst(' ', 'T') + 'Z')?.toLocal(),
        mine: j['mine'] == true,
        badge: j['badge'] == null ? null : '${j['badge']}',
      );
}

class ChatFetch {
  const ChatFetch({required this.ok, this.open = true, this.messages = const [], this.windows = const [], this.nextOpenHour});
  final bool ok;
  final bool open;
  final List<ChatMessage> messages;
  final List<List<int>> windows;
  final double? nextOpenHour;
}

class ChatSendResult {
  const ChatSendResult({required this.ok, this.error = '', this.message = ''});
  final bool ok;
  final String error; // no_name | not_registered | closed | blocked | slow_down | link | phone | net
  final String message;
}

class CompanionPost {
  const CompanionPost({
    required this.id,
    this.uid = '',
    required this.title,
    this.origin = '',
    this.destination = '',
    required this.details,
    required this.travelDate,
    required this.seats,
    required this.name,
    required this.mine,
    this.badge,
  });

  final int id;
  final String uid;
  final String title;
  final String origin;
  final String destination;
  final String details;
  final String travelDate;
  final int seats;
  final String name;
  final bool mine;
  final String? badge;

  factory CompanionPost.fromJson(Map<String, dynamic> j) => CompanionPost(
        id: int.tryParse('${j['id']}') ?? 0,
        uid: '${j['uid'] ?? ''}',
        title: '${j['title'] ?? ''}',
        origin: '${j['origin'] ?? ''}'.replaceAll('null', ''),
        destination: '${j['destination'] ?? ''}'.replaceAll('null', ''),
        details: '${j['details'] ?? ''}'.replaceAll('null', ''),
        travelDate: '${j['travel_date'] ?? ''}'.replaceAll('null', ''),
        seats: int.tryParse('${j['seats_left']}') ?? 1,
        name: '${j['name'] ?? 'کاربر'}',
        mine: j['mine'] == true,
        badge: j['badge'] == null ? null : '${j['badge']}',
      );
}

/// ارتباط با API چت‌روم (Worker پنل). پیام‌ها موقتی‌اند و سمت سرور پاک می‌شوند.
class ChatService {
  ChatService._();

  static const String _base = ApiConfig.panelBaseUrl;

  static Future<Map<String, dynamic>?> _call(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: query);
      final req = await client.openUrl(method, uri).timeout(const Duration(seconds: 10));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      // توکن دستگاه: ورکر برای حساب‌های ثبت‌شده آن را می‌خواهد (بدونش «نشست نامعتبر است»)
      req.headers.set('X-Cyrus-Token', await BadgeService.deviceToken());
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(const Duration(seconds: 10));
      final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<ChatRoom>> rooms() async {
    final j = await _call('GET', '/api/chat/rooms');
    if (j == null || j['success'] != true) return const [];
    return (j['data'] as List).whereType<Map<String, dynamic>>().map(ChatRoom.fromJson).toList();
  }

  static Future<ChatFetch> messages(int roomId, {int afterId = 0}) async {
    final uid = await BadgeService.userUid();
    final j = await _call('GET', '/api/chat/messages', query: {
      'room_id': '$roomId',
      'after_id': '$afterId',
      'user_uid': uid,
    });
    if (j == null || j['success'] != true) return const ChatFetch(ok: false);
    return ChatFetch(
      ok: true,
      open: j['open'] == true,
      nextOpenHour: j['next_open_hour'] == null ? null : double.tryParse('${j['next_open_hour']}'),
      windows: ((j['windows'] as List?) ?? const [])
          .whereType<List>()
          .map((w) => [int.tryParse('${w[0]}') ?? 0, int.tryParse('${w[1]}') ?? 0])
          .toList(),
      messages: ((j['messages'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
    );
  }

  static Future<ChatSendResult> send(int roomId, String text) async {
    final uid = await BadgeService.userUid();
    final j = await _call('POST', '/api/chat/send', body: {'user_uid': uid, 'room_id': roomId, 'body': text});
    if (j == null) return const ChatSendResult(ok: false, error: 'net', message: 'ارتباط با سرور برقرار نشد.');
    if (j['success'] == true) return const ChatSendResult(ok: true);
    return ChatSendResult(ok: false, error: '${j['error'] ?? ''}', message: '${j['message'] ?? 'ارسال نشد.'}');
  }

  static Future<bool> report(int messageId, {String reason = ''}) async {
    final uid = await BadgeService.userUid();
    final j = await _call('POST', '/api/chat/report', body: {'user_uid': uid, 'message_id': messageId, 'reason': reason});
    return j != null && j['success'] == true;
  }

  static Future<bool> block(String blockedUid) async {
    final uid = await BadgeService.userUid();
    final j = await _call('POST', '/api/chat/block', body: {'user_uid': uid, 'blocked_uid': blockedUid});
    return j != null && j['success'] == true;
  }

  static Future<List<CompanionPost>> posts(String city) async {
    final uid = await BadgeService.userUid();
    final j = await _call('GET', '/api/companion/posts', query: {'city': city, 'user_uid': uid});
    if (j == null || j['success'] != true) return const [];
    return (j['data'] as List).whereType<Map<String, dynamic>>().map(CompanionPost.fromJson).toList();
  }

  static Future<ChatSendResult> createPost({
    required String city,
    required String origin,
    required String destination,
    String title = '',
    String details = '',
    String travelDate = '',
    int seats = 1,
  }) async {
    final uid = await BadgeService.userUid();
    final j = await _call('POST', '/api/companion/post', body: {
      'user_uid': uid,
      'city': city,
      'title': title,
      'origin': origin,
      'destination': destination,
      'details': details,
      'travel_date': travelDate,
      'seats_left': seats,
    });
    if (j == null) return const ChatSendResult(ok: false, error: 'net', message: 'ارتباط با سرور برقرار نشد.');
    if (j['success'] == true) return const ChatSendResult(ok: true);
    return ChatSendResult(ok: false, error: '${j['error'] ?? ''}', message: '${j['message'] ?? 'ثبت نشد.'}');
  }

  static Future<bool> closePost(int postId) async {
    final uid = await BadgeService.userUid();
    final j = await _call('POST', '/api/companion/close', body: {'user_uid': uid, 'post_id': postId});
    return j != null && j['success'] == true;
  }
}
