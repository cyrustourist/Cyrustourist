import 'package:flutter/material.dart';

/// فایل مستقل تنظیمات اعلان‌های سایروس توریست.
///
/// فعلاً فقط رابط کاربری و ساختار تنظیمات را آماده می‌کند.
/// اتصال واقعی به سیستم اعلان گوشی در مرحله نهایی انجام می‌شود.
///
/// امکانات:
/// - فعال/غیرفعال کردن اعلان‌ها
/// - اعلان‌های گردشگری
/// - پیشنهادهای سفر
/// - اطلاع‌رسانی‌های مهم
/// - پیام‌های پشتیبانی
///
/// زبان‌های آماده:
/// فارسی، انگلیسی، عربی، ترکی، روسی،
/// فرانسوی، آلمانی، اسپانیایی، چینی، ایتالیایی

class CyrusSettingsNotifications {
  CyrusSettingsNotifications._();

  /// ساخت تنظیمات اعلان.
  static List<CyrusNotificationItem> buildItems({
    required String languageCode,
    required bool notificationsEnabled,
    required bool tourismNotificationsEnabled,
    required bool travelSuggestionsEnabled,
    required bool supportNotificationsEnabled,
    required bool soundEffectEnabled,
    required ValueChanged<bool> onNotificationsChanged,
    required ValueChanged<bool> onTourismNotificationsChanged,
    required ValueChanged<bool> onTravelSuggestionsChanged,
    required ValueChanged<bool> onSupportNotificationsChanged,
    required ValueChanged<bool> onSoundEffectChanged,
  }) {
    return [
      CyrusNotificationItem(
        icon: Icons.notifications_active_rounded,
        title: _text(
          languageCode,
          'اعلان‌های برنامه',
          'App Notifications',
          'إشعارات التطبيق',
          'Uygulama Bildirimleri',
          'Уведомления приложения',
          'Notifications de l’application',
          'App-Benachrichtigungen',
          'Notificaciones de la aplicación',
          '应用通知',
          'Notifiche app',
        ),
        subtitle: _text(
          languageCode,
          'دریافت اعلان از سایروس توریست',
          'Receive notifications from CyrusTourist',
          'تلقي الإشعارات من سايروس توريست',
          'CyrusTourist bildirimlerini al',
          'Получать уведомления от CyrusTourist',
          'Recevoir les notifications de CyrusTourist',
          'Benachrichtigungen von CyrusTourist erhalten',
          'Recibir notificaciones de CyrusTourist',
          '接收 CyrusTourist 通知',
          'Ricevi notifiche da CyrusTourist',
        ),
        value: notificationsEnabled,
        enabled: true,
        color: const Color(0xffc9a227),
        onChanged: onNotificationsChanged,
      ),
      CyrusNotificationItem(
        icon: Icons.travel_explore_rounded,
        title: _text(
          languageCode,
          'اعلان‌های گردشگری',
          'Tourism Notifications',
          'إشعارات السياحة',
          'Turizm Bildirimleri',
          'Туристические уведомления',
          'Notifications touristiques',
          'Tourismus-Benachrichtigungen',
          'Notificaciones turísticas',
          '旅游通知',
          'Notifiche turistiche',
        ),
        subtitle: _text(
          languageCode,
          'اطلاع از جاذبه‌ها و رویدادهای گردشگری',
          'Updates about attractions and tourism events',
          'تحديثات حول المعالم والفعاليات السياحية',
          'Turistik yerler ve etkinlikler hakkında güncellemeler',
          'Новости о достопримечательностях и событиях',
          'Actualités sur les sites et événements touristiques',
          'Neuigkeiten zu Sehenswürdigkeiten und Veranstaltungen',
          'Novedades sobre atracciones y eventos turísticos',
          '景点和旅游活动更新',
          'Aggiornamenti su attrazioni ed eventi turistici',
        ),
        value: tourismNotificationsEnabled,
        enabled: notificationsEnabled,
        color: const Color(0xff1769aa),
        onChanged: onTourismNotificationsChanged,
      ),
      CyrusNotificationItem(
        icon: Icons.auto_awesome_rounded,
        title: _text(
          languageCode,
          'پیشنهادهای سفر',
          'Travel Suggestions',
          'اقتراحات السفر',
          'Seyahat Önerileri',
          'Предложения для путешествий',
          'Suggestions de voyage',
          'Reiseempfehlungen',
          'Sugerencias de viaje',
          '旅行推荐',
          'Suggerimenti di viaggio',
        ),
        subtitle: _text(
          languageCode,
          'پیشنهادهای ویژه برای سفر و گردشگری',
          'Special travel and tourism suggestions',
          'اقتراحات خاصة للسفر والسياحة',
          'Özel seyahat ve turizm önerileri',
          'Специальные предложения для путешествий',
          'Suggestions spéciales de voyage et tourisme',
          'Besondere Reise- und Tourismusempfehlungen',
          'Sugerencias especiales de viaje y turismo',
          '特别旅行和旅游推荐',
          'Suggerimenti speciali di viaggio e turismo',
        ),
        value: travelSuggestionsEnabled,
        enabled: notificationsEnabled,
        color: const Color(0xff8e244d),
        onChanged: onTravelSuggestionsChanged,
      ),
      CyrusNotificationItem(
        icon: Icons.support_agent_rounded,
        title: _text(
          languageCode,
          'پیام‌های پشتیبانی',
          'Support Messages',
          'رسائل الدعم',
          'Destek Mesajları',
          'Сообщения поддержки',
          'Messages du support',
          'Support-Nachrichten',
          'Mensajes de soporte',
          '支持消息',
          'Messaggi di supporto',
        ),
        subtitle: _text(
          languageCode,
          'دریافت پاسخ و پیام‌های پشتیبانی',
          'Receive support replies and messages',
          'تلقي ردود ورسائل الدعم',
          'Destek yanıtlarını ve mesajlarını al',
          'Получать ответы и сообщения поддержки',
          'Recevoir les réponses et messages du support',
          'Support-Antworten und Nachrichten erhalten',
          'Recibir respuestas y mensajes de soporte',
          '接收支持回复和消息',
          'Ricevi risposte e messaggi di supporto',
        ),
        value: supportNotificationsEnabled,
        enabled: notificationsEnabled,
        color: const Color(0xff2f7d5b),
        onChanged: onSupportNotificationsChanged,
      ),
      CyrusNotificationItem(
        icon: Icons.volume_up_rounded,
        title: _text(
          languageCode,
          'افکت صدای آگهی جدید',
          'New Announcement Sound',
          'صوت الإعلان الجديد',
          'Yeni Duyuru Sesi',
          'Звук нового объявления',
          'Son de nouvelle annonce',
          'Sound für neue Ankündigung',
          'Sonido de nuevo anuncio',
          '新公告提示音',
          'Suono nuovo annuncio',
        ),
        subtitle: _text(
          languageCode,
          'پخش صدا هنگام رسیدن آگهی جدید (خاموش = سکوت)',
          'Play a sound when a new announcement arrives (off = silent)',
          'تشغيل صوت عند وصول إعلان جديد (إيقاف = صامت)',
          'Yeni duyuru geldiğinde ses çal (kapalı = sessiz)',
          'Воспроизводить звук при новом объявлении (выкл. = тишина)',
          'Jouer un son à l’arrivée d’une nouvelle annonce (désactivé = silencieux)',
          'Ton bei neuer Ankündigung abspielen (aus = lautlos)',
          'Reproducir sonido al llegar un nuevo anuncio (apagado = silencio)',
          '收到新公告时播放提示音（关闭=静音）',
          'Riproduci un suono quando arriva un nuovo annuncio (off = silenzioso)',
        ),
        value: soundEffectEnabled,
        enabled: true,
        color: const Color(0xffc9a227),
        onChanged: onSoundEffectChanged,
      ),
    ];
  }

