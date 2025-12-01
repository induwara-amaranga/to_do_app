import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/data/database.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_app/utils/date_time_utils.dart';

final _uuid = Uuid();

class GoogleCalendarService {
  //static const _scopes = [gcal.CalendarApi.calendarScope];
  static gcal.CalendarApi? _calendarApi;
  //static AuthClient? _client;
  static Map<String, String>? headers;
  static GoogleSignInAccount? _account;
  static final storage = FlutterSecureStorage();

  static const webClientId =
      '879200055223-f40a49a8tvse1ca2sngrudqh8r5f3ccg.apps.googleusercontent.com';
  static const androidClientId =
      '879200055223-ber902b42l2nh4bbg43kuvs3tq41dd9i.apps.googleusercontent.com';

  // /// Signs in with Google → authenticates Supabase → returns Calendar API client
  // static Future<gcal.CalendarApi?> initializeSignIn() async {
  //   print("🔄 Initializing Google Sign-In...");

  //   final GoogleSignIn signIn = GoogleSignIn.instance;

  //   // Initialize Google Sign-In
  //   unawaited(
  //     signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
  //   );

  //   // 🔐 Perform the sign-in
  //   final googleAccount = await signIn.authenticate(
  //     scopeHint: ['https://www.googleapis.com/auth/calendar'],
  //   );

  //   if (googleAccount == null) {
  //     print('❌ Sign-in cancelled by user.');
  //     return null;
  //   }

  //   // Request authorization for Calendar scope
  //   final googleAuthorization = await googleAccount.authorizationClient
  //       .authorizationForScopes(['https://www.googleapis.com/auth/calendar']);
  //   if (googleAuthorization == null) return null;

  //   final googleAuth = await googleAccount.authentication;

  //   final idToken = googleAuth.idToken;
  //   final accessToken = googleAuthorization.accessToken;

  //   if (idToken == null || accessToken == null) {
  //     print('❌ Missing tokens.');
  //     return null;
  //   }

  //   // 🔗 Sign in to Supabase
  //   final response = await Supabase.instance.client.auth.signInWithIdToken(
  //     provider: OAuthProvider.google,
  //     idToken: idToken,
  //     accessToken: accessToken,
  //   );

  //   print('✅ Signed in to Supabase successfully as ${googleAccount.email}');
  //   print('🔑 Access Token: $accessToken');

  //   // 📆 Initialize Google Calendar API
  //   final calendarApi = await _getCalendarApi(accessToken);

  //   print('✅ Google Calendar API ready');
  //   return calendarApi;
  // }

  // /// Helper: build an authenticated Google Calendar API client
  // static Future<gcal.CalendarApi> _getCalendarApi(String accessToken) async {
  //   final authClient = authenticatedClient(
  //     http.Client(),
  //     AccessCredentials(
  //       AccessToken(
  //         'Bearer',
  //         accessToken,
  //         DateTime.now().toUtc().add(const Duration(hours: 1)),
  //       ),
  //       null,
  //       [gcal.CalendarApi.calendarScope],
  //     ),
  //   );
  //   return gcal.CalendarApi(authClient);
  // }

  static Future<bool> restoreLastSession() async {
    print("🔄 Trying to restore previous Google session...");

    String? auth = await storage.read(key: 'google_cal_headers');

    if (auth == null) {
      print("❌ No stored token. User must sign in once.");
      return false;
    }
    Map<String, dynamic> header = jsonDecode(auth);

    //final headers = {'Authorization': auth, 'X-Goog-AuthUser': '0'};

    try {
      _calendarApi = await getCalendarApi(header.cast<String, String>());

      //_driveApi = drive.DriveApi(client);

      // test token
      //await _driveApi!.files.list(pageSize: 1);

      print("✅ Restored calendar session without sign-in!");
      return true;
    } catch (e) {
      print("❌ Saved token expired: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> initializeSignIn() async {
    print("initializing google sign in...");

    // 1️⃣ Initialize GoogleSignIn
    await GoogleSignIn.instance.initialize(
      clientId: androidClientId,
      serverClientId: webClientId,
    );

    GoogleSignInAccount? account;

    // 2️⃣ Attempt SILENT sign-in first
    print("Trying silent sign-in...");
    account = await GoogleSignIn.instance.attemptLightweightAuthentication();

    if (account != null) {
      print("✅ Silent sign-in success: ${account.email}");
    } else {
      print("❌ Silent sign-in failed, asking user to sign in...");
      // 3️⃣ Fallback to UI sign-in
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['https://www.googleapis.com/auth/calendar'],
      );
    }

    // 4️⃣ Now request OAuth headers (tokens)
    print("Requesting OAuth headers...");
    var headers = await account.authorizationClient.authorizationHeaders(
      ['https://www.googleapis.com/auth/calendar'],
      promptIfNecessary: false, // silent permission request
    );

    // 5️⃣ If tokens are null, ask for permission with popup
    if (headers == null) {
      print("Silent header generation failed — requesting user consent...");
      headers = await account.authorizationClient.authorizationHeaders([
        'https://www.googleapis.com/auth/calendar',
      ], promptIfNecessary: true);
    }

    // 6️⃣ If STILL no headers → fail
    if (headers == null) {
      print("❌ Failed to obtain OAuth headers");
      return null;
    }
    await storage.write(key: 'google_cal_headers', value: jsonEncode(headers));

    print('🔑 Access token: ${headers['Authorization']}');

    // 7️⃣ Build Calendar API
    final gcal.CalendarApi calendarApi = await getCalendarApi(headers);
    print('✅ Google Calendar API initialized');

    _calendarApi = calendarApi;
    _account = account;

    return {"api": calendarApi, "userName": account.displayName};
  }

  // /// Use this for signed-in user authentication (via Google Sign-In)
  // static Future<void> fromAccessCredentials(
  //   AccessCredentials credentials,
  // ) async {
  //   final client = authenticatedClient(http.Client(), credentials);
  //   await initialize(client);
  // }

  /// Get user's Google calendars

  static Future<gcal.CalendarApi> getCalendarApi(
    Map<String, String> headers,
  ) async {
    final authClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          headers['Authorization']!.replaceFirst('Bearer ', ''),
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [gcal.CalendarApi.calendarScope],
      ),
    );

