import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// جستجوی صوتی سایروس توریست — مشترک بین «نقشه» و «جستجوی هوشمند».
///
/// زبان تشخیص گفتار همیشه از روی زبان انتخاب‌شده‌ی برنامه (۱۰ زبان) تعیین
/// می‌شود: fa، en، ar، tr، ru، fr، de، es، zh، it.
///
/// استفاده:
/// ```dart
/// final text = await showVoiceSearchSheet(context, languageCode: 'fa');
/// if (text != null) { ... }
/// ```
/// اگر کاربر چیزی نگوید یا پنجره را ببندد، `null` برمی‌گردد.
Future<String?> showVoiceSearchSheet(
  BuildContext context, {
  required String languageCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VoiceSearchSheet(languageCode: languageCode),
  );
}

/// شناسه‌ی زبان ترجیحی هر زبان برنامه برای موتور تشخیص گفتار اندروید.
const Map<String, String> kVoiceLocales = {
  'fa': 'fa_IR',
  'en': 'en_US',
  'ar': 'ar_SA',
  'tr': 'tr_TR',
  'ru': 'ru_RU',
  'fr': 'fr_FR',
  'de': 'de_DE',
  'es': 'es_ES',
  'zh': 'zh_CN',
  'it': 'it_IT',
};

enum _VoiceState { starting, listening, error }

class _VoiceSearchSheet extends StatefulWidget {
  const _VoiceSearchSheet({required this.languageCode});

  final String languageCode;

  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends State<_VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _pulse;

  _VoiceState _state = _VoiceState.starting;
  String _errorKey = '';
  String _words = '';
  double _level = 0;
  bool _closed = false;

  String get _lang {
    final c = widget.languageCode.toLowerCase().trim();
    return kVoiceLocales.containsKey(c) ? c : 'en';
  }

  bool get _isRtl => _lang == 'fa' || _lang == 'ar';

  String _t(String key) => _kVoiceTexts[_lang]?[key] ?? _kVoiceTexts['en']![key]!;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  /// پیدا کردن زبان مناسب بین زبان‌های نصب‌شده‌ی گوشی؛ ابتدا مطابقت کامل
  /// (مثلاً fa_IR)، بعد هر زبانی با همان کد زبان (مثلاً fa_AF).
  Future<String?> _pickLocale() async {
    final wanted = kVoiceLocales[_lang]!;
    List<LocaleName> locales;
    try {
      locales = await _speech.locales();
    } catch (_) {
      return wanted;
    }
    // بعضی دستگاه‌ها فهرست خالی می‌دهند ولی تشخیص گفتار کار می‌کند.
    if (locales.isEmpty) return wanted;

    String norm(String id) => id.replaceAll('-', '_').toLowerCase();

    for (final l in locales) {
      if (norm(l.localeId) == norm(wanted)) return l.localeId;
    }
    for (final l in locales) {
      if (norm(l.localeId).split('_').first == _lang) return l.localeId;
    }
    // زبان در فهرست «دانلودشده» نیست؛ ولی تشخیص آنلاین گوگل معمولاً فارسی را می‌فهمد.
    // پس مسدود نمی‌کنیم و همان کد را امتحان می‌کنیم؛ اگر موتور نپذیرفت، خطای
    // error_language_* می‌آید و راهنمای دانلود زبان نشان داده می‌شود.
    return wanted;
  }

