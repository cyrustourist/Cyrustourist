
import 'package:flutter/foundation.dart';
import '../services/map_state_service.dart';

class MapStateProvider extends ChangeNotifier {
  final MapStateService _service = MapStateService();

  bool get isLoading => _service.isLoading;
  bool get hasLocation => _service.hasLocation;
  bool get isGpsEnabled => _service.isGpsEnabled;
  String get message => _service.message;

  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    await _service.refreshLocation();
    notifyListeners();
  }

  void setLoading(bool value) {
    _service.setLoading(value);
    notifyListeners();
  }

  void updateMessage(String value) {
    _service.updateMessage(value);
    notifyListeners();
  }
}
