import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/google_calendar_sync_page.dart';
import 'package:to_do_app/pages/local_calendar_sync_page.dart';
import 'package:to_do_app/services/google_calendar_service.dart';
import 'package:to_do_app/services/local_calendar_service.dart';

class GoogleCalendarTile extends StatefulWidget {
  final ToDoDataBase db;
  final String title;

  const GoogleCalendarTile({super.key, required this.title, required this.db});

  @override
  State<GoogleCalendarTile> createState() => _CalendarTileState();
}

class _CalendarTileState extends State<GoogleCalendarTile> {
  bool isSyncTrue = false;

  late ToDoDataBase db;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    db = widget.db;
  }

  @override
  Widget build(BuildContext context) {
    isSyncTrue =
        db.syncToCalendars["google"] != "none" ||
        db.viewOnlyCalendars["google"]!.isNotEmpty;
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
                      "Sync with google calendars",
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
                            Map<String, dynamic>? calendarInit =
                                await GoogleCalendarService.initializeSignIn();
                            gcal.CalendarApi? calendarAPI =
                                calendarInit!["api"];
                            print("fetching calendar list......");
                            gcal.CalendarList calendars = gcal.CalendarList();
                            if (calendarAPI != null) {
                              calendars = await calendarAPI.calendarList.list();
                              print(
                                '📅 Found ${calendars.items?.length ?? 0} calendars',
                              );

                              for (final cal in calendars.items ?? []) {
                                print('• ${cal.summary}  (ID: ${cal.id})');
                              }
                            }

                            if (calendars.items!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GoogleCalendarSyncPage(
                                        calendars: calendars.items ?? [],
                                        db: db,
                                        accountName: calendarInit["userName"],
                                        calendarAPI: calendarAPI!,
                                      ),
                                ),
                              );
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
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (_) => GoogleCalendarSyncPage(
                              //           calendars: calendars,
                              //           db: db,
                              //         ),
                              //   ),
                              // );
                            } else {
                              print("No calendars found");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("No calendars found"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            print("Error fetching events: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error fetching events: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
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
                      Map<String, dynamic>? calendarInit =
                          await GoogleCalendarService.initializeSignIn();
                      gcal.CalendarApi? calendarAPI = calendarInit!["api"];
                      gcal.CalendarList calendars = gcal.CalendarList();
                      if (calendarAPI != null) {
                        calendars = await calendarAPI.calendarList.list();
                        print(
                          '📅 Found ${calendars.items?.length ?? 0} calendars',
                        );

                        for (final cal in calendars.items ?? []) {
                          print('• ${cal.summary}  (ID: ${cal.id})');
                        }
                      }

                      if (calendars.items!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GoogleCalendarSyncPage(
                                  calendarAPI: calendarAPI!,
                                  calendars: calendars.items ?? [],
                                  db: db,
                                  accountName: calendarInit["userName"],
                                ),
                          ),
                        );
                      } else {
                        print("No calendars found");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("No calendars found"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      print("Error fetching events: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error fetching events: $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } else {
                    db.syncToCalendars["google"] = "none";
                    db.viewOnlyCalendars["google"] = {};
                    db.updateDataBase();
                    setState(() {
                      isSyncTrue = false;
                    });
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
