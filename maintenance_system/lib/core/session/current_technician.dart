import 'package:flutter/foundation.dart';

class CurrentTechnician extends ChangeNotifier {
  String? _technicianId;

  String? get technicianId => _technicianId;

  void setTechnician(String id) {
    _technicianId = id;
    notifyListeners();
  }
}