    return gcal.CalendarApi(authClient);
  }

  /// Get events for a given calendar
  static Future<List<gcal.Event>> getEvents(String calendarId) async {
    _requireInit();
    final now = DateTime.now();
    final result = await _calendarApi!.events.list(
      calendarId,
      timeMin: now.subtract(const Duration(days: 60)).toUtc(),
      timeMax: now.add(const Duration(days: 60)).toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );
    return result.items ?? [];
  }

  /// Add or update a Google Calendar event from a google task
  static Future<void> addOrUpdateEvent(
    String calendarId,
    List<dynamic> task,
  ) async {
    _requireInit();

    try {
      final dueDate = DateTimeUtilsHelper.parseDate(task[3]);
      final dueTime = DateTimeUtilsHelper.parseTime(task[4]);
      if (dueDate == null) return;

      final start = DateTimeUtilsHelper.combineDateAndTime(
        dueDate,
        dueTime ?? DateTime(0),
      );
      final end = start.add(const Duration(minutes: 30));
      // final exists = events.cast<Event?>().firstWhere((e) {
      //   print(
      //     "${e?.eventId} and -> ${task[16]}  ${e != null && e.eventId == task[16]}",
      //   );
      //   return e != null && e.eventId == task[16];
      // }, orElse: () => null);

      // if (exists != null) {
      //   event.eventId = exists.eventId;
      //   print("event ${event.title} already exists");
      //   return;
      // }
      // print("id ${event.eventId}");
      final events = await getEvents(calendarId);

      final exists = events.cast<gcal.Event?>().firstWhere((e) {
        print("${e?.id} and -> ${task[16]}  ${e != null && e.id == task[16]}");
        return e != null && e.id == task[16];
      }, orElse: () => null);

      if (exists != null) {
        print("event ${task[0]} already exists");
        final event = gcal.Event(
          summary: task[0] ?? 'Untitled Task',
          description: task[2] ?? '',
          start: gcal.EventDateTime(dateTime: start.toUtc(), timeZone: 'UTC'),
          end: gcal.EventDateTime(dateTime: end.toUtc(), timeZone: 'UTC'),
          //id: task.length > 16 ? task[16] : null,
        );
        final result = await _calendarApi!.events.patch(
          event,
          calendarId,
          exists.id!,
          sendUpdates: "all", // "none", "externalOnly", "all"
        );

        //event.eventId = exists.id;
        print('✅ editted event: ${result.summary}');
        return;
      }
      //print("id ${event.eventId}");

      final event = gcal.Event(
        summary: task[0] ?? 'Untitled Task',
        description: task[2] ?? '',
        start: gcal.EventDateTime(dateTime: start.toUtc(), timeZone: 'UTC'),
        end: gcal.EventDateTime(dateTime: end.toUtc(), timeZone: 'UTC'),
        //id: task.length > 16 ? task[16] : null,
      );

      // if (task.length > 16 && task[16] != null) {
      //   event.id = task[16];
      // }

      final created = await _calendarApi!.events.insert(event, calendarId);
      print('✅ inserted event: ${created.summary}');
      task[16] = created.id;
    } catch (e, st) {
      print('❌ Error adding/updating Google event: $e');
      print(st);
    }
  }

  /// Delete a Google Calendar event
  static Future<void> deleteEvent(String calendarId, String eventId) async {
    _requireInit();
    try {
      await _calendarApi!.events.delete(calendarId, eventId);
      print('🗑️ Deleted event: $eventId');
    } catch (e) {
      print('❌ Error deleting Google event: $e');
    }
  }

  /// Import events from Google Calendar into google DB
  static Future<void> importEventsToDB(
    String calendarId,
    ToDoDataBase db,
  ) async {
    int updatedCount = 0;
    int importedCount = 0;
    _requireInit();
    final events = await getEvents(calendarId);
    print('🔁 Importing ${events.length} Google events');

    for (final e in events) {
      if (e.start?.dateTime == null) continue;

      final start = e.start!.dateTime ?? e.start!.date?.toUtc();
      //print("==========$start");
      final dueDate = start!.toIso8601String().split('T')[0];
      final dueTime = start.toIso8601String().split('T')[1].split('.')[0];

      final existingIndex = db.toDoList.indexWhere(
        (t) => t[15] == e.id && t[14] == calendarId,
      );
      if (existingIndex != -1) {
        db.toDoList[existingIndex][0] = e.summary ?? 'Untitled Event';
        db.toDoList[existingIndex][2] = e.description ?? '';
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
        //continue;
        continue;
      }
      ;

      db.toDoList.add([
        e.summary ?? 'Untitled Event', //0
        false, //1
        e.description ?? '', //2
        dueDate, //3
        dueTime, //4
        'None', //5
        'Low', //6
        'none', //7
        10, //8
        'none', //9
        false, //10
        DateTime.now().toUtc().toString(), //11
        _uuid.v4(), //12
        [], //13
        calendarId, //14
        e.id, //15
        e.id, //16
        _account?.displayName ?? 'google',
      ]);

      importedCount++;
    }

    db.updateDataBase();
    db.loadData();
    print(
      '✅ Imported $importedCount events into google DB.updated $updatedCount events.',
    );
  }

  /// Import a list of view-only events into the google DB
  static Future<void> importViewOnlyEventsToDB(
    List<dynamic>? events,
    ToDoDataBase db,
  ) async {
    print('----------------- Importing view-only events -----------------');
    if (events == null || events.isEmpty) {
      print('No events to import.');
      return;
    }

    int importedCount = 0;
    int updatedCount = 0;

    for (final event in events) {
      if (event.start == null) continue;

      // Parse start time
      // DateTime? start;
      // if (event.start != null) {
      //   start = event.start!.dateTime ?? event.start!.date?.toLocal();
      // }
      // if (start == null) continue; // skip if we can't get a start time

      final startRaw = event.start!.dateTime ?? event.start!.date?.toLocal();
      DateTime start = DateTimeUtilsHelper.toUtcUsingLocal(startRaw);
      final parts = start.toIso8601String().split('T');
      final dueDate = parts.first;
      final dueTime = parts.length > 1 ? parts[1].split('.')[0] : '00:00:00';

      // Safe access for calendarId and eventId
      final calendarId = event.organizer?.email ?? 'unknown_calendar';
      final eventId =
          event.id ?? _uuid.v4(); // fallback to uuid if event.id missing

      final taskDetails = {
        'taskName': event.summary ?? 'Untitled Event',
        'taskNote': event.description ?? '',
        'dueDate': dueDate,
        'dueTime': dueTime,
        'taskCategory': 'None',
        'taskPriority': 'Low',
        'repeatType': 'none',
        'remainderAmount': 10,
        'remainderType': 'none',
        'isStarred': false,
        'createdAt': DateTime.now().toUtc().toString(),
        'subTasks': [],
        'calendarId': calendarId,
        'eventId': eventId,
      };

      // Check if event already exists in DB
      final existingIndex = db.calTasks.indexWhere(
        (task) =>
            task.length > 15 &&
            ((task[14] == calendarId && task[15] == event.id) ||
                task[16] == event.id),
      );

      final combined = DateTimeUtilsHelper.combineDateAndTime(
        DateTimeUtilsHelper.parseDate(taskDetails['dueDate']),
        DateTimeUtilsHelper.parseDate(taskDetails['dueTime']),
      );
      final utcTime = DateTimeUtilsHelper.toUtcUsingLocal(combined);

      if (existingIndex != -1) {
        // Update existing task
        db.calTasks[existingIndex][0] = taskDetails['taskName'];
        db.calTasks[existingIndex][2] = taskDetails['taskNote'];
        db.calTasks[existingIndex][3] = DateTimeUtilsHelper.formatDate(utcTime);
        db.calTasks[existingIndex][4] = DateTimeUtilsHelper.formatTime(utcTime);
        db.calTasks[existingIndex][5] = taskDetails['taskCategory'];
        db.calTasks[existingIndex][6] = taskDetails['taskPriority'];
        db.calTasks[existingIndex][7] = taskDetails['repeatType'];
        db.calTasks[existingIndex][8] = taskDetails['remainderAmount'];
        db.calTasks[existingIndex][9] = taskDetails['remainderType'];
        db.calTasks[existingIndex][10] = taskDetails['isStarred'];
        db.calTasks[existingIndex][13] = taskDetails['subTasks'];
        updatedCount++;
        print('✏️ Updated existing task: ${event.summary}');
        continue;
      }
      print("existing = $existingIndex");

      // Add new task
      db.calTasks.add([
        taskDetails['taskName'],
        false,
        taskDetails['taskNote'],
        DateTimeUtilsHelper.formatDate(utcTime),
        DateTimeUtilsHelper.formatTime(utcTime),
        taskDetails['taskCategory'],
        taskDetails['taskPriority'],
        taskDetails['repeatType'],
        taskDetails['remainderAmount'],
        taskDetails['remainderType'],
        taskDetails['isStarred'],
        taskDetails['createdAt'],
        _uuid.v4(),
        taskDetails['subTasks'],
        taskDetails['calendarId'],
        taskDetails['eventId'],
        taskDetails['eventId'],
        //false,
      ]);

      importedCount++;
      print('➕ Added new task: ${event.summary}');
    }

    db.updateDataBase();
    db.loadData();

    print(
      '✅ Imported $importedCount new events, updated $updatedCount existing ones.',
    );
  }

  // /// Sync google tasks → Google Calendar
  // static Future<void> syncTasksToGoogle(
  //   ToDoDataBase db,
  //   String calendarId,
  // ) async {
  //   _requireInit();
  //   int count = 0;
  //   for (final task in List.from(db.toDoList)) {
  //     await addOrUpdateEvent(calendarId, task);
  //     count++;
  //   }
  //   print('📤 Synced $count tasks to Google Calendar');
  // }

  /// Helper to ensure initialization
  static void _requireInit() {
    if (_calendarApi == null) {
      throw Exception(
        '❌ GoogleCalendarService not initialized. Call initialize() first.',
      );
    }
  }

  /// Create or get a Google Calendar by name
  static Future<gcal.Calendar?> createOrGetCalendar(
    List<gcal.CalendarListEntry> calendarList,
  ) async {
    _requireInit();

    try {
      // 1️⃣ List all existing calendars
      // final calendarList = await _calendarApi!.calendarList.list();

      // 2️⃣ Check if a calendar with the same name already exists
      final existing = calendarList.firstWhere(
        (c) => c.summary?.toLowerCase() == "ToDoList".toLowerCase(),
        orElse: () => gcal.CalendarListEntry(),
      );
      //existing=calendarFromListEntry

      if (existing.id != null) {
        print('✅ Calendar "ToDoList" already exists');
        return calendarFromListEntry(existing);
      }

      // 3️⃣ If not found, create a new calendar
      final newCalendar =
          gcal.Calendar()
            ..summary = "ToDoList"
            ..timeZone = 'UTC'; // adjust timezone if needed

      final createdCalendar = await _calendarApi!.calendars.insert(newCalendar);
      print('✅ Created new calendar: ${createdCalendar.summary}');

      // 4️⃣ Optionally add it to calendar list (so it shows up in UI)
      await _calendarApi!.calendarList.insert(
        gcal.CalendarListEntry(id: createdCalendar.id),
      );

      return gcal.Calendar(
        id: createdCalendar.id,
        summary: createdCalendar.summary,
        timeZone: createdCalendar.timeZone,
      );
    } catch (e, st) {
      print('❌ Error creating/getting calendar: $e');
      print(st);
      return null;
    }
  }

  static gcal.Calendar calendarFromListEntry(gcal.CalendarListEntry entry) {
    return gcal.Calendar()
      ..id = entry.id
      ..summary = entry.summary
      ..description = entry.description
      ..timeZone = entry.timeZone ?? 'UTC';
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
        print('❌ Failed to sync ${calendarID} "${task[0]}".');
      }
    }
    print("📅 $count tasks added to google calendar");
  }

  static Future<void> syncTasksFromCalendars(ToDoDataBase db) async {
    print("sync from------------------------------");
    final calID = db.syncToCalendars["google"];
    db.calTasks.removeWhere((t) => t[14] == calID);
    List<dynamic> events = await getEvents(calID);
    try {
      await importViewOnlyEventsToDB(events, db);
    } catch (e) {
      print("Sync from error $e");
    }
  }
}
