import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  // ============================================================
  // اطلاعات رسمی Cyrus Tourist
  // ============================================================

  static const String phoneNumber = '09153448818';
  static const String whatsappNumber = '09153448818';

  static const String telegramUsername = '@Cyrustourist';

  static const String telegramGroupUrl =
      'https://t.me/cyrustourist_app';

  static const String emailAddress =
      'cyrustourist@gmail.com';

  static const String address =
      'استان خراسان رضوی، بلوار پیروزی، رضا شهر';

  static const String websiteUrl =
      'https://cyrustourist-maker.github.io/Cyrustourist/';

  // ============================================================
  // پیام سیستم
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // باز کردن URL
  // ============================================================

  Future<void> _openUrl(
    BuildContext context,
    String url,
  ) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        _showMessage(
          context,
          'امکان باز کردن این بخش وجود ندارد.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          'خطایی در باز کردن این بخش رخ داد.',
        );
      }
    }
  }

  // ============================================================
  // تماس
  // ============================================================

  Future<void> _call(BuildContext context) async {
    await _openUrl(
      context,
      'tel:$phoneNumber',
    );
  }

  // ============================================================
  // واتساپ
  // ============================================================

  Future<void> _openWhatsapp(
    BuildContext context,
  ) async {
    final String number = whatsappNumber
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');

    await _openUrl(
      context,
      'https://wa.me/98${number.substring(1)}',
    );
  }

  // ============================================================
  // تلگرام
  // ============================================================

  Future<void> _openTelegram(
    BuildContext context,
  ) async {
    final String username =
        telegramUsername.replaceAll('@', '');

    await _openUrl(
      context,
      'https://t.me/$username',
    );
  }

  // ============================================================
  // گروه تلگرام
  // ============================================================

  Future<void> _openTelegramGroup(
    BuildContext context,
  ) async {
    await _openUrl(
      context,
      telegramGroupUrl,
    );
  }

  // ============================================================
  // ایمیل
  // ============================================================

  Future<void> _sendEmail(
    BuildContext context,
  ) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: const {
        'subject': 'Cyrus Tourist Support',
      },
    );

    await _openUrl(
      context,
      uri.toString(),
    );
  }

  // ============================================================
  // وب‌سایت
  // ============================================================

  Future<void> _openWebsite(
    BuildContext context,
  ) async {
    await _openUrl(
      context,
      websiteUrl,
    );
  }

  // ============================================================
  // کارت ارتباطی
  // ============================================================

  Widget _contactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: const Color(0xff0b506b).withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xffffd36a).withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xffffd36a)
                        .withValues(alpha: 0.11),
                    border: Border.all(
                      color: const Color(0xffffd36a)
                          .withValues(alpha: 0.70),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xffffd36a),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xffffd36a),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xffffd36a),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // صفحه پشتیبانی
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),

        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'پشتیبانی و تماس',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              15,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [

                // ==================================================
                // آیکن پشتیبانی
                // ==================================================

                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffffd36a)
                          .withValues(alpha: 0.10),
                      border: Border.all(
                        color: const Color(0xffffd36a),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Color(0xffffd36a),
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'همراه شما هستیم',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'ما در Cyrus Tourist آماده‌ایم تا در مسیر سفر و استفاده از خدمات برنامه همراه شما باشیم.\n\n'
                  'برای پرسش، پیشنهاد، گزارش مشکل یا همکاری با ما، می‌توانید از راه‌های ارتباطی زیر استفاده کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 26),

                // ==================================================
                // تماس تلفنی
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.phone,
                  title: 'تماس با ما',
                  subtitle: phoneNumber,
                  onTap: () => _call(context),
                ),

                // ==================================================
                // واتساپ
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.chat,
                  title: 'واتساپ',
                  subtitle:
                      'ارتباط مستقیم با پشتیبانی',
                  onTap: () =>
                      _openWhatsapp(context),
                ),

                // ==================================================
                // تلگرام
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.send,
                  title: 'تلگرام',
                  subtitle: telegramUsername,
                  onTap: () =>
                      _openTelegram(context),
                ),

                // ==================================================
                // گروه تلگرام
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.groups,
                  title: 'گروه تلگرام',
                  subtitle:
                      'عضویت در گروه Cyrus Tourist',
                  onTap: () =>
                      _openTelegramGroup(context),
                ),

                // ==================================================
                // ایمیل
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.email_outlined,
                  title: 'ایمیل',
                  subtitle: emailAddress,
                  onTap: () =>
                      _sendEmail(context),
                ),

                // ==================================================
                // وب‌سایت
                // ==================================================

                _contactCard(
                  context: context,
                  icon: Icons.language,
                  title: 'وب‌سایت رسمی',
                  subtitle:
                      'مشاهده اطلاعات و خدمات بیشتر',
                  onTap: () =>
                      _openWebsite(context),
                ),

                const SizedBox(height: 4),

                // ==================================================
                // چت آنلاین
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xff0b506b)
                        .withValues(alpha: 0.30),
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xffffd36a)
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    children: [

                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xffffd36a)
                              .withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          color: Color(0xffffd36a),
                          size: 31,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'چت آنلاین',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xffffd36a),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'با تیم پشتیبانی Cyrus Tourist به‌صورت آنلاین گفتگو کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),

                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OnlineChatPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                        ),
                        label: const Text(
                          'ورود به چت آنلاین',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xffffd36a),
                          foregroundColor:
                              const Color(0xff071722),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // آدرس
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xff0b506b)
                        .withValues(alpha: 0.22),
                    borderRadius:
                        BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xffffd36a)
                          .withValues(alpha: 0.40),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xffffd36a),
                        size: 30,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            const Text(
                              'آدرس',
                              style: TextStyle(
                                color:
                                    Color(0xffffd36a),
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 7),

                            const Text(
                              address,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // پیشنهاد و گزارش مشکل
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xff0b506b)
                        .withValues(alpha: 0.22),
                    borderRadius:
                        BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xffffd36a)
                          .withValues(alpha: 0.40),
                    ),
                  ),
                  child: Column(
                    children: [

                      const Icon(
                        Icons.feedback_outlined,
                        color: Color(0xffffd36a),
                        size: 34,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'پیشنهاد یا گزارش مشکل دارید؟',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Color(0xffffd36a),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'بازخورد شما به ما کمک می‌کند Cyrus Tourist را بهتر و کاربردی‌تر کنیم.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),

                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        onPressed: () =>
                            _sendEmail(context),
                        icon: const Icon(
                          Icons.send_outlined,
                        ),
                        label: const Text(
                          'ارسال پیام به پشتیبانی',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xffffd36a),
                          side: const BorderSide(
                            color:
                                Color(0xffffd36a),
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Cyrus Tourist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd36a),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'سفر کن، کشف کن، لذت ببر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

// ==================================================================
// صفحه چت آنلاین
// ==================================================================

class OnlineChatPage extends StatefulWidget {
  const OnlineChatPage({super.key});

  @override
  State<OnlineChatPage> createState() =>
      _OnlineChatPageState();
}

class _OnlineChatPageState
    extends State<OnlineChatPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final List<String> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(text);
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),

        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.support_agent,
                color: Color(0xffffd36a),
              ),

              SizedBox(width: 8),

              Text(
                'چت آنلاین',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        body: Column(
          children: [

            // ====================================================
            // وضعیت پشتیبانی
            // ====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              color: const Color(0xff0b506b)
                  .withValues(alpha: 0.35),

              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.circle,
                    color: Colors.greenAccent,
                    size: 10,
                  ),

                  SizedBox(width: 8),

                  Text(
                    'پشتیبانی Cyrus Tourist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // پیام‌ها
            // ====================================================

            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [

                            const Icon(
                              Icons.forum_outlined,
                              color:
                                  Color(0xffffd36a),
                              size: 58,
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            const Text(
                              'به پشتیبانی Cyrus Tourist خوش آمدید.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            const Text(
                              'پیام خود را بنویسید تا پس از اتصال سرویس آنلاین، از همین بخش با پشتیبانی گفتگو کنید.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 13,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(15),
                      itemCount:
                          _messages.length,
                      itemBuilder:
                          (context, index) {
                        return Align(
                          alignment:
                              Alignment.centerRight,
                          child: Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(0xffffd36a)
                                      .withValues(
                                alpha: 0.15,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                              border: Border.all(
                                color:
                                    const Color(
                                  0xffffd36a,
                                ).withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: Text(
                              _messages[index],
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ====================================================
            // ورودی پیام
            // ====================================================

            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  8,
                  10,
                  8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff0b202c),
                ),
                child: Row(
                  children: [

                    Expanded(
                      child: TextField(
                        controller:
                            _messageController,

                        style:
                            const TextStyle(
                          color: Colors.white,
                        ),

                        minLines: 1,
                        maxLines: 4,

                        decoration:
                            InputDecoration(
                          hintText:
                              'پیام خود را بنویسید...',

                          hintStyle:
                              const TextStyle(
                            color:
                                Colors.white54,
                          ),

                          filled: true,

                          fillColor:
                              const Color(
                            0xff071722,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide.none,
                          ),

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xffffd36a),
                        shape:
                            BoxShape.circle,
                      ),

                      child: IconButton(
                        onPressed:
                            _sendMessage,

                        icon: const Icon(
                          Icons.send,
                          color:
                              Color(0xff071722),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
