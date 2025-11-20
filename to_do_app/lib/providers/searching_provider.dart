import 'package:flutter/material.dart';
//import 'package:to_do_app/models/sorting_mode.dart';

class SearchingProvider with ChangeNotifier {
  String _query = "";
  //SortingMode _mode = SortingMode.starredFirst;

  String get query => _query;

  void setQuery(String query) {
    _query = query;
    notifyListeners(); // tells widgets to rebuild
  }
}
