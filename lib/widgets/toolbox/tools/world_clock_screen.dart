import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/world_clock_service.dart';

const _kBg = Color(0xff071722);
const _kCard1 = Color(0xff173747);
const _kCard2 = Color(0xff0b202c);
const _kGold = Color(0xffffd76a);

/// این صفحه دو ابزار «ساعت جهانی» و «زمان محلی مقصد» را در قالب دو تب
/// ادغام می‌کند، چون از نظر عملکردی یک قابلیت واحدند: نمایش ساعت دقیق
/// شهرهای مختلف با احتساب تغییر ساعت تابستانی/زمستانی — یکی با لیست
/// آماده، دیگری با جستجوی مقصد دلخواه.
class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _ticker;
  DateTime _tick = DateTime.now();

  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _allTz = [];
  List<String> _filtered = [];
  String? _selectedTz;

  @override
  void initState() {
    super.initState();
    WorldClockService.init();
    _tabController = TabController(length: 2, vsync: this);
    _allTz = WorldClockService.allTimezoneIds();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = [];
      } else {
        _filtered = _allTz
            .where((tzId) =>
                tzId.toLowerCase().contains(q.toLowerCase().trim()))
            .take(30)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kGold),
          title: const Text(
            'ساعت جهانی',
            style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: _kGold,
            labelColor: _kGold,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'شهرهای پرکاربرد'),
              Tab(text: 'جستجوی مقصد'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCityList(WorldClockService.defaultCities),
              _buildDestinationSearch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityList(List<WorldCityInfo> cities) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _cityTile(cities[i]),
    );
  }

  Widget _cityTile(WorldCityInfo c) {
    final now = WorldClockService.nowIn(c.timezoneId);
    final diff = WorldClockService.offsetDiffHoursFromDevice(c.timezoneId);
    final diffText = diff == 0
        ? 'هم‌زمان با شما'
        : (diff > 0
            ? '${diff.toStringAsFixed(1)} ساعت جلوتر'
            : '${diff.abs().toStringAsFixed(1)} ساعت عقب‌تر');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCard1, _kCard2],
        ),
        border: Border.all(color: _kGold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(c.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.city,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(diffText,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
                color: _kGold, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'مثلاً Tehran یا Paris یا Dubai',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.public_rounded, color: _kGold),
              filled: true,
              fillColor: _kCard1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_selectedTz != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _cityTile(
              WorldCityInfo(
                city: _selectedTz!.split('/').last.replaceAll('_', ' '),
                country: '',
                flag: '📍',
                timezoneId: _selectedTz!,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final tzId = _filtered[i];
              return ListTile(
                iconColor: _kGold,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(tzId.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedTz = tzId;
                    _filtered = [];
                    _searchCtrl.clear();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
