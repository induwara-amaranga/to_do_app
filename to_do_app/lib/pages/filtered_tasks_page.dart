import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/components/task_tile.dart';
//import 'package:table_calendar/table_calendar.dart';
import 'package:to_do_app/components/tasktile.dart';
import 'package:to_do_app/services/filter_tasks_service.dart';

class Filteredtaskspage extends StatefulWidget {
  final Map<String, dynamic>? filterData;
  final List<List<dynamic>> toDoList;
  final void Function(int, dynamic)? onTaskChanged;
  final Function(int, bool?)? onChanged;
  final Function(int)? deleteFunction;
  final List<String> categoryTypes;

  const Filteredtaskspage({
    super.key,
    required this.categoryTypes,
    required this.deleteFunction,
    required this.onChanged,
    this.onTaskChanged,
    required this.filterData,
    required this.toDoList,
  });

  @override
  State<Filteredtaskspage> createState() => _FilteredtaskspageState();
}

class _FilteredtaskspageState extends State<Filteredtaskspage> {
  List<String> repeatTypes = ["daily", "weekly", "monthly", "yearly"];
  List<String> priorityTypes = ["Low", "Medium", "High"];
  List<String> remainderTypes = ["minutes", "hours", "days"];
  List<List<dynamic>> filteredTasks = [];
  @override
  void initState() {
    super.initState();
    filteredTasks = FilterTasksService.filterTasksByCategory(
      widget.toDoList,
      widget.filterData,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List<List<dynamic>> filteredTasks =
    //     FilterTasksService.filterTasksByCategory(
    //       widget.toDoList,
    //       widget.filterData,
    //     );

    print("filteredTasks:$filteredTasks");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Filtered Tasks",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body:
          filteredTasks.isEmpty
              ? Center(
                child: Text(
                  "No tasks found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = filteredTasks.removeAt(oldIndex);
                    filteredTasks.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];

                  return Container(
                    key: ValueKey(
                      task[0] + index.toString(),
                    ), // unique key for reorder
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: TaskTile(
                      disableCompleted: () {},
                      initialSubtasks:
                          task[13] != null
                              ? List<Map<String, dynamic>>.from(task[13])
                              : [],
                      index: widget.toDoList.indexOf(task),
                      isStarred: task[10] == "true",
                      taskName: task[0],
                      taskCompleted: task[1],
                      taskNote: task[2],
                      dueDate: DateFormat('yyyy-MM-dd').parse(task[3]!),
                      dueTime:
                          task[4] != "00:00"
                              ? DateFormat("HH:mm").parse(task[4]!)
                              : null,
                      taskCategory: task[5],
                      taskPriority: task[6],
                      repeatType: task[7],
                      remainderAmount: task[8],
                      remainderType: task[9],
                      onChanged: (index, value) {
                        setState(() {
                          widget.onChanged?.call(index, value);
                        });
                      },
                      deleteFunction: (index) {
                        setState(() {
                          widget.deleteFunction?.call(index);
                        });
                      },
                      onEdit: (index, taskDetails) {
                        setState(() {
                          widget.onTaskChanged?.call(index, taskDetails);
                        });
                      },
                      repeatTypes: repeatTypes,
                      priorityTypes: priorityTypes,
                      remainderTypes: remainderTypes,
                      categoryTypes: widget.categoryTypes,
                    ),
                  );
                },
              ),
    );
  }
}
