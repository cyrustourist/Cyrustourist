import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/app_language.dart';
import '../../models/showcase_item.dart';
import 'showcase_cover.dart';
import 'showcase_kinds.dart';

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);

/// صفحه‌ی جزئیات عمومی — برای هر آیتمی که سرور بفرستد و قالب اختصاصی
/// (فیلم/اقامتگاه/لیدر/آژانس) نداشته باشد (مثلاً گردشگری سلامت).
class ShowcaseDetailPage extends StatelessWidget {
  const ShowcaseDetailPage({super.key, required this.item});

  final ShowcaseItem item;

  String get _lang {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'fa';
      case AppLanguage.arabic:
        return 'ar';
      default:
        return 'en';
    }
  }

  String _tr(String fa, String en, String ar) {
    switch (_lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _snack(context);
    } catch (_) {
      if (context.mounted) _snack(context);
    }
  }

  void _snack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_tr('امکان باز کردن لینک وجود ندارد.', 'Unable to open this link.', 'تعذر فتح هذا الرابط.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ShowcaseKinds.of(item.kind);
    final rtl = _lang != 'en';
    final title = item.title(_lang);
    final loc = item.location(_lang);
    final cat = item.categoryLabel(_lang);
    final desc = item.description(_lang);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(info.title(_lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ShowcaseCover(item: item, fallbackIcon: info.icon, lang: _lang),
                      if (item.hasVideo)
                        Center(
                          child: InkWell(
                            onTap: () => _open(context, item.videoUrl!),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.55),
                                border: Border.all(color: _gold),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: _gold, size: 34),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.4)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (loc.isNotEmpty) _chip(Icons.location_on_outlined, loc),
                  if (cat.isNotEmpty) _chip(Icons.label_outline_rounded, cat),
                  if (item.rating != null)
                    _chip(Icons.star_rounded,
                        '${item.rating!.toStringAsFixed(1)}${item.ratingCount != null ? ' (${item.ratingCount})' : ''}'),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_tr('چکیده', 'Summary', 'نبذة'),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(desc,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5, height: 1.8)),
              ],
              const SizedBox(height: 18),
              if (item.ctaUrl != null && item.ctaUrl!.isNotEmpty)
                _bigButton(
                  icon: Icons.local_offer_rounded,
                  label: item.ctaLabel(_lang).isNotEmpty
                      ? item.ctaLabel(_lang)
                      : _tr('مشاهده پیشنهاد', 'View offer', 'عرض العرض'),
                  color: _gold,
                  onTap: () => _open(context, item.ctaUrl!),
                ),
              if (item.latitude != null && item.longitude != null)
                _bigButton(
                  icon: Icons.map_rounded,
                  label: _tr('مسیریابی سریع', 'Fast route', 'المسار السريع'),
                  color: _teal,
                  onTap: () => _open(context,
                      'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}'),
                ),
              if (item.phone != null && item.phone!.isNotEmpty)
                _bigButton(
                  icon: Icons.call_rounded,
                  label: _tr('تماس مستقیم', 'Call now', 'اتصال مباشر'),
                  color: _gold,
                  onTap: () => _open(context, 'tel:${item.phone}'),
                ),
              Row(
                children: [
                  if (item.instagramUrl != null && item.instagramUrl!.isNotEmpty)
                    Expanded(
                      child: _smallButton(Icons.camera_alt_rounded, 'Instagram',
                          () => _open(context, item.instagramUrl!)),
                    ),
                  if (item.instagramUrl != null &&
                      item.instagramUrl!.isNotEmpty &&
                      item.websiteUrl != null &&
                      item.websiteUrl!.isNotEmpty)
                    const SizedBox(width: 10),
                  if (item.websiteUrl != null && item.websiteUrl!.isNotEmpty)
                    Expanded(
                      child: _smallButton(Icons.language_rounded, _tr('وب‌سایت', 'Website', 'الموقع'),
                          () => _open(context, item.websiteUrl!)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                style: const TextStyle(color: _goldBright, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: _bg,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _smallButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: _gold, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
