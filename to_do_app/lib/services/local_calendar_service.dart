import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar/device_calendar.dart' as tz;
import 'package:flutter/material.dart%20';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:uuid/uuid.dart';

final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin(
  shouldInitTimezone: false,
);
var uuid = Uuid();

class LocalCalendarService {
  static Future<bool> hasCalendarPermission() async {
    final r = await _deviceCalendarPlugin.hasPermissions();
    return r.isSuccess && r.data == true;
  }

  static Future<bool> requestCalendarPermission() async {
    final r = await _deviceCalendarPlugin.requestPermissions();
    return r.isSuccess && r.data == true;
  }

  static Future<List<Calendar>> getCalendars() async {
    try {
      // Request permissions if not granted
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (!permissionsGranted.isSuccess || permissionsGranted.data == false) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      }

      if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
        final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
        print('**Calendar permissions granted**');

        return calendarsResult.data ?? [];
      } else {
        print('**Calendar permissions not granted**');
      }
    } catch (e) {
      print('Error retrieving calendars: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getEvents(String? calendarId) async {
    if (calendarId == null) {
      return [];
    }
    final startDate = DateTime.now().subtract(const Duration(days: 60));
    final endDate = DateTime.now().add(const Duration(days: 60));

    final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(startDate: startDate, endDate: endDate),
    );

    final events = eventsResult.data ?? [];
    for (final event in events) {
      // print('Event: ${event.title} (${event.start})');
    }
    return events;
  }

  static Future<void> addEvent(String calendarId, List<dynamic> task) async {
    try {
      // Parse due date and time
      final dueDate = DateTimeUtilsHelper.parseDate(task[3]);
      final dueTime = DateTimeUtilsHelper.parseDate(task[4]);
      RecurrenceRule? recurrenceRule = _buildRecurrenceRule(task[7]);

      if (dueDate == null) {
        print('⚠️ Skipped: missing due date for ${task[0]}');
        return;
      }
      print(
        "${task[3]}  ,${task[4]}  ${DateTimeUtilsHelper.combineDateAndTime(DateTimeUtilsHelper.parseDate(task[3])!, DateTimeUtilsHelper.parseTime(task[4])!)}",
      );

      // Build start/end as TZDateTime
      final now = tz.TZDateTime.from(
        DateTime.now().subtract(const Duration(minutes: 15)),
        tz.local,
      );
      final startCombined = DateTimeUtilsHelper.combineDateAndTime(
        DateTimeUtilsHelper.parseDate(task[3])!,
        DateTimeUtilsHelper.parseTime(task[4])!,
      );

      final start = //start.add(const Duration(hours: 1));
          dueTime != null
              ? tz.TZDateTime.from(
                DateTimeUtilsHelper.toLocalUsingTz(startCombined),
                tz.local,
              )
              : now.add(const Duration(hours: 1));
      // Build end time 1 hour after start
      final end = start.add(const Duration(minutes: 30));

      if (!end.isAfter(start)) {
        print('⚠️ Adjusted end time for "${task[0]}"');
        end.add(const Duration(minutes: 30));
      }

      final event = Event(
        calendarId,
        title: task[0] ?? 'Untitled Task',
        description: task[2] ?? '',
        start: start,
        end: end,
        eventId: task[16][0],
        recurrenceRule: recurrenceRule,
      );
      print('event${event.start} ${event.end}');

      // 1️⃣ Retrieve events in a small window around this time
      final events = await LocalCalendarService.getEvents(calendarId);
      //final events = eventsResult.data ?? [];
      // for (var event in events) {
      //   print("${event.eventId}  ${event.title}");
      // }

      // 2️⃣ Check if an event with the same title and start time exists
      // 2️⃣ Check if an event with the same ID exists
      final exists = events.cast<Event?>().firstWhere((e) {
        print(
          "${e?.eventId} and -> ${task[16][0]}  ${e != null && e.eventId == task[16][0]}",
        );
        return e != null && e.eventId == task[16][0];
      }, orElse: () => null);

      if (exists != null) {
        event.eventId = exists.eventId;
        print("event ${event.title} already exists");
        //return;
        //return;
      } else {
        print("event ${event.title} does not exist, creating new one");
        event.eventId = null; // Ensure new event is created
      }
      print("id ${event.eventId}");

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (result!.isSuccess && result.data != null) {
        print(
          'local============>✅ Event ${task[0]} created or edited:  ${result.data}',
        );
        task[16][0] = result.data;
      } else {
        print(
          '❌ Failed to create event.task=$task Success=${result.isSuccess}, '
          'Data=${result.data}, Errors=${result.errors.toString()}',
        );
        throw Exception(
          '❌ Failed to create event.task=$task Success=${result.isSuccess}, '
          'Data=${result.data}, Errors=${result.errors.toString()}',
        );
      }
    } catch (e, st) {
      //print('❌ Exception while creating event: $e task=$task ');
      print(st);
      throw Exception('❌ Exception while creating event: $e task=$task ');
    }
  }

  static Future<void> deleteEvent(String? eventId, String? calendarId) async {
    // print("deletde$eventId")
    final result = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);

    // 3️⃣ Handle result
    if (result.isSuccess && result.data == true) {
      print('✅ Event deleted successfully. id ${eventId}');
    } else {
      print('Failed to delete event.');
    }
  }

  // static Future<void> importCalendarEventsToDB(
  //   List<dynamic>? events,
  //   ToDoDataBase db,
  // ) async {
  //   print("-----------------importing----------------------");
  //   if (events == null || events.isEmpty) {
  //     print('No events to import.');
  //     return;
  //   }

  //   int importedCount = 0;
  //   for (final event in events) {
  //     if (event.start == null) continue;

  //     // Skip if this event already exists in toDoList
  //     final exists = db.toDoList.any(
  //       (task) =>
  //           task.length > 15 && // ensure extended structure
  //           task[14] == event.calendarId &&
  //           task[15] == event.eventId,
  //     );
  //     print("${event.title}   ${event.eventId}-cal ${event.calendarId}");

  //     if (exists) {
  //       print('⚠️ Skipped duplicate: ${event.title}');
  //       continue;
  //     }

  //     // Parse start time into date/time strings
  //     final start = event.start!;
  //     final parts = start.toIso8601String().split('T');
  //     final dueDate = parts.first;
  //     final dueTime = parts.length > 1 ? parts[1] : '00:00:00';

  //     final taskDetails = {
  //       'taskName': event.title ?? 'Untitled Event',
  //       'taskNote': event.description ?? '',
  //       'dueDate': dueDate,
  //       'dueTime': dueTime,
  //       'taskCategory': 'None',
  //       'taskPriority': 'Low',
  //       'repeatType': 'none',
  //       'remainderAmount': 10,
  //       'remainderType': 'none',
  //       'isStarred': false,
  //       'createdAt': DateTime.now().toIso8601String(),
  //       'subTasks': [],
  //       'calendarId': event.calendarId,
  //       'eventId': event.eventId,
  //     };

  //     db.toDoList.add([
  //       taskDetails['taskName'],
  //       false,
  //       taskDetails['taskNote'],
  //       taskDetails['dueDate'],
  //       taskDetails['dueTime'],
  //       taskDetails['taskCategory'],
  //       taskDetails['taskPriority'],
  //       taskDetails['repeatType'],
  //       taskDetails['remainderAmount'],
  //       taskDetails['remainderType'],
  //       taskDetails['isStarred'],
  //       taskDetails['createdAt'],
  //       uuid.v4(),
  //       taskDetails['subTasks'],
  //       taskDetails['calendarId'], // store calendar ID
  //       taskDetails['eventId'],
  //     ]);

  //     importedCount++;
  //   }

  //   db.updateDataBase();
  //   db.loadData();
  //   print('✅ Imported $importedCount new events into task list.');
  // }

  static Future<void> importCalendarEventsToDB(
    List<dynamic>? events,
    ToDoDataBase db,
  ) async {
    print("-----------------importing----------------------");
    if (events == null || events.isEmpty) {
      print('No events to import.');
      return;
    }

    int importedCount = 0;
    int updatedCount = 0;

    for (final event in events) {
      if (event.start == null) continue;

      // Parse start time into date/time strings
      final start = event.start!;
      final parts = start.toIso8601String().split('T');
      final dueDate = parts.first;
      final dueTime = parts.length > 1 ? parts[1] : '00:00:00';

      final taskDetails = {
        'taskName': event.title ?? 'Untitled Event',
        'taskNote': event.description ?? '',
        'dueDate': dueDate,
        'dueTime': dueTime,
        'taskCategory': 'None',
        'taskPriority': 'Low',
        'repeatType': _repeatTypeFromRule(event.recurrenceRule),
        'remainderAmount': 10,
        'remainderType': 'none',
        'isStarred': false,
        'createdAt': DateTime.now().toUtc().toString(),
        'subTasks': [],
        'calendarId': event.calendarId,
        'eventId': event.eventId,
      };

      // Find if this event already exists
      final existingIndex = db.toDoList.indexWhere((task) {
        // print(
        //   "${task[14]} == ${event.calendarId} && ${task[15]} == ${event.eventId}",
        // );

        return task.length > 15 &&
            (task[14] == event.calendarId && task[16][0] == event.eventId);
      });

      if (existingIndex != -1) {
        // Update existing task
        db.toDoList[existingIndex][0] = taskDetails['taskName'];
        db.toDoList[existingIndex][2] = taskDetails['taskNote'];
        db.toDoList[existingIndex][3] = taskDetails['dueDate'];
        db.toDoList[existingIndex][4] = taskDetails['dueTime'];
        db.toDoList[existingIndex][5] = taskDetails['taskCategory'];
        db.toDoList[existingIndex][6] = taskDetails['taskPriority'];
        db.toDoList[existingIndex][7] = taskDetails['repeatType'];
        db.toDoList[existingIndex][8] = taskDetails['remainderAmount'];
        db.toDoList[existingIndex][9] = taskDetails['remainderType'];
        db.toDoList[existingIndex][10] = taskDetails['isStarred'];
        db.toDoList[existingIndex][13] = taskDetails['subTasks'];
        updatedCount++;
        print('✏️ Updated existing task: ${event.title}');
        continue;
      }

      // Otherwise, add new task
      db.toDoList.add([
        taskDetails['taskName'],
        false,
        taskDetails['taskNote'],
        taskDetails['dueDate'],
        taskDetails['dueTime'],
        taskDetails['taskCategory'],
        taskDetails['taskPriority'],
        taskDetails['repeatType'],
        taskDetails['remainderAmount'],
        taskDetails['remainderType'],
        taskDetails['isStarred'],
        taskDetails['createdAt'],
        uuid.v4(),
        taskDetails['subTasks'],
        taskDetails['calendarId'], // store calendar ID
        taskDetails['eventId'],
        [taskDetails['eventId'], "", ""],
        "local calendar",
        "none", //18 completed at
        [],
      ]);

      importedCount++;
      print('➕ Added new task: ${event.title}');
    }

    await db.updateDataBase();
    print(
      '✅ Imported $importedCount new events, updated $updatedCount existing ones.',
    );
  }

  // static Future<void> importToDoCalendarEventsToDB(
  //   List<dynamic>? events,
  //   ToDoDataBase db,
  // ) async {
  //   print("-----------------importing----------------------");
  //   if (events == null || events.isEmpty) {
  //     print('No events to import.');
  //     return;
  //   }

  //   int importedCount = 0;
  //   int updatedCount = 0;

  //   for (final event in events) {
  //     if (event.start == null) continue;

  //     // Parse start time into date/time strings
  //     final _start = event.start!;
  //     print("start cal$_start");
  //     DateTime start = DateTimeUtilsHelper.toUtcUsingLocal(_start);
  //     start = DateTimeUtilsHelper.toUtcUsingLocal(start);
  //     print("Start utc $start");
  //     final parts = start.toIso8601String().split('T');
  //     final dueDate = parts.first;
  //     final dueTime = parts.length > 1 ? parts[1] : '00:00:00';

  //     final taskDetails = {
  //       'taskName': event.title ?? 'Untitled Event',
  //       'taskNote': event.description ?? '',
  //       'dueDate': dueDate,
  //       'dueTime': dueTime,
  //       'taskCategory': 'None',
  //       'taskPriority': 'Low',
  //       'repeatType': 'none',
  //       'remainderAmount': 10,
  //       'remainderType': 'none',
  //       'isStarred': false,
  //       'createdAt': DateTime.now().toUtc().toString(),
  //       'subTasks': [],
  //       'calendarId': event.calendarId,
  //       'eventId': event.eventId,
  //     };

  //     // Find if this event already exists
  //     final existingIndex = db.toDoList.indexWhere(
  //       (task) =>
  //           task.length > 15 &&
  //           task[14] == event.calendarId &&
  //           task[15] == event.eventId,
  //     );

  //     final combined = DateTimeUtilsHelper.combineDateAndTime(
  //       DateTimeUtilsHelper.parseDate(taskDetails['dueDate']),

  //       DateTimeUtilsHelper.parseDate(taskDetails['dueTime']),
  //     );
  //     final utcTime = DateTimeUtilsHelper.toUtcUsingLocal(combined);
  //     if (existingIndex != -1) {
  //       // Update existing task
  //       db.localCalTasks[existingIndex][0] = taskDetails['taskName'];
  //       db.localCalTasks[existingIndex][2] = taskDetails['taskNote'];
  //       db.localCalTasks[existingIndex][3] = DateTimeUtilsHelper.formatDate(utcTime);
  //       db.localCalTasks[existingIndex][4] = DateTimeUtilsHelper.formatTime(utcTime);
  //       db.localCalTasks[existingIndex][5] = taskDetails['taskCategory'];
  //       db.localCalTasks[existingIndex][6] = taskDetails['taskPriority'];
  //       db.localCalTasks[existingIndex][7] = taskDetails['repeatType'];
  //       db.localCalTasks[existingIndex][8] = taskDetails['remainderAmount'];
  //       db.localCalTasks[existingIndex][9] = taskDetails['remainderType'];
  //       db.localCalTasks[existingIndex][10] = taskDetails['isStarred'];
  //       db.localCalTasks[existingIndex][13] = taskDetails['subTasks'];
  //       updatedCount++;
  //       print('✏️ Updated existing task: ${event.title}');
  //       continue;
  //     }

  //     // Otherwise, add new task
  //     db.localCalTasks.add([
  //       taskDetails['taskName'],
  //       false,
  //       taskDetails['taskNote'],
  //       DateTimeUtilsHelper.formatDate(utcTime),
  //       DateTimeUtilsHelper.formatTime(utcTime),
  //       taskDetails['taskCategory'],
  //       taskDetails['taskPriority'],
  //       taskDetails['repeatType'],
  //       taskDetails['remainderAmount'],
  //       taskDetails['remainderType'],
  //       taskDetails['isStarred'],
  //       taskDetails['createdAt'],
  //       uuid.v4(),
  //       taskDetails['subTasks'],
  //       taskDetails['calendarId'], // store calendar ID
  //       taskDetails['eventId'],
  //       taskDetails['eventId'],
  //       false,
  //     ]);

  //     importedCount++;
  //     print('➕ Added new task: ${event.title}');
  //   }

  //   db.updateDataBase();
  //   db.loadData();
  //   print(
  //     '✅ Imported $importedCount new events, updated $updatedCount existing ones.',
  //   );
  // }

  static Future<Calendar> createNewCalendar(List<Calendar> calendars) async {
    // Get existing calendars

    // Check for existing “ToDoList” calendar
    final existing = calendars.firstWhere(
      (cal) => cal.name?.toLowerCase() == 'todolist',
      orElse: () => Calendar(id: ''),
    );

    if (existing.id != null && existing.id!.isNotEmpty) {
      return existing; // Already exists
    }

    // Create a new local calendar
    // final newCalendar = Calendar(
    //   name: 'ToDoList',
    //   isReadOnly: false,
    //   color: 0xFF2196F3, // blue
    //   accountName: 'ToDo App',
    // );

    final createResult = await _deviceCalendarPlugin.createCalendar(
      'ToDoList',
      calendarColor: Colors.red, // blue color
    );
    if (createResult.isSuccess && createResult.data != null) {
      // Retrieve the newly created calendar
      final created = (await getCalendars()).firstWhere(
        (cal) => cal.id == createResult.data,
      );
      return created;
    } else {
      throw Exception("Failed to create ToDoList calendar");
    }
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
      if (task[17] == "repeat") continue;
      try {
        await addEvent(calendarID, task);
        count++;
      } catch (e) {
        print('❌ Failed to sync(add) ${calendarID} "${task[0]}"  $e.');
      }
    }
    print("📅 $count tasks added/updated to local calendar");
  }

  static Future<void> syncTasksFromCalendar(ToDoDataBase db) async {
    print("sync from------------------------------");
    final calID = db.syncToCalendars["local"];
    //db.localCalTasks.removeWhere((t) => t[14] == calID);
    List<dynamic> events = await getEvents(calID);
    await importViewOnlyEventsToDB(events, db);
  }

  static Future<void> importViewOnlyEventsToDB(
    List<dynamic>? events,
    ToDoDataBase db,
  ) async {
    db.loadData();
    print("-----------------importing-view only---------------------");
    if (events == null || events.isEmpty) {
      print('No events to import.');
      return;
    }

    int importedCount = 0;
    int updatedCount = 0;

    // Recurring events expand into many instances with the same eventId.
    // Keep only the earliest instance per eventId so we import the start date.
    final Map<String, dynamic> earliestByEventId = {};
    for (final event in events) {
      if (event.start == null || event.eventId == null) continue;
      final existing = earliestByEventId[event.eventId];
      if (existing == null ||
          (event.start as DateTime).isBefore(existing.start as DateTime)) {
        earliestByEventId[event.eventId] = event;
      }
    }
    final deduplicatedEvents = earliestByEventId.values.toList();

    for (final event in deduplicatedEvents) {
      if (event.start == null) continue;

      // Convert event start to UTC; strip milliseconds/Z from time part
      final startUtc = DateTimeUtilsHelper.toUtcUsingLocal(event.start!);
      final isoParts = startUtc.toIso8601String().split('T');
      final dueDate = isoParts.first;
      final dueTime =
          isoParts.length > 1
              ? isoParts[1].split('.').first.replaceAll('Z', '')
              : '00:00:00';

      final taskDetails = {
        'taskName': event.title ?? 'Untitled Event',
        'taskNote': event.description ?? '',
        'dueDate': dueDate,
        'dueTime': dueTime,
        'taskCategory': 'None',
        'taskPriority': 'Low',
        'repeatType': _repeatTypeFromRule(event.recurrenceRule),
        'remainderAmount': 10,
        'remainderType': 'none',
        'isStarred': false,
        'createdAt': DateTime.now().toUtc().toString(),
        'subTasks': [],
        'calendarId': event.calendarId,
        'eventId': event.eventId,
      };

      // Find if this event already exists
      final existingIndex = db.localCalTasks.indexWhere(
        (task) => task.length > 15 && task[16] == event.eventId,
      );

      if (existingIndex != -1) {
        // Update existing task
        db.localCalTasks[existingIndex][0] = taskDetails['taskName'];
        db.localCalTasks[existingIndex][2] = taskDetails['taskNote'];
        db.localCalTasks[existingIndex][3] = dueDate;
        db.localCalTasks[existingIndex][4] = dueTime;
        db.localCalTasks[existingIndex][5] = taskDetails['taskCategory'];
        db.localCalTasks[existingIndex][6] = taskDetails['taskPriority'];
        db.localCalTasks[existingIndex][7] = taskDetails['repeatType'];
        db.localCalTasks[existingIndex][8] = taskDetails['remainderAmount'];
        db.localCalTasks[existingIndex][9] = taskDetails['remainderType'];
        db.localCalTasks[existingIndex][10] = taskDetails['isStarred'];
        db.localCalTasks[existingIndex][13] = taskDetails['subTasks'];
        updatedCount++;
        print('✏️ Updated existing task: ${event.title}');
        continue;
      }

      // Otherwise, add new task
      db.localCalTasks.add([
        taskDetails['taskName'],
        false,
        taskDetails['taskNote'],
        dueDate,
        dueTime,
        taskDetails['taskCategory'],
        taskDetails['taskPriority'],
        taskDetails['repeatType'],
        taskDetails['remainderAmount'],
        taskDetails['remainderType'],
        taskDetails['isStarred'],
        taskDetails['createdAt'],
        uuid.v4(),
        taskDetails['subTasks'],
        taskDetails['calendarId'],
        taskDetails['eventId'],
        taskDetails['eventId'],
        "local",
        "none",
      ]);

      importedCount++;
      print('➕ Added new task: ${event.title}');
    }

    print(" localCalTasks after import ${db.localCalTasks}");
    await db.updateDataBase();
    print(
      '✅ Imported $importedCount new events, updated $updatedCount existing ones.',
    );
  }

  static String _repeatTypeFromRule(RecurrenceRule? rule) {
    if (rule == null) return 'none';
    switch (rule.recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return 'daily';
      case RecurrenceFrequency.Weekly:
        return 'weekly';
      case RecurrenceFrequency.Monthly:
        return 'monthly';
      case RecurrenceFrequency.Yearly:
        return 'yearly';
      default:
        return 'none';
    }
  }

  static RecurrenceRule? _buildRecurrenceRule(String? repeatType) {
    if (repeatType == null || repeatType == 'none' || repeatType == 'None') {
      return null; // no repeat
    }

    switch (repeatType.toLowerCase()) {
      case 'daily':
        return RecurrenceRule(RecurrenceFrequency.Daily, interval: 1);

      case 'weekly':
        return RecurrenceRule(RecurrenceFrequency.Weekly, interval: 1);

      case 'monthly':
        return RecurrenceRule(RecurrenceFrequency.Monthly, interval: 1);

      case 'yearly':
        return RecurrenceRule(RecurrenceFrequency.Yearly, interval: 1);

      default:
        return null;
    }
  }
}
