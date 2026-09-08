import 'package:flutter/material.dart';

import '../models/cyrus_announcement.dart';
import '../services/notification_service.dart';

/// صفحه‌ی «اعلان‌ها»ی سایروس توریست.
///
/// از داخل کلید ۸ (حساب کاربری → گزینه‌ی زنگوله‌ی اعلان‌ها) باز می‌شود.
/// لیست را از API واقعی می‌گیرد:
/// https://cyrus-tourist-api.cyrustourist.workers.dev/notifications
///
/// این نسخه مخصوص پیام‌های تبلیغاتی/اطلاع‌رسانی طراحی شده:
/// - فقط خواندن (بدون نیاز به هیچ اقدام دیگری از کاربر)
/// - امکان حذف هر پیام توسط کاربر (با سوایپ یا دکمه‌ی سطل زباله)
/// - متن پیام هیچ محدودیت طولی ندارد و کامل نمایش داده می‌شود
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({
    super.key,
    this.languageCode = 'fa',
  });

  final String languageCode;

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<CyrusAnnouncement>? _items;
  bool _loading = true;

  bool get _isRtl =>
      widget.languageCode == 'fa' || widget.languageCode == 'ar';

  late final _AnnouncementsTranslations _texts =
      _AnnouncementsTranslations.get(widget.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final items = await NotificationService.instance.fetchAnnouncements();

    // به‌محض باز شدن صفحه، همه را «خوانده‌شده» علامت می‌زنیم
    // تا بج قرمز روی کلید ۸ پاک شود.
    await NotificationService.instance.markAllAsRead(items);

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<bool> _confirmDelete(CyrusAnnouncement item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff102733),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xffff7070),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _texts.deleteTitle,
                  style: const TextStyle(
                    color: Color(0xffffd36a),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _texts.deleteMessage,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                _texts.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff9f3030),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_texts.delete),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteItem(CyrusAnnouncement item) async {
    setState(() {
      _items?.removeWhere((element) => element.id == item.id);
    });

    await NotificationService.instance.dismiss(item.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff102733),
        content: Text(
          _texts.deletedSnackbar,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
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
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            _texts.title,
            style: const TextStyle(
              color: Color(0xffffd36a),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xffffd36a),
            backgroundColor: const Color(0xff102733),
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(
              color: Color(0xffffd36a),
            ),
          ),
        ],
      );
    }

    final items = _items ?? const [];

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Dismissible(
          key: ValueKey('announcement_${item.id}'),
          direction: DismissDirection.horizontal,
          background: _buildSwipeBackground(alignStart: true),
          secondaryBackground: _buildSwipeBackground(alignStart: false),
          confirmDismiss: (_) => _confirmDelete(item),
          onDismissed: (_) => _deleteItem(item),
          child: _AnnouncementCard(
            item: item,
            texts: _texts,
            onDelete: () async {
              final confirmed = await _confirmDelete(item);
              if (confirmed) {
                await _deleteItem(item);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground({required bool alignStart}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      decoration: BoxDecoration(
        color: const Color(0xff9f3030),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.delete_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_rounded,
                      color: Color(0xff5b7280),
                      size: 54,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _texts.empty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// کارت اعلان به‌سبک بنر تبلیغاتی — بدون محدودیت طول متن.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.texts,
    required this.onDelete,
  });

  final CyrusAnnouncement item;
  final _AnnouncementsTranslations texts;
  final VoidCallback onDelete;

  List<Color> get _typeGradient {
    switch (item.type) {
      case 'update':
        return const [Color(0xff1769aa), Color(0xff0d3f61)];
      case 'event':
        return const [Color(0xff8e244d), Color(0xff4a1329)];
      case 'warning':
        return const [Color(0xffb85c1f), Color(0xff5c2c0c)];
      default:
        return const [Color(0xffb8860b), Color(0xff5c4109)];
    }
  }

  Color get _accentColor {
    switch (item.type) {
      case 'update':
        return const Color(0xff4fc3ff);
      case 'event':
        return const Color(0xffff7fb8);
      case 'warning':
        return const Color(0xffffb257);
      default:
        return const Color(0xffffd36a);
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case 'update':
        return Icons.system_update_alt_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case 'update':
        return texts.typeUpdate;
      case 'event':
        return texts.typeEvent;
      case 'warning':
        return texts.typeWarning;
      default:
        return texts.typeInfo;
    }
  }

  String get _formattedDate {
    final date = item.createdAt;
    if (date == null) return '';

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');

    return '$y/$m/$d  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff132b37),
            Color(0xff0a1a24),
          ],
        ),
        border: Border.all(
          color: _accentColor.withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // نوار بالای کارت — به‌سبک بنر تبلیغاتی
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _typeGradient,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(_typeIcon, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  splashRadius: 22,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // متن اصلی پیام — بدون محدودیت طول
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14.5,
                    height: 1.75,
                  ),
                ),
                if (_formattedDate.isNotEmpty || item.version.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_formattedDate.isNotEmpty) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formattedDate,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      if (_formattedDate.isNotEmpty && item.version.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      if (item.version.isNotEmpty)
                        Text(
                          'v${item.version}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ترجمه ۱۰ زبان صفحه‌ی اعلان‌ها.
class _AnnouncementsTranslations {
  const _AnnouncementsTranslations({
    required this.title,
    required this.empty,
    required this.typeUpdate,
    required this.typeInfo,
    required this.typeEvent,
    required this.typeWarning,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.delete,
    required this.cancel,
    required this.deletedSnackbar,
  });

  final String title;
  final String empty;
  final String typeUpdate;
  final String typeInfo;
  final String typeEvent;
  final String typeWarning;
  final String deleteTitle;
  final String deleteMessage;
  final String delete;
  final String cancel;
  final String deletedSnackbar;

  static _AnnouncementsTranslations get(String languageCode) {
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

  static const _fa = _AnnouncementsTranslations(
    title: 'آگهی‌ها',
    empty: 'در حال حاضر آگهی‌ای وجود ندارد.',
    typeUpdate: 'بروزرسانی',
    typeInfo: 'اطلاعیه',
    typeEvent: 'رویداد',
    typeWarning: 'هشدار',
    deleteTitle: 'حذف آگهی',
    deleteMessage: 'آیا از حذف این پیام مطمئن هستید؟',
    delete: 'حذف',
    cancel: 'انصراف',
    deletedSnackbar: 'پیام حذف شد.',
  );

  static const _en = _AnnouncementsTranslations(
    title: 'Announcements',
    empty: 'There are no announcements right now.',
    typeUpdate: 'Update',
    typeInfo: 'Info',
    typeEvent: 'Event',
    typeWarning: 'Warning',
    deleteTitle: 'Delete Announcement',
    deleteMessage: 'Are you sure you want to delete this message?',
    delete: 'Delete',
    cancel: 'Cancel',
    deletedSnackbar: 'Message deleted.',
  );

  static const _ar = _AnnouncementsTranslations(
    title: 'الإشعارات',
    empty: 'لا توجد إشعارات حالياً.',
    typeUpdate: 'تحديث',
    typeInfo: 'معلومة',
    typeEvent: 'فعالية',
    typeWarning: 'تحذير',
    deleteTitle: 'حذف الإشعار',
    deleteMessage: 'هل أنت متأكد من حذف هذه الرسالة؟',
    delete: 'حذف',
    cancel: 'إلغاء',
    deletedSnackbar: 'تم حذف الرسالة.',
  );

  static const _tr = _AnnouncementsTranslations(
    title: 'Duyurular',
    empty: 'Şu anda duyuru bulunmuyor.',
    typeUpdate: 'Güncelleme',
    typeInfo: 'Bilgi',
    typeEvent: 'Etkinlik',
    typeWarning: 'Uyarı',
    deleteTitle: 'Duyuruyu Sil',
    deleteMessage: 'Bu mesajı silmek istediğinizden emin misiniz?',
    delete: 'Sil',
    cancel: 'İptal',
    deletedSnackbar: 'Mesaj silindi.',
  );

  static const _ru = _AnnouncementsTranslations(
    title: 'Объявления',
    empty: 'Сейчас нет объявлений.',
    typeUpdate: 'Обновление',
    typeInfo: 'Информация',
    typeEvent: 'Событие',
    typeWarning: 'Предупреждение',
    deleteTitle: 'Удалить объявление',
    deleteMessage: 'Вы уверены, что хотите удалить это сообщение?',
    delete: 'Удалить',
    cancel: 'Отмена',
    deletedSnackbar: 'Сообщение удалено.',
  );

  static const _fr = _AnnouncementsTranslations(
    title: 'Annonces',
    empty: 'Aucune annonce pour le moment.',
    typeUpdate: 'Mise à jour',
    typeInfo: 'Info',
    typeEvent: 'Événement',
    typeWarning: 'Avertissement',
    deleteTitle: 'Supprimer l’annonce',
    deleteMessage: 'Voulez-vous vraiment supprimer ce message ?',
    delete: 'Supprimer',
    cancel: 'Annuler',
    deletedSnackbar: 'Message supprimé.',
  );

  static const _de = _AnnouncementsTranslations(
    title: 'Ankündigungen',
    empty: 'Derzeit gibt es keine Ankündigungen.',
    typeUpdate: 'Update',
    typeInfo: 'Info',
    typeEvent: 'Ereignis',
    typeWarning: 'Warnung',
    deleteTitle: 'Ankündigung löschen',
    deleteMessage: 'Möchten Sie diese Nachricht wirklich löschen?',
    delete: 'Löschen',
    cancel: 'Abbrechen',
    deletedSnackbar: 'Nachricht gelöscht.',
  );

  static const _es = _AnnouncementsTranslations(
    title: 'Anuncios',
    empty: 'No hay anuncios por el momento.',
    typeUpdate: 'Actualización',
    typeInfo: 'Info',
    typeEvent: 'Evento',
    typeWarning: 'Advertencia',
    deleteTitle: 'Eliminar anuncio',
    deleteMessage: '¿Seguro que deseas eliminar este mensaje?',
    delete: 'Eliminar',
    cancel: 'Cancelar',
    deletedSnackbar: 'Mensaje eliminado.',
  );

  static const _zh = _AnnouncementsTranslations(
    title: '公告',
    empty: '目前没有公告。',
    typeUpdate: '更新',
    typeInfo: '信息',
    typeEvent: '活动',
    typeWarning: '警告',
    deleteTitle: '删除公告',
    deleteMessage: '确定要删除这条消息吗？',
    delete: '删除',
    cancel: '取消',
    deletedSnackbar: '消息已删除。',
  );

  static const _it = _AnnouncementsTranslations(
    title: 'Annunci',
    empty: 'Al momento non ci sono annunci.',
    typeUpdate: 'Aggiornamento',
    typeInfo: 'Info',
    typeEvent: 'Evento',
    typeWarning: 'Avviso',
    deleteTitle: 'Elimina annuncio',
    deleteMessage: 'Sei sicuro di voler eliminare questo messaggio?',
    delete: 'Elimina',
    cancel: 'Annulla',
    deletedSnackbar: 'Messaggio eliminato.',
  );
}
