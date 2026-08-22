import 'package:flutter/foundation.dart';

class MapStateService extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasLocation = false;
  bool _isGpsEnabled = false;
  String _message = '';

  bool get isLoading => _isLoading;
  bool get hasLocation => _hasLocation;
  bool get isGpsEnabled => _isGpsEnabled;
  String get message => _message;

  Future<void> initialize() async {
    _isLoading = true;
    _message = 'در حال بررسی وضعیت نقشه...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _isGpsEnabled = true;
    _hasLocation = true;
    _isLoading = false;
    _message = 'موقعیت شما آماده است';

    notifyListeners();
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _hasLocation = true;
    _isLoading = false;
    _message = 'موقعیت به‌روزرسانی شد';

    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void updateMessage(String value) {
    _message = value;
    notifyListeners();
  }
}
