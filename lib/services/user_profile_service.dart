import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
    this.visibility = 'all',
    this.videoLink = '',
  });

  final String displayName;
  final String username;
  final String bio;
  final String city;
  final String phone;
  final List<String> interests;
  final String photoBase64;

  /// چه کسانی پروفایل را می‌بینند: all (همگانی) | friends (دوستان) | none (هیچ‌کس)
  final String visibility;

  /// لینک «فیلم من در سایروس توریست» (فقط لینک cyrustourist.ir)
  final String videoLink;

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
    String? visibility,
    String? videoLink,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      photoBase64: photoBase64 ?? this.photoBase64,
      visibility: visibility ?? this.visibility,
      videoLink: videoLink ?? this.videoLink,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'username': username,
        'bio': bio,
        'city': city,
        'phone': phone,
        'interests': interests,
        'visibility': visibility,
        'videoLink': videoLink,
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
      visibility: ['all', 'friends', 'none'].contains('${j['visibility']}') ? '${j['visibility']}' : 'all',
      videoLink: '${j['videoLink'] ?? ''}',
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

  // عکس پروفایل (Base64 بزرگ) داخل فایل ذخیره می‌شود نه SharedPreferences؛
  // نوشتن رشته‌ی بزرگ در SharedPreferences روی بعضی گوشی‌ها خطا می‌داد.
  static Future<File?> _photoFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/profile_photo_v1.b64');
    } catch (_) {
      return null;
    }
  }

  static Future<String> _readPhoto(SharedPreferences? p) async {
    try {
      final f = await _photoFile();
      if (f != null && await f.exists()) {
        final t = await f.readAsString();
        if (t.isNotEmpty) return t;
      }
    } catch (_) {}
    try {
      return p?.getString(_kPhoto) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<UserProfile> _read() async {
    SharedPreferences? p;
    try {
      p = await SharedPreferences.getInstance();
    } catch (_) {}
    try {
      final raw = p?.getString(_kData);
      final photo = await _readPhoto(p);
      if (raw == null || raw.isEmpty) {
        return UserProfile(photoBase64: photo.isNotEmpty ? photo : (cached?.photoBase64 ?? ''));
      }
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
        photo,
      );
    } catch (_) {
      // خواندن حافظه خطا داد: آخرین پروفایل داخل حافظهٔ اپ، نه یک پروفایل خالی.
      return cached ?? const UserProfile();
    }
  }

  /// متن پروفایل در SharedPreferences و عکس در فایل جدا ذخیره می‌شود.
  /// فقط اگر ذخیرهٔ متن (یا عکس) کاملاً شکست بخورد false برمی‌گردد.
  static Future<bool> save(UserProfile profile) async {
    cached = profile;
    var textOk = false;
    var photoOk = true;

    for (var i = 0; i < 2 && !textOk; i++) {
      try {
        final p = await SharedPreferences.getInstance();
        textOk = await p.setString(_kData, jsonEncode(profile.toJson()));
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }

    try {
      final f = await _photoFile();
      if (profile.photoBase64.isEmpty) {
        if (f != null && await f.exists()) await f.delete();
        try {
          final p = await SharedPreferences.getInstance();
          await p.remove(_kPhoto);
        } catch (_) {}
      } else if (f != null) {
        await f.writeAsString(profile.photoBase64, flush: true);
        try {
          final p = await SharedPreferences.getInstance();
          await p.remove(_kPhoto);
        } catch (_) {}
      } else {
        final p = await SharedPreferences.getInstance();
        photoOk = await p.setString(_kPhoto, profile.photoBase64);
      }
    } catch (_) {
      photoOk = false;
    }

    changes.value++;
    return textOk && photoOk;
  }

  /// حذف کامل اطلاعات پروفایل از روی دستگاه.
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kData);
    await p.remove(_kPhoto);
    try {
      final f = await _photoFile();
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
    cached = const UserProfile();
    changes.value++;
  }
}
