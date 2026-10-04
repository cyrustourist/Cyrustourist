import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/user_profile_service.dart';
import 'support_page.dart';

/// «چت با پشتیبانی» — حساب کاربری.
///
/// کاربر موضوع را انتخاب می‌کند (و در صورت تمایل توضیح کوتاه می‌نویسد)،
/// یک پیام آماده با نام او ساخته می‌شود و با یک لمس در واتساپ، تلگرام
/// یا ایتا برای پشتیبانی فرستاده می‌شود. بدون سرور و بدون فرم.
class SupportChatPage extends StatefulWidget {
  const SupportChatPage({
    super.key,
    this.languageCode = 'fa',
    this.initialTopic = 0,
    this.initialDetails = '',
  });

  final String languageCode;
  final int initialTopic;
  final String initialDetails;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

const List<IconData> _kTopicIcons = [
  Icons.app_registration_rounded,
  Icons.build_circle_rounded,
  Icons.workspace_premium_rounded,
  Icons.help_outline_rounded,
];

const List<String> _kChatLangs = ['fa', 'en', 'ar', 'de', 'es', 'fr', 'it', 'ru', 'tr', 'zh'];

const Map<String, List<String>> _kChat = {
  'title': ['چت با پشتیبانی', 'Chat with support', 'الدردشة مع الدعم', 'Chat mit dem Support', 'Chatea con soporte', 'Discuter avec le support', 'Chatta con il supporto', 'Чат с поддержкой', 'Destekle sohbet', '联系客服'],
  'ask': ['موضوع پیام شما چیست؟', 'What is your message about?', 'ما موضوع رسالتك؟', 'Worum geht es in Ihrer Nachricht?', '¿Sobre qué es su mensaje?', 'Quel est le sujet de votre message ?', 'Di cosa tratta il tuo messaggio?', 'О чём ваше сообщение?', 'Mesajınız ne hakkında?', '您的留言是关于什么？'],
  'topic0': ['ثبت‌نام اقامتگاه / کسب‌وکار', 'Business / stay registration', 'تسجيل نشاط / إقامة', 'Registrierung Unternehmen / Unterkunft', 'Registro de negocio / alojamiento', 'Inscription entreprise / hébergement', 'Registrazione attività / struttura', 'Регистрация бизнеса / размещения', 'İşletme / konaklama kaydı', '商家 / 住宿注册'],
  'topic1': ['مشکل فنی در برنامه', 'Technical problem in the app', 'مشكلة تقنية في التطبيق', 'Technisches Problem in der App', 'Problema técnico en la app', 'Problème technique dans l\'application', 'Problema tecnico nell\'app', 'Техническая проблема в приложении', 'Uygulamada teknik sorun', '应用技术问题'],
  'topic2': ['تبلیغات و جایگاه VIP', 'Advertising and VIP spot', 'الإعلان ومكان VIP', 'Werbung und VIP-Platz', 'Publicidad y puesto VIP', 'Publicité et place VIP', 'Pubblicità e posto VIP', 'Реклама и VIP-место', 'Reklam ve VIP yeri', '广告与 VIP 位置'],
  'topic3': ['سؤال دیگر', 'Another question', 'سؤال آخر', 'Andere Frage', 'Otra pregunta', 'Autre question', 'Altra domanda', 'Другой вопрос', 'Başka bir soru', '其他问题'],
  'hint': ['توضیح کوتاه (اختیاری)', 'Short details (optional)', 'تفاصيل قصيرة (اختياري)', 'Kurze Angaben (optional)', 'Detalles breves (opcional)', 'Détails brefs (facultatif)', 'Dettagli brevi (facoltativo)', 'Краткие детали (необязательно)', 'Kısa ayrıntılar (isteğe bağlı)', '简要说明（可选）'],
  'preview': ['پیش‌نمایش پیام', 'Message preview', 'معاينة الرسالة', 'Nachrichtenvorschau', 'Vista previa del mensaje', 'Aperçu du message', 'Anteprima del messaggio', 'Предпросмотр сообщения', 'Mesaj önizlemesi', '消息预览'],
  'sendVia': ['ارسال از طریق', 'Send via', 'الإرسال عبر', 'Senden über', 'Enviar por', 'Envoyer via', 'Invia tramite', 'Отправить через', 'Şununla gönder', '通过以下方式发送'],
  'copy': ['کپی پیام', 'Copy message', 'نسخ الرسالة', 'Nachricht kopieren', 'Copiar mensaje', 'Copier le message', 'Copia messaggio', 'Копировать сообщение', 'Mesajı kopyala', '复制消息'],
  'copied': ['پیام کپی شد؛ در چت بچسبانید.', 'Message copied; paste it in the chat.', 'تم نسخ الرسالة؛ الصقها في المحادثة.', 'Nachricht kopiert; im Chat einfügen.', 'Mensaje copiado; péguelo en el chat.', 'Message copié ; collez-le dans le chat.', 'Messaggio copiato; incollalo nella chat.', 'Сообщение скопировано; вставьте его в чат.', 'Mesaj kopyalandı; sohbete yapıştırın.', '消息已复制，请粘贴到聊天中。'],
  'tgNote': ['اگر متن وارد نشد، پیام کپی شده را بچسبانید.', 'If the text did not appear, paste the copied message.', 'إذا لم يظهر النص، الصق الرسالة المنسوخة.', 'Falls der Text nicht erscheint, fügen Sie die kopierte Nachricht ein.', 'Si el texto no apareció, pegue el mensaje copiado.', 'Si le texte n\'est pas apparu, collez le message copié.', 'Se il testo non è comparso, incolla il messaggio copiato.', 'Если текст не появился, вставьте скопированное сообщение.', 'Metin görünmediyse kopyalanan mesajı yapıştırın.', '如果文字未出现，请粘贴已复制的消息。'],
  'failOpen': ['باز نشد.', 'Could not open.', 'تعذر الفتح.', 'Konnte nicht geöffnet werden.', 'No se pudo abrir.', 'Impossible d\'ouvrir.', 'Impossibile aprire.', 'Не удалось открыть.', 'Açılamadı.', '无法打开。'],
  'who': ['کاربر سایروس توریست', 'a Cyrus Tourist user', 'مستخدم سايروس توريست', 'ein Cyrus-Tourist-Nutzer', 'un usuario de Cyrus Tourist', 'un utilisateur de Cyrus Tourist', 'un utente di Cyrus Tourist', 'пользователь Cyrus Tourist', 'bir Cyrus Tourist kullanıcısı', 'Cyrus Tourist 用户'],
  'msgHead': ['سلام، من «{who}» هستم.\nموضوع: {topic}', 'Hello, I am "{who}".\nTopic: {topic}', 'مرحباً، أنا «{who}».\nالموضوع: {topic}', 'Hallo, ich bin „{who}“.\nThema: {topic}', 'Hola, soy «{who}».\nTema: {topic}', 'Bonjour, je suis « {who} ».\nSujet : {topic}', 'Ciao, sono «{who}».\nArgomento: {topic}', 'Здравствуйте, я «{who}».\nТема: {topic}', 'Merhaba, ben "{who}".\nKonu: {topic}', '您好，我是“{who}”。\n主题：{topic}'],
  'msgTail': ['لطفاً راهنمایی کنید.', 'Please help me.', 'يرجى المساعدة.', 'Bitte helfen Sie mir.', 'Por favor, ayúdeme.', 'Merci de m\'aider.', 'Per favore, aiutatemi.', 'Пожалуйста, помогите.', 'Lütfen yardımcı olun.', '请协助我。'],
  'wa': ['واتساپ', 'WhatsApp', 'واتساب', 'WhatsApp', 'WhatsApp', 'WhatsApp', 'WhatsApp', 'WhatsApp', 'WhatsApp', 'WhatsApp'],
  'tg': ['تلگرام', 'Telegram', 'تيليجرام', 'Telegram', 'Telegram', 'Telegram', 'Telegram', 'Telegram', 'Telegram', 'Telegram'],
  'ei': ['ایتا', 'Eitaa', 'إيتا', 'Eitaa', 'Eitaa', 'Eitaa', 'Eitaa', 'Eitaa', 'Eitaa', 'Eitaa'],
};

class _SupportChatPageState extends State<SupportChatPage> {
  static const Color _bg = Color(0xff06121d);
  static const Color _panel = Color(0xff0b2636);
  static const Color _gold = Color(0xffffd36a);

