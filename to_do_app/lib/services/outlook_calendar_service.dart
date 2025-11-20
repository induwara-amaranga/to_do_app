//import 'package:msal_flutter/msal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:msal_auth/msal_auth.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class OutlookCalendarService {
  static const _clientId = '6450d522-3a1c-4005-ae93-1fdc7f91aea2';
  static const _redirectUri =
      "msauth://com.example.to_do_app/Oust7aZi9rTbGkNnTUHkeg3V6WQ%3D";
  static const _scopes = ['User.Read', 'Calendars.ReadWrite'];

  //static late PublicClientApplication _pca;
  static String? _accessToken;

  static late SingleAccountPca _pca;

  static Future<void> init() async {
    try {
      _pca = await SingleAccountPca.create(
        clientId: _clientId,
        androidConfig: AndroidConfig(
          configFilePath: 'assets/msal_config.json',
          redirectUri: _redirectUri,
        ),
      );
    } catch (e) {
      print("❌init error: $e");
    }
  }

  static Future<String?> signIn() async {
    try {
      //await _pca.signOut();
      final result = await _pca.acquireToken(
        scopes: [
          'https://graph.microsoft.com/User.Read',
          'https://graph.microsoft.com/Calendars.ReadWrite',
        ],
        prompt: Prompt.login,
      );

      print('Access Token: ${result.accessToken}');
      return result.accessToken;
    } catch (e) {
      print("❌sign in error $e");
    }
  }

  static Future<bool> initialize() async {
    // _pca = await PublicClientApplication.createPublicClientApplication(
    //   _clientId,
    //   authority:
    //       "https://login.microsoftonline.com/common", // use your tenant if needed
    // );
    // print("getting token....");
    try {
      //   final result = await _pca.acquireToken(_scopes);
      //   _accessToken = result;

      // final msalAuth = await SingleAccountPca.create(
      //   clientId: _clientId,
      //   androidConfig: AndroidConfig(
      //     configFilePath: 'assets/msal_config.json',
      //     redirectUri: _redirectUri,
      //   ),
      //   appleConfig: AppleConfig(
      //     authority: '<Optional, but must be provided for b2c>',
      //     // Change authority type to 'b2c' for business to customer flow.
      //     authorityType: AuthorityType.aad,
      //     // Change broker if you need. Applicable only for iOS platform.
      //     broker: Broker.msAuthenticator,
      //   ),
      // );
      await init();
      _accessToken = await signIn();
      print("✅ Access Token: $_accessToken");
      return true;
    } catch (e) {
      print("❌ Sign-in failed: $e");
      return false;
    }
    //return true;
  }

  /// 🔹 Create or get a calendar named "ToDoList"
  static Future<Map<String, dynamic>?> createOrGetCalendar(
    List<Map<String, dynamic>> calendars,
  ) async {
    if (_accessToken == null) throw Exception('Not signed in');

    // 1️⃣ Fetch all calendars
    //final calendars = await getAllCalendars();

    // 2️⃣ Check if "ToDoList" calendar already exists
    final existing = calendars.firstWhere(
      (c) => (c['name'] as String?)?.toLowerCase() == 'todolist',
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      print('✅ Calendar "ToDoList" already exists: ${existing['id']}');
      return existing;
    }

    // 3️⃣ Create a new calendar
    final url = Uri.parse("https://graph.microsoft.com/v1.0/me/calendars");
    final body = jsonEncode({
      "name": "ToDoList",
      "color": "auto", // optional, can choose any color
    });

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $_accessToken",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final newCalendar = jsonDecode(response.body);
      print('✅ Created new calendar "ToDoList": ${newCalendar['id']}');
      calendars.add(newCalendar);
      return newCalendar;
    } else {
      print("❌ Failed to create calendar: ${response.body}");
      return null;
    }
  }

  /// 🔹 Get all Outlook calendars for the signed-in user
  static Future<List<Map<String, dynamic>>> getAllCalendars() async {
    if (_accessToken == null) throw Exception('Not signed in');

    final url = Uri.parse("https://graph.microsoft.com/v1.0/me/calendars");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List calendars = data['value'];

      print("📅 Found ${calendars.length} Outlook calendars");
      for (final c in calendars) {
        print("- ${c['name']} (${c['id']})");
      }

      return calendars.cast<Map<String, dynamic>>();
    } else {
      print("❌ Error fetching calendars: ${response.body}");
      return [];
    }
  }

  /// 🔹 Get events from a specific calendar
  static Future<List<Map<String, dynamic>>> getCalendarEvents(
    String calendarId,
  ) async {
    if (_accessToken == null) throw Exception('Not signed in');

    final url = Uri.parse(
      "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events",
    );
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['value']);
    } else {
      print("❌ Error fetching events: ${response.body}");
      return [];
    }
  }

  /// 🔹 Delete an event from a specific calendar
  static Future<bool> deleteEvent(String calendarId, String eventId) async {
    if (_accessToken == null) throw Exception('Not signed in');

    final url = Uri.parse(
      "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events/$eventId",
    );

    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode == 204) {
      print("🗑️ Event deleted successfully: $eventId");
      return true;
    } else {
      print(
        "❌ Failed to delete event: ${response.statusCode} — ${response.body}",
      );
      return false;
    }
  }

  /// 🔹 Add a new event or update an existing one in a calendar
  static Future<void> addOrUpdateEvent(
    String calendarId,
    List<dynamic> eventData,
  ) async {
    if (_accessToken == null) throw Exception('Not signed in');

    final String? eventId = eventData[16];

    // If event ID is provided → check if it exists
    bool exists = false;
    if (eventId != null) {
      print("Checking if event exists: $eventId");
      final checkUrl = Uri.parse(
        "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events/$eventId",
      );

      final checkResponse = await http.get(
        checkUrl,
        headers: {"Authorization": "Bearer $_accessToken"},
      );

      if (checkResponse.statusCode == 200) {
        final data = jsonDecode(checkResponse.body);
        print("Event data fetched for existence check: $data");
        // Verify that the event actually belongs to your target calendar
        if (data['id'] == eventId) {
          exists = true;
        }
      }
    }
    String start = "";
    String end = "";
    try {
      print("Preparing to add/update event: ${eventData[0]}");
      start =
          DateTimeUtilsHelper.combineDateAndTimeFromStrings(
            eventData[3],
            eventData[4],
          ).toIso8601String();
      end =
          DateTimeUtilsHelper.combineDateAndTimeFromStrings(
            eventData[3],
            eventData[4],
          ).add(Duration(hours: 1)).toIso8601String();
      print("Start time: $start");
      print("End time: $end");
    } catch (e) {
      print("date time error: $e");
    }
    // 1️⃣ Build event JSON body (example mapping)
    final Map<String, dynamic> eventBody = {
      "subject": eventData[0],
      "body": {"contentType": "HTML", "content": "Weekly status update"},
      "start": {"dateTime": start, "timeZone": "UTC"},
      "end": {"dateTime": end, "timeZone": "UTC"},
    };

    if (exists) {
      print("Updating existing event: $eventId");
      // 🔄 Update existing event
      final updateUrl = Uri.parse(
        "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events/$eventId",
      );

      final response = await http.patch(
        updateUrl,
        headers: {
          "Authorization": "Bearer $_accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(eventBody),
      );

      if (response.statusCode == 200) {
        print("✅ Event updated successfully: $eventId");
        eventData[16] = jsonDecode(response.body)['id'];
      } else {
        print(
          "❌ Failed to update event: ${response.statusCode} — ${response.body}",
        );
      }
    } else {
      //Print();
      print("Creating new event");
      // ➕ Create new event
      final createUrl = Uri.parse(
        "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events",
      );

      final response = await http.post(
        createUrl,
        headers: {
          "Authorization": "Bearer $_accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(eventBody),
      );

      if (response.statusCode == 201) {
        print("✅ New event created successfully");
        eventData[16] = jsonDecode(response.body)['id'];
      } else {
        print(
          "❌ Failed to create event: ${response.statusCode} — ${response.body}",
        );
      }
    }
  }

  /// 🔹 Import Outlook calendar events into local ToDo database
  static Future<void> importEventsToDB(
    String calendarId,
    ToDoDataBase db,
  ) async {
    if (_accessToken == null) throw Exception('Not signed in');

    print('🔁 Fetching events from Outlook calendar: $calendarId');

    // Microsoft Graph endpoint
    final url = Uri.parse(
      "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode != 200) {
      print('❌ Failed to fetch Outlook events: ${response.body}');
      return;
    }

    final data = jsonDecode(response.body);
    final events = List<Map<String, dynamic>>.from(data['value']);
    print('📅 Found ${events.length} events in Outlook');

    int importedCount = 0;
    int updatedCount = 0;

    for (final e in events) {
      if (e['start'] == null) continue;

      final startRaw = e['start']['dateTime'];
      if (startRaw == null) continue;

      // Convert start time to DateTime
      final start = DateTime.parse(startRaw).toLocal();
      final dueDate = DateTimeUtilsHelper.formatDate(start);
      final dueTime = DateTimeUtilsHelper.formatTime(start);

      final eventId = e['id'] ?? _uuid.v4();

      // Check if already exists in DB
      final existingIndex = db.toDoList.indexWhere(
        (t) => t.length > 15 && t[15] == eventId && t[14] == calendarId,
      );

      if (existingIndex != -1) {
        // ✏️ Update existing record
        db.toDoList[existingIndex][0] = e['subject'] ?? 'Untitled Event';
        db.toDoList[existingIndex][2] = e['bodyPreview'] ?? '';
        db.toDoList[existingIndex][3] = dueDate;
        db.toDoList[existingIndex][4] = dueTime;
        db.toDoList[existingIndex][5] = 'None';
        db.toDoList[existingIndex][6] = 'Low';
        db.toDoList[existingIndex][7] = 'none';
        db.toDoList[existingIndex][8] = 10;
        db.toDoList[existingIndex][9] = 'none';
        db.toDoList[existingIndex][10] = false;
        db.toDoList[existingIndex][13] = [];
        updatedCount++;
        continue;
      }

      // ➕ Add new record
      db.toDoList.add([
        e['subject'] ?? 'Untitled Event', // 0: taskName
        false, // 1: isCompleted
        e['bodyPreview'] ?? '', // 2: note
        dueDate, // 3
        dueTime, // 4
        'None', // 5: category
        'Low', // 6: priority
        'none', // 7: repeat
        10, // 8: reminder amount
        'none', // 9: reminder type
        false, // 10: starred
        DateTime.now().toUtc().toString(), // 11: createdAt
        _uuid.v4(), // 12: internal ID
        [], // 13: subTasks
        calendarId, // 14
        eventId, // 15
        eventId, // 16 duplicate id for consistency
        //false, // 17 placeholder
      ]);
      importedCount++;
    }

    db.updateDataBase();
    db.loadData();

    print(
      '✅ Imported $importedCount new events, updated $updatedCount existing ones.',
    );
  }

  /// (Optional) Setter for access token from login
  static void setAccessToken(String token) {
    _accessToken = token;
  }

  /// 🔹 Import view-only Outlook events (no editing)
  static Future<void> importViewOnlyEventsToDB(
    String calendarId,
    ToDoDataBase db,
  ) async {
    if (_accessToken == null) throw Exception('Not signed in');

    print('📥 Importing view-only events from Outlook calendar: $calendarId');

    // Fetch events
    final url = Uri.parse(
      "https://graph.microsoft.com/v1.0/me/calendars/$calendarId/events",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode != 200) {
      print('❌ Failed to fetch view-only events: ${response.body}');
      return;
    }

    final data = jsonDecode(response.body);
    final events = List<Map<String, dynamic>>.from(data['value']);

    print('📅 Found ${events.length} view-only events.');

    int importedCount = 0;
    int updatedCount = 0;

    for (final e in events) {
      if (e['start'] == null) continue;

      final startRaw = e['start']['dateTime'];
      print('Event start raw: $startRaw');
      if (startRaw == null) continue;

      final start = DateTime.parse(startRaw).toLocal();
      final dueDate = DateTimeUtilsHelper.formatDate(start);
      final dueTime = DateTimeUtilsHelper.formatTime(start);

      final eventId = e['id'] ?? _uuid.v4();

      // Check if already in DB (to avoid duplicates)
      // final alreadyExists = db.calTasks.any(
      //   (t) =>
      //       t.length > 15 &&
      //       ((t[15] == eventId && t[14] == calendarId) || t[16] == eventId),
      // );
      // Check if already exists in DB
      final existingIndex = db.toDoList.indexWhere(
        (t) =>
            t.length > 15 &&
            ((t[15] == eventId && t[14] == calendarId) || t[16] == eventId),
      );

      if (existingIndex != -1) {
        // ✏️ Update existing record
        db.calTasks[existingIndex][0] = e['subject'] ?? 'Untitled Event';
        db.calTasks[existingIndex][2] = e['bodyPreview'] ?? '';
        db.calTasks[existingIndex][3] = dueDate;
        db.calTasks[existingIndex][4] = dueTime;
        db.calTasks[existingIndex][5] = 'None';
        db.calTasks[existingIndex][6] = 'Low';
        db.calTasks[existingIndex][7] = 'none';
        db.calTasks[existingIndex][8] = 10;
        db.calTasks[existingIndex][9] = 'none';
        db.calTasks[existingIndex][10] = false;
        db.calTasks[existingIndex][13] = [];
        updatedCount++;
        continue;
      }

      // ➕ Add as read-only event (marked so user knows it’s not editable)
      db.calTasks.add([
        e['subject'] ?? 'Untitled Event', // 0: taskName
        false, // 1: isCompleted
        e['bodyPreview'] ?? '', // 2: note
        dueDate, // 3
        dueTime, // 4
        'View Only', // 5: category
        'Low', // 6: priority
        'none', // 7: repeat
        10, // 8: reminder
        'none', // 9: reminder type
        false, // 10: starred
        DateTime.now().toUtc().toString(), // 11: createdAt
        _uuid.v4(), // 12: internal ID
        [], // 13: subTasks
        calendarId, // 14
        eventId, // 15: Outlook event ID
        eventId, // 16: duplicate for consistency
        //true, // 17: mark as read-only
      ]);

      importedCount++;
    }

    db.updateDataBase();
    db.loadData();

    print(
      '✅ Imported $importedCount view-only events, updated $updatedCount existing ones.',
    );
  }

  static Future<void> syncTasksToCalendar(
    ToDoDataBase db,
    String calendarID,
  ) async {
    print("Sync to ------------------------------------------------");
    int count = 0;
    //final calendar = await ensureToDoListCalendar();
    final tasksToSync = List.from(db.toDoList);
    for (var task in tasksToSync) {
      try {
        await addOrUpdateEvent(calendarID, task);
        count++;
      } catch (e) {
        print('❌ Failed to sync to ${calendarID} task :"${task[0]}".');
      }
    }
    print("📅 $count tasks added to outlook calendar");
  }

  static Future<void> syncFromCalendar(ToDoDataBase db) async {
    print("sync from------------------------------");
    final calID = db.syncToCalendars["outlook"];
    db.calTasks.removeWhere((t) => t[14] == calID);
    //List<dynamic> events = await getEvents(calID);
    try {
      await importViewOnlyEventsToDB(calID, db);
    } catch (e) {
      print("Sync from error $e");
    }
  }
}
