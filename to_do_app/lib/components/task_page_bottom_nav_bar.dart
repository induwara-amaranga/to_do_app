import 'package:flutter/material.dart';

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
        // Handle navigation logic here
      },
    );
  }
}
