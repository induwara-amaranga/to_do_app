import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/local_calendar_service.dart';
import 'package:to_do_app/providers/calendar_sync_provider.dart';
import 'package:uuid/uuid.dart';

class LocalCalendarSyncPage extends StatefulWidget {
  final List<Calendar> calendars;
  final ToDoDataBase db;

  const LocalCalendarSyncPage({
    super.key,
    required this.calendars,
    required this.db,
  });

  @override
  State<LocalCalendarSyncPage> createState() => _LocalCalendarSyncPageState();
}

class _LocalCalendarSyncPageState extends State<LocalCalendarSyncPage> {
  bool? syncToCalendar = false;
  late Map<String, bool> importCalendars = {};
  late Map<String, bool> syncCalendars = {};
  List<Calendar> calendars = [];
  bool isImportLoading = false;
  bool isImportRefreshing = false;

  bool isViewOnlyLoading = false;
  bool isSyncing = false;
  //CalendarSyncProvider provider = CalendarSyncProvider();

  @override
  void initState() {
    super.initState();
    // Initialize all calendars as unchecked
    calendars = widget.calendars;
    importCalendars = {for (var cal in calendars) cal.id!: false};
    syncCalendars = {for (var cal in calendars) cal.id!: false};
    if (widget.db.syncToCalendars["local"] != "none") {
      syncToCalendar = true;
    }
    final uuid = Uuid();
  }

  void _toggleImportCalendar(String calendarId, bool? value) {
    setState(() {
      importCalendars[calendarId] = value ?? true;
    });
  }

  void _toggleSyncCalendar(String calendarId, bool? value) {
    setState(() {
      syncCalendars[calendarId] = value ?? true;
    });
  }

  Future<List<Calendar>> _getSelectedCalendars(
    Map<dynamic, dynamic> selectedCalMap,
  ) async {
    final selected =
        calendars
            .where(
              (cal) => selectedCalMap[cal.id] == true,
              //cal.id != widget.db.syncToCalendars["local"].hashCode,
            )
            .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No calendars selected")));

      return [];
    }

