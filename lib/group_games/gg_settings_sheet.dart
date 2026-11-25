import 'package:flutter/material.dart';

import '../pages/games/game_economy.dart';
import '../pages/games/game_wheel.dart' show wFa;
import '../pages/groups/group_ui.dart';
import 'gg_prefs.dart';

/// تنظیمات، فروشگاه رنگ و تم، و ارتقاها (با سکه‌ی همان کیف پول بازی‌ها).
Future<void> showGgSettings(BuildContext context, String game) async {
  await GgPrefs.instance.load();
  await GameEconomy.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: gPanel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Directionality(textDirection: gDir, child: _GgSettings(game: game)),
  );
}

class _GgSettings extends StatefulWidget {
  const _GgSettings({required this.game});
  final String game;

  @override
  State<_GgSettings> createState() => _GgSettingsState();
}

class _GgSettingsState extends State<_GgSettings> {
  final GgPrefs p = GgPrefs.instance;
  bool get _hockey => widget.game == 'hockey';

  void _set(VoidCallback f) {
    setState(f);
    p.save();
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 14.5)),
      );

  Widget _switch(String t, bool v, ValueChanged<bool> on) => SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        value: v,
        activeColor: gGold,
        title: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
        onChanged: (x) => _set(() => on(x)),
      );

  Widget _seg(List<String> labels, int cur, ValueChanged<int> on) => Wrap(
        spacing: 6,
        children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i], style: TextStyle(color: cur == i ? gBg : Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
              selected: cur == i,
              selectedColor: gGold,
              backgroundColor: gBg,
              onSelected: (_) => _set(() => on(i)),
            ),
        ],
      );

  Widget _colors(int cur, ValueChanged<int> on) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < GgPrefs.palette.length; i++)
          GestureDetector(
            onTap: () async {
              if (!p.ownsColor(i)) {
                final ok = await p.buyColor(context, i);
                if (!ok || !mounted) return;
              }
              _set(() => on(i));
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GgPrefs.palette[i],
                border: Border.all(color: cur == i ? Colors.white : Colors.white24, width: cur == i ? 3 : 1),
              ),
              child: p.ownsColor(i) ? (cur == i ? const Icon(Icons.check_rounded, color: Colors.black87, size: 20) : null) : const Icon(Icons.lock_rounded, color: Colors.black87, size: 17),
            ),
          ),
      ],
    );
  }

  Widget _themes(List<String> names, int cur, ValueChanged<int> on) {
    final g = _hockey ? 'hk' : 'gf';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < names.length; i++)
          ChoiceChip(
            avatar: p.ownsTheme(g, i) ? null : const Icon(Icons.lock_rounded, size: 14, color: gGold),
            label: Text(names[i], style: TextStyle(color: cur == i ? gBg : Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
            selected: cur == i,
            selectedColor: gGold,
            backgroundColor: gBg,
            onSelected: (_) async {
              if (!p.ownsTheme(g, i)) {
                final ok = await p.buyTheme(context, g, i, names[i]);
                if (!ok || !mounted) return;
              }
              _set(() => on(i));
            },
          ),
      ],
    );
  }

  Widget _upgrade(String k) {
    final lv = p.lvl(k);
    final max = lv >= GgPrefs.maxLevel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: gBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: gLine)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(GgPrefs.upTitles[k]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text(GgPrefs.upDescs[k]!, style: const TextStyle(color: gMuted, fontSize: 11.5)),
                const SizedBox(height: 4),
                Row(children: [
                  for (var i = 0; i < GgPrefs.maxLevel; i++)
                    Container(width: 18, height: 6, margin: const EdgeInsetsDirectional.only(end: 3), decoration: BoxDecoration(color: i < lv ? gGold : Colors.white12, borderRadius: BorderRadius.circular(3))),
                ]),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: max ? Colors.white12 : gTeal, foregroundColor: gBg, minimumSize: const Size(88, 40)),
            onPressed: max
                ? null
                : () async {
                    final ok = await p.upgrade(context, k);
                    if (ok && mounted) setState(() {});
                  },
            child: Text(max ? 'کامل' : '${wFa(p.upCost(k))} 🪙', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      minChildSize: .5,
      maxChildSize: .95,
      builder: (_, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(_hockey ? 'تنظیمات هاکی روی میز' : 'تنظیمات مینی‌گلف', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17))),
              Text('${wFa(GameEconomy.balance)} 🪙', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          if (_hockey) ...[
            _h('تم میز'),
            _themes(GgPrefs.hkThemeNames, p.hkTheme, (i) => p.hkTheme = i),
            _h('رنگ دسته‌ی شما'),
            _colors(p.hkMallet, (i) => p.hkMallet = i),
            _h('رنگ توپ'),
            _colors(p.hkPuck, (i) => p.hkPuck = i),
            _h('سرعت توپ'),
            _seg(const <String>['کند', 'معمولی', 'تند'], p.hkSpeed, (i) => p.hkSpeed = i),
            _switch('دنباله‌ی نورانی توپ', p.hkTrail, (v) => p.hkTrail = v),
            _switch('افکت برخورد و گل', p.hkFx, (v) => p.hkFx = v),
          ] else ...[
            _h('تم زمین'),
            _themes(GgPrefs.gfThemeNames, p.gfTheme, (i) => p.gfTheme = i),
            _h('رنگ توپ شما'),
            _colors(p.gfBall, (i) => p.gfBall = i),
            _switch('خط هدف‌گیری', p.gfAim, (v) => p.gfAim = v),
            _switch('نمایش نام روی توپ‌ها', p.gfNames, (v) => p.gfNames = v),
            _h('حساسیت کشیدن (${wFa(p.gfSens)}٪)'),
            Slider(value: p.gfSens.toDouble(), min: 50, max: 150, divisions: 10, activeColor: gGold, onChanged: (v) => _set(() => p.gfSens = v.round())),
          ],
          _h('صدا و کیفیت'),
          Row(children: [
            const Icon(Icons.volume_up_rounded, color: gMuted, size: 20),
            Expanded(child: Slider(value: p.vol.toDouble(), min: 0, max: 100, activeColor: gGold, onChanged: (v) => _set(() => p.vol = v.round()))),
          ]),
          _switch('بی‌صدا', p.mute, (v) => p.mute = v),
          _switch('لرزش', p.vib, (v) => p.vib = v),
          const SizedBox(height: 4),
          const Text('کیفیت گرافیک (برای گوشی‌های ضعیف «کم» بگذارید)', style: TextStyle(color: gMuted, fontSize: 12)),
          const SizedBox(height: 6),
          _seg(const <String>['کم', 'بالا'], p.quality, (i) => p.quality = i),
          _h('ارتقاها (فقط در حالت تک‌نفره با ربات اثر دارند)'),
          if (_hockey) ...[_upgrade('hk_size'), _upgrade('hk_power')] else ...[_upgrade('gf_power'), _upgrade('gf_aim')],
          const SizedBox(height: 6),
          const Text('سکه را از برد در بازی‌ها، گردونه و معرفی دوستان می‌گیرید. در مسابقه‌ی چندنفره فقط ظاهر (رنگ و تم) اعمال می‌شود تا رقابت عادلانه بماند.', style: TextStyle(color: gMuted, fontSize: 11.5, height: 1.8)),
        ],
      ),
    );
  }
}