  /// ترجمه داخلی ۱۰ زبان.
  static String _text(
    String languageCode,
    String fa,
    String en,
    String ar,
    String tr,
    String ru,
    String fr,
    String de,
    String es,
    String zh,
    String it,
  ) {
    final code = languageCode.toLowerCase().split('-').first;

    switch (code) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      case 'tr':
        return tr;
      case 'ru':
        return ru;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'es':
        return es;
      case 'zh':
        return zh;
      case 'it':
        return it;
      case 'fa':
      default:
        return fa;
    }
  }
}

/// مدل هر گزینه اعلان.
class CyrusNotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  const CyrusNotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.color,
    required this.onChanged,
  });
}

/// کلید سه‌بعدی اعلان با جلوه طلایی.
class CyrusNotificationSwitch extends StatefulWidget {
  final CyrusNotificationItem item;

  const CyrusNotificationSwitch({
    super.key,
    required this.item,
  });

  @override
  State<CyrusNotificationSwitch> createState() =>
      _CyrusNotificationSwitchState();
}

class _CyrusNotificationSwitchState
    extends State<CyrusNotificationSwitch> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  void _toggle() {
    if (!widget.item.enabled) return;

    widget.item.onChanged(!widget.item.value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final bool active = item.value && item.enabled;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        _toggle();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _pressed ? 3 : 0,
          0,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [
                    item.color.withOpacity(0.28),
                    const Color(0xff101f29),
                  ]
                : [
                    const Color(0xff203641),
                    const Color(0xff0b1b25),
                  ],
          ),
          border: Border.all(
            color: active
                ? const Color(0xffffd966)
                : const Color(0xff8c7020),
            width: active ? 1.7 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffffc107).withOpacity(
                active ? 0.38 : 0.18,
              ),
              blurRadius: active ? 13 : 8,
              spreadRadius: active ? 1 : 0,
              offset: Offset(
                0,
                _pressed ? 2 : 6,
              ),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Opacity(
          opacity: item.enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildIcon(item, active),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildSwitch(active),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    CyrusNotificationItem item,
    bool active,
  ) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color.withOpacity(active ? 0.95 : 0.60),
            item.color.withOpacity(active ? 0.50 : 0.30),
          ],
        ),
        border: Border.all(
          color: const Color(0xffffd966),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffc107).withOpacity(
              active ? 0.36 : 0.18,
            ),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        item.icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildSwitch(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 54,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: active
            ? const Color(0xffc9a227)
            : const Color(0xff344750),
        border: Border.all(
          color: active
              ? const Color(0xffffe08a)
              : const Color(0xff8c7020),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffc107).withOpacity(
              active ? 0.30 : 0.10,
            ),
            blurRadius: 7,
          ),
        ],
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: active
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: active
              ? const Icon(
                  Icons.check_rounded,
                  color: Color(0xff9b7a12),
                  size: 15,
                )
              : null,
        ),
      ),
    );
  }
}

