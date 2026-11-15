import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// سرور کوچک بازی روی خود گوشی (بدون اینترنت):
///  - صفحه‌ی بازی (assets/web/games.html) و qrcode.js را از طریق HTTP می‌دهد؛
///  - مسیر /ws یک رله‌ی ساده‌ی اتاق است (همان پروتکلی که games.html سایت دارد).
/// آیفون با سافاری فقط همین آدرس را باز می‌کند؛ هیچ برنامه‌ای لازم نیست.
class LocalGameServer {
  LocalGameServer._();
  static final LocalGameServer instance = LocalGameServer._();

  HttpServer? _server;
  final Map<String, _Room> _rooms = <String, _Room>{};
  String? _html;
  String? _qrJs;

  bool get running => _server != null;
  int get port => _server?.port ?? 0;

  Future<bool> start() async {
    if (_server != null) return true;
    try {
      _html = await rootBundle.loadString('assets/web/games.html');
      _qrJs = await rootBundle.loadString('assets/web/qrcode.js');
    } catch (e) {
      debugPrint('LocalGameServer assets: $e');
      return false;
    }
    for (final p in <int>[8080, 8088, 0]) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, p);
        break;
      } catch (e) {
        debugPrint('LocalGameServer bind $p: $e');
      }
    }
    final s = _server;
    if (s == null) return false;
    s.listen(_handle, onError: (Object e) => debugPrint('LocalGameServer: $e'));
    return true;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    for (final r in _rooms.values) {
      r.close();
    }
    _rooms.clear();
    try {
      await s?.close(force: true);
    } catch (_) {}
  }

  void _handle(HttpRequest req) {
    final path = req.uri.path;
    if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then(_onSocket).catchError((Object e) {
        debugPrint('LocalGameServer ws: $e');
      });
      return;
    }
    if (path == '/' || path == '/games.html' || path == '/index.html') {
      _send(req, 'text/html; charset=utf-8', _html ?? '');
    } else if (path == '/js/qrcode.js') {
      _send(req, 'application/javascript; charset=utf-8', _qrJs ?? '');
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  void _send(HttpRequest req, String type, String body) {
    final bytes = utf8.encode(body);
    req.response
      ..headers.set('content-type', type)
      ..headers.set('cache-control', 'no-store')
      ..contentLength = bytes.length
      ..add(bytes);
    req.response.close();
  }

  // ------------------------------------------------------------------ رله‌ی اتاق
  void _onSocket(WebSocket ws) {
    ws.pingInterval = const Duration(seconds: 15);
    _Room? room;
    String? myId; // null = میزبان
    var joined = false;

    void reply(Map<String, dynamic> m) {
      try {
        ws.add(jsonEncode(m));
      } catch (_) {}
    }

    ws.listen((dynamic data) {
      if (data is! String || data.length > 65536) return;
      Map<String, dynamic> m;
      try {
        m = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
      if (!joined) {
        final code = '${m['r'] ?? ''}'.trim();
        final role = '${m['role'] ?? ''}';
        if (code.isEmpty || code.length > 12) {
          reply({'_': 'err', 'e': 'bad'});
          return;
        }
        if (role == 'host') {
          if (_rooms.containsKey(code)) {
            reply({'_': 'err', 'e': 'room-exists'});
            return;
          }
          room = _Room(ws);
          _rooms[code] = room!;
          joined = true;
          reply({'_': 'ok'});
        } else {
          final r = _rooms[code];
          if (r == null) {
            reply({'_': 'err', 'e': 'no-room'});
            return;
          }
          room = r;
          myId = 'g${++r.seq}';
          r.guests[myId!] = ws;
          joined = true;
          reply({'_': 'ok', 'id': myId});
          r.toHost({'_': 'join', 'id': myId});
        }
        return;
      }
      final r = room;
      if (r == null) return;
      if (myId == null) {
        // میزبان → مهمان
        if (m['_'] == 'to') {
          r.toGuest('${m['id']}', {'_': 'm', 'm': m['m']});
        }
      } else if (m['_'] == 'm') {
        // مهمان → میزبان
        r.toHost({'_': 'm', 'id': myId, 'm': m['m']});
      }
    }, onDone: () {
      final r = room;
      if (r == null) return;
      if (myId == null) {
        r.toAllGuests({'_': 'host-left'});
        r.close();
        _rooms.removeWhere((_, v) => identical(v, r));
      } else {
        r.guests.remove(myId);
        r.toHost({'_': 'leave', 'id': myId});
      }
    }, onError: (Object _) {});
  }
}

class _Room {
  _Room(this.host);
  final WebSocket host;
  final Map<String, WebSocket> guests = <String, WebSocket>{};
  int seq = 0;

  void _add(WebSocket w, Map<String, dynamic> m) {
    try {
      w.add(jsonEncode(m));
    } catch (_) {}
  }

  void toHost(Map<String, dynamic> m) => _add(host, m);
  void toGuest(String id, Map<String, dynamic> m) {
    final g = guests[id];
    if (g != null) _add(g, m);
  }

  void toAllGuests(Map<String, dynamic> m) {
    for (final g in guests.values) {
      _add(g, m);
    }
  }

  void close() {
    for (final g in guests.values) {
      try {
        g.close();
      } catch (_) {}
    }
    guests.clear();
  }
}
