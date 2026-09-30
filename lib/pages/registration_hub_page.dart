import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/menu_translations.dart';
import '../widgets/brand_icons.dart';

// ===================== رنگ‌ها (عیناً از CSS سایت: residences.html و residences-registration.js) =====================

const Color _pageBg = Color(0xfff3f6f7);
const Color _topBar = Color(0xff0b6e69);
const Color _boxA = Color(0xfffff8e8);
const Color _boxB = Color(0xfffffdf7);
const Color _boxBorder = Color(0xfff1dfb6);
const Color _titleGold = Color(0xff765000);
const Color _descBrown = Color(0xff6c624d);
const Color _btnGold = Color(0xffc88a14);
const Color _ink = Color(0xff202936);
const Color _inkSoft = Color(0xff687482);
const Color _teal = Color(0xff11998e);

const List<Color> _brandGradient = [
  Color(0xff11998e),
  Color(0xff38ef7d),
  Color(0xff667eea),
];
const List<Color> _primaryGradient = [Color(0xff11998e), Color(0xff38ef7d)];
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
  static const String instagram = 'https://www.instagram.com/cyrustourist?igsi=aDc3end6dTNqNW1o';
  static const String website = 'https://cyrustourist-maker.github.io/Cyrustourist/#residence';
  static const String youtube = 'https://www.youtube.com/@cyrustourist';
  static const String tiktok = 'https://www.tiktok.com/@cyrustourist';
  static const String aparat = 'https://www.aparat.com/cyrustourist';
  static const String sampleVideo =
      'https://www.aparat.com/video/video/embed/videohash/w43c127/vt/frame';
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
    'enterReg': 'ورود به ثبت‌نام',
    'chatTitle': 'چت مستقیم با پشتیبانی',
    'chatDesc': 'برای راهنمایی یا پیگیری ثبت‌نام، مستقیم با پشتیبانی گفتگو کنید.',
    'callDirect': 'تماس مستقیم',
    'chatTg': 'چت در تلگرام',
    'chatEitaa': 'چت در ایتا',
    'chatWa': 'چت در واتساپ',
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
    'enterReg': 'Enter Registration',
    'chatTitle': 'Chat directly with support',
    'chatDesc': 'Need help or want to follow up? Chat with our support team directly.',
    'callDirect': 'Call directly',
    'chatTg': 'Chat on Telegram',
    'chatEitaa': 'Chat on Eitaa',
    'chatWa': 'Chat on WhatsApp',
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
    'enterReg': 'الدخول إلى التسجيل',
    'chatTitle': 'دردشة مباشرة مع الدعم',
    'chatDesc': 'للمساعدة أو متابعة التسجيل، تحدث مع الدعم مباشرة.',
    'callDirect': 'اتصال مباشر',
    'chatTg': 'دردشة على تيليجرام',
    'chatEitaa': 'دردشة على إيتا',
    'chatWa': 'دردشة على واتساب',
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
    'sendTg': 'ارسال در تلگرام',
    'sendEitaa': 'ارسال در ایتا',
    'pasteHint': 'پیام کپی شد. در گفتگوی باز شده Paste کنید و ارسال بزنید.',
    'samplePlaying': 'در حال بارگذاری نمونه…',
    'close': '✕',
    'sampleTitle': '🏡 نمونه کارت معرفی شما',
    'sampleDesc': 'این یک نمونه از کارت معرفی شماست. برای فیلم معرفی دو روش دارید: ۱. ارسال لینک فیلم شبکه‌های اجتماعی‌تان به پشتیبانی سایروس توریست ۲. سفارش تولید محتوای حرفه‌ای توسط تیم سایروس توریست (حضوری یا دورکاری).',
    'sampleRoute': '🗺️ مسیریابی (مکان من)',
    'sampleCall': '📞 تماس مستقیم',
    'sampleCallMobile': '📱 تلفن همراه',
    'sampleCallLandline': '☎️ تلفن ثابت',
    'sampleCallSupport': '🛟 تلفن پشتیبان',
    'sampleCallNote': 'پس از ثبت‌نام آماده به کار است.',
    'sampleInstagram': '📸 اینستاگرام',
    'sampleWebsite': '🌐 وب‌سایت',
    'sampleYoutube': '▶️ یوتیوب',
    'sampleTiktok': '🎵 تیک‌تاک',
    'sampleAparat': '▶️ آپارات',
    'sampleTelegram': '✈️ تلگرام',
    'sampleWhatsapp': '💬 واتساپ',
    'sampleEitaa': '💬 ایتا',
    'accepted': '✅ قوانین و شرایط پذیرفته شد.',
  },
  'en': {
    'sendTg': 'Send via Telegram',
    'sendEitaa': 'Send via Eitaa',
    'pasteHint': 'Message copied. Paste it in the chat that opens and send.',
    'samplePlaying': 'Loading sample…',
    'close': '✕',
    'sampleTitle': '🏡 Sample Listing Card',
    'sampleDesc': 'This is a sample of your listing card. There are two ways to add your video: 1. Send your social media video link to Cyrus Tourist support 2. Order professional content production by the Cyrus Tourist team (in person or remote).',
    'sampleRoute': '🗺️ Route (My Location)',
    'sampleCall': '📞 Direct Call',
    'sampleCallMobile': '📱 Mobile Number',
    'sampleCallLandline': '☎️ Landline Number',
    'sampleCallSupport': '🛟 Support Line',
    'sampleCallNote': 'Ready to use after registration.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Website',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Terms and conditions accepted.',
  },
  'ar': {
    'sendTg': 'إرسال عبر تيليجرام',
    'sendEitaa': 'إرسال عبر إيتا',
    'pasteHint': 'تم نسخ الرسالة. الصقها في المحادثة التي ستفتح ثم أرسلها.',
    'samplePlaying': 'جارٍ تحميل النموذج…',
    'close': '✕',
    'sampleTitle': '🏡 نموذج بطاقة التعريف الخاصة بك',
    'sampleDesc': 'هذا نموذج لبطاقة إقامتك. لديك طريقتان لإضافة الفيديو: ١. إرسال رابط فيديو من وسائل التواصل الاجتماعي إلى دعم سايروس توريست ٢. طلب إنتاج محتوى احترافي من فريق سايروس توريست (حضورياً أو عن بُعد).',
    'sampleRoute': '🗺️ الملاحة (موقعي)',
    'sampleCall': '📞 اتصال مباشر',
    'sampleCallMobile': '📱 رقم الجوال',
    'sampleCallLandline': '☎️ رقم الهاتف الأرضي',
    'sampleCallSupport': '🛟 خط الدعم',
    'sampleCallNote': 'جاهز للاستخدام بعد التسجيل.',
    'sampleInstagram': '📸 إنستغرام',
    'sampleWebsite': '🌐 الموقع الإلكتروني',
    'sampleYoutube': '▶️ يوتيوب',
    'sampleTiktok': '🎵 تيك توك',
    'sampleAparat': '▶️ آپارات',
    'sampleTelegram': '✈️ تلغرام',
    'sampleWhatsapp': '💬 واتساب',
    'sampleEitaa': '💬 ایتا',
    'accepted': '✅ تمت الموافقة على الشروط والأحكام.',
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

/// صفحهٔ ثبت‌نام داخل برنامه — همان ظاهر و روال «ثبت‌نام در سایروس توریست» سایت:
/// کادر کرم‌رنگ با دکمه‌های دسته ← پنجرهٔ سفید (مزایا و قوانین) ← فرم ← ارسال به پشتیبان.
class RegistrationHubPage extends StatefulWidget {
  const RegistrationHubPage({super.key, this.initialCategory});

  /// اگر مقدار بدهید، مستقیم به مرحلهٔ مزایا و قوانین همان دسته می‌رود.
  final String? initialCategory;

  @override
  State<RegistrationHubPage> createState() => _RegistrationHubPageState();
}

class _RegistrationHubPageState extends State<RegistrationHubPage> {
  _Step _step = _Step.hub;
  String _category = 'residence';
  bool _accepted = false;
  bool _confirmed = false;
  bool _callOpen = false;
  String? _error;
  String _message = '';

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _video = TextEditingController();
  final Map<String, TextEditingController> _socials = {
    for (final s in _kSocials) s[0]: TextEditingController(),
  };
  final _scroll = ScrollController();

  bool get _rtl => MenuLanguage.isRtl;

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
      _callOpen = false;
    });
    _go(_Step.terms);
  }

  void _onBack() {
    switch (_step) {
      case _Step.hub:
        Navigator.of(context).pop();
        break;
      case _Step.terms:
        if (widget.initialCategory != null) {
          Navigator.of(context).pop();
        } else {
          _go(_Step.hub);
        }
        break;
      case _Step.form:
        _go(_Step.terms);
        break;
      case _Step.support:
        _go(_Step.form);
        break;
    }
  }

  /// بستن «پنجره» — مثل دکمهٔ ✕ سایت
  void _closeModal() {
    if (widget.initialCategory != null) {
      Navigator.of(context).pop();
    } else {
      _go(_Step.hub);
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

  /// پیام را کپی می‌کند و گفتگوی پشتیبانی را باز می‌کند (تلگرام و ایتا متن آماده را
  /// از لینک نمی‌پذیرند؛ کاربر فقط Paste می‌کند).
  Future<void> _copyAndOpen(String url) async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('pasteHint'))));
    await _openUrl(context, url);
  }

  // ===================== ساختار صفحه =====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: _step == _Step.hub,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: _step == _Step.hub ? _hubScaffold() : _modalScaffold(),
      ),
    );
  }

  // ---------- کادر ثبت‌نام (صفحهٔ روشن مثل سایت) ----------

  Widget _hubScaffold() {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _topBar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _t('hubTitle'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          children: [_hubBox()],
        ),
      ),
    );
  }

  Widget _hubBox() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_boxA, _boxB],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _boxBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xff825a00).withValues(alpha: 0.06), blurRadius: 25, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            _t('hubTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _titleGold, fontSize: 22, fontWeight: FontWeight.w900, height: 1.5),
          ),
          const SizedBox(height: 9),
          Text(
            _t('hubDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _descBrown, fontSize: 14, height: 1.9),
          ),
          const SizedBox(height: 17),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final cat in _kCategories)
                _goldPill(_t('regBtn').replaceAll('{cat}', _catName(cat)), () => _openCategory(cat)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _contactChip(_t('callBtn'), _callGradient, () => _openUrl(context, 'tel:${_Support.phone}')),
              _contactChip(_t('tgBtn'), _telegramGradient, () => _openUrl(context, _Support.telegram)),
              _contactChip(_t('waBtn'), _whatsappGradient, () => _openUrl(context, _Support.whatsapp)),
              _contactChip(_t('eitaaBtn'), _eitaaGradient, () => _openUrl(context, _Support.eitaa)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goldPill(String label, VoidCallback onTap) {
    return Material(
      color: _btnGold,
      elevation: 3,
      shadowColor: _btnGold.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _contactChip(String label, List<Color> gradient, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ---------- «پنجرهٔ» سفید با هدر گرادیانی (مثل modal سایت) ----------

  Widget _modalScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xff2b3240),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            // Material لازم است تا دکمه‌های گرادیانی (Ink) روی زمینهٔ سفید دیده شوند
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  _modalHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: _modalContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 19),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: _brandGradient,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 44),
                  child: Text(
                    _t('titleTemplate').replaceAll('{cat}', _catName(_category)),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('subtitle'),
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.9),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: -6,
            start: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _closeModal,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Text('✕', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modalContent() {
    switch (_step) {
      case _Step.terms:
        return _termsStep();
      case _Step.form:
        return _formStep();
      case _Step.support:
        return _supportStep();
      case _Step.hub:
        return const SizedBox.shrink();
    }
  }

  // ===================== مرحلهٔ ۱: نمونه کارت، مزایا و قوانین =====================

  Widget _termsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sampleCard(),
        _sectionTitle(_t('benefitsTitle')),
        for (var i = 1; i <= 8; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xfff8fbff), Color(0xffeef8f5)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe5edf0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('benefit$i'),
                  style: const TextStyle(color: Color(0xff1d2935), fontSize: 15, fontWeight: FontWeight.w900, height: 1.7),
                ),
                const SizedBox(height: 6),
                Text(
                  _t('benefit${i}Desc'),
                  style: const TextStyle(color: _inkSoft, fontSize: 12, height: 1.9),
                ),
              ],
            ),
          ),
        const SizedBox(height: 11),
        _sectionTitle(_t('rulesTitle')),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xfffff9ed),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xfff3dfb3)),
          ),
          child: Text(
            _t('rules'),
            style: const TextStyle(color: Color(0xff4d4331), fontSize: 13, height: 2),
          ),
        ),
        const SizedBox(height: 18),
        _checkCard(_accepted, _t('accept'), (v) => setState(() => _accepted = v)),
        const SizedBox(height: 18),
        _enterButton(_t('enterReg'), _accepted ? () => _go(_Step.form) : null),
      ],
    );
  }

  Widget _sampleCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xfff8fbff), Color(0xffeef8f5)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe5edf0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(aspectRatio: 16 / 9, child: _SampleVideo()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('sampleTitle'),
                  style: const TextStyle(color: Color(0xff1d2935), fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('sampleDesc'),
                  style: const TextStyle(color: _inkSoft, fontSize: 12.5, height: 1.9),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _sampleBtn(
                        _t('sampleRoute'),
                        () => _openUrl(context, 'https://maps.google.com'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sampleBtn(
                        _t('sampleCall'),
                        () => setState(() => _callOpen = !_callOpen),
                        call: true,
                      ),
                    ),
                  ],
                ),
                if (_callOpen) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final k in const ['sampleCallMobile', 'sampleCallLandline', 'sampleCallSupport'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff344050),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                side: const BorderSide(color: Color(0xffdbe3ea)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                _t(k),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xfffff7e6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _t('sampleCallNote'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xff8a6d1d), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in <List<String>>[
                      ['sampleInstagram', _Support.instagram],
                      ['sampleWebsite', _Support.website],
                      ['sampleYoutube', _Support.youtube],
                      ['sampleTiktok', _Support.tiktok],
                      ['sampleAparat', _Support.aparat],
                      ['sampleTelegram', _Support.telegram],
                      ['sampleWhatsapp', _Support.whatsapp],
                      ['sampleEitaa', _Support.eitaa],
                    ])
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 32 - 32 - 8) / 2,
                        child: _sampleBtn(_t(e[0]), () => _openUrl(context, e[1])),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleBtn(String label, VoidCallback onTap, {bool call = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          gradient: call ? const LinearGradient(colors: _primaryGradient) : null,
          color: call ? null : const Color(0xffedf1f5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: call ? Colors.white : const Color(0xff344050),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  // ===================== مرحلهٔ ۲: فرم =====================

  Widget _formStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(_t('f_title')),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            _t('f_desc'),
            style: const TextStyle(color: Color(0xff5a6572), fontSize: 13, height: 1.9),
          ),
        ),
        _field(_t('f_name'), _name, maxLength: 120),
        _fieldLabel(_t('f_category')),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffd9e0e7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xff25303b), fontSize: 14),
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
            style: const TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ),
        for (final s in _kSocials)
          _field(s[1], _socials[s[0]]!, keyboard: TextInputType.url, ltr: true, hint: 'https://'),
        const SizedBox(height: 4),
        _checkCard(_confirmed, _t('f_confirm'), (v) => setState(() => _confirmed = v)),
        const SizedBox(height: 10),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xffc0392b), fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        _primaryButton(_t('f_submit'), _submit),
        const SizedBox(height: 10),
        _secondaryButton(_t('back'), () => _go(_Step.terms)),
      ],
    );
  }

  // ===================== مرحلهٔ ۳: ارسال به پشتیبان =====================

  Widget _supportStep() {
    final waUrl = '${_Support.whatsapp}?text=${Uri.encodeComponent(_message)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xffeafaf1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${_t('accepted')}\n${_t('f_sendDesc')}',
            style: const TextStyle(color: Color(0xff176b43), fontSize: 13, fontWeight: FontWeight.w800, height: 1.8),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xfff4f8ff), Color(0xfff4fff9)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffe3eaf0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t('f_sendTitle'),
                style: const TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe3eaf0)),
                ),
                child: SelectableText(
                  _message,
                  style: const TextStyle(color: Color(0xff637080), fontSize: 12.5, height: 1.9),
                ),
              ),
              const SizedBox(height: 16),
              _supportButton(_t('sendWa'), const [Color(0xff25d366), Color(0xff128c7e)],
                  BrandIcons.whatsapp, () => _openUrl(context, waUrl)),
              const SizedBox(height: 12),
              _supportButton(_t('sendTg'), const [Color(0xff2aabee), Color(0xff1c86c9)],
                  BrandIcons.telegram, () => _copyAndOpen(_Support.telegram)),
              const SizedBox(height: 12),
              _supportButton(_t('sendEitaa'), const [Color(0xfff7a21b), Color(0xffe2740f)],
                  BrandIcons.eitaa, () => _copyAndOpen(_Support.eitaa)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _chatSupportCard(),
        const SizedBox(height: 18),
        _secondaryButton(_t('copyAgain'), () async {
          await Clipboard.setData(ClipboardData(text: _message));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('copied'))));
        }),
        const SizedBox(height: 10),
        _secondaryButton(_t('back'), () => _go(_Step.form)),
        const SizedBox(height: 10),
        _secondaryButton(_t('done'), () => Navigator.of(context).pop()),
      ],
    );
  }

  // ===================== اجزای مشترک UI =====================

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(
          text,
          style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900, height: 1.5),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xff313b46), fontSize: 12, fontWeight: FontWeight.w800),
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
          _fieldLabel(label),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLength: maxLength,
            textDirection: ltr ? TextDirection.ltr : null,
            style: const TextStyle(color: Color(0xff25303b), fontSize: 14),
            cursorColor: _teal,
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xff9aa4ae)),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffd9e0e7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkCard(bool value, String label, ValueChanged<bool> onChanged) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfff4f7fa),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: _teal,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xff313b46), fontSize: 13, fontWeight: FontWeight.w800, height: 1.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _primaryGradient),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xffedf1f5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff344050), fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  /// دکمهٔ بزرگ «ورود به ثبت‌نام» (جایگزین فلش کوچک)
  Widget _enterButton(String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xff11998e), Color(0xff38ef7d)]
              : const [Color(0xffcfd8dc), Color(0xffb0bec5)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [BoxShadow(color: const Color(0xff11998e).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// دکمهٔ رنگی با آیکون SVG (همیشه قابل‌دیدن، مستقل از زمینه)
  Widget _supportButton(String label, List<Color> gradient, String svg, VoidCallback onTap,
      {String? sub}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    child: BrandIcon(svg, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        if (sub != null)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              sub,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بخش «چت مستقیم با پشتیبانی»: ۱) تماس  ۲) تلگرام  ۳) ایتا  ۴) واتساپ
  Widget _chatSupportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff4fbf8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffcdeee2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t('chatTitle'),
            style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _t('chatDesc'),
            style: const TextStyle(color: Color(0xff5a6572), fontSize: 13, height: 1.9),
          ),
          const SizedBox(height: 14),
          _supportButton(_t('callDirect'), const [Color(0xff10b981), Color(0xff047857)], BrandIcons.phone,
              () => _openUrl(context, 'tel:${_Support.phone}'),
              sub: _Support.phone),
          const SizedBox(height: 12),
          _supportButton(_t('chatTg'), const [Color(0xff2aabee), Color(0xff1c86c9)], BrandIcons.telegram,
              () => _openUrl(context, _Support.telegram)),
          const SizedBox(height: 12),
          _supportButton(_t('chatEitaa'), const [Color(0xfff7a21b), Color(0xffe2740f)], BrandIcons.eitaa,
              () => _openUrl(context, _Support.eitaa)),
          const SizedBox(height: 12),
          _supportButton(_t('chatWa'), const [Color(0xff25d366), Color(0xff128c7e)], BrandIcons.whatsapp,
              () => _openUrl(context, _Support.whatsapp)),
        ],
      ),
    );
  }
}

/// ویدیوی نمونهٔ کارت معرفی (همان iframe آپارات سایت)
class _SampleVideo extends StatefulWidget {
  const _SampleVideo();

  @override
  State<_SampleVideo> createState() => _SampleVideoState();
}

class _SampleVideoState extends State<_SampleVideo> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            return request.url.contains('aparat.com')
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_Support.sampleVideo));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          ),
        if (_failed)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _failed = false;
                  _loading = true;
                });
                _controller.reload();
              },
              child: const Text('↻', style: TextStyle(color: Colors.white, fontSize: 28)),
            ),
          ),
      ],
    );
  }
}
