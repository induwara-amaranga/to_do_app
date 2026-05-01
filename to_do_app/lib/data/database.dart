import 'package:hive/hive.dart';
import 'package:to_do_app/utils/date_time_utils.dart';

//import 'package:flutter_native_timezone_updated/flutter_native_timezone.dart';
//import 'package:flutter_native_timezone/flutter_timezone.dart';

class ToDoDataBase {
  List<List<dynamic>> localCalTasks = [];
  List<List<dynamic>> googleCalTasks = [];
  List<List<dynamic>> outlookCalTasks = [];
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
    localCalTasks = [];
    googleCalTasks = [];
    outlookCalTasks = [];
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

  void saveToDoList() => _mybox.put("TODOLIST", toDoList);
  void saveCategories() => _mybox.put("CATEGORIES", categories);
  void saveSettings() => _mybox.put("SETTINGS", settings);
  void saveAccountDetails() => _mybox.put("ACCOUNT", accountDetails);
  void saveLocalCalTasks() => _mybox.put("LOCAL_CAL_TASKS", localCalTasks);
  void saveGoogleCalTasks() => _mybox.put("GOOGLE_CAL_TASKS", googleCalTasks);
  void saveOutlookCalTasks() =>
      _mybox.put("OUTLOOK_CAL_TASKS", outlookCalTasks);
  void saveSyncToCalendars() =>
      _mybox.put("SYNC_TO_CALENDARS", syncToCalendars);

  void saveViewOnlyCalendars() {
    _mybox.put("VIEW_ONLY_CALENDARS", {
      "local": viewOnlyCalendars["local"]!.toList(),
      "google": viewOnlyCalendars["google"]!.toList(),
      "outlook": viewOnlyCalendars["outlook"]!.toList(),
    });
  }

  // ─── Load Methods ────────────────────────────────────────────────────────

  void loadToDoList() {
    final data = _mybox.get("TODOLIST");
    if (data is List) {
      toDoList = data.map((item) => item as List<dynamic>).toList();
    }
  }

  void loadCategories() {
    final data = _mybox.get("CATEGORIES");
    if (data is List) categories = data.cast<String>();
  }

  void loadSettings() {
    final data = _mybox.get("SETTINGS");
    if (data is Map)
      settings = Map<String, dynamic>.from(data.cast<String, dynamic>());
  }

  void loadAccountDetails() {
    final data = _mybox.get("ACCOUNT");
    if (data is Map)
      accountDetails = Map<String, dynamic>.from(data.cast<String, dynamic>());
  }

  void loadLocalCalTasks() {
    final data = _mybox.get("LOCAL_CAL_TASKS");
    if (data is List)
      localCalTasks = data.map((item) => item as List<dynamic>).toList();
  }

  void loadGoogleCalTasks() {
    final data = _mybox.get("GOOGLE_CAL_TASKS");
    if (data is List)
      googleCalTasks = data.map((item) => item as List<dynamic>).toList();
  }

  void loadOutlookCalTasks() {
    final data = _mybox.get("OUTLOOK_CAL_TASKS");
    if (data is List)
      outlookCalTasks = data.map((item) => item as List<dynamic>).toList();
  }

  void loadSyncToCalendars() {
    final data = _mybox.get("SYNC_TO_CALENDARS");
    if (data is Map)
      syncToCalendars = Map<String, dynamic>.from(data.cast<String, dynamic>());
  }

  void loadViewOnlyCalendars() {
    final data = _mybox.get("VIEW_ONLY_CALENDARS");
    if (data is Map) {
      viewOnlyCalendars = {
        "local": (data["local"] ?? []).cast<String>().toSet(),
        "google": (data["google"] ?? []).cast<String>().toSet(),
        "outlook": (data["outlook"] ?? []).cast<String>().toSet(),
      };
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
    final storedFromCalendars = _mybox.get("VIEW_ONLY_CALENDARS");
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
    final storedLocalCalTasks = _mybox.get("LOCAL_CAL_TASKS");
    if (storedLocalCalTasks is List) {
      localCalTasks =
          storedLocalCalTasks.map((item) => item as List<dynamic>).toList();
    }
    final storedGoogleCalTasks = _mybox.get("GOOGLE_CAL_TASKS");
    if (storedGoogleCalTasks is List) {
      googleCalTasks =
          storedGoogleCalTasks.map((item) => item as List<dynamic>).toList();
    }
    final storedOutlookCalTasks = _mybox.get("OUTLOOK_CAL_TASKS");
    if (storedOutlookCalTasks is List) {
      outlookCalTasks =
          storedOutlookCalTasks.map((item) => item as List<dynamic>).toList();
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
    _mybox.put("VIEW_ONLY_CALENDARS", hiveviewOnlyCalendars);
    _mybox.put("SYNC_TO_CALENDARS", syncToCalendars);
    _mybox.put("LOCAL_CAL_TASKS", localCalTasks);
    _mybox.put("GOOGLE_CAL_TASKS", googleCalTasks);
    _mybox.put("OUTLOOK_CAL_TASKS", outlookCalTasks);
    _mybox.put("SETTINGS", settings);
    _mybox.put("ACCOUNT", accountDetails);

    print("🗄️ Database updated");
    print("viewOnlyCalendars (in-memory Sets): $viewOnlyCalendars");
    print("viewOnlyCalendars (Hive Lists): $hiveviewOnlyCalendars");
    print(toDoList);
    print("✅local ===> $localCalTasks");
    print("✅google===> $googleCalTasks");
    print("✅outlook===> $outlookCalTasks");
  }
}
