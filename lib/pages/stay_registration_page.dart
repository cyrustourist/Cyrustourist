import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../core/language/menu_translations.dart';
import '../services/badge_service.dart';

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
    'video': 'لینک فیلم (آپارات یا یوتیوب)',
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
    'video': 'Video link (Aparat or YouTube)',
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
    'video': 'رابط الفيديو (آپارات أو يوتيوب)',
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

String _t(String key) {
  final m = _kTx[MenuLanguage.current] ?? _kTx['en']!;
  return m[key] ?? _kTx['en']![key] ?? _kTx['fa']![key] ?? key;
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
class StayRegistrationPage extends StatefulWidget {
  const StayRegistrationPage({super.key});

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

  bool get _rtl => MenuLanguage.isRtl;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  @override
  void dispose() {
    for (final c in [_name, _province, _city, _address, _mobile, _phone, _rooms, _desc, _video, _insta, _web]) {
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
    setState(() => _mine = (j['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
  }

  Future<void> _deleteMine(int id) async {
    final uid = await BadgeService.userUid();
    await BadgeService.call('POST', '/api/stay-reg/delete', body: {'user_uid': uid, 'id': id});
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
      final out = await compute(_compressJpeg, raw);
      if (out.isEmpty) return _snack(_t('photoErr'));
      if (!mounted) return;
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
    if (_type.isEmpty) e['type'] = _t('e_type');
    if (_resolveProvince(_province.text) == null) e['province'] = _t('e_province');
    if (_city.text.trim().length < 2) e['city'] = _t('e_city');
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

  Future<void> _submit() async {
    if (_busy) return;
    if (!_validate()) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
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
      final body = <String, dynamic>{
        'user_uid': uid,
        'hp': '',
        'name': _name.text.trim(),
        'accommodation_type': _type,
        'province': _resolveProvince(_province.text),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'mobile': _digits(_mobile.text).replaceAll(RegExp(r'[\s\-]'), ''),
        'phone': _digits(_phone.text).trim(),
        'rooms': _digits(_rooms.text).trim(),
        'description': _desc.text.trim(),
        'amenities': _amen.toList(),
        'video_url': _video.text.trim(),
        'instagram': _insta.text.trim(),
        'website': _web.text.trim(),
        'captcha_id': cap.id,
        'captcha_x': cap.x,
        'captcha_trail': cap.trail,
        if (_photo != null) 'photo': 'data:image/jpeg;base64,${base64Encode(_photo!)}',
      };
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
      _snack('${j['message'] ?? _t('netErr')}');
      if (!code.startsWith('captcha_')) return;
    }
  }

  void _reset() {
    for (final c in [_name, _province, _city, _address, _mobile, _phone, _rooms, _desc, _video, _insta, _web]) {
      c.clear();
    }
    setState(() {
      _type = '';
      _amen.clear();
      _photo = null;
      _errors.clear();
      _doneCode = '';
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
          title: Text(_t('title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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

  List<Widget> _formChildren() {
    return [
      Text(_t('intro'), style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
      const SizedBox(height: 12),
      if (_mine.isNotEmpty) ...[_mineCard(), const SizedBox(height: 12)],
      _card(_t('s_info'), [
        _field('name', _name, _t('name'), maxLength: 80),
        _label(_t('type')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _kTypes) _chip(_lbl(r), _type == r[0], () => setState(() => _type = r[0])),
        ]),
        _errText('type'),
        const SizedBox(height: 12),
        _label(_t('province')),
        _provinceField(),
        _errText('province'),
        const SizedBox(height: 12),
        _field('city', _city, _t('city'), maxLength: 60),
        _field('address', _address, _t('address'), lines: 2, maxLength: 250),
      ]),
      _card(_t('s_contact'), [
        _field('mobile', _mobile, _t('mobile'), keyboard: TextInputType.phone, ltr: true, maxLength: 14),
        _field('phone', _phone, _t('phone'), keyboard: TextInputType.phone, ltr: true, maxLength: 16),
      ]),
      _card(_t('s_more'), [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _kAmenities)
            _chip(_lbl(r), _amen.contains(r[0]), () => setState(() => _amen.contains(r[0]) ? _amen.remove(r[0]) : _amen.add(r[0]))),
        ]),
        const SizedBox(height: 12),
        _field('rooms', _rooms, _t('rooms'), keyboard: TextInputType.number, maxLength: 3),
        _field('desc', _desc, _t('desc'), lines: 3, maxLength: 600),
      ]),
      _card(_t('s_photo'), [
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
                _photo == null ? _t('photoHint') : '${(_photo!.length / 1024).round()} KB',
                style: const TextStyle(color: _soft, fontSize: 12, height: 1.7),
              ),
            ]),
          ),
        ]),
      ]),
      _card(_t('s_social'), [
        _field('video', _video, _t('video'), keyboard: TextInputType.url, ltr: true),
        _field('instagram', _insta, _t('instagram'), ltr: true),
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
              : Text(_t('submit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
      const SizedBox(height: 24),
    ];
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
        const SizedBox(height: 8),
        for (final m in _mine)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${m['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                  Text('${m['tracking_code'] ?? ''} · ${m['province'] ?? ''} ${m['city'] ?? ''}', style: const TextStyle(color: _soft, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m['status'] == 'approved' ? const Color(0xffeafaf1) : const Color(0xfffff3d6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  m['status'] == 'approved' ? _t('approved') : _t('pending'),
                  style: TextStyle(
                    color: m['status'] == 'approved' ? const Color(0xff176b43) : _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (m['status'] != 'approved')
                IconButton(
                  tooltip: _t('delete'),
                  onPressed: () => _deleteMine(int.tryParse('${m['id']}') ?? 0),
                  icon: const Icon(Icons.delete_outline_rounded, color: _err, size: 20),
                ),
            ]),
          ),
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
        Text(_t('doneTitle'), textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(_t('doneCode'), style: const TextStyle(color: _soft, fontSize: 13)),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(_doneCode, style: const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        Text(_t('doneText'), textAlign: TextAlign.center, style: const TextStyle(color: _soft, fontSize: 13, height: 1.9)),
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
