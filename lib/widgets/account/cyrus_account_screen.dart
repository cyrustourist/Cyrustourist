import 'package:flutter/material.dart';

import '../../pages/announcements_page.dart';
import '../../pages/residence_register_page.dart';
import '../../services/notification_service.dart';

/// کلید شماره ۸ — حساب کاربری سایروس توریست
///
/// این فایل به‌صورت مستقل طراحی شده است و فعلاً به main.dart
/// یا سایر فایل‌های پروژه متصل نمی‌شود.
///
/// ساختار حساب کاربری برای توسعه آینده، از جمله چت آنلاین،
/// گروه‌های گردشگری و همسفریابی نیز در نظر گرفته شده است.
class CyrusAccountScreen extends StatelessWidget {
  const CyrusAccountScreen({
    super.key,
    this.languageCode = 'fa',
  });

  final String languageCode;

  bool get _isRtl =>
      languageCode == 'fa' ||
      languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final texts = _AccountTranslations.get(languageCode);

    return Directionality(
      textDirection: _isRtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff071722),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xffffd36a),
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          title: Text(
            texts.title,
            style: const TextStyle(
              color: Color(0xffffd36a),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              28,
            ),
            child: Column(
              children: [
                _buildProfileHeader(texts),
                const SizedBox(height: 22),

                _buildSection(
                  context,
                  title: texts.accountSection,
                  items: [
                    _AccountItem(
                      icon: Icons.notifications_active_rounded,
                      title: texts.announcements,
                      subtitle: texts.announcementsSubtitle,
                      iconColor: const Color(0xffffd36a),
                      actionId: 'announcements',
                      showNotificationBadge: true,
                    ),
                    _AccountItem(
                      icon: Icons.person_rounded,
                      title: texts.profile,
                      subtitle: texts.profileSubtitle,
                      iconColor: const Color(0xffffd36a),
                    ),
                    _AccountItem(
                      icon: Icons.edit_rounded,
                      title: texts.editProfile,
                      subtitle: texts.editProfileSubtitle,
                      iconColor: const Color(0xff66d9ff),
                    ),
                    _AccountItem(
                      icon: Icons.photo_camera_rounded,
                      title: texts.profileImage,
                      subtitle: texts.profileImageSubtitle,
                      iconColor: const Color(0xffc89cff),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildSection(
                  context,
                  title: texts.registrationSection,
                  items: [
                    _AccountItem(
                      icon: Icons.hotel_rounded,
                      title: texts.accommodationRegistration,
                      subtitle:
                          texts.accommodationRegistrationSubtitle,
                      iconColor: const Color(0xffffb84d),
                      actionId: 'registration',
                    ),
                    _AccountItem(
                      icon: Icons.local_hospital_rounded,
                      title: texts.healthTourismRegistration,
                      subtitle:
                          texts.healthTourismRegistrationSubtitle,
                      iconColor: const Color(0xff66e6a5),
                      actionId: 'registration',
                    ),
                    _AccountItem(
                      icon: Icons.cottage_rounded,
                      title: texts.cabinRegistration,
                      subtitle:
                          texts.cabinRegistrationSubtitle,
                      iconColor: const Color(0xffffd36a),
                      actionId: 'registration',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildSection(
                  context,
                  title: texts.activitySection,
                  items: [
                    _AccountItem(
                      icon: Icons.star_rounded,
                      title: texts.myReviews,
                      subtitle: texts.myReviewsSubtitle,
                      iconColor: const Color(0xffffd36a),
                    ),
                    _AccountItem(
                      icon: Icons.analytics_rounded,
                      title: texts.travelStats,
                      subtitle: texts.travelStatsSubtitle,
                      iconColor: const Color(0xff66d9ff),
                    ),
                    _AccountItem(
                      icon: Icons.emoji_events_rounded,
                      title: texts.achievements,
                      subtitle: texts.achievementsSubtitle,
                      iconColor: const Color(0xffffc857),
                    ),
                    _AccountItem(
                      icon: Icons.card_giftcard_rounded,
                      title: texts.rewards,
                      subtitle: texts.rewardsSubtitle,
                      iconColor: const Color(0xffff8fc7),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildSection(
                  context,
                  title: texts.securitySection,
                  items: [
                    _AccountItem(
                      icon: Icons.lock_rounded,
                      title: texts.security,
                      subtitle: texts.securitySubtitle,
                      iconColor: const Color(0xff8fc7ff),
                    ),
                    _AccountItem(
                      icon: Icons.devices_rounded,
                      title: texts.devices,
                      subtitle: texts.devicesSubtitle,
                      iconColor: const Color(0xffa9e6c4),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildSection(
                  context,
                  title: texts.futureSection,
                  items: [
                    _AccountItem(
                      icon: Icons.chat_bubble_rounded,
                      title: texts.onlineChat,
                      subtitle: texts.futureSubtitle,
                      iconColor: const Color(0xff65d9ff),
                      futureFeature: true,
                    ),
                    _AccountItem(
                      icon: Icons.groups_rounded,
                      title: texts.createTravelGroup,
                      subtitle: texts.futureSubtitle,
                      iconColor: const Color(0xffffd36a),
                      futureFeature: true,
                    ),
                    _AccountItem(
                      icon: Icons.public_rounded,
                      title: texts.joinTravelGroups,
                      subtitle: texts.futureSubtitle,
                      iconColor: const Color(0xff8fd8a8),
                      futureFeature: true,
                    ),
                    _AccountItem(
                      icon: Icons.handshake_rounded,
                      title: texts.travelCompanion,
                      subtitle: texts.futureSubtitle,
                      iconColor: const Color(0xffffa56b),
                      futureFeature: true,
                    ),
                    _AccountItem(
                      icon: Icons.forum_rounded,
                      title: texts.destinationRoom,
                      subtitle: texts.futureSubtitle,
                      iconColor: const Color(0xffb995ff),
                      futureFeature: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildLogoutButton(
                  context,
                  texts,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    _AccountTranslations texts,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff132d3a),
            Color(0xff0a1d29),
          ],
        ),
        border: Border.all(
          color: const Color(0xffffd36a).withOpacity(0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffd36a).withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff102733),
              border: Border.all(
                color: const Color(0xffffd36a),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffffd36a).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: Color(0xffffd36a),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts.account,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  texts.accountSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffffd36a).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    texts.usernamePlaceholder,
                    style: const TextStyle(
                      color: Color(0xffffd36a),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_AccountItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 5,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xffffd36a),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: item.showNotificationBadge
                ? _AccountBadgeButton(
                    item: item,
                    languageCode: languageCode,
                  )
                : CyrusAccountButton(
                    item: item,
                    onTap: () {
                      _handleAccountItem(context, item);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    _AccountTranslations texts,
  ) {
    return CyrusAccountButton(
      item: _AccountItem(
        icon: Icons.logout_rounded,
        title: texts.logout,
        subtitle: texts.logoutSubtitle,
        iconColor: const Color(0xffff7070),
        logout: true,
      ),
      onTap: () {
        _handleLogout(context, texts);
      },
    );
  }

  void _handleAccountItem(
    BuildContext context,
    _AccountItem item,
  ) {
    if (item.futureFeature) {
      _showFutureMessage(context);
      return;
    }

    // نکته: گزینه‌ی «اعلان‌ها» (بج‌دار) ناوبری خودش را مستقل در
    // _AccountBadgeButton انجام می‌دهد تا بتواند بعد از بازگشت
    // کاربر، شمارنده‌ی بج را دوباره بخواند؛ به همین دلیل اینجا
    // نیازی به مسیردهی جداگانه برای آن نیست.

    // هر سه گزینه‌ی ثبت‌نام (اقامتگاه، گردشگری سلامت، کلبه) فعلاً
    // به همان یک فایل ثبت‌نام آماده و موجود وصل می‌شوند:
    // residence_register_page.dart (همان کلیدی که بالای «نمایش
    // فیلم‌ها»، کلید ۴، قرار دارد). بقیه‌ی گزینه‌های حساب کاربری
    // در مرحله نهایی اتصال کلید ۸ انجام خواهد شد.
    if (item.actionId == 'registration') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ResidenceRegisterPage(),
        ),
      );
      return;
    }
  }

  void _handleLogout(
    BuildContext context,
    _AccountTranslations texts,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff102733),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            texts.logoutConfirmTitle,
            style: const TextStyle(
              color: Color(0xffffd36a),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            texts.logoutConfirmMessage,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                texts.cancel,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff9f3030),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // در مرحله اتصال نهایی:
                // 1. عکس پروفایل محلی حذف می‌شود.
                // 2. اطلاعات محلی حساب پاک می‌شود.
                // 3. نشست ورود حذف می‌شود.
                // 4. کاربر به صفحه ورود برمی‌گردد.
              },
              child: Text(texts.logout),
            ),
          ],
        );
      },
    );
  }

  void _showFutureMessage(BuildContext context) {
    final texts = _AccountTranslations.get(languageCode);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff102733),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xffffd36a),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texts.futureTitle,
                  style: const TextStyle(
                    color: Color(0xffffd36a),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            texts.futureMessage,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                texts.ok,
                style: const TextStyle(
                  color: Color(0xffffd36a),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// مدل داخلی هر گزینه حساب کاربری.
class _AccountItem {
  const _AccountItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.futureFeature = false,
    this.logout = false,
    this.actionId,
    this.showNotificationBadge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool futureFeature;
  final bool logout;

  /// شناسه‌ی داخلی برای مسیردهی در `_handleAccountItem`
  /// (مثلاً 'registration' برای هر سه گزینه‌ی ثبت‌نام،
  /// یا 'announcements' برای گزینه‌ی اعلان‌ها).
  final String? actionId;

  /// اگر true باشد، تعداد اعلان‌های خوانده‌نشده به‌صورت بج قرمز
  /// روی آیکون این گزینه نمایش داده می‌شود.
  final bool showNotificationBadge;
}

/// نسخه‌ی بج‌دار دکمه‌ی حساب کاربری، مخصوص گزینه‌ی «اعلان‌ها».
///
/// تعداد اعلان‌های خوانده‌نشده را از [NotificationService] می‌گیرد
/// و به‌صورت یک بج قرمز کوچک روی گوشه‌ی آیکون زنگوله نشان می‌دهد.
class _AccountBadgeButton extends StatefulWidget {
  const _AccountBadgeButton({
    required this.item,
    required this.languageCode,
  });

  final _AccountItem item;
  final String languageCode;

  @override
  State<_AccountBadgeButton> createState() => _AccountBadgeButtonState();
}

class _AccountBadgeButtonState extends State<_AccountBadgeButton> {
  late Future<int> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = NotificationService.instance.getUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final future = NotificationService.instance.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadFuture = future;
      });
    }
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CyrusAccountButton(
          item: widget.item,
          onTap: () async {
            // صفحه‌ی اعلان‌ها را باز می‌کنیم و منتظر بازگشت کاربر می‌مانیم؛
            // چون خودِ آن صفحه هنگام باز شدن، اعلان‌ها را «خوانده‌شده»
            // علامت می‌زند، بعد از بازگشت باید بج را دوباره بخوانیم.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnnouncementsPage(
                  languageCode: widget.languageCode,
                ),
              ),
            );
            await _refreshUnreadCount();
          },
        ),
        Positioned(
          left: 8,
          top: 6,
          child: FutureBuilder<int>(
            future: _unreadFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              if (count <= 0) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minWidth: 20),
                decoration: BoxDecoration(
                  color: const Color(0xffe0353d),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff071722),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// دکمه سه‌بعدی حساب کاربری با سایه طلایی.
class CyrusAccountButton extends StatefulWidget {
  const CyrusAccountButton({
    super.key,
    required this.item,
    required this.onTap,
  });

  final _AccountItem item;
  final VoidCallback onTap;

  @override
  State<CyrusAccountButton> createState() =>
      _CyrusAccountButtonState();
}

class _CyrusAccountButtonState
    extends State<CyrusAccountButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(
        0,
        _pressed ? 3 : 0,
        0,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 76,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.logout
                  ? const [
                      Color(0xff2a171b),
                      Color(0xff171016),
                    ]
                  : const [
                      Color(0xff132b37),
                      Color(0xff0b1d28),
                    ],
            ),
            border: Border.all(
              color: item.logout
                  ? const Color(0xffff7070).withOpacity(0.55)
                  : const Color(0xffffd36a).withOpacity(0.28),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: item.logout
                    ? const Color(0xffff7070).withOpacity(0.10)
                    : const Color(0xffffd36a).withOpacity(0.10),
                blurRadius: _pressed ? 7 : 14,
                offset: Offset(
                  0,
                  _pressed ? 3 : 7,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: item.iconColor.withOpacity(0.12),
                  border: Border.all(
                    color: item.iconColor.withOpacity(0.30),
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.logout
                                  ? const Color(0xffff8b8b)
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (item.futureFeature) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffffd36a)
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'آینده',
                              style: TextStyle(
                                color: Color(0xffffd36a),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: item.logout
                    ? const Color(0xffff7070)
                    : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ترجمه کامل ۱۰ زبان کلید حساب کاربری.
class _AccountTranslations {
  const _AccountTranslations({
    required this.title,
    required this.account,
    required this.accountSubtitle,
    required this.usernamePlaceholder,
    required this.accountSection,
    required this.announcements,
    required this.announcementsSubtitle,
    required this.profile,
    required this.profileSubtitle,
    required this.editProfile,
    required this.editProfileSubtitle,
    required this.profileImage,
    required this.profileImageSubtitle,
    required this.registrationSection,
    required this.accommodationRegistration,
    required this.accommodationRegistrationSubtitle,
    required this.healthTourismRegistration,
    required this.healthTourismRegistrationSubtitle,
    required this.cabinRegistration,
    required this.cabinRegistrationSubtitle,
    required this.activitySection,
    required this.myReviews,
    required this.myReviewsSubtitle,
    required this.travelStats,
    required this.travelStatsSubtitle,
    required this.achievements,
    required this.achievementsSubtitle,
    required this.rewards,
    required this.rewardsSubtitle,
    required this.securitySection,
    required this.security,
    required this.securitySubtitle,
    required this.devices,
    required this.devicesSubtitle,
    required this.futureSection,
    required this.onlineChat,
    required this.createTravelGroup,
    required this.joinTravelGroups,
    required this.travelCompanion,
    required this.destinationRoom,
    required this.futureSubtitle,
    required this.logout,
    required this.logoutSubtitle,
    required this.logoutConfirmTitle,
    required this.logoutConfirmMessage,
    required this.cancel,
    required this.ok,
    required this.futureTitle,
    required this.futureMessage,
  });

  final String title;
  final String account;
  final String accountSubtitle;
  final String usernamePlaceholder;
  final String accountSection;
  final String announcements;
  final String announcementsSubtitle;
  final String profile;
  final String profileSubtitle;
  final String editProfile;
  final String editProfileSubtitle;
  final String profileImage;
  final String profileImageSubtitle;
  final String registrationSection;
  final String accommodationRegistration;
  final String accommodationRegistrationSubtitle;
  final String healthTourismRegistration;
  final String healthTourismRegistrationSubtitle;
  final String cabinRegistration;
  final String cabinRegistrationSubtitle;
  final String activitySection;
  final String myReviews;
  final String myReviewsSubtitle;
  final String travelStats;
  final String travelStatsSubtitle;
  final String achievements;
  final String achievementsSubtitle;
  final String rewards;
  final String rewardsSubtitle;
  final String securitySection;
  final String security;
  final String securitySubtitle;
  final String devices;
  final String devicesSubtitle;
  final String futureSection;
  final String onlineChat;
  final String createTravelGroup;
  final String joinTravelGroups;
  final String travelCompanion;
  final String destinationRoom;
  final String futureSubtitle;
  final String logout;
  final String logoutSubtitle;
  final String logoutConfirmTitle;
  final String logoutConfirmMessage;
  final String cancel;
  final String ok;
  final String futureTitle;
  final String futureMessage;

  static _AccountTranslations get(String languageCode) {
    switch (languageCode) {
      case 'en':
        return _en;
      case 'ar':
        return _ar;
      case 'tr':
        return _tr;
      case 'ru':
        return _ru;
      case 'fr':
        return _fr;
      case 'de':
        return _de;
      case 'es':
        return _es;
      case 'zh':
        return _zh;
      case 'it':
        return _it;
      case 'fa':
      default:
        return _fa;
    }
  }

  static const _fa = _AccountTranslations(
    title: 'حساب کاربری',
    account: 'حساب کاربری من',
    accountSubtitle: 'مدیریت اطلاعات و امکانات حساب شما',
    usernamePlaceholder: 'نام کاربری هنوز ثبت نشده',
    accountSection: 'اطلاعات حساب',
    announcements: 'آگهی‌ها',
    announcementsSubtitle: 'مشاهده آخرین اطلاعیه‌ها و بروزرسانی‌ها',
    profile: 'پروفایل من',
    profileSubtitle: 'مشاهده اطلاعات حساب کاربری',
    editProfile: 'ویرایش اطلاعات',
    editProfileSubtitle: 'ویرایش نام کاربری و اطلاعات حساب',
    profileImage: 'تصویر پروفایل',
    profileImageSubtitle: 'انتخاب و مدیریت تصویر پروفایل',
    registrationSection: 'ثبت‌نام خدمات گردشگری',
    accommodationRegistration: 'ثبت‌نام اقامتگاه',
    accommodationRegistrationSubtitle:
        'ثبت اقامتگاه و معرفی آن به گردشگران',
    healthTourismRegistration: 'ثبت‌نام گردشگری سلامت',
    healthTourismRegistrationSubtitle:
        'ثبت خدمات و مراکز گردشگری سلامت',
    cabinRegistration: 'ثبت‌نام کلبه',
    cabinRegistrationSubtitle:
        'ثبت کلبه و اقامتگاه اختصاصی',
    activitySection: 'فعالیت و امتیازات',
    myReviews: 'امتیازها و نظرات من',
    myReviewsSubtitle: 'مدیریت امتیازها و نظرات ثبت‌شده',
    travelStats: 'آمار و عملکرد سفر من',
    travelStatsSubtitle:
        'مشاهده آمار سفرها و فعالیت‌های گردشگری',
    achievements: 'دستاوردهای سفر',
    achievementsSubtitle:
        'دستاوردها و نشان‌های گردشگری شما',
    rewards: 'امتیازات و جوایز',
    rewardsSubtitle:
        'مشاهده امتیازات و پاداش‌های حساب',
    securitySection: 'امنیت حساب',
    security: 'امنیت حساب',
    securitySubtitle:
        'مدیریت امنیت و تنظیمات ورود',
    devices: 'دستگاه‌های متصل',
    devicesSubtitle:
        'مدیریت دستگاه‌هایی که با حساب شما وارد شده‌اند',
    futureSection: 'قابلیت‌های آینده',
    onlineChat: 'چت آنلاین',
    createTravelGroup: 'ایجاد گروه گردشگری',
    joinTravelGroups: 'پیوستن به گروه‌های گردشگری',
    travelCompanion: 'همسفریابی',
    destinationRoom: 'اتاق گفت‌وگوی مقصد',
    futureSubtitle: 'در بروزرسانی آینده فعال خواهد شد',
    logout: 'خروج از حساب کاربری',
    logoutSubtitle:
        'خروج و پاک‌سازی اطلاعات حساب از دستگاه',
    logoutConfirmTitle: 'خروج از حساب',
    logoutConfirmMessage:
        'با خروج از حساب، اطلاعات محلی حساب و تصویر پروفایل از این دستگاه پاک خواهد شد.',
    cancel: 'انصراف',
    ok: 'متوجه شدم',
    futureTitle: 'این قابلیت در راه است',
    futureMessage:
        'این قابلیت در بروزرسانی‌های آینده سایروس توریست ارائه خواهد شد. زیرساخت حساب کاربری از ابتدا برای پشتیبانی از ارتباطات اجتماعی و گردشگری آینده طراحی شده است.',
  );

  static const _en = _AccountTranslations(
    title: 'Account',
    account: 'My Account',
    accountSubtitle: 'Manage your account and travel features',
    usernamePlaceholder: 'Username not set yet',
    accountSection: 'Account Information',
    announcements: 'Announcements',
    announcementsSubtitle: 'View the latest news and updates',
    profile: 'My Profile',
    profileSubtitle: 'View your account information',
    editProfile: 'Edit Information',
    editProfileSubtitle: 'Edit username and account information',
    profileImage: 'Profile Picture',
    profileImageSubtitle: 'Choose and manage your profile picture',
    registrationSection: 'Tourism Registration',
    accommodationRegistration: 'Accommodation Registration',
    accommodationRegistrationSubtitle:
        'Register and introduce your accommodation',
    healthTourismRegistration: 'Health Tourism Registration',
    healthTourismRegistrationSubtitle:
        'Register health tourism services and centers',
    cabinRegistration: 'Cabin Registration',
    cabinRegistrationSubtitle:
        'Register your cabin or private stay',
    activitySection: 'Activity & Rewards',
    myReviews: 'My Ratings & Reviews',
    myReviewsSubtitle: 'Manage your ratings and reviews',
    travelStats: 'My Travel Statistics',
    travelStatsSubtitle: 'View your travel and tourism activity',
    achievements: 'Travel Achievements',
    achievementsSubtitle: 'Your tourism achievements and badges',
    rewards: 'Points & Rewards',
    rewardsSubtitle: 'View your account points and rewards',
    securitySection: 'Account Security',
    security: 'Account Security',
    securitySubtitle: 'Manage security and login settings',
    devices: 'Connected Devices',
    devicesSubtitle: 'Manage devices connected to your account',
    futureSection: 'Future Features',
    onlineChat: 'Online Chat',
    createTravelGroup: 'Create Travel Group',
    joinTravelGroups: 'Join Travel Groups',
    travelCompanion: 'Travel Companion Finder',
    destinationRoom: 'Destination Discussion Room',
    futureSubtitle: 'Available in a future update',
    logout: 'Log Out',
    logoutSubtitle: 'Sign out and clear account data from this device',
    logoutConfirmTitle: 'Log Out',
    logoutConfirmMessage:
        'Logging out will remove local account information and the profile picture from this device.',
    cancel: 'Cancel',
    ok: 'OK',
    futureTitle: 'Coming in a Future Update',
    futureMessage:
        'This feature will be introduced in a future Cyrus Tourist update. The account architecture is being prepared to support future social and tourism communication features.',
  );

  static const _ar = _AccountTranslations(
    title: 'الحساب',
    account: 'حسابي',
    accountSubtitle: 'إدارة الحساب وميزات السفر',
    usernamePlaceholder: 'اسم المستخدم غير مسجل بعد',
    accountSection: 'معلومات الحساب',
    announcements: 'الإشعارات',
    announcementsSubtitle: 'عرض آخر الأخبار والتحديثات',
    profile: 'ملفي الشخصي',
    profileSubtitle: 'عرض معلومات الحساب',
    editProfile: 'تعديل المعلومات',
    editProfileSubtitle: 'تعديل اسم المستخدم ومعلومات الحساب',
    profileImage: 'صورة الملف الشخصي',
    profileImageSubtitle: 'اختيار وإدارة صورة الملف الشخصي',
    registrationSection: 'تسجيل الخدمات السياحية',
    accommodationRegistration: 'تسجيل مكان الإقامة',
    accommodationRegistrationSubtitle:
        'تسجيل مكان الإقامة وعرضه للسياح',
    healthTourismRegistration: 'تسجيل السياحة العلاجية',
    healthTourismRegistrationSubtitle:
        'تسجيل خدمات ومراكز السياحة العلاجية',
    cabinRegistration: 'تسجيل الكوخ',
    cabinRegistrationSubtitle: 'تسجيل الكوخ أو مكان الإقامة الخاص',
    activitySection: 'النشاط والمكافآت',
    myReviews: 'تقييماتي وآرائي',
    myReviewsSubtitle: 'إدارة التقييمات والآراء',
    travelStats: 'إحصاءات رحلاتي',
    travelStatsSubtitle: 'عرض إحصاءات السفر والنشاط السياحي',
    achievements: 'إنجازات السفر',
    achievementsSubtitle: 'إنجازات وشاراتك السياحية',
    rewards: 'النقاط والمكافآت',
    rewardsSubtitle: 'عرض نقاط ومكافآت الحساب',
    securitySection: 'أمان الحساب',
    security: 'أمان الحساب',
    securitySubtitle: 'إدارة الأمان وإعدادات الدخول',
    devices: 'الأجهزة المتصلة',
    devicesSubtitle: 'إدارة الأجهزة المتصلة بالحساب',
    futureSection: 'ميزات مستقبلية',
    onlineChat: 'الدردشة عبر الإنترنت',
    createTravelGroup: 'إنشاء مجموعة سياحية',
    joinTravelGroups: 'الانضمام إلى مجموعات سياحية',
    travelCompanion: 'البحث عن رفيق سفر',
    destinationRoom: 'غرفة نقاش الوجهة',
    futureSubtitle: 'ستتوفر في تحديث مستقبلي',
    logout: 'تسجيل الخروج',
    logoutSubtitle: 'تسجيل الخروج وحذف بيانات الحساب من الجهاز',
    logoutConfirmTitle: 'تسجيل الخروج',
    logoutConfirmMessage:
        'سيؤدي تسجيل الخروج إلى حذف بيانات الحساب المحلية وصورة الملف الشخصي من هذا الجهاز.',
    cancel: 'إلغاء',
    ok: 'حسنًا',
    futureTitle: 'هذه الميزة قادمة',
    futureMessage:
        'ستتوفر هذه الميزة في تحديثات سايروس توريست المستقبلية.',
  );

  static const _tr = _AccountTranslations(
    title: 'Hesap',
    account: 'Hesabım',
    accountSubtitle: 'Hesabınızı ve seyahat özelliklerinizi yönetin',
    usernamePlaceholder: 'Kullanıcı adı henüz ayarlanmadı',
    accountSection: 'Hesap Bilgileri',
    announcements: 'Duyurular',
    announcementsSubtitle: 'Son haberleri ve güncellemeleri görün',
    profile: 'Profilim',
    profileSubtitle: 'Hesap bilgilerinizi görüntüleyin',
    editProfile: 'Bilgileri Düzenle',
    editProfileSubtitle: 'Kullanıcı adı ve hesap bilgilerini düzenle',
    profileImage: 'Profil Fotoğrafı',
    profileImageSubtitle: 'Profil fotoğrafını seç ve yönet',
    registrationSection: 'Turizm Kayıtları',
    accommodationRegistration: 'Konaklama Kaydı',
    accommodationRegistrationSubtitle:
        'Konaklama yerinizi kaydedin',
    healthTourismRegistration: 'Sağlık Turizmi Kaydı',
    healthTourismRegistrationSubtitle:
        'Sağlık turizmi hizmetlerini kaydedin',
    cabinRegistration: 'Kulübe Kaydı',
    cabinRegistrationSubtitle:
        'Kulübenizi veya özel konaklamanızı kaydedin',
    activitySection: 'Aktivite ve Ödüller',
    myReviews: 'Puanlarım ve Yorumlarım',
    myReviewsSubtitle: 'Puan ve yorumlarınızı yönetin',
    travelStats: 'Seyahat İstatistiklerim',
    travelStatsSubtitle: 'Seyahat ve turizm aktivitelerinizi görün',
    achievements: 'Seyahat Başarıları',
    achievementsSubtitle: 'Turizm başarılarınız ve rozetleriniz',
    rewards: 'Puanlar ve Ödüller',
    rewardsSubtitle: 'Hesap puanlarınızı ve ödüllerinizi görün',
    securitySection: 'Hesap Güvenliği',
    security: 'Hesap Güvenliği',
    securitySubtitle: 'Güvenlik ve giriş ayarlarını yönetin',
    devices: 'Bağlı Cihazlar',
    devicesSubtitle: 'Hesabınıza bağlı cihazları yönetin',
    futureSection: 'Gelecek Özellikler',
    onlineChat: 'Çevrimiçi Sohbet',
    createTravelGroup: 'Tur Grubu Oluştur',
    joinTravelGroups: 'Tur Gruplarına Katıl',
    travelCompanion: 'Seyahat Arkadaşı Bul',
    destinationRoom: 'Destinasyon Sohbet Odası',
    futureSubtitle: 'Gelecek bir güncellemede kullanılabilir',
    logout: 'Çıkış Yap',
    logoutSubtitle: 'Çıkış yap ve cihazdaki hesap verilerini temizle',
    logoutConfirmTitle: 'Çıkış Yap',
    logoutConfirmMessage:
        'Çıkış yapmak yerel hesap bilgilerini ve profil fotoğrafını bu cihazdan kaldırır.',
    cancel: 'İptal',
    ok: 'Tamam',
    futureTitle: 'Gelecek Güncellemede',
    futureMessage:
        'Bu özellik gelecekteki Cyrus Tourist güncellemelerinde sunulacaktır.',
  );

  static const _ru = _AccountTranslations(
    title: 'Аккаунт',
    account: 'Мой аккаунт',
    accountSubtitle: 'Управление аккаунтом и функциями путешествий',
    usernamePlaceholder: 'Имя пользователя не задано',
    accountSection: 'Информация аккаунта',
    announcements: 'Объявления',
    announcementsSubtitle: 'Смотреть последние новости и обновления',
    profile: 'Мой профиль',
    profileSubtitle: 'Просмотр данных аккаунта',
    editProfile: 'Редактировать данные',
    editProfileSubtitle: 'Изменить имя пользователя и данные',
    profileImage: 'Фото профиля',
    profileImageSubtitle: 'Выбор и управление фото профиля',
    registrationSection: 'Регистрация туристических услуг',
    accommodationRegistration: 'Регистрация размещения',
    accommodationRegistrationSubtitle: 'Регистрация объекта размещения',
    healthTourismRegistration: 'Регистрация медицинского туризма',
    healthTourismRegistrationSubtitle: 'Регистрация услуг медтуризма',
    cabinRegistration: 'Регистрация коттеджа',
    cabinRegistrationSubtitle: 'Регистрация коттеджа или жилья',
    activitySection: 'Активность и награды',
    myReviews: 'Мои оценки и отзывы',
    myReviewsSubtitle: 'Управление оценками и отзывами',
    travelStats: 'Статистика моих путешествий',
    travelStatsSubtitle: 'Статистика путешествий и активности',
    achievements: 'Достижения путешествий',
    achievementsSubtitle: 'Ваши достижения и значки',
    rewards: 'Баллы и награды',
    rewardsSubtitle: 'Баллы и награды аккаунта',
    securitySection: 'Безопасность аккаунта',
    security: 'Безопасность аккаунта',
    securitySubtitle: 'Безопасность и настройки входа',
    devices: 'Подключённые устройства',
    devicesSubtitle: 'Управление подключёнными устройствами',
    futureSection: 'Будущие функции',
    onlineChat: 'Онлайн-чат',
    createTravelGroup: 'Создать туристическую группу',
    joinTravelGroups: 'Вступить в туристические группы',
    travelCompanion: 'Поиск попутчика',
    destinationRoom: 'Чат по направлению',
    futureSubtitle: 'Будет доступно в будущем обновлении',
    logout: 'Выйти из аккаунта',
    logoutSubtitle: 'Выйти и удалить данные аккаунта с устройства',
    logoutConfirmTitle: 'Выход',
    logoutConfirmMessage:
        'При выходе локальные данные аккаунта и фото профиля будут удалены с устройства.',
    cancel: 'Отмена',
    ok: 'ОК',
    futureTitle: 'В будущем обновлении',
    futureMessage:
        'Эта функция появится в будущих обновлениях Cyrus Tourist.',
  );

  static const _fr = _AccountTranslations(
    title: 'Compte',
    account: 'Mon compte',
    accountSubtitle: 'Gérer votre compte et vos fonctions de voyage',
    usernamePlaceholder: 'Nom d’utilisateur non défini',
    accountSection: 'Informations du compte',
    announcements: 'Annonces',
    announcementsSubtitle: 'Voir les dernières actualités et mises à jour',
    profile: 'Mon profil',
    profileSubtitle: 'Voir les informations du compte',
    editProfile: 'Modifier les informations',
    editProfileSubtitle: 'Modifier le nom d’utilisateur et les données',
    profileImage: 'Photo de profil',
    profileImageSubtitle: 'Choisir et gérer la photo de profil',
    registrationSection: 'Inscription touristique',
    accommodationRegistration: 'Inscription d’hébergement',
    accommodationRegistrationSubtitle:
        'Enregistrer votre hébergement',
    healthTourismRegistration: 'Inscription tourisme médical',
    healthTourismRegistrationSubtitle:
        'Enregistrer les services de tourisme médical',
    cabinRegistration: 'Inscription de chalet',
    cabinRegistrationSubtitle:
        'Enregistrer votre chalet ou hébergement',
    activitySection: 'Activité et récompenses',
    myReviews: 'Mes notes et avis',
    myReviewsSubtitle: 'Gérer vos notes et avis',
    travelStats: 'Mes statistiques de voyage',
    travelStatsSubtitle: 'Voir vos activités touristiques',
    achievements: 'Réalisations de voyage',
    achievementsSubtitle: 'Vos réalisations et badges',
    rewards: 'Points et récompenses',
    rewardsSubtitle: 'Voir vos points et récompenses',
    securitySection: 'Sécurité du compte',
    security: 'Sécurité du compte',
    securitySubtitle: 'Gérer la sécurité et la connexion',
    devices: 'Appareils connectés',
    devicesSubtitle: 'Gérer les appareils connectés',
    futureSection: 'Fonctions futures',
    onlineChat: 'Chat en ligne',
    createTravelGroup: 'Créer un groupe touristique',
    joinTravelGroups: 'Rejoindre des groupes touristiques',
    travelCompanion: 'Trouver un compagnon de voyage',
    destinationRoom: 'Salon de discussion de destination',
    futureSubtitle: 'Disponible dans une prochaine mise à jour',
    logout: 'Se déconnecter',
    logoutSubtitle: 'Déconnexion et suppression des données locales',
    logoutConfirmTitle: 'Déconnexion',
    logoutConfirmMessage:
        'La déconnexion supprimera les données locales du compte et la photo de profil de cet appareil.',
    cancel: 'Annuler',
    ok: 'OK',
    futureTitle: 'Disponible prochainement',
    futureMessage:
        'Cette fonction sera proposée dans une future mise à jour de Cyrus Tourist.',
  );

  static const _de = _AccountTranslations(
    title: 'Konto',
    account: 'Mein Konto',
    accountSubtitle: 'Konto und Reisefunktionen verwalten',
    usernamePlaceholder: 'Benutzername noch nicht festgelegt',
    accountSection: 'Kontoinformationen',
    announcements: 'Ankündigungen',
    announcementsSubtitle: 'Neueste Neuigkeiten und Updates ansehen',
    profile: 'Mein Profil',
    profileSubtitle: 'Kontoinformationen anzeigen',
    editProfile: 'Informationen bearbeiten',
    editProfileSubtitle: 'Benutzername und Kontodaten bearbeiten',
    profileImage: 'Profilbild',
    profileImageSubtitle: 'Profilbild auswählen und verwalten',
    registrationSection: 'Tourismus-Registrierung',
    accommodationRegistration: 'Unterkunft registrieren',
    accommodationRegistrationSubtitle:
        'Unterkunft registrieren und präsentieren',
    healthTourismRegistration: 'Gesundheitstourismus registrieren',
    healthTourismRegistrationSubtitle:
        'Gesundheitstourismus-Dienste registrieren',
    cabinRegistration: 'Hütte registrieren',
    cabinRegistrationSubtitle:
        'Hütte oder private Unterkunft registrieren',
    activitySection: 'Aktivität und Prämien',
    myReviews: 'Meine Bewertungen',
    myReviewsSubtitle: 'Bewertungen und Rezensionen verwalten',
    travelStats: 'Meine Reisestatistik',
    travelStatsSubtitle: 'Reise- und Tourismusaktivitäten anzeigen',
    achievements: 'Reiseerfolge',
    achievementsSubtitle: 'Ihre Erfolge und Abzeichen',
    rewards: 'Punkte und Prämien',
    rewardsSubtitle: 'Kontopunkte und Prämien anzeigen',
    securitySection: 'Kontosicherheit',
    security: 'Kontosicherheit',
    securitySubtitle: 'Sicherheits- und Anmeldeeinstellungen',
    devices: 'Verbundene Geräte',
    devicesSubtitle: 'Verbundene Geräte verwalten',
    futureSection: 'Zukünftige Funktionen',
    onlineChat: 'Online-Chat',
    createTravelGroup: 'Reisegruppe erstellen',
    joinTravelGroups: 'Reisegruppen beitreten',
    travelCompanion: 'Reisepartner finden',
    destinationRoom: 'Reiseziel-Chat',
    futureSubtitle: 'In einem zukünftigen Update verfügbar',
    logout: 'Abmelden',
    logoutSubtitle: 'Abmelden und Kontodaten vom Gerät löschen',
    logoutConfirmTitle: 'Abmelden',
    logoutConfirmMessage:
        'Beim Abmelden werden lokale Kontodaten und das Profilbild von diesem Gerät gelöscht.',
    cancel: 'Abbrechen',
    ok: 'OK',
    futureTitle: 'In einem zukünftigen Update',
    futureMessage:
        'Diese Funktion wird in einem zukünftigen Cyrus Tourist Update verfügbar sein.',
  );

  static const _es = _AccountTranslations(
    title: 'Cuenta',
    account: 'Mi cuenta',
    accountSubtitle: 'Gestiona tu cuenta y funciones de viaje',
    usernamePlaceholder: 'Nombre de usuario no configurado',
    accountSection: 'Información de la cuenta',
    announcements: 'Anuncios',
    announcementsSubtitle: 'Ver las últimas noticias y actualizaciones',
    profile: 'Mi perfil',
    profileSubtitle: 'Ver información de la cuenta',
    editProfile: 'Editar información',
    editProfileSubtitle: 'Editar nombre de usuario y datos',
    profileImage: 'Foto de perfil',
    profileImageSubtitle: 'Elegir y gestionar la foto de perfil',
    registrationSection: 'Registro turístico',
    accommodationRegistration: 'Registro de alojamiento',
    accommodationRegistrationSubtitle:
        'Registrar y presentar tu alojamiento',
    healthTourismRegistration: 'Registro de turismo de salud',
    healthTourismRegistrationSubtitle:
        'Registrar servicios de turismo de salud',
    cabinRegistration: 'Registro de cabaña',
    cabinRegistrationSubtitle:
        'Registrar tu cabaña o alojamiento privado',
    activitySection: 'Actividad y recompensas',
    myReviews: 'Mis valoraciones y opiniones',
    myReviewsSubtitle: 'Gestionar valoraciones y opiniones',
    travelStats: 'Mis estadísticas de viaje',
    travelStatsSubtitle: 'Ver actividad turística y viajes',
    achievements: 'Logros de viaje',
    achievementsSubtitle: 'Tus logros y distintivos',
    rewards: 'Puntos y recompensas',
    rewardsSubtitle: 'Ver puntos y recompensas de la cuenta',
    securitySection: 'Seguridad de la cuenta',
    security: 'Seguridad de la cuenta',
    securitySubtitle: 'Gestionar seguridad e inicio de sesión',
    devices: 'Dispositivos conectados',
    devicesSubtitle: 'Gestionar dispositivos conectados',
    futureSection: 'Funciones futuras',
    onlineChat: 'Chat en línea',
    createTravelGroup: 'Crear grupo turístico',
    joinTravelGroups: 'Unirse a grupos turísticos',
    travelCompanion: 'Buscar compañero de viaje',
    destinationRoom: 'Sala de conversación del destino',
    futureSubtitle: 'Disponible en una futura actualización',
    logout: 'Cerrar sesión',
    logoutSubtitle: 'Salir y borrar los datos de la cuenta del dispositivo',
    logoutConfirmTitle: 'Cerrar sesión',
    logoutConfirmMessage:
        'Al cerrar sesión se eliminarán los datos locales y la foto de perfil de este dispositivo.',
    cancel: 'Cancelar',
    ok: 'Aceptar',
    futureTitle: 'Próximamente',
    futureMessage:
        'Esta función estará disponible en futuras actualizaciones de Cyrus Tourist.',
  );

  static const _zh = _AccountTranslations(
    title: '账户',
    account: '我的账户',
    accountSubtitle: '管理账户和旅行功能',
    usernamePlaceholder: '尚未设置用户名',
    accountSection: '账户信息',
    announcements: '公告',
    announcementsSubtitle: '查看最新消息和更新',
    profile: '我的资料',
    profileSubtitle: '查看账户信息',
    editProfile: '编辑信息',
    editProfileSubtitle: '编辑用户名和账户信息',
    profileImage: '头像',
    profileImageSubtitle: '选择和管理头像',
    registrationSection: '旅游服务注册',
    accommodationRegistration: '住宿注册',
    accommodationRegistrationSubtitle: '注册并展示您的住宿',
    healthTourismRegistration: '健康旅游注册',
    healthTourismRegistrationSubtitle: '注册健康旅游服务',
    cabinRegistration: '小屋注册',
    cabinRegistrationSubtitle: '注册您的小屋或私人住宿',
    activitySection: '活动与奖励',
    myReviews: '我的评分和评论',
    myReviewsSubtitle: '管理评分和评论',
    travelStats: '我的旅行统计',
    travelStatsSubtitle: '查看旅行和旅游活动',
    achievements: '旅行成就',
    achievementsSubtitle: '您的旅游成就和徽章',
    rewards: '积分和奖励',
    rewardsSubtitle: '查看账户积分和奖励',
    securitySection: '账户安全',
    security: '账户安全',
    securitySubtitle: '管理安全和登录设置',
    devices: '已连接设备',
    devicesSubtitle: '管理已连接的设备',
    futureSection: '未来功能',
    onlineChat: '在线聊天',
    createTravelGroup: '创建旅游群组',
    joinTravelGroups: '加入旅游群组',
    travelCompanion: '寻找旅行伙伴',
    destinationRoom: '目的地讨论室',
    futureSubtitle: '将在未来更新中提供',
    logout: '退出账户',
    logoutSubtitle: '退出并清除设备上的账户数据',
    logoutConfirmTitle: '退出账户',
    logoutConfirmMessage: '退出后，本地账户信息和头像将从此设备删除。',
    cancel: '取消',
    ok: '确定',
    futureTitle: '未来更新',
    futureMessage: '此功能将在未来的 Cyrus Tourist 更新中提供。',
  );

  static const _it = _AccountTranslations(
    title: 'Account',
    account: 'Il mio account',
    accountSubtitle: 'Gestisci le informazioni e le funzioni del tuo account',
    usernamePlaceholder: 'Nome utente non ancora impostato',
    accountSection: 'Informazioni account',
    announcements: 'Annunci',
    announcementsSubtitle: 'Visualizza le ultime novità e aggiornamenti',
    profile: 'Il mio profilo',
    profileSubtitle: 'Visualizza le informazioni dell\u2019account',
    editProfile: 'Modifica informazioni',
    editProfileSubtitle: 'Modifica nome utente e informazioni account',
    profileImage: 'Immagine del profilo',
    profileImageSubtitle: 'Scegli e gestisci l\u2019immagine del profilo',
    registrationSection: 'Registrazione servizi turistici',
    accommodationRegistration: 'Registrazione alloggio',
    accommodationRegistrationSubtitle:
        'Registra il tuo alloggio e presentalo ai turisti',
    healthTourismRegistration: 'Registrazione turismo sanitario',
    healthTourismRegistrationSubtitle:
        'Registra servizi e centri di turismo sanitario',
    cabinRegistration: 'Registrazione cottage',
    cabinRegistrationSubtitle:
        'Registra il tuo cottage o alloggio esclusivo',
    activitySection: 'Attività e punteggi',
    myReviews: 'I miei punteggi e recensioni',
    myReviewsSubtitle: 'Gestisci punteggi e recensioni registrate',
    travelStats: 'Statistiche di viaggio',
    travelStatsSubtitle:
        'Visualizza statistiche di viaggio e attività turistiche',
    achievements: 'Traguardi di viaggio',
    achievementsSubtitle:
        'I tuoi traguardi e badge turistici',
    rewards: 'Punti e premi',
    rewardsSubtitle:
        'Visualizza punti e premi dell\u2019account',
    securitySection: 'Sicurezza dell\u2019account',
    security: 'Sicurezza dell\u2019account',
    securitySubtitle:
        'Gestisci sicurezza e impostazioni di accesso',
    devices: 'Dispositivi connessi',
    devicesSubtitle:
        'Gestisci i dispositivi collegati al tuo account',
    futureSection: 'Funzioni future',
    onlineChat: 'Chat online',
    createTravelGroup: 'Crea gruppo di viaggio',
    joinTravelGroups: 'Unisciti a gruppi di viaggio',
    travelCompanion: 'Trova un compagno di viaggio',
    destinationRoom: 'Stanza di discussione sulla destinazione',
    futureSubtitle: 'Sarà attivato in un futuro aggiornamento',
    logout: 'Esci dall\u2019account',
    logoutSubtitle:
        'Esci e cancella i dati dell\u2019account da questo dispositivo',
    logoutConfirmTitle: 'Esci dall\u2019account',
    logoutConfirmMessage:
        'Uscendo, i dati locali dell\u2019account e l\u2019immagine del profilo verranno cancellati da questo dispositivo.',
    cancel: 'Annulla',
    ok: 'Ho capito',
    futureTitle: 'Questa funzione è in arrivo',
    futureMessage:
        'Questa funzione sarà disponibile nei prossimi aggiornamenti di Cyrus Tourist. L\u2019infrastruttura dell\u2019account è stata progettata fin dall\u2019inizio per supportare le future comunicazioni sociali e turistiche.',
  );
}
