import 'package:hive/hive.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
//import 'package:flutter_native_timezone_updated/flutter_native_timezone.dart';
//import 'package:flutter_native_timezone/flutter_timezone.dart';

class ToDoDataBase {
  List<List<dynamic>> calTasks = [];
  List<List<dynamic>> toDoList = [];
  List<String> categories = [];

  // In-memory Sets
  Map<String, Set<String>> viewOnlyCalendars = {
    //View only
    "local": <String>{},
    "google": <String>{},
    "outlook": <String>{},
  };

  Map<String, dynamic> syncToCalendars = {
    //ToDOList
    "local": "none",
    "google": "none",
    "outlook": "none",
  };

  Map<String, dynamic> settings = {"timeZone": ""};

  Map<String, dynamic> accountDetails = {
    "userName": "none",
    "profilePicture": "none",
  };

  Box get _mybox => Hive.box("mybox");

  // Future<void> getDeviceTimeZone() async {
  //   final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  //   print("Device time zone: $timeZoneName"); // e.g. "Asia/Colombo"
  // }

  void createInitialData() {
    DateTime dueDateTime = DateTime.now().toUtc().add(Duration(minutes: 1));
    calTasks = [];
    toDoList = [
      // [
      //   "Take a break",
      //   false,
      //   "task note",
      //   DateTimeUtilsHelper.formatDate(dueDateTime),
      //   DateTimeUtilsHelper.formatTime(dueDateTime),
      //   "None",
      //   "High",
      //   "daily",
      //   0,
      //   "none",
      //   "false",
      //   DateTime.now().toUtc().toString(),
      //   "id-example",
      //   [
      //     {
      //       "name": "sub 1",
      //       "dueDate": null,
      //       "dueTime": null,
      //       "completed": false,
      //     },
      //   ],
      //   "",
      //   "",
      //   "",
      //   "initial",
      // ],
    ];
    categories = ["None", "Work", "Personal", "Study", "Others"];
    if (settings["timeZone"] == "") {
      //get local time zone
    }
  }

  void loadData() {
    print("🗄️ Loading database...");
    // Load to-do list
    final storedToDo = _mybox.get("TODOLIST");
    if (storedToDo is List) {
      toDoList = storedToDo.map((item) => item as List<dynamic>).toList();
    }

    print("ToDo Tasks: $toDoList");

    // Load categories
    final storedCategories = _mybox.get("CATEGORIES");
    if (storedCategories is List) {
      categories = storedCategories.cast<String>();
    }

    // Load viewOnlyCalendars (convert back to Sets)
    final storedFromCalendars = _mybox.get("SYNC_FROM_CALENDARS");
    if (storedFromCalendars is Map) {
      viewOnlyCalendars = {
        "local": (storedFromCalendars["local"] ?? []).cast<String>().toSet(),
        "google": (storedFromCalendars["google"] ?? []).cast<String>().toSet(),
        "outlook":
            (storedFromCalendars["outlook"] ?? []).cast<String>().toSet(),
      };
    }

    // Load syncToCalendars
    final storedToCalendars = _mybox.get("SYNC_TO_CALENDARS");
    if (storedToCalendars is Map) {
      syncToCalendars = Map<String, String>.from(
        storedToCalendars.cast<String, String>(),
      );
    }

    final storedSettings = _mybox.get("SETTINGS");
    if (storedSettings is Map) {
      settings = Map<String, dynamic>.from(
        storedSettings.cast<String, dynamic>(),
      );
    }
    print("Loaded settings: $settings");
    final storedAccount = _mybox.get("ACCOUNT");
    if (storedAccount is Map) {
      accountDetails = Map<String, dynamic>.from(
        storedAccount.cast<String, dynamic>(),
      );
    }

    // ✅ FIX: Load calendar tasks correctly
    final storedCalTasks = _mybox.get("CAL_TASKS");
    if (storedCalTasks is List) {
      calTasks = storedCalTasks.map((item) => item as List<dynamic>).toList();
    }
    print("🗄️ Database loaded");
  }

  void updateDataBase() {
    // Convert Sets to Lists for Hive storage
    final hiveviewOnlyCalendars = {
      "local": viewOnlyCalendars["local"]!.toList(),
      "google": viewOnlyCalendars["google"]!.toList(),
      "outlook": viewOnlyCalendars["outlook"]!.toList(),
    };

    _mybox.put("TODOLIST", toDoList);
    _mybox.put("CATEGORIES", categories);
    _mybox.put("SYNC_FROM_CALENDARS", hiveviewOnlyCalendars);
    _mybox.put("SYNC_TO_CALENDARS", syncToCalendars);
    _mybox.put("CAL_TASKS", calTasks);
    _mybox.put("SETTINGS", settings);
    _mybox.put("ACCOUNT", accountDetails);

    print("🗄️ Database updated");
    print("viewOnlyCalendars (in-memory Sets): $viewOnlyCalendars");
    print("viewOnlyCalendars (Hive Lists): $hiveviewOnlyCalendars");
    print(toDoList);
    print("✅$calTasks");
  }
}
