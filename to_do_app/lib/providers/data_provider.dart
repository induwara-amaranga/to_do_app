import 'package:flutter/foundation.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/models/calendar_event.dart';
import 'package:to_do_app/models/task.dart';

/// Wraps [ToDoDataBase] in a [ChangeNotifier] so widgets can react to
/// data changes via Provider instead of receiving `db` as a constructor arg.
///
/// Exposes data in two shapes:
/// - Legacy positional `List<List<dynamic>>` (matches the in-memory format
///   used by existing index-based code throughout the app).
/// - Typed `List<Task>` views for new code, computed on demand.
class DataProvider extends ChangeNotifier {
  final ToDoDataBase db;
  DataProvider(this.db);

  // ── Legacy shape (zero-copy) ──────────────────────────────────────────
  List<List<dynamic>> get toDoList        => db.toDoList;
  List<List<dynamic>> get localCalTasks   => db.localCalTasks;
  List<List<dynamic>> get googleCalTasks  => db.googleCalTasks;
  List<List<dynamic>> get outlookCalTasks => db.outlookCalTasks;
  List<String>        get categories      => db.categories;

  // ── Typed views (allocate; use sparingly) ─────────────────────────────
  List<Task>          get tasks         => db.toDoList.map(Task.fromList).toList();
  List<CalendarEvent> get localEvents   => db.localCalTasks.map(CalendarEvent.fromList).toList();
  List<CalendarEvent> get googleEvents  => db.googleCalTasks.map(CalendarEvent.fromList).toList();
  List<CalendarEvent> get outlookEvents => db.outlookCalTasks.map(CalendarEvent.fromList).toList();

  // ── Mutations ─────────────────────────────────────────────────────────
  Future<void> persistAll() async {
    await db.updateDataBase();
    notifyListeners();
  }

  Future<void> persistToDoList() async {
    await db.saveToDoList();
    notifyListeners();
  }

  Future<void> persistCategories() async {
    db.saveCategories();
    notifyListeners();
  }
}
