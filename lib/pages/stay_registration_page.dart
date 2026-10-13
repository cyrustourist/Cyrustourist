import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/language/menu_translations.dart';
import '../services/account_service.dart';
import '../services/badge_service.dart';
import 'profile/my_profile_page.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/registration_steps_card.dart';
import 'location_picker_page.dart';
import 'profile/photo_cropper.dart';

// ===================== رنگ‌ها (هم‌شکل صفحهٔ ثبت‌نام) =====================
const Color _bg = Color(0xfff3f6f7);
const Color _bar = Color(0xff0b6e69);
const Color _ink = Color(0xff202936);
const Color _soft = Color(0xff687482);
const Color _teal = Color(0xff11998e);
const Color _gold = Color(0xffc88a14);
const Color _line = Color(0xffe0e8ec);
const Color _err = Color(0xffc0392b);

// ===================== متن‌ها (fa / en / ar؛ سایر زبان‌ها انگلیسی) =====================
const Map<String, Map<String, String>> _kTx = {
  'fa': {
    'title': 'ثبت اقامتگاه',
    'intro': 'اطلاعات اقامتگاه را وارد کنید. پس از بررسی مدیریت، در اپ و روی نقشه نمایش داده می‌شود.',
    'mine': 'درخواست‌های من',
    'pending': 'در انتظار بررسی',
    'approved': 'منتشر شد',
    'delete': 'حذف',
    's_info': 'مشخصات اقامتگاه',
    'name': 'نام اقامتگاه *',
    'type': 'نوع اقامتگاه *',
    'province': 'استان *',
    'provinceHint': 'تایپ کنید، مثلاً «خ»',
    'city': 'شهر یا روستا *',
    'address': 'آدرس',
    's_contact': 'تماس',
    'mobile': 'موبایل *',
    'phone': 'تلفن ثابت',
    's_more': 'امکانات و ظرفیت',
    'rooms': 'تعداد اتاق',
    'desc': 'توضیحات',
    's_photo': 'عکس پروفایل',
    'photoAdd': 'انتخاب عکس',
    'photoChange': 'تغییر عکس',
    'photoHint': 'یک عکس. پیش از ارسال خودکار فشرده می‌شود.',
    's_social': 'فیلم و شبکه‌های اجتماعی (اختیاری)',
    'video': '⭐ لینک نمایش فیلم ویژه (لینک آپارات/یوتیوب یا کد Embed)',
    'videoHint': 'لینک فیلم یا کد Embed کامل آپارات را همان‌طور که کپی کرده‌اید بچسبانید.',
    'instagram': 'اینستاگرام',
    'website': 'وب‌سایت',
    'submit': 'ثبت اقامتگاه',
    'sending': 'در حال ارسال…',
    'e_name': 'نام اقامتگاه را وارد کنید',
    'e_type': 'نوع اقامتگاه را انتخاب کنید',
    'e_province': 'استان را از فهرست انتخاب کنید',
    'e_city': 'شهر را وارد کنید',
    'e_mobile': 'شمارهٔ موبایل را مانند 09123456789 وارد کنید',
    'cTitle': 'تأیید انسانی',
    'cHelp': 'قطعه را بکشید تا در جای خالی بنشیند',
    'cLoading': 'در حال آماده‌سازی…',
    'cRetry': 'تلاش دوباره',
    'cancel': 'انصراف',
    'doneTitle': 'اقامتگاه شما ثبت شد',
    'doneCode': 'کد پیگیری',
    'doneText': 'پس از بررسی مدیریت منتشر می‌شود. وضعیت را در همین صفحه، بخش «درخواست‌های من» می‌بینید.',
    'back': 'بازگشت',
    'another': 'ثبت اقامتگاه دیگر',
    'netErr': 'ارتباط با سرور برقرار نشد. اینترنت را بررسی کنید.',
    'photoErr': 'عکس خوانده نشد. عکس دیگری انتخاب کنید.',
  },
  'en': {
    'title': 'Register accommodation',
    'intro': 'Enter your accommodation details. After admin review it appears in the app and on the map.',
    'mine': 'My requests',
    'pending': 'Pending review',
    'approved': 'Published',
    'delete': 'Delete',
    's_info': 'Accommodation details',
    'name': 'Accommodation name *',
    'type': 'Type *',
    'province': 'Province *',
    'provinceHint': 'Start typing',
    'city': 'City or village *',
    'address': 'Address',
    's_contact': 'Contact',
    'mobile': 'Mobile *',
    'phone': 'Landline',
    's_more': 'Amenities and capacity',
    'rooms': 'Rooms',
    'desc': 'Description',
    's_photo': 'Profile photo',
    'photoAdd': 'Choose photo',
    'photoChange': 'Change photo',
    'photoHint': 'One photo. It is compressed automatically before sending.',
    's_social': 'Video and social links (optional)',
    'video': '⭐ Featured film link (Aparat/YouTube link or Embed code)',
    'videoHint': 'Paste the film link or the full Aparat embed code as copied.',
    'instagram': 'Instagram',
    'website': 'Website',
    'submit': 'Submit accommodation',
    'sending': 'Sending…',
    'e_name': 'Enter the accommodation name',
    'e_type': 'Choose a type',
    'e_province': 'Pick a province from the list',
    'e_city': 'Enter the city',
    'e_mobile': 'Enter a mobile number like 09123456789',
    'cTitle': 'Human check',
    'cHelp': 'Drag the piece into the empty slot',
    'cLoading': 'Preparing…',
    'cRetry': 'Try again',
    'cancel': 'Cancel',
    'doneTitle': 'Your accommodation was submitted',
    'doneCode': 'Tracking code',
    'doneText': 'It will be published after review. You can follow the status under “My requests” on this page.',
    'back': 'Back',
    'another': 'Register another',
    'netErr': 'Could not reach the server. Check your internet.',
    'photoErr': 'Could not read the photo. Choose another one.',
  },
  'ar': {
    'title': 'تسجيل مكان إقامة',
    'intro': 'أدخل بيانات مكان الإقامة. بعد مراجعة الإدارة سيظهر في التطبيق وعلى الخريطة.',
    'mine': 'طلباتي',
    'pending': 'قيد المراجعة',
    'approved': 'تم النشر',
    'delete': 'حذف',
    's_info': 'بيانات مكان الإقامة',
    'name': 'اسم مكان الإقامة *',
    'type': 'النوع *',
    'province': 'المحافظة *',
    'provinceHint': 'ابدأ بالكتابة',
    'city': 'المدينة أو القرية *',
    'address': 'العنوان',
    's_contact': 'التواصل',
    'mobile': 'الجوال *',
    'phone': 'الهاتف الثابت',
    's_more': 'المرافق والسعة',
    'rooms': 'عدد الغرف',
    'desc': 'الوصف',
    's_photo': 'صورة الملف',
    'photoAdd': 'اختيار صورة',
    'photoChange': 'تغيير الصورة',
    'photoHint': 'صورة واحدة. يتم ضغطها تلقائياً قبل الإرسال.',
    's_social': 'الفيديو والشبكات (اختياري)',
    'video': '⭐ رابط عرض الفيديو المميز (رابط آپارات/يوتيوب أو كود Embed)',
    'videoHint': 'الصق رابط الفيديو أو كود Embed الكامل كما نسخته.',
    'instagram': 'إنستغرام',
    'website': 'الموقع',
    'submit': 'تسجيل مكان الإقامة',
    'sending': 'جارٍ الإرسال…',
    'e_name': 'أدخل اسم مكان الإقامة',
    'e_type': 'اختر النوع',
    'e_province': 'اختر المحافظة من القائمة',
    'e_city': 'أدخل المدينة',
    'e_mobile': 'أدخل رقم جوال مثل 09123456789',
    'cTitle': 'تأكيد بشري',
    'cHelp': 'اسحب القطعة إلى المكان الفارغ',
    'cLoading': 'جارٍ التحضير…',
    'cRetry': 'حاول مجدداً',
    'cancel': 'إلغاء',
    'doneTitle': 'تم إرسال مكان إقامتك',
    'doneCode': 'رمز المتابعة',
    'doneText': 'سيُنشر بعد المراجعة. يمكنك متابعة الحالة في «طلباتي» بهذه الصفحة.',
    'back': 'رجوع',
    'another': 'تسجيل آخر',
    'netErr': 'تعذر الاتصال بالخادم. تحقق من الإنترنت.',
    'photoErr': 'تعذرت قراءة الصورة. اختر صورة أخرى.',
  },
};

