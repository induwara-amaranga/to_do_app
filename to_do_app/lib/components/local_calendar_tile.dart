import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/local_calendar_sync_page.dart';
import 'package:to_do_app/services/local_calendar_service.dart';

class LocalCalendarTile extends StatefulWidget {
  final ToDoDataBase db;
  final String title;

  const LocalCalendarTile({super.key, required this.title, required this.db});

  @override
  State<LocalCalendarTile> createState() => _CalendarTileState();
}

class _CalendarTileState extends State<LocalCalendarTile> {
  bool isSyncTrue = false;

  late ToDoDataBase db;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    db = widget.db;
  }

  Future<void> _showOpenSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Calendar Access Blocked'),
            content: const Text(
              'Calendar access was denied. Please enable it in Settings to sync your tasks.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  Future<List<Calendar>?> _requestCalendarWithRationale() async {
    if (await LocalCalendarService.hasCalendarPermission()) {
      return _getCalendarsOrNull();
    }

    final status = await Permission.calendarFullAccess.status;
    if (!mounted) return null;

    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog();
      return null;
    }

    // Dialog 1: permission can still be requested
    final bool accepted =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Calendar Access Required'),
                content: const Text(
                  'To sync your tasks with your device calendar, the app needs calendar access.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not Now'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Grant Access'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!accepted) return null;

    final granted = await LocalCalendarService.requestCalendarPermission();
    if (!granted) {
      // OS silently blocked (denied once on some devices) — explain and open Settings
      await _showOpenSettingsDialog();
      return null;
    }

    return _getCalendarsOrNull();
  }

  Future<List<Calendar>?> _getCalendarsOrNull() async {
    final calendars = await LocalCalendarService.getCalendars();
    if (calendars.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No calendars found on this device.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }
    return calendars;
  }

  @override
  Widget build(BuildContext context) {
    isSyncTrue =
        db.syncToCalendars["local"] != "none" ||
        db.viewOnlyCalendars["local"]!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),

        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Text(
            widget.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Row(
                  children: [
                    Text(
                      "Sync with local calendar",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    Spacer(),
                    if (isSyncTrue)
                      IconButton(
                        onPressed: () async {
                          // Update toggle states first

                          try {
                            // Fetch calendars
                            final calendars =
                                await _requestCalendarWithRationale();
                            if (calendars == null) return;
                            if (calendars.isNotEmpty) {
                              // final events = await CalendarService.getEvents(
                              //   calendars[5].id!,
                              // );
                              // List<String?> calNames =
                              //     calendars.map((c) => c.name).toList();
                              // print(
                              //   "Fetched ${events.length} events from here ${calNames}",
                              // );

                              // WidgetsBinding.instance.addPostFrameCallback((_) async {
                              //   await CalendarService.importCalendarEventsToDB(
                              //     events,
                              //     db,
                              //   );
                              //   setState(
                              //     () {},
                              //   ); // optional: rebuild if tasks visible in UI
                              // });
                              //CalendarService.importCalendarEventsToDB(events, db);
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text(
                              //       "Fetched ${events.length} events from ${calendars[5].name}",
                              //     ),
                              //     backgroundColor: const Color.fromARGB(
                              //       255,
                              //       82,
                              //       255,
                              //       105,
                              //     ),
                              //   ),
                              // );
                              //isSyncTrue = true;
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => LocalCalendarSyncPage(
                                          calendars: calendars,
                                          db: db,
                                        ),
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "No calendars found on this device.",
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error fetching events: $e"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.refresh),
                      )
                    else
                      SizedBox.shrink(),
                  ],
                ),
                value: isSyncTrue,
                onChanged: (value) async {
                  // Update toggle states first
                  setState(() {
                    isSyncTrue = value;
                  });

                  if (value) {
                    try {
                      // Fetch calendars
                      final calendars = await _requestCalendarWithRationale();
                      if (calendars == null) {
                        setState(() {
                          isSyncTrue = false;
                        });
                        return;
                      }
                      final toDoCal =
                          await LocalCalendarService.createNewCalendar(
                            calendars,
                          );
                      if (calendars.isNotEmpty) {
                        // widget.db.viewOnlyCalendars["local"]!.addAll(
                        //   calendars.map((c) => c.id!),
                        // );
                        widget.db.syncToCalendars["local"] = toDoCal.id!;
                        // final events = await CalendarService.getEvents(
                        //   calendars[5].id!,
                        // );
                        // List<String?> calNames =
                        //     calendars.map((c) => c.name).toList();
                        // print(
                        //   "Fetched ${events.length} events from here ${calNames}",
                        // );

                        // WidgetsBinding.instance.addPostFrameCallback((_) async {
                        //   await CalendarService.importCalendarEventsToDB(
                        //     events,
                        //     db,
                        //   );
                        //   setState(
                        //     () {},
                        //   ); // optional: rebuild if tasks visible in UI
                        // });
                        //CalendarService.importCalendarEventsToDB(events, db);
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text(
                        //       "Fetched ${events.length} events from ${calendars[5].name}",
                        //     ),
                        //     backgroundColor: const Color.fromARGB(
                        //       255,
                        //       82,
                        //       255,
                        //       105,
                        //     ),
                        //   ),
                        // );

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => LocalCalendarSyncPage(
                                    calendars: calendars,
                                    db: db,
                                  ),
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          isSyncTrue = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No calendars found on this device.",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error fetching events: $e"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  } else {
                    widget.db.viewOnlyCalendars["local"] = {};
                    widget.db.syncToCalendars["local"] = "none";
                  }
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
