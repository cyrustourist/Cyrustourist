import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';

// ===================== رنگ‌ها (هماهنگ با سایت و صفحه‌های ثبت‌نام قبلی) =====================

const Color _bg = Color(0xff070f18);
const Color _card = Color(0xff0d2432);
const Color _cardAlt = Color(0xff0a1c28);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff22e0ad);

const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];
const List<Color> _goldGradient = [Color(0xffffd36a), Color(0xfff5a623)];
const List<Color> _callGradient = [Color(0xff34d399), Color(0xff059669)];
const List<Color> _telegramGradient = [Color(0xff4fb6e8), Color(0xff229ed9)];
const List<Color> _whatsappGradient = [Color(0xff34d67a), Color(0xff25d366)];
const List<Color> _eitaaGradient = [Color(0xff5fc9a8), Color(0xff0f9d78)];

/// اطلاعات پشتیبانی — همان مقادیر residences-registration.js سایت
class _Support {
  static const String phone = '09153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
  static const String whatsapp = 'https://wa.me/989153448818';
  static const String eitaa = 'https://eitaa.com/cyrustourist';
}

const List<String> _kCategories = [
  'residence',
  'cafe',
  'restaurant',
  'tourleader',
  'health',
  'agency',
  'services',
  'handicraft',
  'partner',
];

const List<List<String>> _kSocials = [
  ['instagram', 'اینستاگرام / Instagram'],
  ['website', 'وب‌سایت / Website'],
  ['youtube', 'یوتیوب / YouTube'],
  ['tiktok', 'تیک‌تاک / TikTok'],
  ['aparat', 'آپارات / Aparat'],
  ['telegram', 'تلگرام / Telegram'],
  ['whatsapp', 'واتساپ / WhatsApp'],
  ['eitaa', 'ایتا / Eitaa'],
];

// ===================== متن‌ها (fa / en / ar — مطابق سایت؛ سایر زبان‌ها انگلیسی) =====================

