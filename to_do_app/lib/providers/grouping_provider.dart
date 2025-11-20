import 'package:flutter/material.dart';
import 'package:to_do_app/models/grouping_mode.dart';

class GroupingProvider with ChangeNotifier {
  GroupingMode _mode = GroupingMode.Default;

  GroupingMode get mode => _mode;

  void setMode(GroupingMode mode) {
    _mode = mode;
    notifyListeners(); // tells widgets to rebuild
  }
}
