import 'package:flutter/material.dart';
import 'package:to_do_app/components/edit_categories_dialog.dart';
import 'package:to_do_app/components/my_tab_bar.dart';
import 'package:to_do_app/components/task_filter.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/filtered_tasks_page.dart';
import 'package:to_do_app/pages/calender_sync_page.dart';
import 'package:to_do_app/pages/manage_categories_page.dart';
import 'package:to_do_app/pages/saved_timetables_page.dart';
import 'package:to_do_app/models/grouping_mode.dart';
import 'package:to_do_app/providers/grouping_provider.dart';
import 'package:to_do_app/providers/sorting_provider.dart';
import 'package:to_do_app/providers/searching_provider.dart';

import 'package:provider/provider.dart';
import 'package:to_do_app/models/sorting_mode.dart';
import 'package:uuid/uuid.dart';

class TaskPageAppBar extends StatefulWidget {
  final ToDoDataBase db;
  //final List<List<dynamic>> toDoList;
  final List<String> categoryTypes;
  final List<Widget> Function() _taskCategoryTabs;
  final VoidCallback openDrawer;
  final void Function(int, dynamic) onTaskChnaged;
  final TabController _tabController;
  final List<String> categoriesAndPriorities;
  final BuildContext pageContext;
  final Function(int, bool?)? onChanged;
  final Function(int)? deleteFunction;
  final void Function(List<String>, List<String>, Map<String, String>)
  onCategoryChanged;
  final List<String> hidingCategories;

  const TaskPageAppBar({
    super.key,
    required this.db,
    required this.hidingCategories,
    required this.onCategoryChanged,
    required this.categoryTypes,
    required this.onChanged,
    required this.deleteFunction,
    required this.onTaskChnaged,
    //required this.toDoList,
    required this.pageContext,
    required this.categoriesAndPriorities,
    required this.openDrawer,
    required taskCategoryTabs,
    required tabController,
  }) : _taskCategoryTabs = taskCategoryTabs,
       _tabController = tabController;

  @override
  State<TaskPageAppBar> createState() => _TaskPageAppBarState();
}

