import 'dart:math';

/// موتور «میوه‌چین» (سه‌تایی‌چین ۷×۷): حذف ۳ تا ۵ میوه، میوهٔ ویژه (↔ ↕ بمب رنگی)، یخ، ریزش و مرحله‌ها.
/// بدون وابستگی به فلاتر؛ قابل تست.
///
/// خانه‌ها: شمارهٔ ردیف×۷ + ستون. نوع میوه ۰ تا ۵ ؛ ‎-۱‎ = خالی.
/// ویژه‌ها (sp): ۰ هیچ، ۱ پاک‌کردن ردیف، ۲ پاک‌کردن ستون، ۳ بمب رنگی.

const int kFruitN = 7;

class FruitGoal {
  FruitGoal(this.f, this.n);

  /// نوع میوه؛ ‎-۱‎ یعنی «شکستن یخ»
  final int f;
  int n;
}

class FruitLevel {
  FruitLevel(this.moves, this.goals);
  int moves;
  final List<FruitGoal> goals;
}

class FruitMatch {
  FruitMatch(this.cells, this.marks);
  final Set<int> cells;

  /// ویژه‌هایی که باید ساخته شوند: [خانه، نوع ویژه]
  final List<List<int>> marks;
  bool get isEmpty => cells.isEmpty;
}

class FruitEngine {
  FruitEngine([Random? r]) : rnd = r ?? Random();

  final Random rnd;
  static const int n = kFruitN;
  int types = 4;
  List<int> t = List<int>.filled(n * n, 0);
  List<int> sp = List<int>.filled(n * n, 0);
  List<int> ice = List<int>.filled(n * n, 0);

  List<int> _range(int i, int l, int st) => <int>[for (var k = 0; k < l; k++) i + k * st];

  bool adj(int a, int b) {
    final d = (a - b).abs();
    return d == n || (d == 1 && a ~/ n == b ~/ n);
  }

  void swapCells(int a, int b) {
    var x = t[a];
    t[a] = t[b];
    t[b] = x;
    x = sp[a];
    sp[a] = sp[b];
    sp[b] = x;
  }

  /// پیدا کردن ردیف‌های ≥۳ ؛ [pref] خانه‌های جابه‌جاشده‌اند (محل ساخت میوهٔ ویژه)
  FruitMatch find(List<int> pref) {
    final set = <int>{};
    final mk = <List<int>>[];
    void run(List<int> cs, bool horizontal) {
      set.addAll(cs);
      if (cs.length >= 4) {
        var at = cs[1];
        for (final q in pref) {
          if (cs.contains(q)) {
            at = q;
            break;
          }
        }
        mk.add(<int>[at, cs.length >= 5 ? 3 : (horizontal ? 1 : 2)]);
      }
    }

    for (var r = 0; r < n; r++) {
      var c = 0;
      while (c < n) {
        final i = r * n + c;
        final v = t[i];
        var l = 1;
        while (c + l < n && t[i + l] == v) {
          l++;
        }
        if (l >= 3 && v >= 0) run(_range(i, l, 1), true);
        c += l;
      }
    }
    for (var c = 0; c < n; c++) {
      var r = 0;
      while (r < n) {
        final j = r * n + c;
        final w = t[j];
        var m = 1;
        while (r + m < n && t[j + m * n] == w) {
          m++;
        }
        if (m >= 3 && w >= 0) run(_range(j, m, n), false);
        r += m;
      }
    }
    return FruitMatch(set, mk);
  }

  /// گسترش حذف: ویژه‌های داخل مجموعه فعال می‌شوند
  void expand(Set<int> set) {
    final q = set.toList();
    void add(int j) {
      if (set.add(j)) q.add(j);
    }

    while (q.isNotEmpty) {
      final i = q.removeLast();
      final r = i ~/ n, c = i % n;
      if (sp[i] == 1) {
        for (var x = 0; x < n; x++) {
          add(r * n + x);
        }
      } else if (sp[i] == 2) {
        for (var x = 0; x < n; x++) {
          add(x * n + c);
        }
      } else if (sp[i] == 3) {
        for (var x = 0; x < n * n; x++) {
          if (t[x] == t[i]) add(x);
        }
      }
    }
  }

  /// ریزش و پر کردن از بالا؛ فاصلهٔ افتادن هر خانه را برمی‌گرداند (برای انیمیشن)
  List<int> gravity() {
    final drop = List<int>.filled(n * n, 0);
    for (var c = 0; c < n; c++) {
      final col = <List<int>>[];
      for (var r = n - 1; r >= 0; r--) {
        final i = r * n + c;
        if (t[i] >= 0) col.add(<int>[t[i], sp[i], r]);
      }
      final empty = n - col.length;
      var k = 0;
      for (var r = n - 1; r >= 0; r--) {
        final i = r * n + c;
        if (k < col.length) {
          final e = col[k++];
          t[i] = e[0];
          sp[i] = e[1];
          drop[i] = r - e[2];
        } else {
          t[i] = rnd.nextInt(types);
          sp[i] = 0;
          drop[i] = empty;
        }
      }
    }
    return drop;
  }

  bool hasMove() {
    for (var i = 0; i < n * n; i++) {
      if (sp[i] == 3) return true;
    }
    return findHint() != null;
  }

  /// یک جابه‌جایی که چیدمان می‌سازد (راهنما)
  List<int>? findHint() {
    for (var k = 0; k < n * n; k++) {
      final nb = <int>[];
      if (k % n < n - 1) nb.add(k + 1);
      if (k + n < n * n) nb.add(k + n);
      for (final j in nb) {
        swapCells(k, j);
        final f = !find(const <int>[]).isEmpty;
        swapCells(k, j);
        if (f) return <int>[k, j];
      }
    }
    return null;
  }

  void fill() {
    do {
      for (var i = 0; i < n * n; i++) {
        final r = i ~/ n, c = i % n;
        int v;
        do {
          v = rnd.nextInt(types);
        } while ((c >= 2 && t[i - 1] == v && t[i - 2] == v) || (r >= 2 && t[i - n] == v && t[i - 2 * n] == v));
        t[i] = v;
        sp[i] = 0;
      }
    } while (!hasMove());
  }

  /// وقتی جابه‌جایی نمانده: میوه‌ها مخلوط می‌شوند
  void reshuffle() {
    do {
      for (var i = 0; i < n * n; i++) {
        t[i] = rnd.nextInt(types);
        sp[i] = 0;
      }
    } while (!find(const <int>[]).isEmpty || !hasMove());
  }

  FruitLevel setup(int level) {
    types = level < 3 ? 4 : (level < 6 ? 5 : 6);
    var moves = max(14, 22 - level ~/ 2);
    final a = rnd.nextInt(types);
    int b;
    do {
      b = rnd.nextInt(types);
    } while (b == a);
    final goalN = level < 4 ? 6 + level * 2 : 4 + level;
    final goals = <FruitGoal>[FruitGoal(a, goalN), FruitGoal(b, goalN)];
    ice = List<int>.filled(n * n, 0);
    if (level >= 4) {
      final ic = min(level + 2, 16);
      var cn = 0;
      while (cn < ic) {
        final z = rnd.nextInt(n * n);
        if (ice[z] == 0) {
          ice[z] = (level >= 8 && rnd.nextInt(3) == 0) ? 2 : 1;
          cn++;
        }
      }
      goals.add(FruitGoal(-1, ic));
      moves += 4;
    }
    sp = List<int>.filled(n * n, 0);
    fill();
    return FruitLevel(moves, goals);
  }
}
