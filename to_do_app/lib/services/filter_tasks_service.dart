import 'package:to_do_app/utils/date_time_utils.dart'; // lib == to_do_app
//import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class FilterTasksService {
  static List<List<dynamic>> filterTasksByCategory(
    List<List<dynamic>> toDoList,
    Map<String, dynamic>? filterData,
  ) {
    List<List<dynamic>> filteredTasks =
        toDoList.where((task) {
          //return true;
          DateTime now = DateTime.now();

          DateTime? taskTime = DateTimeUtilsHelper.parseTime(task[4]);
          DateTime taskDate =
              DateTimeUtilsHelper.parseDate(task[3]) ?? DateTime(1970, 01, 01);
          // if (task[3] != null && task[3] != "0000-00-00") {
          //   try {
          //     taskDate = DateFormat('yyyy-MM-dd').parse(task[3]!);
          //   } catch (e) {
          //     taskDate = DateTime(1970, 01, 01);
          //   }
          // } else {
          //   taskDate = DateTime(1970, 01, 01);
          // }

          bool isCategoryMatched(
            List<dynamic> task,
            Map<String, dynamic>? filterData,
          ) {
            if ((filterData!["categories"].contains(task[5])) ||
                (filterData!["categories"].contains(task[6])) ||
                (filterData!["categories"].isEmpty) ||
                (filterData!["categories"].contains("Completed") &&
                    task[1] == true) ||
                (filterData!["categories"].contains("Pending") &&
                    (task[1] == false) &&
                    (taskDate.isAfter(now) ||
                        (taskDate.isAtSameMomentAs(
                              DateTime(now.year, now.month, now.day),
                            ) &&
                            (taskTime == null ||
                                (taskTime.hour > now.hour ||
                                    (taskTime.hour == now.hour &&
                                        taskTime.minute > now.minute)))))) ||
                (filterData!["categories"].contains("Missed") &&
                    (task[1] == false) &&
                    (taskDate.isBefore(now) ||
                        (taskDate.isAtSameMomentAs(
                              DateTime(now.year, now.month, now.day),
                            ) &&
                            (taskTime != null &&
                                (taskTime.hour < now.hour ||
                                    (taskTime.hour == now.hour &&
                                        taskTime.minute < now.minute))))))) {
              return true;
            } else {
              return false;
            }
          }

          // print(
          //   "++++++++" +
          //       task[0] +
          //       " : " +
          //       isCategoryMatched(task, widget.filterData).toString(),
          // );

          if ((filterData!["selectedDueDates"].isEmpty)) {
            if (isCategoryMatched(task, filterData)) {
              return true;
            }

            return false;
          } else if (!isSameDay(taskTime, DateTime(1970, 01, 01))) {
            for (DateTime date in filterData!["selectedDueDates"]) {
              //print("filter date:$date  task date:" + taskDate.toString());
              if ((filterData!["selectedFilter"] == "Selected_dates")) {
                // Ignore invalid dates for dueDate filter
                if (!isSameDay(
                      DateTime(date.year, date.month, date.day),
                      taskDate,
                    ) ||
                    !isCategoryMatched(task, filterData)) {
                  return false;
                }
              } else if ((filterData!["selectedFilter"] == "Before")) {
                if (!taskDate.isBefore(
                      DateTime(date.year, date.month, date.day),
                    ) ||
                    !isCategoryMatched(task, filterData)) {
                  return false;
                }
              } else if ((filterData!["selectedFilter"] == "After")) {
                if (!taskDate.isAfter(
                      DateTime(date.year, date.month, date.day),
                    ) ||
                    !isCategoryMatched(task, filterData)) {
                  return false;
                }
              }

              return true;
            }
            //return false;
          }

          return false;
        }).toList();
    return filteredTasks;
  }
}
