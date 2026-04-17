import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_app/components/sync_tile.dart';
import 'package:to_do_app/models/types.dart';
import 'package:to_do_app/providers/calendar_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/components/create_task_sheet.dart';
import 'package:to_do_app/components/drawer.dart';
import 'package:to_do_app/components/task_page_appbar.dart';
import 'package:to_do_app/components/task_page_bottom_nav_bar.dart';
import 'package:to_do_app/components/task_tile.dart';
import 'package:to_do_app/data/database.dart';
//import 'package:intl/intl.dart';
//import 'package:to_do_app/pages/completed_tasks_page.dart';
import 'package:to_do_app/providers/grouping_provider.dart';
import 'package:to_do_app/providers/sorting_provider.dart';
import 'package:to_do_app/providers/searching_provider.dart';
import 'package:to_do_app/services/google_calendar_service.dart';
import 'package:to_do_app/services/google_sign.dart';
import 'package:to_do_app/services/local_calendar_service.dart';
//import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:to_do_app/services/group_tasks_service.dart';
import 'package:to_do_app/models/grouping_mode.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/services/outlook_calendar_service.dart';
import 'package:to_do_app/services/outlook_sign.dart';
import 'package:to_do_app/services/repeat_task.dart';
import 'package:to_do_app/services/search_tasks.dart';
import 'package:to_do_app/services/sort_tasks_service.dart';
import 'package:to_do_app/models/sorting_mode.dart';
import 'package:to_do_app/utils/date_time_utils.dart';
import 'package:uuid/uuid.dart';

