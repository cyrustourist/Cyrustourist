
import 'package:flutter/material.dart';

/// آیتم مستقل برای منوی تنظیمات سایروس توریست.
///
/// هر گزینه می‌تواند آیکن، عنوان، توضیح و عملکرد مستقل داشته باشد.
class CyrusSettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showDivider;

  const CyrusSettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.showDivider = true,
  });
}

/// پنل مستقل تنظیمات.
///
/// این ویجت عمداً از فایل‌های فعلی پروژه مستقل است تا بعداً
/// گزینه‌های تأییدشده بدون تغییر ساختار اصلی برنامه به آن اضافه شوند.
class CyrusSettingsPanel extends StatelessWidget {
  final List<CyrusSettingsItem> items;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  const CyrusSettingsPanel({
    super.key,
    required this.items,
    this.title = 'تنظیمات',
    this.subtitle,
    this.onClose,
  });

  static const Color _background = Color(0xff071722);
  static const Color _gold = Color(0xffffd36a);
  static const Color _goldDark = Color(0xff9b6a19);
  static const Color _card = Color(0xff0d202d);

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);

    return Directionality(
      textDirection: direction,
      child: Material(
        color: _background,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildItemsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        color: _background,
        border: Border(
          bottom: BorderSide(
            color: _goldDark,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onClose != null)
            _buildCloseButton()
          else
            const SizedBox(
              width: 44,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.settings_outlined,
            color: _gold,
            size: 27,
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Builder(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(
                  color: _goldDark,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: _gold,
                size: 23,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList() {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'گزینه‌ای برای تنظیمات اضافه نشده است.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        12,
        14,
        12,
        20,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        final item = items[index];

        if (!item.showDivider) {
          return const SizedBox(
            height: 6,
          );
        }

        return const SizedBox(
          height: 6,
        );
      },
      itemBuilder: (context, index) {
        return _buildItem(items[index]);
      },
    );
  }

  Widget _buildItem(CyrusSettingsItem item) {
    final bool active = item.enabled && item.onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? item.onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? _goldDark
                  : Colors.white12,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              _buildItemIcon(
                item.icon,
                active,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? Colors.white54
                              : Colors.white24,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: active
                    ? _gold
                    : Colors.white24,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemIcon(
    IconData icon,
    bool active,
  ) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: active
              ? _goldDark
              : Colors.white12,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: active
            ? _gold
            : Colors.white30,
        size: 23,
      ),
    );
  }
}
