import 'badge_service.dart';

class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.name,
    required this.visible,
    this.visibility = 'all',
    this.badge,
    this.username = '',
    this.city = '',
    this.bio = '',
    this.videoLink = '',
    this.photoData = '',
    this.lastSeen = '',
  });

  final String uid;
  final String name;
  final bool visible;
  final String visibility;
  final String? badge;
  final String username;
  final String city;
  final String bio;
  final String videoLink;
  final String photoData;

  /// آخرین بازدید تقریبی: recently | week | month | long (خالی = نامشخص)
  final String lastSeen;
}

class PublicProfileService {
  PublicProfileService._();

  /// null = خطای ارتباط یا کاربر پیدا نشد
  static Future<PublicProfile?> fetch(String uid) async {
    final me = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/users/profile', query: {'uid': uid, 'viewer': me});
    if (j == null || j['success'] != true) return null;
    return PublicProfile(
      uid: uid,
      name: '${j['name'] ?? 'کاربر'}',
      visible: j['visible'] == true,
      visibility: '${j['visibility'] ?? 'all'}',
      badge: j['badge'] == null ? null : '${j['badge']}',
      username: '${j['username'] ?? ''}',
      city: '${j['city'] ?? ''}',
      bio: '${j['bio'] ?? ''}',
      videoLink: '${j['video_link'] ?? ''}',
      photoData: '${j['photo_data'] ?? ''}',
      lastSeen: '${j['last_seen'] ?? ''}',
    );
  }
}
