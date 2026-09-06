import 'package:flutter/material.dart';

/// ===============================================================
/// Cyrus Tourist
/// کلید ۷ — جعبه ابزار بسیار هوشمند
///
/// نسخه مستقل اولیه
/// ---------------------------------------------------------------
/// این فایل فعلاً به main.dart یا API خارجی متصل نیست.
/// ساختار قابلیت‌ها برای اتصال نهایی آماده شده است.
/// ===============================================================

class CyrusSmartToolbox extends StatelessWidget {
  const CyrusSmartToolbox({
    super.key,
    this.languageCode = 'fa',
  });

  final String languageCode;

  bool get _isRtl =>
      languageCode == 'fa' || languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Color(0xffffd76a),
          ),
          title: Text(
            _tr('جعبه ابزار بسیار هوشمند'),
            style: const TextStyle(
              color: Color(0xffffd76a),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 22),

              _buildSection(
                title: _tr('هوشمند سفر'),
                icon: Icons.auto_awesome,
                children: _smartItems(),
              ),

              const SizedBox(height: 18),

              _buildSection(
                title: _tr('اضطراری و ضروری'),
                icon: Icons.health_and_safety_rounded,
                children: _essentialItems(),
              ),

              const SizedBox(height: 18),

              _buildSection(
                title: _tr('ابزارهای سفر'),
                icon: Icons.build_rounded,
                children: _travelToolItems(),
              ),

              const SizedBox(height: 18),

              _buildSection(
                title: _tr('ابزارهای آنلاین'),
                icon: Icons.public_rounded,
                children: _onlineItems(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // Header
  // =============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff173747),
            Color(0xff0b202c),
          ],
        ),
        border: Border.all(
          color: const Color(0xffffd76a).withOpacity(0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffffc94d).withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xffffefb0),
                  Color(0xffd99b21),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffffc94d).withOpacity(0.42),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Color(0xff16242c),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _tr('همراه هوشمند سفر سایروس'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              'ابزارهای هوشمند و کاربردی برای یک سفر بهتر',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // Sections
  // =============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<CyrusToolItem> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffffd76a).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xffffd76a).withOpacity(0.40),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xffffd76a),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CyrusSmartToolButton(
              item: item,
              onTap: () => _toolTapped(item),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // 1. Smart Travel
  // =============================================================

  List<CyrusToolItem> _smartItems() {
    return [
      CyrusToolItem(
        id: 'ai_assistant',
        icon: Icons.smart_toy_rounded,
        title: _tr('دستیار هوشمند سفر'),
        subtitle: _tr(
          'گفتگو با سایروس و دریافت راهنمایی سفر',
        ),
        iconColor: const Color(0xffffd76a),
      ),
      CyrusToolItem(
        id: 'personal_trip',
        icon: Icons.favorite_rounded,
        title: _tr('سفر شخصی من'),
        subtitle: _tr(
          'پیشنهاد مقصد بر اساس سلیقه، بودجه و شرایط شما',
        ),
        iconColor: const Color(0xffff7f9f),
      ),
      CyrusToolItem(
        id: 'trip_planner',
        icon: Icons.route_rounded,
        title: _tr('برنامه‌ریز هوشمند سفر'),
        subtitle: _tr(
          'ساخت برنامه سفر روزانه بر اساس زمان و مقصد',
        ),
        iconColor: const Color(0xff72d6ff),
      ),
      CyrusToolItem(
        id: 'nearby',
        icon: Icons.location_on_rounded,
        title: _tr('اطراف من'),
        subtitle: _tr(
          'پیدا کردن مکان‌ها و خدمات مناسب در اطراف شما',
        ),
        iconColor: const Color(0xff75e0a0),
      ),
      CyrusToolItem(
        id: 'instant_suggestion',
        icon: Icons.bolt_rounded,
        title: _tr('پیشنهاد لحظه‌ای'),
        subtitle: _tr(
          'پیشنهاد مناسب بر اساس زمان، مکان و شرایط',
        ),
        iconColor: const Color(0xffffc857),
      ),
      CyrusToolItem(
        id: 'travel_budget',
        icon: Icons.account_balance_wallet_rounded,
        title: _tr('مدیریت هزینه سفر'),
        subtitle: _tr(
          'مدیریت و برآورد هزینه‌های سفر',
        ),
        iconColor: const Color(0xff72e6b0),
      ),
      CyrusToolItem(
        id: 'travel_type',
        icon: Icons.groups_rounded,
        title: _tr('نوع سفر'),
        subtitle: _tr(
          'خانوادگی، دوستانه، انفرادی، رمانتیک و ماجراجویی',
        ),
        iconColor: const Color(0xffc9a7ff),
      ),
    ];
  }

  // =============================================================
  // 2. Essential
  // =============================================================

  List<CyrusToolItem> _essentialItems() {
    return [
      CyrusToolItem(
        id: 'emergency',
        icon: Icons.sos_rounded,
        title: _tr('کمک فوری در سفر'),
        subtitle: _tr(
          'دسترسی سریع به خدمات ضروری و امدادی',
        ),
        iconColor: const Color(0xffff6262),
      ),
      CyrusToolItem(
        id: 'travel_mode',
        icon: Icons.luggage_rounded,
        title: _tr('حالت سفر'),
        subtitle: _tr(
          'فعال‌سازی ابزارها و اطلاعات مورد نیاز سفر',
        ),
        iconColor: const Color(0xff78b8ff),
      ),
      CyrusToolItem(
        id: 'flashlight',
        icon: Icons.flashlight_on_rounded,
        title: _tr('چراغ قوه'),
        subtitle: _tr(
          'استفاده سریع از چراغ قوه تلفن همراه',
        ),
        iconColor: const Color(0xffffe08a),
      ),
      CyrusToolItem(
        id: 'compass',
        icon: Icons.explore_rounded,
        title: _tr('قطب نما'),
        subtitle: _tr(
          'نمایش جهت‌های اصلی و جهت حرکت',
        ),
        iconColor: const Color(0xff72d6ff),
      ),
    ];
  }

  // =============================================================
  // 3. Travel Tools
  // =============================================================

  List<CyrusToolItem> _travelToolItems() {
    return [
      CyrusToolItem(
        id: 'unit_converter',
        icon: Icons.straighten_rounded,
        title: _tr('تبدیل واحدها'),
        subtitle: _tr(
          'تبدیل مسافت، وزن، دما و واحدهای کاربردی',
        ),
        iconColor: const Color(0xffb9a7ff),
      ),
      CyrusToolItem(
        id: 'trip_calculator',
        icon: Icons.calculate_rounded,
        title: _tr('محاسبه‌گر سفر'),
        subtitle: _tr(
          'محاسبه زمان، مسافت و هزینه تقریبی سفر',
        ),
        iconColor: const Color(0xff73e0a0),
      ),
      CyrusToolItem(
        id: 'essential_services',
        icon: Icons.local_hospital_rounded,
        title: _tr('خدمات ضروری نزدیک من'),
        subtitle: _tr(
          'بیمارستان، داروخانه، پلیس، ATM و خدمات ضروری',
        ),
        iconColor: const Color(0xffff8585),
      ),
      CyrusToolItem(
        id: 'battery_saver',
        icon: Icons.battery_saver_rounded,
        title: _tr('حالت کم‌مصرف سفر'),
        subtitle: _tr(
          'کاهش مصرف باتری هنگام سفر',
        ),
        iconColor: const Color(0xffffc857),
      ),
      CyrusToolItem(
        id: 'offline_trip',
        icon: Icons.cloud_off_rounded,
        title: _tr('سفر آفلاین'),
        subtitle: _tr(
          'دسترسی به اطلاعات ذخیره‌شده در نبود اینترنت',
        ),
        iconColor: const Color(0xff91c7ff),
      ),
    ];
  }

  // =============================================================
  // 4. Online Tools
  // =============================================================

  List<CyrusToolItem> _onlineItems() {
    return [
      CyrusToolItem(
        id: 'currency',
        icon: Icons.currency_exchange_rounded,
        title: _tr('تبدیل ارز آنلاین'),
        subtitle: _tr(
          'دریافت نرخ آنلاین و تبدیل ارزهای مختلف',
        ),
        iconColor: const Color(0xffffd76a),
      ),
      CyrusToolItem(
        id: 'weather',
        icon: Icons.cloud_rounded,
        title: _tr('آب‌وهوای هوشمند مقصد'),
        subtitle: _tr(
          'مکان من، جستجوی شهر یا جستجوی مکان با جدول دقیق',
        ),
        iconColor: const Color(0xff72d6ff),
      ),
      CyrusToolItem(
        id: 'world_clock',
        icon: Icons.public_rounded,
        title: _tr('ساعت جهانی'),
        subtitle: _tr(
          'نمایش ساعت شهرهای مختلف جهان',
        ),
        iconColor: const Color(0xffc9a7ff),
      ),
      CyrusToolItem(
        id: 'local_time',
        icon: Icons.access_time_rounded,
        title: _tr('زمان محلی مقصد'),
        subtitle: _tr(
          'نمایش زمان محلی و اختلاف ساعت مقصد',
        ),
        iconColor: const Color(0xff75e0a0),
      ),
      CyrusToolItem(
        id: 'connection',
        icon: Icons.network_check_rounded,
        title: _tr('وضعیت اتصال'),
        subtitle: _tr(
          'بررسی وضعیت اینترنت برای قابلیت‌های آنلاین',
        ),
        iconColor: const Color(0xffffc857),
      ),
    ];
  }

  // =============================================================
  // Tool action
  // =============================================================

  void _toolTapped(CyrusToolItem item) {
    // -----------------------------------------------------------
    // اتصال واقعی هر ابزار در مرحله بعد انجام می‌شود.
    //
    // نکته:
    // weather ساختار اختصاصی خود را خواهد داشت:
    // - موقعیت خودکار
    // - جستجوی شهر
    // - جستجوی مکان
    // - وضعیت فعلی
    // - جدول ساعتی
    // - پیش‌بینی چندروزه
    // - دمای احساس‌شده
    // - رطوبت
    // - باد
    // - بارش
    // - UV
    // - طلوع و غروب
    // - پیشنهاد بهترین زمان گردش
    // -----------------------------------------------------------
  }

  // =============================================================
  // Translation
  // =============================================================

  String _tr(String text) {
    const Map<String, Map<String, String>> translations = {
      'جعبه ابزار بسیار هوشمند': {
        'fa': 'جعبه ابزار بسیار هوشمند',
        'en': 'Very Smart Travel Toolbox',
        'ar': 'صندوق أدوات السفر الذكي',
        'tr': 'Çok Akıllı Seyahat Araç Kutusu',
        'ru': 'Очень умный туристический набор',
        'fr': 'Boîte à outils de voyage intelligente',
        'de': 'Sehr intelligente Reise-Werkzeuge',
        'es': 'Caja de herramientas de viaje inteligente',
        'zh': '智能旅行工具箱',
        'it': 'Kit di strumenti di viaggio molto intelligente',
      },
      'همراه هوشمند سفر سایروس': {
        'fa': 'همراه هوشمند سفر سایروس',
        'en': 'Cyrus Smart Travel Companion',
        'ar': 'مرافق سايروس الذكي للسفر',
        'tr': 'Cyrus Akıllı Seyahat Asistanı',
        'ru': 'Умный помощник Cyrus для путешествий',
        'fr': 'Assistant de voyage intelligent Cyrus',
        'de': 'Cyrus intelligenter Reisebegleiter',
        'es': 'Asistente de viaje inteligente Cyrus',
        'zh': 'Cyrus 智能旅行助手',
        'it': 'Assistente di viaggio intelligente Cyrus',
      },
      'ابزارهای هوشمند و کاربردی برای یک سفر بهتر': {
        'fa': 'ابزارهای هوشمند و کاربردی برای یک سفر بهتر',
        'en': 'Smart and useful tools for a better trip',
        'ar': 'أدوات ذكية ومفيدة لرحلة أفضل',
        'tr': 'Daha iyi bir seyahat için akıllı ve kullanışlı araçlar',
        'ru': 'Умные и полезные инструменты для путешествия',
        'fr': 'Des outils intelligents et utiles pour un meilleur voyage',
        'de': 'Intelligente und nützliche Werkzeuge für eine bessere Reise',
        'es': 'Herramientas inteligentes y útiles para un mejor viaje',
        'zh': '让旅行更美好的智能实用工具',
        'it': 'Strumenti intelligenti e utili per un viaggio migliore',
      },
      'هوشمند سفر': {
        'fa': 'هوشمند سفر',
        'en': 'Smart Travel',
        'ar': 'السفر الذكي',
        'tr': 'Akıllı Seyahat',
        'ru': 'Умное путешествие',
        'fr': 'Voyage intelligent',
        'de': 'Intelligentes Reisen',
        'es': 'Viaje inteligente',
        'zh': '智能旅行',
        'it': 'Viaggio intelligente',
      },
      'اضطراری و ضروری': {
        'fa': 'اضطراری و ضروری',
        'en': 'Emergency & Essential',
        'ar': 'الطوارئ والضروريات',
        'tr': 'Acil ve Gerekli',
        'ru': 'Экстренное и необходимое',
        'fr': 'Urgence et essentiel',
        'de': 'Notfall und wichtig',
        'es': 'Emergencias y esenciales',
        'zh': '紧急与必备',
        'it': 'Emergenza ed essenziali',
      },
      'ابزارهای سفر': {
        'fa': 'ابزارهای سفر',
        'en': 'Travel Tools',
        'ar': 'أدوات السفر',
        'tr': 'Seyahat Araçları',
        'ru': 'Инструменты для путешествий',
        'fr': 'Outils de voyage',
        'de': 'Reisewerkzeuge',
        'es': 'Herramientas de viaje',
        'zh': '旅行工具',
        'it': 'Strumenti di viaggio',
      },
      'ابزارهای آنلاین': {
        'fa': 'ابزارهای آنلاین',
        'en': 'Online Tools',
        'ar': 'الأدوات عبر الإنترنت',
        'tr': 'Çevrimiçi Araçlar',
        'ru': 'Онлайн-инструменты',
        'fr': 'Outils en ligne',
        'de': 'Online-Werkzeuge',
        'es': 'Herramientas en línea',
        'zh': '在线工具',
        'it': 'Strumenti online',
      },

      // ---------------------------------------------------------
      // Smart
      // ---------------------------------------------------------

      'دستیار هوشمند سفر': {
        'fa': 'دستیار هوشمند سفر',
        'en': 'Smart Travel Assistant',
        'ar': 'مساعد السفر الذكي',
        'tr': 'Akıllı Seyahat Asistanı',
        'ru': 'Умный помощник путешествий',
        'fr': 'Assistant de voyage intelligent',
        'de': 'Intelligenter Reiseassistent',
        'es': 'Asistente de viaje inteligente',
        'zh': '智能旅行助手',
        'it': 'Assistente di viaggio intelligente',
      },
      'گفتگو با سایروس و دریافت راهنمایی سفر': {
        'fa': 'گفتگو با سایروس و دریافت راهنمایی سفر',
        'en': 'Talk with Cyrus and get travel guidance',
        'ar': 'تحدث مع سايروس واحصل على إرشادات السفر',
        'tr': 'Cyrus ile konuşun ve seyahat rehberliği alın',
        'ru': 'Общайтесь с Cyrus и получайте советы',
        'fr': 'Discutez avec Cyrus et obtenez des conseils',
        'de': 'Sprechen Sie mit Cyrus und erhalten Sie Reisetipps',
        'es': 'Habla con Cyrus y recibe consejos de viaje',
        'zh': '与 Cyrus 对话并获取旅行建议',
        'it': 'Parla con Cyrus e ricevi consigli di viaggio',
      },
      'سفر شخصی من': {
        'fa': 'سفر شخصی من',
        'en': 'My Personalized Trip',
        'ar': 'رحلتي الشخصية',
        'tr': 'Kişisel Seyahatim',
        'ru': 'Моя персональная поездка',
        'fr': 'Mon voyage personnalisé',
        'de': 'Meine persönliche Reise',
        'es': 'Mi viaje personalizado',
        'zh': '我的个性化旅行',
        'it': 'Il mio viaggio personalizzato',
      },
      'پیشنهاد مقصد بر اساس سلیقه، بودجه و شرایط شما': {
        'fa': 'پیشنهاد مقصد بر اساس سلیقه، بودجه و شرایط شما',
        'en': 'Destinations based on your preferences, budget and situation',
        'ar': 'اقتراح الوجهات حسب تفضيلاتك وميزانيتك وظروفك',
        'tr': 'Tercihlerinize, bütçenize ve koşullarınıza göre destinasyonlar',
        'ru': 'Направления с учетом ваших предпочтений и бюджета',
        'fr': 'Destinations selon vos préférences, budget et situation',
        'de': 'Ziele nach Ihren Vorlieben, Ihrem Budget und Ihrer Situation',
        'es': 'Destinos según tus preferencias, presupuesto y situación',
        'zh': '根据您的偏好、预算和情况推荐目的地',
        'it': 'Destinazioni in base a preferenze, budget e situazione',
      },
      'برنامه‌ریز هوشمند سفر': {
        'fa': 'برنامه‌ریز هوشمند سفر',
        'en': 'Smart Trip Planner',
        'ar': 'مخطط الرحلات الذكي',
        'tr': 'Akıllı Seyahat Planlayıcı',
        'ru': 'Умный планировщик путешествий',
        'fr': 'Planificateur de voyage intelligent',
        'de': 'Intelligenter Reiseplaner',
        'es': 'Planificador de viajes inteligente',
        'zh': '智能旅行规划器',
        'it': 'Pianificatore di viaggio intelligente',
      },
      'ساخت برنامه سفر روزانه بر اساس زمان و مقصد': {
        'fa': 'ساخت برنامه سفر روزانه بر اساس زمان و مقصد',
        'en': 'Create a daily itinerary based on time and destination',
        'ar': 'إنشاء برنامج يومي حسب الوقت والوجهة',
        'tr': 'Zaman ve destinasyona göre günlük seyahat planı',
        'ru': 'Создание ежедневного маршрута по времени и месту',
        'fr': 'Créer un itinéraire quotidien selon le temps et la destination',
        'de': 'Tagesplan nach Zeit und Ziel erstellen',
        'es': 'Crear un itinerario diario según tiempo y destino',
        'zh': '根据时间和目的地创建每日行程',
        'it': 'Crea un itinerario giornaliero in base a tempo e destinazione',
      },
      'اطراف من': {
        'fa': 'اطراف من',
        'en': 'Around Me',
        'ar': 'من حولي',
        'tr': 'Etrafımda',
        'ru': 'Рядом со мной',
        'fr': 'Autour de moi',
        'de': 'In meiner Nähe',
        'es': 'Cerca de mí',
        'zh': '我附近',
        'it': 'Nei dintorni',
      },
      'پیدا کردن مکان‌ها و خدمات مناسب در اطراف شما': {
        'fa': 'پیدا کردن مکان‌ها و خدمات مناسب در اطراف شما',
        'en': 'Find suitable places and services around you',
        'ar': 'العثور على الأماكن والخدمات المناسبة من حولك',
        'tr': 'Çevrenizdeki uygun yerleri ve hizmetleri bulun',
        'ru': 'Поиск подходящих мест и услуг рядом с вами',
        'fr': 'Trouver des lieux et services adaptés autour de vous',
        'de': 'Passende Orte und Dienste in Ihrer Nähe finden',
        'es': 'Encuentra lugares y servicios adecuados cerca de ti',
        'zh': '查找您附近合适的地点和服务',
        'it': 'Trova luoghi e servizi adatti nelle vicinanze',
      },
      'پیشنهاد لحظه‌ای': {
        'fa': 'پیشنهاد لحظه‌ای',
        'en': 'Instant Suggestions',
        'ar': 'اقتراحات فورية',
        'tr': 'Anlık Öneriler',
        'ru': 'Мгновенные рекомендации',
        'fr': 'Suggestions instantanées',
        'de': 'Sofortige Empfehlungen',
        'es': 'Sugerencias instantáneas',
        'zh': '即时推荐',
        'it': 'Suggerimenti in tempo reale',
      },
      'پیشنهاد مناسب بر اساس زمان، مکان و شرایط': {
        'fa': 'پیشنهاد مناسب بر اساس زمان، مکان و شرایط',
        'en': 'Suggestions based on time, location and conditions',
        'ar': 'اقتراحات حسب الوقت والموقع والظروف',
        'tr': 'Zaman, konum ve koşullara göre öneriler',
        'ru': 'Рекомендации с учетом времени, места и условий',
        'fr': 'Suggestions selon l’heure, le lieu et les conditions',
        'de': 'Empfehlungen nach Zeit, Ort und Bedingungen',
        'es': 'Sugerencias según hora, ubicación y condiciones',
        'zh': '根据时间、地点和条件提供推荐',
        'it': 'Suggerimenti in base a orario, luogo e condizioni',
      },
      'مدیریت هزینه سفر': {
        'fa': 'مدیریت هزینه سفر',
        'en': 'Travel Expense Management',
        'ar': 'إدارة نفقات السفر',
        'tr': 'Seyahat Gider Yönetimi',
        'ru': 'Управление расходами поездки',
        'fr': 'Gestion des dépenses de voyage',
        'de': 'Reisekostenverwaltung',
        'es': 'Gestión de gastos de viaje',
        'zh': '旅行费用管理',
        'it': 'Gestione spese di viaggio',
      },
      'مدیریت و برآورد هزینه‌های سفر': {
        'fa': 'مدیریت و برآورد هزینه‌های سفر',
        'en': 'Manage and estimate travel expenses',
        'ar': 'إدارة وتقدير نفقات السفر',
        'tr': 'Seyahat giderlerini yönetin ve tahmin edin',
        'ru': 'Управление и расчет расходов на поездку',
        'fr': 'Gérer et estimer les dépenses de voyage',
        'de': 'Reisekosten verwalten und schätzen',
        'es': 'Gestionar y estimar gastos de viaje',
        'zh': '管理和估算旅行费用',
        'it': 'Gestisci e stima le spese di viaggio',
      },
      'نوع سفر': {
        'fa': 'نوع سفر',
        'en': 'Travel Type',
        'ar': 'نوع السفر',
        'tr': 'Seyahat Türü',
        'ru': 'Тип поездки',
        'fr': 'Type de voyage',
        'de': 'Reiseart',
        'es': 'Tipo de viaje',
        'zh': '旅行类型',
        'it': 'Tipo di viaggio',
      },
      'خانوادگی، دوستانه، انفرادی، رمانتیک و ماجراجویی': {
        'fa': 'خانوادگی، دوستانه، انفرادی، رمانتیک و ماجراجویی',
        'en': 'Family, friends, solo, romantic and adventure',
        'ar': 'عائلية، أصدقاء، فردية، رومانسية ومغامرات',
        'tr': 'Aile, arkadaş, solo, romantik ve macera',
        'ru': 'Семейная, дружеская, индивидуальная, романтическая и приключенческая',
        'fr': 'Familial, amis, solo, romantique et aventure',
        'de': 'Familie, Freunde, allein, romantisch und Abenteuer',
        'es': 'Familiar, amigos, individual, romántico y aventura',
        'zh': '家庭、朋友、独自、浪漫和冒险',
        'it': 'Famiglia, amici, da solo, romantico e avventura',
      },

      // ---------------------------------------------------------
      // Essential
      // ---------------------------------------------------------

      'کمک فوری در سفر': {
        'fa': 'کمک فوری در سفر',
        'en': 'Travel Emergency Help',
        'ar': 'المساعدة الطارئة أثناء السفر',
        'tr': 'Seyahat Acil Yardım',
        'ru': 'Экстренная помощь в путешествии',
        'fr': 'Aide d’urgence en voyage',
        'de': 'Notfallhilfe auf Reisen',
        'es': 'Ayuda de emergencia en viaje',
        'zh': '旅行紧急帮助',
        'it': 'Aiuto d'emergenza in viaggio',
      },
      'دسترسی سریع به خدمات ضروری و امدادی': {
        'fa': 'دسترسی سریع به خدمات ضروری و امدادی',
        'en': 'Quick access to essential and emergency services',
        'ar': 'وصول سريع إلى الخدمات الضرورية والطوارئ',
        'tr': 'Temel ve acil hizmetlere hızlı erişim',
        'ru': 'Быстрый доступ к экстренным службам',
        'fr': 'Accès rapide aux services essentiels et d’urgence',
        'de': 'Schneller Zugang zu Notfall- und wichtigen Diensten',
        'es': 'Acceso rápido a servicios esenciales y de emergencia',
        'zh': '快速访问必要和紧急服务',
        'it': 'Accesso rapido ai servizi essenziali e d'emergenza',
      },
      'حالت سفر': {
        'fa': 'حالت سفر',
        'en': 'Travel Mode',
        'ar': 'وضع السفر',
        'tr': 'Seyahat Modu',
        'ru': 'Режим путешествия',
        'fr': 'Mode voyage',
        'de': 'Reisemodus',
        'es': 'Modo viaje',
        'zh': '旅行模式',
        'it': 'Modalità viaggio',
      },
      'فعال‌سازی ابزارها و اطلاعات مورد نیاز سفر': {
        'fa': 'فعال‌سازی ابزارها و اطلاعات مورد نیاز سفر',
        'en': 'Activate the tools and information needed while traveling',
        'ar': 'تفعيل الأدوات والمعلومات المطلوبة أثناء السفر',
        'tr': 'Seyahat sırasında gereken araçları ve bilgileri etkinleştirin',
        'ru': 'Включение необходимых инструментов и информации',
        'fr': 'Activer les outils et informations nécessaires pendant le voyage',
        'de': 'Benötigte Werkzeuge und Informationen aktivieren',
        'es': 'Activar las herramientas e información necesarias durante el viaje',
        'zh': '启用旅行所需的工具和信息',
        'it': 'Attiva strumenti e informazioni necessari durante il viaggio',
      },
      'چراغ قوه': {
        'fa': 'چراغ قوه',
        'en': 'Flashlight',
        'ar': 'مصباح يدوي',
        'tr': 'El Feneri',
        'ru': 'Фонарик',
        'fr': 'Lampe torche',
        'de': 'Taschenlampe',
        'es': 'Linterna',
        'zh': '手电筒',
        'it': 'Torcia',
      },
      'استفاده سریع از چراغ قوه تلفن همراه': {
        'fa': 'استفاده سریع از چراغ قوه تلفن همراه',
        'en': 'Quickly use your phone flashlight',
        'ar': 'استخدام مصباح الهاتف بسرعة',
        'tr': 'Telefonunuzun fenerini hızlıca kullanın',
        'ru': 'Быстрый доступ к фонарику телефона',
        'fr': 'Utiliser rapidement la lampe du téléphone',
        'de': 'Taschenlampe des Telefons schnell verwenden',
        'es': 'Usa rápidamente la linterna del teléfono',
        'zh': '快速使用手机手电筒',
        'it': 'Usa rapidamente la torcia del telefono',
      },
      'قطب نما': {
        'fa': 'قطب نما',
        'en': 'Compass',
        'ar': 'بوصلة',
        'tr': 'Pusula',
        'ru': 'Компас',
        'fr': 'Boussole',
        'de': 'Kompass',
        'es': 'Brújula',
        'zh': '指南针',
        'it': 'Bussola',
      },
      'نمایش جهت‌های اصلی و جهت حرکت': {
        'fa': 'نمایش جهت‌های اصلی و جهت حرکت',
        'en': 'Show cardinal directions and heading',
        'ar': 'عرض الاتجاهات الأساسية واتجاه الحركة',
        'tr': 'Ana yönleri ve hareket yönünü gösterir',
        'ru': 'Показывает стороны света и направление движения',
        'fr': 'Afficher les points cardinaux et la direction',
        'de': 'Himmelsrichtungen und Bewegungsrichtung anzeigen',
        'es': 'Muestra los puntos cardinales y la dirección',
        'zh': '显示主要方向和移动方向',
        'it': 'Mostra i punti cardinali e la direzione',
      },

      // ---------------------------------------------------------
      // Travel tools
      // ---------------------------------------------------------

      'تبدیل واحدها': {
        'fa': 'تبدیل واحدها',
        'en': 'Unit Converter',
        'ar': 'تحويل الوحدات',
        'tr': 'Birim Dönüştürücü',
        'ru': 'Конвертер единиц',
        'fr': 'Convertisseur d’unités',
        'de': 'Einheitenumrechner',
        'es': 'Conversor de unidades',
        'zh': '单位转换器',
        'it': 'Convertitore di unità',
      },
      'تبدیل مسافت، وزن، دما و واحدهای کاربردی': {
        'fa': 'تبدیل مسافت، وزن، دما و واحدهای کاربردی',
        'en': 'Convert distance, weight, temperature and useful units',
        'ar': 'تحويل المسافة والوزن والحرارة والوحدات المفيدة',
        'tr': 'Mesafe, ağırlık, sıcaklık ve diğer birimleri dönüştürün',
        'ru': 'Конвертация расстояния, веса, температуры и других единиц',
        'fr': 'Convertir distance, poids, température et autres unités',
        'de': 'Entfernung, Gewicht, Temperatur und weitere Einheiten umrechnen',
        'es': 'Convierte distancia, peso, temperatura y otras unidades',
        'zh': '转换距离、重量、温度等常用单位',
        'it': 'Converti distanza, peso, temperatura e altre unità utili',
      },
      'محاسبه‌گر سفر': {
        'fa': 'محاسبه‌گر سفر',
        'en': 'Trip Calculator',
        'ar': 'حاسبة السفر',
        'tr': 'Seyahat Hesaplayıcı',
        'ru': 'Калькулятор поездки',
        'fr': 'Calculateur de voyage',
        'de': 'Reiserechner',
        'es': 'Calculadora de viaje',
        'zh': '旅行计算器',
        'it': 'Calcolatore di viaggio',
      },
      'محاسبه زمان، مسافت و هزینه تقریبی سفر': {
        'fa': 'محاسبه زمان، مسافت و هزینه تقریبی سفر',
        'en': 'Calculate travel time, distance and estimated cost',
        'ar': 'حساب وقت السفر والمسافة والتكلفة التقديرية',
        'tr': 'Seyahat süresi, mesafe ve tahmini maliyeti hesaplayın',
        'ru': 'Расчет времени, расстояния и примерной стоимости',
        'fr': 'Calculer le temps, la distance et le coût estimé',
        'de': 'Reisezeit, Entfernung und geschätzte Kosten berechnen',
        'es': 'Calcula tiempo, distancia y coste estimado',
        'zh': '计算旅行时间、距离和预计费用',
        'it': 'Calcola tempo, distanza e costo stimato del viaggio',
      },
      'خدمات ضروری نزدیک من': {
        'fa': 'خدمات ضروری نزدیک من',
        'en': 'Essential Services Near Me',
        'ar': 'الخدمات الضرورية القريبة مني',
        'tr': 'Yakınımdaki Gerekli Hizmetler',
        'ru': 'Необходимые службы рядом',
        'fr': 'Services essentiels à proximité',
        'de': 'Wichtige Dienste in meiner Nähe',
        'es': 'Servicios esenciales cerca de mí',
        'zh': '附近的必要服务',
        'it': 'Servizi essenziali nelle vicinanze',
      },
      'بیمارستان، داروخانه، پلیس، ATM و خدمات ضروری': {
        'fa': 'بیمارستان، داروخانه، پلیس، ATM و خدمات ضروری',
        'en': 'Hospitals, pharmacies, police, ATMs and essential services',
        'ar': 'المستشفيات والصيدليات والشرطة وأجهزة الصراف والخدمات الضرورية',
        'tr': 'Hastane, eczane, polis, ATM ve gerekli hizmetler',
        'ru': 'Больницы, аптеки, полиция, банкоматы и необходимые службы',
        'fr': 'Hôpitaux, pharmacies, police, distributeurs et services essentiels',
        'de': 'Krankenhäuser, Apotheken, Polizei, Geldautomaten und wichtige Dienste',
        'es': 'Hospitales, farmacias, policía, cajeros y servicios esenciales',
        'zh': '医院、药店、警察、ATM和必要服务',
        'it': 'Ospedali, farmacie, polizia, bancomat e servizi essenziali',
      },
      'حالت کم‌مصرف سفر': {
        'fa': 'حالت کم‌مصرف سفر',
        'en': 'Travel Battery Saver',
        'ar': 'وضع توفير البطارية أثناء السفر',
        'tr': 'Seyahat Pil Tasarrufu',
        'ru': 'Экономия батареи в путешествии',
        'fr': 'Économie de batterie en voyage',
        'de': 'Akku sparen auf Reisen',
        'es': 'Ahorro de batería durante el viaje',
        'zh': '旅行省电模式',
        'it': 'Risparmio batteria in viaggio',
      },
      'کاهش مصرف باتری هنگام سفر': {
        'fa': 'کاهش مصرف باتری هنگام سفر',
        'en': 'Reduce battery usage while traveling',
        'ar': 'تقليل استهلاك البطارية أثناء السفر',
        'tr': 'Seyahat sırasında pil tüketimini azaltın',
        'ru': 'Снижение расхода батареи во время поездки',
        'fr': 'Réduire la consommation de batterie pendant le voyage',
        'de': 'Akkuverbrauch während der Reise reduzieren',
        'es': 'Reduce el consumo de batería durante el viaje',
        'zh': '减少旅行时的电池消耗',
        'it': 'Riduci il consumo della batteria durante il viaggio',
      },
      'سفر آفلاین': {
        'fa': 'سفر آفلاین',
        'en': 'Offline Travel',
        'ar': 'السفر دون اتصال',
        'tr': 'Çevrimdışı Seyahat',
        'ru': 'Офлайн-путешествие',
        'fr': 'Voyage hors ligne',
        'de': 'Offline-Reise',
        'es': 'Viaje sin conexión',
        'zh': '离线旅行',
        'it': 'Viaggio offline',
      },
      'دسترسی به اطلاعات ذخیره‌شده در نبود اینترنت': {
        'fa': 'دسترسی به اطلاعات ذخیره‌شده در نبود اینترنت',
        'en': 'Access saved information without internet',
        'ar': 'الوصول إلى المعلومات المحفوظة دون إنترنت',
        'tr': 'İnternet olmadan kaydedilmiş bilgilere erişin',
        'ru': 'Доступ к сохраненной информации без интернета',
        'fr': 'Accéder aux informations enregistrées sans internet',
        'de': 'Gespeicherte Informationen ohne Internet nutzen',
        'es': 'Accede a la información guardada sin internet',
        'zh': '无网络时访问已保存的信息',
        'it': 'Accedi alle informazioni salvate senza internet',
      },

      // ---------------------------------------------------------
      // Online
      // ---------------------------------------------------------

      'تبدیل ارز آنلاین': {
        'fa': 'تبدیل ارز آنلاین',
        'en': 'Online Currency Converter',
        'ar': 'محول العملات عبر الإنترنت',
        'tr': 'Çevrimiçi Döviz Çevirici',
        'ru': 'Онлайн-конвертер валют',
        'fr': 'Convertisseur de devises en ligne',
        'de': 'Online-Währungsrechner',
        'es': 'Conversor de divisas en línea',
        'zh': '在线货币转换器',
        'it': 'Convertitore di valuta online',
      },
      'دریافت نرخ آنلاین و تبدیل ارزهای مختلف': {
        'fa': 'دریافت نرخ آنلاین و تبدیل ارزهای مختلف',
        'en': 'Get live rates and convert different currencies',
        'ar': 'الحصول على أسعار مباشرة وتحويل العملات المختلفة',
        'tr': 'Canlı kurları alın ve farklı para birimlerini dönüştürün',
        'ru': 'Получение актуальных курсов и конвертация валют',
        'fr': 'Obtenir les taux en direct et convertir les devises',
        'de': 'Aktuelle Kurse abrufen und Währungen umrechnen',
        'es': 'Obtén tasas en vivo y convierte diferentes monedas',
        'zh': '获取实时汇率并转换不同货币',
        'it': 'Ottieni tassi aggiornati e converti le valute',
      },
      'آب‌وهوای هوشمند مقصد': {
        'fa': 'آب‌وهوای هوشمند مقصد',
        'en': 'Smart Destination Weather',
        'ar': 'الطقس الذكي للوجهة',
        'tr': 'Akıllı Destinasyon Hava Durumu',
        'ru': 'Умная погода в пункте назначения',
        'fr': 'Météo intelligente de la destination',
        'de': 'Intelligentes Wetter am Reiseziel',
        'es': 'Clima inteligente del destino',
        'zh': '智能目的地天气',
        'it': 'Meteo intelligente della destinazione',
      },
      'مکان من، جستجوی شهر یا جستجوی مکان با جدول دقیق': {
        'fa': 'مکان من، جستجوی شهر یا جستجوی مکان با جدول دقیق',
        'en': 'My location, city or place search with detailed tables',
        'ar': 'موقعي أو البحث عن مدينة أو مكان مع جداول دقيقة',
        'tr': 'Konumum, şehir veya yer araması ve ayrıntılı tablolar',
        'ru': 'Мое местоположение, поиск города или места с подробными таблицами',
        'fr': 'Ma position, recherche de ville ou lieu avec tableaux détaillés',
        'de': 'Mein Standort, Stadt- oder Ortssuche mit detaillierten Tabellen',
        'es': 'Mi ubicación, búsqueda de ciudad o lugar con tablas detalladas',
        'zh': '我的位置、城市或地点搜索及详细天气表',
        'it': 'Cerca posizione, città o luogo con tabelle meteo dettagliate',
      },
      'ساعت جهانی': {
        'fa': 'ساعت جهانی',
        'en': 'World Clock',
        'ar': 'الساعة العالمية',
        'tr': 'Dünya Saati',
        'ru': 'Мировые часы',
        'fr': 'Horloge mondiale',
        'de': 'Weltzeituhr',
        'es': 'Reloj mundial',
        'zh': '世界时钟',
        'it': 'Orologio mondiale',
      },
      'نمایش ساعت شهرهای مختلف جهان': {
        'fa': 'نمایش ساعت شهرهای مختلف جهان',
        'en': 'Show the time in cities around the world',
        'ar': 'عرض الوقت في مدن مختلفة حول العالم',
        'tr': 'Dünyanın farklı şehirlerindeki saati göster',
        'ru': 'Время в разных городах мира',
        'fr': 'Afficher l’heure dans différentes villes du monde',
        'de': 'Uhrzeit in Städten weltweit anzeigen',
        'es': 'Muestra la hora de diferentes ciudades del mundo',
        'zh': '显示世界各地城市的时间',
        'it': 'Mostra l'ora nelle città del mondo',
      },
      'زمان محلی مقصد': {
        'fa': 'زمان محلی مقصد',
        'en': 'Destination Local Time',
        'ar': 'الوقت المحلي للوجهة',
        'tr': 'Varış Yeri Yerel Saati',
        'ru': 'Местное время в пункте назначения',
        'fr': 'Heure locale de la destination',
        'de': 'Ortszeit am Reiseziel',
        'es': 'Hora local del destino',
        'zh': '目的地当地时间',
        'it': 'Ora locale della destinazione',
      },
      'نمایش زمان محلی و اختلاف ساعت مقصد': {
        'fa': 'نمایش زمان محلی و اختلاف ساعت مقصد',
        'en': 'Show local time and time difference',
        'ar': 'عرض الوقت المحلي وفارق التوقيت',
        'tr': 'Yerel saati ve saat farkını göster',
        'ru': 'Местное время и разница во времени',
        'fr': 'Afficher l’heure locale et le décalage horaire',
        'de': 'Ortszeit und Zeitunterschied anzeigen',
        'es': 'Muestra la hora local y la diferencia horaria',
        'zh': '显示当地时间和时差',
        'it': 'Mostra l'ora locale e il fuso orario',
      },
      'وضعیت اتصال': {
        'fa': 'وضعیت اتصال',
        'en': 'Connection Status',
        'ar': 'حالة الاتصال',
        'tr': 'Bağlantı Durumu',
        'ru': 'Состояние подключения',
        'fr': 'État de la connexion',
        'de': 'Verbindungsstatus',
        'es': 'Estado de conexión',
        'zh': '连接状态',
        'it': 'Stato della connessione',
      },
      'بررسی وضعیت اینترنت برای قابلیت‌های آنلاین': {
        'fa': 'بررسی وضعیت اینترنت برای قابلیت‌های آنلاین',
        'en': 'Check internet status for online features',
        'ar': 'فحص حالة الإنترنت للميزات المتصلة',
        'tr': 'Çevrimiçi özellikler için internet bağlantısını kontrol edin',
        'ru': 'Проверка интернета для онлайн-функций',
        'fr': 'Vérifier internet pour les fonctions en ligne',
        'de': 'Internetstatus für Online-Funktionen prüfen',
        'es': 'Comprueba internet para las funciones en línea',
        'zh': '检查在线功能的网络状态',
        'it': 'Verifica la connessione internet per le funzioni online',
      },
    };

    return translations[text]?[languageCode] ??
        translations[text]?['fa'] ??
        text;
  }
}

