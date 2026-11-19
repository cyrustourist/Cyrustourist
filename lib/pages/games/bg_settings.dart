import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'bg_score.dart';
import 'game_economy.dart';
import 'bg_sfx.dart';
import 'bg_theme.dart';

/// متن «آموزش بازی» تخته‌نرد (در تنظیمات، زبانه‌ی آموزش)
const List<List<String>> kBgGuide = <List<String>>[
  <String>['هدف بازی', 'هر بازیکن ۱۵ مهره دارد. برنده کسی است که زودتر همه‌ی مهره‌هایش را از تخته بیرون ببرد.'],
  <String>['جهت حرکت', 'بازیکن اول (مهره‌های روشن) از بالای تخته به سمت پایین چپ و بازیکن دوم در جهت مخالف حرکت می‌کند. خانه‌ی هر بازیکن، آخرین شش خانه‌ی مسیر اوست و مهره‌ها فقط از همان‌جا بیرون می‌روند.'],
  <String>['تاس انداختن', 'در هر نوبت دو تاس می‌اندازید. هر تاس یک حرکت جداگانه است؛ می‌توانید یک مهره را با هر دو تاس یا دو مهره‌ی مختلف را با هر کدام حرکت دهید.'],
  <String>['جفت (دبل)', 'اگر هر دو تاس یکی بیاید (مثلاً ۴ و ۴) چهار حرکت با همان عدد دارید.'],
  <String>['خانه‌ی بسته', 'روی خانه‌ای که دو مهره یا بیشتر از حریف دارد نمی‌شود رفت. روی خانه‌ی خالی، خانه‌ی خودتان یا خانه‌ای که فقط یک مهره‌ی حریف دارد می‌شود رفت.'],
  <String>['زدن مهره', 'اگر روی تک‌مهره‌ی حریف بروید، آن مهره زده می‌شود و روی میله‌ی وسط می‌نشیند.'],
  <String>['مهره روی میله', 'تا مهره‌ای روی میله دارید نمی‌توانید مهره‌ی دیگری حرکت دهید. باید با تاس خود آن را به خانه‌ی شروع حریف برگردانید. اگر خانه‌ی ورود بسته بود، نوبت از دست می‌رود.'],
  <String>['بیرون بردن مهره', 'وقتی هر ۱۵ مهره‌ی شما در خانه‌ی خودتان بود می‌توانید بیرون ببرید. عدد تاس باید برابر فاصله‌ی مهره تا بیرون باشد. اگر عدد بزرگ‌تر آمد و مهره‌ای دورتر از آن نداشتید، از دورترین مهره بیرون می‌برید.'],
  <String>['بیشترین تاس', 'اگر می‌توانید هر دو تاس را بازی کنید، موظفید هر دو را بازی کنید. اگر فقط یکی شدنی است، باید بزرگ‌تر را بازی کنید (اگر هر دو ممکن نبود).'],
  <String>['امتیاز: برد ساده', 'حریف دست‌کم یک مهره بیرون برده است: ۱ امتیاز.'],
  <String>['امتیاز: گمون', 'حریف هیچ مهره‌ای بیرون نبرده است: ۲ امتیاز.'],
  <String>['امتیاز: بک‌گمون', 'گمون شده و حریف هنوز مهره‌ای روی میله یا در خانه‌ی شما دارد: ۳ امتیاز.'],
  <String>['شمارش پیپ', 'پیپ یعنی مجموع فاصله‌ی همه‌ی مهره‌ها تا بیرون رفتن. هر چه کمتر باشد جلوترید. مهره‌ی روی میله ۲۵ پیپ حساب می‌شود.'],
  <String>['مسابقه تا چند امتیاز', 'در تنظیمات می‌توانید هدف مسابقه را (۳، ۵، ۷ …) انتخاب کنید. بازی‌ها پشت سر هم انجام می‌شود و هر کس اول به هدف برسد مسابقه را می‌برد. بدون مسابقه، فقط جمع امتیازها نگه داشته می‌شود.'],
  <String>['قانون کرافورد', 'وقتی کسی یک امتیاز تا هدف مانده، در بازی بعد فقط نشانگر «کرافورد» دیده می‌شود. در این نسخه مکعب دوبل ندارد و فقط نشانگر برای آشنایی است.'],
  <String>['کنترل بازی', 'روی مهره بزنید تا مقصدهای ممکن طلایی شود، بعد روی مقصد بزنید. برای بیرون بردن، روی مهره‌ی داخل خانه‌ی خودتان و بعد روی «خروج مهره» بزنید.'],
  <String>['چت و زمان', 'در بازی دونفره‌ی شبکه‌ای می‌توانید از جمله‌های آماده یا متن دلخواه استفاده کنید. اگر زمان نوبت تمام شود حرکت خودکار انجام می‌شود.'],
];

Future<void> showBgSettings(BuildContext context, {VoidCallback? onChanged}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BgSettingsSheet(onChanged: onChanged),
  );
}

class _BgSettingsSheet extends StatefulWidget {
  const _BgSettingsSheet({this.onChanged});
  final VoidCallback? onChanged;

  @override
  State<_BgSettingsSheet> createState() => _BgSettingsSheetState();
}

class _BgSettingsSheetState extends State<_BgSettingsSheet> {
  final BgPrefs p = BgPrefs.instance;

  @override
  void initState() {
    super.initState();
    GameEconomy.load().then((_) {
      if (mounted) setState(() {});
    });
  }
  void _chg() {
    p.save();
    widget.onChanged?.call();
    setState(() {});
  }

