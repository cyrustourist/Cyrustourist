import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/language/home_texts.dart';
import '../../core/language/menu_translations.dart';
import '../cyrus_ad_banner.dart';
import 'cyrus_home_style.dart';

/// ==========================================================
/// Cyrus Tourist — نمای جدید صفحه اصلی (طرح HTML نسخه v7)
/// ==========================================================
///
/// هدر (منو/زبان/حساب) از بیرون (main.dart) داده می‌شود؛ باقی صفحه:
/// لوگو، نوار جستجو (علاقه‌مندی سمت چپ)، ۸ کلید، ۲ جایگاه تبلیغات،
/// کادر معرفی کسب‌وکار، شبکه‌های اجتماعی، تنظیمات (صدا/رنگ/حالت/انیمیشن).

/// نسخه‌ی نمایش‌داده‌شده در پایین صفحه (با pubspec.yaml هماهنگ نگه دارید).
const String kCyrusVersionLabel = '5.9.15';

/// لینک شبکه‌های اجتماعی — به آدرس واقعی پیج‌های خودتان تغییر دهید.
const Map<String, String> kCyrusSocialUrls = {
  'instagram': 'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o',
  'aparat': 'https://www.aparat.com/Cyrustourist',
  'youtube': 'https://youtube.com/@cyrustourist?si=fKcSD3vB6bzz2J6i',
  'telegram': 'https://t.me/',
  'eitaa': 'https://eitaa.com/cyrustourist',
  'links': 'https://cyrustourist.ir/',
};

/// آیکون اختصاصی هر کلید (کلید = شماره‌ی کلید در اپ ۱ تا ۸).
/// وقتی PNG/WebP آیکون‌ها آماده شد، مسیرش را اینجا بگذارید و در
/// pubspec.yaml هم ثبت کنید؛ تا آن موقع آیکون‌های وکتور نمایش داده می‌شوند.
/// نمونه:  1: 'assets/images/icons/btn_map.png',
const Map<int, String> kHomeIconAssets = {};

const Map<int, IconData> _kHomeIcons = {
  1: Icons.map_rounded,
  2: Icons.health_and_safety_rounded,
  3: Icons.account_balance_rounded,
  4: Icons.cottage_rounded,
  5: Icons.explore_rounded,
  6: Icons.movie_creation_rounded,
  7: Icons.manage_search_rounded,
  8: Icons.luggage_rounded,
};

/// ترتیب نمایش مطابق طرح جدید (۲ ستون × ۴ ردیف)؛ مقدارها = شماره‌ی کلید در اپ:
/// نقشه، جاذبه | سلامت، اقامتگاه | فیلم، تور | راهنمای سفر، جستجو
const List<int> kHomeButtonOrder = [1, 3, 2, 4, 6, 8, 5, 7];

class _Social {
  const _Social(this.key, this.icon);
  final String key;
  final IconData icon;
}

const List<_Social> _kSocials = [
  _Social('instagram', Icons.camera_alt_outlined),
  _Social('aparat', Icons.play_circle_outline_rounded),
  _Social('youtube', Icons.smart_display_rounded),
  _Social('telegram', Icons.send_rounded),
  _Social('eitaa', Icons.chat_bubble_outline_rounded),
  _Social('links', Icons.link_rounded),
];

class CyrusHomeView extends StatefulWidget {
  const CyrusHomeView({
    super.key,
    required this.header,
    required this.onButtonTap,
    required this.onOpenSearch,
    required this.onOpenFavorites,
    required this.onOpenRegister,
  });

  /// ردیف هدر (همبرگری / زبان / حساب کاربری).
  final Widget header;

  /// با شماره‌ی کلید در اپ (۱ تا ۸) صدا زده می‌شود.
  final ValueChanged<int> onButtonTap;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenFavorites;

  /// لمس عکس پیش‌فرض تبلیغات و کادر «معرفی کسب‌وکار شما».
  final VoidCallback onOpenRegister;

  @override
  State<CyrusHomeView> createState() => _CyrusHomeViewState();
}

