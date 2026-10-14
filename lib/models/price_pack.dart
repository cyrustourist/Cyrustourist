import 'dart:convert';

/// ===============================================================
/// پک قیمت و آفر اقامتگاه (هماهنگ با ستون price_pack در ورکر)
/// ---------------------------------------------------------------
/// قیمت‌ها «تومان» و «برای هر شب» هستند.
/// ظرفیت پایه: قیمت برای همین تعداد نفر است؛ هر نفر اضافه [extra] تومان در شب.
/// ===============================================================

enum PriceDay { weekday, weekend, peak }

int _i(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is num) return v.round();
  final s = _asciiDigits(v.toString()).replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(s) ?? def;
}

String _asciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(r - 0x06F0 + 48);
    } else if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(r - 0x0660 + 48);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

class PriceUnit {
  PriceUnit({
    required this.id,
    this.name = '',
    this.base = 2,
    this.max = 3,
    this.wd = 0,
    this.we = 0,
    this.pk = 0,
    this.extra = 0,
    this.minPk = 1,
    this.disc = 0,
    this.open = true,
  });

  String id;
  String name;
  int base;
  int max;
  int wd;
  int we;
  int pk;
  int extra;
  int minPk;
  int disc;
  bool open;

  factory PriceUnit.fromJson(Map<dynamic, dynamic> j) => PriceUnit(
        id: '${j['id'] ?? ''}'.isEmpty ? 'u${DateTime.now().microsecondsSinceEpoch}' : '${j['id']}',
        name: '${j['name'] ?? ''}',
        base: _i(j['base'], 2),
        max: _i(j['max'], 3),
        wd: _i(j['wd']),
        we: _i(j['we']),
        pk: _i(j['pk']),
        extra: _i(j['extra']),
        minPk: _i(j['minPk'], 1),
        disc: _i(j['disc']),
        open: !(j['open'] == false || j['open'] == 0 || j['open'] == '0'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name.trim(),
        'base': base,
        'max': max,
        'wd': wd,
        'we': we,
        'pk': pk,
        'extra': extra,
        'minPk': minPk,
        'disc': disc,
        'open': open,
      };

  PriceUnit copy() => PriceUnit.fromJson(toJson());

  int priceFor(PriceDay d) {
    switch (d) {
      case PriceDay.weekday:
        return wd;
      case PriceDay.weekend:
        return we;
      case PriceDay.peak:
        return pk;
    }
  }

  /// کد خطا (برای نمایش پیام) یا null اگر معتبر است
  String? get error {
    if (name.trim().length < 2) return 'name';
    if (base < 1 || base > 50) return 'cap';
    if (max < base || max > 60) return 'cap';
    if (wd < 1000 || we < 1000 || pk < 1000) return 'price';
    if (max > base && extra <= 0) return 'extra';
    if (minPk < 1 || minPk > 30) return 'minPk';
    if (disc < 0 || disc > 50) return 'disc';
    return null;
  }
}

class PricePromo {
  PricePromo({this.on = false, this.pct = 20, this.text = ''});

  bool on;
  int pct;
  String text;

  factory PricePromo.fromJson(dynamic j) {
    if (j is! Map) return PricePromo();
    return PricePromo(on: j['on'] == true || j['on'] == 1 || j['on'] == '1', pct: _i(j['pct'], 20), text: '${j['text'] ?? ''}');
  }

  Map<String, dynamic> toJson() => {'on': on, 'pct': pct, 'text': text.trim()};

  bool get active => on && pct > 0 && pct <= 70;

  String? get error {
    if (!on) return null;
    if (pct < 1 || pct > 70) return 'pct';
    if (text.trim().isEmpty) return 'text';
    return null;
  }
}

class PriceQuote {
  const PriceQuote({
    required this.perNight,
    required this.extraPerNight,
    required this.subtotal,
    required this.promoOff,
    required this.longOff,
    required this.total,
  });

