import 'package:flutter/material.dart';

/// دکمه انتخاب زبان سایروس توریست.
///
/// این ویجت در main.dart (هدر صفحه اصلی) استفاده و به
/// MenuLanguage/MenuTranslations وصل است.
///
/// زبان‌های پشتیبانی‌شده:
/// fa = فارسی
/// en = English
/// ar = العربية
/// tr = Türkçe
/// ru = Русский
/// fr = Français
/// de = Deutsch
/// es = Español
/// zh = 中文
/// it = Italiano
class CyrusLanguageButton extends StatelessWidget {
  const CyrusLanguageButton({
    super.key,
    this.currentLanguage = 'fa',
    this.onLanguageChanged,
    this.showLabel = true,
  });

  final String currentLanguage;

  /// هنگام انتخاب زبان جدید اجرا می‌شود.
  ///
  /// فعلاً فقط callback است و تغییر زبان واقعی برنامه در مرحله
  /// اتصال نهایی انجام خواهد شد.
  final ValueChanged<String>? onLanguageChanged;

  /// نمایش نام کوتاه زبان کنار آیکون.
  final bool showLabel;

  static const List<CyrusLanguage> languages = [
    CyrusLanguage(
      code: 'fa',
      name: 'فارسی',
      nativeName: 'فارسی',
      flag: '🇮🇷',
      isRtl: true,
    ),
    CyrusLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'ar',
      name: 'العربية',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRtl: true,
    ),
    CyrusLanguage(
      code: 'tr',
      name: 'Türkçe',
      nativeName: 'Türkçe',
      flag: '🇹🇷',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'ru',
      name: 'Русский',
      nativeName: 'Русский',
      flag: '🇷🇺',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'fr',
      name: 'Français',
      nativeName: 'Français',
      flag: '🇫🇷',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'de',
      name: 'Deutsch',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'es',
      name: 'Español',
      nativeName: 'Español',
      flag: '🇪🇸',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'zh',
      name: '中文',
      nativeName: '中文',
      flag: '🇨🇳',
      isRtl: false,
    ),
    CyrusLanguage(
      code: 'it',
      name: 'Italiano',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      isRtl: false,
    ),
  ];

  CyrusLanguage get _current {
    final normalized = currentLanguage.toLowerCase().trim();

    return languages.firstWhere(
      (language) => language.code == normalized,
      orElse: () => languages.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: _tooltip,
      elevation: 12,
      color: const Color(0xff102532),
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xffd6ad55).withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xffc99b3b),
          width: 0.8,
        ),
      ),
      offset: const Offset(0, 8),
      onSelected: (code) {
        onLanguageChanged?.call(code);
      },
      itemBuilder: (context) {
        return languages.map((language) {
          final selected = language.code == _current.code;

          return PopupMenuItem<String>(
            value: language.code,
            height: 58,
            child: Directionality(
              textDirection:
                  language.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Row(
                children: [
                  _LanguageFlag(
                    flag: language.flag,
                    selected: selected,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      language.nativeName,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xffffd978)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xffffd56d),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: _LanguageHeaderButton(
        language: _current,
        showLabel: showLabel,
      ),
    );
  }

  String get _tooltip {
    switch (_current.code) {
      case 'en':
        return 'Language';
      case 'ar':
        return 'اللغة';
      case 'tr':
        return 'Dil';
      case 'ru':
        return 'Язык';
      case 'fr':
        return 'Langue';
      case 'de':
        return 'Sprache';
      case 'es':
        return 'Idioma';
      case 'zh':
        return '语言';
      case 'it':
        return 'Lingua';
      case 'fa':
      default:
        return 'زبان';
    }
  }
}

/// مدل زبان.
class CyrusLanguage {
  const CyrusLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isRtl,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRtl;
}

/// ظاهر دکمه زبان در هدر.
class _LanguageHeaderButton extends StatelessWidget {
  const _LanguageHeaderButton({
    required this.language,
    required this.showLabel,
  });

  final CyrusLanguage language;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 44,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 9 : 6,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xfff0cb70),
            Color(0xffa9701d),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffffdf8a),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffd6ad55).withOpacity(0.30),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            color: Color(0xff071722),
            size: 23,
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              language.code.toUpperCase(),
              style: const TextStyle(
                color: Color(0xff071722),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// پرچم زبان در منوی انتخاب زبان.
class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({
    required this.flag,
    required this.selected,
  });

  final String flag;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xffd6ad55).withOpacity(0.16)
            : const Color(0xff071722),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected
              ? const Color(0xffd6ad55)
              : const Color(0xff49606b),
          width: 0.7,
        ),
      ),
      child: Text(
        flag,
        style: const TextStyle(
          fontSize: 21,
        ),
      ),
    );
  }
}