const Map<String, Map<String, String>> _kText = {
  'fa': {
    'titleTemplate': '➕ ثبت {cat} در سایروس توریست',
    'subtitle': 'کسب‌وکار یا خدمات گردشگری خود را معرفی کنید و در سامانه گردشگری سایروس توریست دیده شوید.',
    'benefitsTitle': '🌟 مزایای ثبت‌نام در سایروس توریست',
    'rulesTitle': '📋 قوانین و شرایط خدمات',
    'rules': 'ثبت‌نام در سایروس توریست با پرداخت حق عضویت یک‌ساله انجام می‌شود و صرفاً برای حضور در فضای تبلیغاتی سایروس توریست و معرفی شما به کاربران است. این خدمت در چارچوب خدمات دیجیتال، تبلیغاتی و زیرساخت‌های مبتنی بر اینترنت ارائه می‌شود. در صورت اختلال، محدودیت یا قطعی اینترنت، مخابرات یا سرویس‌های شخص ثالث که خارج از کنترل سایروس توریست است، سایروس توریست مسئولیت مستقیمی نخواهد داشت.',
    'continueButton': '➡️ ادامه',
    'back': '↩ برگشت',
    'accept': 'قوانین و شرایط خدمات سایروس توریست را مطالعه کرده‌ام و می‌پذیرم.',
    'benefit1': '🎬 نمایش فیلم معرفی در سایت و نرم‌افزار سایروس توریست',
    'benefit1Desc': 'لینک فیلم معرفی خود را ارسال کنید یا در صورت درخواست، تولید فیلم توسط سایروس توریست انجام می‌شود.',
    'benefit2': '🗺️ مسیریابی',
    'benefit2Desc': 'گردشگران می‌توانند مسیر رسیدن به شما را مشاهده کنند.',
    'benefit3': '📞 تماس مستقیم گردشگر',
    'benefit3Desc': 'امکان تماس مستقیم گردشگر با شما در صورت فعال بودن شماره تماس.',
    'benefit4': '📸 نمایش اینستاگرام',
    'benefit4Desc': 'صفحه اینستاگرام اقامتگاه در کارت معرفی نمایش داده می‌شود.',
    'benefit5': '🌐 نمایش وب‌سایت',
    'benefit5Desc': 'وب‌سایت اقامتگاه می‌تواند در صفحه معرفی قرار گیرد.',
    'benefit6': '⭐ امتیاز گردشگران',
    'benefit6Desc': 'گردشگران می‌توانند از ۱ تا ۵ ستاره به شما امتیاز دهند.',
    'benefit7': '📢 حضور در فضای تبلیغاتی سایروس توریست',
    'benefit7Desc': 'معرفی مستمر شما در وب‌سایت، نرم‌افزار و شبکه‌های اجتماعی سایروس توریست در طول دوره عضویت.',
    'benefit8': '🤝 دیده‌شدن توسط گردشگران بیشتر',
    'benefit8Desc': 'دسترسی گردشگران داخلی و خارجی به اطلاعات و راه‌های ارتباطی شما از طریق یک سامانه واحد.',
    'f_title': '📝 فرم ثبت‌نام',
    'f_desc': 'اطلاعات زیر را تکمیل کنید. فیلدهای ستاره‌دار الزامی هستند.',
    'f_name': 'نام کسب‌وکار / اقامتگاه *',
    'f_category': 'دسته‌بندی *',
    'f_phone': 'شماره تلفن *',
    'f_video': 'لینک فیلم معرفی',
    'f_socials': 'شبکه‌های اجتماعی (اختیاری)',
    'f_confirm': 'اطلاعات واردشده را بررسی کرده‌ام و صحت آن را تأیید می‌کنم. *',
    'f_submit': '✅ تأیید و ارسال',
    'f_errName': 'نام را وارد کنید.',
    'f_errPhone': 'شماره تلفن معتبر وارد کنید.',
    'f_errLink': 'لینک واردشده معتبر نیست.',
    'f_errConfirm': 'تأیید نهایی الزامی است.',
    'f_sendTitle': 'ارسال اطلاعات',
    'f_sendDesc': 'اطلاعات شما کپی شد. یکی از پیام‌رسان‌ها را باز کنید و پیام را برای پشتیبانی ارسال (paste) کنید.',
    'f_msgHead': 'درخواست ثبت‌نام در سایروس توریست',
    'hubTitle': '➕ ثبت‌نام در سایروس توریست',
    'hubDesc': 'اقامتگاه، کافه، رستوران، لیدر تور، گردشگری سلامت، آژانس مسافرتی، خدمات گردشگری، صنایع‌دستی یا همکاری گردشگری خود را معرفی کنید و از خدمات معرفی، نمایش فیلم، مسیریابی، تماس مستقیم و امتیاز گردشگران بهره‌مند شوید.',
    'regBtn': '➕ ثبت {cat}',
    'callBtn': '📞 تماس مستقیم',
    'tgBtn': '✈️ تلگرام',
    'waBtn': '💬 واتساپ',
    'eitaaBtn': '💬 ایتا',
    'copyAgain': '📋 کپی دوباره پیام',
    'copied': 'پیام کپی شد.',
    'sendWa': 'ارسال در واتساپ',
    'done': '✔ پایان',
    'linkErr': 'امکان باز کردن لینک وجود ندارد.',
    'cat_residence': 'اقامتگاه',
    'cat_cafe': 'کافه',
    'cat_restaurant': 'رستوران',
    'cat_tourleader': 'لیدر تور',
    'cat_health': 'گردشگری سلامت',
    'cat_agency': 'آژانس مسافرتی',
    'cat_services': 'خدمات گردشگری',
    'cat_handicraft': 'صنایع دستی',
    'cat_partner': 'همکار گردشگری',
  },
  'en': {
    'titleTemplate': '➕ Register {cat} on Cyrus Tourist',
    'subtitle': 'Introduce your tourism business or service and make it visible on Cyrus Tourist.',
    'benefitsTitle': '🌟 Registration Benefits',
    'rulesTitle': '📋 Terms and Conditions',
    'rules': 'Registration with Cyrus Tourist is completed by paying a one-year membership fee and is solely for having a presence in the Cyrus Tourist advertising space and being introduced to users. This service is provided within the framework of digital, advertising and internet-based infrastructure services. In the event of disruption, limitation or interruption of internet, telecommunications or third-party services beyond the control of Cyrus Tourist, Cyrus Tourist shall not be directly responsible.',
    'continueButton': '➡️ Continue',
    'back': '↩ Back',
    'accept': 'I have read and accept the Cyrus Tourist terms and conditions.',
    'benefit1': '🎬 Residence video',
    'benefit1Desc': 'Send your residence video link, or request video production by Cyrus Tourist.',
    'benefit2': '🗺️ Route navigation',
    'benefit2Desc': 'Tourists can find the route to your residence.',
    'benefit3': '📞 Direct tourist call',
    'benefit3Desc': 'Tourists can directly contact the residence when a phone number is enabled.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'Your residence Instagram page can be displayed.',
    'benefit5': '🌐 Website',
    'benefit5Desc': 'Your residence website can be displayed on the profile.',
    'benefit6': '⭐ Tourist ratings',
    'benefit6Desc': 'Tourists can rate you from 1 to 5 stars.',
    'benefit7': '📢 Presence in Cyrus Tourist\'s advertising space',
    'benefit7Desc': 'Ongoing visibility on the Cyrus Tourist website, app and social media during your membership period.',
    'benefit8': '🤝 Reach more tourists',
    'benefit8Desc': 'Domestic and international tourists can find your information and contact details in one place.',
    'f_title': '📝 Registration Form',
    'f_desc': 'Please complete the details below. Fields marked * are required.',
    'f_name': 'Business / Residence name *',
    'f_category': 'Category *',
    'f_phone': 'Phone number *',
    'f_video': 'Intro video link',
    'f_socials': 'Social networks (optional)',
    'f_confirm': 'I have reviewed the information and confirm it is correct. *',
    'f_submit': '✅ Confirm and send',
    'f_errName': 'Please enter the name.',
    'f_errPhone': 'Please enter a valid phone number.',
    'f_errLink': 'The link is not valid.',
    'f_errConfirm': 'Final confirmation is required.',
    'f_sendTitle': 'Send your information',
    'f_sendDesc': 'Your details were copied. Open a messenger and paste the message to support.',
    'f_msgHead': 'Cyrus Tourist registration request',
    'hubTitle': '➕ Register on Cyrus Tourist',
    'hubDesc': 'Introduce your residence, cafe, restaurant, tour leader service, health tourism, travel agency, tourism services, handicrafts or tourism partnership, and benefit from introduction, video showcase, navigation, direct contact and tourist ratings.',
    'regBtn': '➕ Register {cat}',
    'callBtn': '📞 Call directly',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'copyAgain': '📋 Copy message again',
    'copied': 'Message copied.',
    'sendWa': 'Send via WhatsApp',
    'done': '✔ Done',
    'linkErr': 'Unable to open the link.',
    'cat_residence': 'Residence',
    'cat_cafe': 'Cafe',
    'cat_restaurant': 'Restaurant',
    'cat_tourleader': 'Tour Leader',
    'cat_health': 'Health Tourism',
    'cat_agency': 'Travel Agency',
    'cat_services': 'Tourism Services',
    'cat_handicraft': 'Handicrafts',
    'cat_partner': 'Tourism Partner',
  },
  'ar': {
    'titleTemplate': '➕ تسجيل {cat} في سايروس توريست',
    'subtitle': 'عرّف بعملك أو خدماتك السياحية واظهر في منصة سايروس توريست السياحية.',
    'benefitsTitle': '🌟 مزايا التسجيل',
    'rulesTitle': '📋 الشروط والأحكام',
    'rules': 'يتم التسجيل في سايروس توريست عبر دفع رسوم عضوية لمدة سنة واحدة، وهو مخصص حصراً للتواجد في المساحة الإعلانية لسايروس توريست وتعريفكم للمستخدمين. تُقدَّم هذه الخدمة ضمن إطار الخدمات الرقمية والإعلانية والبنى التحتية القائمة على الإنترنت. وفي حال حدوث خلل أو تقييد أو انقطاع في خدمات الإنترنت أو الاتصالات أو خدمات الجهات الخارجية الخارجة عن سيطرة سايروس توريست، فلا تتحمل سايروس توريست مسؤولية مباشرة.',
    'continueButton': '➡️ متابعة',
    'back': '↩ رجوع',
    'accept': 'لقد قرأت شروط خدمات سايروس توريست وأوافق عليها.',
    'benefit1': '🎬 عرض فيديو مكان الإقامة',
    'benefit1Desc': 'يمكنك إرسال رابط الفيديو أو طلب إنتاج فيديو من سايروس توريست.',
    'benefit2': '🗺️ الملاحة',
    'benefit2Desc': 'يمكن للسياح مشاهدة الطريق إلى مكان الإقامة.',
    'benefit3': '📞 اتصال مباشر',
    'benefit3Desc': 'يمكن للسائح الاتصال مباشرة بمكان الإقامة عند تفعيل رقم الهاتف.',
    'benefit4': '📸 إنستغرام',
    'benefit4Desc': 'يمكن عرض صفحة إنستغرام الخاصة بمكان الإقامة.',
    'benefit5': '🌐 الموقع الإلكتروني',
    'benefit5Desc': 'يمكن عرض الموقع الإلكتروني لمكان الإقامة.',
    'benefit6': '⭐ تقييم السياح',
    'benefit6Desc': 'يمكن للسياح تقييمك من نجمة إلى خمس نجوم.',
    'benefit7': '📢 التواجد في المساحة الإعلانية لسايروس توريست',
    'benefit7Desc': 'ظهور مستمر لك على موقع وتطبيق ووسائل التواصل الاجتماعي لسايروس توريست خلال فترة العضوية.',
    'benefit8': '🤝 الوصول إلى مزيد من السياح',
    'benefit8Desc': 'يمكن للسياح المحليين والأجانب الوصول إلى معلوماتك وطرق التواصل معك من خلال منصة واحدة.',
    'f_title': '📝 نموذج التسجيل',
    'f_desc': 'يرجى إكمال البيانات أدناه. الحقول المعلَّمة بـ * إلزامية.',
    'f_name': 'اسم النشاط / الإقامة *',
    'f_category': 'الفئة *',
    'f_phone': 'رقم الهاتف *',
    'f_video': 'رابط فيديو التعريف',
    'f_socials': 'شبكات التواصل (اختياري)',
    'f_confirm': 'لقد راجعت المعلومات وأؤكد صحتها. *',
    'f_submit': '✅ تأكيد وإرسال',
    'f_errName': 'يرجى إدخال الاسم.',
    'f_errPhone': 'يرجى إدخال رقم هاتف صحيح.',
    'f_errLink': 'الرابط غير صالح.',
    'f_errConfirm': 'التأكيد النهائي مطلوب.',
    'f_sendTitle': 'إرسال المعلومات',
    'f_sendDesc': 'تم نسخ بياناتكم. افتحوا أحد التطبيقات والصقوا الرسالة للدعم.',
    'f_msgHead': 'طلب تسجيل في سايروس توريست',
    'hubTitle': '➕ التسجيل في سايروس توريست',
    'hubDesc': 'عرّف بمكان إقامتك أو مقهاك أو مطعمك أو خدمة قيادة الجولات أو السياحة العلاجية أو وكالة السفر أو الخدمات السياحية أو الصناعات اليدوية أو شراكتك السياحية، واستفد من التعريف وعرض الفيديو والملاحة والاتصال المباشر وتقييمات السياح.',
    'regBtn': '➕ تسجيل {cat}',
    'callBtn': '📞 اتصال مباشر',
    'tgBtn': '✈️ تيليجرام',
    'waBtn': '💬 واتساب',
    'eitaaBtn': '💬 إيتا',
    'copyAgain': '📋 نسخ الرسالة مرة أخرى',
    'copied': 'تم نسخ الرسالة.',
    'sendWa': 'إرسال عبر واتساب',
    'done': '✔ إنهاء',
    'linkErr': 'تعذّر فتح الرابط.',
    'cat_residence': 'الإقامة',
    'cat_cafe': 'مقهى',
    'cat_restaurant': 'مطعم',
    'cat_tourleader': 'قائد الجولة',
    'cat_health': 'السياحة العلاجية',
    'cat_agency': 'وكالة سفر',
    'cat_services': 'خدمات سياحية',
    'cat_handicraft': 'الصناعات اليدوية',
    'cat_partner': 'شريك سياحي',
  },
};

