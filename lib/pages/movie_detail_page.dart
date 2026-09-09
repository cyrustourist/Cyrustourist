import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/app_language.dart';
import '../models/cyrus_movie_entry.dart';

const Color _bg = Color(0xff06121d);
const Color _cardBg = Color(0xff0b2636);
const Color _goldColor = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _tealColor = Color(0xff29e0ad);
const Color _tealBright = Color(0xff6bf0c8);

/// صفحه‌ی «امکانات کامل» هر فیلم — با کلیک روی کارت کاور باز می‌شود.
/// همان الگوی residence_register_page.dart (معرفی/مزایا + تماس با
/// پشتیبانی برای ثبت‌نام واقعی) اما مخصوص یک فیلم مشخص با کد یکتای خودش.
class MovieDetailPage extends StatelessWidget {
  final CyrusMovieEntry entry;

  const MovieDetailPage({super.key, required this.entry});

  String get _languageCode {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.italian:
        return 'it';
      case AppLanguage.russian:
        return 'ru';
      case AppLanguage.turkish:
        return 'tr';
      case AppLanguage.chinese:
        return 'zh';
    }
  }

  bool get _isRtl =>
      LanguageManager.current == AppLanguage.persian ||
      LanguageManager.current == AppLanguage.arabic;

  String get _codeLabel {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'کد یکتا';
      case AppLanguage.arabic:
        return 'الرمز الفريد';
      case AppLanguage.english:
        return 'Unique code';
      case AppLanguage.german:
        return 'Eindeutiger Code';
      case AppLanguage.spanish:
        return 'Código único';
      case AppLanguage.french:
        return 'Code unique';
      case AppLanguage.italian:
        return 'Codice univoco';
      case AppLanguage.russian:
        return 'Уникальный код';
      case AppLanguage.turkish:
        return 'Benzersiz kod';
      case AppLanguage.chinese:
        return '唯一代码';
    }
  }

  String get _benefitsTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'امکانات این بخش';
      case AppLanguage.arabic:
        return 'مزايا هذا القسم';
      case AppLanguage.english:
        return 'What this listing offers';
      case AppLanguage.german:
        return 'Was dieser Eintrag bietet';
      case AppLanguage.spanish:
        return 'Qué ofrece este listado';
      case AppLanguage.french:
        return 'Ce que propose cette fiche';
      case AppLanguage.italian:
        return 'Cosa offre questa scheda';
      case AppLanguage.russian:
        return 'Что предлагает эта запись';
      case AppLanguage.turkish:
        return 'Bu kayıt neler sunuyor';
      case AppLanguage.chinese:
        return '此条目提供的服务';
    }
  }

  List<String> get _benefits {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return [
          'نمایش فیلم گردشگری در اپلیکیشن و سایت سایروس توریست',
          'کد یکتای اختصاصی برای جست‌وجوی سریع این فیلم',
          'لینک مستقیم به صفحه‌ی اینستاگرام و وب‌سایت شما',
          'امکان پین‌شدن کدهای رند/ویژه',
        ];
      case AppLanguage.arabic:
        return [
          'عرض الفيديو السياحي في تطبيق وموقع سايروس توريست',
          'رمز فريد مخصص للبحث السريع عن هذا الفيديو',
          'رابط مباشر لصفحة إنستغرام وموقعك',
          'إمكانية تثبيت الرموز المميزة',
        ];
      case AppLanguage.english:
        return [
          'Your tourism video shown in the Cyrus Tourist app and website',
          'A dedicated unique code for quick search',
          'Direct link to your Instagram and website',
          'Round/special codes can be pinned',
        ];
      case AppLanguage.german:
        return [
          'Ihr Tourismusvideo in der Cyrus Tourist App und Website',
          'Ein eigener Code für die schnelle Suche',
          'Direkter Link zu Ihrem Instagram und Ihrer Website',
          'Besondere Codes können angepinnt werden',
        ];
      case AppLanguage.spanish:
        return [
          'Tu video turístico en la app y web de Cyrus Tourist',
          'Un código único para búsqueda rápida',
          'Enlace directo a tu Instagram y sitio web',
          'Los códigos especiales se pueden fijar',
        ];
      case AppLanguage.french:
        return [
          'Votre vidéo touristique dans l\'app et le site Cyrus Tourist',
          'Un code unique pour une recherche rapide',
          'Lien direct vers votre Instagram et site web',
          'Les codes spéciaux peuvent être épinglés',
        ];
      case AppLanguage.italian:
        return [
          'Il tuo video turistico nell\'app e sul sito Cyrus Tourist',
          'Un codice univoco per la ricerca rapida',
          'Link diretto al tuo Instagram e sito web',
          'I codici speciali possono essere fissati',
        ];
      case AppLanguage.russian:
        return [
          'Ваше видео в приложении и на сайте Cyrus Tourist',
          'Уникальный код для быстрого поиска',
          'Прямая ссылка на ваш Instagram и сайт',
          'Особые коды можно закрепить',
        ];
      case AppLanguage.turkish:
        return [
          'Turizm videonuz Cyrus Tourist uygulaması ve sitesinde',
          'Hızlı arama için özel benzersiz kod',
          'Instagram ve web sitenize doğrudan bağlantı',
          'Özel kodlar sabitlenebilir',
        ];
      case AppLanguage.chinese:
        return [
          '您的旅游视频将展示在 Cyrus Tourist 应用和网站上',
          '专属唯一代码，便于快速搜索',
          '直接链接到您的 Instagram 和网站',
          '特殊代码可以置顶',
        ];
    }
  }

  String get _contactTitle {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'تماس با پشتیبانی برای ثبت‌نام';
      case AppLanguage.arabic:
        return 'التواصل مع الدعم للتسجيل';
      case AppLanguage.english:
        return 'Contact support to register';
      case AppLanguage.german:
        return 'Support für Registrierung kontaktieren';
      case AppLanguage.spanish:
        return 'Contactar soporte para registrarse';
      case AppLanguage.french:
        return 'Contacter le support pour vous inscrire';
      case AppLanguage.italian:
        return 'Contatta il supporto per registrarti';
      case AppLanguage.russian:
        return 'Связаться с поддержкой для регистрации';
      case AppLanguage.turkish:
        return 'Kayıt için destek ile iletişime geçin';
      case AppLanguage.chinese:
        return '联系客服进行注册';
    }
  }

  String get _watchOnAparat {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'پخش در آپارات';
      case AppLanguage.arabic:
        return 'مشاهدة على آپارات';
      case AppLanguage.english:
        return 'Watch on Aparat';
      case AppLanguage.german:
        return 'Auf Aparat ansehen';
      case AppLanguage.spanish:
        return 'Ver en Aparat';
      case AppLanguage.french:
        return 'Voir sur Aparat';
      case AppLanguage.italian:
        return 'Guarda su Aparat';
      case AppLanguage.russian:
        return 'Смотреть на Aparat';
      case AppLanguage.turkish:
        return 'Aparat\'ta izle';
      case AppLanguage.chinese:
        return '在 Aparat 观看';
    }
  }

  String get _backText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'بازگشت';
      case AppLanguage.arabic:
        return 'رجوع';
      case AppLanguage.english:
        return 'Back';
      case AppLanguage.german:
        return 'Zurück';
      case AppLanguage.spanish:
        return 'Atrás';
      case AppLanguage.french:
        return 'Retour';
      case AppLanguage.italian:
        return 'Indietro';
      case AppLanguage.russian:
        return 'Назад';
      case AppLanguage.turkish:
        return 'Geri';
      case AppLanguage.chinese:
        return '返回';
    }
  }

  String get _linkErrorText {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'امکان باز کردن لینک وجود ندارد.';
      case AppLanguage.arabic:
        return 'تعذر فتح الرابط.';
      case AppLanguage.english:
        return 'Unable to open the link.';
      case AppLanguage.german:
        return 'Link kann nicht geöffnet werden.';
      case AppLanguage.spanish:
        return 'No se puede abrir el enlace.';
      case AppLanguage.french:
        return 'Impossible d\'ouvrir le lien.';
      case AppLanguage.italian:
        return 'Impossibile aprire il link.';
      case AppLanguage.russian:
        return 'Не удалось открыть ссылку.';
      case AppLanguage.turkish:
        return 'Bağlantı açılamıyor.';
      case AppLanguage.chinese:
        return '无法打开链接。';
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_linkErrorText, textAlign: TextAlign.center)),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_linkErrorText, textAlign: TextAlign.center)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = entry.text('title', _languageCode);
    final String location = entry.text('location', _languageCode);
    final String category = entry.text('category', _languageCode);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(entry.coverImage, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xaa06121d)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            if (entry.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: _tealColor,
                                  size: 18,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xcc06121d),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _goldColor.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                '$_codeLabel: #${entry.uniqueCode}',
                                style: const TextStyle(
                                  color: _goldColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (location.isNotEmpty || category.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (location.isNotEmpty)
                      _InfoChip(icon: Icons.location_on_rounded, text: location),
                    if (category.isNotEmpty)
                      _InfoChip(icon: Icons.local_offer_rounded, text: category),
                  ],
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(context, entry.videoUrl),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(_watchOnAparat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldColor,
                    foregroundColor: const Color(0xff06121d),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _benefitsTitle,
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              ..._benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _tealColor,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _goldColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contactTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final phone in entry.phoneNumbers)
                          _ContactButton(
                            icon: Icons.call_rounded,
                            label: phone,
                            onTap: () => _openUrl(context, 'tel:$phone'),
                          ),
                        _ContactButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Instagram',
                          onTap: () => _openUrl(context, entry.instagramUrl),
                        ),
                        _ContactButton(
                          icon: Icons.public_rounded,
                          label: 'Website',
                          onTap: () => _openUrl(context, entry.websiteUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(_backText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _goldColor),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_tealColor, _tealBright],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: const Color(0xff03202a)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff03202a),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
