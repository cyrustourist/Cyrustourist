import 'package:flutter/material.dart';

import '../../models/tour.dart';
import '../../services/public_link_service.dart';
import '../../widgets/share_sheet.dart';
import 'tour_categories_page.dart';
import 'tour_detail_page.dart';

const Color _bg = Color(0xff06121d);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

/// فهرست تورهای یک دسته (یا فیلتر سریع)
class TourListPage extends StatefulWidget {
  const TourListPage({
    super.key,
    required this.title,
    required this.tours,
    required this.online,
  });

  final String title;
  final List<Tour> tours;
  final bool online;

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  String _filter = 'all';

  List<Tour> get _visible {
    switch (_filter) {
      case 'video':
        return widget.tours.where((t) => t.hasVideo).toList();
      case 'vip':
        return widget.tours.where((t) => t.vip || t.featured).toList();
      default:
        return widget.tours;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
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
            widget.title,
            style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Center(child: TourSourceBadge(online: widget.online)),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('all', 'همه'),
                    const SizedBox(width: 8),
                    _chip('vip', '👑 ویژه'),
                    const SizedBox(width: 8),
                    _chip('video', '🎥 دارای فیلم'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                _empty()
              else
                ...rows.map(
                  (t) => _TourCard(
                    tour: t,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TourDetailPage(tour: t)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String key, String label) {
    final on = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: on
              ? const LinearGradient(colors: [_gold, _goldBright])
              : const LinearGradient(colors: [Color(0xff102b3a), Color(0xff0a1d29)]),
          border: Border.all(color: _gold.withValues(alpha: 0.75), width: 1.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? const Color(0xff3a2a00) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.tour_outlined, color: Colors.white38, size: 56),
          const SizedBox(height: 14),
          Text(
            'هنوز توری در این بخش ثبت نشده است — به‌زودی 🌿',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13.5, height: 1.8),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.tour, required this.onTap});

  final Tour tour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catId = tour.categoryIds.isNotEmpty ? tour.categoryIds.first : 0;
    final color = tourGroupColorOf(catId);
    final emoji = tourCategoryById(catId)?.emoji ?? '🧳';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff0c2b3e), Color(0xff081b29)],
              ),
              border: Border.all(color: _gold.withValues(alpha: tour.vip ? 0.7 : 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 124,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: 0.5), const Color(0xff04101a)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(child: Text(emoji, style: const TextStyle(fontSize: 54))),
                      if (tour.shareEnabled)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: GestureDetector(
                            onTap: () => ShareSheet.show(
                              context,
                              entityType: PublicLinkService.tour,
                              entityId: '${tour.id}',
                              title: tour.title,
                            ),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.55),
                                border: Border.all(color: _gold.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      PositionedDirectional(
                        bottom: 8,
                        start: 10,
                        child: Row(
                          children: [
                            if (tour.vip || tour.featured) _tag('👑 ویژه', gold: true),
                            if (tour.hasVideo) ...[
                              const SizedBox(width: 6),
                              _tag('▶ دارای فیلم'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: const TextStyle(color: _goldBright, fontSize: 15.5, fontWeight: FontWeight.w900, height: 1.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tour.code,
                        style: TextStyle(color: _gold.withValues(alpha: 0.8), fontSize: 10.5, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (tour.city.isNotEmpty) _meta('📍', tour.city),
                          if (tour.duration.isNotEmpty) _meta('⏱', tour.duration),
                          if (tour.startDate.isNotEmpty) _meta('📅', tour.startDate),
                          if (tour.remaining.isNotEmpty) _meta('👥', 'ظرفیت باقی‌مانده ${tour.remaining}'),
                        ],
                      ),
                      if (tour.price.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tour.price, style: const TextStyle(color: _teal, fontWeight: FontWeight.w900, fontSize: 14)),
                            const Text('مشاهده ‹', style: TextStyle(color: _gold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _meta(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5)),
      ],
    );
  }
}