// متن‌های مخصوص لیدر / آژانس / گردشگری سلامت
const Map<String, Map<String, String>> _kTx2 = {
  'fa': {
    'title_stay': 'ثبت اقامتگاه',
    'title_health': 'ثبت گردشگری سلامت',
    'title_agency': 'ثبت آژانس مسافرتی',
    'title_leader': 'ثبت لیدر گردشگری',
    'intro_stay': 'اطلاعات اقامتگاه را وارد کنید. پس از بررسی مدیریت، در اپ و روی نقشه نمایش داده می‌شود.',
    'intro_health': 'اطلاعات مرکز یا خدمت سلامت را وارد کنید. پس از بررسی مدیریت، در بخش گردشگری سلامت نمایش داده می‌شود.',
    'intro_agency': 'اطلاعات آژانس را وارد کنید. پس از بررسی مدیریت، در بخش آژانس‌های مسافرتی نمایش داده می‌شود.',
    'intro_leader': 'اطلاعات خود را وارد کنید. پس از بررسی مدیریت، پروفایل شما در بخش لیدرها فعال می‌شود.',
    'name_stay': 'نام اقامتگاه *',
    'name_health': 'نام مرکز یا خدمت *',
    'name_agency': 'نام آژانس *',
    'name_leader': 'نام و نام خانوادگی *',
    's_info_stay': 'مشخصات اقامتگاه',
    's_info_health': 'مشخصات مرکز',
    's_info_agency': 'مشخصات آژانس',
    's_info_leader': 'مشخصات فردی',
    'healthType': 'نوع مرکز *',
    'specialty': 'تخصص',
    'doctor': 'پزشک یا مسئول',
    'hours': 'ساعت کاری',
    'manager': 'نام مدیر',
    'license': 'شماره مجوز (در صورت وجود)',
    'regions': 'مناطق و مقاصد اصلی',
    'experience': 'سابقه فعالیت',
    'areas': 'مناطق فعالیت',
    'fields': 'زمینهٔ فعالیت',
    'languages': 'زبان‌های مسلط',
    'services': 'خدمات',
    'telegram': 'تلگرام یا ایتا',
    's_prof': 'تخصص و سابقه',
    'e_htype': 'نوع مرکز را انتخاب کنید',
    'e_lname': 'نام و نام خانوادگی را کامل وارد کنید',
    'photo_agency': 'لوگو یا عکس',
  },
  'en': {
    'title_stay': 'Register accommodation',
    'title_health': 'Register health tourism',
    'title_agency': 'Register travel agency',
    'title_leader': 'Register tour leader',
    'intro_stay': 'Enter your accommodation details. After admin review it appears in the app and on the map.',
    'intro_health': 'Enter the health center or service details. After admin review it appears in Health Tourism.',
    'intro_agency': 'Enter your agency details. After admin review it appears in Travel Agencies.',
    'intro_leader': 'Enter your details. After admin review your profile becomes active in Tour Leaders.',
    'name_stay': 'Accommodation name *',
    'name_health': 'Center or service name *',
    'name_agency': 'Agency name *',
    'name_leader': 'Full name *',
    's_info_stay': 'Accommodation details',
    's_info_health': 'Center details',
    's_info_agency': 'Agency details',
    's_info_leader': 'Personal details',
    'healthType': 'Center type *',
    'specialty': 'Specialty',
    'doctor': 'Doctor or manager',
    'hours': 'Working hours',
    'manager': 'Manager name',
    'license': 'License number (if any)',
    'regions': 'Main regions and destinations',
    'experience': 'Experience',
    'areas': 'Areas of activity',
    'fields': 'Fields of activity',
    'languages': 'Languages you speak',
    'services': 'Services',
    'telegram': 'Telegram or Eitaa',
    's_prof': 'Expertise and experience',
    'e_htype': 'Choose a center type',
    'e_lname': 'Enter your first and last name',
    'photo_agency': 'Logo or photo',
  },
  'ar': {
    'title_stay': 'تسجيل مكان إقامة',
    'title_health': 'تسجيل السياحة العلاجية',
    'title_agency': 'تسجيل وكالة سفر',
    'title_leader': 'تسجيل مرشد سياحي',
    'intro_stay': 'أدخل بيانات مكان الإقامة. بعد مراجعة الإدارة سيظهر في التطبيق وعلى الخريطة.',
    'intro_health': 'أدخل بيانات المركز أو الخدمة. بعد مراجعة الإدارة سيظهر في السياحة العلاجية.',
    'intro_agency': 'أدخل بيانات الوكالة. بعد مراجعة الإدارة ستظهر في وكالات السفر.',
    'intro_leader': 'أدخل بياناتك. بعد مراجعة الإدارة يتم تفعيل ملفك في المرشدين.',
    'name_stay': 'اسم مكان الإقامة *',
    'name_health': 'اسم المركز أو الخدمة *',
    'name_agency': 'اسم الوكالة *',
    'name_leader': 'الاسم الكامل *',
    's_info_stay': 'بيانات مكان الإقامة',
    's_info_health': 'بيانات المركز',
    's_info_agency': 'بيانات الوكالة',
    's_info_leader': 'البيانات الشخصية',
    'healthType': 'نوع المركز *',
    'specialty': 'التخصص',
    'doctor': 'الطبيب أو المسؤول',
    'hours': 'ساعات العمل',
    'manager': 'اسم المدير',
    'license': 'رقم الترخيص (إن وجد)',
    'regions': 'المناطق والوجهات الرئيسية',
    'experience': 'الخبرة',
    'areas': 'مناطق النشاط',
    'fields': 'مجال النشاط',
    'languages': 'اللغات التي تتقنها',
    'services': 'الخدمات',
    'telegram': 'تيليجرام أو إيتا',
    's_prof': 'التخصص والخبرة',
    'e_htype': 'اختر نوع المركز',
    'e_lname': 'أدخل الاسم الأول والأخير',
    'photo_agency': 'الشعار أو صورة',
  },
};

