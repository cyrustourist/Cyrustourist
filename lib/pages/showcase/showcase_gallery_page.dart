import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/app_language.dart';
import '../../models/agency.dart';
import '../../models/leader.dart';
import '../../models/showcase_item.dart';
import '../../services/showcase_service.dart';
import '../../services/video_favorites_service.dart';
import '../agencies/agency_profile_page.dart';
import '../agencies/agency_registration_intro_page.dart';
import '../leaders/leader_profile_page.dart';
import '../leaders/leader_registration_intro_page.dart';
import '../residence_register_page.dart';
import '../../widgets/showcase_hub_banner.dart';
import 'showcase_cover.dart';
import 'showcase_kinds.dart';
import 'showcase_navigator.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

const String _aparatChannel = 'https://www.aparat.com/Cyrustourist';
const String _instagramUrl =
    'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
const String _youtubeUrl =
    'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i';
const String _tiktokUrl = 'https://www.tiktok.com/@cyrustourist_app';

enum _Sort { recommended, name, rating }

/// قالب مشترک همه‌ی صفحه‌های «نمایش»:
/// جست‌وجوی پیشرفته + نوار ابزار اختصاصی هر بخش + کارت‌های کاور‌دار دو ستونه.
/// داده از [ShowcaseService] می‌آید (محلی یا سرور).
class ShowcaseGalleryPage extends StatefulWidget {
  const ShowcaseGalleryPage({
    super.key,
    required this.kind,
    this.initialFilter,
    this.showHubBanner = false,
  });

  final ShowcaseKind kind;

  /// کلید فیلتری که از ابتدا انتخاب شود (مثلاً health از نقشه سلامت)
  final String? initialFilter;

  /// اگر true باشد، بالای صفحه بنر تصویریِ «هاب ۴ کلید» (اقامتی/جاذبه/سلامت/لیدر)
  /// نمایش داده می‌شود و بقیه‌ی محتوا (جست‌وجو، فیلترها، فهرست) پایین‌تر می‌آید.
  final bool showHubBanner;

  @override
  State<ShowcaseGalleryPage> createState() => _ShowcaseGalleryPageState();
}

