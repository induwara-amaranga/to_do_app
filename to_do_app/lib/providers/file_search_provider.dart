import 'package:flutter/material.dart%20';

class FileSearchProvider with ChangeNotifier {
  String _searchQuery = "";
  String get searchQuery => _searchQuery;
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners(); // tells widgets to rebuild
  }
}
