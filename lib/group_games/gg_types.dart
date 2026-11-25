/// بازیکن یک مسابقه (انسان یا ربات). همه‌ی گوشی‌ها فهرست یکسانی می‌گیرند.
class GgPlayer {
  GgPlayer({required this.name, required this.col, this.bot = false, this.uid = ''});

  final String name;
  final int col; // اندیس رنگ در GgPrefs.palette
  final bool bot;
  final String uid;

  Map<String, dynamic> toJson() => <String, dynamic>{'n': name, 'c': col, 'b': bot ? 1 : 0, 'u': uid};

  factory GgPlayer.fromJson(Map<dynamic, dynamic> j) => GgPlayer(
        name: '${j['n']}',
        col: (j['c'] as num?)?.toInt() ?? 0,
        bot: '${j['b']}' == '1',
        uid: '${j['u'] ?? ''}',
      );
}

/// تنظیمات شروع مسابقه
class GgConfig {
  GgConfig({required this.game, required this.players, this.level = 1, this.lives = 5, this.holes = 9, this.solo = false});

  final String game; // 'hockey' | 'golf'
  final List<GgPlayer> players;
  final int level; // سختی ربات: 0 آسان، 1 معمولی، 2 سخت
  final int lives; // هاکی: جان هر بازیکن
  final int holes; // گلف: تعداد حفره
  final bool solo; // تک‌نفره با ربات (ارتقاها فقط اینجا اثر دارند)

  Map<String, dynamic> toJson() => <String, dynamic>{
        'game': game,
        'players': players.map((e) => e.toJson()).toList(),
        'level': level,
        'lives': lives,
        'holes': holes,
        'solo': solo ? 1 : 0,
      };

  factory GgConfig.fromJson(Map<String, dynamic> j) => GgConfig(
        game: '${j['game']}',
        players: (j['players'] as List).map((e) => GgPlayer.fromJson(e as Map)).toList(),
        level: (j['level'] as num?)?.toInt() ?? 1,
        lives: (j['lives'] as num?)?.toInt() ?? 5,
        holes: (j['holes'] as num?)?.toInt() ?? 9,
        solo: '${j['solo']}' == '1',
      );
}
