import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/tour.dart';
import '../../services/public_link_service.dart';
import '../../widgets/aparat_embed_player.dart';
import '../../widgets/share_sheet.dart';
import '../leaders/leader_profile_page.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

/// جزئیات تور — فقط بخش‌هایی که اطلاعات معتبر دارند نمایش داده می‌شوند
/// (طبق دستورکار: هیچ گزینه‌ای نباید کاربر را به صفحه‌ی خالی ببرد).
class TourDetailPage extends StatelessWidget {
  const TourDetailPage({super.key, required this.tour});

  final Tour tour;

  Tour get t => tour;

  @override
  Widget build(BuildContext context) {
    final catId = t.categoryIds.isNotEmpty ? t.categoryIds.first : 0;
    final color = tourGroupColorOf(catId);
    final emoji = tourCategoryById(catId)?.emoji ?? '🧳';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: const Text(
            'جزئیات تور',
            style: TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (t.shareEnabled)
              ShareIconButton(
                entityType: PublicLinkService.tour,
                entityId: '${t.id}',
                title: t.title,
              ),
          ],
        ),
        bottomNavigationBar: _actionBar(context),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _header(color, emoji),
              const SizedBox(height: 14),
              _specs(context),
              if (t.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                _section('توضیحات', child: Text(
                  t.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.8),
                )),
              ],
              if (t.hasVideo) ...[
                const SizedBox(height: 14),
                _videoCard(),
              ],
              if (t.leader != null || (t.agencyName ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                _providers(context),
              ],
              if (_hasProgram) ...[
                const SizedBox(height: 14),
                _program(),
              ],
              if (t.services.isNotEmpty) ...[
                const SizedBox(height: 14),
                _servicesChips(),
              ],
              if (t.shareEnabled) ...[
                const SizedBox(height: 14),
                ShareCard(
                  entityType: PublicLinkService.tour,
                  entityId: '${t.id}',
                  title: t.title,
                  heading: 'اشتراک‌گذاری این تور',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------

  Widget _header(Color color, String emoji) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: t.vip ? 0.7 : 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.55), const Color(0xff04101a)],
              ),
            ),
            child: Stack(
              children: [
                Center(child: Text(emoji, style: const TextStyle(fontSize: 60))),
                PositionedDirectional(
                  bottom: 10,
                  start: 12,
                  child: Row(
                    children: [
                      if (t.vip || t.featured) _tag('👑 ویژه', gold: true),
                      if (t.categoryLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _tag(t.categoryLabel),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: _card,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: const TextStyle(color: _goldBright, fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  t.code,
                  style: TextStyle(color: _gold.withValues(alpha: 0.85), fontSize: 11, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specs(BuildContext context) {
    final rows = <(String, String)>[
      ('دسته', t.categoryLabel),
      ('مقصد', t.destination),
      ('شهر', t.city),
      ('تاریخ شروع', t.startDate),
      ('تاریخ پایان', t.endDate),
      ('مدت', t.duration),
      ('ظرفیت', t.capacity),
      ('ظرفیت باقی‌مانده', t.remaining),
      ('قیمت', t.price),
    ].where((e) => e.$2.trim().isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    final width = (MediaQuery.of(context).size.width - 32 - 28 - 8) / 2;
    return _section(
      'مشخصات',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: rows
            .map(
              (e) => Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.$1, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10.5)),
                    const SizedBox(height: 2),
                    Text(
                      e.$2,
                      style: TextStyle(
                        color: e.$1 == 'قیمت' ? _teal : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _videoCard() {
    return _section(
      '🎥 فیلم تور',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: AparatEmbedPlayer(hash: t.aparatHash!),
        ),
      ),
    );
  }

  Widget _providers(BuildContext context) {
    final leader = t.leader;
    final agency = t.agencyName;
    return _section(
      'ارائه‌دهندگان',
      child: Column(
        children: [
          // ترتیب دستورکار: اول لیدر تور، بعد آژانس مسافرتی
          if (leader != null)
            _providerTile(
              icon: '🧭',
              name: leader.name,
              badge: 'لیدر تور',
              sub: [
                if (leader.code.isNotEmpty) leader.code,
                if (leader.languages.isNotEmpty) leader.languages.join('، '),
                '⭐ ${leader.rating.toStringAsFixed(1)}',
              ].join(' · '),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LeaderProfilePage(leader: leader)),
              ),
            ),
          if (agency != null && agency.isNotEmpty)
            _providerTile(
              icon: '🏢',
              name: agency,
              badge: 'آژانس',
              sub: [
                if ((t.agencyCode ?? '').isNotEmpty) t.agencyCode!,
                if ((t.agencyCity ?? '').isNotEmpty) t.agencyCity!,
                if (t.agencyRating != null) '⭐ ${t.agencyRating!.toStringAsFixed(1)}',
              ].join(' · '),
            ),
        ],
      ),
    );
  }

  Widget _providerTile({
    required String icon,
    required String name,
    required String badge,
    required String sub,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.16),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(badge, style: const TextStyle(color: _teal, fontSize: 10)),
                          ),
                        ],
                      ),
                      if (sub.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_left_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasProgram =>
      t.transport.isNotEmpty || t.accommodation.isNotEmpty || t.meals.isNotEmpty || t.rules.isNotEmpty;

  Widget _program() {
    final items = <(String, String)>[
      ('🚌 حمل‌ونقل', t.transport),
      ('🏨 اقامت', t.accommodation),
      ('🍽️ وعده‌های غذایی', t.meals),
      ('📜 قوانین و شرایط', t.rules),
    ].where((e) => e.$2.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('جزئیات برنامه', style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            ...items.map(
              (e) => ExpansionTile(
                iconColor: _gold,
                collapsedIconColor: _gold,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(e.$1, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                expandedAlignment: Alignment.centerRight,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      e.$2,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesChips() {
    return _section(
      'خدمات',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: t.services
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _teal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_rounded, color: _teal, size: 14),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // نوار پایین: رزرو فقط وقتی API فعالش کرده باشد
  // ------------------------------------------------------------

  Widget? _actionBar(BuildContext context) {
    if (!t.reservationEnabled) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _openReserve(context),
            icon: const Icon(Icons.event_available_rounded),
            label: const Text('رزرو / درخواست', style: TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xff3a2a00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ),
    );
  }

  void _openReserve(BuildContext context) {
    final mobile = t.leader?.mobile;
    final pageUrl = PublicLinkService.entityUrl(PublicLinkService.tour, '${t.id}');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xff0a2030),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('رزرو / درخواست تور',
                  style: TextStyle(color: _goldBright, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              if (mobile != null && mobile.isNotEmpty)
                _sheetButton(ctx, Icons.call_rounded, 'تماس با لیدر', () => _launch('tel:$mobile')),
              _sheetButton(ctx, Icons.public_rounded, 'ثبت درخواست در صفحه‌ی وب تور', () => _launch(pageUrl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetButton(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            onTap();
          },
          icon: Icon(icon, color: _gold),
          label: Text(label, style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _gold.withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ------------------------------------------------------------

  Widget _section(String title, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _tag(String text, {bool gold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: gold ? _gold : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: gold ? null : Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: gold ? const Color(0xff3a2a00) : Colors.white,
          fontSize: 10.5,
          fontWeight: gold ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    );
  }
}
