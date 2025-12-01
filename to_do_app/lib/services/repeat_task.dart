import 'package:flutter/widgets.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:uuid/uuid.dart';

class RepeatTask {
  static var uuid = Uuid();
  // Create all pending repeated tasks if their due date(s) have passed
  static void createPendingRepeatTasks(ToDoDataBase db, BuildContext context) {
    final today = DateTime.now().toUtc();

    // Make a copy so iteration isn’t affected by .add()
    final originalTasks = List<List<dynamic>>.from(db.toDoList);

    for (var task in originalTasks) {
      // Skip if task has no repeat type
      if (task[7] == null || task[7] == "none") continue;

      // Parse due date
      DateTime? dueDate = DateTimeUtilsHelper.parseDate(task[3]);
      if (dueDate == null) continue;

      // Add repeated tasks until dueDate is in the future
      int maxRepeats = 1000; // safety cap
      int count = 0;

      while (dueDate!.isBefore(DateTime(today.year, today.month, today.day)) &&
          count < maxRepeats) {
        dueDate = _createNextRepeatTask(context, db, task, dueDate);
        count++;
      }
    }

    db.updateDataBase(); // Save changes to Hive
  }

  // Private helper to create the next repeat task
  // Returns the next due date
  static DateTime _createNextRepeatTask(
    BuildContext context,
    ToDoDataBase db,
    List<dynamic> task,
    DateTime dueDate,
  ) {
    String repeatType = task[7];
    DateTime nextDate;

    switch (repeatType) {
      case "daily":
        nextDate = dueDate.add(Duration(days: 1));
        break;
      case "weekly":
        nextDate = dueDate.add(Duration(days: 7));
        break;
      case "monthly":
        nextDate = DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        break;
      case "yearly":
        nextDate = DateTime(dueDate.year + 1, dueDate.month, dueDate.day);
        break;
      default:
        return dueDate; // unknown repeat type
    }
    String id = uuid.v4();

    db.toDoList.add([
      task[0], // name
      false, // incomplete
      task[2], // note
      DateTimeUtilsHelper.formatDate(nextDate), // new due date
      task[4], // same due time
      task[5], // category
      task[6], // priority
      task[7], // repeatType
      task[8], // remainderAmount
      task[9], // remainderType
      task[10], // isStarred
      DateTime.now().toUtc().toString(), // createdAt
      id, // new unique ID
      task[13], // subtasks
      "", //14 cal id
      "", //15 event id
      "", //16 local cal event id
      "repeat",
    ]);
    // print(
    //   "added ${[
    //     task[0], // name
    //     false, // incomplete
    //     task[2], // note
    //     DateTimeUtilsHelper.formatDate(nextDate), // new due date
    //     task[4], // same due time
    //     task[5], // category
    //     task[6], // priority
    //     task[7], // repeatType
    //     task[8], // remainderAmount
    //     task[9], // remainderType
    //     task[10], // isStarred
    //     DateTime.now().toString(), // createdAt
    //     id, // new unique ID
    //     task[13], // subtasks
    //   ]}",
    // );
    //if due date and time  is after now  then schedule notification
    DateTime now = DateTime.now().toUtc();
    if (nextDate.isAfter(DateTime(now.year, now.month, now.day))) {
      //schedule notification
      if (task[8] >= 0) {
        DateTime? dueTime = DateTimeUtilsHelper.parseTime(task[4]);
        if (dueTime != null) {
          DateTime remainderDateTime = NotificationService.remainderDateTime(
            nextDate,
            dueTime,
            task[9],
            task[8],
          );
          if (remainderDateTime.isAfter(DateTime.now().toUtc())) {
            NotificationService.scheduleInitialRemainderForTask(id, context, {
              'dueDate': DateTimeUtilsHelper.formatDate(nextDate),
              'dueTime': task[4],
              'taskName': task[0],
              'taskPriority': task[6],
              'remainderType': task[9],
              'remainderAmount': task[8],
            });
            // try {
            //   NotificationService.sheduledTimeNotification(
            //     priority: task[6],
            //     context: context,
            //     id: id.hashCode,
            //     title: "Task Reminder",
            //     body: task[0],
            //     year: remainderDateTime.year,
            //     month: remainderDateTime.month,
            //     day: remainderDateTime.day,
            //     hour: remainderDateTime.hour,
            //     minutes: remainderDateTime.minute,
            //     payload: [
            //       id,
            //       task[6],
            //       DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
            //       "teask remainder",
            //       task[0],
            //     ],
            //   );
            // } catch (e) {
            //   print("Error scheduling notification for repeated task: $e");
            // }
          }
        }
      }
    }

    return nextDate;
  }

  static void createNextRepeatTask(
    BuildContext context,
    int index,
    ToDoDataBase db,
  ) {
    var task = db.toDoList[index];

    // Parse the current due date
    DateTime? dueDate = DateTimeUtilsHelper.parseDate(task[3]);
    if (dueDate == null) return;

    // Only create next task if current date is after due date
    DateTime today = DateTime.now().toUtc();
    if (DateTime(today.year, today.month, today.day).isAfter(dueDate)) {
      //Due date not passed yet, don't create next task
      return;
    }

    // Calculate next due date
    String repeatType = task[7]; // daily, weekly, monthly, yearly
    DateTime nextDate;
    switch (repeatType) {
      case "daily":
        nextDate = dueDate.add(Duration(days: 1));
        break;
      case "weekly":
        nextDate = dueDate.add(Duration(days: 7));
        break;
      case "monthly":
        nextDate = DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        break;
      case "yearly":
        nextDate = DateTime(dueDate.year + 1, dueDate.month, dueDate.day);
        break;
      default:
        return;
    }
    String id = uuid.v4();

    final indexWhere = db.toDoList.indexWhere((t) {
      DateTime dueDate = DateTimeUtilsHelper.parseDate(t[3])!;

      return t.length > 15 &&
          dueDate.year == nextDate.year &&
          dueDate.month == nextDate.month &&
          dueDate.day == nextDate.day &&
          t[0] == task[0];
    });
    print("index  $indexWhere");
    if (indexWhere != -1) return;

    // Add the new repeated task
    db.toDoList.add([
      task[0], // name
      false, // incomplete
      task[2], // note
      DateTimeUtilsHelper.formatDate(nextDate), // new due date
      task[4], // same due time
      task[5], // category
      task[6], // priority
      task[7], // repeatType
      task[8], // remainderAmount
      task[9], // remainderType
      task[10], // isStarred
      DateTime.now().toUtc().toString(), // createdAt
      id,
      task[13],
      "", //14 cal id
      "", //15 event id
      "", //16 local cal event id
      "repeat",
    ]);

    db.updateDataBase();
    if (task[8] >= 0) {
      DateTime? dueTime = DateTimeUtilsHelper.parseTime(task[4]);
      if (dueTime != null) {
        DateTime remainderDateTime = NotificationService.remainderDateTime(
          nextDate,
          dueTime,
          task[9],
          task[8],
        );
        if (remainderDateTime.isAfter(DateTime.now().toUtc())) {
          NotificationService.scheduleInitialRemainderForTask(id, context, {
            'dueDate': DateTimeUtilsHelper.formatDate(nextDate),
            'dueTime': task[4],
            'taskName': task[0],
            'taskPriority': task[6],
            'remainderType': task[9],
            'remainderAmount': task[8],
          });
        }
      }
    }
  }
}
