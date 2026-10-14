import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

import '../core/language/menu_translations.dart';
import '../widgets/registration_steps_card.dart';
import 'stay_registration_page.dart';

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

/// ویدیوی نمونه (داخل برنامه نمایش داده می‌شود؛ هیچ لینک بیرونی‌ای در این صفحه نیست)
class _Support {
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

// ===================== متن‌ها (fa / en / ar — مطابق سایت؛ سایر زبان‌ها انگلیسی) =====================

const Map<String, Map<String, String>> _kText = {
  'fa': {
    'titleTemplate': '➕ ثبت {cat} در سایروس توریست',
    'subtitle': 'کسب‌وکار یا خدمات گردشگری خود را معرفی کنید و در سامانه گردشگری سایروس توریست دیده شوید.',
    'benefitsTitle': '🌟 مزایای ثبت‌نام در سایروس توریست',
    'rulesTitle': '📋 قوانین و شرایط خدمات',
    'rules': 'ثبت‌نام در سایروس توریست صرفاً برای حضور در فضای تبلیغاتی سایروس توریست و معرفی شما به کاربران است. این خدمت در چارچوب خدمات دیجیتال، تبلیغاتی و زیرساخت‌های مبتنی بر اینترنت ارائه می‌شود. در صورت اختلال، محدودیت یا قطعی اینترنت، مخابرات یا سرویس‌های شخص ثالث که خارج از کنترل سایروس توریست است، سایروس توریست مسئولیت مستقیمی نخواهد داشت.',
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
    'sendOptsTitle': 'نمونه گزینه‌ها برای ارسال و هماهنگی مستقیم با پشتیبانی',
    'sendOptsDesc': 'برای ثبت‌نام، اطلاعات زیر را آماده کنید و از مسیر بالا به پشتیبانی سایروس توریست اطلاع دهید:',
    'supportTitle': 'تماس با پشتیبانی',
    'supportPath': 'برای ثبت‌نام، از منوی «شناسه کاربری» ← «ارتباط با ما» ← «چت با پشتیبانی» اقدام کنید.',
    'sendOpt1': '• نام کسب‌وکار / اقامتگاه',
    'sendOpt2': '• دسته‌بندی (اقامتگاه، کافه، رستوران، لیدر تور، گردشگری سلامت، آژانس مسافرتی و…)',
    'sendOpt3': '• شماره تلفن (همراه، ثابت یا کمکی)',
    'sendOpt4': '• لینک فیلم معرفی (در صورت وجود) یا درخواست تولید فیلم توسط سایروس توریست',
    'sendOpt5': '• لینک شبکه‌های اجتماعی و وب‌سایت (اینستاگرام، یوتیوب، تیک‌تاک، آپارات، تلگرام، واتساپ، ایتا)',
    'socialsTitle': 'شبکه‌های اجتماعی سایروس توریست',
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
    'benefit7Desc': 'معرفی مستمر شما در وب‌سایت، نرم‌افزار و شبکه‌های اجتماعی سایروس توریست در طول دوره حضور شما.',
    'benefit8': '🤝 دیده‌شدن توسط گردشگران بیشتر',
    'benefit8Desc': 'دسترسی گردشگران داخلی و خارجی به اطلاعات و راه‌های ارتباطی شما از طریق یک سامانه واحد.',
    'hubTitle': '➕ ثبت‌نام در سایروس توریست',
    'hubDesc': 'اقامتگاه، کافه، رستوران، لیدر تور، گردشگری سلامت، آژانس مسافرتی، خدمات گردشگری، صنایع‌دستی یا همکاری گردشگری خود را معرفی کنید و از خدمات معرفی، نمایش فیلم، مسیریابی، تماس مستقیم و امتیاز گردشگران بهره‌مند شوید.',
    'regBtn': '➕ ثبت {cat}',
    'callBtn': '📞 تماس مستقیم',
    'tgBtn': '✈️ تلگرام',
    'waBtn': '💬 واتساپ',
    'eitaaBtn': '💬 ایتا',
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
    'rules': 'Registration with Cyrus Tourist is solely for having a presence in the Cyrus Tourist advertising space and being introduced to users. This service is provided within the framework of digital, advertising and internet-based infrastructure services. In the event of disruption, limitation or interruption of internet, telecommunications or third-party services beyond the control of Cyrus Tourist, Cyrus Tourist shall not be directly responsible.',
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
    'sendOptsTitle': 'Sample options to send and coordinate directly with support',
    'sendOptsDesc': 'To register, prepare the details below and send them to Cyrus Tourist support through the path above:',
    'supportTitle': 'Contact support',
    'supportPath': 'To register, open the "User ID" menu → "Contact us" → "Chat with support".',
    'sendOpt1': '• Business / residence name',
    'sendOpt2': '• Category (residence, cafe, restaurant, tour leader, health tourism, travel agency, etc.)',
    'sendOpt3': '• Phone number (mobile, landline or auxiliary)',
    'sendOpt4': '• Intro video link (if you have one), or request video production by Cyrus Tourist',
    'sendOpt5': '• Social network and website links (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Cyrus Tourist social networks',
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
    'benefit7Desc': 'Ongoing visibility on the Cyrus Tourist website, app and social media during your listing period.',
    'benefit8': '🤝 Reach more tourists',
    'benefit8Desc': 'Domestic and international tourists can find your information and contact details in one place.',
    'hubTitle': '➕ Register on Cyrus Tourist',
    'hubDesc': 'Introduce your residence, cafe, restaurant, tour leader service, health tourism, travel agency, tourism services, handicrafts or tourism partnership, and benefit from introduction, video showcase, navigation, direct contact and tourist ratings.',
    'regBtn': '➕ Register {cat}',
    'callBtn': '📞 Call directly',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
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
    'rules': 'التسجيل في سايروس توريست مخصص حصراً للتواجد في المساحة الإعلانية لسايروس توريست وتعريفكم للمستخدمين. تُقدَّم هذه الخدمة ضمن إطار الخدمات الرقمية والإعلانية والبنى التحتية القائمة على الإنترنت. وفي حال حدوث خلل أو تقييد أو انقطاع في خدمات الإنترنت أو الاتصالات أو خدمات الجهات الخارجية الخارجة عن سيطرة سايروس توريست، فلا تتحمل سايروس توريست مسؤولية مباشرة.',
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
    'sendOptsTitle': 'نموذج الخيارات للإرسال والتنسيق المباشر مع الدعم',
    'sendOptsDesc': 'للتسجيل، جهّز المعلومات التالية وأرسلها إلى دعم سايروس توريست عبر المسار أعلاه:',
    'supportTitle': 'التواصل مع الدعم',
    'supportPath': 'للتسجيل، افتح قائمة «معرّف المستخدم» ← «تواصل معنا» ← «الدردشة مع الدعم».',
    'sendOpt1': '• اسم النشاط / الإقامة',
    'sendOpt2': '• الفئة (إقامة، مقهى، مطعم، قائد جولة، سياحة علاجية، وكالة سفر وغيرها)',
    'sendOpt3': '• رقم الهاتف (جوال أو أرضي أو إضافي)',
    'sendOpt4': '• رابط فيديو التعريف (إن وجد) أو طلب إنتاج فيديو من سايروس توريست',
    'sendOpt5': '• روابط شبكات التواصل والموقع الإلكتروني (إنستغرام، يوتيوب، تيك توك، آپارات، تيليجرام، واتساب، إيتا)',
    'socialsTitle': 'شبكات التواصل لسايروس توريست',
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
    'benefit7Desc': 'ظهور مستمر لك على موقع وتطبيق ووسائل التواصل الاجتماعي لسايروس توريست خلال فترة الظهور.',
    'benefit8': '🤝 الوصول إلى مزيد من السياح',
    'benefit8Desc': 'يمكن للسياح المحليين والأجانب الوصول إلى معلوماتك وطرق التواصل معك من خلال منصة واحدة.',
    'hubTitle': '➕ التسجيل في سايروس توريست',
    'hubDesc': 'عرّف بمكان إقامتك أو مقهاك أو مطعمك أو خدمة قيادة الجولات أو السياحة العلاجية أو وكالة السفر أو الخدمات السياحية أو الصناعات اليدوية أو شراكتك السياحية، واستفد من التعريف وعرض الفيديو والملاحة والاتصال المباشر وتقييمات السياح.',
    'regBtn': '➕ تسجيل {cat}',
    'callBtn': '📞 اتصال مباشر',
    'tgBtn': '✈️ تيليجرام',
    'waBtn': '💬 واتساب',
    'eitaaBtn': '💬 إيتا',
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
  'de': {
    'titleTemplate': '➕ {cat} bei Cyrus Tourist registrieren',
    'subtitle': 'Stellen Sie Ihr Tourismusunternehmen oder Ihre Dienstleistung vor und werden Sie bei Cyrus Tourist sichtbar.',
    'benefitsTitle': '🌟 Vorteile der Registrierung',
    'rulesTitle': '📋 Allgemeine Geschäftsbedingungen',
    'rules': 'Die Registrierung bei Cyrus Tourist dient ausschließlich der Präsenz im Werberaum von Cyrus Tourist und der Vorstellung bei den Nutzern. Diese Leistung wird im Rahmen digitaler, werblicher und internetbasierter Infrastrukturdienste erbracht. Bei Störungen, Einschränkungen oder Unterbrechungen von Internet-, Telekommunikations- oder Drittdiensten, die außerhalb der Kontrolle von Cyrus Tourist liegen, übernimmt Cyrus Tourist keine unmittelbare Verantwortung.',
    'continueButton': '➡️ Weiter',
    'enterReg': 'Zur Registrierung',
    'chatTitle': 'Direkt mit dem Support chatten',
    'chatDesc': 'Brauchen Sie Hilfe oder möchten nachfragen? Chatten Sie direkt mit unserem Support-Team.',
    'callDirect': 'Direkt anrufen',
    'chatTg': 'Im Telegram chatten',
    'chatEitaa': 'Im Eitaa chatten',
    'chatWa': 'Im WhatsApp chatten',
    'back': '↩ Zurück',
    'accept': 'Ich habe die Geschäftsbedingungen von Cyrus Tourist gelesen und akzeptiere sie.',
    'sendOptsTitle': 'Beispiel-Angaben zum Senden und zur direkten Abstimmung mit dem Support',
    'sendOptsDesc': 'Halten Sie für die Registrierung die folgenden Angaben bereit und senden Sie sie über den obigen Weg an den Cyrus-Tourist-Support:',
    'supportTitle': 'Support kontaktieren',
    'supportPath': 'Zur Registrierung öffnen Sie das Menü „Benutzer-ID“ → „Kontakt“ → „Chat mit dem Support“.',
    'sendOpt1': '• Name des Unternehmens / der Unterkunft',
    'sendOpt2': '• Kategorie (Unterkunft, Café, Restaurant, Tourenleiter, Gesundheitstourismus, Reisebüro usw.)',
    'sendOpt3': '• Telefonnummer (Mobil, Festnetz oder Zusatznummer)',
    'sendOpt4': '• Link zum Vorstellungsvideo (falls vorhanden) oder Anfrage zur Videoproduktion durch Cyrus Tourist',
    'sendOpt5': '• Links zu sozialen Netzwerken und Website (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Soziale Netzwerke von Cyrus Tourist',
    'benefit1': '🎬 Unterkunftsvideo',
    'benefit1Desc': 'Senden Sie den Link zu Ihrem Unterkunftsvideo oder bestellen Sie die Videoproduktion bei Cyrus Tourist.',
    'benefit2': '🗺️ Routenführung',
    'benefit2Desc': 'Touristen finden den Weg zu Ihrer Unterkunft.',
    'benefit3': '📞 Direkter Anruf',
    'benefit3Desc': 'Touristen können die Unterkunft direkt kontaktieren, sobald eine Telefonnummer freigeschaltet ist.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'Die Instagram-Seite Ihrer Unterkunft kann angezeigt werden.',
    'benefit5': '🌐 Website',
    'benefit5Desc': 'Die Website Ihrer Unterkunft kann im Profil angezeigt werden.',
    'benefit6': '⭐ Bewertungen von Touristen',
    'benefit6Desc': 'Touristen können Sie mit 1 bis 5 Sternen bewerten.',
    'benefit7': '📢 Präsenz im Werberaum von Cyrus Tourist',
    'benefit7Desc': 'Dauerhafte Sichtbarkeit auf Website, App und Social Media von Cyrus Tourist während Ihrer Präsenz.',
    'benefit8': '🤝 Mehr Touristen erreichen',
    'benefit8Desc': 'Inländische und ausländische Touristen finden Ihre Informationen und Kontaktdaten an einem Ort.',
    'hubTitle': '➕ Bei Cyrus Tourist registrieren',
    'hubDesc': 'Stellen Sie Ihre Unterkunft, Ihr Café, Restaurant, Ihren Tourenleiter-Service, Gesundheitstourismus, Reisebüro, Tourismusdienstleistungen, Kunsthandwerk oder Tourismuspartnerschaft vor und profitieren Sie von Vorstellung, Videopräsentation, Navigation, direktem Kontakt und Touristenbewertungen.',
    'regBtn': '➕ {cat} registrieren',
    'callBtn': '📞 Direkt anrufen',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Fertig',
    'linkErr': 'Der Link konnte nicht geöffnet werden.',
    'cat_residence': 'Unterkunft',
    'cat_cafe': 'Café',
    'cat_restaurant': 'Restaurant',
    'cat_tourleader': 'Tourenleiter',
    'cat_health': 'Gesundheitstourismus',
    'cat_agency': 'Reisebüro',
    'cat_services': 'Tourismusdienstleistungen',
    'cat_handicraft': 'Kunsthandwerk',
    'cat_partner': 'Tourismuspartner',
  },
  'es': {
    'titleTemplate': '➕ Registrar {cat} en Cyrus Tourist',
    'subtitle': 'Presente su negocio o servicio turístico y hágase visible en Cyrus Tourist.',
    'benefitsTitle': '🌟 Ventajas del registro',
    'rulesTitle': '📋 Términos y condiciones',
    'rules': 'El registro en Cyrus Tourist tiene como único fin tener presencia en el espacio publicitario de Cyrus Tourist y ser presentado a los usuarios. Este servicio se presta en el marco de servicios de infraestructura digital, publicitaria y basada en internet. En caso de interrupción, limitación o corte de internet, telecomunicaciones o servicios de terceros fuera del control de Cyrus Tourist, esta no será directamente responsable.',
    'continueButton': '➡️ Continuar',
    'enterReg': 'Entrar al registro',
    'chatTitle': 'Chatea directamente con soporte',
    'chatDesc': '¿Necesita ayuda o quiere hacer seguimiento? Chatee directamente con nuestro equipo de soporte.',
    'callDirect': 'Llamar directamente',
    'chatTg': 'Chatear en Telegram',
    'chatEitaa': 'Chatear en Eitaa',
    'chatWa': 'Chatear en WhatsApp',
    'back': '↩ Volver',
    'accept': 'He leído y acepto los términos y condiciones de Cyrus Tourist.',
    'sendOptsTitle': 'Ejemplos de datos para enviar y coordinar directamente con soporte',
    'sendOptsDesc': 'Para registrarse, prepare los siguientes datos y envíelos al soporte de Cyrus Tourist por la ruta indicada arriba:',
    'supportTitle': 'Contactar con soporte',
    'supportPath': 'Para registrarse, abra el menú «ID de usuario» → «Contáctenos» → «Chatea con soporte».',
    'sendOpt1': '• Nombre del negocio / alojamiento',
    'sendOpt2': '• Categoría (alojamiento, cafetería, restaurante, guía de tours, turismo de salud, agencia de viajes, etc.)',
    'sendOpt3': '• Número de teléfono (móvil, fijo o auxiliar)',
    'sendOpt4': '• Enlace del vídeo de presentación (si lo tiene) o solicitud de producción de vídeo por Cyrus Tourist',
    'sendOpt5': '• Enlaces a redes sociales y sitio web (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Redes sociales de Cyrus Tourist',
    'benefit1': '🎬 Vídeo del alojamiento',
    'benefit1Desc': 'Envíe el enlace del vídeo de su alojamiento o solicite su producción a Cyrus Tourist.',
    'benefit2': '🗺️ Navegación de ruta',
    'benefit2Desc': 'Los turistas pueden encontrar la ruta hasta su alojamiento.',
    'benefit3': '📞 Llamada directa',
    'benefit3Desc': 'Los turistas pueden contactar directamente con el alojamiento cuando hay un teléfono activado.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'Se puede mostrar la página de Instagram de su alojamiento.',
    'benefit5': '🌐 Sitio web',
    'benefit5Desc': 'El sitio web de su alojamiento se puede mostrar en el perfil.',
    'benefit6': '⭐ Valoraciones de turistas',
    'benefit6Desc': 'Los turistas pueden valorarle de 1 a 5 estrellas.',
    'benefit7': '📢 Presencia en el espacio publicitario de Cyrus Tourist',
    'benefit7Desc': 'Visibilidad continua en el sitio web, la app y las redes sociales de Cyrus Tourist durante su período de presencia.',
    'benefit8': '🤝 Llegue a más turistas',
    'benefit8Desc': 'Turistas nacionales e internacionales encuentran su información y datos de contacto en un solo lugar.',
    'hubTitle': '➕ Regístrese en Cyrus Tourist',
    'hubDesc': 'Presente su alojamiento, cafetería, restaurante, servicio de guía de tours, turismo de salud, agencia de viajes, servicios turísticos, artesanía o colaboración turística, y benefíciese de presentación, vídeo, navegación, contacto directo y valoraciones de turistas.',
    'regBtn': '➕ Registrar {cat}',
    'callBtn': '📞 Llamar directamente',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Hecho',
    'linkErr': 'No se pudo abrir el enlace.',
    'cat_residence': 'Alojamiento',
    'cat_cafe': 'Cafetería',
    'cat_restaurant': 'Restaurante',
    'cat_tourleader': 'Guía de tours',
    'cat_health': 'Turismo de salud',
    'cat_agency': 'Agencia de viajes',
    'cat_services': 'Servicios turísticos',
    'cat_handicraft': 'Artesanía',
    'cat_partner': 'Socio turístico',
  },
  'fr': {
    'titleTemplate': '➕ Inscrire {cat} sur Cyrus Tourist',
    'subtitle': 'Présentez votre entreprise ou service touristique et gagnez en visibilité sur Cyrus Tourist.',
    'benefitsTitle': '🌟 Avantages de l\'inscription',
    'rulesTitle': '📋 Conditions générales',
    'rules': 'L\'inscription à Cyrus Tourist vise uniquement à être présent dans l\'espace publicitaire de Cyrus Tourist et à être présenté aux utilisateurs. Ce service est fourni dans le cadre de services d\'infrastructure numérique, publicitaire et internet. En cas de perturbation, de limitation ou d\'interruption d\'internet, des télécommunications ou de services tiers indépendants de la volonté de Cyrus Tourist, celle-ci n\'est pas directement responsable.',
    'continueButton': '➡️ Continuer',
    'enterReg': 'Accéder à l\'inscription',
    'chatTitle': 'Discuter directement avec le support',
    'chatDesc': 'Besoin d\'aide ou d\'un suivi ? Discutez directement avec notre équipe de support.',
    'callDirect': 'Appeler directement',
    'chatTg': 'Discuter sur Telegram',
    'chatEitaa': 'Discuter sur Eitaa',
    'chatWa': 'Discuter sur WhatsApp',
    'back': '↩ Retour',
    'accept': 'J\'ai lu et j\'accepte les conditions générales de Cyrus Tourist.',
    'sendOptsTitle': 'Exemples d\'éléments à envoyer et à coordonner directement avec le support',
    'sendOptsDesc': 'Pour vous inscrire, préparez les informations ci-dessous et transmettez-les au support de Cyrus Tourist par le chemin indiqué ci-dessus :',
    'supportTitle': 'Contacter le support',
    'supportPath': 'Pour vous inscrire, ouvrez le menu « Identifiant » → « Nous contacter » → « Discuter avec le support ».',
    'sendOpt1': '• Nom de l\'entreprise / de l\'hébergement',
    'sendOpt2': '• Catégorie (hébergement, café, restaurant, guide de voyage, tourisme de santé, agence de voyages, etc.)',
    'sendOpt3': '• Numéro de téléphone (mobile, fixe ou auxiliaire)',
    'sendOpt4': '• Lien de la vidéo de présentation (si vous en avez une) ou demande de production vidéo par Cyrus Tourist',
    'sendOpt5': '• Liens vers les réseaux sociaux et le site web (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Réseaux sociaux de Cyrus Tourist',
    'benefit1': '🎬 Vidéo de l\'hébergement',
    'benefit1Desc': 'Envoyez le lien de la vidéo de votre hébergement ou demandez sa production à Cyrus Tourist.',
    'benefit2': '🗺️ Itinéraire',
    'benefit2Desc': 'Les touristes peuvent trouver l\'itinéraire vers votre hébergement.',
    'benefit3': '📞 Appel direct',
    'benefit3Desc': 'Les touristes peuvent contacter directement l\'hébergement lorsqu\'un numéro est activé.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'La page Instagram de votre hébergement peut être affichée.',
    'benefit5': '🌐 Site web',
    'benefit5Desc': 'Le site web de votre hébergement peut être affiché sur le profil.',
    'benefit6': '⭐ Avis des touristes',
    'benefit6Desc': 'Les touristes peuvent vous noter de 1 à 5 étoiles.',
    'benefit7': '📢 Présence dans l\'espace publicitaire de Cyrus Tourist',
    'benefit7Desc': 'Visibilité continue sur le site web, l\'application et les réseaux sociaux de Cyrus Tourist pendant votre période d\'adhésion.',
    'benefit8': '🤝 Touchez plus de touristes',
    'benefit8Desc': 'Les touristes français et étrangers trouvent vos informations et coordonnées au même endroit.',
    'hubTitle': '➕ S\'inscrire sur Cyrus Tourist',
    'hubDesc': 'Présentez votre hébergement, café, restaurant, service de guide, tourisme de santé, agence de voyages, services touristiques, artisanat ou partenariat touristique, et profitez de la présentation, de la vidéo, de la navigation, du contact direct et des avis des touristes.',
    'regBtn': '➕ Inscrire {cat}',
    'callBtn': '📞 Appeler directement',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Terminé',
    'linkErr': 'Impossible d\'ouvrir le lien.',
    'cat_residence': 'Hébergement',
    'cat_cafe': 'Café',
    'cat_restaurant': 'Restaurant',
    'cat_tourleader': 'Guide de voyage',
    'cat_health': 'Tourisme de santé',
    'cat_agency': 'Agence de voyages',
    'cat_services': 'Services touristiques',
    'cat_handicraft': 'Artisanat',
    'cat_partner': 'Partenaire touristique',
  },
  'it': {
    'titleTemplate': '➕ Registra {cat} su Cyrus Tourist',
    'subtitle': 'Presenta la tua attività o il tuo servizio turistico e rendilo visibile su Cyrus Tourist.',
    'benefitsTitle': '🌟 Vantaggi della registrazione',
    'rulesTitle': '📋 Termini e condizioni',
    'rules': 'La registrazione a Cyrus Tourist è finalizzata esclusivamente alla presenza nello spazio pubblicitario di Cyrus Tourist e alla presentazione agli utenti. Il servizio è fornito nell\'ambito di servizi di infrastruttura digitale, pubblicitaria e basata su internet. In caso di interruzione, limitazione o sospensione di internet, delle telecomunicazioni o di servizi di terzi al di fuori del controllo di Cyrus Tourist, Cyrus Tourist non è direttamente responsabile.',
    'continueButton': '➡️ Continua',
    'enterReg': 'Vai alla registrazione',
    'chatTitle': 'Chatta direttamente con il supporto',
    'chatDesc': 'Hai bisogno di aiuto o vuoi un aggiornamento? Chatta direttamente con il nostro team di supporto.',
    'callDirect': 'Chiama direttamente',
    'chatTg': 'Chatta su Telegram',
    'chatEitaa': 'Chatta su Eitaa',
    'chatWa': 'Chatta su WhatsApp',
    'back': '↩ Indietro',
    'accept': 'Ho letto e accetto i termini e le condizioni di Cyrus Tourist.',
    'sendOptsTitle': 'Esempi di dati da inviare e coordinare direttamente con il supporto',
    'sendOptsDesc': 'Per registrarti, prepara i dati qui sotto e inviali al supporto di Cyrus Tourist tramite il percorso indicato sopra:',
    'supportTitle': 'Contatta il supporto',
    'supportPath': 'Per registrarti, apri il menu «ID utente» → «Contattaci» → «Chatta con il supporto».',
    'sendOpt1': '• Nome dell\'attività / della struttura',
    'sendOpt2': '• Categoria (alloggio, caffè, ristorante, guida turistica, turismo sanitario, agenzia di viaggi, ecc.)',
    'sendOpt3': '• Numero di telefono (cellulare, fisso o ausiliario)',
    'sendOpt4': '• Link al video di presentazione (se disponibile) o richiesta di produzione video da parte di Cyrus Tourist',
    'sendOpt5': '• Link ai social network e al sito web (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Social network di Cyrus Tourist',
    'benefit1': '🎬 Video della struttura',
    'benefit1Desc': 'Invia il link del video della tua struttura o richiedi la produzione del video a Cyrus Tourist.',
    'benefit2': '🗺️ Navigazione del percorso',
    'benefit2Desc': 'I turisti possono trovare il percorso per la tua struttura.',
    'benefit3': '📞 Chiamata diretta',
    'benefit3Desc': 'I turisti possono contattare direttamente la struttura quando è attivato un numero di telefono.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'La pagina Instagram della tua struttura può essere mostrata.',
    'benefit5': '🌐 Sito web',
    'benefit5Desc': 'Il sito web della tua struttura può essere mostrato nel profilo.',
    'benefit6': '⭐ Valutazioni dei turisti',
    'benefit6Desc': 'I turisti possono valutarti da 1 a 5 stelle.',
    'benefit7': '📢 Presenza nello spazio pubblicitario di Cyrus Tourist',
    'benefit7Desc': 'Visibilità continua su sito web, app e social di Cyrus Tourist durante il periodo di adesione.',
    'benefit8': '🤝 Raggiungi più turisti',
    'benefit8Desc': 'Turisti italiani e stranieri trovano le tue informazioni e i tuoi contatti in un unico posto.',
    'hubTitle': '➕ Registrati su Cyrus Tourist',
    'hubDesc': 'Presenta il tuo alloggio, caffè, ristorante, servizio di guida, turismo sanitario, agenzia di viaggi, servizi turistici, artigianato o partnership turistica e approfitta di presentazione, video, navigazione, contatto diretto e valutazioni dei turisti.',
    'regBtn': '➕ Registra {cat}',
    'callBtn': '📞 Chiama direttamente',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Fatto',
    'linkErr': 'Impossibile aprire il link.',
    'cat_residence': 'Alloggio',
    'cat_cafe': 'Caffè',
    'cat_restaurant': 'Ristorante',
    'cat_tourleader': 'Guida turistica',
    'cat_health': 'Turismo sanitario',
    'cat_agency': 'Agenzia di viaggi',
    'cat_services': 'Servizi turistici',
    'cat_handicraft': 'Artigianato',
    'cat_partner': 'Partner turistico',
  },
  'ru': {
    'titleTemplate': '➕ Зарегистрировать {cat} в Cyrus Tourist',
    'subtitle': 'Представьте свой туристический бизнес или услугу и станьте заметны в Cyrus Tourist.',
    'benefitsTitle': '🌟 Преимущества регистрации',
    'rulesTitle': '📋 Условия и положения',
    'rules': 'Регистрация в Cyrus Tourist предназначена исключительно для присутствия в рекламном пространстве Cyrus Tourist и представления пользователям. Услуга предоставляется в рамках цифровой, рекламной и интернет-инфраструктуры. В случае сбоя, ограничения или прерывания интернета, связи или сторонних сервисов, не зависящих от Cyrus Tourist, Cyrus Tourist не несёт прямой ответственности.',
    'continueButton': '➡️ Продолжить',
    'enterReg': 'Перейти к регистрации',
    'chatTitle': 'Чат напрямую с поддержкой',
    'chatDesc': 'Нужна помощь или хотите уточнить статус? Напишите напрямую нашей службе поддержки.',
    'callDirect': 'Позвонить напрямую',
    'chatTg': 'Написать в Telegram',
    'chatEitaa': 'Написать в Eitaa',
    'chatWa': 'Написать в WhatsApp',
    'back': '↩ Назад',
    'accept': 'Я прочитал(а) и принимаю условия и положения Cyrus Tourist.',
    'sendOptsTitle': 'Примеры данных для отправки и согласования напрямую с поддержкой',
    'sendOptsDesc': 'Для регистрации подготовьте данные ниже и отправьте их в поддержку Cyrus Tourist по указанному выше пути:',
    'supportTitle': 'Связаться с поддержкой',
    'supportPath': 'Для регистрации откройте меню «ID пользователя» → «Связаться с нами» → «Чат с поддержкой».',
    'sendOpt1': '• Название бизнеса / места размещения',
    'sendOpt2': '• Категория (размещение, кафе, ресторан, тур-лидер, медицинский туризм, турагентство и т. д.)',
    'sendOpt3': '• Номер телефона (мобильный, стационарный или дополнительный)',
    'sendOpt4': '• Ссылка на видео-презентацию (если есть) или запрос на производство видео командой Cyrus Tourist',
    'sendOpt5': '• Ссылки на соцсети и сайт (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Соцсети Cyrus Tourist',
    'benefit1': '🎬 Видео места размещения',
    'benefit1Desc': 'Отправьте ссылку на видео вашего места размещения или закажите его производство у Cyrus Tourist.',
    'benefit2': '🗺️ Навигация по маршруту',
    'benefit2Desc': 'Туристы смогут найти маршрут к вашему месту размещения.',
    'benefit3': '📞 Прямой звонок',
    'benefit3Desc': 'Туристы могут напрямую связаться с местом размещения, когда включён номер телефона.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'Страница вашего места размещения в Instagram может быть показана.',
    'benefit5': '🌐 Сайт',
    'benefit5Desc': 'Сайт вашего места размещения может отображаться в профиле.',
    'benefit6': '⭐ Оценки туристов',
    'benefit6Desc': 'Туристы могут оценить вас от 1 до 5 звёзд.',
    'benefit7': '📢 Присутствие в рекламном пространстве Cyrus Tourist',
    'benefit7Desc': 'Постоянная видимость на сайте, в приложении и соцсетях Cyrus Tourist в течение срока размещения.',
    'benefit8': '🤝 Охватите больше туристов',
    'benefit8Desc': 'Российские и иностранные туристы находят вашу информацию и контакты в одном месте.',
    'hubTitle': '➕ Регистрация в Cyrus Tourist',
    'hubDesc': 'Представьте своё место размещения, кафе, ресторан, услуги тур-лидера, медицинский туризм, турагентство, туристические услуги, ремёсла или туристическое партнёрство и получите презентацию, видеовитрину, навигацию, прямой контакт и оценки туристов.',
    'regBtn': '➕ Зарегистрировать: {cat}',
    'callBtn': '📞 Позвонить напрямую',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Готово',
    'linkErr': 'Не удалось открыть ссылку.',
    'cat_residence': 'Размещение',
    'cat_cafe': 'Кафе',
    'cat_restaurant': 'Ресторан',
    'cat_tourleader': 'Тур-лидер',
    'cat_health': 'Медицинский туризм',
    'cat_agency': 'Турагентство',
    'cat_services': 'Туристические услуги',
    'cat_handicraft': 'Ремёсла',
    'cat_partner': 'Туристический партнёр',
  },
  'tr': {
    'titleTemplate': '➕ {cat} kaydını Cyrus Tourist\'e ekleyin',
    'subtitle': 'Turizm işletmenizi veya hizmetinizi tanıtın ve Cyrus Tourist\'te görünür olun.',
    'benefitsTitle': '🌟 Kayıt Avantajları',
    'rulesTitle': '📋 Şartlar ve Koşullar',
    'rules': 'Cyrus Tourist\'e kayıt, yalnızca Cyrus Tourist reklam alanında yer almak ve kullanıcılara tanıtılmak içindir. Bu hizmet dijital, reklam ve internet tabanlı altyapı hizmetleri çerçevesinde sunulur. Cyrus Tourist\'in kontrolü dışındaki internet, telekomünikasyon veya üçüncü taraf hizmetlerinde aksama, sınırlama veya kesinti olması halinde Cyrus Tourist doğrudan sorumlu değildir.',
    'continueButton': '➡️ Devam',
    'enterReg': 'Kayda Gir',
    'chatTitle': 'Destekle doğrudan sohbet edin',
    'chatDesc': 'Yardıma mı ihtiyacınız var ya da takip etmek mi istiyorsunuz? Destek ekibimizle doğrudan sohbet edin.',
    'callDirect': 'Doğrudan ara',
    'chatTg': 'Telegram\'da sohbet et',
    'chatEitaa': 'Eitaa\'da sohbet et',
    'chatWa': 'WhatsApp\'ta sohbet et',
    'back': '↩ Geri',
    'accept': 'Cyrus Tourist şartlarını ve koşullarını okudum ve kabul ediyorum.',
    'sendOptsTitle': 'Destekle doğrudan göndermek ve koordine etmek için örnek seçenekler',
    'sendOptsDesc': 'Kayıt için aşağıdaki bilgileri hazırlayın ve yukarıdaki yoldan Cyrus Tourist desteğine iletin:',
    'supportTitle': 'Destekle iletişim',
    'supportPath': 'Kayıt için "Kullanıcı Kimliği" menüsü → "Bize ulaşın" → "Destekle sohbet" yolunu izleyin.',
    'sendOpt1': '• İşletme / konaklama adı',
    'sendOpt2': '• Kategori (konaklama, kafe, restoran, tur lideri, sağlık turizmi, seyahat acentesi vb.)',
    'sendOpt3': '• Telefon numarası (cep, sabit veya yardımcı)',
    'sendOpt4': '• Tanıtım videosu bağlantısı (varsa) veya Cyrus Tourist\'ten video üretimi talebi',
    'sendOpt5': '• Sosyal ağ ve web sitesi bağlantıları (Instagram, YouTube, TikTok, Aparat, Telegram, WhatsApp, Eitaa)',
    'socialsTitle': 'Cyrus Tourist sosyal ağları',
    'benefit1': '🎬 Konaklama videosu',
    'benefit1Desc': 'Konaklama videonuzun bağlantısını gönderin veya Cyrus Tourist\'ten video üretimi isteyin.',
    'benefit2': '🗺️ Rota yönlendirme',
    'benefit2Desc': 'Turistler konaklamanıza giden rotayı bulabilir.',
    'benefit3': '📞 Doğrudan turist araması',
    'benefit3Desc': 'Telefon numarası etkinleştirildiğinde turistler konaklamayla doğrudan iletişime geçebilir.',
    'benefit4': '📸 Instagram',
    'benefit4Desc': 'Konaklamanızın Instagram sayfası gösterilebilir.',
    'benefit5': '🌐 Web sitesi',
    'benefit5Desc': 'Konaklamanızın web sitesi profilde gösterilebilir.',
    'benefit6': '⭐ Turist puanları',
    'benefit6Desc': 'Turistler size 1 ile 5 yıldız arasında puan verebilir.',
    'benefit7': '📢 Cyrus Tourist reklam alanında yer alma',
    'benefit7Desc': 'Üyelik süreniz boyunca Cyrus Tourist web sitesinde, uygulamasında ve sosyal medyasında sürekli görünürlük.',
    'benefit8': '🤝 Daha fazla turiste ulaşın',
    'benefit8Desc': 'Yerli ve yabancı turistler bilgilerinizi ve iletişim detaylarınızı tek yerde bulur.',
    'hubTitle': '➕ Cyrus Tourist\'e Kayıt Ol',
    'hubDesc': 'Konaklamanızı, kafenizi, restoranınızı, tur lideri hizmetinizi, sağlık turizmini, seyahat acentenizi, turizm hizmetlerini, el sanatlarını veya turizm ortaklığını tanıtın; tanıtım, video vitrini, navigasyon, doğrudan iletişim ve turist puanlarından yararlanın.',
    'regBtn': '➕ {cat} kaydı',
    'callBtn': '📞 Doğrudan ara',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ Tamam',
    'linkErr': 'Bağlantı açılamadı.',
    'cat_residence': 'Konaklama',
    'cat_cafe': 'Kafe',
    'cat_restaurant': 'Restoran',
    'cat_tourleader': 'Tur Lideri',
    'cat_health': 'Sağlık Turizmi',
    'cat_agency': 'Seyahat Acentesi',
    'cat_services': 'Turizm Hizmetleri',
    'cat_handicraft': 'El Sanatları',
    'cat_partner': 'Turizm Ortağı',
  },
  'zh': {
    'titleTemplate': '➕ 在 Cyrus Tourist 注册{cat}',
    'subtitle': '介绍您的旅游业务或服务，让更多人在 Cyrus Tourist 上看到您。',
    'benefitsTitle': '🌟 注册优势',
    'rulesTitle': '📋 条款与条件',
    'rules': '在 Cyrus Tourist 的注册仅用于在 Cyrus Tourist 广告空间中展示并向用户介绍。本服务在数字、广告和互联网基础设施服务框架内提供。若因 Cyrus Tourist 无法控制的互联网、电信或第三方服务中断、受限或故障，Cyrus Tourist 不承担直接责任。',
    'continueButton': '➡️ 继续',
    'enterReg': '进入注册',
    'chatTitle': '直接与客服聊天',
    'chatDesc': '需要帮助或想跟进进度？请直接与我们的客服团队聊天。',
    'callDirect': '直接拨打电话',
    'chatTg': '在 Telegram 聊天',
    'chatEitaa': '在 Eitaa 聊天',
    'chatWa': '在 WhatsApp 聊天',
    'back': '↩ 返回',
    'accept': '我已阅读并接受 Cyrus Tourist 的条款与条件。',
    'sendOptsTitle': '直接发送并与客服协调的示例选项',
    'sendOptsDesc': '注册前请准备以下信息，并通过上述路径发送给 Cyrus Tourist 客服：',
    'supportTitle': '联系客服',
    'supportPath': '注册请打开“用户ID”菜单 → “联系我们” → “联系客服”。',
    'sendOpt1': '• 商家 / 住宿名称',
    'sendOpt2': '• 类别（住宿、咖啡馆、餐厅、领队、健康旅游、旅行社等）',
    'sendOpt3': '• 电话号码（手机、座机或备用号码）',
    'sendOpt4': '• 介绍视频链接（如有）或请 Cyrus Tourist 制作视频',
    'sendOpt5': '• 社交网络和网站链接（Instagram、YouTube、TikTok、Aparat、Telegram、WhatsApp、Eitaa）',
    'socialsTitle': 'Cyrus Tourist 社交网络',
    'benefit1': '🎬 住宿视频',
    'benefit1Desc': '发送您的住宿视频链接，或请 Cyrus Tourist 制作视频。',
    'benefit2': '🗺️ 路线导航',
    'benefit2Desc': '游客可以找到前往您住宿的路线。',
    'benefit3': '📞 游客直接致电',
    'benefit3Desc': '启用电话号码后，游客可以直接联系住宿。',
    'benefit4': '📸 Instagram',
    'benefit4Desc': '可以展示您住宿的 Instagram 页面。',
    'benefit5': '🌐 网站',
    'benefit5Desc': '可以在资料页展示您住宿的网站。',
    'benefit6': '⭐ 游客评分',
    'benefit6Desc': '游客可以给您打 1 到 5 星。',
    'benefit7': '📢 进驻 Cyrus Tourist 广告空间',
    'benefit7Desc': '展示期间，在 Cyrus Tourist 网站、应用和社交媒体上持续曝光。',
    'benefit8': '🤝 触达更多游客',
    'benefit8Desc': '国内外游客可在一处找到您的信息和联系方式。',
    'hubTitle': '➕ 在 Cyrus Tourist 注册',
    'hubDesc': '介绍您的住宿、咖啡馆、餐厅、领队服务、健康旅游、旅行社、旅游服务、手工艺品或旅游合作，享受推介、视频展示、导航、直接联系和游客评分。',
    'regBtn': '➕ 注册{cat}',
    'callBtn': '📞 直接致电',
    'tgBtn': '✈️ Telegram',
    'waBtn': '💬 WhatsApp',
    'eitaaBtn': '💬 Eitaa',
    'done': '✔ 完成',
    'linkErr': '无法打开链接。',
    'cat_residence': '住宿',
    'cat_cafe': '咖啡馆',
    'cat_restaurant': '餐厅',
    'cat_tourleader': '领队',
    'cat_health': '健康旅游',
    'cat_agency': '旅行社',
    'cat_services': '旅游服务',
    'cat_handicraft': '手工艺品',
    'cat_partner': '旅游合作伙伴',
  },
};


const Map<String, Map<String, String>> _kExtra = {
  'fa': {
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
  'de': {
    'samplePlaying': 'Beispiel wird geladen…',
    'close': '✕',
    'sampleTitle': '🏡 Beispiel einer Angebotskarte',
    'sampleDesc': 'Dies ist ein Beispiel Ihrer Angebotskarte. Für Ihr Video gibt es zwei Wege: 1. Senden Sie den Link zu Ihrem Social-Media-Video an den Cyrus-Tourist-Support. 2. Beauftragen Sie das Cyrus-Tourist-Team mit professioneller Inhaltsproduktion (vor Ort oder remote).',
    'sampleRoute': '🗺️ Route (mein Standort)',
    'sampleCall': '📞 Direkter Anruf',
    'sampleCallMobile': '📱 Handynummer',
    'sampleCallLandline': '☎️ Festnetznummer',
    'sampleCallSupport': '🛟 Support-Hotline',
    'sampleCallNote': 'Nach der Registrierung einsatzbereit.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Website',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Geschäftsbedingungen akzeptiert.',
  },
  'es': {
    'samplePlaying': 'Cargando ejemplo…',
    'close': '✕',
    'sampleTitle': '🏡 Tarjeta de anuncio de ejemplo',
    'sampleDesc': 'Este es un ejemplo de su tarjeta de anuncio. Hay dos formas de añadir su vídeo: 1. Envíe el enlace de su vídeo de redes sociales al soporte de Cyrus Tourist. 2. Encargue la producción de contenido profesional al equipo de Cyrus Tourist (presencial o remoto).',
    'sampleRoute': '🗺️ Ruta (mi ubicación)',
    'sampleCall': '📞 Llamada directa',
    'sampleCallMobile': '📱 Número de móvil',
    'sampleCallLandline': '☎️ Número fijo',
    'sampleCallSupport': '🛟 Línea de soporte',
    'sampleCallNote': 'Listo para usar tras el registro.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Sitio web',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Términos y condiciones aceptados.',
  },
  'fr': {
    'samplePlaying': 'Chargement de l\'exemple…',
    'close': '✕',
    'sampleTitle': '🏡 Exemple de fiche d\'annonce',
    'sampleDesc': 'Ceci est un exemple de votre fiche d\'annonce. Vous avez deux façons d\'ajouter votre vidéo : 1. Envoyez le lien de votre vidéo de réseaux sociaux au support de Cyrus Tourist. 2. Commandez une production de contenu professionnelle à l\'équipe de Cyrus Tourist (sur place ou à distance).',
    'sampleRoute': '🗺️ Itinéraire (ma position)',
    'sampleCall': '📞 Appel direct',
    'sampleCallMobile': '📱 Numéro de mobile',
    'sampleCallLandline': '☎️ Numéro fixe',
    'sampleCallSupport': '🛟 Ligne de support',
    'sampleCallNote': 'Prêt à l\'emploi après l\'inscription.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Site web',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Conditions générales acceptées.',
  },
  'it': {
    'samplePlaying': 'Caricamento esempio…',
    'close': '✕',
    'sampleTitle': '🏡 Scheda di esempio',
    'sampleDesc': 'Questo è un esempio della tua scheda. Ci sono due modi per aggiungere il video: 1. Invia il link del video dei tuoi social al supporto di Cyrus Tourist. 2. Ordina la produzione di contenuti professionali al team di Cyrus Tourist (di persona o da remoto).',
    'sampleRoute': '🗺️ Percorso (la mia posizione)',
    'sampleCall': '📞 Chiamata diretta',
    'sampleCallMobile': '📱 Numero di cellulare',
    'sampleCallLandline': '☎️ Numero fisso',
    'sampleCallSupport': '🛟 Linea di supporto',
    'sampleCallNote': 'Pronto all\'uso dopo la registrazione.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Sito web',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Termini e condizioni accettati.',
  },
  'ru': {
    'samplePlaying': 'Загрузка примера…',
    'close': '✕',
    'sampleTitle': '🏡 Пример карточки объявления',
    'sampleDesc': 'Это пример вашей карточки. Добавить видео можно двумя способами: 1. Отправьте ссылку на видео из соцсетей в поддержку Cyrus Tourist. 2. Закажите профессиональное производство контента у команды Cyrus Tourist (лично или удалённо).',
    'sampleRoute': '🗺️ Маршрут (моё местоположение)',
    'sampleCall': '📞 Прямой звонок',
    'sampleCallMobile': '📱 Мобильный номер',
    'sampleCallLandline': '☎️ Стационарный номер',
    'sampleCallSupport': '🛟 Линия поддержки',
    'sampleCallNote': 'Готово к использованию после регистрации.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Сайт',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Условия и положения приняты.',
  },
  'tr': {
    'samplePlaying': 'Örnek yükleniyor…',
    'close': '✕',
    'sampleTitle': '🏡 Örnek İlan Kartı',
    'sampleDesc': 'Bu, ilan kartınızın bir örneğidir. Videonuzu eklemenin iki yolu var: 1. Sosyal medya video bağlantınızı Cyrus Tourist desteğine gönderin. 2. Cyrus Tourist ekibinden profesyonel içerik üretimi sipariş edin (yüz yüze veya uzaktan).',
    'sampleRoute': '🗺️ Rota (konumum)',
    'sampleCall': '📞 Doğrudan Arama',
    'sampleCallMobile': '📱 Cep Numarası',
    'sampleCallLandline': '☎️ Sabit Numara',
    'sampleCallSupport': '🛟 Destek Hattı',
    'sampleCallNote': 'Kayıttan sonra kullanıma hazır.',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 Web sitesi',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ Şartlar ve koşullar kabul edildi.',
  },
  'zh': {
    'samplePlaying': '正在加载示例…',
    'close': '✕',
    'sampleTitle': '🏡 示例信息卡',
    'sampleDesc': '这是您信息卡的示例。添加视频有两种方式：1. 将您的社交媒体视频链接发送给 Cyrus Tourist 客服；2. 委托 Cyrus Tourist 团队制作专业内容（现场或远程）。',
    'sampleRoute': '🗺️ 路线（我的位置）',
    'sampleCall': '📞 直接致电',
    'sampleCallMobile': '📱 手机号码',
    'sampleCallLandline': '☎️ 座机号码',
    'sampleCallSupport': '🛟 客服热线',
    'sampleCallNote': '注册后即可使用。',
    'sampleInstagram': '📸 Instagram',
    'sampleWebsite': '🌐 网站',
    'sampleYoutube': '▶️ YouTube',
    'sampleTiktok': '🎵 TikTok',
    'sampleAparat': '▶️ Aparat',
    'sampleTelegram': '✈️ Telegram',
    'sampleWhatsapp': '💬 WhatsApp',
    'sampleEitaa': '💬 Eitaa',
    'accepted': '✅ 已接受条款与条件。',
  },
};

String _t(String key) {
  final lang = MenuLanguage.current;
  final map = _kText[lang] ?? _kText['en']!;
  final extra = _kExtra[lang] ?? _kExtra['en']!;
  return map[key] ?? extra[key] ?? _kText['fa']![key] ?? _kExtra['fa']![key] ?? key;
}

String _catName(String cat) => _t('cat_$cat');

enum _Step { hub, terms, support }

/// صفحهٔ ثبت‌نام داخل برنامه — همان ظاهر و روال «ثبت‌نام در سایروس توریست» سایت:
/// کادر کرم‌رنگ با دکمه‌های دسته ← پنجرهٔ سفید (مزایا و قوانین) ← گزینه‌های ارسال و هماهنگی مستقیم با پشتیبانی.
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
  bool _callOpen = false;
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
    _scroll.dispose();
    super.dispose();
  }

  void _go(_Step s) {
    setState(() => _step = s);
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
      case _Step.support:
        _go(_Step.terms);
        break;
    }
  }

