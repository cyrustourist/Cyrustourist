import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../groups/group_ui.dart';
import 'hokm_engine.dart' show HCard;
import 'hokm_prefs.dart';
import 'hokm_widgets.dart';

/// تنظیمات «حکم»: نمایش، صدا، پروفایل و قوانین. از منو و از داخل بازی باز می‌شود.
Future<void> showHokmSettings(BuildContext context, {int tab = 0}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HokmSettingsSheet(initialTab: tab),
  );
}

const List<List<String>> kHokmRules = <List<String>>[
  ['هدف بازی', 'چهار نفر در دو تیم بازی می‌کنند و هم‌تیمی‌ها روبه‌روی هم می‌نشینند. تیمی که زودتر به امتیاز هدف برسد برنده است.'],
  ['حاکم و حکم', 'در اولین دست حاکم تصادفی است. حاکم پنج کارت اول را می‌بیند و حکم (خال برنده) را اعلام می‌کند. بعد هشت کارت دیگر پخش می‌شود و حاکم دست اول را شروع می‌کند.'],
  ['تغییر حاکم', 'اگر تیم حاکم دور را ببرد، حاکم همان می‌ماند. اگر ببازد، حاکم به نفر بعدی می‌رسد.'],
  ['قوانین بازی کردن', 'باید هم‌خال با اولین کارت زمین بازی کنید. اگر آن خال را ندارید، هر کارتی مجاز است، از جمله حکم. کارت‌های مجاز بالا می‌آیند و دورشان رنگی می‌شود.'],
  ['برنده‌ی هر دست', 'بالاترین کارت حکم می‌برد. اگر حکمی بازی نشده باشد، بالاترین کارت هم‌خال اولین کارت می‌برد. ترتیب: آس، شاه، بی‌بی، سرباز، ۱۰ تا ۲.'],
  ['برنده‌ی یک دور', 'تیمی که زودتر ۷ دست ببرد، دور را می‌برد. اگر تیم حاکم ببرد ۱ امتیاز می‌گیرد و اگر تیم مقابل ببرد ۲ امتیاز.'],
  ['کوت', 'اگر تیم حاکم ۷ دست ببرد و حریف هیچ دستی نبرده باشد، کوت است و ۲ امتیاز می‌گیرد.'],
  ['حاکم کوت', 'اگر تیم مقابل ۷ دست ببرد و تیم حاکم هیچ دستی نبرده باشد، حاکم کوت است و تیم مقابل ۳ امتیاز می‌گیرد.'],
  ['میان‌دست شریک', 'حاکم می‌تواند انتخاب را به هم‌تیمی بدهد. هم‌تیمی با پنج کارت خودش حکم را تعیین می‌کند و حاکم همان حاکم می‌ماند.'],
  ['نرس', 'بدون حکم. برگ کوچک برنده است: ۲ از همه قوی‌تر است، بعد ۳، ۴ و همین‌طور بالا تا ۱۰، سرباز، بی‌بی، شاه و آخر از همه آس که ضعیف‌ترین است. برنده‌ی هر دست قوی‌ترین برگ هم‌خال اولین برگ زمین است. خال اولین برگ مثل حکم عمل می‌کند: اگر کسی آن خال را نداشت، برگ خال دیگرش نمی‌برد.'],
  ['تک نرس', 'بدون حکم. اول تک (آس) هر چهار خال از همه قوی‌تر است، بعد ۲، ۳، ۴ و همین‌طور بالا (برگ کوچک برنده است) تا شاه که ضعیف‌ترین است. اگر مثلاً ۲ دل بازی شود و کسی دل نداشته باشد، بقیه‌ی دل‌ها مثل حکم حساب می‌شوند و برنده بین همان دل‌هاست. برنده‌ی دور ۳ امتیاز می‌گیرد، چه تیم حاکم و چه حریف.'],
  ['سرس', 'بدون حکم. از آس به پایین مثل حکم: آس قوی‌ترین، بعد شاه، بی‌بی، سرباز، ۱۰ و همین‌طور پایین تا ۲ که ضعیف‌ترین است. خال اولین برگ مثل حکم عمل می‌کند و برگ خال دیگر نمی‌برد. امتیاز مثل بازی عادی است: ۱ یا ۲ امتیاز.'],
  ['۷ یار', 'فقط حاکم می‌تواند انتخابش کند. ۷ پنج برگ اول شریکِ حاکم «برگ یار» است و خال آن ۷ حکم بازی می‌شود. اگر شریک در پنج برگ اول ۷ نداشته باشد، حکم همان خالی می‌شود که حاکم بیشترین برگ را از آن دارد.'],
  ['حکم عادی', 'با انتخاب یکی از چهار خال (دل، خشت، پیک، گشنیز) آن خال حکم می‌شود و هر برگ حکم از همه‌ی برگ‌های خال دیگر بالاتر است.'],
  ['قطع اتصال', 'اگر یک گوشی قطع شود، ربات نوبت او را بازی می‌کند و با وصل شدن دوباره جایش را پس می‌گیرد.'],
];

class HokmSettingsSheet extends StatefulWidget {
  const HokmSettingsSheet({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HokmSettingsSheet> createState() => _HokmSettingsSheetState();
}

class _HokmSettingsSheetState extends State<HokmSettingsSheet> {
  final HokmPrefs p = HokmPrefs.instance;
  late final TextEditingController _name = TextEditingController(text: p.name);
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _upd(VoidCallback f) {
    setState(f);
    p.save();
  }

  Widget _carousel(String title, List<String> names, int value, void Function(int) set, Widget preview) {
    void go(int d) => _upd(() => set((value + d + names.length) % names.length));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              _arrow(Icons.chevron_left_rounded, () => go(-1)),
              const SizedBox(width: 14),
              preview,
              const SizedBox(width: 14),
              _arrow(Icons.chevron_right_rounded, () => go(1)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${names[value]} · ${value + 1} از ${names.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _arrow(IconData i, VoidCallback f) => InkResponse(
        onTap: f,
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff7bea7b), Color(0xff0b8a1a)])),
          child: Icon(i, color: Colors.white, size: 30),
        ),
      );