  Widget _title(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(t, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)));

  Widget _sw(String t, bool v, ValueChanged<bool> f) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: gLine)),
        child: SwitchListTile(
          value: v,
          onChanged: f,
          activeColor: gGold,
          title: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _boards() {
    return Column(children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('موجودی تو: ${bgFa(GameEconomy.balance)} 🪙 · صفحه‌های قفل را با سکه باز کن', style: const TextStyle(color: gMuted, fontSize: 12.5))),
      _boardGrid(),
    ]);
  }

  Widget _boardGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kBgThemes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .66),
      itemBuilder: (_, i) {
        final sel = p.board == i;
        return GestureDetector(
          onTap: () async {
            final price = kBgThemePrice[i];
            if (price > 0 && !GameEconomy.isOwned('bg_board_$i') && p.board != i) {
              final ok = await GameEconomy.buy(context, 'bg_board_$i', price, 'صفحه «${kBgThemes[i].label}»');
              if (!ok) return;
            }
            p.board = i;
            BgSfx.click();
            _chg();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? gGold : gLine, width: sel ? 2.4 : 1),
              boxShadow: sel ? const <BoxShadow>[BoxShadow(color: Color(0x66ffd36a), blurRadius: 14)] : const <BoxShadow>[BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
                Expanded(child: Center(child: BgBoardPreview(theme: kBgThemes[i], width: 118))),
                const SizedBox(height: 6),
                Text(kBgThemes[i].label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? gGold : Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                if (sel)
                  const Icon(Icons.check_circle, color: gGold, size: 18)
                else if (kBgThemePrice[i] > 0 && !GameEconomy.isOwned('bg_board_$i'))
                  Text('🔒 ${bgFa(kBgThemePrice[i])} 🪙', style: const TextStyle(color: gGold, fontWeight: FontWeight.w800, fontSize: 12.5))
                else
                  const Icon(Icons.lock_open_rounded, color: gMuted, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sound() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sw('صدا روشن باشد', !p.mute, (v) {
          p.mute = !v;
          _chg();
        }),
        _sw('لرزش هنگام تاس و حرکت', p.vib, (v) {
          p.vib = v;
          _chg();
        }),
        _title('بلندی صدا: ${bgFa(p.vol)}'),
        Slider(
          value: p.vol.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: gGold,
          onChanged: (v) {
            p.vol = v.round();
            setState(() {});
          },
          onChangeEnd: (_) {
            _chg();
            BgSfx.move();
          },
        ),
        _title('امتحان صدا'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tryBtn('تاس انداختن', BgSfx.diceRoll),
            _tryBtn('نشستن تاس', BgSfx.diceLand),
            _tryBtn('حرکت مهره', BgSfx.move),
            _tryBtn('زدن مهره', BgSfx.hit),
            _tryBtn('خروج مهره', BgSfx.bearOff),
            _tryBtn('پیام چت', BgSfx.chat),
            _tryBtn('برد', BgSfx.win),
            _tryBtn('باخت', BgSfx.lose),
          ],
        ),
      ],
    );
  }

  Widget _tryBtn(String t, VoidCallback f) => ActionChip(
        backgroundColor: gPanel,
        side: const BorderSide(color: gLine),
        label: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        avatar: const Icon(Icons.volume_up_rounded, size: 18, color: gGold),
        onPressed: f,
      );

  Widget _score() {
    const opts = <int>[0, 3, 5, 7, 9, 11, 15, 21];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('طول مسابقه'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in opts)
              ChoiceChip(
                selected: p.matchTo == o,
                selectedColor: gGold,
                backgroundColor: gPanel,
                side: const BorderSide(color: gLine),
                label: Text(o == 0 ? 'بدون مسابقه (جمع امتیاز)' : 'تا ${bgFa(o)} امتیاز', style: TextStyle(color: p.matchTo == o ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
                onSelected: (_) {
                  p.matchTo = o;
                  _chg();
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('تغییر طول مسابقه از بازی بعد اثر می‌کند.', style: TextStyle(color: gMuted, fontSize: 12)),
        const SizedBox(height: 10),
        _sw('نمایش شمارش پیپ بالای تخته', p.showPip, (v) {
          p.showPip = v;
          _chg();
        }),
        _title('آمار شما'),
        AnimatedBuilder(animation: BgStats.instance, builder: (_, __) => const BgStatsView()),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            await BgStats.instance.clear();
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.delete_outline, color: Color(0xffff8a65)),
          label: const Text('پاک کردن آمار', style: TextStyle(color: Color(0xffff8a65))),
        ),
      ],
    );
  }

  Widget _guide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < kBgGuide.length; i++)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: gPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: gLine)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${bgFa(i + 1)}. ${kBgGuide[i][0]}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(kBgGuide[i][1], style: const TextStyle(color: Colors.white, height: 1.7, fontSize: 13.5)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * .88,
          decoration: const BoxDecoration(
            color: gBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: <BoxShadow>[BoxShadow(color: Colors.black87, blurRadius: 24)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 44, height: 5, decoration: BoxDecoration(color: gLine, borderRadius: BorderRadius.circular(3))),
              const Padding(padding: EdgeInsets.only(top: 10), child: Text('تنظیمات تخته‌نرد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
              const TabBar(
                isScrollable: true,
                indicatorColor: gGold,
                labelColor: gGold,
                unselectedLabelColor: gMuted,
                labelStyle: TextStyle(fontWeight: FontWeight.w800),
                tabs: <Widget>[Tab(text: 'صفحه بازی'), Tab(text: 'صدا'), Tab(text: 'امتیاز و آمار'), Tab(text: 'آموزش بازی')],
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    for (final w in <Widget>[_boards(), _sound(), _score(), _guide()]) SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 28), child: w),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
