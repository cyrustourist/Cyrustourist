import 'package:flutter/material.dart';

import '../../models/tour.dart';
import 'tour_detail_page.dart';
import 'tour_list_page.dart';

const Color _bg = Color(0xff06121d);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);

/// «تورهای گردشگری»: ۲۵ دسته در ۵ گروه آکاردئونی (بدون شلوغی)،
/// جستجو (نوع تور، شهر یا کد) و چیپ‌های سریع.
class TourCategoriesPage extends StatefulWidget {
  const TourCategoriesPage({super.key});

  @override
  State<TourCategoriesPage> createState() => _TourCategoriesPageState();
}

class _TourCategoriesPageState extends State<TourCategoriesPage> {
  final TextEditingController _search = TextEditingController();
  final Set<int> _open = {0};

  TourLoadResult? _result;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await TourRepository.load();
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  List<Tour> get _tours => _result?.tours ?? const [];

  int _countOf(int categoryId) => _tours.where((t) => t.categoryIds.contains(categoryId)).length;

  void _openList(String title, List<Tour> tours) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TourListPage(
          title: title,
          tours: tours,
          online: _result?.online ?? false,
        ),
      ),
    );
  }

  void _openCategory(TourCategory c) {
    _openList(c.title, _tours.where((t) => t.categoryIds.contains(c.id)).toList());
  }

  List<Tour> get _matchingTours {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _tours
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.city.toLowerCase().contains(q) ||
            t.code.toLowerCase().contains(q) ||
            t.destination.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final matching = _matchingTours;

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
            'دسته‌بندی تورها',
            style: TextStyle(color: _gold, fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: _gold,
            backgroundColor: const Color(0xff0b2636),
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                Center(child: TourSourceBadge(online: _result?.online, loading: _loading)),
                const SizedBox(height: 12),
                _searchBox(),
                const SizedBox(height: 12),
                _quickChips(),
                const SizedBox(height: 12),
                if (matching.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, right: 4),
                    child: Text(
                      'تورهای پیدا‌شده',
                      style: TextStyle(color: _goldBright, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  ...matching.map(
                    (t) => ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: const Icon(Icons.tour_rounded, color: _gold),
                      title: Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(
                        '${t.code} · ${t.city}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TourDetailPage(tour: t)),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12),
                ],
                ..._groups(q),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xff0b2233),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: _gold.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'جستجوی نوع تور، شهر یا کد…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _quickChips() {
    final items = <(String, VoidCallback)>[
      (
        '👑 ویژه',
        () => _openList('تورهای ویژه', _tours.where((t) => t.vip || t.featured).toList()),
      ),
      ('💰 اقتصادی', () => _openCategory(tourCategoryById(21)!)),
      ('☀️ یک‌روزه', () => _openCategory(tourCategoryById(24)!)),
      ('🗓️ چندروزه', () => _openCategory(tourCategoryById(25)!)),
      ('🎥 دارای فیلم', () => _openList('تورهای دارای فیلم', _tours.where((t) => t.hasVideo).toList())),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: items[i].$2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff0d2537),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.3),
            ),
            child: Text(
              items[i].$1,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _groups(String q) {
    final out = <Widget>[];
    for (var gi = 0; gi < kTourGroups.length; gi++) {
      final g = kTourGroups[gi];
      final cats = q.isEmpty ? g.categories : g.categories.where((c) => c.title.contains(q)).toList();
      if (cats.isEmpty) continue;
      final isOpen = q.isNotEmpty || _open.contains(gi);

      out.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xff0a2030),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.22)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  if (!_open.remove(gi)) _open.add(gi);
                }),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: g.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(g.emoji, style: const TextStyle(fontSize: 19)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          g.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        height: 24,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${cats.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((c) => _catTile(c, g.color)).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (out.isEmpty) {
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, color: Colors.white38, size: 44),
              const SizedBox(height: 10),
              Text(
                'دسته‌ای با این نام پیدا نشد',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  Widget _catTile(TourCategory c, Color color) {
    final count = _countOf(c.id);
    final width = (MediaQuery.of(context).size.width - 32 - 24 - 8) / 2;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openCategory(c),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10.5)),
              ),
          ],
        ),
      ),
    );
  }
}

/// نشان منبع اطلاعات: 🟢 آنلاین (API) ، 🟡 نمونه/آفلاین
class TourSourceBadge extends StatelessWidget {
  const TourSourceBadge({super.key, required this.online, this.loading = false});

  final bool? online;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading || online == null) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
      );
    }
    final on = online!;
    final color = on ? const Color(0xff29e0ad) : const Color(0xffffc857);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        on ? '🟢 اطلاعات آنلاین' : '🟡 اطلاعات نمونه',
        style: TextStyle(color: color, fontSize: 10.5),
      ),
    );
  }
}
