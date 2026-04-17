import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:to_do_app/components/bar_chart.dart';
import 'package:to_do_app/components/pie_chart.dart';
import 'package:to_do_app/components/statistics_tile.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/utils/date_time_utils.dart';

class StatisticsPage extends StatefulWidget {
  final ToDoDataBase db;
  const StatisticsPage({super.key, required this.db});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime today = DateTime.now().toUtc();
  late DateTime firstDate;
  late DateTime lastDate;
  int displayWeek = 0;

  late List<List<dynamic>> toDoList;
  late List<List<dynamic>> missedTasks;
  late List<List<dynamic>> pendingTasks;
  late List<List<dynamic>> completedTasks;
  late List<List<dynamic>> completedPastTasks;
  late List<List<dynamic>> pastTasks;
  Map<String, List<List<dynamic>>> groupedByCompletedDate = {};
  Map<int, List<List<dynamic>>> groupedWeekByCompletedDate = {};
  List<String> selectedWeek = [];

  Map<String, List<List<dynamic>>> groupedMissedTasksByPriority = {
    'Low': [],
    'Medium': [],
    'High': [],
  };
  Map<String, List<List<dynamic>>> groupedPendingTasksByPriority = {
    'Low': [],
    'Medium': [],
    'High': [],
  };
  Map<String, List<List<dynamic>>> groupedPendingTasksByCategory = {};

  DateTime? _getUtcDateTime(List<dynamic> task) {
    DateTime? dueDateUtc = DateTimeUtilsHelper.parseDate(task[3]);
    DateTime? dueTimeUtc = DateTimeUtilsHelper.parseTime(task[4]);
    //print("due date utc $dueDateUtc");
    DateTime? dueDate;
    if (dueDateUtc != null && dueTimeUtc != null) {
      final combined = DateTimeUtilsHelper.combineDateAndTimeFromStrings(
        task[3],
        task[4],
      );
      if (combined != null) {
        return DateTime.utc(
          combined.year,
          combined.month,
          combined.day,
          combined.hour,
          combined.minute,
        );
      }
    }

    //return
  }

  List<DateTime> _getWeekDates({
    int weeksAgo = 0,
    bool startFromMonday = true,
  }) {
    final now = DateTime.now().toUtc();

    // Current weekday (1 = Monday, 7 = Sunday)
    int currentWeekday = now.weekday;

    // Difference to get start of current week
    int diff = startFromMonday ? currentWeekday - 1 : currentWeekday % 7;

    // Start of current week
    DateTime startOfCurrentWeek = now.subtract(Duration(days: diff));

    // Move back by weeksAgo
    DateTime startOfTargetWeek = startOfCurrentWeek.subtract(
      Duration(days: 7 * weeksAgo),
    );

    // Generate 7 days
    return List.generate(
      7,
      (index) => startOfTargetWeek.add(Duration(days: index)),
    );
  }

  void createWeekMap() {
    selectedWeek =
        _getWeekDates(
          startFromMonday: false,
          weeksAgo: displayWeek,
        ).map((e) => e.toString()).toList();

    groupedWeekByCompletedDate = {};
    for (var day in _getWeekDates(
      startFromMonday: false,
      weeksAgo: displayWeek,
    )) {
      print("${day.weekday}\n");
      groupedWeekByCompletedDate[day.weekday] = [];
    }

    for (var entry in groupedByCompletedDate.entries) {
      final DateTime completed = DateTimeUtilsHelper.parseDateTime(entry.key);

      if (selectedWeek.any((d) {
        final DateTime day = DateTimeUtilsHelper.parseDateTime(d);
        //groupedWeekByCompletedDate[day.weekday] = [];

        return day.year == completed.year &&
            day.month == completed.month &&
            day.day == completed.day;
      })) {
        if (groupedWeekByCompletedDate.containsKey(completed.weekday)) {
          groupedWeekByCompletedDate[completed.weekday]!.addAll(entry.value);
        } else {
          groupedWeekByCompletedDate[completed.weekday] = [];
          groupedWeekByCompletedDate[completed.weekday]!.addAll(entry.value);
        }
      }
    }
    firstDate = DateTimeUtilsHelper.parseDateTime(selectedWeek[0]);
    lastDate = DateTimeUtilsHelper.parseDateTime(selectedWeek.last);
    firstDate = DateTimeUtilsHelper.toLocalUsingTz(firstDate);
    lastDate = DateTimeUtilsHelper.toLocalUsingTz(lastDate);
  }

