import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _goldBright = Color(0xffffe39a);
const Color _teal = Color(0xff29e0ad);

class _SupportInfo {
  static const String phone = '09153448818';
  static const String whatsapp = 'https://wa.me/989153448818';
  static const String telegram = 'https://t.me/Cyrustourist';
}

const List<String> _contactMethods = ['تماس تلفنی', 'تلگرام', 'واتساپ'];

/// «درخواست ثبت‌نام لیدر» — فقط ارسال درخواست به پشتیبانی؛
/// ثبت‌نام نهایی و فعال‌سازی فقط توسط مدیریت انجام می‌شود.
class LeaderRegistrationFormPage extends StatefulWidget {
  const LeaderRegistrationFormPage({super.key});

  @override
  State<LeaderRegistrationFormPage> createState() =>
      _LeaderRegistrationFormPageState();
}

class _LeaderRegistrationFormPageState extends State<LeaderRegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _preferredContact = _contactMethods.first;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _fieldCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _buildMessage() {
    return 'درخواست ثبت‌نام لیدر — CYRUS TOURIST\n\n'
        'نام و نام خانوادگی: ${_nameCtrl.text.trim()}\n'
        'شماره تماس: ${_phoneCtrl.text.trim()}\n'
        'شهر محل فعالیت: ${_cityCtrl.text.trim()}\n'
        'زمینه فعالیت: ${_fieldCtrl.text.trim()}\n'
        'توضیحات: ${_descCtrl.text.trim().isEmpty ? '—' : _descCtrl.text.trim()}\n'
        'روش تماس ترجیحی: $_preferredContact';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final message = Uri.encodeComponent(_buildMessage());
    final uri = Uri.parse('${_SupportInfo.whatsapp}?text=$message');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    if (!mounted) return;
    _showConfirmation();
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.check_circle_rounded, color: _teal, size: 44),
          content: const Text(
            'درخواست شما با موفقیت دریافت شد. اطلاعات شما توسط مدیریت CYRUS TOURIST '
            'بررسی خواهد شد و پس از بررسی، جهت ادامه مراحل با شما تماس گرفته خواهد شد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.7),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xff06121d),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('باشه', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      filled: true,
      fillColor: _card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _gold, width: 1.4),
      ),
    );
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
          title: const Text(
            'درخواست ثبت‌نام لیدر',
            style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'اطلاعات اولیه شما فقط برای هماهنگی توسط پشتیبانی CYRUS TOURIST استفاده می‌شود.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('نام و نام خانوادگی'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'وارد کنید' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('شماره تماس'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'وارد کنید' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('شهر محل فعالیت'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'وارد کنید' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _fieldCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('زمینه فعالیت', hint: 'مثلاً: میراث تاریخی، طبیعت‌گردی...'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'وارد کنید' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('توضیحات (اختیاری)'),
                ),
                const SizedBox(height: 18),

                Text(
                  'روش تماس ترجیحی',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _contactMethods.map((m) {
                    final selected = _preferredContact == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => setState(() => _preferredContact = m),
                      selectedColor: _gold,
                      backgroundColor: _card,
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xff06121d) : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xff06121d),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('ارسال درخواست', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
