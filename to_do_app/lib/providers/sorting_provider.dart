import 'package:flutter/material.dart';
import 'package:to_do_app/models/sorting_mode.dart';

class SortingProvider with ChangeNotifier {
  bool doSort = true;
  SortingMode _mode = SortingMode.createdDateDecreasing;
  //SortingMode _mode = SortingMode.starredFirst;

  SortingMode get mode => _mode;

  void setMode(SortingMode mode) {
    _mode = mode;
    doSort = true;
    notifyListeners(); // tells widgets to rebuild
  }
}