class _CyrusHomeViewState extends State<CyrusHomeView>
    with SingleTickerProviderStateMixin {
  final CyrusHomeStyle _style = CyrusHomeStyle.instance;
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: _style.sweepDuration);
    _style.addListener(_onStyleChanged);
    _style.load();
    _syncSweep();
  }

  @override
  void dispose() {
    _style.removeListener(_onStyleChanged);
    _sweep.dispose();
    super.dispose();
  }

  void _onStyleChanged() {
    _syncSweep();
    if (mounted) setState(() {});
  }

  void _syncSweep() {
    _sweep.stop();
    _sweep.duration = _style.sweepDuration;
    if (_style.sweepEnabled) {
      _sweep.repeat();
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // بی‌سروصدا؛ باز نشدن لینک نباید باعث خطا شود.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final lang = MenuLanguage.current;
    final rtl = MenuLanguage.isRtl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: s.isDay ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: s.pageGradient,
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
          child: Stack(
            children: [
              if (!s.isDay)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -1.1),
                          radius: 0.9,
                          colors: [
                            Color(0xff173d78),
                            Color(0xff0b1b3b),
                            Color(0x000b1b3b),
                          ],
                          stops: [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            // جای دکمه‌های هدر در همه‌ی زبان‌ها ثابت می‌ماند
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: widget.header,
                            ),
                          ),
                          _brand(s),
                          _searchRow(s, lang, rtl),
                          _grid(s, lang),
                          _adSection(s, lang),
                          _note(s, lang),
                          _socials(s, lang),
                          _settingsRow(s, lang),
                          _footer(s),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // لوگو و عنوان
  // ------------------------------------------------------------

  Widget _brand(CyrusHomeStyle s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff159ed5),
              border: Border.all(color: s.accent, width: 3),
              boxShadow: [
                BoxShadow(color: s.accent.withValues(alpha: 0.06), spreadRadius: 6),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo-new.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CYRUS TOURIST',
            style: TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              fontSize: 25,
              letterSpacing: 1.8,
              color: s.titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'سایروس توریست',
            style: TextStyle(color: s.accent, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'From Iran to the World',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: s.mutedColor, fontSize: 11, letterSpacing: 0.7),
          ),
          const SizedBox(height: 12),
          FractionallySizedBox(
            widthFactor: 0.64,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    s.accent.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // نوار جستجو — علاقه‌مندی‌ها سمت چپ، ذره‌بین سمت راست
  // ------------------------------------------------------------

  Widget _searchRow(CyrusHomeStyle s, String lang, bool rtl) {
    final hint = MenuTranslations.searchHint(lang);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: s.accent, width: 2),
            gradient: LinearGradient(colors: s.cardGradient),
          ),
          child: Row(
            children: [
              _circleIcon(s, Icons.favorite_border_rounded, widget.onOpenFavorites),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onOpenSearch,
                  child: Align(
                    alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        hint,
                        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.mutedColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _circleIcon(s, Icons.search_rounded, widget.onOpenSearch),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(CyrusHomeStyle s, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: s.accent.withValues(alpha: 0.18),
          border: Border.all(color: s.accent, width: 2),
        ),
        child: Icon(icon, size: 20, color: s.isDay ? s.optionText : s.accentText),
      ),
    );
  }

  // ------------------------------------------------------------
  // ۸ کلید اصلی (۲ ستون × ۴ ردیف)
  // ------------------------------------------------------------

  Widget _grid(CyrusHomeStyle s, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 0),
      child: Column(
        children: [
          for (var r = 0; r < 4; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == 3 ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _item(s, lang, kHomeButtonOrder[r * 2])),
                  const SizedBox(width: 14),
                  Expanded(child: _item(s, lang, kHomeButtonOrder[r * 2 + 1])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(CyrusHomeStyle s, String lang, int number) {
    return _HomeItem(
      number: number,
      label: MenuTranslations.title(lang, number),
      style: s,
      sweep: _sweep,
      onTap: () {
        s.playTap();
        widget.onButtonTap(number);
      },
    );
  }

  // ------------------------------------------------------------
  // تبلیغات: جایگاه ۱ و ۲ (عکس‌های پیش‌فرض ۱ـ۱ / ۱ـ۲ و ۲ـ۱ / ۲ـ۲)
  // ------------------------------------------------------------

  Widget _adSection(CyrusHomeStyle s, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 8),
          child: Text(
            HomeTexts.get(lang, 'adTitle'),
            style: TextStyle(
              color: s.isDay ? const Color(0xff24364f) : const Color(0xffd5dced),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _adFrame(
          s,
          slot: 1,
          ratio: 1983 / 386,
          defaults: const [
            'assets/images/ads/slot1_default_1.jpg',
            'assets/images/ads/slot1_default_2.jpg',
          ],
        ),
        const SizedBox(height: 14),
        _adFrame(
          s,
          slot: 2,
          ratio: 2174 / 513,
          defaults: const [
            'assets/images/ads/slot2_default_1.jpg',
            'assets/images/ads/slot2_default_2.jpg',
          ],
        ),
      ],
    );
  }

  Widget _adFrame(
    CyrusHomeStyle s, {
    required int slot,
    required double ratio,
    required List<String> defaults,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: s.accent, width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.carouselGradient,
          ),
          boxShadow: [
            BoxShadow(color: s.shadowColor, blurRadius: 26, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.5),
          child: AspectRatio(
            aspectRatio: ratio,
            child: CyrusAdBanner(
              slot: slot,
              borderRadius: 0,
              defaultAssets: defaults,
              onDefaultTap: widget.onOpenRegister,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // کادر «معرفی کسب‌وکار شما»
  // ------------------------------------------------------------

  Widget _note(CyrusHomeStyle s, String lang) {
    return GestureDetector(
      onTap: widget.onOpenRegister,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: s.noteBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: s.accent.withValues(alpha: 0.33)),
          boxShadow: [
            BoxShadow(color: s.shadowColor, blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Text(
          '🌍 ${HomeTexts.get(lang, 'noteTitle')}\n${HomeTexts.get(lang, 'noteBody')}',
          textAlign: TextAlign.center,
          style: TextStyle(color: s.bodyTextColor, fontSize: 12, height: 1.85),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // شبکه‌های اجتماعی
  // ------------------------------------------------------------

  Widget _socials(CyrusHomeStyle s, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 8),
          child: Text(
            HomeTexts.get(lang, 'socialTitle'),
            style: TextStyle(
              color: s.isDay ? const Color(0xff24364f) : const Color(0xffd5dced),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            children: [
              for (var r = 0; r < 2; r++)
                Padding(
                  padding: EdgeInsets.only(bottom: r == 0 ? 8 : 0),
                  child: Row(
                    children: [
                      for (var c = 0; c < 3; c++) ...[
                        if (c > 0) const SizedBox(width: 8),
                        Expanded(child: _socialTile(s, lang, _kSocials[r * 3 + c])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialTile(CyrusHomeStyle s, String lang, _Social item) {
    return GestureDetector(
      onTap: () {
        s.playTap();
        _openUrl(kCyrusSocialUrls[item.key] ?? 'https://cyrustourist.ir/');
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: s.accent.withValues(alpha: 0.53)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.cardGradient,
          ),
          boxShadow: [
            BoxShadow(color: s.shadowColor, blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: s.isDay ? const Color(0xffedf3f9) : const Color(0xff050d20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: s.accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(item.icon, size: 16, color: s.cardTextColor),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      HomeTexts.get(lang, item.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: s.cardTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SweepPainter(_sweep, s.sweepEnabled)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // دکمه‌های تنظیمات (صدا / رنگ / حالت / انیمیشن)
  // ------------------------------------------------------------

  Widget _settingsRow(CyrusHomeStyle s, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _settingsButton(s, '🔊 ${HomeTexts.get(lang, 'sound')}', () => _showSoundPanel(lang)),
          _settingsButton(s, '🎨 ${HomeTexts.get(lang, 'color')}', () => _showColorPanel(lang)),
          _settingsButton(s, '🌙 ${HomeTexts.get(lang, 'mode')}', () => _showModePanel(lang)),
          _settingsButton(s, '✨ ${HomeTexts.get(lang, 'animation')}', () => _showAnimationPanel(lang)),
        ],
      ),
    );
  }

  Widget _settingsButton(CyrusHomeStyle s, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.accent.withValues(alpha: 0.47)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.cardGradient,
          ),
          boxShadow: [
            BoxShadow(color: s.shadowColor, blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: s.cardTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _footer(CyrusHomeStyle s) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Column(
        children: [
          Text(
            'Cyrus Tourist • Version $kCyrusVersionLabel',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: s.footerColor, fontSize: 10),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () => _openUrl('https://cyrustourist.ir/'),
            child: Text(
              'https://cyrustourist.ir/',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: s.accent, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // پنجره‌های پایین‌صفحه‌ی تنظیمات
  // ------------------------------------------------------------

  void _showSoundPanel(String lang) {
    _showPanel(
      lang: lang,
      emoji: '🔊',
      titleKey: 'soundTitle',
      options: () => [
        _Opt(HomeTexts.get(lang, 'soundClassic'), _style.sound == CyrusSoundMode.classic,
            () => _style.setSound(CyrusSoundMode.classic)),
        _Opt(HomeTexts.get(lang, 'soundSoft'), _style.sound == CyrusSoundMode.soft,
            () => _style.setSound(CyrusSoundMode.soft)),
        _Opt(HomeTexts.get(lang, 'soundGold'), _style.sound == CyrusSoundMode.gold,
            () => _style.setSound(CyrusSoundMode.gold)),
        _Opt('🔇 ${HomeTexts.get(lang, 'soundSilent')}', _style.sound == CyrusSoundMode.silent,
            () => _style.setSound(CyrusSoundMode.silent)),
      ],
    );
  }

  void _showColorPanel(String lang) {
    const names = {
      CyrusColorMode.gold: 'gold',
      CyrusColorMode.blue: 'blue',
      CyrusColorMode.emerald: 'emerald',
      CyrusColorMode.purple: 'purple',
      CyrusColorMode.red: 'red',
      CyrusColorMode.cyan: 'cyan',
    };
    _showPanel(
      lang: lang,
      emoji: '🎨',
      titleKey: 'colorTitle',
      options: () => [
        for (final mode in CyrusColorMode.values)
          _Opt(
            HomeTexts.get(lang, names[mode]!),
            _style.color == mode,
            () => _style.setColor(mode),
            dot: kCyrusPalettes[mode]!.accent,
          ),
      ],
    );
  }

  void _showModePanel(String lang) {
    _showPanel(
      lang: lang,
      emoji: '🌙',
      titleKey: 'modeTitle',
      options: () => [
        _Opt('🌙 ${HomeTexts.get(lang, 'night')}', _style.display == CyrusDisplayMode.night,
            () => _style.setDisplay(CyrusDisplayMode.night)),
        _Opt('☀️ ${HomeTexts.get(lang, 'day')}', _style.display == CyrusDisplayMode.day,
            () => _style.setDisplay(CyrusDisplayMode.day)),
      ],
    );
  }

  void _showAnimationPanel(String lang) {
    _showPanel(
      lang: lang,
      emoji: '✨',
      titleKey: 'animationTitle',
      options: () => [
        _Opt(HomeTexts.get(lang, 'animSmooth'), _style.animation == CyrusAnimationMode.smooth,
            () => _style.setAnimation(CyrusAnimationMode.smooth)),
        _Opt(HomeTexts.get(lang, 'animLow'), _style.animation == CyrusAnimationMode.low,
            () => _style.setAnimation(CyrusAnimationMode.low)),
        _Opt(HomeTexts.get(lang, 'animOff'), _style.animation == CyrusAnimationMode.off,
            () => _style.setAnimation(CyrusAnimationMode.off)),
      ],
    );
  }

  void _showPanel({
    required String lang,
    required String emoji,
    required String titleKey,
    required List<_Opt> Function() options,
  }) {
    final rtl = MenuLanguage.isRtl;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ListenableBuilder(
                  listenable: _style,
                  builder: (context, _) {
                    final s = _style;
                    final opts = options();
                    return Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: s.accent.withValues(alpha: 0.6)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: s.panelGradient,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0xbb000000), blurRadius: 35, offset: Offset(0, -10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$emoji ${HomeTexts.get(lang, titleKey)}',
                            style: TextStyle(
                              color: s.isDay ? const Color(0xff24364f) : const Color(0xffffe7a0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, box) {
                              final w = (box.maxWidth - 9) / 2;
                              return Wrap(
                                spacing: 9,
                                runSpacing: 9,
                                children: [
                                  for (final o in opts) _optionTile(s, o, w),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: s.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  HomeTexts.get(lang, 'close'),
                                  style: const TextStyle(
                                    color: Color(0xff111111),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(CyrusHomeStyle s, _Opt o, double width) {
    return GestureDetector(
      onTap: o.onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: s.optionBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: o.selected ? s.accent : s.accent.withValues(alpha: 0.33),
            width: o.selected ? 1.6 : 1,
          ),
          boxShadow: o.selected
              ? [BoxShadow(color: s.accent.withValues(alpha: 0.3), blurRadius: 14)]
              : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (o.dot != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: o.dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                o.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: o.selected
                      ? (s.isDay ? const Color(0xff16233a) : s.accentText)
                      : s.optionText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opt {
  const _Opt(this.label, this.selected, this.onTap, {this.dot});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
}

// ==============================================================
// یک کلید دایره‌ای صفحه اصلی
// ==============================================================

class _HomeItem extends StatefulWidget {
  const _HomeItem({
    required this.number,
    required this.label,
    required this.style,
    required this.sweep,
    required this.onTap,
  });

  final int number;
  final String label;
  final CyrusHomeStyle style;
  final Animation<double> sweep;
  final VoidCallback onTap;

  @override
  State<_HomeItem> createState() => _HomeItemState();
}

class _HomeItemState extends State<_HomeItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final asset = kHomeIconAssets[widget.number];
    final icon = _kHomeIcons[widget.number] ?? Icons.circle;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.955 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: s.accent, width: 3),
                    gradient: const RadialGradient(
                      center: Alignment(-0.36, -0.6),
                      radius: 1.0,
                      colors: [
                        Color(0xff2a9fd4),
                        Color(0xff164f8c),
                        Color(0xff0a1f46),
                        Color(0xff071127),
                      ],
                      stops: [0.0, 0.42, 0.78, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: s.shadowColor,
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x3bffffff)),
                              ),
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, box) {
                            final size = box.maxWidth * 0.44;
                            if (asset != null) {
                              return Image.asset(
                                asset,
                                width: size * 1.3,
                                height: size * 1.3,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(icon, size: size, color: s.accentText),
                              );
                            }
                            return Icon(
                              icon,
                              size: size,
                              color: s.accentText,
                              shadows: const [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _SweepPainter(widget.sweep, s.sweepEnabled),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: s.labelColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
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

// ==============================================================
// برق طلایی که روی کلیدها و کارت‌های شبکه‌های اجتماعی می‌گذرد
// (همان انیمیشن sweep طرح HTML)
// ==============================================================

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.progress, this.enabled) : super(repaint: progress);

  final Animation<double> progress;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;

    final t = progress.value;

    final double x;
    if (t <= 0.15) {
      x = -0.55;
    } else if (t >= 0.82) {
      x = 1.3;
    } else {
      x = -0.55 + 1.85 * ((t - 0.15) / 0.67);
    }

    final double o;
    if (t < 0.15) {
      o = 0;
    } else if (t < 0.28) {
      o = 0.9 * (t - 0.15) / 0.13;
    } else if (t < 0.6) {
      o = 0.9;
    } else if (t < 0.82) {
      o = 0.9 * (1 - (t - 0.6) / 0.22);
    } else {
      o = 0;
    }
    if (o <= 0.01) return;

    final bandW = size.width * 0.27;
    final left = size.width * x;
    final rect = Rect.fromLTWH(left, -size.height * 0.25, bandW, size.height * 1.5);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00ffffff),
          Color.fromRGBO(255, 255, 255, 0.6 * o),
          Color.fromRGBO(255, 233, 166, 0.67 * o),
          const Color(0x00ffe9a6),
        ],
      ).createShader(rect);

    canvas.save();
    canvas.translate(left + bandW / 2, size.height / 2);
    canvas.transform(Matrix4.skewX(-0.32).storage);
    canvas.translate(-(left + bandW / 2), -size.height / 2);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.enabled != enabled;
}