class _ShowcaseGalleryPageState extends State<ShowcaseGalleryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final VideoFavoritesService _favService = VideoFavoritesService();

  List<ShowcaseItem> _items = [];
  List<ShowcaseFilter>? _serverFilters;
  Set<String> _favIds = {};
  bool _loading = true;

  String _query = '';
  late String _filterKey;
  _Sort _sort = _Sort.recommended;
  String? _province;
  bool _onlyVip = false;

  ShowcaseKindInfo get _info => ShowcaseKinds.of(widget.kind);

  String get _lang {
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

  bool get _rtl => _lang == 'fa' || _lang == 'ar';

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

  @override
  void initState() {
    super.initState();
    _filterKey = widget.initialFilter ?? 'all';
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// لمس یکی از ۴ کلید بنر بالای صفحه: اگر همان بخش فعلی باشد کاری نمی‌کند،
  /// در غیر این صورت گالری همان دسته را باز می‌کند (با همان بنر بالای صفحه).
  void _openHubSection(ShowcaseKind kind) {
    if (kind == widget.kind) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShowcaseGalleryPage(kind: kind, showHubBanner: true),
      ),
    );
  }

  Future<void> _load() async {
    var result = await ShowcaseService.load(widget.kind, lang: _lang);

    // تا وقتی داده‌ی واقعیِ لیدر/گردشگری سلامت از سرور نرسیده، برای اینکه
    // صفحه‌ی هاب خالی به‌نظر نرسد، همان فیلم‌های نمایشیِ موجود را به‌عنوان
    // نمونه‌ی موقت نشان می‌دهیم (به محض رسیدن داده‌ی واقعی، همین‌جا حذف شود).
    if (result.items.isEmpty &&
        (widget.kind == ShowcaseKind.leader || widget.kind == ShowcaseKind.health)) {
      final fallback = await ShowcaseService.load(ShowcaseKind.video, lang: _lang);
      result = ShowcaseLoad(items: fallback.items, filters: result.filters);
    }

    Set<String> favs = {};
    if (widget.kind.isVideoLike) {
      try {
        favs = await _favService.loadFavoriteIds();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _items = result.items;
      _serverFilters = result.filters;
      _favIds = favs;
      _loading = false;
    });
  }

  // ------------------------------------------------------------
  // فیلتر و مرتب‌سازی
  // ------------------------------------------------------------

  ShowcaseFilter get _allFilter => const ShowcaseFilter(
        key: 'all',
        labels: {'fa': 'همه', 'en': 'All', 'ar': 'الكل'},
      );

  List<ShowcaseFilter> get _filters {
    if (_serverFilters != null && _serverFilters!.isNotEmpty) {
      return _serverFilters!;
    }
    final info = _info;
    if (info.dynamicFilters) {
      final seen = <String>{};
      final list = <ShowcaseFilter>[];
      for (final it in _items) {
        final c = it.categoryLabel(_lang);
        if (c.isNotEmpty && seen.add(c)) {
          list.add(ShowcaseFilter(key: 'cat:$c', labels: {_lang: c}));
        }
      }
      return [...list, ...info.filters];
    }
    return info.filters;
  }

  bool _matches(ShowcaseItem item, ShowcaseFilter f) {
    if (f.key == 'all') return true;
    if (f.key.startsWith('cat:')) {
      return item.categoryLabel(_lang) == f.key.substring(4);
    }
    if (item.categories.contains(f.key)) return true;
    final text = item.filterText;
    for (final k in f.keywords) {
      if (text.contains(showcaseNormalize(k))) return true;
    }
    return false;
  }

  List<ShowcaseItem> get _visible {
    final filter = _filters.firstWhere(
      (e) => e.key == _filterKey,
      orElse: () => _allFilter,
    );
    final tokens = showcaseNormalize(_query)
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();

    final list = _items.where((it) {
      if (!_matches(it, filter)) return false;
      if (_onlyVip && it.tier == ShowcaseTier.normal) return false;
      if (_province != null && it.province(_lang) != _province) return false;
      if (tokens.isNotEmpty) {
        final text = it.searchText;
        for (final t in tokens) {
          if (!text.contains(t)) return false;
        }
      }
      return true;
    }).toList();

    int byRecommended(ShowcaseItem a, ShowcaseItem b) {
      final w = b.tierWeight.compareTo(a.tierWeight);
      if (w != 0) return w;
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return a.code.compareTo(b.code);
    }

    switch (_sort) {
      case _Sort.recommended:
        list.sort(byRecommended);
        break;
      case _Sort.name:
        list.sort((a, b) => a.title(_lang).compareTo(b.title(_lang)));
        break;
      case _Sort.rating:
        list.sort((a, b) {
          final r = (b.rating ?? 0).compareTo(a.rating ?? 0);
          return r != 0 ? r : byRecommended(a, b);
        });
        break;
    }
    return list;
  }

  bool get _advancedActive =>
      _sort != _Sort.recommended || _province != null || _onlyVip;

  Future<void> _toggleFav(ShowcaseItem item) async {
    final added = await _favService.toggleFavorite(item.toFavoriteMap());
    if (!mounted) return;
    final id = item.videoUrl ?? item.id;
    setState(() {
      if (added) {
        _favIds.add(id);
      } else {
        _favIds.remove(id);
      }
    });
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // جست‌وجوی پیشرفته (برگه‌ی پایین)
  // ------------------------------------------------------------

  void _openAdvanced() {
    final provinces = _items
        .map((e) => e.province(_lang))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    var tmpSort = _sort;
    String? tmpProvince = _province;
    var tmpVip = _onlyVip;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setSheet) {
              Widget choice(String label, bool selected, VoidCallback onTap) {
                return GestureDetector(
                  onTap: () => setSheet(onTap),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: selected
                          ? const LinearGradient(colors: [Color(0xff29e0ad), Color(0xff3ff0a8)])
                          : null,
                      color: selected ? null : _card,
                      border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? _bg : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              }

              Widget title(String text) => Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(text,
                        style: const TextStyle(color: _goldBright, fontSize: 13.5, fontWeight: FontWeight.bold)),
                  );

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      18, 14, 18, 14 + MediaQuery.of(context).viewInsets.bottom),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(_tr('جست‌وجوی پیشرفته', 'Advanced search', 'بحث متقدم'),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        title(_tr('مرتب‌سازی', 'Sort by', 'ترتيب حسب')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            choice(_tr('پیشنهادی', 'Recommended', 'موصى به'),
                                tmpSort == _Sort.recommended, () => tmpSort = _Sort.recommended),
                            choice(_tr('نام', 'Name', 'الاسم'),
                                tmpSort == _Sort.name, () => tmpSort = _Sort.name),
                            choice(_tr('امتیاز', 'Rating', 'التقييم'),
                                tmpSort == _Sort.rating, () => tmpSort = _Sort.rating),
                          ],
                        ),
                        if (provinces.isNotEmpty) ...[
                          title(_tr('استان / منطقه', 'Province / area', 'المحافظة / المنطقة')),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              choice(_tr('همه', 'All', 'الكل'), tmpProvince == null,
                                  () => tmpProvince = null),
                              for (final p in provinces)
                                choice(p, tmpProvince == p, () => tmpProvince = p),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _gold,
                          value: tmpVip,
                          onChanged: (v) => setSheet(() => tmpVip = v),
                          title: Text(_tr('فقط VIP و ویژه', 'VIP & featured only', 'VIP والمميز فقط'),
                              style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _sort = _Sort.recommended;
                                    _province = null;
                                    _onlyVip = false;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _gold,
                                  side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(_tr('پاک کردن', 'Reset', 'إعادة تعيين')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _sort = tmpSort;
                                    _province = tmpProvince;
                                    _onlyVip = tmpVip;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _gold,
                                  foregroundColor: _bg,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(_tr('اعمال', 'Apply', 'تطبيق'),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ساخت صفحه
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            _info.title(_lang),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: _gold,
            backgroundColor: _card,
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (widget.showHubBanner)
                  SliverToBoxAdapter(
                    child: ShowcaseHubBanner(
                      highlight: widget.kind,
                      onSelect: _openHubSection,
                    ),
                  ),
                SliverToBoxAdapter(child: _searchBar()),
                SliverToBoxAdapter(child: _chips()),
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: CircularProgressIndicator(color: _gold)),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverToBoxAdapter(child: _empty())
                else
                  _grid(visible),
                SliverToBoxAdapter(child: _footer()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: _gold.withValues(alpha: 0.85), size: 21),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        hintText: _info.hint(_lang),
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 12),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.55), size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openAdvanced,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gold.withValues(alpha: _advancedActive ? 0.9 : 0.28)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: _gold, size: 22),
                  ),
                ),
              ),
              if (_advancedActive)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    final filters = [_allFilter, ..._filters];
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = f.opensKind == null && _filterKey == f.key;
          final isLink = f.opensKind != null;
          return GestureDetector(
            onTap: () {
              if (isLink) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ShowcaseGalleryPage(kind: f.opensKind!)),
                );
              } else {
                setState(() => _filterKey = f.key);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xff29e0ad), Color(0xff3ff0a8)])
                    : null,
                color: selected ? null : (isLink ? Colors.transparent : _card),
                border: selected
                    ? null
                    : Border.all(
                        color: isLink ? _gold.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.14),
                      ),
              ),
              child: Text(
                isLink ? '🧭 ${f.label(_lang)}' : f.label(_lang),
                style: TextStyle(
                  color: selected ? _bg : (isLink ? _gold : Colors.white70),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grid(List<ShowcaseItem> visible) {
    final rows = (visible.length + 1) ~/ 2;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, r) {
            final a = r * 2;
            final b = a + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _cardFor(visible[a], a + 1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: b < visible.length
                          ? _cardFor(visible[b], b + 1)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: rows,
        ),
      ),
    );
  }

  Widget _cardFor(ShowcaseItem item, int rank) {
    final showHeart = widget.kind.isVideoLike && item.hasVideo;
    final favId = item.videoUrl ?? item.id;
    return _ShowcaseCard(
      item: item,
      rank: rank,
      lang: _lang,
      icon: _info.icon,
      showHeart: showHeart,
      isFav: _favIds.contains(favId),
      onTap: () => ShowcaseNavigator.open(context, item),
      onFav: () => _toggleFav(item),
    );
  }

  Widget _empty() {
    final isLeader = widget.kind == ShowcaseKind.leader;
    final isAgency = widget.kind == ShowcaseKind.agency;
    final hasFilters = _query.isNotEmpty || _filterKey != 'all' || _advancedActive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
      child: Column(
        children: [
          Icon(_info.icon, size: 44, color: _gold.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(
            _items.isNotEmpty && hasFilters
                ? _tr('نتیجه‌ای با این جست‌وجو پیدا نشد.', 'No results for this search.', 'لا توجد نتائج لهذا البحث.')
                : _info.emptyText(_lang),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13.5, height: 1.7),
          ),
          if (_items.isEmpty && (isLeader || isAgency)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                if (isLeader) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LeaderProfilePage(leader: demoLeader)));
                } else {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgencyProfilePage(agency: demoAgency)));
                }
              },
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: Text(_tr('مشاهده نمونه پروفایل', 'View sample profile', 'عرض نموذج الملف')),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    Widget? join;
    Widget? registerPage;
    String joinText = '';

    switch (widget.kind) {
      case ShowcaseKind.accommodation:
        registerPage = const ResidenceRegisterPage();
        joinText = _tr('ثبت‌نام اقامتگاه شما', 'Register your stay', 'سجّل إقامتك');
        break;
      case ShowcaseKind.leader:
        registerPage = const LeaderRegistrationIntroPage();
        joinText = _tr('ثبت‌نام لیدر', 'Register as a leader', 'سجّل كقائد');
        break;
      case ShowcaseKind.agency:
        registerPage = const AgencyRegistrationIntroPage();
        joinText = _tr('ثبت‌نام آژانس مسافرتی', 'Register your agency', 'سجّل وكالتك');
        break;
      default:
        break;
    }

    if (registerPage != null) {
      final page = registerPage;
      join = Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            icon: const Icon(Icons.how_to_reg_rounded, size: 20),
            label: Text(joinText, style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _bg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }

    Widget social(IconData icon, String label, String url) {
      return Expanded(
        child: Material(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openUrl(url),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.22)),
              ),
              child: Column(
                children: [
                  Icon(icon, color: _gold, size: 20),
                  const SizedBox(height: 3),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 26),
      child: Column(
        children: [
          if (join != null) join,
          if (widget.kind.isVideoLike)
            Row(
              children: [
                social(Icons.ondemand_video_rounded, 'Aparat', _aparatChannel),
                const SizedBox(width: 8),
                social(Icons.camera_alt_rounded, 'Instagram', _instagramUrl),
                const SizedBox(width: 8),
                social(Icons.smart_display_rounded, 'YouTube', _youtubeUrl),
                const SizedBox(width: 8),
                social(Icons.music_note_rounded, 'TikTok', _tiktokUrl),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
// کارت هر آیتم — کاور ۱۶:۹، رتبه، قلب، مدت، عنوان، توضیح، مکان
// ============================================================

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.item,
    required this.rank,
    required this.lang,
    required this.icon,
    required this.showHeart,
    required this.isFav,
    required this.onTap,
    required this.onFav,
  });

  final ShowcaseItem item;
  final int rank;
  final String lang;
  final IconData icon;
  final bool showHeart;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) {
    final title = item.title(lang);
    final desc = item.description(lang);
    final loc = item.location(lang);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.tier == ShowcaseTier.normal
                  ? _gold.withValues(alpha: 0.22)
                  : _gold.withValues(alpha: 0.75),
              width: item.tier == ShowcaseTier.normal ? 1 : 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ShowcaseCover(item: item, fallbackIcon: icon, lang: lang),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0x00000000), Color(0x66000000)],
                          stops: [0, 0.5, 1],
                        ),
                      ),
                    ),
                    if (item.hasVideo)
                      Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xff29e0ad), Color(0xff3ff0a8)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('#$rank',
                            style: const TextStyle(color: _bg, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    if (showHeart)
                      PositionedDirectional(
                        top: 5,
                        end: 5,
                        child: GestureDetector(
                          onTap: onFav,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.5),
                              border: Border.all(color: _gold.withValues(alpha: 0.7)),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? const Color(0xffff6b81) : Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    if (item.tier != ShowcaseTier.normal)
                      PositionedDirectional(
                        bottom: 6,
                        end: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.tier == ShowcaseTier.vip
                                ? 'VIP'
                                : (lang == 'fa' ? 'ویژه' : (lang == 'ar' ? 'مميز' : 'Featured')),
                            style: const TextStyle(color: _bg, fontSize: 9.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.4),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, height: 1.5),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: _gold, size: 14),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              loc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _goldBright, fontSize: 10.5),
                            ),
                          ),
                          if (item.rating != null && item.rating! > 0) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: _gold, size: 14),
                            Text(item.rating!.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                          ],
                        ],
                      ),
                    ],
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
