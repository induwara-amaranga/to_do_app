// lib/services/import_from_ics.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';

class ImportFromIcsService {
  static var uuid = Uuid();

  /// Picks an .ics file and parses its events into a list of task maps.
  static Future<List<Map<String, dynamic>>> pickAndParseICS() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );

    if (result == null || result.files.single.path == null) return [];

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final calendar = ICalendar.fromString(content);
    final events = calendar.data.where((e) => e['type'] == 'VEVENT').toList();

    final parsed =
        events.map((event) {
          DateTime? _startDate;
          DateTime? startDate;
          try {
            try {
              if (event['dtstart'] != null && event['dtstart'] is IcsDateTime) {
                final icsDate = event['dtstart'] as IcsDateTime;
                startDate = DateTime.tryParse(icsDate.dt);
              }
            } catch (e) {
              print("Error parsing start date: $e");
            }

            _startDate =
                event['DTSTART'] != null
                    ? DateTime.tryParse(
                      event['DTSTART'] is Map
                          ? event['DTSTART']['value'].dt ?? event['DTSTART'].dt
                          : event['DTSTART'].dt,
                    )
                    : event['dtstart'] != null
                    ? DateTime.tryParse(
                      event['dstart'] is Map
                          ? event['dtstart']['value'].dt ?? event['dtstart'].dt
                          : event['dtstart'].dt,
                    )
                    : null;
            print("event $event");
            print("DTSTART ${event['dtstart'].dt}");
            print("Parsed start date: $startDate");
          } catch (_) {}

          return {
            'taskName':
                event['SUMMARY'] ?? event['summary'] ?? 'Untitled Event',
            'taskNote': event['DESCRIPTION'] ?? event['description'] ?? '',
            'dueDate': _startDate,
            'dueTime': _startDate,
            // 'priority':
            //     priority ?? event['PRIORITY'] ?? event['priority'] ?? 'Medium',
            // 'category': category,
            // 'repeat': repeat,
            // 'remainderAmount': remainderAmount,
            // 'remainderType': remainderType,
            // 'isStarred': isStarred,
            'id': uuid.v4(),
          };
        }).toList();

    return parsed;
  }

  /// Imports a list of parsed tasks into the local database.
  static Future<void> importTasksToDB(
    BuildContext context,
    ToDoDataBase db,
    List<Map<String, dynamic>> parsedTasks,
    String priority,
    String category,
    String repeat,
    int remainderAmount,
    String remainderType,
    bool isStarred,
  ) async {
    //db.loadData();
    for (final task in parsedTasks) {
      // final combined = DateTimeUtilsHelper.combineDateAndTime(
      //   task['dueDate'],

      //   task['dueDate'],
      // );
      final utcTime = DateTimeUtilsHelper.toUtcUsingLocal(task["dueDate"]);
      print("utc time $utcTime  ${task["dueDate"]}");

      db.toDoList.add([
        task['taskName'], // 0 - name
        false, // 1 - completed
        task['taskNote'], // 2 - note
        DateTimeUtilsHelper.formatDate(utcTime), // 3 - date
        DateTimeUtilsHelper.formatTime(utcTime), // 4 - time
        category,
        priority, // task['priority'], // 6 - priority
        repeat, // task['repeat'],
        remainderAmount, // task['remainderAmount'],
        remainderType, // task['remainderType'], // 7–9 - repeat/remainder types
        isStarred, // task['isIsStarred'],
        DateTime.now().toString(), // 11 - extra
        task['id'], // 12 - ID (if you use UUIDs)
        [], // 13 - subtasks
        "",
        "",
        "",
        "ICS",
        "none", //18 completed at
        [],
      ]);
      await NotificationService.scheduleInitialRemainderForTask(
        task['id'],
        context,
        {
          'taskName': task['taskName'],
          'dueDate': DateTimeUtilsHelper.formatDate(utcTime), //utc time??
          'dueTime': DateTimeUtilsHelper.formatTime(utcTime),
          'remainderAmount': remainderAmount,
          'remainderType': remainderType,
          'taskPriority': priority,
        },
        db,
        db.toDoList.length - 1,
      );
    }

    db.updateDataBase();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${parsedTasks.length} tasks imported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }
}
