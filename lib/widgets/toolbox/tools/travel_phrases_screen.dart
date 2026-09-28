import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tool_ui.dart';

class _Lang {
  const _Lang(this.name, this.rtl, this.phrases);

  final String name;
  final bool rtl;

  /// به ترتیب همان معنی‌های فارسی در [_meanings].
  final List<String> phrases;
}

/// عبارات کاربردی سفر (آفلاین) — با لمس، عبارت کپی می‌شود.
class TravelPhrasesScreen extends StatefulWidget {
  const TravelPhrasesScreen({super.key});

  @override
  State<TravelPhrasesScreen> createState() => _TravelPhrasesScreenState();
}

class _TravelPhrasesScreenState extends State<TravelPhrasesScreen> {
  static const List<String> _meanings = [
    'سلام',
    'ممنون',
    'لطفاً',
    'ببخشید',
    'کمک!',
    'این چند است؟',
    'دستشویی کجاست؟',
    'بیمارستان کجاست؟',
    'به پزشک نیاز دارم',
    'متوجه نمی‌شوم',
    'انگلیسی صحبت می‌کنید؟',
    'آب می‌خواهم',
    'صورتحساب لطفاً',
    'نزدیک‌ترین داروخانه کجاست؟',
    'گم شده‌ام',
  ];

  static const List<_Lang> _languages = [
    _Lang('English', false, [
      'Hello',
      'Thank you',
      'Please',
      'Excuse me',
      'Help!',
      'How much is this?',
      'Where is the toilet?',
      'Where is the hospital?',
      'I need a doctor',
      "I don't understand",
      'Do you speak English?',
      'Water, please',
      'The bill, please',
      'Where is the nearest pharmacy?',
      'I am lost',
    ]),
    _Lang('Türkçe', false, [
      'Merhaba',
      'Teşekkür ederim',
      'Lütfen',
      'Affedersiniz',
      'İmdat!',
      'Bu ne kadar?',
      'Tuvalet nerede?',
      'Hastane nerede?',
      'Doktora ihtiyacım var',
      'Anlamıyorum',
      'İngilizce biliyor musunuz?',
      'Su lütfen',
      'Hesap lütfen',
      'En yakın eczane nerede?',
      'Kayboldum',
    ]),
    _Lang('العربية', true, [
      'مرحباً',
      'شكراً',
      'من فضلك',
      'المعذرة',
      'النجدة!',
      'بكم هذا؟',
      'أين الحمّام؟',
      'أين المستشفى؟',
      'أحتاج إلى طبيب',
      'لا أفهم',
      'هل تتكلم الإنجليزية؟',
      'ماء من فضلك',
      'الحساب من فضلك',
      'أين أقرب صيدلية؟',
      'لقد تُهت',
    ]),
    _Lang('Русский', false, [
      'Здравствуйте',
      'Спасибо',
      'Пожалуйста',
      'Извините',
      'Помогите!',
      'Сколько это стоит?',
      'Где туалет?',
      'Где больница?',
      'Мне нужен врач',
      'Я не понимаю',
      'Вы говорите по-английски?',
      'Воды, пожалуйста',
      'Счёт, пожалуйста',
      'Где ближайшая аптека?',
      'Я заблудился',
    ]),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final language = _languages[_selected];

    return ToolScaffold(
      title: 'عبارات کاربردی سفر',
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selected;
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  label: Text(_languages[index].name),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xff071722) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedColor: kToolGold,
                  backgroundColor: kToolCard,
                  side: BorderSide(color: kToolGold.withValues(alpha: 0.4)),
                  onSelected: (_) => setState(() => _selected = index),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: _meanings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final phrase = language.phrases[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phrase));
                    showToolSnack(context, 'کپی شد: $phrase');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: toolCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _meanings[index],
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            phrase,
                            textDirection:
                                language.rtl ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: language.rtl ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: kToolGold,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
