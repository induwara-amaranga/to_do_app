import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/components/google_calendar_tile.dart';
import 'package:to_do_app/components/local_calendar_tile.dart';
import 'package:to_do_app/components/outlook_calendar_tile.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/providers/calendar_sync_provider.dart';

class CalenderSyncPage extends StatefulWidget {
  final ToDoDataBase db;
  const CalenderSyncPage({super.key, required this.db});

  @override
  State<CalenderSyncPage> createState() => _CalenderSyncPageState();
}

class _CalenderSyncPageState extends State<CalenderSyncPage> {
  late ToDoDataBase db;
  @override
  void initState() {
    super.initState();
    db = widget.db;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CalendarSyncProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70.0),
          child: Text(
            "Calender Sync",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text("Select Calender Sync method", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              "This is where calender sync settings will be managed.By enabling you can sync your tasks with calendar events",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            SizedBox(height: 30),
            LocalCalendarTile(title: "Sync with local calendar app", db: db),
            SizedBox(height: 20),
            GoogleCalendarTile(title: "sync with google calendar", db: db),
            SizedBox(height: 20),
            OutlookCalendarTile(title: "sync with outtlook calendar", db: db),
          ],
        ),
      ),
    );
  }
}
