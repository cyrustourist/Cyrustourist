import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// دانلود عکس چت (با هدر توکن) و ذخیره در گالری گوشی، پوشهٔ «Cyrustourist».
Future<bool> saveChatImageToGallery(String url, Map<String, String> headers) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  File? tmp;
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 15));
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return false;
    final bytes = await consolidateHttpClientResponseBytes(res);
    if (bytes.isEmpty) return false;
    final dir = await getTemporaryDirectory();
    tmp = File('${dir.path}/cyrus_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tmp.writeAsBytes(bytes, flush: true);
    await Gal.putImage(tmp.path, album: 'Cyrustourist');
    return true;
  } catch (e) {
    debugPrint('saveChatImage: ${e.runtimeType}');
    return false;
  } finally {
    client.close(force: true);
    try {
      await tmp?.delete();
    } catch (_) {}
  }
}
