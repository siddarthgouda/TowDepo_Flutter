import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AppState extends ChangeNotifier {
  Position? _currentPosition;
  String? _pincode;

  Position? get currentPosition => _currentPosition;
  String? get pincode => _pincode;

  void setPosition(Position? pos) {
    _currentPosition = pos;
    notifyListeners();
  }

  void setPincode(String? pin) {
    _pincode = pin;
    notifyListeners();
  }
}
