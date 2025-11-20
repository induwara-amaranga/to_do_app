import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:to_do_app/main.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:to_do_app/utils/string_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    //init timezone handling
    tz.initializeTimeZones();
    var currentTimeZone = await FlutterTimezone.getLocalTimezone();
    String zoneString = currentTimeZone.identifier;
    //print("detected zone is=====================>$zoneString");
    tz.setLocalLocation(tz.getLocation(zoneString));
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
    );
  }

  static NotificationDetails notificationDetails(String priority) {
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
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: true,
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
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: true,
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
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'dismiss',
                '❌ Dismiss',
                showsUserInterface: true,
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
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss',
            '❌ Dismiss',
            showsUserInterface: true,
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
    return _notifications.show(id, title, body, notificationDetails("Low"));
  }

  static Future<void> sheduledTimeNotification({
    required List<dynamic> payload,
    BuildContext? context, // 👈 add this
    required int id,
    required String title,
    required String body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minutes,
    required String priority,
  }) async {
    final scheduledDateTime = tz.TZDateTime(
      tz.UTC,
      year,
      month,
      day,
      hour,
      minutes,
    );

    print(
      "-------------------scheduling notification for $scheduledDateTime---------------------",
    );

    final now = tz.TZDateTime.now(tz.UTC);
    if (context != null) {
      // 👇 Check if scheduled time is before now
      if (scheduledDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ Scheduled time is in the past! Remainder not set.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    try {
      String _title =
          title +
          " " +
          (priority == "High"
              ? "🔴"
              : priority == "Low"
              ? "🟢"
              : "🟡");

      await _notifications.zonedSchedule(
        id,
        _title,
        body,
        scheduledDateTime,
        notificationDetails(priority),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload.toString(),
      );
      // if (navigatorKey.currentContext != null) {
      //   showDialog(
      //     context: navigatorKey.currentContext!,
      //     builder:
      //         (ctx) => AlertDialog(
      //           title: const Text("⚠️ High Priority Task"),
      //           content: const Text("Finish the report ASAP!"),
      //           actions: [
      //             TextButton(
      //               onPressed: () => Navigator.of(ctx).pop(),
      //               child: const Text("OK"),
      //             ),
      //           ],
      //         ),
      //   );
      // }
    } catch (e) {
      print("scheduling error $e");
      if (context != null) {
        // 👇 Show error message if context is available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to schedule notification: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
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

  static void onNotificationResponse(NotificationResponse response) {
    final id = response.id;
    final actionId = response.actionId;

    final payload = StringUtils.listFromString(response.payload!);
    print("Notification payload: $payload");
    final DateTime now = DateTime.now();

    if (payload[1] == 'High') {
      showDialog(
        context: navigatorKey.currentContext!,
        builder:
            (ctx) => AlertDialog(
              title: const Text("⚠️ High Priority Task"),
              content: Text(payload[4]), // task name
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }

    if (actionId == 'mark_done') {
      print("✅ Task $payload marked as done!");
      // TODO: update database / provider
    } else if (actionId == 'working') {
      print("🕒 Working on task $payload");
      DateTime dueDateTime = DateTimeUtilsHelper.parseDateTime(payload[2]);
      switch (payload[1]) {
        case 'High':
          DateTime newTime = now.add(const Duration(minutes: 30));
          if (!newTime.isBefore(dueDateTime)) {
            newTime = dueDateTime;
          }
          rescheduleNotification(
            payload: payload,
            id: id!,
            title: payload[3],
            body: payload[4],
            newTime: newTime,
          );
          break;
        case 'Medium':
          DateTime newTime = now.add(const Duration(minutes: 60));
          if (!newTime.isBefore(dueDateTime)) {
            newTime = dueDateTime;
          }
          rescheduleNotification(
            payload: payload,
            id: id!,
            title: payload[3],
            body: payload[4],
            newTime: newTime,
          );
          break;
        case 'Low':
          // DateTime newTime = now.add(const Duration(minutes: 10));
          // if (!newTime.isBefore(dueDateTime)) {
          //   newTime = dueDateTime;
          // }
          // //print("low - secheduled");
          // rescheduleNotification(
          //   payload: payload,
          //   id: id!,
          //   title: payload[3],
          //   body: payload[4],
          //   newTime: newTime,
          // );
          break;
        default:
          print("Unknown priority level: $payload");
      }

      //final payload = response.payload;
    } else if (actionId == 'dismiss') {
      print("❌ Dismissed task $payload");
    } else {
      print("Notification tapped normally");
    }
  }

  // Reschedule a notification
  static Future<void> rescheduleNotification({
    required List<dynamic> payload,
    required int id,
    required String title,
    required String body,
    required DateTime newTime,
  }) async {
    // 1️⃣ Cancel the old notification
    await cancelNotification(id);

    // 2️⃣ Schedule the new one
    await sheduledTimeNotification(
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
    await _notifications.cancel(id);
    print("notification $id cancelled");
    //if there is no notification with id, nothing happens
  }

  static scheduleInitialRemainderForTask(
    String id,
    BuildContext context,
    Map<String, dynamic> taskDetails,
  ) {
    DateTime? dueDate = DateTimeUtilsHelper.parseDate(taskDetails['dueDate']);
    DateTime? dueTime = DateTimeUtilsHelper.parseTime(taskDetails['dueTime']);
    if (taskDetails['remainderAmount'] >= 0 &&
        taskDetails['remainderType'] != "none") {
      DateTime remainderDateTime = NotificationService.remainderDateTime(
        dueDate!,
        dueTime!,
        //taskDetails['dueTime'],
        taskDetails['remainderType'],
        taskDetails['remainderAmount'],
      );
      try {
        NotificationService.sheduledTimeNotification(
          priority: taskDetails['taskPriority'],
          context: context,
          id: id.hashCode,
          title: "teask remainder",
          body: taskDetails['taskName'],
          year: remainderDateTime.year,
          month: remainderDateTime.month,
          day: remainderDateTime.day,
          hour: remainderDateTime.hour,
          minutes: remainderDateTime.minute,
          payload: [
            id,
            taskDetails['taskPriority'],
            DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
            "teask remainder",
            taskDetails['taskName'],
          ],
        );
      } catch (e) {
        print("shedule error form task page => $e");
      }
    }
    if (taskDetails['taskPriority'] == "High") {
      //print("high priority - secheduled");
      DateTime remainderDateTime = NotificationService.remainderDateTime(
        dueDate!,
        dueTime!,
        //taskDetails['dueTime'],
        'hours',
        2,
      );
      if (remainderDateTime.isBefore(DateTime.now())) {
        remainderDateTime = DateTime.now().add(const Duration(minutes: 1));
      }
      try {
        NotificationService.sheduledTimeNotification(
          priority: taskDetails['taskPriority'],
          context: context,
          id: id.hashCode,
          title: "teask remainder",
          body: taskDetails['taskName'],
          year: remainderDateTime.year,
          month: remainderDateTime.month,
          day: remainderDateTime.day,
          hour: remainderDateTime.hour,
          minutes: remainderDateTime.minute,
          payload: [
            id,
            taskDetails['taskPriority'],
            DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
            "teask remainder",
            taskDetails['taskName'],
          ],
        );
      } catch (e) {
        print("High task shedule error form task page => $e");
      }
    } else if (taskDetails['taskPriority'] == "Medium") {
      DateTime remainderDateTime = NotificationService.remainderDateTime(
        dueDate!,
        dueTime!,
        //taskDetails['dueTime'],
        'hours',
        1,
      );
      if (remainderDateTime.isBefore(DateTime.now())) {
        remainderDateTime = DateTime.now().add(const Duration(minutes: 1));
      }
      try {
        NotificationService.sheduledTimeNotification(
          priority: taskDetails['taskPriority'],
          context: context,
          id: id.hashCode,
          title: "teask remainder",
          body: taskDetails['taskName'],
          year: remainderDateTime.year,
          month: remainderDateTime.month,
          day: remainderDateTime.day,
          hour: remainderDateTime.hour,
          minutes: remainderDateTime.minute,
          payload: [
            id,
            taskDetails['taskPriority'],
            DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
            "teask remainder",
            taskDetails['taskName'],
          ],
        );
      } catch (e) {
        print("Medium task shedule error form task page => $e");
      }
    }
  }
}