// متن‌های تأیید حساب و ویرایش
const Map<String, Map<String, String>> _kTx3 = {
  'fa': {
    'gateTitle': 'ابتدا حساب کاربری را تکمیل کنید',
    'gateText': 'برای جلوگیری از ثبت‌های جعلی، و برای اینکه بعد از تأیید بتوانید تیک آبی بگیرید و استوری بگذارید، شمارهٔ همراه خود را با کد پیامک تأیید کنید. سپس به همین صفحه برگردید و ثبت‌نام را ادامه دهید.',
    'gateBtn': 'رفتن به شناسه کاربری',
    'gateRecheck': 'تأیید کردم، ادامه',
    'gateStill': 'هنوز حساب شما تأیید نشده است.',
    'locSearch': 'جستجوی آدرس یا انتخاب از روی نقشه',
    'locTip': 'برای ثبت مسیریابی دقیق، روی نقشه تا بیشترین حد زوم کنید و نقطه را روی ورودی بگذارید.',
    'locSet': 'موقعیت روی نقشه ثبت شد',
    'locChange': 'تغییر',
    'e_location': 'موقعیت را روی نقشه انتخاب کنید',
    'editBtn': 'ویرایش',
    'editTitle': 'ویرایش اطلاعات',
    'editIntro': 'تغییرات شما بلافاصله اعمال نمی‌شود؛ ابتدا در صف بررسی پشتیبانی قرار می‌گیرد و پس از تأیید منتشر می‌شود. تا آن زمان اطلاعات قبلی نمایش داده می‌شود.',
    'editSubmit': 'ارسال ویرایش برای بررسی',
    'editPending': 'ویرایش در صف بررسی',
    'editCancel': 'انصراف از ویرایش',
    'editKeepPhoto': 'عکس فعلی حفظ می‌شود؛ فقط برای تغییر، عکس جدید انتخاب کنید.',
    'editDoneTitle': 'ویرایش شما ثبت شد',
    'editDoneText': 'تغییرات در صف بررسی پشتیبانی قرار گرفت. پس از تأیید اعمال می‌شود و وضعیت را در «درخواست‌های من» می‌بینید.',
  },
  'en': {
    'gateTitle': 'Complete your account first',
    'gateText': 'To prevent fake listings, and so you can later get a blue tick and post stories, verify your mobile number with an SMS code. Then come back to this page and continue.',
    'gateBtn': 'Go to my account',
    'gateRecheck': 'I verified, continue',
    'gateStill': 'Your account is not verified yet.',
    'locSearch': 'Search an address or pick on the map',
    'locTip': 'For accurate routing, zoom in to the maximum on the map and place the pin on the entrance.',
    'locSet': 'Map location saved',
    'locChange': 'Change',
    'e_location': 'Pick the location on the map',
    'editBtn': 'Edit',
    'editTitle': 'Edit details',
    'editIntro': 'Your changes are not applied immediately. They go into the support review queue and are published after approval. Until then the previous details stay visible.',
    'editSubmit': 'Send edit for review',
    'editPending': 'Edit in review queue',
    'editCancel': 'Cancel editing',
    'editKeepPhoto': 'The current photo is kept. Choose a new one only to change it.',
    'editDoneTitle': 'Your edit was submitted',
    'editDoneText': 'Your changes are in the support review queue. They apply after approval; follow the status in "My requests".',
  },
  'ar': {
    'gateTitle': 'أكمل حسابك أولاً',
    'gateText': 'لمنع التسجيلات المزيفة، ولتتمكن لاحقاً من الحصول على العلامة الزرقاء ونشر القصص، أكّد رقم هاتفك برمز SMS ثم عد إلى هذه الصفحة وأكمل التسجيل.',
    'gateBtn': 'الانتقال إلى حسابي',
    'gateRecheck': 'تم التأكيد، متابعة',
    'gateStill': 'لم يتم تأكيد حسابك بعد.',
    'locSearch': 'ابحث عن عنوان أو اخترْه على الخريطة',
    'locTip': 'لتوجيه دقيق، قرّب إلى أقصى حد على الخريطة وضع الدبوس على المدخل.',
    'locSet': 'تم حفظ الموقع على الخريطة',
    'locChange': 'تغيير',
    'e_location': 'اختر الموقع على الخريطة',
    'editBtn': 'تعديل',
    'editTitle': 'تعديل البيانات',
    'editIntro': 'لا تُطبَّق تعديلاتك فوراً؛ تدخل أولاً في قائمة مراجعة الدعم وتُنشر بعد الموافقة، وتبقى البيانات السابقة ظاهرة حتى ذلك الحين.',
    'editSubmit': 'إرسال التعديل للمراجعة',
    'editPending': 'التعديل قيد المراجعة',
    'editCancel': 'إلغاء التعديل',
    'editKeepPhoto': 'تبقى الصورة الحالية. اختر صورة جديدة فقط إذا أردت تغييرها.',
    'editDoneTitle': 'تم إرسال تعديلك',
    'editDoneText': 'دخلت تعديلاتك قائمة مراجعة الدعم وستُطبَّق بعد الموافقة. تابع الحالة في «طلباتي».',
  },
};

String _t(String key) {
  final lang = MenuLanguage.current;
  final m = _kTx[lang] ?? _kTx['en']!;
  final m2 = _kTx2[lang] ?? _kTx2['en']!;
  final m3 = _kTx3[lang] ?? _kTx3['en']!;
  return m[key] ?? m2[key] ?? m3[key] ?? _kTx3['en']![key] ?? _kTx['en']![key] ?? _kTx2['en']![key] ?? _kTx['fa']![key] ?? _kTx2['fa']![key] ?? _kTx3['fa']![key] ?? key;
}

// [کلید، فارسی، انگلیسی، عربی]
const List<List<String>> _kTypes = [
  ['hotel', 'هتل', 'Hotel', 'فندق'],
  ['ecolodge', 'بوم‌گردی', 'Eco-lodge', 'نزل بيئي'],
  ['cottage', 'کلبه', 'Cottage', 'كوخ'],
  ['apartment', 'آپارتمان', 'Apartment', 'شقة'],
  ['villa', 'ویلا', 'Villa', 'فيلا'],
  ['suite', 'سوئیت', 'Suite', 'جناح'],
  ['guesthouse', 'مهمان‌پذیر', 'Guest house', 'بيت ضيافة'],
  ['hotel_apartment', 'هتل آپارتمان', 'Hotel apartment', 'شقق فندقية'],
  ['motel', 'متل', 'Motel', 'موتيل'],
  ['pension', 'پانسیون', 'Pension', 'بنسيون'],
  ['hostel', 'هاستل', 'Hostel', 'نزل'],
  ['camp', 'کمپ و چادر', 'Camp', 'مخيم'],
  ['traditional', 'اقامتگاه سنتی', 'Traditional house', 'بيت تقليدي'],
  ['resort', 'ریزورت', 'Resort', 'منتجع'],
  ['other', 'سایر', 'Other', 'أخرى'],
];

const List<List<String>> _kAmenities = [
  ['wifi', 'وای‌فای', 'Wi-Fi', 'واي فاي'],
  ['breakfast', 'صبحانه', 'Breakfast', 'فطور'],
  ['parking', 'پارکینگ', 'Parking', 'موقف'],
  ['air_conditioning', 'تهویه', 'A/C', 'تكييف'],
  ['heating', 'گرمایش', 'Heating', 'تدفئة'],
  ['hot_water', 'آب گرم', 'Hot water', 'ماء ساخن'],
  ['kitchen', 'آشپزخانه', 'Kitchen', 'مطبخ'],
  ['restaurant', 'رستوران', 'Restaurant', 'مطعم'],
  ['elevator', 'آسانسور', 'Elevator', 'مصعد'],
  ['pool', 'استخر', 'Pool', 'مسبح'],
  ['garden', 'فضای سبز', 'Garden', 'حديقة'],
  ['pet_friendly', 'حیوان خانگی', 'Pets allowed', 'يسمح بالحيوانات'],
  ['prayer_room', 'نمازخانه', 'Prayer room', 'مصلى'],
  ['tv', 'تلویزیون', 'TV', 'تلفاز'],
];

const List<List<String>> _kHealthTypes = [
  ['hospital', 'بیمارستان', 'Hospital', 'مستشفى'],
  ['clinic', 'کلینیک و درمانگاه', 'Clinic', 'عيادة'],
  ['dental', 'دندان‌پزشکی', 'Dental', 'أسنان'],
  ['beauty', 'زیبایی، پوست و مو', 'Beauty and skin', 'تجميل وبشرة'],
  ['spa', 'آبگرم و اسپا', 'Spa and hot spring', 'منتجع صحي'],
  ['massage', 'ماساژ و ریلکسیشن', 'Massage', 'تدليك'],
  ['specialist', 'پزشک متخصص', 'Specialist doctor', 'طبيب مختص'],
  ['physio', 'فیزیوتراپی و توانبخشی', 'Physiotherapy', 'علاج طبيعي'],
  ['lab', 'آزمایشگاه و تصویربرداری', 'Lab and imaging', 'مختبر وتصوير'],
  ['eye', 'چشم‌پزشکی و لیزیک', 'Eye care', 'طب العيون'],
  ['hair', 'کاشت مو', 'Hair transplant', 'زراعة الشعر'],
  ['fertility', 'زنان و ناباروری', 'Women and fertility', 'نساء وخصوبة'],
  ['traditional', 'طب سنتی و گیاهی', 'Traditional medicine', 'طب تقليدي'],
  ['nutrition', 'تغذیه و رژیم‌درمانی', 'Nutrition', 'تغذية'],
  ['pharmacy', 'داروخانه', 'Pharmacy', 'صيدلية'],
  ['wellness', 'سلامت و تندرستی', 'Wellness', 'عافية'],
  ['other', 'سایر', 'Other', 'أخرى'],
];

