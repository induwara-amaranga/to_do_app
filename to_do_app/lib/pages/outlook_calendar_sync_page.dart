import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
//import 'package:Outlookapis/calendar/v3.dart';
//import 'package:Outlookapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/Outlook_calendar_service.dart';
import 'package:to_do_app/services/local_calendar_service.dart';
import 'package:to_do_app/providers/calendar_sync_provider.dart';
import 'package:to_do_app/services/outlook_sign.dart';
import 'package:uuid/uuid.dart';

class OutlookCalendarSyncPage extends StatefulWidget {
  final List<Map<String, dynamic>> calendars;
  final ToDoDataBase db;
  final String accountName;
  //final gcal.CalendarApi calApi;

  const OutlookCalendarSyncPage({
    super.key,
    //required this.calApi,
    required this.accountName,
    required this.calendars,
    required this.db,
  });

  @override
  State<OutlookCalendarSyncPage> createState() => _LocalCalendarSyncPageState();
}

class _LocalCalendarSyncPageState extends State<OutlookCalendarSyncPage> {
  bool? syncToCalendar = false;
  late Map<String, bool> importCalendars = {};
  late Map<String, bool> syncCalendars = {};
  List<Map<String, dynamic>> calendars = [];
  bool isImportLoading = false;
  bool isImportRefreshing = false;

  bool isViewOnlyLoading = false;
  bool isSyncing = false;
  //CalendarSyncProvider provider = CalendarSyncProvider();

  @override
  void initState() {
    super.initState();
    calendars = widget.calendars;
    // Initialize all calendars as unchecked
    importCalendars = {for (var cal in calendars) cal["id"]: false};
    syncCalendars = {for (var cal in calendars) cal["id"]: false};
    if (widget.db.syncToCalendars["outlook"] != "none") {
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

  List<Map<String, dynamic>> _getSelectedCalendars(
    Map<dynamic, dynamic> selectedCalMap,
  ) {
    final selected =
        calendars
            .where(
              (cal) => selectedCalMap[cal["id"]] == true,
              //cal.id != widget.db.syncToCalendars["Outlook"].hashCode,
            )
            .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No calendars selected")));

      return [];
    }

    // TODO: implement OutlookCalendarService to import tasks from selected calendars
    // await OutlookCalendarService.importEvents(selected);

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
        title: const Text("Sync Outlook Calendars"),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () async {
              await OutlookAuthService.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(),
          Row(
            children: [
              SizedBox(
                width: 270,
                child: Text(
                  "Import events from following Calendars to Outlook Todolist",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  calendars = await OutlookCalendarService.getAllCalendars();
                  //calendars = widget.calendars;
                  importCalendars = {
                    for (var cal in calendars) cal["id"]!: false,
                  };
                  syncCalendars = {
                    for (var cal in calendars) cal["id"]!: false,
                  };
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
                      final Map<String, dynamic>? toDoCalendar;
                      toDoCalendar =
                          await OutlookCalendarService.createOrGetCalendar(
                            calendars,
                          );
                      //widget.db.viewOnlyCalendars["Outlook"] = [];
                      if (toDoCalendar == null) return;

                      for (var cal in selectedImportCalendars) {
                        //widget.db.viewOnlyCalendars["Outlook"].add(cal.id);
                        print("to do calendar ${toDoCalendar["name"]}");
                        print("${cal["name"]}");
                        await OutlookCalendarService.importEventsToDB(
                          cal["id"],
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
                if (calendar["id"] == widget.db.syncToCalendars["Outlook"]) {
                  return SizedBox.shrink();
                }
                return CheckboxListTile(
                  title: Text(calendar["name"] ?? 'Unnamed Calendar'),
                  subtitle: Text(
                    widget.accountName ?? 'Unknown account',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  value: importCalendars[calendar["id"]],
                  onChanged:
                      (value) => _toggleImportCalendar(calendar["id"]!, value),
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
                  calendars = await OutlookCalendarService.getAllCalendars();
                  //calendars = widget.calendars;
                  importCalendars = {
                    for (var cal in calendars) cal["id"]!: false,
                  };
                  syncCalendars = {
                    for (var cal in calendars) cal["id"]!: false,
                  };
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
                      try {
                        final selectedSyncCalendars = _getSelectedCalendars(
                          syncCalendars,
                        );
                        //print("import");
                        // final gcal.Calendar? toDoCalendar;
                        // toDoCalendar =
                        //     await OutlookCalendarService.createOrGetCalendar(
                        //       calendars,
                        //     );
                        // if (toDoCalendar == null) return;
                        //widget.db.viewOnlyCalendars["Outlook"] = selectedImportCalendars;
                        //widget.db.calTasks = [];

                        for (var cal in selectedSyncCalendars) {
                          // Mark calendar as synced
                          widget.db.viewOnlyCalendars["outlook"]!.add(
                            cal["id"]!,
                          );

                          print("Syncing from calendar: ${cal["name"]}");

                          // Fetch events from this calendar
                          final events =
                              await OutlookCalendarService.getCalendarEvents(
                                cal["id"]!,
                              );

                          await OutlookCalendarService.importViewOnlyEventsToDB(
                            cal["id"],
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
                      } catch (e) {
                        print("view only error $e");
                      }
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
                  title: Text(calendar["name"] ?? 'Unnamed Calendar'),
                  subtitle: Text(
                    widget.accountName ?? 'Unknown account',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  value: syncCalendars[calendar["id"]],
                  onChanged:
                      (value) => _toggleSyncCalendar(calendar["id"]!, value),
                );
              },
            ),
          ),
          Divider(),
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Sync tasks between Outlook Todo list and Calendar",
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
              final Map<String, dynamic>? toDoCalendar;
              print("sync value $syncToCalendar");
              if (value != null && value) {
                setState(() {
                  isSyncing = true;
                });
                toDoCalendar = await OutlookCalendarService.createOrGetCalendar(
                  calendars,
                );
                print("to do calendar ${toDoCalendar!["name"]}");
                widget.db.syncToCalendars["outlook"] = toDoCalendar["id"];
                try {
                  await OutlookCalendarService.syncTasksToCalendar(
                    widget.db,
                    toDoCalendar["id"],
                  );
                  await OutlookCalendarService.syncTasksFromCalendar(widget.db);
                  //print("tasks added");
                } catch (d) {
                  print("failded to sync calendars");
                }
              } else {
                widget.db.syncToCalendars["outlook"] = "none";
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
