import 'package:flutter/foundation.dart';

class MapStateService extends ChangeNotifier {
  bool _isLoading = false;
  bool _mapReady = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get mapReady => _mapReady;
  String? get errorMessage => _errorMessage;

  void startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void setMapReady() {
    _isLoading = false;
    _mapReady = true;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    _mapReady = false;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _mapReady = false;
    _errorMessage = null;
    notifyListeners();
  }
}
