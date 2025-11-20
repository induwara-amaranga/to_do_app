import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const webClientId =
      '879200055223-f40a49a8tvse1ca2sngrudqh8r5f3ccg.apps.googleusercontent.com';
  static const androidClientId =
      '879200055223-ber902b42l2nh4bbg43kuvs3tq41dd9i.apps.googleusercontent.com';
  // final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   scopes: [
  //     drive.DriveApi.driveFileScope, // access only files your app creates
  //     // drive.DriveApi.driveScope,   // use this only if you need full Drive access
  //   ],
  // );

  static drive.DriveApi? _driveApi;
  GoogleSignInAccount? _account;

  /// --------------------------
  ///  SIGN IN & INIT DRIVE API
  /// --------------------------
  static Future<GoogleSignInAccount?> initializeSignIn() async {
    print("initializing google sign in...");
    // 1️⃣ Initialize the singleton instance with your OAuth client IDs
    await GoogleSignIn.instance.initialize(
      clientId: androidClientId,
      serverClientId: webClientId,
    );

    // 2️⃣ Start the authentication flow
    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate(scopeHint: ['https://www.googleapis.com/auth/calendar']);

    // 3️⃣ Get OAuth headers to use with Google APIs
    final headers = await account.authorizationClient.authorizationHeaders([
      drive.DriveApi.driveFileScope, // access only files your app creates
      // drive.DriveApi.driveScope,   // use this only if you need full Drive access
    ], promptIfNecessary: true);

    print('✅ Signed in as: ${account.email}');
    print('🔑 Access token: ${headers?['Authorization']}');

    if (headers == null) {
      print('User not signed in');
      return null;
    }
    final client = _GoogleAuthClient(headers);

    _driveApi = drive.DriveApi(client);

    //final _driveApi = await getCalendarApi(headers);
    print('✅ Google Calendar API initialized');
    //_calendarApi = calendarApi;
    return account;
  }

  /// --------------------------
  ///  LIST FILES IN DRIVE
  /// --------------------------
  static Future<List<drive.File>> listFiles() async {
    //final apiMap = await initializeSignIn();
    //final api=apiMap?["api"] as drive.DriveApi?;
    if (_driveApi == null) return [];

    final result = await _driveApi!.files.list(
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, size)',
    );

    return result.files ?? [];
  }

  /// --------------------------
  ///  UPLOAD FILE
  /// --------------------------
  static Future<String?> uploadFile(File file) async {
    //final api = await initializeSignIn();
    if (_driveApi == null) return null;

    final fileMeta = drive.File()..name = file.path.split('/').last;

    final uploaded = await _driveApi!.files.create(
      fileMeta,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );

    return uploaded.id;
  }

  /// --------------------------
  ///  DOWNLOAD FILE
  /// --------------------------
  static Future<File?> downloadFile(String fileId, String savePath) async {
    //final api = await initializeSignIn();
    if (_driveApi == null) return null;

    final media =
        await _driveApi!.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final file = File(savePath);
    final sink = file.openWrite();

    await media.stream.pipe(sink);
    await sink.close();

    return file;
  }

  /// --------------------------
  ///  CREATE FOLDER
  /// --------------------------
  static Future<String?> createFolder() async {
    String folderName = "ToDoListData";
    if (_driveApi == null) return null;

    // 1️⃣ Check if folder already exists
    final existingFolders = await _driveApi!.files.list(
      q: "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      $fields: "files(id, name)",
    );

    if (existingFolders.files != null && existingFolders.files!.isNotEmpty) {
      // Folder found → return existing ID
      return existingFolders.files!.first.id;
    }

    // 2️⃣ Create folder if not found
    final folder =
        drive.File()
          ..name = folderName
          ..mimeType = "application/vnd.google-apps.folder";

    final result = await _driveApi!.files.create(folder);
    return result.id;
  }

  /// --------------------------
  ///  UPLOAD FILE INTO FOLDER
  /// --------------------------
  static Future<String?> uploadToFolder(File file, String folderId) async {
    //final api = await initializeSignIn();
    if (_driveApi == null) return null;

    final fileMeta =
        drive.File()
          ..name = file.path.split('/').last
          ..parents = [folderId];

    final uploaded = await _driveApi!.files.create(
      fileMeta,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );

    return uploaded.id;
  }

  /// --------------------------
  ///  DELETE FILE
  /// --------------------------
  static Future<bool> deleteFile(String fileId) async {
    //final api = await initializeSignIn();
    if (_driveApi == null) return false;

    await _driveApi!.files.delete(fileId);
    return true;
  }

  /// --------------------------
  ///  SIGN OUT
  /// --------------------------
  static Future<void> signOut() async {
    _driveApi = null;
    await GoogleSignIn.instance.signOut();
  }
}

/// Custom client for authenticated Google requests
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request..headers.addAll(headers));
}