  @override
  void initState() {
    super.initState();
    groupedPendingTasksByCategory = {
      for (var e in widget.db.categories) e: <List<dynamic>>[],
    };

    toDoList = widget.db.toDoList;
    missedTasks =
        toDoList.where((task) {
          DateTime? dueDateTimeUtc = _getUtcDateTime(task);
          if (dueDateTimeUtc == null) return false;
          return dueDateTimeUtc.isBefore(today) && task[1] == false;
        }).toList();
    pastTasks =
        toDoList.where((task) {
          DateTime? dueDateTimeUtc = _getUtcDateTime(task);
          if (dueDateTimeUtc == null) return false;
          return dueDateTimeUtc.isBefore(today);
        }).toList();
    pendingTasks =
        toDoList.where((task) {
          final dueDateTimeUtc = _getUtcDateTime(task);
          if (dueDateTimeUtc == null) return false;
          return (!(dueDateTimeUtc.isBefore(today)) && task[1] == false);
        }).toList();
    completedTasks = toDoList.where((task) => task[1] == true).toList();
    completedPastTasks =
        completedTasks.where((task) {
          final dueDateTimeUtc = _getUtcDateTime(task);
          if (dueDateTimeUtc == null) return false;
          return dueDateTimeUtc.isBefore(today) && task[1] == true;
        }).toList();
    for (var task in pendingTasks) {
      String priority = task[6];
      if (groupedPendingTasksByPriority.containsKey(priority)) {
        groupedPendingTasksByPriority[priority]!.add(task);
      } else {
        groupedPendingTasksByPriority[priority] = [];
        groupedPendingTasksByPriority[priority]!.add(task);
      }
    }
    for (var task in missedTasks) {
      String priority = task[6];
      if (groupedMissedTasksByPriority.containsKey(priority)) {
        groupedMissedTasksByPriority[priority]!.add(task);
      } else {
        groupedMissedTasksByPriority[priority] = [];
        groupedMissedTasksByPriority[priority]!.add(task);
      }
    }
    for (var task in pendingTasks) {
      String category = task[5];

      if (groupedPendingTasksByCategory.containsKey(category)) {
        groupedPendingTasksByCategory[category]!.add(task);
      } else {
        groupedPendingTasksByCategory[category] = [];
        groupedPendingTasksByCategory[category]!.add(task);
      }
    }
    for (var task in completedTasks) {
      DateTime completedDate = DateTimeUtilsHelper.parseDateTime(task[18]);
      String key = completedDate.toString();
      if (groupedByCompletedDate.containsKey(key)) {
        groupedByCompletedDate[key]!.add(task);
      } else {
        groupedByCompletedDate[key] = [];
        groupedByCompletedDate[key]!.add(task);
      }
    }
    createWeekMap();

    print(
      "----${selectedWeek}---$groupedWeekByCompletedDate-----------$groupedByCompletedDate",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics Page')),
      body: ListView(
        children: [
          SizedBox(height: 20),
          Column(
            children: [
              CircularPercentIndicator(
                linearGradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
                animation: true,
                animationDuration: 800,
                radius: 60.0,
                lineWidth: 10.0,
                percent:
                    pastTasks.isNotEmpty
                        ? completedPastTasks.length / pastTasks.length
                        : 0,
                center: Text(
                  pastTasks.isNotEmpty
                      ? "${(completedPastTasks.length / pastTasks.length * 100).round()}%"
                      : "N/A",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                //progressColor: Colors.blue,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(height: 20),
              Text(
                "Task Completion Rate",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: StatisticsTile(
              isPending: false,
              tasksMap: groupedMissedTasksByPriority,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: StatisticsTile(
              isPending: true,
              tasksMap: groupedPendingTasksByPriority,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(8),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // border: Border.all(),
                color: Theme.of(context).colorScheme.secondary,
              ),
              width: 150,
              height: 200,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Tasks completed daily :"),
                      Spacer(),
                      Container(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  groupedWeekByCompletedDate = {};
                                  displayWeek++;
                                  createWeekMap();
                                });
                              },
                              icon: Icon(Icons.chevron_left),
                            ),
                            Text(
                              "${DateFormat('MMM dd').format(firstDate)}-${DateFormat('MMM dd').format(lastDate)}",
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  groupedWeekByCompletedDate = {};
                                  displayWeek--;
                                  createWeekMap();
                                });
                              },
                              icon: Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: MyBarChart(
                      mappedWeek: groupedWeekByCompletedDate,
                      isFromMonday: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 250,
              height: 350,
              child: Column(
                children: [
                  Text("Pending tasks by category :"),
                  SizedBox(height: 30),
                  Expanded(
                    child: MyPieChart(
                      color: Theme.of(context).colorScheme.primary,
                      mappedPending: groupedPendingTasksByCategory,
                      total: pendingTasks.length,
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