  Future<void> _start() async {
    if (_closed) return;
    setState(() {
      _state = _VoiceState.starting;
      _words = '';
      _errorKey = '';
    });

    bool ok = false;
    try {
      ok = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted || _closed) return;

    if (!ok) {
      // initialize در حالت نبود مجوز یا نبود سرویس گفتار false می‌دهد.
      final hasPermission = await _speech.hasPermission;
      _fail(hasPermission ? 'unavailable' : 'permission');
      return;
    }

    final localeId = await _pickLocale();
    if (!mounted || _closed) return;

    if (localeId == null) {
      _fail('noLang');
      return;
    }

    setState(() => _state = _VoiceState.listening);

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          if (!mounted) return;
          // سطح صدا در اندروید حدود ۰ تا ۱۰ است.
          setState(() => _level = (level / 10).clamp(0.0, 1.0));
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
        ),
      );
    } catch (_) {
      _fail('unavailable');
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted || _closed) return;
    setState(() => _words = result.recognizedWords);
    if (result.finalResult) {
      _finish(result.recognizedWords);
    }
  }

  void _onStatus(String status) {
    // وقتی موتور گفتار خودش متوقف شد (سکوت)، اگر متنی داریم تحویل بده.
    if (!mounted || _closed) return;
    if (status == 'done' || status == 'notListening') {
      if (_state == _VoiceState.listening) {
        final text = _words.trim();
        if (text.isNotEmpty) {
          _finish(text);
        } else {
          _fail('noMatch');
        }
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted || _closed) return;
    final msg = error.errorMsg;
    if (msg.contains('permission')) {
      _fail('permission');
    } else if (msg == 'error_no_match' || msg == 'error_speech_timeout') {
      final text = _words.trim();
      if (text.isNotEmpty) {
        _finish(text);
      } else {
        _fail('noMatch');
      }
    } else if (msg == 'error_language_not_supported' ||
        msg == 'error_language_unavailable') {
      _fail('noLang');
    } else {
      _fail('unavailable');
    }
  }

  void _fail(String key) {
    if (!mounted || _closed) return;
    _speech.cancel();
    setState(() {
      _state = _VoiceState.error;
      _errorKey = key;
    });
  }

  void _finish(String text) {
    final clean = text.trim();
    if (_closed || clean.isEmpty) return;
    _closed = true;
    _speech.stop();
    Navigator.of(context).pop(clean);
  }

  static const MethodChannel _sys = MethodChannel('cyrus/system');

  Future<void> _openVoiceSettings() async {
    try {
      await _sys.invokeMethod('openVoiceSettings');
    } catch (_) {}
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _speech.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          decoration: const BoxDecoration(
            color: Color(0xff0b1d29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xffc99b3b), width: 1.2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xff39505d),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t('title'),
                  style: const TextStyle(
                    color: Color(0xffffd979),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                _buildMic(),
                const SizedBox(height: 20),
                _buildStatusText(),
                const SizedBox(height: 22),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMic() {
    final listening = _state == _VoiceState.listening;
    final hasError = _state == _VoiceState.error;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final wave = listening ? (0.35 * _pulse.value + 0.65 * _level) : 0.0;
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84 + 46 * wave,
                height: 84 + 46 * wave,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffffd56d)
                      .withValues(alpha: listening ? 0.18 : 0.06),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: hasError
                        ? const [Color(0xff59636a), Color(0xff3a444b)]
                        : const [Color(0xfff4cf70), Color(0xffb98524)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffffd56d)
                          .withValues(alpha: listening ? 0.45 : 0.15),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Icon(
                  hasError ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 40,
                  color: const Color(0xff071722),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    String main;
    String? sub;
    Color mainColor = Colors.white;

    switch (_state) {
      case _VoiceState.starting:
        main = _t('starting');
        break;
      case _VoiceState.listening:
        if (_words.isEmpty) {
          main = _t('listening');
          sub = _t('hint');
        } else {
          main = _words;
        }
        break;
      case _VoiceState.error:
        main = _t(_errorKey);
        mainColor = const Color(0xffffb4a8);
        break;
    }

    return Column(
      children: [
        Text(
          main,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mainColor,
            fontSize: _state == _VoiceState.listening && _words.isNotEmpty
                ? 20
                : 15,
            height: 1.6,
            fontWeight: _state == _VoiceState.listening && _words.isNotEmpty
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff8fa4ad), fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final hasError = _state == _VoiceState.error;
    final canSend =
        _state == _VoiceState.listening && _words.trim().isNotEmpty;

    final needSettings =
        hasError && (_errorKey == 'noLang' || _errorKey == 'unavailable');
    if (needSettings) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openVoiceSettings,
              icon: const Icon(Icons.settings_voice_rounded, size: 19),
              label: Text(_t('openSettings')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff29e0ad),
                side: const BorderSide(color: Color(0xff29e0ad)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildBaseActions(hasError, canSend),
        ],
      );
    }
    return _buildBaseActions(hasError, canSend);
  }

  Widget _buildBaseActions(bool hasError, bool canSend) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _close,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffffd979),
              side: const BorderSide(color: Color(0xffc99b3b)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(_t('cancel')),
          ),
        ),
        if (hasError || canSend) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: hasError ? _start : () => _finish(_words),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffffe39a),
                foregroundColor: const Color(0xff071722),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(hasError ? _t('retry') : _t('search')),
            ),
          ),
        ],
      ],
    );
  }
}

