import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/leader.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

class LeaderProfilePage extends StatelessWidget {
  const LeaderProfilePage({super.key, required this.leader});

  final Leader leader;

  Future<void> _openVideo(BuildContext context) async {
    final url = leader.introVideoUrl;
    if (url == null) return;
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
            leader.name,
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
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: _gold.withValues(alpha: 0.15),
                  backgroundImage:
                      leader.photoAsset != null ? AssetImage(leader.photoAsset!) : null,
                  child: leader.photoAsset == null
                      ? const Icon(Icons.person, color: _gold, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  leader.name,
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
                    if (leader.isLocalLeader) _badge('لیدر محلی'),
                    if (leader.isLicensed) _badge('دارای مجوز'),
                    _statusBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _sectionCard(
                icon: Icons.star_rounded,
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: _teal, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      leader.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${leader.reviewCount} نظر کاربران)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const Spacer(),
                    if (leader.experienceText.isNotEmpty)
                      Flexible(
                        child: Text(
                          leader.experienceText,
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

              if (leader.bio.isNotEmpty)
                _infoSection(title: 'معرفی لیدر', body: leader.bio),

              if (leader.regions.isNotEmpty)
                _chipsSection(
                  title: 'شهر و مناطق فعالیت',
                  icon: Icons.location_on_rounded,
                  items: leader.regions,
                ),

              if (leader.languages.isNotEmpty)
                _chipsSection(
                  title: 'زبان‌ها',
                  icon: Icons.language_rounded,
                  items: leader.languages,
                ),

              _infoSection(title: 'زمینه تخصصی', body: leader.specialty),

              if (leader.introVideoUrl != null)
                _sectionCard(
                  icon: Icons.play_circle_fill_rounded,
                  child: InkWell(
                    onTap: () => _openVideo(context),
                    child: Row(
                      children: const [
                        Icon(Icons.play_circle_fill_rounded, color: _teal, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'مشاهده ویدئوی معرفی',
                          style: TextStyle(
                            color: _goldBright,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (leader.tours.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 4),
                  child: Text(
                    'تورهای ارائه‌شده توسط این لیدر',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...leader.tours.map(
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
    final status = leader.status;
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

  Widget _sectionCard({required IconData icon, required Widget child}) {
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
      icon: Icons.info_outline_rounded,
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
      icon: icon,
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
