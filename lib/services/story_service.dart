import 'package:shared_preferences/shared_preferences.dart';

import 'badge_service.dart';

class Story {
  Story({
    required this.id,
    required this.kind,
    required this.text,
    required this.bg,
    required this.at,
    required this.hasImage,
    this.likes = 0,
    this.views,
    this.liked = false,
    this.featured = false,
  });

  final int id;
  final String kind; // image | text
  final String text;
  final int bg;
  final DateTime? at;
  final bool hasImage;
  int likes;
  final int? views; // فقط برای صاحب استوری
  bool liked;
  final bool featured;

  bool get isText => kind == 'text';
}

class StoryGroup {
  StoryGroup({required this.uid, required this.name, required this.badge, required this.hasPhoto, required this.mine, required this.stories});

  final String uid;
  final String name;
  final String? badge;
  final bool hasPhoto;
  final bool mine;
  final List<Story> stories;
}

class StoryMe {
  const StoryMe({
    required this.canPost,
    this.badge,
    this.dailyLimit = 0,
    this.storiesToday = 0,
    this.remaining = 0,
    this.storyEnabled = true,
  });
  final bool canPost;
  final String? badge;
  final int dailyLimit;
  final int storiesToday;
  final int remaining;
  final bool storyEnabled;
}

class AudiencePerson {
  const AudiencePerson({required this.uid, required this.name, required this.hasPhoto, required this.at, required this.liked});
  final String uid;
  final String name;
  final bool hasPhoto;
  final DateTime? at;
  final bool liked;
}

class StoryAudience {
  const StoryAudience({required this.views, required this.likes, required this.people});
  final int views;
  final int likes;
  final List<AudiencePerson> people;
}

class StoryActionResult {
  const StoryActionResult({required this.ok, this.message = '', this.code = ''});
  final bool ok;
  final String message;
  final String code;
}

/// استوری ۲۴ ساعته. دیدن برای همه؛ گذاشتن فقط برای دارندگان تیک آبی/طلایی (سرور بررسی می‌کند).
class StoryService {
  StoryService._();

  static String imageUrl(int id) => '${BadgeService.baseUrl}/api/stories/image?id=$id';
  static String photoUrl(String uid) => '${BadgeService.baseUrl}/api/users/photo?uid=$uid';

  /// null = خطای ارتباط
  static Future<List<StoryGroup>?> fetch() async {
    final me = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/stories', query: {'viewer': me});
    if (j == null || j['success'] != true) return null;
    final list = j['groups'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((g) {
      final stories = (g['stories'] is List ? g['stories'] as List : const [])
          .whereType<Map>()
          .map((x) => Story(
                id: int.tryParse('${x['id']}') ?? 0,
                kind: '${x['kind'] ?? 'image'}',
                text: '${x['text'] ?? ''}',
                bg: int.tryParse('${x['bg']}') ?? 0,
                at: DateTime.tryParse('${x['at'] ?? ''}'.replaceFirst(' ', 'T') + 'Z')?.toLocal(),
                hasImage: x['has_image'] == true,
                likes: int.tryParse('${x['likes']}') ?? 0,
                views: x['views'] == null ? null : int.tryParse('${x['views']}'),
                liked: x['liked'] == true,
                featured: x['featured'] == true,
              ))
          .toList();
      return StoryGroup(
        uid: '${g['uid']}',
        name: '${g['name'] ?? ''}',
        badge: g['badge'] == null ? null : '${g['badge']}',
        hasPhoto: g['has_photo'] == true,
        mine: g['mine'] == true,
        stories: stories,
      );
    }).where((g) => g.stories.isNotEmpty).toList();
  }

  static Future<StoryMe?> me() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/stories/me', query: {'user_uid': uid});
    if (j == null || j['success'] != true) return null;
    return StoryMe(
      canPost: j['can_post'] == true,
      badge: j['badge'] == null ? null : '${j['badge']}',
      dailyLimit: int.tryParse('${j['daily_limit']}') ?? 0,
      storiesToday: int.tryParse('${j['stories_today']}') ?? 0,
      remaining: int.tryParse('${j['remaining']}') ?? 0,
      storyEnabled: j['story_enabled'] != false,
    );
  }

