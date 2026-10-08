import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/language/menu_translations.dart';
import '../../core/language/new_texts.dart';
import '../../services/story_service.dart';
import '../linkified_text.dart';

/// نمایش تمام‌صفحهٔ استوری‌ها (مثل واتساپ): نوار پیشرفت، لمس برای بعدی/قبلی، نگه‌داشتن برای توقف.
/// وقتی استوری‌ای حذف شود، با نتیجهٔ true برمی‌گردد تا نوار بازخوانی شود.
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({super.key, required this.groups, required this.initial});

  final List<StoryGroup> groups;
  final int initial;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> with SingleTickerProviderStateMixin {
  late final PageController _pc;
  late final AnimationController _anim;
  late int _g;
  int _s = 0;
  bool _changed = false;

  StoryGroup get _group => widget.groups[_g];

  @override
  void initState() {
    super.initState();
    _g = widget.initial;
    _pc = PageController(initialPage: _g);
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) _next();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _anim.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    final st = _group.stories[_s];
    StoryService.markSeen(st.id);
    if (!_group.mine) StoryService.view(st.id); // هر کاربر فقط یک بازدید
    _anim.forward(from: 0);
  }

  Future<void> _toggleLike(Story st) async {
    final want = !st.liked;
    setState(() {
      st.liked = want;
      st.likes += want ? 1 : -1;
      if (st.likes < 0) st.likes = 0;
    });
    final n = await StoryService.like(st.id, want);
    if (!mounted) return;
    if (n == null) {
      setState(() {
        st.liked = !want;
        st.likes += want ? -1 : 1;
        if (st.likes < 0) st.likes = 0;
      });
    } else {
      setState(() => st.likes = n);
    }
  }

  Future<void> _report(Story st) async {
    _anim.stop();
    final reasons = <String, String>{
      'inappropriate': NT.t('r_inappropriate'),
      'spam': NT.t('r_spam'),
      'ads': NT.t('r_ads'),
      'rules': NT.t('r_rules'),
    };
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xff0e2433),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(NT.t('st_report'), style: const TextStyle(color: Color(0xffffd36a), fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            for (final e in reasons.entries)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white70),
                title: Text(e.value, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(c, e.key),
              ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
    if (picked != null) {
      final msg = await StoryService.report(st.id, picked);
      if (mounted && msg.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    if (mounted) _anim.forward();
  }

  Future<void> _showAudience(Story st) async {
    _anim.stop();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0e2433),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (c) => _AudienceSheet(storyId: st.id),
    );
    if (mounted) _anim.forward();
  }

  Widget _actions(StoryGroup g, Story st) {
    final style = const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, shadows: [Shadow(blurRadius: 6, color: Colors.black54)]);
    if (g.mine) {
      return InkWell(
        onTap: () => _showAudience(st),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text('${st.views ?? 0}', style: style),
            const SizedBox(width: 18),
            const Icon(Icons.favorite_rounded, color: Color(0xffff5c7a), size: 20),
            const SizedBox(width: 6),
            Text('${st.likes}', style: style),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70),
          ]),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        tooltip: NT.t('st_like'),
        onPressed: () => _toggleLike(st),
        icon: Icon(st.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: st.liked ? const Color(0xffff5c7a) : Colors.white, size: 30),
      ),
      Text('${st.likes}', style: style),
      const SizedBox(width: 16),
      Tooltip(
        message: NT.t('st_views'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.visibility_rounded, color: Colors.white, size: 21),
          const SizedBox(width: 5),
          Text('${st.views ?? 0}', style: style),
        ]),
      ),
      const SizedBox(width: 10),
      IconButton(
        tooltip: NT.t('st_report'),
        onPressed: () => _report(st),
        icon: const Icon(Icons.flag_outlined, color: Colors.white70, size: 24),
      ),
    ]);
  }

  void _close() => Navigator.of(context).pop(_changed);

  void _next() {
    if (!mounted) return;
    if (_s < _group.stories.length - 1) {
      setState(() => _s++);
      _start();
    } else if (_g < widget.groups.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _close();
    }
  }

  void _prev() {
    if (_s > 0) {
      setState(() => _s--);
      _start();
    } else if (_g > 0) {
      _pc.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _anim.forward(from: 0);
    }
  }

  Future<void> _delete() async {
    _anim.stop();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color(0xff0e2433),
          title: Text(NT.t('st_delete'), style: const TextStyle(color: Color(0xffffd36a))),
          content: Text(NT.t('st_delete_q'), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(NT.t('st_cancel'))),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(NT.t('st_delete_ok'), style: const TextStyle(color: Colors.redAccent))),
          ],
        ),
      ),
    );
    if (ok != true) {
      _anim.forward();
      return;
    }
    final id = _group.stories[_s].id;
    final done = await StoryService.delete(id);
    if (!mounted) return;
    if (done) {
      _changed = true;
      _group.stories.removeAt(_s);
      if (_group.stories.isEmpty) {
        _close();
        return;
      }
      setState(() => _s = _s.clamp(0, _group.stories.length - 1));
      _start();
    } else {
      _anim.forward();
    }
  }

  Widget _tick(String? b) => b == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Icon(Icons.verified_rounded, size: 18, color: b == 'gold' ? const Color(0xffffc233) : const Color(0xff2a8cff)),
        );

  String _time(DateTime? t) {
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Widget _content(Story st) {
    if (st.isText) {
      final c = kStoryGradients[st.bg.clamp(0, kStoryGradients.length - 1)];
      return Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(c[0]), Color(c[1])])),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: LinkifiedText(
          text: st.text,
          linkColor: Colors.white,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.6),
        ),
      );
    }
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Image.network(
        StoryService.imageUrl(st.id),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xffffd36a))),
        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48)),
      ),
    );
  }

  Widget _page(int gi) {
    final g = widget.groups[gi];
    final si = gi == _g ? _s.clamp(0, g.stories.length - 1) : 0;
    final st = g.stories[si];
    final rtl = MenuLanguage.isRtl;
    return Stack(
      fit: StackFit.expand,
      children: [
        _content(st),
        // لمس: نیمهٔ شروع = قبلی، نیمهٔ پایان = بعدی
        Row(children: [
          Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _prev, onLongPressStart: (_) => _anim.stop(), onLongPressEnd: (_) => _anim.forward())),
          Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _next, onLongPressStart: (_) => _anim.stop(), onLongPressEnd: (_) => _anim.forward())),
        ]),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (c, _) => Row(
                  children: List.generate(g.stories.length, (i) {
                    final v = gi != _g ? 0.0 : (i < si ? 1.0 : (i == si ? _anim.value : 0.0));
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: v, minHeight: 3, backgroundColor: Colors.white24, color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xff102733),
                  backgroundImage: g.hasPhoto ? NetworkImage(StoryService.photoUrl(g.uid)) : null,
                  child: g.hasPhoto ? null : const Icon(Icons.person_rounded, color: Color(0xffffd36a), size: 20),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5, shadows: [Shadow(blurRadius: 6, color: Colors.black54)]))),
                _tick(g.badge),
                const SizedBox(width: 8),
                Text(_time(st.at), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (g.mine)
                  IconButton(tooltip: NT.t('st_delete'), onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.white)),
                IconButton(tooltip: NT.t('st_close'), onPressed: _close, icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ]),
            ]),
          ),
        ),
        if (!st.isText && st.text.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 96),
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xcc000000)])),
              child: LinkifiedText(text: st.text, linkColor: const Color(0xff66d9ff), style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.7)),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(child: Padding(padding: const EdgeInsets.only(bottom: 10), child: _actions(g, st))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: PageView.builder(
            controller: _pc,
            itemCount: widget.groups.length,
            onPageChanged: (i) {
              setState(() {
                _g = i;
                _s = 0;
              });
              _start();
            },
            itemBuilder: (c, i) => _page(i),
          ),
        ),
      ),
    );
  }
}