/// متن‌های پنجره‌ی جستجوی صوتی در ۱۰ زبان برنامه.
const Map<String, Map<String, String>> _kVoiceTexts = {
  'fa': {
    'title': 'جستجوی صوتی',
    'starting': 'در حال آماده‌سازی میکروفون…',
    'listening': 'در حال گوش دادن…',
    'hint': 'نام شهر، مکان یا جمله‌ی خود را بگویید',
    'noMatch': 'چیزی متوجه نشدم. دوباره امتحان کنید.',
    'permission': 'برای جستجوی صوتی باید دسترسی میکروفون را در تنظیمات گوشی مجاز کنید.',
    'unavailable': 'تشخیص گفتار روی این دستگاه در دسترس نیست یا اینترنت قطع است.',
    'noLang': 'زبان فارسی برای تشخیص گفتار روی این دستگاه نصب نیست. آن را از تنظیمات گوشی (زبان و ورودی ← تایپ صوتی گوگل) دانلود کنید.',
    'retry': 'تلاش دوباره',
    'cancel': 'بستن',
    'search': 'جستجو',
    'openSettings': 'باز کردن تنظیمات تایپ صوتی',
  },
  'en': {
    'title': 'Voice Search',
    'starting': 'Preparing the microphone…',
    'listening': 'Listening…',
    'hint': 'Say a city, a place or a sentence',
    'noMatch': 'I didn\'t catch that. Please try again.',
    'permission': 'Allow microphone access in your phone settings to use voice search.',
    'unavailable': 'Speech recognition is unavailable on this device, or you are offline.',
    'noLang': 'This language is not installed for speech recognition on your device. Download it in your phone settings (Language & input → Google voice typing).',
    'retry': 'Try again',
    'cancel': 'Close',
    'search': 'Search',
    'openSettings': 'Open voice typing settings',
  },
  'ar': {
    'title': 'البحث الصوتي',
    'starting': 'جارٍ تجهيز الميكروفون…',
    'listening': 'جارٍ الاستماع…',
    'hint': 'قل اسم مدينة أو مكان أو جملة',
    'noMatch': 'لم أفهم ما قلت. حاول مرة أخرى.',
    'permission': 'اسمح بالوصول إلى الميكروفون من إعدادات الهاتف لاستخدام البحث الصوتي.',
    'unavailable': 'التعرف على الكلام غير متاح على هذا الجهاز أو لا يوجد اتصال بالإنترنت.',
    'noLang': 'هذه اللغة غير مثبتة للتعرف على الكلام على جهازك. نزّلها من إعدادات الهاتف (اللغة والإدخال ← الكتابة الصوتية من Google).',
    'retry': 'حاول مرة أخرى',
    'cancel': 'إغلاق',
    'search': 'بحث',
    'openSettings': 'فتح إعدادات الكتابة الصوتية',
  },
  'tr': {
    'title': 'Sesli Arama',
    'starting': 'Mikrofon hazırlanıyor…',
    'listening': 'Dinleniyor…',
    'hint': 'Bir şehir, yer veya cümle söyleyin',
    'noMatch': 'Anlayamadım. Lütfen tekrar deneyin.',
    'permission': 'Sesli aramayı kullanmak için telefon ayarlarından mikrofon iznini verin.',
    'unavailable': 'Konuşma tanıma bu cihazda kullanılamıyor veya internet bağlantısı yok.',
    'noLang': 'Bu dil cihazınızda konuşma tanıma için yüklü değil. Telefon ayarlarından indirin (Dil ve giriş → Google sesle yazma).',
    'retry': 'Tekrar dene',
    'cancel': 'Kapat',
    'search': 'Ara',
  },
  'ru': {
    'title': 'Голосовой поиск',
    'starting': 'Подготовка микрофона…',
    'listening': 'Слушаю…',
    'hint': 'Назовите город, место или скажите фразу',
    'noMatch': 'Не расслышал. Попробуйте ещё раз.',
    'permission': 'Разрешите доступ к микрофону в настройках телефона, чтобы пользоваться голосовым поиском.',
    'unavailable': 'Распознавание речи недоступно на этом устройстве или нет подключения к интернету.',
    'noLang': 'Этот язык не установлен для распознавания речи на устройстве. Скачайте его в настройках телефона (Язык и ввод → Голосовой ввод Google).',
    'retry': 'Повторить',
    'cancel': 'Закрыть',
    'search': 'Найти',
  },
  'fr': {
    'title': 'Recherche vocale',
    'starting': 'Préparation du micro…',
    'listening': 'J\'écoute…',
    'hint': 'Dites une ville, un lieu ou une phrase',
    'noMatch': 'Je n\'ai pas compris. Réessayez.',
    'permission': 'Autorisez l\'accès au micro dans les réglages du téléphone pour utiliser la recherche vocale.',
    'unavailable': 'La reconnaissance vocale n\'est pas disponible sur cet appareil, ou vous êtes hors ligne.',
    'noLang': 'Cette langue n\'est pas installée pour la reconnaissance vocale sur votre appareil. Téléchargez-la dans les réglages (Langue et saisie → Saisie vocale Google).',
    'retry': 'Réessayer',
    'cancel': 'Fermer',
    'search': 'Rechercher',
  },
  'de': {
    'title': 'Sprachsuche',
    'starting': 'Mikrofon wird vorbereitet…',
    'listening': 'Ich höre zu…',
    'hint': 'Nennen Sie eine Stadt, einen Ort oder einen Satz',
    'noMatch': 'Das habe ich nicht verstanden. Bitte versuchen Sie es erneut.',
    'permission': 'Erlauben Sie den Mikrofonzugriff in den Telefoneinstellungen, um die Sprachsuche zu nutzen.',
    'unavailable': 'Spracherkennung ist auf diesem Gerät nicht verfügbar oder Sie sind offline.',
    'noLang': 'Diese Sprache ist für die Spracherkennung auf Ihrem Gerät nicht installiert. Laden Sie sie in den Einstellungen herunter (Sprache & Eingabe → Google-Spracheingabe).',
    'retry': 'Erneut versuchen',
    'cancel': 'Schließen',
    'search': 'Suchen',
  },
  'es': {
    'title': 'Búsqueda por voz',
    'starting': 'Preparando el micrófono…',
    'listening': 'Escuchando…',
    'hint': 'Di una ciudad, un lugar o una frase',
    'noMatch': 'No te he entendido. Inténtalo de nuevo.',
    'permission': 'Permite el acceso al micrófono en los ajustes del teléfono para usar la búsqueda por voz.',
    'unavailable': 'El reconocimiento de voz no está disponible en este dispositivo o no hay conexión.',
    'noLang': 'Este idioma no está instalado para el reconocimiento de voz en tu dispositivo. Descárgalo en los ajustes (Idioma y entrada → Escritura por voz de Google).',
    'retry': 'Reintentar',
    'cancel': 'Cerrar',
    'search': 'Buscar',
  },
  'zh': {
    'title': '语音搜索',
    'starting': '正在准备麦克风…',
    'listening': '正在聆听…',
    'hint': '请说出城市、地点或一句话',
    'noMatch': '没有听清，请再试一次。',
    'permission': '请在手机设置中允许麦克风权限，以使用语音搜索。',
    'unavailable': '此设备不支持语音识别，或当前没有网络连接。',
    'noLang': '您的设备未安装此语言的语音识别包。请在手机设置中下载（语言和输入法 → Google 语音输入）。',
    'retry': '重试',
    'cancel': '关闭',
    'search': '搜索',
  },
  'it': {
    'title': 'Ricerca vocale',
    'starting': 'Preparazione del microfono…',
    'listening': 'In ascolto…',
    'hint': 'Dì una città, un luogo o una frase',
    'noMatch': 'Non ho capito. Riprova.',
    'permission': 'Consenti l\'accesso al microfono nelle impostazioni del telefono per usare la ricerca vocale.',
    'unavailable': 'Il riconoscimento vocale non è disponibile su questo dispositivo oppure sei offline.',
    'noLang': 'Questa lingua non è installata per il riconoscimento vocale sul tuo dispositivo. Scaricala nelle impostazioni (Lingua e inserimento → Digitazione vocale Google).',
    'retry': 'Riprova',
    'cancel': 'Chiudi',
    'search': 'Cerca',
  },
};