    // TODO: implement LocalCalendarService to import tasks from selected calendars
    // await LocalCalendarService.importEvents(selected);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${selected.length} calendar(s) selected for sync"),
      ),
    );
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Text("Sync Local Calendars")]),
        actions: [],
      ),
      body: Column(
        children: [
          const Divider(),
          Row(
            children: [
              SizedBox(
                width: 270,
                child: Text(
                  "Import events from following Calendars to local Todolist",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  calendars = await LocalCalendarService.getCalendars();
                  //calendars = widget.calendars;
                  importCalendars = {for (var cal in calendars) cal.id!: false};
                  syncCalendars = {for (var cal in calendars) cal.id!: false};
                  setState(() {});
                  // TODO: reload calendars if needed
                },
              ),
              isImportLoading
                  ? Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                  : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      setState(() {
                        isImportLoading = true;
                      });
                      final selectedImportCalendars =
                          await _getSelectedCalendars(importCalendars);
                      //print("import");
                      final Calendar toDoCalendar;
                      toDoCalendar =
                          await LocalCalendarService.createNewCalendar(
                            calendars,
                          );
                      //widget.db.viewOnlyCalendars["local"] = [];

                      for (var cal in selectedImportCalendars) {
                        //widget.db.viewOnlyCalendars["local"].add(cal.id);
                        print("to do calendar ${toDoCalendar.name}");
                        print("${cal.name}");
                        await LocalCalendarService.importCalendarEventsToDB(
                          await LocalCalendarService.getEvents(cal.id),
                          widget.db,
                        );
                      }
                      //print("sync value $syncToCalendar");
                      context.read<CalendarSyncProvider>().notify();
                      setState(() {
                        isImportLoading = false;
                      });
                      // Pop back to previous screen after import finishes
                      // if (context.mounted) {
                      //   Navigator.pop(context);
                      // }
                    },
                  ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: calendars.length,
              itemBuilder: (context, index) {
                final calendar = calendars[index];
                if (calendar.id == widget.db.syncToCalendars["local"]) {
                  return SizedBox.shrink();
                }
                return CheckboxListTile(
                  title: Text(calendar.name ?? 'Unnamed Calendar'),
                  subtitle: Text(
                    calendar.accountName ?? 'Unknown account',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  value: importCalendars[calendar.id],
                  onChanged:
                      (value) => _toggleImportCalendar(calendar.id!, value),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            children: [
              SizedBox(
                width: 270,
                child: Text(
                  "View events from following Calendar in Todolist(view only)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  calendars = await LocalCalendarService.getCalendars();
                  //calendars = widget.calendars;
                  importCalendars = {for (var cal in calendars) cal.id!: false};
                  syncCalendars = {for (var cal in calendars) cal.id!: false};
                  setState(() {});
                  // TODO: reload calendars if needed
                },
              ),
              isViewOnlyLoading
                  ? Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                  : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      setState(() {
                        isViewOnlyLoading = true;
                      });
                      final selectedSyncCalendars = await _getSelectedCalendars(
                        syncCalendars,
                      );
                      //print("import");
                      // final Calendar toDoCalendar;
                      // toDoCalendar = await LocalCalendarService.createNewCalendar(
                      //   widget.calendars,
                      // );
                      //widget.db.viewOnlyCalendars["local"] = selectedImportCalendars;
                      //widget.db.localCalTasks = [];

                      for (var cal in selectedSyncCalendars) {
                        // Mark calendar as synced
                        widget.db.viewOnlyCalendars["local"]!.add(cal.id!);

                        print("Syncing from calendar: ${cal.name}");

                        // Fetch events from this calendar
                        final events = await LocalCalendarService.getEvents(
                          cal.id,
                        );

                        await LocalCalendarService.importViewOnlyEventsToDB(
                          events,
                          widget.db,
                        );
                      }
                      //print("sync value $syncToCalendar");
                      context.read<CalendarSyncProvider>().notify();
                      setState(() {
                        isViewOnlyLoading = false;
                      });
                      // Pop back to previous screen after import finishes
                      // if (context.mounted) {
                      //   Navigator.pop(context);
                      // }
                    },
                  ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: calendars.length,
              itemBuilder: (context, index) {
                final calendar = calendars[index];
                return CheckboxListTile(
                  title: Text(calendar.name ?? 'Unnamed Calendar'),
                  subtitle: Text(
                    calendar.accountName ?? 'Unknown account',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  value: syncCalendars[calendar.id],
                  onChanged:
                      (value) => _toggleSyncCalendar(calendar.id!, value),
                );
              },
            ),
          ),
          Divider(),
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Sync tasks between local Todo list and Calendar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),

              SizedBox(width: 10),
              isSyncing
                  ? Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                  : SizedBox.shrink(),
            ],
          ),
          CheckboxListTile(
            title: Text("Select check box to enable syncing to calendar"),
            subtitle: Text(
              "A new calendar \"ToDoList\" will be used for syncting.Only upcoming tasks will be synced.Past tasks will not be synced",
              style: TextStyle(color: Colors.grey.shade500),
            ),
            value: syncToCalendar,
            onChanged: (value) async {
              setState(() {
                syncToCalendar = value;
              });
              final Calendar toDoCalendar;
              print("sync value $syncToCalendar");
              if (value != null && value) {
                setState(() {
                  isSyncing = true;
                });
                toDoCalendar = await LocalCalendarService.createNewCalendar(
                  calendars,
                );
                print("to do calendar ${toDoCalendar.name}");
                widget.db.syncToCalendars["local"] = toDoCalendar.id!;
                try {
                  await LocalCalendarService.syncTasksToCalendar(
                    widget.db,
                    toDoCalendar.id.toString(),
                  );
                  await LocalCalendarService.syncTasksFromCalendar(widget.db);
                  //print("tasks added");
                } catch (d, st) {
                  print("failed to sync calendars $d ,$st");
                }
              } else {
                widget.db.syncToCalendars["local"] = "none";
              }
              widget.db.updateDataBase();
              context.read<CalendarSyncProvider>().notify();
              setState(() {
                isSyncing = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
