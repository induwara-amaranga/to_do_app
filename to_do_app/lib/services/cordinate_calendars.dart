import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/google_calendar_service.dart';
import 'package:to_do_app/services/local_calendar_service.dart';
import 'package:to_do_app/services/outlook_calendar_service.dart';

class CordinateCalendars {
  static Future<void> addUpdateTaskToCalendars(
    ToDoDataBase db,
    List<dynamic> task,
  ) async {
    String googleCalID = db.syncToCalendars["google"] ?? "none";
    String outlookCalID = db.syncToCalendars["outlook"] ?? "none";
    String localCalID = db.syncToCalendars["local"] ?? "none";

    if (db.syncToCalendars["google"] != "none") {
      await GoogleCalendarService.addOrUpdateEvent(googleCalID, task);
    }
    if (db.syncToCalendars["outlook"] != "none") {
      await OutlookCalendarService.addOrUpdateEvent(outlookCalID, task);
    }
    if (db.syncToCalendars["local"] != "none") {
      await LocalCalendarService.addEvent(localCalID, task);
    }
  }

  static Future<void> deleteTaskFromCalendars(
    ToDoDataBase db,
    List<dynamic> task,
  ) async {
    String googleCalID = db.syncToCalendars["google"] ?? "none";
    String outlookCalID = db.syncToCalendars["outlook"] ?? "none";
    String localCalID = db.syncToCalendars["local"] ?? "none";

    if (db.syncToCalendars["google"] != "none") {
      await GoogleCalendarService.deleteEvent(googleCalID, task[16][1]);
    }
    if (db.syncToCalendars["outlook"] != "none") {
      await OutlookCalendarService.deleteEvent(outlookCalID, task[16][2]);
    }
    if (db.syncToCalendars["local"] != "none") {
      await LocalCalendarService.deleteEvent(task[16][0], localCalID);
    }
  }
}
