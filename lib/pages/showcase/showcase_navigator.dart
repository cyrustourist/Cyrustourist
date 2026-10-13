import 'package:flutter/material.dart';

import '../../models/agency.dart';
import '../../models/leader.dart';
import '../../models/showcase_item.dart';
import '../../models/stay_details.dart';
import '../../services/public_link_service.dart';
import '../agencies/agency_profile_page.dart';
import '../leaders/leader_profile_page.dart';
import '../movie_video_page.dart'
    show MovieContact, MovieSlotData, MovieSocial, MovieVideoPage;
import '../residence_video_page.dart' show ResidenceVideoData, ResidenceVideoPage;
import 'showcase_detail_page.dart';
import 'stay_detail_page.dart';

const String _defaultPhone = '09153448818';
const String _defaultInstagram =
    'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
const String _defaultWebsite = 'https://cyrustourist-maker.github.io/Cyrustourist/';

/// باز کردن صفحه‌ی جزئیات مناسب هر آیتم.
///
/// - آیتم‌های محلی → همان صفحه‌های موجود (فیلم، اقامتگاه، لیدر، آژانس)
/// - آیتم‌های سرور با ویدیوی آپارات → قالب فیلم (مثل تصویر معرفی)
/// - بقیه → صفحه‌ی جزئیات عمومی
class ShowcaseNavigator {
  ShowcaseNavigator._();

  static void open(BuildContext context, ShowcaseItem item) {
    final n = item.native;
    Widget page;

    if (n is MovieSlotData) {
      page = MovieVideoPage(
        data: n,
        shareType: PublicLinkService.typeForShowcaseKind(item.kind),
      );
    } else if (n is ResidenceVideoData) {
      page = ResidenceVideoPage(data: n);
    } else if (n is Leader) {
      page = LeaderProfilePage(leader: n);
    } else if (n is Agency) {
      page = AgencyProfilePage(agency: n);
    } else if (item.kind.isVideoLike && item.aparatHash != null) {
      page = MovieVideoPage(
        data: _toMovie(item),
        shareType: PublicLinkService.typeForShowcaseKind(item.kind),
      );
    } else if ((item.kind == ShowcaseKind.accommodation ||
            item.kind == ShowcaseKind.health) &&
        item.stay != null) {
      // اقامتگاه / مرکز سلامتِ واقعی از دیتابیس → صفحه‌ی جدید با همه‌ی اطلاعات جدول
      page = StayDetailPage(item: item);
    } else if (item.kind == ShowcaseKind.accommodation &&
        item.aparatHash != null) {
      page = ResidenceVideoPage(data: _toResidence(item));
    } else {
      page = ShowcaseDetailPage(item: item);
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  static String? _v(Map<String, String> m, String k) {
    final s = m[k];
    return (s == null || s.isEmpty) ? null : s;
  }

  static MovieSlotData _toMovie(ShowcaseItem i) {
    final phone = i.phone ?? _defaultPhone;

    // امکانات تیک‌خورده در پنل مدیریت (ستون amenities / amenity_labels همان ردیف سرور)
    final raw = i.native;
    var amenityKeys = <String>[];
    var amenityLabels = <String, String>{};
    var bedrooms = 0;
    if (raw is Map) {
      final row = Map<String, dynamic>.from(raw);
      final all = StayDetails.parseAmenities(row['amenities_list'] ?? row['amenities']);
      for (final a in all) {
        if (a.startsWith('bedrooms:')) {
          bedrooms = int.tryParse(a.substring(9)) ?? bedrooms;
        } else {
          amenityKeys.add(a);
        }
      }
      amenityLabels = StayDetails.parseAmenityLabels(row['amenity_labels']);
    }

    // داده‌های کامل ورکر (فقط برای ردیف‌های سرور)
    final phones = <MovieContact>[];
    final socials = <MovieSocial>[];
    String? navUrl;
    String? mStatus, mLabel;
    int? mDays;
    if (raw is Map) {
      final row = Map<String, dynamic>.from(raw);
      final ph = row['phones'];
      if (ph is List) {
        for (final e in ph) {
          if (e is Map) {
            final n = '${e['number'] ?? ''}'.trim();
            if (n.isNotEmpty) phones.add(MovieContact('${e['label'] ?? ''}', n));
          }
        }
      }
      final sl = row['social_links'];
      if (sl is List) {
        for (final e in sl) {
          if (e is Map) {
            final u = '${e['url'] ?? ''}'.trim();
            if (u.isNotEmpty) {
              socials.add(MovieSocial('${e['type'] ?? ''}', '${e['label'] ?? ''}', u));
            }
          }
        }
      }
      final nu = '${row['navigation_url'] ?? ''}'.trim();
      if (nu.isNotEmpty) navUrl = nu;
      final ms = '${row['membership_status'] ?? ''}'.trim();
      if (ms.isNotEmpty) mStatus = ms;
      mLabel = '${row['membership_label'] ?? ''}'.trim();
      mDays = int.tryParse('${row['membership_days_left']}');
    }

    return MovieSlotData(
      phones: phones,
      socialLinks: socials,
      navigationUrl: navUrl,
      membershipStatus: mStatus,
      membershipLabel: mLabel,
      membershipDaysLeft: mDays,
      code: i.code,
      assigned: true,
      name: _v(i.titles, 'fa') ?? i.title('fa'),
      nameEn: _v(i.titles, 'en'),
      nameAr: _v(i.titles, 'ar'),
      city: _v(i.locations, 'fa') ?? i.location('fa'),
      cityEn: _v(i.locations, 'en'),
      cityAr: _v(i.locations, 'ar'),
      category: _v(i.categoryLabels, 'fa') ?? i.categoryLabel('fa'),
      categoryEn: _v(i.categoryLabels, 'en'),
      categoryAr: _v(i.categoryLabels, 'ar'),
      description: _v(i.descriptions, 'fa'),
      descriptionEn: _v(i.descriptions, 'en'),
      descriptionAr: _v(i.descriptions, 'ar'),
      aparatUrl: i.videoUrl,
      latitude: i.latitude,
      longitude: i.longitude,
      mobilePhone: phone,
      landlinePhone: phone,
      supportPhone: phone,
      instagramUrl: i.instagramUrl ?? _defaultInstagram,
      websiteUrl: i.websiteUrl ?? _defaultWebsite,
      bedroomCount: bedrooms > 0 ? bedrooms : null,
      panelAmenityKeys: amenityKeys,
      panelAmenityLabels: amenityLabels,
    );
  }

  static ResidenceVideoData _toResidence(ShowcaseItem i) {
    return ResidenceVideoData(
      code: i.code,
      assigned: true,
      name: _v(i.titles, 'fa') ?? i.title('fa'),
      nameEn: _v(i.titles, 'en'),
      nameAr: _v(i.titles, 'ar'),
      city: _v(i.locations, 'fa') ?? i.location('fa'),
      cityEn: _v(i.locations, 'en'),
      cityAr: _v(i.locations, 'ar'),
      description: _v(i.descriptions, 'fa'),
      descriptionEn: _v(i.descriptions, 'en'),
      descriptionAr: _v(i.descriptions, 'ar'),
      aparatHash: i.aparatHash,
      mobilePhone: i.phone,
      supportPhone: i.phone,
      landlinePhone: i.phone,
      instagramUrl: i.instagramUrl,
      websiteUrl: i.websiteUrl,
      latitude: i.latitude,
      longitude: i.longitude,
      rating: i.rating,
      ratingCount: i.ratingCount,
    );
  }
}
