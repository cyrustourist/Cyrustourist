import 'package:flutter/material.dart';

/// فایل مستقل تنظیمات ظاهر سایروس توریست.
///
/// سه حالت ظاهری:
/// 1. روشن
/// 2. تاریک
/// 3. طلایی سایروس
///
/// نکته:
/// این فایل در مرحله فعلی هیچ اتصال مستقیمی به main.dart
/// یا Theme اصلی برنامه ندارد.
/// اتصال نهایی در مرحله اتصال کلیدها انجام خواهد شد.

enum CyrusThemeMode {
  light,
  dark,
  cyrusGold,
}

class CyrusSettingsTheme {
  CyrusSettingsTheme._();

  /// ساخت گزینه‌های سه‌حالته ظاهر برنامه.
  static List<CyrusThemeItem> buildItems({
    required CyrusThemeMode selectedMode,
    required ValueChanged<CyrusThemeMode> onChanged,
    required String languageCode,
  }) {
    return [
      CyrusThemeItem(
        mode: CyrusThemeMode.light,
        icon: Icons.light_mode_rounded,
        title: _text(
          languageCode,
          'روشن',
          'Light',
          'فاتح',
          'Açık',
          'Светлая',
          'Clair',
          'Hell',
          'Claro',
          '浅色',
          'ライト',
        ),
        subtitle: _text(
          languageCode,
          'ظاهر روشن برنامه',
          'Light appearance',
          'مظهر التطبيق الفاتح',
          'Açık uygulama görünümü',
          'Светлый вид приложения',
          'Apparence claire',
          'Helle Darstellung',
          'Apariencia clara',
          '浅色应用界面',
          '明るい表示',
        ),
        color: const Color(0xffe6a817),
        selected: selectedMode == CyrusThemeMode.light,
        onTap: () => onChanged(CyrusThemeMode.light),
      ),
      CyrusThemeItem(
        mode: CyrusThemeMode.dark,
        icon: Icons.dark_mode_rounded,
        title: _text(
          languageCode,
          'تاریک',
          'Dark',
          'داكن',
          'Koyu',
          'Тёмная',
          'Sombre',
          'Dunkel',
          'Oscuro',
          '深色',
          'ダーク',
        ),
        subtitle: _text(
          languageCode,
          'ظاهر تاریک و مناسب شب',
          'Dark appearance for night',
          'مظهر داكن مناسب للاستخدام الليلي',
          'Gece kullanımı için koyu görünüm',
          'Тёмный вид для ночного использования',
          'Apparence sombre pour la nuit',
          'Dunkle Darstellung für die Nacht',
          'Apariencia oscura para la noche',
          '适合夜间使用的深色界面',
          '夜間に適したダーク表示',
        ),
        color: const Color(0xff536d7a),
        selected: selectedMode == CyrusThemeMode.dark,
        onTap: () => onChanged(CyrusThemeMode.dark),
      ),
      CyrusThemeItem(
        mode: CyrusThemeMode.cyrusGold,
        icon: Icons.auto_awesome_rounded,
        title: _text(
          languageCode,
          'طلایی سایروس',
          'Cyrus Gold',
          'ذهبي سايروس',
          'Cyrus Altın',
          'Золотой Cyrus',
          'Or Cyrus',
          'Cyrus Gold',
          'Dorado Cyrus',
          'Cyrus 金色',
          'Cyrus ゴールド',
        ),
        subtitle: _text(
          languageCode,
          'رنگ اختصاصی و لوکس سایروس توریست',
          'Exclusive CyrusTourist gold theme',
          'المظهر الذهبي الفاخر الخاص بسايروس توريست',
          'CyrusTourist özel altın teması',
          'Эксклюзивная золотая тема CyrusTourist',
          'Thème doré exclusif de CyrusTourist',
          'Exklusives CyrusTourist-Gold-Design',
          'Tema dorado exclusivo de CyrusTourist',
          'CyrusTourist 专属金色主题',
          'CyrusTourist専用ゴールドテーマ',
        ),
        color: const Color(0xffc9a227),
        selected: selectedMode == CyrusThemeMode.cyrusGold,
        onTap: () => onChanged(CyrusThemeMode.cyrusGold),
      ),
    ];
  }

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
    String ja,
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
      case 'ja':
        return ja;
      case 'fa':
      default:
        return fa;
    }
  }
}

/// مدل هر حالت ظاهری.
class CyrusThemeItem {
  final CyrusThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const CyrusThemeItem({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });
}

/// دکمه سه‌بعدی انتخاب حالت رنگ.
class CyrusThemeButton extends StatefulWidget {
  final CyrusThemeItem item;

  const CyrusThemeButton({
    super.key,
    required this.item,
  });

  @override
  State<CyrusThemeButton> createState() => _CyrusThemeButtonState();
}

class _CyrusThemeButtonState extends State<CyrusThemeButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        item.onTap();
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
            colors: item.selected
                ? [
                    item.color.withOpacity(0.30),
                    const Color(0xff101f29),
                  ]
                : [
                    const Color(0xff203641),
                    const Color(0xff0b1b25),
                  ],
          ),
          border: Border.all(
            color: item.selected
                ? const Color(0xffffd966)
                : const Color(0xff8c7020),
            width: item.selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffffc107).withOpacity(
                item.selected ? 0.42 : 0.20,
              ),
              blurRadius: item.selected ? 14 : 8,
              spreadRadius: item.selected ? 1 : 0,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(item),
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
                        fontSize: 16,
                        fontWeight: item.selected
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
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildSelection(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(CyrusThemeItem item) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color.withOpacity(0.95),
            item.color.withOpacity(0.50),
          ],
        ),
        border: Border.all(
          color: const Color(0xffffd966),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffc107).withOpacity(0.35),
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

  Widget _buildSelection(CyrusThemeItem item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.selected
            ? const Color(0xffc9a227)
            : Colors.transparent,
        border: Border.all(
          color: item.selected
              ? const Color(0xffffe08a)
              : const Color(0xff8c7020),
          width: 1.4,
        ),
        boxShadow: item.selected
            ? [
                BoxShadow(
                  color: const Color(0xffffc107).withOpacity(0.42),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: item.selected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            )
          : null,
    );
  }
}

/// ویجت کامل سه حالت رنگ.
class CyrusThemeSelector extends StatelessWidget {
  final CyrusThemeMode selectedMode;
  final ValueChanged<CyrusThemeMode> onChanged;
  final String languageCode;

  const CyrusThemeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final items = CyrusSettingsTheme.buildItems(
      selectedMode: selectedMode,
      onChanged: onChanged,
      languageCode: languageCode,
    );

    return Column(
      children: [
        for (final item in items)
          CyrusThemeButton(
            item: item,
          ),
      ],
    );
  }
}