const List<List<String>> _kAgencyServices = [
  ['licensed', 'دارای مجوز', 'Licensed', 'مرخصة'],
  ['tour_booking', 'رزرو تور', 'Tour booking', 'حجز جولات'],
  ['hotel_booking', 'رزرو هتل', 'Hotel booking', 'حجز فنادق'],
  ['flight_booking', 'رزرو پرواز', 'Flight booking', 'حجز طيران'],
  ['visa', 'خدمات ویزا', 'Visa services', 'خدمات التأشيرة'],
  ['insurance', 'بیمه سفر', 'Travel insurance', 'تأمين سفر'],
  ['transfer', 'ترانسفر', 'Transfer', 'نقل'],
  ['corporate', 'خدمات سازمانی', 'Corporate', 'خدمات شركات'],
  ['online_booking', 'رزرو آنلاین', 'Online booking', 'حجز إلكتروني'],
  ['24h_support', 'پشتیبانی ۲۴ ساعته', '24h support', 'دعم 24 ساعة'],
  ['multilingual', 'پشتیبانی چندزبانه', 'Multilingual', 'متعدد اللغات'],
];

// [مقدار فارسی (ارسال به سرور)، English، عربی]
const List<List<String>> _kLeaderFields = [
  ['تاریخی و فرهنگی', 'Historical and cultural', 'تاريخي وثقافي'],
  ['طبیعت‌گردی', 'Nature tours', 'سياحة الطبيعة'],
  ['کویر و ماجراجویی', 'Desert and adventure', 'صحراء ومغامرة'],
  ['تور شهری', 'City tours', 'جولات المدينة'],
  ['تور خانوادگی', 'Family tours', 'جولات عائلية'],
  ['تور خارجی', 'Outbound tours', 'جولات خارجية'],
  ['گردشگری سلامت', 'Health tourism', 'السياحة العلاجية'],
];

const List<List<String>> _kLanguages = [
  ['فارسی', 'Persian', 'الفارسية'],
  ['English', 'English', 'الإنجليزية'],
  ['العربية', 'Arabic', 'العربية'],
  ['Türkçe', 'Turkish', 'التركية'],
  ['Русский', 'Russian', 'الروسية'],
  ['Deutsch', 'German', 'الألمانية'],
  ['Français', 'French', 'الفرنسية'],
];

String _lbl(List<String> row) {
  switch (MenuLanguage.current) {
    case 'fa':
      return row[1];
    case 'ar':
      return row[3];
    default:
      return row[2];
  }
}

// [فارسی، English]
const List<List<String>> _kProvinces = [
  ['آذربایجان شرقی', 'East Azerbaijan'],
  ['آذربایجان غربی', 'West Azerbaijan'],
  ['اردبیل', 'Ardabil'],
  ['اصفهان', 'Isfahan'],
  ['البرز', 'Alborz'],
  ['ایلام', 'Ilam'],
  ['بوشهر', 'Bushehr'],
  ['تهران', 'Tehran'],
  ['چهارمحال و بختیاری', 'Chaharmahal and Bakhtiari'],
  ['خراسان جنوبی', 'South Khorasan'],
  ['خراسان رضوی', 'Razavi Khorasan'],
  ['خراسان شمالی', 'North Khorasan'],
  ['خوزستان', 'Khuzestan'],
  ['زنجان', 'Zanjan'],
  ['سمنان', 'Semnan'],
  ['سیستان و بلوچستان', 'Sistan and Baluchestan'],
  ['فارس', 'Fars'],
  ['قزوین', 'Qazvin'],
  ['قم', 'Qom'],
  ['کردستان', 'Kurdistan'],
  ['کرمان', 'Kerman'],
  ['کرمانشاه', 'Kermanshah'],
  ['کهگیلویه و بویراحمد', 'Kohgiluyeh and Boyer-Ahmad'],
  ['گلستان', 'Golestan'],
  ['گیلان', 'Gilan'],
  ['لرستان', 'Lorestan'],
  ['مازندران', 'Mazandaran'],
  ['مرکزی', 'Markazi'],
  ['هرمزگان', 'Hormozgan'],
  ['همدان', 'Hamadan'],
  ['یزد', 'Yazd'],
];

String _norm(String s) => s
    .replaceAll('ي', 'ی')
    .replaceAll('ى', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll('‌', ' ')
    .replaceAll('ئ', 'ی')
    .toLowerCase()
    .trim();

String _provLabel(List<String> p) => MenuLanguage.current == 'fa' || MenuLanguage.current == 'ar' ? p[0] : p[1];

/// دیتای فشرده‌سازی عکس (در isolate جدا اجرا می‌شود).
Uint8List _compressJpeg(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return Uint8List(0);
  var side = 720;
  var quality = 82;
  Uint8List out = Uint8List(0);
  for (var i = 0; i < 6; i++) {
    final resized = decoded.width >= decoded.height
        ? (decoded.width > side ? img.copyResize(decoded, width: side) : decoded)
        : (decoded.height > side ? img.copyResize(decoded, height: side) : decoded);
    out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    if (out.length <= 165000) return out;
    quality = max(45, quality - 10);
    side = max(360, side - 90);
  }
  return out;
}

class _CaptchaResult {
  _CaptchaResult(this.id, this.x, this.trail);
  final String id;
  final double x;
  final List<List<num>> trail;
}

/// پازل «کشیدن و پر کردن جای خالی» — تصویر را سرور می‌سازد.
class _CaptchaDialog extends StatefulWidget {
  const _CaptchaDialog();

  @override
  State<_CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<_CaptchaDialog> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  String _error = '';
  double _x = 0;
  final List<List<num>> _trail = [];
  final Stopwatch _sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _x = 0;
      _trail.clear();
    });
    final j = await BadgeService.call('GET', '/api/stay-reg/captcha');
    if (!mounted) return;
    if (j == null || j['success'] != true || j['bg_svg'] is! String) {
      setState(() {
        _loading = false;
        _error = '${j?['message'] ?? _t('netErr')}';
      });
      return;
    }
    setState(() {
      _d = j;
      _loading = false;
    });
  }

  double get _maxX {
    final w = (_d?['width'] as num?)?.toDouble() ?? 300;
    final p = (_d?['piece_size'] as num?)?.toDouble() ?? 52;
    return w - p;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = MenuLanguage.isRtl;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(_t('cTitle'), style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 320,
          child: _loading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: _teal),
                    const SizedBox(height: 12),
                    Text(_t('cLoading'), style: const TextStyle(color: _soft)),
                  ]),
                )
              : (_d == null ? _failView() : _puzzleView()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(_t('cancel'))),
        ],
      ),
    );
  }

  Widget _failView() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error, style: const TextStyle(color: _err)),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: _load, child: Text(_t('cRetry'))),
    ]);
  }

  Widget _puzzleView() {
    final d = _d!;
    final w0 = (d['width'] as num).toDouble();
    final h0 = (d['height'] as num).toDouble();
    final p0 = (d['piece_size'] as num).toDouble();
    final top0 = (d['piece_top'] as num).toDouble();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth / w0;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: c.maxWidth,
              height: h0 * s,
              child: Stack(children: [
                SvgPicture.string('${d['bg_svg']}', width: c.maxWidth, height: h0 * s),
                Positioned(
                  left: _x * s,
                  top: top0 * s,
                  child: SvgPicture.string('${d['piece_svg']}', width: p0 * s, height: p0 * s),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Slider(
            value: _x.clamp(0, _maxX).toDouble(),
            min: 0,
            max: _maxX,
            activeColor: _teal,
            onChangeStart: (v) {
              _trail.clear();
              _sw
                ..reset()
                ..start();
              _trail.add([v, 0]);
            },
            onChanged: (v) {
              setState(() => _x = v);
              if (_trail.length < 290) _trail.add([v, _sw.elapsedMilliseconds]);
            },
            onChangeEnd: (v) {
              _trail.add([v, _sw.elapsedMilliseconds]);
              _sw.stop();
              Navigator.of(context).pop(_CaptchaResult('${d['captcha_id']}', v, List<List<num>>.from(_trail)));
            },
          ),
          Text(_t('cHelp'), style: const TextStyle(color: _soft, fontSize: 12.5)),
        ]);
      }),
    );
  }
}