  final int perNight;
  final int extraPerNight;
  final int subtotal;
  final int promoOff;
  final int longOff;
  final int total;
}

class PricePack {
  PricePack({List<PriceUnit>? units, PricePromo? promo, this.updatedAt})
      : units = units ?? <PriceUnit>[],
        promo = promo ?? PricePromo();

  final List<PriceUnit> units;
  final PricePromo promo;
  final String? updatedAt;

  factory PricePack.empty() => PricePack(units: [PriceUnit(id: 'u1')], promo: PricePromo());

  static PricePack? tryParse(dynamic v) {
    try {
      dynamic d = v;
      if (d is String) {
        if (d.trim().isEmpty) return null;
        d = jsonDecode(d);
      }
      if (d is! Map || d['units'] is! List) return null;
      final units = (d['units'] as List).whereType<Map>().map(PriceUnit.fromJson).toList();
      if (units.isEmpty) return null;
      return PricePack(units: units, promo: PricePromo.fromJson(d['promo']), updatedAt: d['updated_at']?.toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'units': units.map((u) => u.toJson()).toList(),
        'promo': promo.toJson(),
      };

  PricePack copy() => PricePack(units: units.map((u) => u.copy()).toList(), promo: PricePromo(on: promo.on, pct: promo.pct, text: promo.text), updatedAt: updatedAt);

  /// null = معتبر؛ در غیر این صورت کد خطا
  String? get error {
    if (units.isEmpty || units.length > 6) return 'units';
    for (final u in units) {
      final e = u.error;
      if (e != null) return e;
    }
    return promo.error == null ? null : 'promo';
  }

  bool get isValid => error == null;

  /// شمارهٔ (از صفر) اولین واحدی که خطا دارد؛ اگر خطا مربوط به آفر باشد یا خطایی نباشد -1
  int get errorUnit {
    if (units.isEmpty || units.length > 6) return -1;
    for (var i = 0; i < units.length; i++) {
      if (units[i].error != null) return i;
    }
    return -1;
  }

  /// قیمت پس از آفر
  int afterPromo(int n) => promo.active ? (n * (100 - promo.pct) / 100).round() : n;

  /// «قیمت از» (کمترین قیمت شب واحدهای موجود) پیش از آفر
  int? get fromPriceOld {
    final open = units.where((u) => u.open && u.wd > 0 && u.we > 0);
    if (open.isEmpty) return null;
    var m = open.first.wd < open.first.we ? open.first.wd : open.first.we;
    for (final u in open) {
      final x = u.wd < u.we ? u.wd : u.we;
      if (x < m) m = x;
    }
    return m;
  }

  int? get fromPrice {
    final o = fromPriceOld;
    return o == null ? null : afterPromo(o);
  }

  PriceQuote quote(PriceUnit u, int guests, int nights, PriceDay day) {
    final n = nights < 1 ? 1 : nights;
    final g = guests < 1 ? 1 : guests;
    final extraPer = (g > u.base ? g - u.base : 0) * u.extra;
    final per = u.priceFor(day) + extraPer;
    final sub = per * n;
    final after = afterPromo(sub);
    final promoOff = sub - after;
    final longOff = (n >= 3 && u.disc > 0) ? (after * u.disc / 100).round() : 0;
    return PriceQuote(perNight: per, extraPerNight: extraPer, subtotal: sub, promoOff: promoOff, longOff: longOff, total: after - longOff);
  }
}

const List<String> _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// عدد با جداکننده‌ی هزارگان؛ فارسی/عربی با ارقام فارسی، انگلیسی با ارقام لاتین
String formatNumber(int n, String lang) {
  final neg = n < 0;
  final s = (neg ? -n : n).toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(lang == 'en' ? ',' : '٬');
    b.write(s[i]);
  }
  var out = b.toString();
  if (lang != 'en') {
    for (var d = 0; d < 10; d++) {
      out = out.replaceAll('$d', _faDigits[d]);
    }
  }
  return neg ? '-$out' : out;
}