  static Future<StoryActionResult> create({required String kind, String text = '', int bg = 0, String imageBase64 = ''}) async {
    await BadgeService.registerUser();
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/stories/create', body: {
      'user_uid': uid,
      'kind': kind,
      'text': text,
      'bg': bg,
      if (kind == 'image') 'image_data': imageBase64,
    });
    if (j == null) return const StoryActionResult(ok: false, code: 'net');
    if (j['success'] == true) return const StoryActionResult(ok: true);
    return StoryActionResult(ok: false, code: '${j['error'] ?? ''}', message: '${j['message'] ?? ''}');
  }

  /// ثبت بازدید (هر کاربر برای هر استوری فقط یک‌بار شمرده می‌شود)
  static Future<void> view(int id) async {
    final uid = await BadgeService.userUid();
    await BadgeService.call('POST', '/api/stories/view', body: {'user_uid': uid, 'story_id': id});
  }

  /// null = خطا
  static Future<int?> like(int id, bool like) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/stories/like', body: {'user_uid': uid, 'story_id': id, 'like': like});
    if (j == null || j['success'] != true) return null;
    return int.tryParse('${j['likes']}') ?? 0;
  }

  static Future<StoryAudience?> audience(int id, {required bool likers}) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', likers ? '/api/stories/likers' : '/api/stories/viewers', query: {'user_uid': uid, 'story_id': '$id'});
    if (j == null || j['success'] != true) return null;
    final list = j['data'] is List ? j['data'] as List : const [];
    return StoryAudience(
      views: int.tryParse('${j['views']}') ?? 0,
      likes: int.tryParse('${j['likes']}') ?? 0,
      people: list
          .whereType<Map>()
          .map((x) => AudiencePerson(
                uid: '${x['uid']}',
                name: '${x['name'] ?? ''}',
                hasPhoto: x['has_photo'] == true,
                at: DateTime.tryParse('${x['at'] ?? ''}'.replaceFirst(' ', 'T') + 'Z')?.toLocal(),
                liked: x['liked'] == true,
              ))
          .toList(),
    );
  }

  /// پیام سرور (به زبان کاربر) برمی‌گرداند؛ خطای ارتباط = ''
  static Future<String> report(int id, String reason) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/stories/report', body: {'user_uid': uid, 'story_id': id, 'reason': reason});
    if (j == null) return '';
    return '${j['message'] ?? ''}';
  }

  static Future<bool> delete(int id) async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('POST', '/api/stories/delete', body: {'user_uid': uid, 'story_id': id});
    return j != null && j['success'] == true;
  }

  // ---- دیده‌شده‌ها (فقط روی همین گوشی) ----
  static const String _seenKey = 'cyrus_seen_stories_v1';

  static Future<Set<int>> seen() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_seenKey) ?? const <String>[]).map((e) => int.tryParse(e) ?? 0).toSet();
  }

  static Future<void> markSeen(int id) async {
    final p = await SharedPreferences.getInstance();
    final l = p.getStringList(_seenKey) ?? <String>[];
    if (l.contains('$id')) return;
    l.add('$id');
    if (l.length > 400) l.removeRange(0, l.length - 400);
    await p.setStringList(_seenKey, l);
  }
}

/// پس‌زمینهٔ استوری‌های متنی (اندیس bg از سرور)
const List<List<int>> kStoryGradients = [
  [0xff173246, 0xff0b5d78],
  [0xff7b2ff7, 0xfff107a3],
  [0xffff8a3d, 0xffffc233],
  [0xff0f9b8e, 0xff29e0ad],
  [0xff2a8cff, 0xff66d9ff],
  [0xff3a1c71, 0xffd76d77],
];
