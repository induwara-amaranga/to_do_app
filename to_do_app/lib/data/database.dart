import 'package:hive/hive.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
//import 'package:flutter_native_timezone_updated/flutter_native_timezone.dart';
//import 'package:flutter_native_timezone/flutter_timezone.dart';

class ToDoDataBase {
  List<List<dynamic>> calTasks = [];
  List<List<dynamic>> toDoList = [];
  List<String> categories = [];

  // In-memory Sets
  Map<String, Set<String>> syncFromCalendars = {
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

  final _mybox = Hive.box("mybox");

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
      //   //false,
      // ],
    ];
    categories = ["None", "Work", "Personal", "Study", "Others"];
    if (settings["timeZone"] == "") {
      //get local time zone
    }
  }

  void loadData() {
    // Load to-do list
    final storedToDo = _mybox.get("TODOLIST");
    if (storedToDo is List) {
      toDoList = storedToDo.map((item) => item as List<dynamic>).toList();
    }

    // Load categories
    final storedCategories = _mybox.get("CATEGORIES");
    if (storedCategories is List) {
      categories = storedCategories.cast<String>();
    }

    // Load syncFromCalendars (convert back to Sets)
    final storedFromCalendars = _mybox.get("SYNC_FROM_CALENDARS");
    if (storedFromCalendars is Map) {
      syncFromCalendars = {
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

    // ✅ FIX: Load calendar tasks correctly
    final storedCalTasks = _mybox.get("CAL_TASKS");
    if (storedCalTasks is List) {
      calTasks = storedCalTasks.map((item) => item as List<dynamic>).toList();
    }
  }

  void updateDataBase() {
    // Convert Sets to Lists for Hive storage
    final hiveSyncFromCalendars = {
      "local": syncFromCalendars["local"]!.toList(),
      "google": syncFromCalendars["google"]!.toList(),
      "outlook": syncFromCalendars["outlook"]!.toList(),
    };

    _mybox.put("TODOLIST", toDoList);
    _mybox.put("CATEGORIES", categories);
    _mybox.put("SYNC_FROM_CALENDARS", hiveSyncFromCalendars);
    _mybox.put("SYNC_TO_CALENDARS", syncToCalendars);
    _mybox.put("CAL_TASKS", calTasks);
    _mybox.put("SETTINGS", settings);

    print("🗄️ Database updated");
    print("syncFromCalendars (in-memory Sets): $syncFromCalendars");
    print("syncFromCalendars (Hive Lists): $hiveSyncFromCalendars");
    print(toDoList);
    print("✅$calTasks");
  }
}
