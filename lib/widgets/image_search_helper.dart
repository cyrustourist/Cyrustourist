import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

/// جستجو با تصویر (جستجوی هوشمند) — کاملاً رایگان و روی خود گوشی.
///
/// موقعیت جی‌پی‌اس داخل عکس (EXIF): اگر عکس مختصات داشته باشد، همان نقطه.
/// (تشخیص محتوای عکس با ML Kit حذف شد تا حجم اپ حدود ۱۳ مگ کم شود.)
class ImageSearchResult {
  const ImageSearchResult({this.point, this.category, this.labels = const []});

  /// مختصات داخل عکس (اگر وجود داشت).
  final LatLng? point;

  /// یکی از: `restaurant`، `cafe`، `market`، `historical`، `nature`.
  final String? category;

  /// برچسب‌های خام تشخیص‌داده‌شده (انگلیسی).
  final List<String> labels;
}

/// انتخاب عکس (دوربین/گالری) و تحلیل آن. اگر کاربر لغو کند `null`؛
/// اگر چیزی تشخیص داده نشود، نتیجه‌ای با `point == null` و `category == null`.
/// خطاها با SnackBar همین‌جا نشان داده می‌شوند.
Future<ImageSearchResult?> pickAndAnalyzeImage(
  BuildContext context, {
  required String languageCode,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final isRtl = languageCode == 'fa' || languageCode == 'ar';

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SourceSheet(languageCode: languageCode),
  );
  if (source == null) return null;

  XFile? file;
  try {
    // عمداً بدون maxWidth/imageQuality: تغییر اندازه، EXIF (مختصات) را پاک می‌کند.
    file = await ImagePicker().pickImage(source: source);
  } catch (_) {
    messenger.showSnackBar(SnackBar(
      content: Text(ImageSearchTexts.get(languageCode, 'error')),
    ));
    return null;
  }
  if (file == null) return null;

  if (!context.mounted) return null;

  // پنجره‌ی «در حال بررسی تصویر…»
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color(0xff102532),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xffc99b3b)),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ImageSearchTexts.get(languageCode, 'analyzing'),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  ImageSearchResult result;
  try {
    result = await _analyze(file);
  } catch (_) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(ImageSearchTexts.get(languageCode, 'error')),
    ));
    return null;
  }

  navigator.pop();
  return result;
}

Future<ImageSearchResult> _analyze(XFile file) async {
  // ۱) مختصات داخل عکس
  LatLng? point;
  try {
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);
    point = _gpsFromExif(data);
  } catch (_) {
    point = null;
  }

  // تشخیص محتوای عکس (ML Kit) برای کم‌کردن حجم اپ حذف شد؛ فقط مختصات EXIF.
  const List<String> labels = [];
  const String? category = null;

  return ImageSearchResult(point: point, category: category, labels: labels);
}

/// تبدیل مختصات EXIF (درجه/دقیقه/ثانیه) به LatLng.
LatLng? _gpsFromExif(Map<String, IfdTag> data) {
  final latTag = data['GPS GPSLatitude'];
  final lonTag = data['GPS GPSLongitude'];
  if (latTag == null || lonTag == null) return null;

  double? dms(IfdTag tag) {
    final list = tag.values.toList();
    if (list.length < 3) return null;
    double part(dynamic r) {
      final n = (r.numerator as num).toDouble();
      final d = (r.denominator as num).toDouble();
      return d == 0 ? double.nan : n / d;
    }

    final value = part(list[0]) + part(list[1]) / 60 + part(list[2]) / 3600;
    return value.isNaN ? null : value;
  }

  var lat = dms(latTag);
  var lon = dms(lonTag);
  if (lat == null || lon == null) return null;

  final latRef = data['GPS GPSLatitudeRef']?.printable.trim().toUpperCase();
  final lonRef = data['GPS GPSLongitudeRef']?.printable.trim().toUpperCase();
  if (latRef == 'S') lat = -lat;
  if (lonRef == 'W') lon = -lon;

  if (lat.abs() > 90 || lon.abs() > 180) return null;
  if (lat == 0 && lon == 0) return null;

  return LatLng(lat, lon);
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final rtl = languageCode == 'fa' || languageCode == 'ar';

    Widget option(IconData icon, String key, ImageSource source) {
      return ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xffc99b3b).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xffffd56d)),
        ),
        title: Text(
          ImageSearchTexts.get(languageCode, key),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        onTap: () => Navigator.of(context).pop(source),
      );
    }

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          color: Color(0xff0b1d29),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: Color(0xffc99b3b))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xff39505d),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                ImageSearchTexts.get(languageCode, 'title'),
                style: const TextStyle(
                  color: Color(0xffffd979),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ImageSearchTexts.get(languageCode, 'subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff8fa4ad), fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              option(Icons.photo_camera_rounded, 'camera', ImageSource.camera),
              option(Icons.photo_library_rounded, 'gallery', ImageSource.gallery),
            ],
          ),
        ),
      ),
    );
  }
}