/// صفحهٔ ثبت اقامتگاه داخل اپ — همهٔ مسیرهای ثبت هتل، کلبه، بوم‌گردی و ... به اینجا می‌رسند.
///
/// kind: stay | health | agency | leader — هر نوع به جدول و پنل خودش وصل می‌شود.
class StayRegistrationPage extends StatefulWidget {
  const StayRegistrationPage({super.key, this.kind = 'stay'});

  final String kind;

  @override
  State<StayRegistrationPage> createState() => _StayRegistrationPageState();
}

class _StayRegistrationPageState extends State<StayRegistrationPage> {
  final _name = TextEditingController();
  final _province = TextEditingController();
  final _provinceFocus = FocusNode();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _mobile = TextEditingController();
  final _phone = TextEditingController();
  final _rooms = TextEditingController();
  final _desc = TextEditingController();
  final _video = TextEditingController();
  final _insta = TextEditingController();
  final _web = TextEditingController();
  final _scroll = ScrollController();

  String _type = '';
  final Set<String> _amen = {};
  Uint8List? _photo;
  final Map<String, String> _errors = {};
  bool _busy = false;
  String _doneCode = '';
  List<Map<String, dynamic>> _mine = [];
  bool? _verified; // null = نامشخص (آفلاین)؛ سرور هنگام ارسال دوباره بررسی می‌کند
  final GlobalKey _locKey = GlobalKey();
  int? _editId; // وقتی null نیست: در حال ویرایش مورد تأییدشده
  bool _doneEdit = false;
  double? _lat;
  double? _lng;
  double? _mapZoom;

  bool get _rtl => MenuLanguage.isRtl;
  String get _kind => widget.kind;

  // فیلدهای مخصوص هر نوع
  final _specialty = TextEditingController();
  final _doctor = TextEditingController();
  final _hours = TextEditingController();
  final _manager = TextEditingController();
  final _license = TextEditingController();
  final _regions = TextEditingController();
  final _experience = TextEditingController();
  final _areas = TextEditingController();
  final _telegram = TextEditingController();
  final Set<String> _langs = {};
  final Set<String> _fields = {};

  @override
  void initState() {
    super.initState();
    _loadMine();
    _loadAccount();
  }

  Future<void> _loadAccount({bool notify = false}) async {
    final a = await AccountService.me();
    if (!mounted) return;
    setState(() => _verified = a == null ? null : (a.phoneVerified || a.emailVerified));
    if (notify && _verified == false) _snack(_t('gateStill'));
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
    await _loadAccount();
  }

  void _fill(Map<String, dynamic> f) {
    String v(String k) => '${f[k] ?? ''}';
    List<String> l(String k) => f[k] is List ? (f[k] as List).map((e) => '$e').toList() : <String>[];
    _name.text = v('name');
    _province.text = v('province');
    _city.text = v('city');
    _address.text = v('address');
    _mobile.text = v('mobile');
    _phone.text = v('phone');
    _rooms.text = v('rooms');
    _desc.text = v('description');
    _video.text = v('video_url');
    _insta.text = v('instagram');
    _web.text = v('website');
    _specialty.text = v('specialty');
    _doctor.text = v('doctor');
    _hours.text = v('hours');
    _manager.text = v('manager');
    _license.text = v('license');
    _regions.text = v('regions');
    _experience.text = v('experience');
    _areas.text = v('areas');
    _telegram.text = v('telegram');
    _lat = double.tryParse(v('latitude'));
    _lng = double.tryParse(v('longitude'));
    _mapZoom = double.tryParse(v('map_zoom'));
    _type = _kind == 'stay' ? v('accommodation_type') : (_kind == 'health' ? v('health_type') : '');
    _amen
      ..clear()
      ..addAll(l('amenities'));
    _langs
      ..clear()
      ..addAll(l('languages'));
    _fields
      ..clear()
      ..addAll(l('fields'));
  }