/// فهرست بازدیدکنندگان و لایک‌کنندگان (فقط برای صاحب استوری)
class _AudienceSheet extends StatefulWidget {
  const _AudienceSheet({required this.storyId});
  final int storyId;

  @override
  State<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends State<_AudienceSheet> {
  bool _likers = false;
  bool _loading = true;
  StoryAudience? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await StoryService.audience(widget.storyId, likers: _likers);
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  String _time(DateTime? t) {
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? const Color(0xffffd36a) : const Color(0xff102733),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: sel ? const Color(0xff06121d) : Colors.white70, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Directionality(
      textDirection: MenuLanguage.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(children: [
              Row(children: [
                _chip('👁 ${NT.t('viewers_title')}${d == null ? '' : ' (${d.views})'}', !_likers, () {
                  if (_likers) {
                    _likers = false;
                    _load();
                  }
                }),
                const SizedBox(width: 10),
                _chip('❤️ ${NT.t('likers_title')}${d == null ? '' : ' (${d.likes})'}', _likers, () {
                  if (!_likers) {
                    _likers = true;
                    _load();
                  }
                }),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xffffd36a)))
                    : (d == null || d.people.isEmpty)
                        ? Center(child: Text(NT.t('no_viewers'), style: const TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            itemCount: d.people.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                            itemBuilder: (c, i) {
                              final p = d.people[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xff102733),
                                  backgroundImage: p.hasPhoto ? NetworkImage(StoryService.photoUrl(p.uid)) : null,
                                  child: p.hasPhoto ? null : const Icon(Icons.person_rounded, color: Color(0xffffd36a)),
                                ),
                                title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                subtitle: Text(_time(p.at), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                trailing: p.liked ? const Icon(Icons.favorite_rounded, color: Color(0xffff5c7a), size: 20) : null,
                              );
                            },
                          ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
