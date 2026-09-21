import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/agency.dart';
import '../../services/public_link_service.dart';
import '../../widgets/share_sheet.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

class AgencyProfilePage extends StatelessWidget {
  const AgencyProfilePage({super.key, required this.agency});

  final Agency agency;

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(
            agency.name,
            style: const TextStyle(
              color: _gold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: _gold.withValues(alpha: 0.15),
                      backgroundImage:
                          agency.logoAsset != null ? AssetImage(agency.logoAsset!) : null,
                      child: agency.logoAsset == null
                          ? const Icon(Icons.apartment_rounded, color: _gold, size: 48)
                          : null,
                    ),
                    // آیکون اشتراک‌گذاری کنار لوگو → برگه‌ی گزینه‌ها
                    if (agencyCodeOf(agency) > 0)
                      Positioned(
                        bottom: -2,
                        left: -6,
                        child: GestureDetector(
                          onTap: () => ShareSheet.show(
                            context,
                            entityType: PublicLinkService.agency,
                            entityId: '${agencyCodeOf(agency)}',
                            title: agency.name,
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [_gold, _goldBright]),
                              border: Border.all(color: _bg, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.ios_share_rounded, color: Color(0xff3a2a00), size: 19),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  agency.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _goldBright,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (agency.isVerifiedPartner) _badge('آژانس معتبر'),
                    if (agency.isLicensed) _badge('دارای مجوز'),
                    _statusBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _sectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: _teal, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      agency.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${agency.reviewCount} نظر کاربران)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const Spacer(),
                    if (agency.experienceText.isNotEmpty)
                      Flexible(
                        child: Text(
                          agency.experienceText,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (agency.bio.isNotEmpty)
                _infoSection(title: 'معرفی آژانس', body: agency.bio),

              if (agency.regions.isNotEmpty)
                _chipsSection(
                  title: 'شهر و مناطق فعالیت',
                  icon: Icons.location_on_rounded,
                  items: agency.regions,
                ),

              _infoSection(title: 'خدمات ارائه‌شده', body: agency.services),

              if (agency.phone != null || agency.website != null)
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'راه‌های ارتباطی',
                        style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      if (agency.phone != null)
                        InkWell(
                          onTap: () => _openLink('tel:${agency.phone}'),
                          child: Row(
                            children: [
                              const Icon(Icons.call_rounded, color: _teal, size: 18),
                              const SizedBox(width: 8),
                              Text(agency.phone!, style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      if (agency.website != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openLink(agency.website!),
                          child: Row(
                            children: [
                              const Icon(Icons.public_rounded, color: _teal, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  agency.website!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              if (agency.introVideoUrl != null)
                _sectionCard(
                  child: InkWell(
                    onTap: () => _openLink(agency.introVideoUrl!),
                    child: Row(
                      children: const [
                        Icon(Icons.play_circle_fill_rounded, color: _teal, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'مشاهده ویدئوی معرفی',
                          style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              if (agency.tours.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 4),
                  child: Text(
                    'تورهای ارائه‌شده توسط این آژانس',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...agency.tours.map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tour_rounded, color: _gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (t.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    t.description,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final status = agency.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.labelFa(),
            style: TextStyle(color: status.color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  Widget _infoSection({required String title, required String body}) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _chipsSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