const Map<String, Map<String, String>> _kExtra = {
  'fa': {
    'sendTg': '✈️ ارسال در تلگرام',
    'sendEitaa': '💬 ارسال در ایتا',
    'pasteHint': 'پیام کپی شد. در گفتگوی باز شده Paste کنید و ارسال بزنید.',
  },
  'en': {
    'sendTg': '✈️ Send via Telegram',
    'sendEitaa': '💬 Send via Eitaa',
    'pasteHint': 'Message copied. Paste it in the chat that opens and send.',
  },
  'ar': {
    'sendTg': '✈️ إرسال عبر تيليجرام',
    'sendEitaa': '💬 إرسال عبر إيتا',
    'pasteHint': 'تم نسخ الرسالة. الصقها في المحادثة التي ستفتح ثم أرسلها.',
  },
};

String _t(String key) {
  final lang = MenuLanguage.current;
  final map = _kText[lang] ?? _kText['en']!;
  final extra = _kExtra[lang] ?? _kExtra['en']!;
  return map[key] ?? extra[key] ?? _kText['fa']![key] ?? _kExtra['fa']![key] ?? key;
}

String _catName(String cat) => _t('cat_$cat');

Future<void> _openUrl(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('linkErr'))));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('linkErr'))));
    }
  }
}

