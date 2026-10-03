import 'package:flutter/material.dart';

import 'registration_send.dart';

const Color _bg = Color(0xff06121d);
const Color _card = Color(0xff0b2636);
const Color _gold = Color(0xffffd36a);
const Color _teal = Color(0xff29e0ad);

enum RegFieldType { text, phone, multiline, url }

/// یک فیلد فرم ثبت‌نام پیشرفته
class RegField {
  const RegField({
    required this.key,
    required this.label,
    this.hint,
    this.type = RegFieldType.text,
    this.required = false,
    this.icon,
  });

  final String key;
  final String label;
  final String? hint;
  final RegFieldType type;
  final bool required;
  final IconData? icon;
}

/// گروهی از فیلدها با رنگ ویژهٔ خودش (رنگ‌بندی ترکیبی بخش‌ها)
class RegSection {
  const RegSection({
    required this.title,
    required this.color,
    required this.icon,
    this.fields = const [],
    this.chipKey,
    this.chipLabel,
    this.chipOptions = const [],
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<RegField> fields;

  /// انتخاب چندگزینه‌ای (مثلاً خدمات یا زبان‌ها)
  final String? chipKey;
  final String? chipLabel;
  final List<String> chipOptions;
}

/// فرم ثبت‌نام پیشرفته و قابل‌استفاده برای آژانس و لیدر.
/// - فیلدهای گروه‌بندی‌شده با رنگ‌های مختلف
/// - اعتبارسنجی موبایل ایران
/// - پیش‌نویس خودکار روی حافظه (با بسته‌شدن صفحه از دست نمی‌رود تا زمان ارسال)
/// - ارسال به پشتیبانی از طریق واتساپ/تلگرام/ایتا
class AdvancedRegistrationForm extends StatefulWidget {
  const AdvancedRegistrationForm({
    super.key,
    required this.pageTitle,
    required this.messageTitle,
    required this.intro,
    required this.sections,
    required this.successText,
    this.accent = _gold,
  });

  final String pageTitle;
  final String messageTitle;
  final String intro;
  final List<RegSection> sections;
  final String successText;
  final Color accent;

  @override
  State<AdvancedRegistrationForm> createState() => _AdvancedRegistrationFormState();
}

class _AdvancedRegistrationFormState extends State<AdvancedRegistrationForm> {
  static const List<String> _contactMethods = ['تماس تلفنی', 'تلگرام', 'واتساپ'];

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, Set<String>> _chips = {};
  String _preferredContact = _contactMethods.first;
  bool _agree = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final s in widget.sections) {
      for (final f in s.fields) {
        _ctrls[f.key] = TextEditingController();
      }
      if (s.chipKey != null) _chips[s.chipKey!] = {};
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String key) => _ctrls[key]?.text.trim() ?? '';

  String _buildMessage() {
    final b = StringBuffer('${widget.messageTitle} — CYRUS TOURIST\n');
    for (final s in widget.sections) {
      b.writeln('\n▪ ${s.title}');
      for (final f in s.fields) {
        var v = _v(f.key);
        if (f.type == RegFieldType.phone) v = normalizeDigits(v);
        b.writeln('${f.label}: ${v.isEmpty ? '—' : v}');
      }
      if (s.chipKey != null) {
        final sel = _chips[s.chipKey!] ?? {};
        b.writeln('${s.chipLabel ?? ''}: ${sel.isEmpty ? '—' : sel.join('، ')}');
      }
    }
    b.writeln('\nروش تماس ترجیحی: $_preferredContact');
    return b.toString();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً صحت اطلاعات را تأیید کنید.')),
      );
      return;
    }
    setState(() => _submitting = true);
    bool sent = false;
    try {
      sent = await showSendChooser(context, _buildMessage());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted || !sent) return;
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
          content: Text(
            widget.successText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.7),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('باشه', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(RegField f, Color color) {
    final label = f.required ? '${f.label} *' : f.label;
    return InputDecoration(
      labelText: label,
      hintText: f.hint,
      prefixIcon: f.icon == null ? null : Icon(f.icon, color: color.withValues(alpha: 0.85), size: 20),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      filled: true,
      fillColor: _bg.withValues(alpha: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 1.4)),
    );
  }

  Widget _field(RegField f, Color color) {
    final isPhone = f.type == RegFieldType.phone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctrls[f.key],
        maxLines: f.type == RegFieldType.multiline ? 4 : 1,
        keyboardType: isPhone
            ? TextInputType.number
            : (f.type == RegFieldType.url ? TextInputType.url : TextInputType.text),
        inputFormatters: isPhone ? mobileInputFormatters : null,
        textDirection: (isPhone || f.type == RegFieldType.url) ? TextDirection.ltr : null,
        style: const TextStyle(color: Colors.white),
        decoration: _dec(f, color),
        validator: (v) {
          final t = (v ?? '').trim();
          if (isPhone) {
            if (t.isEmpty && !f.required) return null;
            return validateIranMobile(v);
          }
          if (f.required && t.isEmpty) return 'وارد کنید';
          return null;
        },
      ),
    );
  }

  Widget _section(RegSection s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [s.color.withValues(alpha: 0.14), _card],
        ),
        border: Border.all(color: s.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: s.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(s.icon, color: s.color, size: 19),
              ),
              const SizedBox(width: 10),
              Text(s.title, style: TextStyle(color: s.color, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          for (final f in s.fields) _field(f, s.color),
          if (s.chipKey != null) ...[
            Text(s.chipLabel ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: s.chipOptions.map((o) {
                final sel = _chips[s.chipKey!]!.contains(o);
                return FilterChip(
                  label: Text(o),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    final set = _chips[s.chipKey!]!;
                    v ? set.add(o) : set.remove(o);
                  }),
                  selectedColor: s.color,
                  checkmarkColor: _bg,
                  backgroundColor: _bg.withValues(alpha: 0.5),
                  labelStyle: TextStyle(color: sel ? _bg : Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5),
                  side: BorderSide(color: s.color.withValues(alpha: 0.45)),
                );
              }).toList(),
            ),
          ],
        ],
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
          iconTheme: IconThemeData(color: widget.accent),
          title: Text(widget.pageTitle, style: TextStyle(color: widget.accent, fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(widget.intro, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.7)),
                const SizedBox(height: 16),
                for (final s in widget.sections) _section(s),
                Text('روش تماس ترجیحی', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
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
                      labelStyle: TextStyle(color: selected ? _bg : Colors.white70, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  activeColor: _teal,
                  checkColor: _bg,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'صحت اطلاعات واردشده را تأیید می‌کنم.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [widget.accent, _teal]),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: _bg,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                          : const Icon(Icons.send_rounded),
                      label: const Text('ارسال درخواست', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
}
