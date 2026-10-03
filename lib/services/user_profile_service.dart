import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// پروفایل کاربر — فعلاً کاملاً روی خود گوشی ذخیره می‌شود (بدون سرور).
/// عکس پروفایل پیش از ذخیره توسط image_picker فشرده می‌شود
/// (حداکثر ۵۱۲×۵۱۲ و کیفیت ۷۰) و به‌صورت Base64 نگه‌داری می‌شود.
class UserProfile {
  const UserProfile({
    this.displayName = '',
    this.username = '',
    this.bio = '',
    this.city = '',
    this.phone = '',
    this.interests = const [],
    this.photoBase64 = '',
  });

  final String displayName;
  final String username;
  final String bio;
  final String city;
  final String phone;
  final List<String> interests;
  final String photoBase64;

  bool get isEmpty =>
      displayName.isEmpty &&
      username.isEmpty &&
      bio.isEmpty &&
      city.isEmpty &&
      phone.isEmpty &&
      interests.isEmpty &&
      photoBase64.isEmpty;

  Uint8List? get photoBytes {
    if (photoBase64.isEmpty) return null;
    try {
      return base64Decode(photoBase64);
    } catch (_) {
      return null;
    }
  }

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? city,
    String? phone,
    List<String>? interests,
    String? photoBase64,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'username': username,
        'bio': bio,
        'city': city,
        'phone': phone,
        'interests': interests,
      };

  static UserProfile fromJson(Map<String, dynamic> j, String photo) {
    return UserProfile(
      displayName: '${j['displayName'] ?? ''}',
      username: '${j['username'] ?? ''}',
      bio: '${j['bio'] ?? ''}',
      city: '${j['city'] ?? ''}',
      phone: '${j['phone'] ?? ''}',
      interests: (j['interests'] is List)
          ? (j['interests'] as List).map((e) => '$e').toList()
          : const [],
      photoBase64: photo,
    );
  }
}

class UserProfileService {
  UserProfileService._();

  /// با هر ذخیره/حذف یک واحد زیاد می‌شود تا هدر حساب کاربری خودش را به‌روز کند.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static const String _kData = 'user_profile_v1';
  static const String _kPhoto = 'user_profile_photo_v1';

  /// آخرین پروفایل خوانده‌شده؛ برای نمایش فوری در منوی هدر.
  static UserProfile? cached;

  static Future<UserProfile> load() async {
    final loaded = await _read();
    cached = loaded;
    return loaded;
  }

  static Future<UserProfile> _read() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kData);
      final photo = p.getString(_kPhoto) ?? '';
      if (raw == null || raw.isEmpty) return UserProfile(photoBase64: photo);
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
        photo,
      );
    } catch (_) {
      return const UserProfile();
    }
  }

  static Future<void> save(UserProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kData, jsonEncode(profile.toJson()));
    if (profile.photoBase64.isEmpty) {
      await p.remove(_kPhoto);
    } else {
      await p.setString(_kPhoto, profile.photoBase64);
    }
    cached = profile;
    changes.value++;
  }

  /// حذف کامل اطلاعات پروفایل از روی دستگاه.
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kData);
    await p.remove(_kPhoto);
    cached = const UserProfile();
    changes.value++;
  }
}
