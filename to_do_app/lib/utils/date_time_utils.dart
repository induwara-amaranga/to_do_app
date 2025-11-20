// utils/date_utils.dart
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateTimeUtilsHelper {
  // Parse String → DateTime
  static DateTime? parseDate(String? dateStr, {String format = "yyyy-MM-dd"}) {
    try {
      DateTime taskDate;
      if (dateStr != null && dateStr != "0000-00-00") {
        try {
          taskDate = DateFormat(format).parse(dateStr);
        } catch (e) {
          taskDate = DateTime(1970, 01, 01);
        }
      } else {
        taskDate = DateTime(1970, 01, 01);
      }
      return taskDate;
    } catch (e) {
      return null; // return null if parsing fails
    }
  }

  // Format DateTime → String
  static String formatDate(DateTime? date, {String format = "yyyy-MM-dd"}) {
    String formatedDate =
        date != null
            ? DateFormat(format).format(date)
            : DateFormat(format).format(DateTime.now());

    return formatedDate;
  }

  static DateTime? parseTime(String timeStr, {String format = "HH:mm"}) {
    try {
      DateTime? taskTime =
          timeStr != "24:00"
              ? DateFormat(format).parse(timeStr)
              : DateTime(1970, 1, 1, 23, 59, 59);
      return taskTime;
    } catch (e) {
      return null; // return null if parsing fails
    }
  }

  static String formatTime(DateTime? time, {String format = "HH:mm"}) {
    if (time == null) return "24:00";
    return DateFormat(format).format(time);
  }

  static DateTime parseDateTime(String timestamp) {
    DateTime dt = DateTime.parse(timestamp);
    return dt;
  }

  static String formatDateTime(DateTime? dt) {
    String timestamp = dt!.toLocal().toString();
    return timestamp;
  }

  static DateTime combineDateAndTime(DateTime? date, DateTime? time) {
    if (date == null) date = DateTime.now();
    if (time == null) time = DateTime(1970, 1, 1, 23, 59);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime combineDateAndTimeFromStrings(
    String dateStr,
    String timeStr,
  ) {
    DateTime date = parseDate(dateStr) ?? DateTime.now();
    DateTime time = parseTime(timeStr) ?? DateTime(1970, 1, 1, 23, 59);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Converts a local DateTime (assumed in tz.local) to UTC
  static DateTime toUtcUsingLocal(DateTime dateTime) {
    // Wrap the DateTime in tz.TZDateTime using tz.local
    //from tz of dateTime to utc
    final localTzDateTime = tz.TZDateTime.from(dateTime, tz.local);

    // Convert to UTC
    return localTzDateTime.toUtc();
  }

  /// Converts a UTC DateTime (or any DateTime) to tz.local time
  static DateTime toLocalUsingTz(DateTime dateTime) {
    final utcTime = DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    // Wrap the DateTime in tz.TZDateTime using tz.local
    final localTzDateTime = tz.TZDateTime.from(utcTime, tz.local);

    // Return a normal Dart DateTime in local tz
    return localTzDateTime;
  }
}