/// ویجت کامل بخش اعلان‌ها.
class CyrusNotificationsSelector extends StatelessWidget {
  final String languageCode;
  final bool notificationsEnabled;
  final bool tourismNotificationsEnabled;
  final bool travelSuggestionsEnabled;
  final bool supportNotificationsEnabled;
  final bool soundEffectEnabled;

  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onTourismNotificationsChanged;
  final ValueChanged<bool> onTravelSuggestionsChanged;
  final ValueChanged<bool> onSupportNotificationsChanged;
  final ValueChanged<bool> onSoundEffectChanged;

  const CyrusNotificationsSelector({
    super.key,
    required this.languageCode,
    required this.notificationsEnabled,
    required this.tourismNotificationsEnabled,
    required this.travelSuggestionsEnabled,
    required this.supportNotificationsEnabled,
    required this.soundEffectEnabled,
    required this.onNotificationsChanged,
    required this.onTourismNotificationsChanged,
    required this.onTravelSuggestionsChanged,
    required this.onSupportNotificationsChanged,
    required this.onSoundEffectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = CyrusSettingsNotifications.buildItems(
      languageCode: languageCode,
      notificationsEnabled: notificationsEnabled,
      tourismNotificationsEnabled:
          tourismNotificationsEnabled,
      travelSuggestionsEnabled:
          travelSuggestionsEnabled,
      supportNotificationsEnabled:
          supportNotificationsEnabled,
      soundEffectEnabled: soundEffectEnabled,
      onNotificationsChanged: onNotificationsChanged,
      onTourismNotificationsChanged:
          onTourismNotificationsChanged,
      onTravelSuggestionsChanged:
          onTravelSuggestionsChanged,
      onSupportNotificationsChanged:
          onSupportNotificationsChanged,
      onSoundEffectChanged: onSoundEffectChanged,
    );

    return Column(
      children: [
        for (final item in items)
          CyrusNotificationSwitch(
            item: item,
          ),
      ],
    );
  }
}
