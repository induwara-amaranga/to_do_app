import 'package:flutter/material.dart';
import 'package:to_do_app/components/app_bar_options_sheet.dart';
import 'package:to_do_app/components/edit_categories_dialog.dart';
import 'package:to_do_app/components/my_tab_bar.dart';
import 'package:to_do_app/components/search_bar.dart' as sb;
import 'package:to_do_app/components/task_filter.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/filtered_tasks_page.dart';
import 'package:to_do_app/pages/calender_sync_page.dart';
import 'package:to_do_app/pages/saved_timetables_page.dart';
import 'package:to_do_app/models/grouping_mode.dart';
import 'package:to_do_app/providers/grouping_provider.dart';
import 'package:to_do_app/providers/sorting_provider.dart';

import 'package:provider/provider.dart';
import 'package:to_do_app/models/sorting_mode.dart';
import 'package:uuid/uuid.dart';

class TaskPageAppBar extends StatefulWidget {
  final ToDoDataBase db;
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

  void _showOptionsSheet(BuildContext appBarContext) {
    showModalBottomSheet(
      context: appBarContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AppBarOptionsSheet(
            db: db,
            categoryTypes: widget.categoryTypes,
            categoriesAndPriorities: widget.categoriesAndPriorities,
            onCategoryChanged: widget.onCategoryChanged,
            hidingCategories: hidingCategories,
            onChanged: widget.onChanged,
            deleteFunction: widget.deleteFunction,
            onTaskChanged: widget.onTaskChnaged,
            parentContext: appBarContext,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 180,
      toolbarHeight: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      bottom: MyTabBar(
        controller: widget._tabController,
        taskCategoryTabs: widget._taskCategoryTabs,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          const maxHeight = 180;
          final minHeight = kToolbarHeight + kTextTabBarHeight;
          final collapseFactor =
              (constraints.maxHeight - minHeight) / (maxHeight - minHeight);

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
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: widget.openDrawer,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          tooltip: "View options",
                          onPressed: () => _showOptionsSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: sb.SearchBar(searchType: "task"),
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