/// متن‌های جستجو با تصویر در ۱۰ زبان برنامه.
class ImageSearchTexts {
  ImageSearchTexts._();

  /// `{x}` در متن با [args] جایگزین می‌شود.
  static String get(
    String lang,
    String key, {
    Map<String, String> args = const {},
  }) {
    final code = lang.toLowerCase().trim();
    var text = _t[code]?[key] ?? _t['en']![key] ?? key;
    args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }

  static const Map<String, Map<String, String>> _t = {
    'fa': {
      'title': 'جستجو با تصویر',
      'subtitle': 'عکسی از یک مکان یا منظره انتخاب کنید',
      'camera': 'گرفتن عکس با دوربین',
      'gallery': 'انتخاب از گالری',
      'analyzing': 'در حال بررسی تصویر…',
      'foundGps': 'موقعیت ثبت‌شده در عکس پیدا شد.',
      'foundCategory': 'در عکس تشخیص داده شد: {cat}. در حال جستجوی اطراف شما…',
      'nothing': 'مکانی در این عکس تشخیص داده نشد و موقعیتی هم در آن ثبت نشده است. عکس دیگری امتحان کنید یا نام مکان را بنویسید.',
      'error': 'بررسی عکس انجام نشد. دوباره تلاش کنید.',
    },
    'en': {
      'title': 'Search by Image',
      'subtitle': 'Choose a photo of a place or a view',
      'camera': 'Take a photo',
      'gallery': 'Choose from gallery',
      'analyzing': 'Analyzing the image…',
      'foundGps': 'Found the location saved in the photo.',
      'foundCategory': 'Detected in the photo: {cat}. Searching near you…',
      'nothing': 'No place was recognized in this photo and it has no saved location. Try another photo or type the place name.',
      'error': 'Could not analyze the photo. Please try again.',
    },
    'ar': {
      'title': 'البحث بالصورة',
      'subtitle': 'اختر صورة لمكان أو منظر',
      'camera': 'التقاط صورة',
      'gallery': 'اختيار من المعرض',
      'analyzing': 'جارٍ تحليل الصورة…',
      'foundGps': 'تم العثور على الموقع المحفوظ في الصورة.',
      'foundCategory': 'تم التعرف في الصورة على: {cat}. جارٍ البحث بالقرب منك…',
      'nothing': 'لم يتم التعرف على مكان في هذه الصورة ولا يوجد موقع محفوظ فيها. جرّب صورة أخرى أو اكتب اسم المكان.',
      'error': 'تعذر تحليل الصورة. حاول مرة أخرى.',
    },
    'tr': {
      'title': 'Görselle Arama',
      'subtitle': 'Bir yerin veya manzaranın fotoğrafını seçin',
      'camera': 'Fotoğraf çek',
      'gallery': 'Galeriden seç',
      'analyzing': 'Görsel inceleniyor…',
      'foundGps': 'Fotoğrafa kaydedilmiş konum bulundu.',
      'foundCategory': 'Fotoğrafta tespit edilen: {cat}. Çevrenizde aranıyor…',
      'nothing': 'Bu fotoğrafta bir yer tanınmadı ve kayıtlı konum da yok. Başka bir fotoğraf deneyin veya yer adını yazın.',
      'error': 'Fotoğraf incelenemedi. Lütfen tekrar deneyin.',
    },
    'ru': {
      'title': 'Поиск по фото',
      'subtitle': 'Выберите фото места или пейзажа',
      'camera': 'Сделать фото',
      'gallery': 'Выбрать из галереи',
      'analyzing': 'Анализ изображения…',
      'foundGps': 'Найдено местоположение, сохранённое в фото.',
      'foundCategory': 'На фото распознано: {cat}. Ищу рядом с вами…',
      'nothing': 'Место на фото не распознано, и в нём нет сохранённого местоположения. Попробуйте другое фото или введите название места.',
      'error': 'Не удалось проанализировать фото. Попробуйте ещё раз.',
    },
    'fr': {
      'title': 'Recherche par image',
      'subtitle': 'Choisissez la photo d\'un lieu ou d\'un paysage',
      'camera': 'Prendre une photo',
      'gallery': 'Choisir dans la galerie',
      'analyzing': 'Analyse de l\'image…',
      'foundGps': 'Position enregistrée dans la photo trouvée.',
      'foundCategory': 'Détecté sur la photo : {cat}. Recherche près de vous…',
      'nothing': 'Aucun lieu reconnu sur cette photo et aucune position enregistrée. Essayez une autre photo ou saisissez le nom du lieu.',
      'error': 'Impossible d\'analyser la photo. Réessayez.',
    },
    'de': {
      'title': 'Bildsuche',
      'subtitle': 'Wählen Sie ein Foto eines Ortes oder einer Landschaft',
      'camera': 'Foto aufnehmen',
      'gallery': 'Aus Galerie wählen',
      'analyzing': 'Bild wird analysiert…',
      'foundGps': 'Im Foto gespeicherter Standort gefunden.',
      'foundCategory': 'Im Foto erkannt: {cat}. Suche in Ihrer Nähe…',
      'nothing': 'Auf diesem Foto wurde kein Ort erkannt und es ist kein Standort gespeichert. Versuchen Sie ein anderes Foto oder geben Sie den Ortsnamen ein.',
      'error': 'Das Foto konnte nicht analysiert werden. Bitte erneut versuchen.',
    },
    'es': {
      'title': 'Búsqueda por imagen',
      'subtitle': 'Elige una foto de un lugar o paisaje',
      'camera': 'Tomar una foto',
      'gallery': 'Elegir de la galería',
      'analyzing': 'Analizando la imagen…',
      'foundGps': 'Se encontró la ubicación guardada en la foto.',
      'foundCategory': 'Detectado en la foto: {cat}. Buscando cerca de ti…',
      'nothing': 'No se reconoció ningún lugar en esta foto y no tiene ubicación guardada. Prueba con otra foto o escribe el nombre del lugar.',
      'error': 'No se pudo analizar la foto. Inténtalo de nuevo.',
    },
    'zh': {
      'title': '图片搜索',
      'subtitle': '选择一张地点或风景照片',
      'camera': '拍照',
      'gallery': '从相册选择',
      'analyzing': '正在分析图片…',
      'foundGps': '已找到照片中保存的位置。',
      'foundCategory': '照片中识别到：{cat}。正在搜索您附近…',
      'nothing': '未能识别这张照片中的地点，照片中也没有保存位置信息。请换一张照片或直接输入地点名称。',
      'error': '无法分析照片，请重试。',
    },
    'it': {
      'title': 'Ricerca per immagine',
      'subtitle': 'Scegli la foto di un luogo o di un paesaggio',
      'camera': 'Scatta una foto',
      'gallery': 'Scegli dalla galleria',
      'analyzing': 'Analisi dell\'immagine…',
      'foundGps': 'Posizione salvata nella foto trovata.',
      'foundCategory': 'Rilevato nella foto: {cat}. Ricerca vicino a te…',
      'nothing': 'Nessun luogo riconosciuto in questa foto e nessuna posizione salvata. Prova un\'altra foto o scrivi il nome del luogo.',
      'error': 'Impossibile analizzare la foto. Riprova.',
    },
  };
}
