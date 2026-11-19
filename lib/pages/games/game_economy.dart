import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/group_ui.dart';
import 'game_api.dart';
import 'game_wheel.dart';

/// لایه‌ی مشترک سکه برای همه‌ی بازی‌ها:
/// موجودی کل (سرور + محلی)، جایزه‌ی برد، خرج کردن برای راهنما و بازگشت به مرحله‌ی قبل، و قفل‌وخرید ظاهر بازی‌ها.
class GameEconomy {
  GameEconomy._();

  // قیمت‌ها (سکه) — اینجا عوض کنید
  static const int hintCost = 15;
  static const int undoCost = 10;
  static const int extraTimeCost = 10;

  /// جایزه‌ی برد بر اساس سختی؛ بازی روی یک گوشی (local) سکه ندارد
  static const Map<String, int> winCoins = <String, int>{'easy': 50, 'normal': 50, 'hard': 50, 'nearby': 50, 'online': 50, 'local': 0};
  static const int drawCoins = 2;
  static const int dailyCap = 1000;

  static const String _k = 'cyrus_econ_v1';
  static bool _loaded = false;
  static final Set<String> _owned = <String>{};
  static String _day = '';
  static int _dayEarned = 0;

  static Future<void> load() async {
    if (_loaded) return;
    await WheelStore.instance.load();
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _owned
          ..clear()
          ..addAll(((m['owned'] as List?) ?? const <dynamic>[]).map((e) => '$e'));
        _day = (m['day'] as String?) ?? '';
        _dayEarned = (m['earned'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode(<String, dynamic>{'owned': _owned.toList(), 'day': _day, 'earned': _dayEarned}));
    } catch (_) {}
  }

  /// موجودی کل: سکه‌ی کیف پول سرور + سکه‌ی محلی (گردونه، معرفی، جایزه‌ی برد) منهای خرج‌ها
  static int get balance {
    final v = GameWallet.instance.coins + WheelStore.instance.net;
    return v < 0 ? 0 : v;
  }

  static bool canAfford(int n) => balance >= n;

  static bool isOwned(String key) => _owned.contains(key);

  /// خرج کردن؛ اگر موجودی کم بود پیام می‌دهد و false برمی‌گرداند.
  static Future<bool> pay(BuildContext context, int cost, String what) async {
    await load();
    if (!canAfford(cost)) {
      if (context.mounted) gToast(context, 'سکه‌ات کافی نیست (${wFa(cost)} 🪙). از گردونه یا معرفی به دوستان سکه بگیر');
      return false;
    }
    await WheelStore.instance.spend(cost);
    if (context.mounted) gToast(context, '−${wFa(cost)} 🪙  $what');
    return true;
  }

  /// خرید دائمی یک آیتم (ظاهر صفحه و ...)
  static Future<bool> buy(BuildContext context, String key, int price, String name) async {
    await load();
    if (_owned.contains(key)) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: gDir,
        child: AlertDialog(
          backgroundColor: gPanel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: gGold)),
          title: Text('خرید $name', style: const TextStyle(color: gGold, fontWeight: FontWeight.w900)),
          content: Text('قیمت: ${wFa(price)} 🪙\nموجودی تو: ${wFa(balance)} 🪙', style: const TextStyle(color: Colors.white, height: 1.8)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('انصراف', style: TextStyle(color: gMuted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: gGold, foregroundColor: gBg),
              onPressed: canAfford(price) ? () => Navigator.of(context).pop(true) : null,
              child: Text(canAfford(price) ? 'بخر' : 'سکه کافی نیست', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return false;
    await WheelStore.instance.spend(price);
    _owned.add(key);
    await _save();
    if (context.mounted) gToast(context, '✓ $name خریداری شد');
    return true;
  }

  /// جایزه‌ی پایان بازی (برای همه‌ی بازی‌ها از GameWallet.reportOffline صدا زده می‌شود). خروجی: سکه‌ی گرفته‌شده.
  static Future<int> winBonus(String result, String level) async {
    await load();
    var n = 0;
    if (result == 'win') {
      n = winCoins[level] ?? 50;
    } else if (result == 'draw' && level != 'local') {
      n = drawCoins;
    }
    if (n <= 0) return 0;
    final today = WheelStore.dayKey(DateTime.now());
    if (_day != today) {
      _day = today;
      _dayEarned = 0;
    }
    if (_dayEarned >= dailyCap) return 0;
    if (_dayEarned + n > dailyCap) n = dailyCap - _dayEarned;
    _dayEarned += n;
    await WheelStore.instance.addCoins(n);
    await _save();
    return n;
  }
}

/// دکمه‌ی کمکی با قیمت سکه (راهنما، بازگشت و ...)
Widget gameHelpButton({required IconData icon, required String label, required int cost, required VoidCallback? onTap}) {
  return OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: onTap == null ? gLine : gGold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: onTap == null ? gMuted : gGold),
    label: Text('$label  ${wFa(cost)}🪙', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: onTap == null ? gMuted : Colors.white)),
  );
}

/// نوار راهنما و کمک: دکمه‌ها به‌علاوه‌ی موجودی
Widget gameHelpRow(List<Widget> buttons) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      children: [
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: buttons),
        const SizedBox(height: 4),
        Text('موجودی: ${wFa(GameEconomy.balance)} 🪙', style: const TextStyle(color: gMuted, fontSize: 11.5)),
      ],
    ),
  );
}