//mutable
class _TaskPageAppBarState extends State<TaskPageAppBar>
    with SingleTickerProviderStateMixin {
  late List<String> hidingCategories;
  late ToDoDataBase db;
  final uuid = Uuid();
  @override
  void initState() {
    super.initState();
    hidingCategories = widget.hidingCategories;
    db = widget.db;
  }

  @override
  Widget build(BuildContext context) {
    //BuildContext parent = context;
    return SliverAppBar(
      //title: Text("To-Do App"),
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 180,
      toolbarHeight: 0, // must be > 0
      backgroundColor: Theme.of(context).colorScheme.primary,
      bottom: MyTabBar(
        controller: widget._tabController,
        taskCategoryTabs: widget._taskCategoryTabs,
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = 180;
          final minHeight = kToolbarHeight + kTextTabBarHeight;
          final collapseFactor =
              1 * (constraints.maxHeight - minHeight) / (maxHeight - minHeight);

          return Container(
            color: Theme.of(context).colorScheme.primary,
            child: SafeArea(
              child: Opacity(
                opacity:
                    collapseFactor.clamp(0.0, 1.0) > 0.7
                        ? collapseFactor.clamp(0.0, 1.0)
                        : 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: widget.openDrawer,
                        ),
                        Expanded(child: Text("")),
                        PopupMenuButton<String>(
                          borderRadius: BorderRadius.circular(20),
                          onSelected: (String value) {
                            // Handle menu action here
                            print("Selected: $value");
                            if (value == 'Saved_timetables') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const SavedTimetablesPage(),
                                ),
                              );
                            } else if (value == 'Change_categories') {
                              bool categoryAddedDeleted = false;
                              Map<String, String> editedCategories = {};

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      TextEditingController
                                      newCategoryController =
                                          TextEditingController();

                                      return EditCategoriesDialog(
                                        hidingCategories: hidingCategories,
                                        onCategoryChanged:
                                            widget.onCategoryChanged,
                                        categoryTypes: widget.categoryTypes,
                                      );
                                    },
                                  );
                                },
                              );
                            } else if (value == 'Sync_with') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CalenderSyncPage(db: db),
                                ),
                              );
                            } else if (value == 'Filter') {
                              showDialog(
                                context:
                                    context, // pass your scaffold's context
                                barrierDismissible: true,
                                builder: (BuildContext dialogContext) {
                                  return TaskFilter(
                                    onApply: (filterData) {
                                      // Close the dialog first
                                      //Navigator.of(dialogContext).pop();

                                      // Then navigate to the filtered tasks page
                                      // Navigator.pop(
                                      //   context,
                                      // ); // close dialog first

                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        Navigator.push(
                                          context, // now it's the parent caller context
                                          MaterialPageRoute(
                                            builder:
                                                (_) => Filteredtaskspage(
                                                  categoryTypes:
                                                      widget.categoryTypes,
                                                  deleteFunction:
                                                      widget.deleteFunction,
                                                  onChanged: widget.onChanged,

                                                  onTaskChanged:
                                                      widget.onTaskChnaged,
                                                  filterData: filterData,
                                                  toDoList: db.toDoList,
                                                  // as List<
                                                  //   List<dynamic>
                                                  // >,
                                                ),
                                          ),
                                        );
                                      });
                                    },
                                    categoriesAndPriorities:
                                        widget.categoriesAndPriorities,
                                    showCompleted: true,
                                    showPending: true,
                                    highPriorityOnly: true,
                                    selectedFilter: "Selected_dates",
                                    selectedDueDate: null,
                                  );
                                },
                              );
                            }

                            //Navigator.pop(context);
                          },
                          itemBuilder:
                              (
                                BuildContext context,
                              ) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  //value: 'Sort',
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Sort by"),
                                        Icon(Icons.chevron_right),
                                      ],
                                    ),
                                    onSelected: (subValue) {
                                      print("Selected sort: $subValue");

                                      final sortingProvider =
                                          context.read<SortingProvider>();

                                      switch (subValue) {
                                        case "aToz":
                                          sortingProvider.setMode(
                                            SortingMode.aToz,
                                          );
                                          break;
                                        case "zToa":
                                          sortingProvider.setMode(
                                            SortingMode.zToa,
                                          );
                                          break;
                                        case "createdDateIncreasing":
                                          sortingProvider.setMode(
                                            SortingMode.createdDateIncreasing,
                                          );
                                          break;
                                        case "createdDateDecreasing":
                                          sortingProvider.setMode(
                                            SortingMode.createdDateDecreasing,
                                          );
                                          break;
                                        case "dueDateIncreasing":
                                          sortingProvider.setMode(
                                            SortingMode.dueDateIncreasing,
                                          );
                                          break;

                                        case "dueDateDecreasing":
                                          sortingProvider.setMode(
                                            SortingMode.dueDateDecreasing,
                                          );
                                          break;
                                        case "starredFirst":
                                          sortingProvider.setMode(
                                            SortingMode.starredFirst,
                                          );
                                          break;
                                        case "nonStarredFirst":
                                          sortingProvider.setMode(
                                            SortingMode.nonStarredFirst,
                                          );
                                      }
                                    },

                                    itemBuilder:
                                        (context) =>
                                            SortingMode.values.map((mode) {
                                              return PopupMenuItem<String>(
                                                value:
                                                    mode
                                                        .toString()
                                                        .split('.')
                                                        .last,
                                                child: Text(
                                                  mode.displayName,
                                                ), // Shows just the enum name
                                              );
                                            }).toList(),
                                  ),
                                ),

                                const PopupMenuItem<String>(
                                  value: 'Filter',
                                  child: Row(
                                    children: [
                                      Text('Filter'),
                                      Spacer(),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  //value: 'group_by',
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      children: const [
                                        Text('group by'),
                                        Spacer(),
                                        Icon(Icons.chevron_right),
                                      ],
                                    ),
                                    onSelected: (subValue) {
                                      print("Selected group: $subValue");

                                      final groupingProvider =
                                          context.read<GroupingProvider>();

                                      switch (subValue) {
                                        case "Default":
                                          groupingProvider.setMode(
                                            GroupingMode.Default,
                                          );
                                          break;
                                        case "day":
                                          groupingProvider.setMode(
                                            GroupingMode.day,
                                          );
                                          break;
                                        case "month":
                                          groupingProvider.setMode(
                                            GroupingMode.month,
                                          );
                                          break;
                                        case "year":
                                          groupingProvider.setMode(
                                            GroupingMode.year,
                                          );
                                          break;
                                      }
                                    },

                                    itemBuilder:
                                        (context) =>
                                            GroupingMode.values.map((mode) {
                                              return PopupMenuItem<String>(
                                                value:
                                                    mode
                                                        .toString()
                                                        .split('.')
                                                        .last,
                                                child: Text(
                                                  "By " +
                                                      mode
                                                          .toString()
                                                          .split('.')
                                                          .last
                                                          .toLowerCase(),
                                                ), // Shows just the enum name
                                              );
                                            }).toList(),
                                  ),
                                ),

                                const PopupMenuItem<String>(
                                  value: 'Change_categories',
                                  child: Row(
                                    children: [
                                      Text('Change categories'),
                                      Spacer(),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Saved_timetables',
                                  child: Row(
                                    children: [
                                      Text('Saved timetables'),
                                      Spacer(),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Sync_with',
                                  child: Row(
                                    children: [
                                      Text('Sync with'),
                                      Spacer(),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search...",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (value) {
                            // Get the provider and update the query
                            context.read<SearchingProvider>().setQuery(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