  final TextEditingController _details = TextEditingController();
  int _topic = 0;
  String _name = '';

  String get _lang => widget.languageCode;
  bool get _rtl => _lang == 'fa' || _lang == 'ar';

  String _s(String key) {
    final list = _kChat[key];
    if (list == null) return key;
    var idx = _kChatLangs.indexOf(_lang);
    if (idx < 0) idx = 1;
    return list[idx];
  }

  @override
  void initState() {
    super.initState();
    _topic = widget.initialTopic.clamp(0, _kTopicIcons.length - 1);
    _details.text = widget.initialDetails;
    _loadName();
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    try {
      final p = await UserProfileService.load();
      final n = p.displayName.trim().isNotEmpty
          ? p.displayName.trim()
          : p.username.trim();
      if (mounted) setState(() => _name = n);
    } catch (_) {}
  }

  String _topicText(int i) => _s('topic$i');

  String get _message {
    final who = _name.isEmpty ? _s('who') : _name;
    final extra = _details.text.trim();
    final head = _s('msgHead')
        .replaceAll('{who}', who)
        .replaceAll('{topic}', _topicText(_topic));
    return '$head${extra.isEmpty ? '' : '\n$extra'}\n${_s('msgTail')}';
  }

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(_s('failOpen'));
    } catch (_) {
      _toast(_s('failOpen'));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copy({bool hint = true}) async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (hint) {
      _toast(_s('copied'));
    }
  }

