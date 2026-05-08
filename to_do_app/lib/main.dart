import 'package:flutter/material.dart';
//import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/calendar_page.dart';
//import 'package:timezone/data/latest.dart' as tz;
//import 'package:timezone/timezone.dart' as tz;

import 'package:to_do_app/pages/filtered_tasks_page.dart';
import 'package:to_do_app/pages/calender_sync_page.dart';
import 'package:to_do_app/pages/manage_categories_page.dart';
import 'package:to_do_app/pages/saved_timetables_page.dart';
import 'package:to_do_app/pages/statistics_page.dart';
import 'package:to_do_app/pages/task_page.dart';
import 'package:to_do_app/providers/calendar_sync_provider.dart';
import 'package:to_do_app/providers/file_search_provider.dart';
import 'package:to_do_app/providers/file_sort_provider.dart';
import 'package:to_do_app/providers/view_provider.dart';
import 'package:to_do_app/services/google_drive_service.dart'
    show GoogleDriveService;
import 'package:to_do_app/services/google_sign.dart';
import 'package:to_do_app/services/outlook_sign.dart';
import 'package:to_do_app/themes/theme_provider.dart';
import 'package:to_do_app/providers/auth_provider.dart';
import 'package:to_do_app/providers/grouping_provider.dart';
import 'package:to_do_app/providers/sorting_provider.dart';
import 'package:to_do_app/providers/searching_provider.dart';
import 'services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/config/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ToDoDataBase db = ToDoDataBase();
String? path;

tz.Location? findLocalLocation() {
  final now = DateTime.now();
  final offset = now.timeZoneOffset;

  for (final name in tz.timeZoneDatabase.locations.keys) {
    final location = tz.getLocation(name);
    final locNow = tz.TZDateTime.now(location);

    if (locNow.timeZoneOffset == offset) {
      return location;
    }
  }
  print("Could not find local timezone location");
  return tz.getLocation('UTC'); // fallback
}

Future<void> initLocalTimeZone() async {
  // 1. Initialize the timezone database
  //tz.initializeTimeZones();

  if (db.settings["timeZone"] == "") {
    //final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    // 2. Get device timezone (e.g., "Asia/Colombo")
    //print("Device timezone: $timeZoneName");
    // 3. Get tz Location
    final localLocation = findLocalLocation()!;
    tz.setLocalLocation(localLocation);
    //print("Local timezone set: ${tz.local.name}");
    print("Local timezone set in tz package: ${tz.local.name}");
  } else {
    // final String timeZoneName = db.settings["timeZone"];
    // // 2. Get device timezone (e.g., "Asia/Colombo")
    // print("Device timezone: $timeZoneName");
    // // 3. Get tz Location
    // final tz.Location location = tz.getLocation(timeZoneName);

    // // 4. Set as local
    // tz.setLocalLocation(location);
    // print("Local timezone set in tz package (from db): ${tz.local.name}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // F-06: key read from --dart-define=SUPABASE_ANON_KEY or AppConfig default
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  await Hive.initFlutter();
  var box = await Hive.openBox("mybox");
  Box fileMetaBox = await Hive.openBox("fileMetaBox");
  path = box.path!;
  //await box.clear();
  final _myBox = Hive.box("mybox");
  if (_myBox.get("TODOLIST") == null && _myBox.get("CATEGORIES") == null) {
    db.createInitialData();
  } else {
    db.loadData();
  }
  // WidgetsFlutterBinding.ensureInitialized();
  await GoogleAuthService.initApp();
  await OutlookAuthService.initialize();

  // F-07: initialise AuthProvider with resolved sign-in state
  final authProvider = AuthProvider(
    isGoogleSignedIn: GoogleAuthService.currentUser != null,
    isOutlookSignedIn: OutlookAuthService.accessToken != null,
    displayName: GoogleAuthService.currentUser?.displayName ?? '',
  );

  // TEST NOTIFICATION
  try {
    await NotificationService.init();
  } catch (e) {
    print("----------Notification error: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GroupingProvider()),
        ChangeNotifierProvider(create: (_) => SortingProvider()),
        ChangeNotifierProvider(create: (_) => SearchingProvider()),
        ChangeNotifierProvider(create: (_) => CalendarSyncProvider()),
        ChangeNotifierProvider(create: (_) => FileSearchProvider()),
        ChangeNotifierProvider(create: (_) => FileSortProvider()),
        ChangeNotifierProvider(create: (_) => ViewProvider()),
        // F-07: central auth state provider
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
  await initLocalTimeZone();
  try {
    // await NotificationService.init();
  } catch (e) {
    print("failed to detect time zome $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: Provider.of<ThemeProvider>(context).themeData,
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                TaskPage(updateMissedTasks: true, db: db, filePath: path),
        '/savedTimetables': (context) => const SavedTimetablesPage(),
        '/manageCategories': (context) => const ManageCategoriesPage(),
        '/calendarSync': (context) => CalenderSyncPage(db: db),
        '/statistics': (context) => StatisticsPage(db: db),
        '/calendar': (context) => CalendarPage(db: db),
        '/filteredTasks':
            (context) => Filteredtaskspage(
              deleteFunction: null,
              onChanged: null,
              onTaskChanged: null,
              filterData: {},
              toDoList: [],
              categoryTypes: [],
            ),
      },
    );
  }
}