  /// اقامتگاه، گردشگری سلامت، آژانس و لیدر ← فرم ثبت داخل اپ (هرکدام به پنل خودش)؛ سایر دسته‌ها ← راهنمای پشتیبانی
  void _enterRegistration() {
    const kinds = {'residence': 'stay', 'health': 'health', 'agency': 'agency', 'tourleader': 'leader'};
    final kind = kinds[_category];
    if (kind != null) {
      final route = MaterialPageRoute<void>(builder: (_) => StayRegistrationPage(kind: kind));
      if (widget.initialCategory != null) {
        Navigator.of(context).pushReplacement(route);
      } else {
        Navigator.of(context).push(route);
      }
      return;
    }
    _go(_Step.support);
  }

  /// بستن «پنجره» — مثل دکمهٔ ✕ سایت
  void _closeModal() {
    if (widget.initialCategory != null) {
      Navigator.of(context).pop();
    } else {
      _go(_Step.hub);
    }
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _boxBorder),
            ),
            child: Text(
              '${_t('supportTitle')}\n${_t('supportPath')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _titleGold, fontSize: 13, fontWeight: FontWeight.w800, height: 1.9),
            ),
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
        const RegistrationStepsCard(),
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
        _enterButton(_t('enterReg'), _accepted ? _enterRegistration : null),
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
                        () {},
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
                    // فقط نمونهٔ ظاهر کارت است؛ لمس این دکمه‌ها کاربر را از برنامه خارج نمی‌کند.
                    for (final k in const [
                      'sampleInstagram',
                      'sampleWebsite',
                      'sampleYoutube',
                      'sampleTiktok',
                      'sampleAparat',
                      'sampleTelegram',
                      'sampleWhatsapp',
                      'sampleEitaa',
                    ])
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 32 - 32 - 8) / 2,
                        child: _sampleBtn(_t(k), () {}),
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

  // ===================== مرحلهٔ ۲: گزینه‌های ارسال و هماهنگی مستقیم با پشتیبانی =====================

  Widget _supportStep() {
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
            _t('accepted'),
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
                _t('supportTitle'),
                style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                _t('supportPath'),
                style: const TextStyle(color: Color(0xff5a6572), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.9),
              ),
              const SizedBox(height: 10),
              Text(
                _t('sendOptsDesc'),
                style: const TextStyle(color: Color(0xff5a6572), fontSize: 13, height: 1.9),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffe3eaf0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == 5 ? 0 : 6),
                        child: Text(
                          _t('sendOpt$i'),
                          style: const TextStyle(color: Color(0xff3f4b58), fontSize: 12.5, height: 1.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _secondaryButton(_t('back'), () => _go(_Step.terms)),
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