bool _isValidLink(String v) {
  if (v.isEmpty) return true;
  final withScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(v) ? v : 'https://$v';
  final uri = Uri.tryParse(withScheme);
  return uri != null && uri.host.contains('.') && !uri.host.startsWith('.') && !uri.host.endsWith('.');
}

enum _Step { hub, terms, form, support }

/// صفحهٔ ثبت‌نام داخل برنامه — همان روال و ظاهر بخش «ثبت‌نام در سایروس توریست» سایت:
/// انتخاب دسته ← مزایا و قوانین ← فرم ← ارسال به پشتیبانی.
class RegistrationHubPage extends StatefulWidget {
  const RegistrationHubPage({super.key, this.initialCategory});

  /// اگر مقدار بدهید، مستقیم به مرحلهٔ قوانین همان دسته می‌رود.
  final String? initialCategory;

  @override
  State<RegistrationHubPage> createState() => _RegistrationHubPageState();
}

class _RegistrationHubPageState extends State<RegistrationHubPage> {
  _Step _step = _Step.hub;
  String _category = 'residence';
  bool _accepted = false;
  bool _confirmed = false;
  String? _error;
  String _message = '';

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _video = TextEditingController();
  final Map<String, TextEditingController> _socials = {
    for (final s in _kSocials) s[0]: TextEditingController(),
  };
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final c = widget.initialCategory;
    if (c != null && _kCategories.contains(c)) {
      _category = c;
      _step = _Step.terms;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _video.dispose();
    for (final c in _socials.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _go(_Step s) {
    setState(() {
      _step = s;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _openCategory(String cat) {
    setState(() {
      _category = cat;
      _accepted = false;
    });
    _go(_Step.terms);
  }

  void _onBack() {
    switch (_step) {
      case _Step.hub:
        Navigator.of(context).pop();
        break;
      case _Step.terms:
        _go(_Step.hub);
        break;
      case _Step.form:
        _go(_Step.terms);
        break;
      case _Step.support:
        _go(_Step.form);
        break;
    }
  }

  String _buildMessage() {
    String clean(String k) => _t(k).replaceAll(' *', '');
    final lines = <String>[
      _t('f_msgHead'),
      '',
      '${clean('f_name')}: ${_name.text.trim()}',
      '${clean('f_category')}: ${_catName(_category)}',
      '${clean('f_phone')}: ${_phone.text.trim()}',
    ];
    if (_video.text.trim().isNotEmpty) {
      lines.add('${_t('f_video')}: ${_video.text.trim()}');
    }
    for (final s in _kSocials) {
      final v = _socials[s[0]]!.text.trim();
      if (v.isNotEmpty) {
        lines.add('${s[1].split(' / ').last}: $v');
      }
    }
    return lines.join('\n');
  }

  void _submit() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_name.text.trim().isEmpty) {
      return setState(() => _error = _t('f_errName'));
    }
    if (digits.length < 8) {
      return setState(() => _error = _t('f_errPhone'));
    }
    final links = <String>[_video.text.trim(), ..._socials.values.map((c) => c.text.trim())];
    if (!links.every(_isValidLink)) {
      return setState(() => _error = _t('f_errLink'));
    }
    if (!_confirmed) {
      return setState(() => _error = _t('f_errConfirm'));
    }
    _message = _buildMessage();
    Clipboard.setData(ClipboardData(text: _message));
    _go(_Step.support);
  }

  // ===================== ساختار صفحه =====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: _step == _Step.hub,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: _stepBody(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final title = _step == _Step.hub
        ? _t('hubTitle')
        : _t('titleTemplate').replaceAll('{cat}', _catName(_category));
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: _brandGradient),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _onBack,
            icon: Icon(
              MenuLanguage.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case _Step.hub:
        return _hubStep();
      case _Step.terms:
        return _termsStep();
      case _Step.form:
        return _formStep();
      case _Step.support:
        return _supportStep();
    }
  }

  // ===================== مرحلهٔ ۰: کادر ثبت‌نام (مثل سایت) =====================

  Widget _hubStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _boxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('hubTitle'),
                style: const TextStyle(color: _goldBright, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _t('hubDesc'),
                style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.9),
              ),
              const SizedBox(height: 14),
              for (final cat in _kCategories) ...[
                _gradientButton(
                  label: _t('regBtn').replaceAll('{cat}', _catName(cat)),
                  gradient: _goldGradient,
                  textColor: const Color(0xff1a1200),
                  onTap: () => _openCategory(cat),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _contactButtons(),
      ],
    );
  }

  Widget _contactButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _contactChip(_t('callBtn'), _callGradient, () => _openUrl(context, 'tel:${_Support.phone}')),
        _contactChip(_t('tgBtn'), _telegramGradient, () => _openUrl(context, _Support.telegram)),
        _contactChip(_t('waBtn'), _whatsappGradient, () => _openUrl(context, _Support.whatsapp)),
        _contactChip(_t('eitaaBtn'), _eitaaGradient, () => _openUrl(context, _Support.eitaa)),
      ],
    );
  }

  Widget _contactChip(String label, List<Color> gradient, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  // ===================== مرحلهٔ ۱: مزایا و قوانین =====================

  Widget _termsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('subtitle'),
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.9),
        ),
        const SizedBox(height: 16),
        _sectionTitle(_t('benefitsTitle')),
        for (var i = 1; i <= 8; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: _boxDecoration(alt: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('benefit$i'),
                  style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.7),
                ),
                const SizedBox(height: 4),
                Text(
                  _t('benefit${i}Desc'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.8),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _sectionTitle(_t('rulesTitle')),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _boxDecoration(),
          child: Text(
            _t('rules'),
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 2),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _accepted = !_accepted),
          child: Row(
            children: [
              Checkbox(
                value: _accepted,
                activeColor: _teal,
                onChanged: (v) => setState(() => _accepted = v ?? false),
              ),
              Expanded(
                child: Text(
                  _t('accept'),
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: _accepted ? 1 : 0.45,
          child: _gradientButton(
            label: _t('continueButton'),
            gradient: _goldGradient,
            textColor: const Color(0xff1a1200),
            onTap: _accepted ? () => _go(_Step.form) : null,
          ),
        ),
        const SizedBox(height: 8),
        _outlineButton(_t('back'), () => _go(_Step.hub)),
      ],
    );
  }

  // ===================== مرحلهٔ ۲: فرم =====================

  Widget _formStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(_t('f_title')),
        Text(
          _t('f_desc'),
          style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.8),
        ),
        const SizedBox(height: 14),
        _field(_t('f_name'), _name, maxLength: 120),
        _label(_t('f_category')),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _inputDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: _card,
              iconEnabledColor: _gold,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: [
                for (final c in _kCategories)
                  DropdownMenuItem<String>(value: c, child: Text(_catName(c))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
          ),
        ),
        _field(_t('f_phone'), _phone,
            keyboard: TextInputType.phone, ltr: true, maxLength: 20, hint: '09xxxxxxxxx'),
        _field(_t('f_video'), _video, keyboard: TextInputType.url, ltr: true, hint: 'https://'),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            _t('f_socials'),
            style: const TextStyle(color: _goldBright, fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
        ),
        for (final s in _kSocials)
          _field(s[1], _socials[s[0]]!, keyboard: TextInputType.url, ltr: true, hint: 'https://'),
        InkWell(
          onTap: () => setState(() => _confirmed = !_confirmed),
          child: Row(
            children: [
              Checkbox(
                value: _confirmed,
                activeColor: _teal,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
              ),
              Expanded(
                child: Text(
                  _t('f_confirm'),
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.8),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xffff8a80), fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(height: 6),
        _gradientButton(
          label: _t('f_submit'),
          gradient: _goldGradient,
          textColor: const Color(0xff1a1200),
          onTap: _submit,
        ),
        const SizedBox(height: 8),
        _outlineButton(_t('back'), () => _go(_Step.terms)),
      ],
    );
  }

  // ===================== مرحلهٔ ۳: ارسال به پشتیبانی =====================

  /// پیام را کپی می‌کند و گفتگوی پشتیبانی را باز می‌کند (تلگرام و ایتا متن آماده را
  /// از لینک نمی‌پذیرند؛ کاربر فقط Paste می‌کند).
  Future<void> _copyAndOpen(String url) async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('pasteHint'))));
    await _openUrl(context, url);
  }

  Widget _supportStep() {
    final waUrl = '${_Support.whatsapp}?text=${Uri.encodeComponent(_message)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _teal.withValues(alpha: 0.4)),
          ),
          child: Text(
            '${_t('f_sendTitle')}\n${_t('f_sendDesc')}',
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.9),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _boxDecoration(alt: true),
          child: SelectableText(
            _message,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.8),
          ),
        ),
        const SizedBox(height: 14),
        _gradientButton(
          label: _t('sendWa'),
          gradient: _whatsappGradient,
          onTap: () => _openUrl(context, waUrl),
        ),
        const SizedBox(height: 8),
        _gradientButton(
          label: _t('sendTg'),
          gradient: _telegramGradient,
          onTap: () => _copyAndOpen(_Support.telegram),
        ),
        const SizedBox(height: 8),
        _gradientButton(
          label: _t('sendEitaa'),
          gradient: _eitaaGradient,
          onTap: () => _copyAndOpen(_Support.eitaa),
        ),
        const SizedBox(height: 8),
        _gradientButton(
          label: _t('callBtn'),
          gradient: _callGradient,
          onTap: () => _openUrl(context, 'tel:${_Support.phone}'),
        ),
        const SizedBox(height: 8),
        _outlineButton(_t('copyAgain'), () async {
          await Clipboard.setData(ClipboardData(text: _message));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('copied'))));
        }),
        const SizedBox(height: 8),
        _outlineButton(_t('back'), () => _go(_Step.form)),
        const SizedBox(height: 8),
        _outlineButton(_t('done'), () => Navigator.of(context).pop()),
      ],
    );
  }

  // ===================== اجزای مشترک UI =====================

  BoxDecoration _boxDecoration({bool alt = false}) => BoxDecoration(
        color: alt ? _cardAlt : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      );

  BoxDecoration _inputDecoration() => BoxDecoration(
        color: _cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(color: _goldBright, fontSize: 15, fontWeight: FontWeight.w800, height: 1.6),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    bool ltr = false,
    int? maxLength,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLength: maxLength,
            textDirection: ltr ? TextDirection.ltr : null,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: _gold,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: _cardAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required List<Color> gradient,
    required VoidCallback? onTap,
    Color textColor = Colors.white,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: _gold.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
