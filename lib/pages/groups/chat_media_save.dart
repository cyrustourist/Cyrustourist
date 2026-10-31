import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _imageChannel = MethodChannel('cyrus/image');

/// دانلود عکس چت (با هدر توکن) و ذخیره در گالری گوشی، پوشهٔ «Cyrustourist».
/// ذخیره با کد بومی اندروید (MediaStore) انجام می‌شود و پکیج جانبی لازم ندارد.
Future<bool> saveChatImageToGallery(String url, Map<String, String> headers) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 15));
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return false;
    final bytes = await consolidateHttpClientResponseBytes(res);
    if (bytes.isEmpty) return false;
    final ok = await _imageChannel.invokeMethod<bool>('saveToGallery', {'bytes': bytes});
    return ok == true;
  } catch (e) {
    debugPrint('saveChatImage: ${e.runtimeType}');
    return false;
  } finally {
    client.close(force: true);
  }
}
