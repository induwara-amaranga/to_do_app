// //mport 'package:googleapis/docs/v1.dart';
// import 'dart:ffi';

// import 'package:to_do_app/main.dart';
// import 'package:flutter/material.dart';

// class TaskMethods {
//   static List<Tab> taskCategoryTabs(List<String> hidingCategories) {
//     return [
//       Tab(text: "All"),
//       ...db.categories
//           .where((c) => (c != "None" && !hidingCategories.contains(c)))
//           .map((d) => Tab(text: d))
//           .toList(),
//       Tab(text: "High"),
//       Tab(text: "Medium"),
//       Tab(text: "Low"),
//     ];
//     // ];
//   }

//   void checkBoxChanged(bool? value, int index) {
//     print("Checkbox at index $index changed to $value");

//     // Step 1: toggle checkbox
//     setState(() {
//       db.toDoList[index][1] = !db.toDoList[index][1];
//     });

//     // Step 2: handle repeating logic OUTSIDE setState
//     if (value == true && db.toDoList[index][7] != "none") {
//       RepeatTask.createNextRepeatTask(context, index, db);
//     }

//     // Step 3: refresh lists & persist data
//     setState(() {
//       toDoList = db.toDoList;
//       hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
//     });

//     db.updateDataBase();
//   }

//   void changeCategories({
//     required List<String> newCategories,
//     required List<String> hidingCategories,
//     required Map<String, String> edittingCategories,
//     required VoidCallback setState,
//     required TickerProvider vsync,
//     required List<List<dynamic>> toDoList,
//   }) {
//     db.categories = newCategories;
//     final _hidingCategories = hidingCategories;
//     print("hiding categories" + _hidingCategories.toString());
//     //_tabController.length=_taskCategoryTabs().length;
//     //_tabController.dispose();
//     final _tabController = TabController(
//       length: TaskMethods.taskCategoryTabs(_hidingCategories).length,
//       // vsync: vsync,
//     );
//     setState(() {
//       // Update existing tasks to reflect renamed or hidden categories
//       for (int i = 0; i < toDoList.length; i++) {
//         final task = toDoList[i];
//         String currentCategory = (task[5] ?? "None") as String;

//         // Rename category if present in edittingCategories (oldName -> newName)
//         if (edittingCategories.containsKey(currentCategory)) {
//           toDoList[i][5] = edittingCategories[currentCategory];
//           currentCategory = toDoList[i][5] as String;
//         }

//         // If category is being hidden, set task category to "None"
//         // if (hidingCategories.contains(currentCategory)) {
//         //   //db.toDoList[i][5] = "None";
//         // }
//       }

//       // Update selected category if it was renamed or hidden
//       if (hidingCategories.contains(_selectedCategory)) {
//         _selectedCategory = "None";
//       } else if (edittingCategories.containsKey(_selectedCategory)) {
//         _selectedCategory = edittingCategories[_selectedCategory]!;
//       }

//       // Refresh local copies and UI
//       //toDoList = db.toDoList;
//       //hotTasks = getUpcomingTasksWithinHotPeriod(toDoList);
//     });
//     print("new categories: $newCategories");

//     db.updateDataBase();
//   }
// }
