import 'package:flutter/material.dart';

class ViewProvider with ChangeNotifier {
  String _currentView = 'tileView';

  String get currentView => _currentView;

  void setView(String view) {
    _currentView = view;
    notifyListeners();
  }
}