  Future<void> _whatsapp() async {
    final number = SupportPage.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final intl = number.startsWith('0') ? '98${number.substring(1)}' : number;
    await _open(Uri.https('wa.me', '/$intl', {'text': _message}));
  }

  Future<void> _telegram() async {
    await _copy(hint: false); // اگر متن خودکار وارد نشد، کاربر بچسباند
    final user = SupportPage.telegramUsername.replaceAll('@', '');
    await _open(Uri.https('t.me', '/$user', {'text': _message}));
    _toast(_s('tgNote'));
  }

  Future<void> _eitaa() async {
    await _copy();
    await _open(Uri.parse(SupportPage.eitaaUrl));
  }

  Widget _channel(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xff071722), size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff071722),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _bg,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: Text(
            _s('title'),
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                _s('ask'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _kTopicIcons.length; i++)
                    ChoiceChip(
                      avatar: Icon(
                        _kTopicIcons[i],
                        size: 18,
                        color: _topic == i ? const Color(0xff071722) : _gold,
                      ),
                      label: Text(_topicText(i)),
                      selected: _topic == i,
                      selectedColor: _gold,
                      backgroundColor: _panel,
                      labelStyle: TextStyle(
                        color: _topic == i ? const Color(0xff071722) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                      side: const BorderSide(color: Color(0xff1d3a4d)),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _topic = i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _details,
                maxLines: 3,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: _s('hint'),
                  hintStyle: const TextStyle(color: Color(0xff8fa5b2)),
                  filled: true,
                  fillColor: _panel,
                  counterStyle: const TextStyle(color: Color(0xff8fa5b2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xff1d3a4d)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xff1d3a4d)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _s('preview'),
                style: const TextStyle(
                    color: _gold, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff0a1c27),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff2e6f8f)),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(
                      color: Color(0xffcfe0ea), fontSize: 13, height: 1.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _s('sendVia'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _channel(_s('wa'),
                      Icons.chat_rounded, const Color(0xff3ddc84), _whatsapp),
                  const SizedBox(width: 10),
                  _channel(_s('tg'),
                      Icons.send_rounded, const Color(0xff4cc3ff), _telegram),
                  const SizedBox(width: 10),
                  _channel(_s('ei'),
                      Icons.forum_rounded, const Color(0xffffb347), _eitaa),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded, color: _gold, size: 18),
                label: Text(
                  _s('copy'),
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _gold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
