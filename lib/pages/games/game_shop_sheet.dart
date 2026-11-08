import 'package:flutter/material.dart';

import '../groups/group_ui.dart';
import 'game_api.dart';
import 'dice_games.dart' show sharedDieSkin;
import 'dice_skins.dart';
import 'game_board.dart';
import 'game_texts.dart';

class _Item {
  const _Item(this.key, this.code, this.price, this.level, this.isIcon, {this.isDice = false});
  final String key;
  final String code;
  final int price;
  final int level;
  final bool isIcon;
  final bool isDice;
}

// همان فهرست و قیمت‌های سرور؛ سرور هنگام خرید دوباره بررسی می‌کند.
const List<_Item> _icons = [
  _Item('icon_lion', 'lion', 0, 1, true),
  _Item('icon_camel', 'camel', 120, 2, true),
  _Item('icon_deer', 'deer', 250, 3, true),
  _Item('icon_boat', 'boat', 400, 4, true),
  _Item('icon_eagle', 'eagle', 600, 5, true),
];
const List<_Item> _themes = [
  _Item('theme_classic', 'classic', 0, 1, false),
  _Item('theme_persepolis', 'persepolis', 150, 2, false),
  _Item('theme_desert', 'desert', 300, 3, false),
  _Item('theme_forest', 'forest', 450, 4, false),
  _Item('theme_caspian', 'caspian', 600, 5, false),
];

// تاس‌ها: خرید از سرور (فهرست dice_*)، انتخاب روی همین گوشی ذخیره می‌شود.
final List<_Item> _dice = <_Item>[
  for (final d in DiceSkins.all) _Item(d.key, d.code, d.price, d.level, false, isDice: true),
];

Future<void> showGameShop(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: gPanel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ShopSheet(),
  );
}

class _ShopSheet extends StatefulWidget {
  const _ShopSheet();
  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> {
  final GameWallet _w = GameWallet.instance;
  String _busy = '';

  @override
  void initState() {
    super.initState();
    _w.addListener(_onChange);
    DiceSkins.current.addListener(_onChange);
  }

  @override
  void dispose() {
    _w.removeListener(_onChange);
    DiceSkins.current.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _act(_Item it) async {
    if (_busy.isNotEmpty) return;
    if (it.isDice && (it.price == 0 || _w.owned.contains(it.key))) {
      await DiceSkins.select(it.code);
      return;
    }
    setState(() => _busy = it.key);
    final owned = _w.owned.contains(it.key);
    final e = it.isDice ? (owned ? '' : await _w.buy(it.key)) : (owned ? await _w.equip(it.key) : await _w.buy(it.key));
    if (!mounted) return;
    setState(() => _busy = '');
    if (e.isEmpty) {
      if (!owned) {
        gToast(context, GameT.t('bought'));
        if (it.isDice) {
          await DiceSkins.select(it.code);
        } else {
          await _w.equip(it.key);
        }
      }
    } else if (e == 'no_coins') {
      gToast(context, GameT.t('no_coins'));
    } else if (e == 'level_low') {
      gToast(context, GameT.t('need_level', <String, String>{'n': '${it.level}'}));
    } else if (e == 'not_registered' || e == 'no_name' || e == 'auth_required') {
      gToast(context, GameT.t('need_profile'));
    } else {
      gToast(context, GameT.t('net_err'));
    }
  }

  Widget _tile(_Item it) {
    final owned = _w.owned.contains(it.key) || (it.isDice && it.price == 0);
    final equipped = it.isDice ? DiceSkins.current.value == it.code : (it.isIcon ? _w.equippedIcon == it.code : _w.equippedTheme == it.code);
    final locked = !owned && _w.level < it.level;
    final th = GameTheme.byCode(it.code);
    String label;
    if (equipped) {
      label = GameT.t('equipped');
    } else if (owned) {
      label = GameT.t('equip');
    } else if (locked) {
      label = GameT.t('need_level', <String, String>{'n': '${it.level}'});
    } else {
      label = '🪙 ${it.price}  ${GameT.t('buy')}';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: gBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: equipped ? gGold : gLine, width: equipped ? 1.8 : 1),
      ),
      child: Row(
        children: [
          if (it.isDice)
            sharedDieSkin(it.code, size: 38)
          else if (it.isIcon)
            Text(kGameIconEmoji[it.code] ?? '🦁', style: const TextStyle(fontSize: 30))
          else
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: th.board, borderRadius: BorderRadius.circular(9), border: Border.all(color: th.line, width: 2)),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              it.isDice ? (GameT.fa ? DiceSkins.byCode(it.code).faName : DiceSkins.byCode(it.code).enName) : GameT.t(it.key),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: equipped ? gTeal : gGold,
              foregroundColor: gBg,
              disabledBackgroundColor: gLine,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: (equipped || locked || _busy.isNotEmpty) ? null : () => _act(it),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        child: Text(t, style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: gDir,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              children: [
                Text(GameT.t('shop'), style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 18)),
                const Spacer(),
                Text('🪙 ${_w.coins}', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            _head(GameT.t('icons')),
            for (final it in _icons) _tile(it),
            _head(GameT.t('themes')),
            for (final it in _themes) _tile(it),
            _head(GameT.fa ? 'تاس‌ها' : 'Dice'),
            for (final it in _dice) _tile(it),
          ],
        ),
      ),
    );
  }
}
