import 'package:flutter/material.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:to_do_app/components/create_task_sheet.dart';
import 'package:to_do_app/components/task_tile.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/models/types.dart';
import 'package:to_do_app/services/local_calendar_service.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/services/repeat_task.dart';
import 'package:to_do_app/utils/date_time_utils.dart';

class CalendarPage extends StatefulWidget {
  final ToDoDataBase db;
  const CalendarPage({super.key, required this.db});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime focusedDay = DateTime.now();
  DateTime firstDay = DateTime.utc(2000, 01, 01);
  DateTime lastDay = DateTime.utc(2100, 12, 31);
  DateTime selectedDay = DateTime.now();
  List<List<dynamic>> toDoList = [];
  List<List<dynamic>> tasksForSelectedDay = [];
  late final ToDoDataBase db;

  bool _isStarred = false;

  void checkBoxChanged(bool? value, int index) {
    print("Checkbox at index $index changed to $value");

    if (value != null) {
      if (value) {
        db.toDoList[index][18] = DateTime.now().toUtc().toString();
      } else {
        db.toDoList[index][18] = "none";
      }
    }

    // Step 1: toggle checkbox
    setState(() {
      toDoList[index][1] = !toDoList[index][1];
    });

    // Step 2: handle repeating logic OUTSIDE setState
    if (value == true && toDoList[index][7] != "none") {
      RepeatTask.createNextRepeatTask(context, index, db);
    }

    // Step 3: refresh lists & persist data
    setState(() {
      toDoList = toDoList;
      //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    });

    db.updateDataBase();
  }

  void saveNewTask(Map<String, dynamic> taskDetails) async {
    final selectedRemainderType = taskDetails['repeatType']; //7
    final selectedRemainderAmount = taskDetails['remainderAmount'];
    String id = uuid.v4();
    setState(() {
      print("adding tasks $taskDetails");
      db.toDoList.add([
        taskDetails['taskName'], //0
        false, //1
        taskDetails['taskNote'], //2
        taskDetails['dueDate'], //3
        taskDetails['dueTime'], //4
        taskDetails['taskCategory'], //5
        taskDetails['taskPriority'], //6
        taskDetails['repeatType'], //7
        taskDetails['remainderAmount'], //8
        taskDetails['remainderType'], //9
        taskDetails['isStarred'], //10
        taskDetails['createdAt'], //11
        id, //12
        taskDetails['subTasks'] ?? [], //13
        "", //14 cal id
        "", //15 event id
        "", //16 local cal event id
        "manual", //17 is synced
        "none", //18 completed at
        [], //19 notification ids
      ]);
    });

    // ⏰ Schedule notification if remainder is set
    if (selectedRemainderAmount >= 0 && selectedRemainderType != "none") {
      await NotificationService.scheduleInitialRemainderForTask(
        id,
        context,
        taskDetails,
        db,
        toDoList.length - 1,
      );
    }
    print("A F T E R   N E W   T A S K-----------------------------");
    print(db.toDoList);
    toDoList = db.toDoList;
    // categorizedToDOTasks =
    //     _taskCategoryTabs().map((tab) {
    //       return _buildTasksForTab(tab.text, grouping, sorting, query);
    //     }).toList();
    //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    db.updateDataBase();
    if (db.syncToCalendars["local"] != "none") {
      print("🔄");
      LocalCalendarService.addEvent(db.syncToCalendars["local"], [
        taskDetails['taskName'], //0
        false, //1
        taskDetails['taskNote'], //2
        taskDetails['dueDate'], //3
        taskDetails['dueTime'], //4
        taskDetails['taskCategory'], //5
        taskDetails['taskPriority'], //6
        taskDetails['repeatType'], //7
        taskDetails['remainderAmount'], //8
        taskDetails['remainderType'], //9
        taskDetails['isStarred'], //10
        taskDetails['createdAt'], //11
        id, //12
        taskDetails['subTasks'] ?? [], //13
        "", //14 cal id
        "", //15
        "", //16
      ]);
    }
    //print(db.toDoList);
    //_taskNameController.clear();
    //_taskNoteController.clear();
    //_remainderAmountController.clear();
  }

  void deleteTask(int index) async {
    await LocalCalendarService.deleteEvent(
      db.toDoList[index][16],
      db.syncToCalendars["local"],
    );
    for (int id in db.toDoList[index][19]) {
      print("calling to id $id for edited task");
      await NotificationService.cancelNotification(id);
    }
    setState(() {
      db.toDoList.removeAt(index);
    });
    toDoList = db.toDoList;
    // categorizedToDOTasks =
    //     _taskCategoryTabs().map((tab) {
    //       return _buildTasksForTab(tab.text, grouping, sorting, query);
    //     }).toList();
    //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    db.updateDataBase();
    if (db.syncToCalendars["local"] != "none" && db.toDoList[index][16] != "") {
      print("🔄");
    }
  }

  void editTask(int index, Map<String, dynamic> taskDetails) async {
    String id = uuid.v4();
    String oldId = db.toDoList[index][12];
    setState(() {
      db.toDoList[index][0] = taskDetails['taskName'];
      db.toDoList[index][2] = taskDetails['taskNote'];
      db.toDoList[index][3] = taskDetails['dueDate'];
      db.toDoList[index][4] = taskDetails['dueTime'];
      db.toDoList[index][5] = taskDetails['taskCategory'];
      db.toDoList[index][6] = taskDetails['taskPriority'];
      db.toDoList[index][7] = taskDetails['repeatType'];
      db.toDoList[index][8] = taskDetails['remainderAmount'];
      db.toDoList[index][9] = taskDetails['remainderType'];
      db.toDoList[index][10] = taskDetails['isStarred'];
      db.toDoList[index][11] = taskDetails['createdAt'];
      //db.toDoList[index][12] = id;
      db.toDoList[index][13] = taskDetails['subTasks'] ?? [];
    });

    for (int id in db.toDoList[index][19]) {
      print("calling to id $id for edited task");
      await NotificationService.cancelNotification(id);
    }

    // ⏰ Schedule notification if remainder is set
    if (taskDetails['remainderAmount'] >= 0 &&
        taskDetails['remainderType'] != "none") {
      await NotificationService.scheduleInitialRemainderForTask(
        id,
        context,
        taskDetails,
        db,
        index,
      );
      // DateTime? dueDate = DateTimeUtilsHelper.parseDate(taskDetails['dueDate']);
      // DateTime? dueTime = DateTimeUtilsHelper.parseTime(taskDetails['dueTime']);
      // DateTime remainderDateTime = NotificationService.remainderDateTime(
      //   dueDate!,
      //   dueTime!,
      //   //taskDetails['dueTime'],
      //   taskDetails['remainderType'],
      //   taskDetails['remainderAmount'],
      // );
      // try {
      //   NotificationService.sheduledTimeNotification(
      //     priority: taskDetails['taskPriority'],
      //     context: context,
      //     id: id.hashCode,
      //     title: "teask remainder" + " ",
      //     body: _taskNameController.text,
      //     year: remainderDateTime.year,
      //     month: remainderDateTime.month,
      //     day: remainderDateTime.day,
      //     hour: remainderDateTime.hour,
      //     minutes: remainderDateTime.minute,
      //     payload: [
      //       id,
      //       taskDetails['taskPriority'],
      //       DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
      //       "teask remainder",
      //       _taskNameController.text,
      //     ],
      //   );
      // } catch (e) {
      //   print("shedule error form task page => $e");
      // }
    }
    print("Edited task at index $index: ${db.toDoList[index]}");
    toDoList = db.toDoList;
    // categorizedToDOTasks =
    //     _taskCategoryTabs().map((tab) {
    //       return _buildTasksForTab(tab.text, grouping, sorting, query);
    //     }).toList();
    //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    if (db.syncToCalendars["local"] != "none") {
      print("🔄");
      LocalCalendarService.addEvent(db.syncToCalendars["local"], [
        taskDetails['taskName'], //0
        false, //1
        taskDetails['taskNote'], //2
        taskDetails['dueDate'], //3
        taskDetails['dueTime'], //4
        taskDetails['taskCategory'], //5
        taskDetails['taskPriority'], //6
        taskDetails['repeatType'], //7
        taskDetails['remainderAmount'], //8
        taskDetails['remainderType'], //9
        taskDetails['isStarred'], //10
        taskDetails['createdAt'], //11
        db.toDoList[index][12], //12
        taskDetails['subTasks'] ?? [], //13
        db.toDoList[index][14], //14 cal id
        db.toDoList[index][15], //15
        db.toDoList[index][16], //16
      ]);
    }
    db.updateDataBase();
  }

  @override
  void initState() {
    super.initState();
    db = widget.db;
    toDoList = widget.db.toDoList;
    tasksForSelectedDay =
        toDoList.where((task) {
          DateTime? dueDateUtc = DateTimeUtilsHelper.parseDate(task[3]);
          DateTime? dueTimeUtc = DateTimeUtilsHelper.parseTime(task[4]);
          //print("due date utc $dueDateUtc");
          DateTime? dueDate;
          if (dueDateUtc != null && dueTimeUtc != null) {
            dueDate = DateTimeUtilsHelper.toLocalUsingTz(
              DateTimeUtilsHelper.combineDateAndTimeFromStrings(
                task[3],
                task[4],
              ),
            );
          }

          if (dueDate != null) {
            return dueDate!.year == selectedDay.year &&
                dueDate!.month == selectedDay.month &&
                dueDate!.day == selectedDay.day;
          }
          return false;
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    focusedDay = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Page')),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TableCalendar(
              headerStyle: HeaderStyle(
                titleCentered: true,
                //formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  //fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, size: 28),
                rightChevronIcon: Icon(Icons.chevron_right, size: 28),
                headerPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',

                CalendarFormat.week: 'Week',
              },
              calendarFormat: calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),

              focusedDay: focusedDay,
              firstDay: firstDay,
              lastDay: lastDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  this.selectedDay = selectedDay;
                  this.focusedDay = focusedDay;
                  DateTime? dueDate;
                  tasksForSelectedDay =
                      toDoList.where((task) {
                        DateTime? dueDateUtc = DateTimeUtilsHelper.parseDate(
                          task[3],
                        );
                        DateTime? dueTimeUtc = DateTimeUtilsHelper.parseTime(
                          task[4],
                        );
                        //print("due date utc $dueDateUtc");
                        if (dueDateUtc != null && dueTimeUtc != null) {
                          dueDate = DateTimeUtilsHelper.toLocalUsingTz(
                            DateTimeUtilsHelper.combineDateAndTimeFromStrings(
                              task[3],
                              task[4],
                            ),
                          );
                        }

                        if (dueDate != null) {
                          return dueDate!.year == selectedDay.year &&
                              dueDate!.month == selectedDay.month &&
                              dueDate!.day == selectedDay.day;
                        }
                        return false;
                      }).toList();
                });
              },
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasksForSelectedDay.length,
              itemBuilder: (context, index) {
                List<dynamic> task = tasksForSelectedDay[index];
                return TaskTile(
                  source: task[17],
                  disableCompleted: () {
                    setState(() {
                      //isDuringAnimation = !isDuringAnimation;
                    });
                  },
                  key: ValueKey('${task[0]}_${task[12]}_${task.toString()}'),
                  initialSubtasks:
                      task[13] != null
                          ? (task[13] as List<dynamic>)
                              .map((e) => Map<String, dynamic>.from(e as Map))
                              .toList()
                          : [],
                  index: toDoList.indexOf(task),
                  isStarred: task[10] == "true",
                  taskName: task[0],
                  taskCompleted: task[1],
                  taskNote: task[2],
                  dueDate: DateTimeUtilsHelper.parseDate(task[3]),
                  dueTime:
                      task[4] != "00:00"
                          ? DateTimeUtilsHelper.parseTime(task[4])
                          : null,
                  taskCategory: task[5],
                  taskPriority: task[6],
                  repeatType: task[7],
                  remainderAmount: task[8],
                  remainderType: task[9],
                  onChanged: (index, value) => checkBoxChanged(value, index),
                  deleteFunction:
                      (context) => deleteTask(toDoList.indexOf(task)),
                  onEdit: (index, taskDetails) => editTask(index, taskDetails),
                  repeatTypes: repeatTypes,
                  priorityTypes: priorityTypes,
                  remainderTypes: remainderTypes,
                  categoryTypes: widget.db.categories,
                );
              },
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: FloatingActionButton(
          heroTag: "Add_Task",
          onPressed:
              () => showModalBottomSheet(
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                backgroundColor: Colors.transparent,
                context: context,
                builder:
                    (context) => CreateTaskSheet(
                      isStarred: _isStarred,
                      taskName: "",
                      taskNote: "",
                      initialSubtasks: [],
                      buttonText: "Add Task",

                      onSave: (taskDetails) {
                        // setState(() {
                        //   _selectedDueDate = taskDetails['dueDate'];
                        //   _selectedDueTime = taskDetails['dueTime'];
                        //   _selectedCategory = taskDetails['taskCategory'];
                        //   _selectedPriority = taskDetails['taskPriority'];
                        //   _selectedRepeatType = taskDetails['repeatType'];
                        //   _selectedRemainderAmount =
                        //       taskDetails['remainderAmount'];
                        //   _selectedRemainderType =
                        //       taskDetails['remainderType'];
                        //   _addedSubtasks = taskDetails['subTasks'] ?? [];
                        //   _isStarred = taskDetails['isStarred'];
                        // });
                        print("New task details: $taskDetails");
                        saveNewTask(taskDetails);
                      },
                      repeatTypes: repeatTypes,
                      priorityTypes: priorityTypes,
                      remainderTypes: remainderTypes,
                      categoryTypes: db.categories,
                    ),
              ),
          child: const Icon(Icons.add_rounded),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
