import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../services/badge_service.dart';
import '../../services/user_profile_service.dart';
import '../../core/language/new_texts.dart';
import '../../widgets/linkified_text.dart';
import 'badge_page.dart';
import 'google_link_card.dart';
import 'photo_cropper.dart';
import 'phone_verify_card.dart';
import '../../services/account_service.dart';

const Color _bg = Color(0xff071722);
const Color _card = Color(0xff0e2433);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);
const Color _sky = Color(0xff66d9ff);
const Color _red = Color(0xffff7070);

const List<String> _interestOptions = [
  'طبیعت‌گردی',
  'تاریخی و فرهنگی',
  'ماجراجویی',
  'سفر خانوادگی',
  'تور خارجی',
  'کوهنوردی',
  'غذا و سوغات',
  'عکاسی',
  'گردشگری سلامت',
];

/// «پروفایل من» — حساب کاربری، ویرایش اطلاعات و تصویر پروفایل در یک صفحه.
/// نام کاربری، بیو (مثل تلگرام)، عکس (فشرده‌شده)، علاقه‌مندی‌ها، ویرایش و حذف.
/// همه‌چیز روی خود گوشی ذخیره می‌شود.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  String _visibility = 'all';
  final _picker = ImagePicker();

  UserProfile _saved = const UserProfile();
  String _photo = '';
  Set<String> _interests = {};
  bool _loading = true;
  bool _editing = false;
  bool _busy = false;
  BadgeStatus? _badge;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBadge();
  }

  Future<void> _loadBadge() async {
    final st = await BadgeService.fetchStatus();
    if (mounted && st != null) setState(() => _badge = st);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await UserProfileService.load();
    if (!mounted) return;
    setState(() {
      _saved = p;
      _fill(p);
      _editing = p.isEmpty; // اولین بار مستقیم وارد حالت ویرایش می‌شود
      _loading = false;
    });
  }

  /// بعد از ورود با گوگل/پیامک: پروفایل همان حساب از سرور می‌آید و نام‌کاربری قابل ویرایش می‌شود (مثل تلگرام).
  Future<void> _afterLogin() async {
    await _load();
    if (!mounted) return;
    // حساب تأیید شد: نام‌کاربری حالا روی سرور رزرو می‌شود (اگر تکراری بود، پیام می‌دهد تا نام دیگری بگذارید)
    final rr = await BadgeService.registerUser();
    if (!mounted) return;
    if (rr.isUsernameError) {
      await AccountService.pullProfile();
      await _load();
    }
    if (!mounted) return;
    setState(() => _editing = true);
    _snack(rr.isUsernameError
        ? 'این نام‌کاربری قبلاً توسط حساب تأییدشدهٔ دیگری گرفته شده؛ نام دیگری انتخاب کنید.'
        : 'وارد شدید. اکنون می‌توانید نام و نام‌کاربری را ویرایش کنید.');
  }

  void _fill(UserProfile p) {
    _nameCtrl.text = p.displayName;
    _userCtrl.text = p.username;
    _bioCtrl.text = p.bio;
    _cityCtrl.text = p.city;
    _phoneCtrl.text = p.phone;
    _videoCtrl.text = p.videoLink;
    _visibility = p.visibility;
    _photo = p.photoBase64;
    _interests = p.interests.toSet();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// انتخاب عکس از گالری/دوربین؛ فشرده‌سازی در همان لحظه انجام می‌شود:
  /// حداکثر ۵۱۲ پیکسل و کیفیت ۷۰ (معمولاً زیر ۶۰ کیلوبایت).
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      if (!mounted) return;
      // کادر دایره‌ای: جابه‌جایی و زوم، خروجی ۴۰۰×۴۰۰ کم‌حجم
      final cropped = await cropProfilePhoto(context, raw);
      if (cropped == null || !mounted) return;
      setState(() => _photo = base64Encode(cropped));
    } catch (_) {
      _snack('امکان انتخاب عکس نبود. دسترسی دوربین/گالری را بررسی کنید.');
    }
  }

  void _photoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _teal),
                title: const Text('انتخاب از گالری', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: _sky),
                title: const Text('گرفتن عکس با دوربین', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              if (_photo.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: _red),
                  title: const Text('حذف عکس', style: TextStyle(color: _red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photo = '');
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    // نام کاربری باید یکتا باشد (بدون حساسیت به حروف بزرگ/کوچک)؛ قبل از ذخیره بررسی می‌شود
    final wantedUser = _userCtrl.text.trim().replaceAll('@', '');
    if (wantedUser.isNotEmpty && wantedUser.toLowerCase() != _saved.username.toLowerCase()) {
      final chk = await AccountService.usernameAvailable(wantedUser);
      if (!chk.available) {
        if (mounted) setState(() => _busy = false);
        _snack('${chk.message}\nاگر این نام‌کاربری مال حساب خودتان است، اول با گوگل یا شماره وارد شوید؛ بعد می‌توانید آن را ویرایش کنید.');
        return;
      }
    }
    final p = UserProfile(
      displayName: _nameCtrl.text.trim(),
      username: _userCtrl.text.trim().replaceAll('@', ''),
      bio: _bioCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      interests: _interests.toList(),
      photoBase64: _photo,
      visibility: _visibility,
      videoLink: _videoCtrl.text.trim(),
    );
    try {
      final persisted = await UserProfileService.save(p);
      final rr = await BadgeService.registerUser(); // همگام‌سازی با سرور و چت‌روم
      if (!mounted) return;
      if (rr.isUsernameError) {
        // سرور نام را نپذیرفت (مثلاً هم‌زمان کسی گرفته)؛ نام کاربری همان حساب را از سرور برمی‌گردانیم
        await AccountService.pullProfile();
        final fresh = await UserProfileService.load();
        if (!mounted) return;
        setState(() => _saved = fresh);
        _fill(fresh);
        _snack(rr.message.isEmpty ? NT.t('un_invalid') : rr.message);
        return;
      }
      setState(() {
        _saved = p;
        _editing = false;
      });
      if (!persisted) {
        _snack('پروفایل ذخیره شد، ولی حافظهٔ گوشی خطا داد؛ بعد از بستن اپ ممکن است پاک شود. (${BadgeService.lastError})');
      } else if (!rr.ok && rr.code == 'net') {
        _snack('روی گوشی ذخیره شد، اما ارتباط با سرور برقرار نشد (${rr.message}).');
      } else if (!rr.ok) {
        _snack(rr.message.isEmpty ? 'سرور ثبت را نپذیرفت (${rr.code}).' : rr.message);
      } else {
        _snack('پروفایل ذخیره شد.');
      }
    } catch (e) {
      _snack('ذخیره انجام نشد (${e.runtimeType}). دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('حذف پروفایل', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          content: const Text(
            'نام، بیو، عکس و همهٔ اطلاعات پروفایل از روی این دستگاه پاک می‌شود. ادامه می‌دهید؟',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف', style: TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff9f3030), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await UserProfileService.clear();
    if (!mounted) return;
    setState(() {
      _saved = const UserProfile();
      _fill(_saved);
      _editing = true;
    });
    _snack('پروفایل حذف شد.');
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
      prefixIcon: icon == null ? null : Icon(icon, color: _gold.withValues(alpha: 0.8), size: 20),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      filled: true,
      fillColor: _card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _gold.withValues(alpha: 0.25))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _gold.withValues(alpha: 0.25))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _gold, width: 1.4)),
    );
  }

  Widget _avatar({double radius = 54}) {
    final bytes = _editing ? _decode(_photo) : _saved.photoBytes;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 2),
            boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 14)],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xff102733),
            backgroundImage: bytes != null ? MemoryImage(bytes) : null,
            child: bytes == null ? Icon(Icons.person_rounded, size: radius, color: _gold) : null,
          ),
        ),
        if (_editing)
          Positioned(
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: _photoSheet,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_teal, _sky]),
                  border: Border.all(color: _bg, width: 2.5),
                ),
                child: const Icon(Icons.photo_camera_rounded, size: 19, color: Color(0xff06121d)),
              ),
            ),
          ),
      ],
    );
  }

  static Uint8List? _decode(String b64) {
    if (b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _gold),
          title: const Text('پروفایل من', style: TextStyle(color: _gold, fontSize: 19, fontWeight: FontWeight.bold)),
          actions: [
            if (!_loading && !_editing)
              IconButton(
                tooltip: 'ویرایش',
                icon: const Icon(Icons.edit_rounded, color: _sky),
                onPressed: () => setState(() => _editing = true),
              ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : (_editing ? _buildEditor() : _buildView()),
        ),
      ),
    );
  }

  // ---------------------------- نمایش ----------------------------
  Widget _buildView() {
    final p = _saved;
    final name = p.displayName.isNotEmpty ? p.displayName : 'کاربر سایروس';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Center(child: _avatar()),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
              if (_badge != null && (_badge!.hasGold || _badge!.hasBlue)) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  color: _badge!.hasGold ? const Color(0xffffc233) : const Color(0xff2a8cff),
                  size: 24,
                ),
              ],
            ],
          ),
        ),
        if (p.username.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('@${p.username}', textDirection: TextDirection.ltr, style: const TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        const SizedBox(height: 18),
        GoogleLinkCard(onChanged: _afterLogin),
        PhoneVerifyCard(onChanged: _afterLogin),
        if (p.displayName.isNotEmpty && p.photoBase64.isNotEmpty) _badgeCard(),
        if (p.bio.isNotEmpty) _infoCard(Icons.info_outline_rounded, 'دربارهٔ من', p.bio, _gold),
        if (p.city.isNotEmpty) _infoCard(Icons.location_city_rounded, 'شهر', p.city, _sky),
        if (p.phone.isNotEmpty) _infoCard(Icons.phone_rounded, 'شماره تماس', p.phone, _teal),
        if (p.videoLink.isNotEmpty) _videoCard(p.videoLink),
        _infoCard(Icons.visibility_rounded, NT.t('vis_card'), _visLabel(p.visibility), _sky),
        if (p.interests.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('علاقه‌مندی‌ها', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.interests
                      .map((e) => Chip(
                            label: Text(e, style: const TextStyle(color: Color(0xff06121d), fontSize: 12, fontWeight: FontWeight.w700)),
                            backgroundColor: _teal,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sky,
                  foregroundColor: const Color(0xff06121d),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('ویرایش', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9f3030),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          NT.t('sync_note'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5),
        ),
      ],
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      );

  Widget _badgeCard() {
    final has = _badge != null && (_badge!.hasGold || _badge!.hasBlue);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xff1b4f9c), Color(0xff2a8cff), Color(0xffffc233)]),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgePage()));
            _loadBadge();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        has ? 'تیک شما فعال است' : 'دریافت تیک آبی / طلایی',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
                      ),
                      const SizedBox(height: 3),
                      const Text('اعتبار سالانه · اختیاری', style: TextStyle(color: Color(0xffeaf3ff), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<String> _visKeys = ['all', 'friends', 'none'];
  String _visLabel(String v) => NT.t('vis_${_visKeys.contains(v) ? v : 'all'}');

  Widget _videoCard(String link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.play_circle_fill_rounded, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(NT.t('video_title'), style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                LinkifiedText(text: link, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            tooltip: NT.t('copy_link'),
            icon: const Icon(Icons.copy_rounded, color: _teal, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              _snack(NT.t('copied'));
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- ویرایش ----------------------------
  Widget _buildEditor() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(child: _avatar()),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _photoSheet,
              icon: const Icon(Icons.add_a_photo_rounded, color: _teal, size: 18),
              label: const Text('تغییر تصویر پروفایل', style: TextStyle(color: _teal)),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('نام نمایشی', icon: Icons.badge_rounded),
            maxLength: 40,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'نام را وارد کنید' : null,
          ),
          TextFormField(
            controller: _userCtrl,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: _dec(NT.t('un_label'), hint: 'cyrus_traveler', icon: Icons.alternate_email_rounded, helper: NT.t('un_helper')),
            maxLength: 30,
            validator: (v) {
              final t = (v ?? '').trim().replaceAll('@', '');
              if (t.isEmpty) return null; // اختیاری
              if (!RegExp(r'^[A-Za-z0-9_.]{3,30}$').hasMatch(t)) return NT.t('un_invalid');
              return null;
            },
          ),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 160,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('بیو (دربارهٔ من)', hint: 'چند خط دربارهٔ خودتان بنویسید…', icon: Icons.notes_rounded),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _cityCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('شهر', icon: Icons.location_city_rounded),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('شماره تماس (اختیاری)', hint: '09xxxxxxxxx', icon: Icons.phone_rounded),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _videoCtrl,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white),
            decoration: _dec(
              NT.t('video_label'),
              hint: 'https://cyrustourist.ir/accommodation/6',
              icon: Icons.play_circle_outline_rounded,
              helper: NT.t('video_helper'),
            ).copyWith(
              suffixIcon: IconButton(
                tooltip: NT.t('paste'),
                icon: const Icon(Icons.content_paste_rounded, color: _teal, size: 20),
                onPressed: () async {
                  final d = await Clipboard.getData(Clipboard.kTextPlain);
                  final t = (d?.text ?? '').trim();
                  if (t.isNotEmpty) setState(() => _videoCtrl.text = t);
                },
              ),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              if (!RegExp(r'^https://(www\.)?cyrustourist\.ir/\S*$', caseSensitive: false).hasMatch(t)) {
                return NT.t('video_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          Text(NT.t('vis_title'), style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            NT.t('vis_hint'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _visKeys.map((k) {
              final sel = _visibility == k;
              return ChoiceChip(
                label: Text(NT.t('vis_$k')),
                selected: sel,
                onSelected: (_) => setState(() => _visibility = k),
                selectedColor: _gold,
                backgroundColor: _card,
                labelStyle: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5),
                side: BorderSide(color: _gold.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text('علاقه‌مندی‌های سفر', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _interestOptions.map((e) {
              final sel = _interests.contains(e);
              return FilterChip(
                label: Text(e),
                selected: sel,
                onSelected: (v) => setState(() => v ? _interests.add(e) : _interests.remove(e)),
                selectedColor: _teal,
                checkmarkColor: const Color(0xff06121d),
                backgroundColor: _card,
                labelStyle: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5),
                side: BorderSide(color: _gold.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: const Color(0xff06121d),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                      : const Icon(Icons.check_rounded),
                  label: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (!_saved.isEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() {
                      _fill(_saved);
                      _editing = false;
                    }),
                    child: const Text('انصراف'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