/// ===============================================================
/// Tool Model
/// ===============================================================

class CyrusToolItem {
  const CyrusToolItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
}

/// ===============================================================
/// 3D Gold Button
/// ===============================================================

class CyrusSmartToolButton extends StatefulWidget {
  const CyrusSmartToolButton({
    super.key,
    required this.item,
    required this.onTap,
  });

  final CyrusToolItem item;
  final VoidCallback onTap;

  @override
  State<CyrusSmartToolButton> createState() =>
      _CyrusSmartToolButtonState();
}

class _CyrusSmartToolButtonState
    extends State<CyrusSmartToolButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        transform: Matrix4.translationValues(
          0,
          _pressed ? 4 : 0,
          0,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff173747),
              Color(0xff0b202c),
            ],
          ),
          border: Border.all(
            color: const Color(0xffffd76a).withOpacity(0.55),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffffc94d).withOpacity(
                _pressed ? 0.10 : 0.22,
              ),
              blurRadius: _pressed ? 8 : 16,
              offset: Offset(
                0,
                _pressed ? 3 : 7,
              ),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.iconColor.withOpacity(0.13),
                border: Border.all(
                  color: item.iconColor.withOpacity(0.52),
                  width: 1.2,
                ),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xffffd76a),
            ),
          ],
        ),
      ),
    );
  }
}
