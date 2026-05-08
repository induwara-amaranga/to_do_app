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
        title: Text(
          'Calendar Sync',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Heading
            Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Select sync method",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Connect your tasks to a calendar so they appear as events. You can enable multiple providers.",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            LocalCalendarTile(db: db),
            const SizedBox(height: 16),
            GoogleCalendarTile(db: db),
            const SizedBox(height: 16),
            OutlookCalendarTile(db: db),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
