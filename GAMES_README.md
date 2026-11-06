# بخش «بازی و سرگرمی» (ADMIN 58)

## اپ
- کلید جدید «بازی و سرگرمی» زیر دو کلید گروه‌ها و تماس در صفحه‌ی اصلی (`cyrus_home_view.dart`).
- کد در `lib/pages/games/`: موتور و ربات (`game_engine.dart`)، کیف سکه (`game_api.dart`)، صفحه‌ی بازی (`game_play_page.dart`)، بازی گوشی نزدیک (`nearby_duel_page.dart`)، فروشگاه، صفحه‌ی اصلی بازی.
- حالت‌ها: ربات (آسان/معمولی/سخت) و دو نفره روی یک گوشی (بدون اینترنت)، گوشی نزدیک (Nearby، بدون اینترنت)، آنلاین (حریف تصادفی).
- شبکه‌ی Nearby همان شبکه‌ی چت آفلاین است؛ فقط دو خط به `offline_mesh_service.dart` اضافه شد (`gameHandler` و `sendGame`).
- تست موتور: `flutter test test/game_engine_test.dart`

## ورکر (worker71.js)
مسیرها: `/api/game/` + config, wallet, daily, goal, buy, equip, offline, top, quick, create, join, rooms, state, move, resign, timeout, chat
جدول‌ها (خودکار): game_wallet, game_daily, game_ledger, game_rooms, game_pairs
- قوانین، نوبت، برنده و سکه فقط سمت سرور است.
- سقف روزانه: آنلاین ۳۰۰ سکه، آفلاین ۶۰ سکه؛ هر دو حریف حداکثر ۳ بازی پاداش‌دار در روز با هم.
- ترک بازی یا تمام شدن وقت (۲ دقیقه): بدون سکه و بدون ضرر.
- خاموش کردن کل بخش بدون انتشار دوباره:
  `INSERT OR REPLACE INTO app_settings(key,value) VALUES('games_enabled','0');`
