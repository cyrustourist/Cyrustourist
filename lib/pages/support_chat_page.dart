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
  const SupportChatPage({super.key, this.languageCode = 'fa'});

  final String languageCode;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _Topic {
  const _Topic(this.fa, this.en, this.ar, this.icon);
  final String fa;
  final String en;
  final String ar;
  final IconData icon;
}

const List<_Topic> _kTopics = [
  _Topic('ثبت‌نام اقامتگاه / کسب‌وکار', 'Business / stay registration',
      'تسجيل نشاط / إقامة', Icons.app_registration_rounded),
  _Topic('مشکل فنی در برنامه', 'Technical problem in the app',
      'مشكلة تقنية في التطبيق', Icons.build_circle_rounded),
  _Topic('تبلیغات و جایگاه VIP', 'Advertising and VIP spot',
      'الإعلان ومكان VIP', Icons.workspace_premium_rounded),
  _Topic('سؤال دیگر', 'Another question', 'سؤال آخر',
      Icons.help_outline_rounded),
];

class _SupportChatPageState extends State<SupportChatPage> {
  static const Color _bg = Color(0xff06121d);
  static const Color _panel = Color(0xff0b2636);
  static const Color _gold = Color(0xffffd36a);

  final TextEditingController _details = TextEditingController();
  int _topic = 0;
  String _name = '';

  String get _lang => widget.languageCode;
  bool get _rtl => _lang == 'fa' || _lang == 'ar';

  String _t(String fa, String en, String ar) {
    switch (_lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  @override
  void initState() {
    super.initState();
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

  String _topicText(_Topic t) => _t(t.fa, t.en, t.ar);

  String get _message {
    final who = _name.isEmpty
        ? _t('کاربر سایروس توریست', 'a Cyrus Tourist user', 'مستخدم سايروس توريست')
        : _name;
    final extra = _details.text.trim();
    return _t(
      'سلام، من «$who» هستم.\nموضوع: ${_topicText(_kTopics[_topic])}'
          '${extra.isEmpty ? '' : '\n$extra'}\nلطفاً راهنمایی کنید.',
      'Hello, I am "$who".\nTopic: ${_topicText(_kTopics[_topic])}'
          '${extra.isEmpty ? '' : '\n$extra'}\nPlease help me.',
      'مرحباً، أنا «$who».\nالموضوع: ${_topicText(_kTopics[_topic])}'
          '${extra.isEmpty ? '' : '\n$extra'}\nيرجى المساعدة.',
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(_t('باز نشد.', 'Could not open.', 'تعذر الفتح.'));
    } catch (_) {
      _toast(_t('باز نشد.', 'Could not open.', 'تعذر الفتح.'));
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
      _toast(_t('پیام کپی شد؛ در چت بچسبانید.', 'Message copied; paste it in the chat.',
          'تم نسخ الرسالة؛ الصقها في المحادثة.'));
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
    _toast(_t('اگر متن وارد نشد، پیام کپی شده را بچسبانید.',
        'If the text did not appear, paste the copied message.',
        'إذا لم يظهر النص، الصق الرسالة المنسوخة.'));
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
            _t('چت با پشتیبانی', 'Chat with support', 'الدردشة مع الدعم'),
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                _t('موضوع پیام شما چیست؟', 'What is your message about?',
                    'ما موضوع رسالتك؟'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _kTopics.length; i++)
                    ChoiceChip(
                      avatar: Icon(
                        _kTopics[i].icon,
                        size: 18,
                        color: _topic == i ? const Color(0xff071722) : _gold,
                      ),
                      label: Text(_topicText(_kTopics[i])),
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
                  hintText: _t('توضیح کوتاه (اختیاری)', 'Short details (optional)',
                      'تفاصيل قصيرة (اختياري)'),
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
                _t('پیش‌نمایش پیام', 'Message preview', 'معاينة الرسالة'),
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
                _t('ارسال از طریق', 'Send via', 'الإرسال عبر'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _channel(_t('واتساپ', 'WhatsApp', 'واتساب'),
                      Icons.chat_rounded, const Color(0xff3ddc84), _whatsapp),
                  const SizedBox(width: 10),
                  _channel(_t('تلگرام', 'Telegram', 'تيليجرام'),
                      Icons.send_rounded, const Color(0xff4cc3ff), _telegram),
                  const SizedBox(width: 10),
                  _channel(_t('ایتا', 'Eitaa', 'إيتا'),
                      Icons.forum_rounded, const Color(0xffffb347), _eitaa),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded, color: _gold, size: 18),
                label: Text(
                  _t('کپی پیام', 'Copy message', 'نسخ الرسالة'),
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
