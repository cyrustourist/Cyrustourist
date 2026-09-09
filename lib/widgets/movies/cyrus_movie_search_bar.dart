import 'package:flutter/material.dart';

import '../../core/language/app_language.dart';
import '../../models/cyrus_movie_entry.dart';

const Color _goldColor = Color(0xffffd36a);
const Color _cardBg = Color(0xff0b2636);

/// جست‌وجوی هوشمند در میان همه‌ی فیلم‌ها بر اساس:
///  - کد یکتا (مثلاً «1001» یا «#1001»)
///  - عنوان فیلم (به هر ۳ زبان موجود: fa/en/ar)
///  - نام شهر یا استان (citySearchKey / provinceSearchKey)
///
/// جست‌وجو contains-based و غیرحساس به کوچک/بزرگی حروف است، نه فقط
/// تطابق دقیق، تا با تایپ نصفه‌ونیمه هم نتیجه بدهد.
List<CyrusMovieEntry> filterMovieEntries(
  List<CyrusMovieEntry> entries,
  String rawQuery,
) {
  final String query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return entries;

  final String queryDigits = query.replaceAll('#', '');

  return entries.where((entry) {
    if (entry.uniqueCode.toString().contains(queryDigits)) return true;

    final List<String> haystacks = [
      entry.titles['fa'] ?? '',
      entry.titles['en'] ?? '',
      entry.titles['ar'] ?? '',
      entry.citySearchKey,
      entry.provinceSearchKey,
    ];

    return haystacks.any((h) => h.toLowerCase().contains(query));
  }).toList();
}

/// نوار جست‌وجوی هوشمند — بالای گرید کاور فیلم‌ها قرار می‌گیرد.
class CyrusMovieSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const CyrusMovieSearchBar({super.key, required this.onChanged});

  @override
  State<CyrusMovieSearchBar> createState() => _CyrusMovieSearchBarState();
}

class _CyrusMovieSearchBarState extends State<CyrusMovieSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hintText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'جست‌وجو با کد، نام فیلم، شهر یا استان...';
      case AppLanguage.arabic:
        return 'البحث بالرمز، اسم الفيلم، المدينة أو المحافظة...';
      case AppLanguage.english:
        return 'Search by code, title, city or province...';
      case AppLanguage.german:
        return 'Suche nach Code, Titel, Stadt oder Provinz...';
      case AppLanguage.spanish:
        return 'Buscar por código, título, ciudad o provincia...';
      case AppLanguage.french:
        return 'Rechercher par code, titre, ville ou province...';
      case AppLanguage.italian:
        return 'Cerca per codice, titolo, città o provincia...';
      case AppLanguage.russian:
        return 'Поиск по коду, названию, городу или провинции...';
      case AppLanguage.turkish:
        return 'Kod, başlık, şehir veya il ile ara...';
      case AppLanguage.chinese:
        return '按代码、标题、城市或省份搜索...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _goldColor.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: _hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
                setState(() {});
              },
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// وقتی جست‌وجو نتیجه‌ای پیدا نکند، این پیام دوستانه به‌جای گرید خالی
/// نمایش داده می‌شود.
class CyrusMovieSearchEmptyState extends StatelessWidget {
  const CyrusMovieSearchEmptyState({super.key});

  String get _message {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'به‌زودی این بخش تکمیل می‌شود؛ سپاس از همراهی‌تان با سایروس توریست 🌿';
      case AppLanguage.arabic:
        return 'سيتم استكمال هذا القسم قريبًا؛ شكرًا لمرافقتكم سايروس توريست 🌿';
      case AppLanguage.english:
        return 'Coming soon — thank you for being with Cyrus Tourist 🌿';
      case AppLanguage.german:
        return 'Demnächst verfügbar — danke, dass Sie bei Cyrus Tourist sind 🌿';
      case AppLanguage.spanish:
        return 'Próximamente — gracias por acompañar a Cyrus Tourist 🌿';
      case AppLanguage.french:
        return 'Bientôt disponible — merci d\'accompagner Cyrus Tourist 🌿';
      case AppLanguage.italian:
        return 'Presto disponibile — grazie per essere con Cyrus Tourist 🌿';
      case AppLanguage.russian:
        return 'Скоро появится — спасибо, что вы с Cyrus Tourist 🌿';
      case AppLanguage.turkish:
        return 'Yakında eklenecek — Cyrus Tourist ile birlikte olduğunuz için teşekkürler 🌿';
      case AppLanguage.chinese:
        return '即将上线 — 感谢您与 Cyrus Tourist 同行 🌿';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.movie_filter_rounded,
            size: 40,
            color: _goldColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 14),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
