import 'package:flutter/material.dart%20';
import 'package:to_do_app/models/sorting_mode.dart';

class FileSortProvider with ChangeNotifier {
  SortingMode _sortingMode = SortingMode.createdDateDecreasing;
  SortingMode get sortingMode => _sortingMode;
  void setSortingMode(SortingMode mode) {
    _sortingMode = mode;
    notifyListeners(); // tells widgets to rebuild
  }
}
