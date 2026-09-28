import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tool_ui.dart';

class _Note {
  _Note({required this.id, required this.title, required this.body});

  final String id;
  String title;
  String body;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};

  static _Note? fromJson(dynamic json) {
    if (json is! Map) return null;
    return _Note(
      id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
    );
  }
}

/// یادداشت‌های سفر (بلیت، مدارک، برنامه‌ها) — روی گوشی ذخیره می‌شود.
class TripNotesScreen extends StatefulWidget {
  const TripNotesScreen({super.key});

  @override
  State<TripNotesScreen> createState() => _TripNotesScreenState();
}

class _TripNotesScreenState extends State<TripNotesScreen> {
  static const String _kNotes = 'cyrus_trip_notes';

  List<_Note> _notes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kNotes);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _notes = decoded.map(_Note.fromJson).whereType<_Note>().toList();
        }
      }
    } catch (_) {
      _notes = [];
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kNotes,
        jsonEncode(_notes.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _edit({_Note? note}) async {
    final title = TextEditingController(text: note?.title ?? '');
    final body = TextEditingController(text: note?.body ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kToolCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note == null ? 'یادداشت جدید' : 'ویرایش یادداشت',
                  style: const TextStyle(
                    color: kToolGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  style: const TextStyle(color: Colors.white),
                  decoration: toolInputDecoration('عنوان'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white, height: 1.7),
                  decoration: toolInputDecoration('متن یادداشت'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kToolGold,
                      foregroundColor: const Color(0xff071722),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ذخیره',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // کنترلرها عمداً dispose نمی‌شوند: پنجره هنوز در حال بسته شدن است و
    // dispose فوری آن‌ها باعث خطای «استفاده بعد از dispose» می‌شود.
    final newTitle = title.text.trim();
    final newBody = body.text.trim();

    if (saved != true || !mounted) return;
    if (newTitle.isEmpty && newBody.isEmpty) return;

    setState(() {
      if (note == null) {
        _notes.insert(
          0,
          _Note(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            title: newTitle.isEmpty ? 'بدون عنوان' : newTitle,
            body: newBody,
          ),
        );
      } else {
        note.title = newTitle.isEmpty ? 'بدون عنوان' : newTitle;
        note.body = newBody;
      }
    });
    _save();
  }

  Future<void> _delete(_Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: kToolCard,
          title: const Text('حذف یادداشت',
              style: TextStyle(color: kToolGold)),
          content: Text(
            '«${note.title}» حذف شود؟',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _notes.removeWhere((n) => n.id == note.id));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'یادداشت‌های سفر',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: kToolGold,
        foregroundColor: const Color(0xff071722),
        icon: const Icon(Icons.add_rounded),
        label: const Text('یادداشت جدید',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: kToolGold))
          : _notes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'هنوز یادداشتی ندارید.\nشماره بلیت، آدرس اقامتگاه و برنامه‌ی سفر را اینجا بنویسید.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 2),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _edit(note: note),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: toolCardDecoration(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: const TextStyle(
                                      color: kToolGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (note.body.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      note.body,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.7,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _delete(note),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
