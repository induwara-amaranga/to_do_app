import 'package:flutter/material.dart';
import 'package:to_do_app/pages/task_page.dart';

class TaskBottomNavBar extends StatefulWidget {
  const TaskBottomNavBar({super.key});

  @override
  State<TaskBottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<TaskBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calender',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tasks'),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights),
          label: 'Statistics',
        ),
      ],
      currentIndex: 1,

      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withAlpha(100),
      onTap: (index) {
        if (index == 1) {
          Navigator.pushNamed(context, '/');
        } else if (index == 0) {
          Navigator.pushNamed(context, '/calendar');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/statistics');
        }
      },
    );
  }
}
