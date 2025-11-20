import 'package:flutter/material.dart';
//import 'package:to_do_app/models/grouping_mode.dart';

class CalendarSyncProvider with ChangeNotifier {
  //GroupingMode _mode = GroupingMode.Default;

  //GroupingMode get mode => _mode;

  bool isSyncing = false;
  double progress = 0.0;

  void startSync() {
    isSyncing = true;
    progress = 0;
    notifyListeners();
  }

  void updateProgress(double value) {
    progress = value;
    notifyListeners();
  }

  void finishSync() {
    isSyncing = false;
    progress = 1.0;
    notifyListeners();
  }

  void notify() {
    print("----------calendar notified------------");
    notifyListeners(); // tells widgets to rebuild
  }
}