  Widget _display() => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _carousel('انتخاب زمینه بازی', HokmPrefs.bgNames, p.bg, (v) => p.bg = v, SizedBox(width: 130, height: 150, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: HokmBackground(index: p.bg)))),
          _carousel(
            'طرح روی کارت‌ها',
            HokmPrefs.faceNames,
            p.face,
            (v) => p.face = v,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HokmCardView(card: const HCard(0, 13), w: 44, face: p.face),
                const SizedBox(width: 4),
                HokmCardView(card: const HCard(1, 12), w: 44, face: p.face),
                const SizedBox(width: 4),
                HokmCardView(card: const HCard(2, 10), w: 44, face: p.face),
              ],
            ),
          ),
          _carousel('طرح پشت کارت‌ها', HokmPrefs.backNames, p.back, (v) => p.back = v, HokmBackView(w: 60, back: p.back)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('سرعت بازی', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
                Slider(value: p.speed.toDouble(), min: 10, max: 100, divisions: 18, label: '${p.speed}', onChanged: (v) => _upd(() => p.speed = v.round())),
              ],
            ),
          ),
        ],
      );

  Widget _switch(String t, bool v, void Function(bool) set) => SwitchListTile(
        value: v,
        onChanged: (x) => _upd(() => set(x)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
        activeColor: const Color(0xff17a34a),
      );

  Widget _sound() => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _carousel(
            'مدل صدا',
            HokmPrefs.sndNames,
            p.snd,
            (v) {
              p.snd = v;
              HokmSfx.play('preview');
              Future<void>.delayed(const Duration(milliseconds: 260), () => HokmSfx.play('win'));
            },
            const Icon(Icons.music_note_rounded, size: 60, color: Color(0xff0d2a55)),
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                HokmSfx.play('play');
                Future<void>.delayed(const Duration(milliseconds: 300), () => HokmSfx.play('deal'));
                Future<void>.delayed(const Duration(milliseconds: 900), () => HokmSfx.play('win'));
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('پخش نمونه'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('بلندی صدا', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
                Slider(
                  value: p.vol.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${p.vol}',
                  onChanged: (v) => _upd(() => p.vol = v.round()),
                  onChangeEnd: (_) => HokmSfx.play('play'),
                ),
              ],
            ),
          ),
          _switch('حالت سکوت (فقط روی همین گوشی)', p.mute, (x) => p.mute = x),
          _switch('لرزش در نوبت شما', p.vib, (x) => p.vib = x),
        ],
      );

  Future<void> _pickPhoto(ImageSource s) async {
    try {
      final f = await _picker.pickImage(source: s, maxWidth: 80, maxHeight: 80, imageQuality: 55);
      if (f == null) return;
      final b = await f.readAsBytes();
      _upd(() => p.avatar = base64Encode(b));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('این عکس باز نشد')));
    }
  }

  Widget _profile() => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('نام شما', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            maxLength: 16,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), counterText: ''),
            onChanged: (v) {
              p.name = v.trim().isEmpty ? 'کوروش' : v.trim();
              p.save();
            },
          ),
          const SizedBox(height: 14),
          const Center(child: Text('عکس کاربر', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87))),
          const SizedBox(height: 8),
          Center(child: HokmAvatar(avatar: p.avatar, size: 74)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < HokmPrefs.avatars.length; i++)
                GestureDetector(
                  onTap: () => _upd(() => p.avatar = '$i'),
                  child: HokmAvatar(avatar: '$i', size: 54, border: p.avatar == '$i' ? const Color(0xffffe24a) : Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library_rounded), label: const Text('از گالری'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.photo_camera_rounded), label: const Text('دوربین'))),
            ],
          ),
          const SizedBox(height: 6),
          const Text('عکس کوچک می‌شود تا در بازی چندگوشی سبک بماند.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  Widget _rules() => ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('امتیاز پایان بازی', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final n in <int>[5, 7, 11])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Center(child: Text('$n')),
                            selected: p.target == n,
                            onSelected: (_) => _upd(() => p.target = n),
                          ),
                        ),
                      ),
                  ],
                ),
                const Text('در بازی چهارگوشی فقط میزبان تعیین می‌کند.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          for (final r in kHokmRules)
            Card(
              color: Colors.white70,
              child: ExpansionTile(
                title: Text(r[0], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                children: [Text(r[1], style: const TextStyle(height: 1.9, color: Colors.black87))],
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 4,
        initialIndex: widget.initialTab.clamp(0, 3).toInt(),
        child: FractionallySizedBox(
          heightFactor: .92,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Material(
              color: const Color(0xff83a9c7),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xff0a8cff),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        const Expanded(child: Text('تنظیمات بازی', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xff04152b)))),
                        InkResponse(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffc01a10)),
                            child: const Icon(Icons.close_rounded, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xff0d2a55),
                    child: const TabBar(
                      indicatorColor: gGold,
                      labelColor: Colors.white,
                      unselectedLabelColor: Color(0xff9db6df),
                      tabs: [Tab(text: 'نمایش'), Tab(text: 'صدا'), Tab(text: 'پروفایل'), Tab(text: 'قوانین')],
                    ),
                  ),
                  Expanded(child: TabBarView(children: [_display(), _sound(), _profile(), _rules()])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