class TaskPage extends StatefulWidget {
  final ToDoDataBase db;
  final bool updateMissedTasks;
  final String? filePath;
  const TaskPage({
    super.key,
    required this.filePath,
    required this.updateMissedTasks,
    required this.db,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

//enum GroupingMode { Default, day, month, year }

class _TaskPageState extends State<TaskPage> with TickerProviderStateMixin {
  bool googleRestored = false;
  bool outlookRestored = false;
  //to do list
  List<List<dynamic>> toDoList = [];
  late List<Widget> categorizedToDOTasks;
  late Map<String, List<List<dynamic>>> hotTasks;
  Color warningColor = Colors.white;

  var _addedSubtasks;
  var uuid = Uuid();
  late TabController _tabController;
  GroupingMode selectedGrouping = GroupingMode.Default;
  SortingMode selectedSorting = SortingMode.createdDateDecreasing;
  bool isDuringAnimation = false;
  //SortingMode selectedSorting = SortingMode.starredFirst;

  // db.categories.map(d);
  // [
  //   Tab(text: "All"),
  //   Tab(text: "Work"),
  //   Tab(text: "Personal"),
  //   Tab(text: "Study"),
  //   Tab(text: "High"),
  //   Tab(text: "Medium"),
  //   Tab(text: "Low"),

  bool _isStarred = false;
  String _selectedDueDate = "";
  String _selectedDueTime = "";
  String _selectedCategory = "None";
  String _selectedPriority = "Low";
  String _selectedRepeatType = "none";
  int _selectedRemainderAmount = 0;
  String _selectedRemainderType = "minutes";
  String groupType = "Default";
  String sortType = "Default";

  List<String> _hidingCategories = [];

  final _taskNameController = TextEditingController();
  final _taskNoteController = TextEditingController();
  final _remainderAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 100,
  );
  //final _myBox = Hive.box("mybox");
  late ToDoDataBase db; //= ToDoDataBase();
  List<Tab> _taskCategoryTabs() {
    return [
      Tab(text: "All"),
      ...db.categories
          .where((c) => (c != "None" && !_hidingCategories.contains(c)))
          .map((d) => Tab(text: d))
          .toList(),
      Tab(text: "High"),
      Tab(text: "Medium"),
      Tab(text: "Low"),
    ];
    // ];
  }

  void changeCategories(
    List<String> newCategories,
    List<String> hidingCategories,
    Map<String, String> edittingCategories,
  ) {
    db.categories = newCategories;
    _hidingCategories = hidingCategories;
    print("hiding categories" + _hidingCategories.toString());
    //_tabController.length=_taskCategoryTabs().length;
    _tabController.dispose();
    _tabController = TabController(
      length: _taskCategoryTabs().length,
      vsync: this,
    );
    setState(() {
      // Update existing tasks to reflect renamed or hidden categories
      for (int i = 0; i < db.toDoList.length; i++) {
        final task = db.toDoList[i];
        String currentCategory = (task[5] ?? "None") as String;

        // Rename category if present in edittingCategories (oldName -> newName)
        if (edittingCategories.containsKey(currentCategory)) {
          db.toDoList[i][5] = edittingCategories[currentCategory];
          currentCategory = db.toDoList[i][5] as String;
        }

        // If category is being hidden, set task category to "None"
        // if (hidingCategories.contains(currentCategory)) {
        //   //db.toDoList[i][5] = "None";
        // }
      }

      // Update selected category if it was renamed or hidden
      if (hidingCategories.contains(_selectedCategory)) {
        _selectedCategory = "None";
      } else if (edittingCategories.containsKey(_selectedCategory)) {
        _selectedCategory = edittingCategories[_selectedCategory]!;
      }

      // Refresh local copies and UI
      //toDoList = db.toDoList;
      //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    });
    print("new categories: $newCategories");

    db.updateDataBase();
  }

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
      db.toDoList[index][1] = !db.toDoList[index][1];
    });

    // Step 2: handle repeating logic OUTSIDE setState
    if (value == true && db.toDoList[index][7] != "none") {
      RepeatTask.createNextRepeatTask(context, index, db);
    }

    // Step 3: refresh lists & persist data
    setState(() {
      toDoList = db.toDoList;
      hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    });

    db.updateDataBase();
  }

  void saveNewTask(Map<String, dynamic> taskDetails) async {
    final selectedRemainderType = taskDetails['repeatType']; //7
    final selectedRemainderAmount = taskDetails['remainderAmount'];
    String id = uuid.v4();
    List<dynamic> task = [
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
      ["", "", ""], //16  cal event ids
      "manual", //17 is synced
      "none", //18 completed at
      [], //19 notification ids
    ];
    print("at task page details: $taskDetails");
    setState(() {
      print("adding tasks $taskDetails");
      db.toDoList.add(task);
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
      // DateTime? dueDate = DateTimeUtilsHelper.parseDate(_selectedDueDate);
      // DateTime? dueTime = DateTimeUtilsHelper.parseTime(_selectedDueTime);
      // DateTime remainderDateTime = NotificationService.remainderDateTime(
      //   dueDate!,
      //   dueTime!,
      //   _selectedRemainderType,
      //   _selectedRemainderAmount,
      // );
      // try {
      //   NotificationService.sheduledTimeNotification(
      //     priority: _selectedPriority,
      //     context: context,
      //     id: id.hashCode,
      //     title: "teask remainder",
      //     body: _taskNameController.text,
      //     year: remainderDateTime.year,
      //     month: remainderDateTime.month,
      //     day: remainderDateTime.day,
      //     hour: remainderDateTime.hour,
      //     minutes: remainderDateTime.minute,
      //     payload: [
      //       id,
      //       _selectedPriority,
      //       DateTimeUtilsHelper.combineDateAndTime(dueDate, dueTime),
      //       "teask remainder",
      //       _taskNameController.text,
      //     ],
      //   );
      // } catch (e) {
      //   print("shedule error form task page => $e");
      // }
    }
    print("A F T E R   N E W   T A S K-----------------------------");
    print(db.toDoList);
    toDoList = db.toDoList;
    // categorizedToDOTasks =
    //     _taskCategoryTabs().map((tab) {
    //       return _buildTasksForTab(tab.text, grouping, sorting, query);
    //     }).toList();
    hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    db.updateDataBase();
    await addOrUpdateEvent(task);

    //print(db.toDoList);
    _taskNameController.clear();
    _taskNoteController.clear();
    _remainderAmountController.clear();
  }

  void deleteTask(int index) async {
    await deleteEvent(db.toDoList[index]);
    print("notifications ${db.toDoList[index][19]}");
    for (int id in db.toDoList[index][19]) {
      print("calling to id $id for deleted task");
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
    hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    db.updateDataBase();
    if (db.syncToCalendars["local"] != "none" &&
        db.toDoList[index][16][0] != "") {
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
      print("calling to id $id for deleted task");
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
    hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //generate a scaffold key to control the drawer

  @override
  void initState() {
    super.initState();
    print("task page zone: ${tz.local.name}");
    db = widget.db;
    //WidgetsBinding.instance.addPostFrameCallback((_) => importViewOnly());

    _remainderAmountController.text = _selectedRemainderAmount.toString();
    _tabController = TabController(
      length: _taskCategoryTabs().length,
      vsync: this,
    );
    if (widget.updateMissedTasks)
      RepeatTask.createPendingRepeatTasks(db, context);
    //print(db.toDoList);
    grouping = context.read<GroupingProvider>().mode;
    sortingProvider = context.read<SortingProvider>();
    sorting = sortingProvider.mode;
    //doSort = context.watch<SortingProvider>().doSort;

    query = context.read<SearchingProvider>().query;
    toDoList = db.toDoList;
    hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
    //sync calendars

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (db.syncToCalendars["google"] != "none") {
        try {
          //if (db.syncToCalendars["google"] != "none") {
          bool isReay = await GoogleAuthService.ensureApisReady();
          print("Google APIs ready: $isReay");
        } catch (d) {
          print("Failed to sync google calendars: $d");
        }
      }
      if (db.syncToCalendars["outlook"] != "none") {
        try {
          outlookRestored =
              await OutlookAuthService.acquireTokenSilently() != null
                  ? true
                  : false;
        } catch (d) {
          print("Failed to sync outlook calendars: $d");
        }
      }
      if (googleRestored) {
        print("google calendar session restored.");
      } else if (outlookRestored) {
        print("outlook calendar session restored.");
      }
      await importViewOnly();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  late SortingProvider sortingProvider;
  late GroupingMode grouping;
  late SortingMode sorting;
  late String query;
  //late CalendarSyncProvider sync;

  bool showCompletedTasks = false;

  //late bool doSort;
  @override
  Widget build(BuildContext context) {
    grouping = context.watch<GroupingProvider>().mode;
    sortingProvider = context.watch<SortingProvider>();
    sorting = sortingProvider.mode;
    //doSort = context.watch<SortingProvider>().doSort;
    context.watch<CalendarSyncProvider>();

    query = context.watch<SearchingProvider>().query;
    print("rebuilding task page ${db.toDoList}");

    return Scaffold(
      drawer: MyDrawer(
        db: db,
        filePath: widget.filePath,
        onImported: () {
          db.loadData();
          print(
            "🔄 Drawer import callback - DB reloaded: ${db.categories} tasks",
          );

          //db.loadData();
          _tabController.dispose();
          _tabController = TabController(
            length: _taskCategoryTabs().length,
            vsync: this,
          );
          toDoList = db.toDoList;
          hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
          setState(() {});
        },
      ),

      key: _scaffoldKey, // assign the key to this Scaffold
      bottomNavigationBar: const TaskBottomNavBar(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            TaskPageAppBar(
              //toDoList: db.toDoList,
              db: db,
              hidingCategories: _hidingCategories,
              onCategoryChanged:
                  (newC, hidden, editting) =>
                      changeCategories(newC, hidden, editting),
              categoryTypes: db.categories,
              onChanged: (index, value) => checkBoxChanged(value, index),
              deleteFunction: (index) => deleteTask(index),
              onTaskChnaged: (index, taskDetails) {
                setState(() {
                  editTask(index, taskDetails);
                });
              },
              //toDoList: db.toDoList,
              pageContext: context,
              categoriesAndPriorities:
                  db.categories +
                  ["High", "Medium", "Low"] +
                  ["Completed", "Pending", "Missed"],
              openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              taskCategoryTabs: _taskCategoryTabs,
              tabController: _tabController,
            ),
          ];
        },
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children:
                  _taskCategoryTabs().map((tab) {
                    return _buildTasksForTab(
                      tab.text,
                      grouping,
                      sorting,
                      query,
                    );
                  }).toList(),
            ),
            warningColor != Colors.white
                ? Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    onPressed: () => showPendingPriorityTasksDialog(context),
                    child: Icon(Icons.warning),
                    backgroundColor: warningColor,
                  ),
                )
                : Container(),
            Positioned(
              top: 0,
              left: 0,
              child: Consumer<CalendarSyncProvider>(
                builder: (_, sync, __) {
                  if (!sync.isSyncing) return SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      child: Row(
                        children: [
                          Text(
                            "Syncing ${(sync.progress * 100).toStringAsFixed(0)}% ",
                            style: TextStyle(
                              color: Colors.grey[700],
                              // fontWeight: FontWeight.,
                            ),
                          ),
                          SizedBox(
                            height: 4,
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: LinearProgressIndicator(
                              value: sync.progress,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
          const SizedBox(height: 10),
          !isDuringAnimation
              ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: FloatingActionButton(
                  heroTag: "Completed_Tasks",
                  onPressed: () {
                    setState(() {
                      showCompletedTasks = !showCompletedTasks;
                    });
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder:
                    //         (context) =>
                    //             const CompletedTaskPage(updateMissedTasks: false),
                    //   ),
                    // );
                  },
                  child:
                      showCompletedTasks
                          ? const Icon(Icons.close_rounded)
                          : const Icon(Icons.check_rounded),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
              : SizedBox(height: 55),
        ],
      ),
    );
  }

  Widget _buildTasksForTab(
    String? tabName,
    GroupingMode grouping,
    SortingMode sorting,
    String query,
  ) {
    List tasksOfThisTab;

    if (tabName == "All") {
      SortTasksService.sortTasksByMode(db.toDoList, sorting)
          as List<List<dynamic>>;
      tasksOfThisTab = db.toDoList;
    } else if (db.categories.contains(tabName)) {
      tasksOfThisTab = db.toDoList.where((t) => t[5] == tabName).toList();
    } else if (["High", "Medium", "Low"].contains(tabName)) {
      tasksOfThisTab = db.toDoList.where((t) => t[6] == tabName).toList();
    } else {
      tasksOfThisTab = [];
    }

    //tasksOfThisTab = [...tasksOfThisTab, ...db.calTasks];

    // tasksOfThisTab.addAll(db.calTasks);

    // Filter out completed tasks
    if (showCompletedTasks) {
      tasksOfThisTab = tasksOfThisTab.where((t) => t[1]).toList();
    } else {
      tasksOfThisTab = tasksOfThisTab.where((t) => !t[1]).toList();
    }

    // Apply search filter
    tasksOfThisTab = SearchTasks.searchByQuery(query, tasksOfThisTab);

    // Apply sorting
    tasksOfThisTab = SortTasksService.sortTasksByMode(tasksOfThisTab, sorting);

    // // Combine all value lists
    // List<dynamic> combined =
    //     db.viewOnlyCalendars.values.expand((v) => v).toList();

    // //check for calendar sync
    // tasksOfThisTab =
    //     tasksOfThisTab
    //         .where((t) => combined.contains(t[14]) || t[14] == "")
    //         .toList();

    // Group by selected mode
    Map<String, List> grouped = GroupTasksService.groupTasksByMode(
      tasksOfThisTab.cast<List<dynamic>>(),
      grouping,
      showCompletedTasks,
    );

    //groupe calendar tasks
    Map<String, List> groupedLocalCalTasks = GroupTasksService.groupTasksByMode(
      db.localCalTasks.cast<List<dynamic>>(),
      grouping,
      showCompletedTasks,
    );
    Map<String, List> groupedGoogleCalTasks =
        GroupTasksService.groupTasksByMode(
          db.googleCalTasks.cast<List<dynamic>>(),
          grouping,
          showCompletedTasks,
        );
    Map<String, List> groupedOutlookCalTasks =
        GroupTasksService.groupTasksByMode(
          db.outlookCalTasks.cast<List<dynamic>>(),
          grouping,
          showCompletedTasks,
        );

    // State for expanded groups
    final Map<String, bool> expandedGroups = {
      "today": true,

      //fore date like "2023-08"
      DateTime.now().toString().substring(0, 7): true,
      DateTime.now().toString().substring(0, 4): true,

      //for date like "2023-08-15"
      DateTime.now().toString().substring(0, 10): true,

      //for date like "2023"
      DateTime.now().year.toString(): true,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children:
          grouped.entries.map((entry) {
            final groupKey = entry.key;
            final groupTasks = entry.value;
            // print(
            //   "expanding group:$groupKey:${expandedGroups[groupKey] ?? false}",
            // );

            return StatefulBuilder(
              builder: (context, setInnerState) {
                final isExpanded = expandedGroups[groupKey] ?? false;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isExpanded,
                      title: Text(
                        groupKey.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onExpansionChanged:
                          (val) => setInnerState(
                            () => expandedGroups[groupKey] = val,
                          ),

                      children: [
                        ...groupedLocalCalTasks[groupKey]!.map(
                          (e) => SyncTile(task: e),
                        ),
                        ...groupedGoogleCalTasks[groupKey]!.map(
                          (e) => SyncTile(task: e),
                        ),
                        ...groupedOutlookCalTasks[groupKey]!.map(
                          (e) => SyncTile(task: e),
                        ),

                        if (groupTasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No tasks",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupTasks.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final movingTaskId = groupTasks[oldIndex][12];
                              final destinationTaskID =
                                  groupTasks[newIndex][12];

                              oldIndex = db.toDoList.indexWhere(
                                (task) => task[12] == movingTaskId,
                              );
                              newIndex = db.toDoList.indexWhere(
                                (task) => task[12] == destinationTaskID,
                              );

                              final task = db.toDoList.removeAt(oldIndex);
                              db.toDoList.insert(newIndex, task);
                              db.updateDataBase();
                              sortingProvider.setMode(SortingMode.manual);

                              setState(() {});
                            },
                            itemBuilder: (context, index) {
                              final task = groupTasks[index];
                              // if (task[17]) {
                              //   return SyncTile(
                              //     key: ValueKey('${task[15]}_${task[12]}'),
                              //     task: task,
                              //   );
                              // }

                              return TaskTile(
                                source: task[17],
                                disableCompleted: () {
                                  setState(() {
                                    isDuringAnimation = !isDuringAnimation;
                                  });
                                },
                                key: ValueKey(
                                  '${task[0]}_${task[12]}_${task.toString()}',
                                ),
                                initialSubtasks:
                                    task[13] != null
                                        ? (task[13] as List<dynamic>)
                                            .map(
                                              (e) => Map<String, dynamic>.from(
                                                e as Map,
                                              ),
                                            )
                                            .toList()
                                        : [],
                                index: db.toDoList.indexOf(task),
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
                                onChanged:
                                    (index, value) =>
                                        checkBoxChanged(value, index),
                                deleteFunction:
                                    (context) =>
                                        deleteTask(db.toDoList.indexOf(task)),
                                onEdit:
                                    (index, taskDetails) =>
                                        editTask(index, taskDetails),
                                repeatTypes: repeatTypes,
                                priorityTypes: priorityTypes,
                                remainderTypes: remainderTypes,
                                categoryTypes: db.categories,
                              );
                            },
                          ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Map<String, List<List<dynamic>>> getUpcomingTasksWithinHotPeriod(
    List<List<dynamic>> toDoList,
  ) {
    final now = DateTime.now().toUtc();
    final twoHoursLater = now.add(const Duration(hours: 2));
    final oneHourLater = now.add(const Duration(hours: 1));

    final Map<String, List<List<dynamic>>> result = {'High': [], 'Medium': []};

    for (var task in toDoList) {
      final String priority = task[6] ?? '';
      final String dueDateStr = task[3] ?? '';
      final String dueTimeStr = task[4] ?? '';

      // Combine date and time safely
      DateTime? dueDate = DateTime.tryParse('$dueDateStr $dueTimeStr')!;
      dueDate = DateTime.utc(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueDate.hour,
        dueDate.minute,
        dueDate.second,
      );
      if (dueDate == null) continue;
      print("Due date for task from $now: $dueDate");
      if (dueDate.isAfter(now) && !task[1]) {
        if (priority == 'High' && dueDate.isBefore(twoHoursLater)) {
          result['High']!.add(task);
        } else if (priority == 'Medium' && dueDate.isBefore(oneHourLater)) {
          result['Medium']!.add(task);
        }
      }
    }

    //print("==============" + result.toString());
    if (result['High']!.isNotEmpty) {
      warningColor = Colors.red;
    } else if (result['Medium']!.isNotEmpty) {
      warningColor = const Color.fromARGB(255, 255, 193, 59);
    } else {
      warningColor = Colors.white;
    }
    print("Warning color: $result");

    return result;
  }

  void showPendingPriorityTasksDialog(BuildContext context) {
    List<List<dynamic>> highPriorityTasks = hotTasks['High'] ?? [];
    List<List<dynamic>> mediumPriorityTasks = hotTasks['Medium'] ?? [];

    if (highPriorityTasks.isEmpty && mediumPriorityTasks.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top accent bar
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Center(
                  child: Text(
                    'Pending Priority Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Scrollable list of tasks
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // High Priority
                        if (highPriorityTasks.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'High Priority',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...highPriorityTasks.map(
                            (task) => Card(
                              color: Colors.red[50],
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.priority_high,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  task[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Due: ${task[3]} ${task[4]}'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Medium Priority
                        if (mediumPriorityTasks.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Medium Priority',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...mediumPriorityTasks.map(
                            (task) => Card(
                              color: Colors.orange[50],
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.low_priority,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  task[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Due: ${task[3]} ${task[4]}'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Fixed OK button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> addOrUpdateEvent(List<dynamic> task) async {
    String localCalendarId = db.syncToCalendars["local"];
    String outlookCalendarId = db.syncToCalendars["outlook"];
    String googleCalendarId = db.syncToCalendars["google"];
    if (localCalendarId != "none") {
      await LocalCalendarService.addEvent(localCalendarId, task);
    }
    if (outlookCalendarId != "none") {
      await OutlookCalendarService.addOrUpdateEvent(outlookCalendarId, task);
    }
    if (googleCalendarId != "none") {
      await GoogleCalendarService.addOrUpdateEvent(googleCalendarId, task);
    }
  }

  Future<void> deleteEvent(List<dynamic> task) async {
    String localCalendarId = db.syncToCalendars["local"];
    String outlookCalendarId = db.syncToCalendars["outlook"];
    String googleCalendarId = db.syncToCalendars["google"];
    if (localCalendarId != "none") {
      await LocalCalendarService.deleteEvent(localCalendarId, task[16][0]);
    }
    if (outlookCalendarId != "none") {
      await OutlookCalendarService.deleteEvent(outlookCalendarId, task[16][2]);
    }
    if (googleCalendarId != "none") {
      await GoogleCalendarService.deleteEvent(googleCalendarId, task[16][2]);
    }
  }

  Future<void> importViewOnly() async {
    final syncProvider = context.read<CalendarSyncProvider>();

    String localCalendarId = db.syncToCalendars["local"];
    String outlookCalendarId = db.syncToCalendars["outlook"];
    String googleCalendarId = db.syncToCalendars["google"];

    if (localCalendarId == "none" &&
        outlookCalendarId == "none" &&
        googleCalendarId == "none")
      return;
    syncProvider.startSync();
    if (localCalendarId != "none") {
      try {
        print("Syncing local calendars...");
        await LocalCalendarService.syncTasksFromCalendar(db);
        syncProvider.updateProgress(0.3);
      } catch (e) {
        print("Failed to sync local calendars: $e");
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      // await Future.delayed(const Duration(milliseconds: 2000));
    }
    if (outlookCalendarId != "none") {
      try {
        print("Syncing outlook calendars...");
        await OutlookCalendarService.syncTasksFromCalendar(db);
        syncProvider.updateProgress(0.5);
      } catch (e) {
        print("Failed to sync outlook calendars: $e");
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (googleCalendarId != "none") {
      try {
        print("Syncing google calendars...");
        await GoogleCalendarService.syncTasksFromCalendars(db);
        syncProvider.updateProgress(0.8);
      } catch (e) {
        print("Failed to sync google calendars: $e");
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    syncProvider.finishSync();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Calendar synced successfully")));
  }
}
