import 'package:flutter/material.dart';
import 'package:googleapis/compute/v1.dart';

class StatisticsTile extends StatelessWidget {
  final bool isPending;
  final Map<String, List<List<dynamic>>> tasksMap;
  late int total;
  late int low;
  late int medium;
  late int high;
  StatisticsTile({super.key, required this.isPending, required this.tasksMap}) {
    low = tasksMap['Low']!.length;
    medium = tasksMap['Medium']!.length;
    high = tasksMap['High']!.length;
    total = low + medium + high;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),

        // border: Border.all(
        //   color: Theme.of(context).colorScheme.primary,
        //   width: 2,
        // ),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Text(
            isPending ? "Pending Tasks : $total" : "Missed Tasks : $total",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 17),
          SizedBox(
            width: 230,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                priorityBox("High", high),
                priorityBox("Medium", medium),
                priorityBox("Low", low),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget priorityBox(String priority, int count) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              priority == "High"
                  ? Colors.red
                  : priority == "Medium"
                  ? const Color.fromARGB(255, 255, 223, 44)
                  : Colors.green,
          width: 3,
        ),

        color:
            priority == "High"
                ? Colors.red.shade300
                : priority == "Medium"
                ? Colors.yellow.shade300
                : Colors.green.shade300,
      ),
      child: Column(children: [Text(priority), Text(count.toString())]),
    );
  }
}
