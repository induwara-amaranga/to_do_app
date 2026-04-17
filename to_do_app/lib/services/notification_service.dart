import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis/driveactivity/v2.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/models/types.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:to_do_app/utils/string_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    //init timezone handling
    //tz.initializeTimeZones();
    //var currentTimeZone = await FlutterTimezone.getLocalTimezone();
    //String zoneString = currentTimeZone.identifier;
    //print("detected zone is=====================>$zoneString");
    //tz.setLocalLocation(tz.getLocation(zoneString));
    //android intialization settings
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // ✅ Request permission after init
    await requestNotificationPermission();
  }

  static Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted = await androidPlugin?.areNotificationsEnabled();
      return granted ?? false;
    }

    // iOS always prompts via requestPermissions, assume granted if init succeeded
    return true;
  }

  static Future<bool> requestNotificationPermission() async {
    bool granted = false;

    if (Platform.isAndroid) {
      // Request basic notification permission (Android 13+)
      final bool? result =
          await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();

      granted = result ?? false;
      print("Android notification permission granted: $granted");

      // Request exact alarm permission (Android 12+)
      final bool? exactAlarmGranted =
          await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestExactAlarmsPermission();

      print("Exact alarm permission granted: $exactAlarmGranted");
    } else if (Platform.isIOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      granted = result ?? false;
      print("iOS notification permission granted: $granted");
    }

    return granted;
  }

  static NotificationDetails notificationDetails(
    String priority,
    bool isFullscreen,
  ) {
    switch (priority) {
      case "High":
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'high_task_channel_id',
            'High Priority Task Notifications',
            channelDescription: 'Notifications for high priority to-do tasks',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: isFullscreen,
            color: const Color.fromARGB(255, 255, 161, 154),
            vibrationPattern: Int64List.fromList([0, 1000, 500, 2000]),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_done',
                '✅ Done',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'working',
                '🕒 Working on it',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        );
      case "Medium":
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'medium_task_channel_id',
            'Medium Priority Task Notifications',
            channelDescription: 'Notifications for medium priority to-do tasks',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            color: Color.fromARGB(255, 253, 244, 170),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_done',
                '✅ Done',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'working',
                '🕒 Working on it',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        );
      case "Low":
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'low_task_channel_id',
            'Low Priority Task Notifications',
            channelDescription: 'Notifications for low priority to-do tasks',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_done',
                '✅ Done',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'working',
                '🕒 Working on it',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        );
    }
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel_id',
        'Task Notifications',
        channelDescription: 'Notifications for to-do tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'mark_done',
            '✅ Done',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'working',
            '🕒 Working on it',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'dismiss',
            '❌ Dismiss',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    print("instant notification showing");
    return _notifications.show(
      id,
      title,
      body,
      notificationDetails("Low", false),
    );
  }

  static Future<void> sheduledTimeNotification({
    required List<dynamic> payload,
    BuildContext? context,
    required int id,
    required String title,
    required String body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minutes,
    required String priority,
    required String repeatType,
    required bool isFullScreen,
  }) async {
    final bool hasPermission = await isNotificationPermissionGranted();
    if (!hasPermission) {
      print("⚠️ Notification permission not granted. Requesting...");
      final bool granted = await requestNotificationPermission();
      if (!granted) {
        print("❌ Permission denied. Notification not scheduled.");
        return;
      }
    }
    final scheduledDateTime = tz.TZDateTime(
      tz.UTC, // 👈 local time (important)
      year,
      month,
      day,
      hour,
      minutes,
    );

    final now = tz.TZDateTime.now(tz.UTC);

    print(
      "------------------------------------------Scheduling notification for $scheduledDateTime | now=$now | repeat=$repeatType -----------",
    );

    if (context != null && scheduledDateTime.isBefore(now)) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("⚠️ Scheduled time is in the past! Reminder not set."),
      //     backgroundColor: Colors.redAccent,
      //   ),
      // );
      print("⚠️ Scheduled time is in the past! Reminder not set.");
      return;
    }

    /// 🔁 Decide repeat behavior
    DateTimeComponents? matchComponents;

    switch (repeatType.toLowerCase()) {
      case "daily":
        matchComponents = DateTimeComponents.time;
        break;

      case "weekly":
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;

      case "monthly":
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;

      case "none":
      default:
        matchComponents = null; // one-time notification
    }
    if (await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestFullScreenIntentPermission() ==
        false) {
      print("Full screen intent permission denied");
    }

    try {
      final _title =
          "$title ${priority == "High"
              ? "🔴"
              : priority == "Low"
              ? "🟢"
              : "🟡"}";

      await _notifications.zonedSchedule(
        id,
        _title,
        body,
        scheduledDateTime,
        notificationDetails(priority, isFullScreen),
        payload: payload.toString(),

        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,

        // 🔁 THIS enables repeating
        matchDateTimeComponents: matchComponents,
      );
    } catch (e) {
      print("Scheduling error: $e");

      if (context != null) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text("Failed to schedule notification: $e"),
        //     backgroundColor: Colors.redAccent,
        //   ),
        // );
        //print("Failed to schedule notification: $e");
      }
    }
  }

  static DateTime remainderDateTime(
    DateTime dueDate,
    DateTime dueTime,
    String remainderType,
    int remainderAmount,
  ) {
    // Combine due date and time
    DateTime fullDueDateTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime.hour,
      dueTime.minute,
    );

    // Subtract remainder
    switch (remainderType) {
      case "minutes":
        return fullDueDateTime.subtract(Duration(minutes: remainderAmount));
      case "hours":
        return fullDueDateTime.subtract(Duration(hours: remainderAmount));
      case "days":
        return fullDueDateTime.subtract(Duration(days: remainderAmount));
      case "weeks":
        return fullDueDateTime.subtract(Duration(days: 7 * remainderAmount));
      default:
        // if type is unknown, return the original date-time
        return fullDueDateTime;
    }
  }

  // @pragma('vm:entry-point')
  // static void notificationTapBackgroundAlt(
  //   NotificationResponse response,
  // ) async {
  //   // IMPORTANT: background isolate needs plugin initialization
  //   WidgetsFlutterBinding.ensureInitialized();
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();

  //   // Write data to confirm background execution
  //   await prefs.setBool('notification_background_ran', true);
  //   await prefs.setString(
  //     'last_notification_action',
  //     response.actionId ?? 'no_action',
  //   );

  //   print('Background action executed');
  // }

  @pragma('vm:entry-point')
  static Future<void> notificationTapBackground(
    NotificationResponse response,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();

    print('BACKGROUND action: ${response.actionId}');

    try {
      final id = response.id;
      final actionId = response.actionId;
      print("get list");
      final payload = StringUtils.listFromString(response.payload!);
      print("Notification payload: $payload");
      final DateTime now = DateTime.now();

      if (payload[1] == 'High') {
        // showDialog(
        //   context: navigatorKey.currentContext!,
        //   builder:
        //       (ctx) => AlertDialog(
        //         title: const Text("⚠️ High Priority Task"),
        //         content: Text(payload[4]), // task name
        //         actions: [
        //           TextButton(
        //             onPressed: () => Navigator.of(ctx).pop(),
        //             child: const Text("OK"),
        //           ),
        //         ],
        //       ),
        //);
      }

      if (actionId == 'mark_done') {
        print("✅ Task $payload marked as done!");
        // TODO: update database / provider
      } else if (actionId == 'working') {
        print("🕒 Working on task $payload");
        DateTime dueDateTime = DateTimeUtilsHelper.parseDateTime(payload[2]);

        //final payload = response.payload;
      } else if (actionId == 'dismiss') {
        print("❌ Dismissed task $payload");

        List<Object> ids =
            payload.length > 5 ? StringUtils.listFromString(payload[5]) : [];

        for (Object remId in ids) {
          try {
            final int parsedId = int.parse(remId.toString().trim());
            await cancelNotification(parsedId);
          } catch (e) {
            print("Failed to parse/cancel notification id '$remId': $e");
          }
        }
      } else {
        print("Notification tapped normally");
      }
    } catch (e) {
      print("---------action error : $e------");
    }
  }

  @pragma('vm:entry-point')
  static void onNotificationResponse(NotificationResponse response) async {
    print("---------------------------------");

    try {
      final id = response.id;
      final actionId = response.actionId;
      print("get list");
      final payload = StringUtils.listFromString(response.payload!);
      print("Notification payload: $payload");
      final DateTime now = DateTime.now();

      if (payload[1] == 'High') {
        // showDialog(
        //   context: navigatorKey.currentContext!,
        //   builder:
        //       (ctx) => AlertDialog(
        //         title: const Text("⚠️ High Priority Task"),
        //         content: Text(payload[4]), // task name
        //         actions: [
        //           TextButton(
        //             onPressed: () => Navigator.of(ctx).pop(),
        //             child: const Text("OK"),
        //           ),
        //         ],
        //       ),
        //);
      }

      if (actionId == 'mark_done') {
        print("✅ Task $payload marked as done!");
        // TODO: update database / provider
      } else if (actionId == 'working') {
        print("🕒 Working on task $payload");
        DateTime dueDateTime = DateTimeUtilsHelper.parseDateTime(payload[2]);
        // switch (payload[1]) {
        //   case 'High':
        //     DateTime newTime = now.add(const Duration(minutes: 1));
        //     if (!newTime.isBefore(dueDateTime)) {
        //       newTime = dueDateTime;
        //     }
        //     rescheduleNotification(
        //       payload: payload,
        //       id: id!,
        //       title: payload[3],
        //       body: payload[4],
        //       newTime: newTime,
        //     );
        //     break;
        //   case 'Medium':
        //     DateTime newTime = now.add(const Duration(minutes: 60));
        //     if (!newTime.isBefore(dueDateTime)) {
        //       newTime = dueDateTime;
        //     }
        //     rescheduleNotification(
        //       payload: payload,
        //       id: id!,
        //       title: payload[3],
        //       body: payload[4],
        //       newTime: newTime,
        //     );
        //     break;
        //   case 'Low':
        //     // DateTime newTime = now.add(const Duration(minutes: 10));
        //     // if (!newTime.isBefore(dueDateTime)) {
        //     //   newTime = dueDateTime;
        //     // }
        //     // //print("low - secheduled");
        //     // rescheduleNotification(
        //     //   payload: payload,
        //     //   id: id!,
        //     //   title: payload[3],
        //     //   body: payload[4],
        //     //   newTime: newTime,
        //     // );
        //     break;
        //   default:
        //     print("Unknown priority level: $payload");
        // }

        //final payload = response.payload;
      } else if (actionId == 'dismiss') {
        print("❌ Dismissed task $payload");
        List<Object> ids =
            payload.length > 5 ? StringUtils.listFromString(payload[5]) : [];
        for (Object remId in ids) {
          await cancelNotification(remId as int);
        }
        //await cancelNotification(id!);
      } else {
        print("Notification tapped normally");
      }
    } catch (e) {
      print("---------action error : $e------");
    }
  }

  // Reschedule a notification
  static Future<void> rescheduleNotification({
    required List<dynamic> payload,
    required int id,
    required String title,
    required String body,
    required DateTime newTime,
    required String repeatType,
    required bool isFullscreen,
  }) async {
    // 1️⃣ Cancel the old notification
    await cancelNotification(id);

    // 2️⃣ Schedule the new one
    await sheduledTimeNotification(
      isFullScreen: isFullscreen,
      repeatType: repeatType,
      payload: payload,
      id: id,
      title: title,
      body: body,
      year: newTime.year,
      month: newTime.month,
      day: newTime.day,
      hour: newTime.hour,
      minutes: newTime.minute,
      priority: payload[1],
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  //function to cancel specific notification
  static Future<void> cancelNotification(int id) async {
    print("Attempting to cancel notification with id: $id");
    try {
      await _notifications.cancel(id);
      print("notification $id cancelled");
    } catch (e) {
      print("Error cancelling notification $id: $e");
    }
    //print("canceled: $id");
    //if there is no notification with id, nothing happens
  }

  static Future<void> scheduleInitialRemainderForTask(
    String id,
    BuildContext context,
    Map<String, dynamic> taskDetails,
    ToDoDataBase db,
    int index,
  ) async {
    List<List<dynamic>> toDoList = db.toDoList;
    DateTime? dueDate = DateTimeUtilsHelper.parseDate(taskDetails['dueDate']);
    DateTime? dueTime = DateTimeUtilsHelper.parseTime(taskDetails['dueTime']);

    if (dueDate == null || dueTime == null) {
      print(
        "scheduleInitialRemainderForTask: dueDate or dueTime is null, skipping.",
      );
      return;
    }

    // --- Custom user-defined reminder ---
    if (taskDetails['remainderAmount'] >= 0 &&
        taskDetails['remainderType'] != "none") {
      DateTime reminderDateTime = NotificationService.remainderDateTime(
        dueDate,
        dueTime,
        taskDetails['remainderType'],
        taskDetails['remainderAmount'],
      );

      int reminderId = id.hashCode;

      try {
        await NotificationService.sheduledTimeNotification(
          isFullScreen: false,
          repeatType: taskDetails["repeatType"],
          priority: taskDetails['taskPriority'],
          context: context,
          id: reminderId,
          title: "Task Reminder",
          body: taskDetails['taskName'],
          year: reminderDateTime.year,
          month: reminderDateTime.month,
          day: reminderDateTime.day,
          hour: reminderDateTime.hour,
          minutes: reminderDateTime.minute,
          payload: [
            id,
            taskDetails['taskPriority'],
            DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
            "Task Reminder",
            taskDetails['taskName'],
            [reminderId],
          ],
        );
      } catch (e) {
        print("Schedule error from task page => $e");
      }

      toDoList[index][19] = [
        reminderId,
      ]; // ✅ fixed: was using undeclared reminderIds
      db.updateDataBase();
    }

    // --- Priority-based interval reminders ---
    if (taskDetails['taskPriority'] == "High" ||
        taskDetails['taskPriority'] == "Medium") {
      final int hoursBeforeStart =
          taskDetails['taskPriority'] == "High" ? 2 : 1;
      final bool isHighPriority = taskDetails['taskPriority'] == "High";

      List<DateTime> reminderTimes = [];
      List<int> reminderIds = [];

      DateTime startReminder = DateTimeUtilsHelper.utcDateTimeFromUTCvalues(
        NotificationService.remainderDateTime(
          dueDate,
          dueTime,
          'hours',
          hoursBeforeStart,
        ),
      );
      DateTime endReminder = DateTimeUtilsHelper.utcDateTimeFromUTCvalues(
        NotificationService.remainderDateTime(dueDate, dueTime, 'hours', 0),
      );

      reminderTimes.add(startReminder);
      reminderIds.add((id + startReminder.toString()).hashCode);

      while (reminderTimes.last.isBefore(endReminder)) {
        DateTime nextReminder = reminderTimes.last.add(
          const Duration(minutes: 30),
        );
        if (!nextReminder.isAfter(endReminder)) {
          reminderTimes.add(nextReminder);
          reminderIds.add((id + nextReminder.toString()).hashCode);
        } else {
          break;
        }
      }

      print("${taskDetails['taskPriority']} reminder times: $reminderTimes");
      print("${taskDetails['taskPriority']} reminder IDs: $reminderIds");

      bool isFullScreen = isHighPriority;

      int i = 0;

      for (DateTime reminderTime in reminderTimes) {
        if (reminderTime.isBefore(DateTime.now().toUtc())) {
          isFullScreen = false;
          continue;
        }
        try {
          await NotificationService.sheduledTimeNotification(
            isFullScreen: isFullScreen,
            repeatType: taskDetails["repeatType"],
            priority: taskDetails['taskPriority'],
            context: context,
            id: reminderIds[i],
            title: "Task Reminder",
            body: taskDetails['taskName'],
            year: reminderTime.year,
            month: reminderTime.month,
            day: reminderTime.day,
            hour: reminderTime.hour,
            minutes: reminderTime.minute,
            payload: [
              id,
              taskDetails['taskPriority'],
              DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
              "Task Reminder",
              taskDetails['taskName'],
              reminderIds,
            ],
          );
        } catch (e) {
          print("${taskDetails['taskPriority']} task schedule error => $e");
        }
        isFullScreen = false; // only first notification is fullscreen
        i++;
      }

      toDoList[index][19] = reminderIds;
      db.updateDataBase();
    }
  }
}
