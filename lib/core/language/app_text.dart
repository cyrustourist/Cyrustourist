import 'app_language.dart';
import 'package:flutter/material.dart';

class AppText {
  /// فقط فارسی و عربی راست‌به‌چپ هستند.
  static bool get rtl {
    return LanguageManager.current == AppLanguage.persian ||
        LanguageManager.current == AppLanguage.arabic;
  }

  static String title() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'سایروس توریست';

      case AppLanguage.english:
        return 'Cyrus Tourist';

      case AppLanguage.arabic:
        return 'سايروس توريست';

      case AppLanguage.german:
        return 'Cyrus Tourist';

      case AppLanguage.spanish:
        return 'Cyrus Tourist';

      case AppLanguage.french:
        return 'Cyrus Tourist';

      case AppLanguage.italian:
        return 'Cyrus Tourist';

      case AppLanguage.russian:
        return 'Cyrus Tourist';

      case AppLanguage.turkish:
        return 'Cyrus Tourist';

      case AppLanguage.chinese:
        return 'Cyrus Tourist';
    }
  }

  static String languageName() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'پارسی';

      case AppLanguage.english:
        return 'English';

      case AppLanguage.arabic:
        return 'العربية';

      case AppLanguage.german:
        return 'Deutsch';

      case AppLanguage.spanish:
        return 'Español';

      case AppLanguage.french:
        return 'Français';

      case AppLanguage.italian:
        return 'Italiano';

      case AppLanguage.russian:
        return 'Русский';

      case AppLanguage.turkish:
        return 'Türkçe';

      case AppLanguage.chinese:
        return '中文';
    }
  }

  static String map() {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        return 'نقشه گردشگری';

      case AppLanguage.english:
        return 'Tourism Map';

      case AppLanguage.arabic:
        return 'خريطة السياحة';

      case AppLanguage.german:
        return 'Tourismuskarte';

      case AppLanguage.spanish:
        return 'Mapa turístico';

      case AppLanguage.french:
        return 'Carte touristique';

      case AppLanguage.italian:
        return 'Mappa turistica';

      case AppLanguage.russian:
        return 'Туристическая карта';

      case AppLanguage.turkish:
        return 'Turizm Haritası';

      case AppLanguage.chinese:
        return '旅游地图';
    }
  }

  static String button(int number) {
    switch (LanguageManager.current) {
      case AppLanguage.persian:
        const items = [
          '',
          'نقشه گردشگری',
          'گردشگری سلامت',
          'جاذبه‌های گردشگری',
          'فیلم‌های گردشگری',
          'اقامتگاه',
          'راهنمای سفر',
          'شبکه‌های اجتماعی',
          'درباره ما',
          'پشتیبانی و تماس',
          'علاقه‌مندی‌ها',
        ];

        return items[number];

      case AppLanguage.english:
        const items = [
          '',
          'Tourism Map',
          'Health Tourism',
          'Tourist Attractions',
          'Tourism Videos',
          'Accommodation',
          'Travel Guide',
          'Social Networks',
          'About Us',
          'Support & Contact',
          'Favorites',
        ];

        return items[number];

      case AppLanguage.arabic:
        const items = [
          '',
          'خريطة السياحة',
          'السياحة العلاجية',
          'المعالم السياحية',
          'أفلام سياحية',
          'الإقامة',
          'دليل السفر',
          'الشبكات الاجتماعية',
          'معلومات عنا',
          'الدعم والاتصال',
          'المفضلة',
        ];

        return items[number];

      case AppLanguage.german:
        const items = [
          '',
          'Tourismuskarte',
          'Gesundheitstourismus',
          'Sehenswürdigkeiten',
          'Tourismusvideos',
          'Unterkunft',
          'Reiseführer',
          'Soziale Netzwerke',
          'Über uns',
          'Support & Kontakt',
          'Favoriten',
        ];

        return items[number];

      case AppLanguage.spanish:
        const items = [
          '',
          'Mapa turístico',
          'Turismo de salud',
          'Atracciones turísticas',
          'Vídeos turísticos',
          'Alojamiento',
          'Guía de viaje',
          'Redes sociales',
          'Sobre nosotros',
          'Soporte y contacto',
          'Favoritos',
        ];

        return items[number];

      case AppLanguage.french:
        const items = [
          '',
          'Carte touristique',
          'Tourisme de santé',
          'Attractions touristiques',
          'Vidéos touristiques',
          'Hébergement',
          'Guide de voyage',
          'Réseaux sociaux',
          'À propos de nous',
          'Assistance et contact',
          'Favoris',
        ];

        return items[number];

      case AppLanguage.italian:
        const items = [
          '',
          'Mappa turistica',
          'Turismo sanitario',
          'Attrazioni turistiche',
          'Video turistici',
          'Alloggio',
          'Guida di viaggio',
          'Social network',
          'Chi siamo',
          'Supporto e contatti',
          'Preferiti',
        ];

        return items[number];

      case AppLanguage.russian:
        const items = [
          '',
          'Туристическая карта',
          'Оздоровительный туризм',
          'Туристические достопримечательности',
          'Туристические видео',
          'Размещение',
          'Путеводитель',
          'Социальные сети',
          'О нас',
          'Поддержка и контакты',
          'Избранное',
        ];

        return items[number];

      case AppLanguage.turkish:
        const items = [
          '',
          'Turizm Haritası',
          'Sağlık Turizmi',
          'Turistik Yerler',
          'Turizm Videoları',
          'Konaklama',
          'Seyahat Rehberi',
          'Sosyal Ağlar',
          'Hakkımızda',
          'Destek ve İletişim',
          'Favoriler',
        ];

        return items[number];

      case AppLanguage.chinese:
        const items = [
          '',
          '旅游地图',
          '医疗旅游',
          '旅游景点',
          '旅游视频',
          '住宿',
          '旅行指南',
          '社交网络',
          '关于我们',
          '支持与联系',
          '收藏夹',
        ];

        return items[number];
    }
  }
}