  Future<void> _startEdit(Map<String, dynamic> m) async {
    final uid = await BadgeService.userUid();
    final id = int.tryParse('${m['id']}') ?? 0;
    final j = await BadgeService.call('GET', '/api/stay-reg/item', query: {'user_uid': uid, 'kind': _kind, 'id': '$id'});
    if (!mounted) return;
    if (j == null || j['success'] != true || j['form'] is! Map) return _snack('${j?['message'] ?? _t('netErr')}');
    if (j['editable'] != true) return _snack('${j['message'] ?? _t('netErr')}');
    setState(() {
      _fill(Map<String, dynamic>.from(j['form'] as Map));
      _editId = id;
      _photo = null;
      _errors.clear();
      _doneCode = '';
      _doneEdit = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _submitEdit() async {
    final uid = await BadgeService.userUid();
    setState(() => _busy = true);
    final body = _formBody(uid)..['id'] = _editId;
    final j = await BadgeService.call('POST', '/api/stay-reg/edit', body: body);
    if (!mounted) return;
    setState(() => _busy = false);
    if (j == null) return _snack(_t('netErr'));
    if (j['success'] == true) {
      setState(() {
        _doneCode = '${j['tracking_code'] ?? ''}';
        _doneEdit = true;
      });
      _loadMine();
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    if ('${j['error']}' == 'account_not_verified') setState(() => _verified = false);
    _snack('${j['message'] ?? _t('netErr')}');
  }

  @override
  void dispose() {
    for (final c in [_name, _province, _city, _address, _mobile, _phone, _rooms, _desc, _video, _insta, _web, _specialty, _doctor, _hours, _manager, _license, _regions, _experience, _areas, _telegram]) {
      c.dispose();
    }
    _provinceFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    final uid = await BadgeService.userUid();
    final j = await BadgeService.call('GET', '/api/stay-reg/mine', query: {'user_uid': uid});
    if (!mounted || j == null || j['success'] != true || j['items'] is! List) return;
    setState(() => _mine = (j['items'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => '${e['kind'] ?? 'stay'}' == _kind)
        .toList());
  }

  Future<void> _deleteMine(int id) async {
    final uid = await BadgeService.userUid();
    await BadgeService.call('POST', '/api/stay-reg/delete', body: {'user_uid': uid, 'id': id, 'kind': _kind});
    await _loadMine();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickPhoto() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (f == null) return;
      final raw = await f.readAsBytes();
      if (!mounted) return;
      // ویرایشگر پیشرفته: برش، چرخش، فیلتر و … (خروجی کم‌حجم ۴۰۰×۴۰۰)
      final out = await cropProfilePhoto(context, raw);
      if (out == null || out.isEmpty || !mounted) return;
      setState(() => _photo = out);
    } catch (_) {
      _snack(_t('photoErr'));
    }
  }

  /// نام فارسی استان از متن واردشده (فارسی یا انگلیسی)؛ اگر در فهرست نبود null
  String? _resolveProvince(String text) {
    final q = _norm(text);
    if (q.isEmpty) return null;
    for (final p in _kProvinces) {
      if (_norm(p[0]) == q || _norm(p[1]) == q) return p[0];
    }
    return null;
  }

  bool _validate() {
    final e = <String, String>{};
    if (_name.text.trim().length < 3) e['name'] = _t('e_name');
    if (_kind == 'leader' && _name.text.trim().split(RegExp(r'\s+')).length < 2) e['name'] = _t('e_lname');
    if (_kind == 'stay' && _type.isEmpty) e['type'] = _t('e_type');
    if (_kind == 'health' && _type.isEmpty) e['type'] = _t('e_htype');
    if (_resolveProvince(_province.text) == null) e['province'] = _t('e_province');
    if (_city.text.trim().length < 2) e['city'] = _t('e_city');
    // در ویرایش، اگر اقامتگاه قبلاً مختصات نداشته، ثبت ویرایش نباید بی‌صدا قفل شود
    if ((_kind == 'stay' || _kind == 'health') && _lat == null && _editId == null) e['location'] = _t('e_location');
    if (!RegExp(r'^09\d{9}$').hasMatch(_digits(_mobile.text).replaceAll(RegExp(r'[\s\-]'), ''))) {
      e['mobile'] = _t('e_mobile');
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(e);
    });
    return e.isEmpty;
  }

  String _digits(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x06F0 && r <= 0x06F9) {
        b.writeCharCode(r - 0x06F0 + 48);
      } else if (r >= 0x0660 && r <= 0x0669) {
        b.writeCharCode(r - 0x0660 + 48);
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  Map<String, dynamic> _formBody(String uid) {
    return <String, dynamic>{
        'user_uid': uid,
        'kind': _kind,
        'hp': '',
        'name': _name.text.trim(),
        if (_kind == 'stay') 'accommodation_type': _type,
        if (_kind == 'health') 'health_type': _type,
        if (_kind == 'health') 'specialty': _specialty.text.trim(),
        if (_kind == 'health') 'doctor': _doctor.text.trim(),
        if (_kind == 'health') 'hours': _hours.text.trim(),
        if (_kind == 'agency') 'manager': _manager.text.trim(),
        if (_kind == 'agency' || _kind == 'leader') 'license': _license.text.trim(),
        if (_kind == 'agency') 'regions': _regions.text.trim(),
        if (_kind == 'agency' || _kind == 'leader') 'experience': _experience.text.trim(),
        if (_kind == 'leader') 'areas': _areas.text.trim(),
        if (_kind == 'leader') 'fields': _fields.toList(),
        if (_kind == 'leader') 'languages': _langs.toList(),
        if (_kind == 'agency' || _kind == 'leader') 'telegram': _telegram.text.trim(),
        'province': _resolveProvince(_province.text),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        if (_lat != null && _lng != null) 'latitude': _lat,
        if (_lat != null && _lng != null) 'longitude': _lng,
        if (_lat != null && _mapZoom != null) 'map_zoom': _mapZoom,
        'mobile': _digits(_mobile.text).replaceAll(RegExp(r'[\s\-]'), ''),
        'phone': _digits(_phone.text).trim(),
        if (_kind == 'stay') 'rooms': _digits(_rooms.text).trim(),
        'description': _desc.text.trim(),
        'amenities': _amen.toList(),
        'video_url': _video.text.trim(),
        'instagram': _insta.text.trim(),
        'website': _web.text.trim(),
        if (_photo != null) 'photo': 'data:image/jpeg;base64,${base64Encode(_photo!)}',
    };
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_validate()) {
      // قبلاً صفحه فقط به بالا می‌پرید و خطا پایین فرم پنهان می‌ماند؛ حالا پیام خطا نشان داده می‌شود
      _snack(_errors.values.first);
      final ctx = _errors.containsKey('location') ? _locKey.currentContext : null;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
      }
      return;
    }
    if (_editId != null) return _submitEdit();
    // پازل ضد ربات؛ در صورت خطای پازل، پازل تازه نشان داده می‌شود
    for (var attempt = 0; attempt < 4; attempt++) {
      final cap = await showDialog<_CaptchaResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CaptchaDialog(),
      );
      if (cap == null || !mounted) return;
      setState(() => _busy = true);
      final uid = await BadgeService.userUid();
      final body = _formBody(uid)
        ..addAll(<String, dynamic>{
          'captcha_id': cap.id,
          'captcha_x': cap.x,
          'captcha_trail': cap.trail,
        });
      final j = await BadgeService.call('POST', '/api/stay-reg/submit', body: body);
      if (!mounted) return;
      setState(() => _busy = false);
      if (j == null) return _snack(_t('netErr'));
      if (j['success'] == true) {
        setState(() => _doneCode = '${j['tracking_code'] ?? ''}');
        _loadMine();
        if (_scroll.hasClients) _scroll.jumpTo(0);
        return;
      }
      final code = '${j['error'] ?? ''}';
      if (code == 'account_not_verified') setState(() => _verified = false);
      _snack('${j['message'] ?? _t('netErr')}');
      if (!code.startsWith('captcha_')) return;
    }
  }

  void _reset() {
    for (final c in [_name, _province, _city, _address, _mobile, _phone, _rooms, _desc, _video, _insta, _web, _specialty, _doctor, _hours, _manager, _license, _regions, _experience, _areas, _telegram]) {
      c.clear();
    }
    setState(() {
      _type = '';
      _langs.clear();
      _fields.clear();
      _amen.clear();
      _photo = null;
      _errors.clear();
      _doneCode = '';
      _doneEdit = false;
      _editId = null;
      _lat = null;
      _lng = null;
      _mapZoom = null;
    });
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bar,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(_editId != null ? _t('editTitle') : _t('title_$_kind'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: _doneCode.isNotEmpty ? [_doneView()] : _formChildren(),
          ),
        ),
      ),
    );
  }

  List<Widget> _gateChildren() {
    return [
      Text(_t('intro_$_kind'), style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.verified_user_rounded, color: _gold, size: 44),
          const SizedBox(height: 10),
          Text(_t('gateTitle'), textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_t('gateText'), textAlign: TextAlign.center, style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openAccount,
              icon: const Icon(Icons.person_rounded),
              label: Text(_t('gateBtn'), style: const TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => _loadAccount(notify: true), child: Text(_t('gateRecheck'))),
        ]),
      ),
      if (_mine.isNotEmpty) ...[const SizedBox(height: 12), _mineCard()],
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _formChildren() {
    if (_verified == false && _editId == null) return _gateChildren();
    return [
      Text(_editId != null ? _t('editIntro') : _t('intro_$_kind'), style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
      const SizedBox(height: 12),
      if (_editId == null) RegistrationStepsCard(key: ValueKey('v$_verified'), compact: true),
      if (_mine.isNotEmpty) ...[_mineCard(), const SizedBox(height: 12)],
      _card(_t('s_info_$_kind'), [
        _field('name', _name, _t('name_$_kind'), maxLength: 80),
        if (_kind == 'stay') ...[
          _label(_t('type')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kTypes) _chip(_lbl(r), _type == r[0], () => setState(() => _type = r[0])),
          ]),
          _errText('type'),
          const SizedBox(height: 12),
        ],
        if (_kind == 'health') ...[
          _label(_t('healthType')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kHealthTypes) _chip(_lbl(r), _type == r[0], () => setState(() => _type = r[0])),
          ]),
          _errText('type'),
          const SizedBox(height: 12),
          _field('specialty', _specialty, _t('specialty'), maxLength: 80),
          _field('doctor', _doctor, _t('doctor'), maxLength: 80),
          _field('hours', _hours, _t('hours'), maxLength: 80),
        ],
        if (_kind == 'agency') ...[
          _field('manager', _manager, _t('manager'), maxLength: 80),
          _field('license', _license, _t('license'), maxLength: 40, ltr: true),
        ],
        _label(_t('province')),
        _provinceField(),
        _errText('province'),
        const SizedBox(height: 12),
        _field('city', _city, _t('city'), maxLength: 60),
        if (_kind != 'leader') _locationBox(),
        _field('address', _address, _t('address'), lines: 2, maxLength: 250),
      ]),
      _card(_t('s_contact'), [
        _field('mobile', _mobile, _t('mobile'), keyboard: TextInputType.phone, ltr: true, maxLength: 14),
        _field('phone', _phone, _t('phone'), keyboard: TextInputType.phone, ltr: true, maxLength: 16),
      ]),
      if (_kind == 'stay')
        _card(_t('s_more'), [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kAmenities)
              _chip(_lbl(r), _amen.contains(r[0]), () => setState(() => _amen.contains(r[0]) ? _amen.remove(r[0]) : _amen.add(r[0]))),
          ]),
          const SizedBox(height: 12),
          _field('rooms', _rooms, _t('rooms'), keyboard: TextInputType.number, maxLength: 3),
          _field('desc', _desc, _t('desc'), lines: 3, maxLength: 600),
        ])
      else if (_kind == 'agency')
        _card(_t('services'), [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kAgencyServices)
              _chip(_lbl(r), _amen.contains(r[0]), () => setState(() => _amen.contains(r[0]) ? _amen.remove(r[0]) : _amen.add(r[0]))),
          ]),
          const SizedBox(height: 12),
          _field('regions', _regions, _t('regions'), maxLength: 200),
          _field('experience', _experience, _t('experience'), maxLength: 100),
          _field('desc', _desc, _t('desc'), lines: 3, maxLength: 600),
        ])
      else if (_kind == 'leader')
        _card(_t('s_prof'), [
          _label(_t('fields')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kLeaderFields)
              _chip(MenuLanguage.current == 'fa' ? r[0] : (MenuLanguage.current == 'ar' ? r[2] : r[1]), _fields.contains(r[0]),
                  () => setState(() => _fields.contains(r[0]) ? _fields.remove(r[0]) : _fields.add(r[0]))),
          ]),
          const SizedBox(height: 12),
          _label(_t('languages')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in _kLanguages)
              _chip(MenuLanguage.current == 'fa' ? r[0] : (MenuLanguage.current == 'ar' ? r[2] : r[1]), _langs.contains(r[0]),
                  () => setState(() => _langs.contains(r[0]) ? _langs.remove(r[0]) : _langs.add(r[0]))),
          ]),
          const SizedBox(height: 12),
          _field('experience', _experience, _t('experience'), maxLength: 100),
          _field('license', _license, _t('license'), maxLength: 40, ltr: true),
          _field('areas', _areas, _t('areas'), maxLength: 200),
          _field('desc', _desc, _t('desc'), lines: 3, maxLength: 600),
        ])
      else
        _card(_t('desc'), [
          _field('desc', _desc, _t('desc'), lines: 3, maxLength: 600),
        ]),
      _card(_kind == 'agency' ? _t('photo_agency') : _t('s_photo'), [
        Row(children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
              border: Border.all(color: _line, width: 2),
              image: _photo == null ? null : DecorationImage(image: MemoryImage(_photo!), fit: BoxFit.cover),
            ),
            child: _photo == null ? const Icon(Icons.add_a_photo_rounded, color: _soft) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: Text(_photo == null ? _t('photoAdd') : _t('photoChange')),
              ),
              const SizedBox(height: 6),
              Text(
                _photo == null ? (_editId != null ? _t('editKeepPhoto') : _t('photoHint')) : '${(_photo!.length / 1024).round()} KB',
                style: const TextStyle(color: _soft, fontSize: 12, height: 1.7),
              ),
            ]),
          ),
        ]),
      ]),
      _card(_t('s_social'), [
        _field('video', _video, _t('video'), lines: 3, keyboard: TextInputType.multiline, ltr: true),
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_t('videoHint'), style: const TextStyle(color: _soft, fontSize: 12, height: 1.7))),
        _field('instagram', _insta, _t('instagram'), ltr: true),
        if (_kind == 'agency' || _kind == 'leader') _field('telegram', _telegram, _t('telegram'), ltr: true),
        _field('website', _web, _t('website'), keyboard: TextInputType.url, ltr: true),
      ]),
      const SizedBox(height: 4),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? Text(_t('sending'), style: const TextStyle(fontWeight: FontWeight.w800))
              : Text(_editId != null ? _t('editSubmit') : _t('submit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
      if (_editId != null) ...[
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _busy ? null : _reset, child: Text(_t('editCancel'))),
      ],
      const SizedBox(height: 24),
    ];
  }

  Future<void> _pickLocation() async {
    final r = await Navigator.of(context).push<PickedLocation>(MaterialPageRoute(
      builder: (_) => LocationPickerPage(
        initial: (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
        initialZoom: _mapZoom,
        initialAddress: _address.text,
      ),
    ));
    if (r == null || !mounted) return;
    setState(() {
      _lat = r.lat;
      _lng = r.lng;
      _mapZoom = r.zoom;
      _errors.remove('location');
      if (r.address.isNotEmpty) _address.text = r.address;
      final st = r.state.replaceAll(RegExp(r'^(استان|محافظة)\s*'), '').replaceAll(RegExp(r'\s*(Province|Provinz)$'), '').trim();
      final p = _resolveProvince(st);
      if (p != null) _province.text = p;
      if (_city.text.trim().isEmpty && r.city.isNotEmpty) _city.text = r.city.replaceAll(RegExp(r'^(شهرستان|شهر)\s*'), '').trim();
    });
  }

  /// جستجوی آدرس / انتخاب از روی نقشه (مثل دیوار)
  Widget _locationBox() {
    final has = _lat != null && _lng != null;
    return Padding(
      key: _locKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy ? null : _pickLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: has ? const Color(0xffeafaf1) : _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _errors.containsKey('location') ? _err : (has ? const Color(0xff1fb36b) : _line), width: 1.5),
            ),
            child: Row(children: [
              Icon(has ? Icons.check_circle_rounded : Icons.search_rounded, color: has ? const Color(0xff1fb36b) : _teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(has ? _t('locSet') : _t('locSearch'), style: TextStyle(color: has ? const Color(0xff176b43) : _ink, fontWeight: FontWeight.w800, fontSize: 13.5)),
                  if (has)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}', style: const TextStyle(color: _soft, fontSize: 12)),
                    ),
                ]),
              ),
              Icon(has ? Icons.edit_location_alt_rounded : Icons.map_rounded, color: _soft),
              if (has) Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: Text(_t('locChange'), style: const TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: 12))),
            ]),
          ),
        ),
        _errText('location'),
        const SizedBox(height: 6),
        Text(_t('locTip'), style: const TextStyle(color: _soft, fontSize: 12, height: 1.7)),
      ]),
    );
  }

  Widget _provinceField() {
    return RawAutocomplete<String>(
      textEditingController: _province,
      focusNode: _provinceFocus,
      optionsBuilder: (v) {
        final q = _norm(v.text);
        final all = _kProvinces;
        final starts = <String>[];
        final contains = <String>[];
        for (final p in all) {
          final a = _norm(p[0]);
          final b = _norm(p[1]);
          if (q.isEmpty || a.startsWith(q) || b.startsWith(q)) {
            starts.add(_provLabel(p));
          } else if (a.contains(q) || b.contains(q)) {
            contains.add(_provLabel(p));
          }
        }
        return [...starts, ...contains];
      },
      onSelected: (v) => setState(() => _errors.remove('province')),
      fieldViewBuilder: (context, ctrl, focus, onSubmit) {
        return TextField(
          controller: ctrl,
          focusNode: focus,
          decoration: _deco(_t('provinceHint'), error: _errors['province'] != null).copyWith(
            suffixIcon: const Icon(Icons.search_rounded, color: _soft),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final o = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(o),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(o, style: const TextStyle(color: _ink, fontSize: 15)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _deco(String hint, {bool error = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: error ? _err : _line),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _soft, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: border,
      border: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _teal, width: 1.6),
      ),
      counterText: '',
    );
  }

  Widget _field(
    String key,
    TextEditingController c,
    String label, {
    int lines = 1,
    int? maxLength,
    TextInputType? keyboard,
    bool ltr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextField(
          controller: c,
          minLines: lines,
          maxLines: lines,
          maxLength: maxLength,
          keyboardType: keyboard ?? (lines > 1 ? TextInputType.multiline : TextInputType.text),
          textDirection: ltr ? TextDirection.ltr : null,
          style: const TextStyle(color: _ink, fontSize: 15),
          onChanged: (_) {
            if (_errors.containsKey(key)) setState(() => _errors.remove(key));
          },
          decoration: _deco('', error: _errors[key] != null),
        ),
        _errText(key),
      ]),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _errText(String key) {
    final e = _errors[key];
    if (e == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(e, style: const TextStyle(color: _err, fontSize: 12)),
    );
  }

  Widget _chip(String text, bool on, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _teal : _line),
        ),
        child: Text(text, style: TextStyle(color: on ? Colors.white : _soft, fontSize: 13, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffffdf7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xfff1dfb6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(color: Color(0xff765000), fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  // ---------- باتری اعتبار + روزشمار ----------
  String _tl(String fa, String en, String ar) {
    switch (MenuLanguage.current) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  final Set<String> _renewSent = <String>{};

  String get _renewModule {
    switch (_kind) {
      case 'health':
        return 'health_tourism';
      case 'agency':
        return 'travel_agencies';
      case 'leader':
        return 'tour_guides';
      default:
        return 'accommodations';
    }
  }

  Future<void> _requestRenew(Map<String, dynamic> m) async {
    final id = int.tryParse('${m['id']}') ?? 0;
    if (id <= 0) return;
    final key = '$_kind:$id';
    final j = await BadgeService.call('POST', '/renewal-requests', body: {'module': _renewModule, 'id': id});
    if (!mounted) return;
    if (j != null && j['success'] == true) {
      setState(() => _renewSent.add(key));
      _snack(_tl('درخواست تمدید برای پشتیبانی ثبت شد.', 'Renewal request sent to support.', 'تم إرسال طلب التجديد إلى الدعم.'));
    } else {
      _snack(_tl('ثبت درخواست ناموفق بود. دوباره تلاش کنید.', 'Could not send the request. Try again.', 'تعذر إرسال الطلب. حاول مرة أخرى.'));
    }
  }

  Future<void> _callSupport(String phone) async {
    final n = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.isEmpty) return;
    try {
      await launchUrl(Uri.parse('tel:$n'), mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack(_tl('امکان باز کردن تماس وجود ندارد.', 'Cannot open the dialer.', 'تعذر فتح الاتصال.'));
    }
  }

  /// کارت «شارژ اعتبار»: باتری گرادیانی با صاعقه، درصد و روز مانده
  Widget _chargeCard(int days, int pct, Color c) {
    final empty = days <= 0;
    final w = (pct.clamp(0, 100)) / 100.0;
    final c2 = Color.lerp(c, Colors.white, 0.35)!;
    final title = empty
        ? _tl('اعتبار تمام شده', 'Credit ended', 'انتهى الرصيد')
        : _tl('شارژ اعتبار', 'Credit charge', 'شحن الرصيد');
    return Semantics(
      label: empty
          ? _tl('اعتبار تمام شده', 'Credit ended', 'انتهى الرصيد')
          : _tl('$days روز اعتبار باقی مانده', '$days days left', 'متبقي $days يوماً'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [c.withValues(alpha: 0.13), c.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [c, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(empty ? Icons.battery_alert_rounded : Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title, style: const TextStyle(color: _soft, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(empty ? '0%' : '$pct%', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 5),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xffb7c7c1), width: 1.6),
                      ),
                      child: LayoutBuilder(builder: (context, box) {
                        return Stack(children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: empty ? 0.02 : (w < 0.05 ? 0.05 : w)),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Container(
                              width: box.maxWidth * v,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [c, c2]),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          // خط‌های جداکننده‌ی باتری (۴ بخش)
                          for (final f in const [0.25, 0.5, 0.75])
                            Positioned(
                              left: box.maxWidth * f,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1.2, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                        ]);
                      }),
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 8,
                    margin: const EdgeInsets.only(left: 1.5),
                    decoration: const BoxDecoration(
                      color: Color(0xffb7c7c1),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(empty ? '—' : '$days', style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 22, height: 1.0)),
            const SizedBox(height: 2),
            Text(empty ? _tl('تمام شد', 'Ended', 'انتهى') : _tl('روز مانده', 'days left', 'يوم متبقٍ'),
                style: const TextStyle(color: _soft, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _mineItem(Map<String, dynamic> m) {
    final approved = m['status'] == 'approved';
    final kindKey = '${m['status_kind'] ?? ''}';
    final days = int.tryParse('${m['days_left']}');
    final pct = int.tryParse('${m['battery_percent']}') ?? 0;
    final level = '${m['battery_level'] ?? ''}';
    final inactive = kindKey == 'inactive' || (days != null && days <= 0 && approved);
    final low = !inactive && approved && (level == 'low' || (days != null && days <= 15));

    Color fg, bg;
    String label;
    if (inactive) {
      fg = const Color(0xffc0392b);
      bg = const Color(0xffffe9e6);
      label = '${m['status_label'] ?? ''}'.isNotEmpty ? '${m['status_label']}' : _tl('غیرفعال، پایان اعتبار', 'Inactive, credit ended', 'غير نشط، انتهى الرصيد');
    } else if (low) {
      fg = const Color(0xffb45309);
      bg = const Color(0xfffff3d6);
      label = _tl('نزدیک پایان اعتبار', 'Credit ending soon', 'قارب الرصيد على الانتهاء');
    } else if (approved) {
      fg = const Color(0xff176b43);
      bg = const Color(0xffeafaf1);
      label = '${m['status_label'] ?? ''}'.isNotEmpty ? '${m['status_label']}' : _t('approved');
    } else {
      fg = _gold;
      bg = const Color(0xfffff3d6);
      label = '${m['status_label'] ?? ''}'.isNotEmpty ? '${m['status_label']}' : _t('pending');
    }
    final batColor = inactive ? const Color(0xffdc2626) : (low ? const Color(0xffd97706) : const Color(0xff16a34a));

    final note = inactive
        ? _tl('اعتبار این ثبت تمام شده است. برای تمدید با پشتیبانی تماس بگیرید.', 'Credit ended. Contact support to renew.', 'انتهى الرصيد. اتصل بالدعم للتجديد.')
        : (low
            ? _tl('اعتبار شما رو به پایان است. برای جلوگیری از غیرفعال شدن تمدید کنید.', 'Credit is running out. Renew to stay active.', 'الرصيد على وشك الانتهاء. جدّد للبقاء نشطاً.')
            : '${m['status_note'] ?? ''}');
    final support = '${m['support_phone'] ?? ''}'.trim();
    final key = '$_kind:${m['id']}';
    final sent = _renewSent.contains(key);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${m['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
        Text('${m['tracking_code'] ?? ''} · ${m['province'] ?? ''} ${m['city'] ?? ''}', style: const TextStyle(color: _soft, fontSize: 12)),
        if (days != null) ...[
          const SizedBox(height: 10),
          _chargeCard(days, pct, batColor),
        ],
        const SizedBox(height: 8),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
          if (approved && m['pending_edit'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xffe6f1ff), borderRadius: BorderRadius.circular(999)),
              child: Text(_t('editPending'), style: const TextStyle(color: Color(0xff1d5fb4), fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(width: 2),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _t('editBtn'),
            onPressed: _busy ? null : () => _startEdit(m),
            icon: Icon(Icons.edit_rounded, color: (!approved || m['pending_edit'] == true) ? _err : _teal, size: 20),
          ),
          if (!approved)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _t('delete'),
              onPressed: () => _deleteMine(int.tryParse('${m['id']}') ?? 0),
              icon: const Icon(Icons.delete_outline_rounded, color: _err, size: 20),
            ),
        ]),
        if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(note, style: const TextStyle(color: _soft, fontSize: 12.5, height: 1.8))),
        if (low)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sent ? null : () => _requestRenew(m),
                icon: Icon(sent ? Icons.check_rounded : Icons.autorenew_rounded, size: 18),
                label: Text(sent ? _tl('درخواست تمدید ثبت شد', 'Renewal requested', 'تم طلب التجديد') : _tl('درخواست تمدید', 'Request renewal', 'طلب التجديد')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffd97706), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
        if (inactive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: support.isEmpty ? null : () => _callSupport(support),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(support.isEmpty ? _tl('تماس با پشتیبانی', 'Contact support', 'اتصل بالدعم') : _tl('تماس با پشتیبانی  $support', 'Call support  $support', 'اتصل بالدعم  $support')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffdc2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _mineCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_t('mine'), style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        for (final m in _mine) _mineItem(m),
      ]),
    );
  }

  Widget _doneView() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(children: [
        const CircleAvatar(radius: 34, backgroundColor: _teal, child: Icon(Icons.check_rounded, color: Colors.white, size: 38)),
        const SizedBox(height: 14),
        Text(_doneEdit ? _t('editDoneTitle') : _t('doneTitle'), textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(_t('doneCode'), style: const TextStyle(color: _soft, fontSize: 13)),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(_doneCode, style: const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        Text(_doneEdit ? _t('editDoneText') : _t('doneText'), textAlign: TextAlign.center, style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
        const SizedBox(height: 16),
        if (_mine.isNotEmpty) _mineCard(),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _reset, child: Text(_t('another')))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(_t('back')))),
      ]),
    );
  }
}
