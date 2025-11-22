import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/google_drive_service.dart';

class SignInPage extends StatefulWidget {
  final String? filePath;
  final ToDoDataBase db;
  final VoidCallback onImported;
  const SignInPage({
    super.key,
    required this.filePath,
    required this.db,
    required this.onImported,
  });

  @override
  State<SignInPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SignInPage> {
  var isAutoSyncOn = false;
  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   try {
    //     final dir = await getApplicationDocumentsDirectory();
    //     //print(dir.path);
    //     print("Hive boxes path: ${widget.filePath}/hive_boxes");
    //   } catch (e) {
    //     print("Error finding file path $e");
    //   }
    // });
    print("file path in SignInPage: ${widget.filePath}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        title: Text(
          'Sign In with Google',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: GestureDetector(
                onTap: () async {
                  try {
                    GoogleSignInAccount? user =
                        await GoogleDriveService.initializeSignIn();
                    if (user != null) {
                      // Navigate to the next page or update the UI accordingly
                      print("Signed in as ${user.displayName}");
                    } else {
                      print("Sign-in failed");
                    }
                  } catch (e) {
                    print("Error during sign-in: $e");
                  }
                },
                child: Image.asset(
                  scale: 1.5,
                  'assets/images/android_light_rd_SI@2x.png',
                  key: const ValueKey('google_image'),

                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String boxName = "mybox";

                // 1. Close the box if it's open
                if (Hive.isBoxOpen(boxName)) {
                  await Hive.box(boxName).close();
                }

                final hiveFile = File(widget.filePath!);

                // 2. Create/Get folder on Drive
                final folderId = await GoogleDriveService.createFolder();
                if (folderId == null) {
                  print("Error creating/accessing folder on Google Drive");
                  return;
                }

                // 3. Get file ID in that folder
                String? fileId = await GoogleDriveService.getFileId(folderId);

                // 4. Download file if exists (await is important!)
                if (fileId != null) {
                  await GoogleDriveService.downloadFile(
                    fileId,
                    widget.filePath!,
                  );
                  print("Downloaded file from Drive");
                }

                // 5. Upload local file to Drive (overwrite if necessary)
                final uploadedId = await GoogleDriveService.uploadFileToFolder(
                  hiveFile,
                  folderId,
                );
                print("Uploaded/Updated file ID = $uploadedId");

                // 6. Reopen Hive box after file is downloaded/overwritten
                final _myBox = await Hive.openBox(boxName);

                print("Hive box opened: ${_myBox.path}");
                // 7. Load or initialize data
                if (_myBox.get("TODOLIST") == null &&
                    _myBox.get("CATEGORIES") == null) {
                  widget.db.createInitialData();
                } else {
                  widget.db.loadData();
                }
              },

              child: Text('Sync Manually'),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                //String boxName = "mybox";

                // // 1. Close the box if it's open
                // if (Hive.isBoxOpen(boxName)) {
                //   await Hive.box(boxName).close();
                // }

                final hiveFile = File(widget.filePath!);

                // 2. Create/Get folder on Drive
                final folderId = await GoogleDriveService.createFolder();
                if (folderId == null) {
                  print("Error creating/accessing folder on Google Drive");
                  return;
                }

                // // 3. Get file ID in that folder
                // String? fileId = await GoogleDriveService.getFileId(folderId);

                // // 4. Download file if exists (await is important!)
                // if (fileId != null) {
                //   await GoogleDriveService.downloadFile(
                //     fileId,
                //     widget.filePath!,
                //   );
                //   print("Downloaded file from Drive");
                // }

                // 5. Upload local file to Drive (overwrite if necessary)
                final uploadedId = await GoogleDriveService.uploadFileToFolder(
                  hiveFile,
                  folderId,
                );
                print("Uploaded/Updated file ID = $uploadedId");

                // // 6. Reopen Hive box after file is downloaded/overwritten
                // final _myBox = await Hive.openBox(boxName);

                // print("Hive box opened: ${_myBox.path}");
                // // 7. Load or initialize data
                // if (_myBox.get("TODOLIST") == null &&
                //     _myBox.get("CATEGORIES") == null) {
                //   widget.db.createInitialData();
                // } else {
                //   widget.db.loadData();
                // }
              },

              child: Text('Upload'),
            ),

            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                String boxName = "mybox";

                // 1. Close the box if it's open
                if (Hive.isBoxOpen(boxName)) {
                  await Hive.box(boxName).close();
                }

                //final hiveFile = File(widget.filePath!);

                // 2. Create/Get folder on Drive
                final folderId = await GoogleDriveService.createFolder();
                if (folderId == null) {
                  print("Error creating/accessing folder on Google Drive");
                  return;
                }

                // 3. Get file ID in that folder
                String? fileId = await GoogleDriveService.getFileId(folderId);

                // 4. Download file if exists (await is important!)
                if (fileId != null) {
                  await GoogleDriveService.downloadFile(
                    fileId,
                    widget.filePath!,
                  );
                  print("Downloaded file from Drive");
                }

                // // 5. Upload local file to Drive (overwrite if necessary)
                // final uploadedId = await GoogleDriveService.uploadToFolder(
                //   hiveFile,
                //   folderId,
                // );
                //print("Uploaded/Updated file ID = $uploadedId");

                // 6. Reopen Hive box after file is downloaded/overwritten
                final _myBox = await Hive.openBox(boxName);

                print("Hive box opened: ${_myBox.path}");
                // 7. Load or initialize data

                widget.onImported();
              },

              child: Text('Download'),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Image.asset(
                  scale: 2.5,
                  'assets/images/logo_drive_2020q4_color_2x_web_64dp.png',
                  key: const ValueKey('drive_image'),

                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Sync With Google Drive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Backup and Sync Your Tasks Seamlessly across Devices',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAutoSyncOn,
                  activeColor: Colors.white, // thumb color when ON
                  activeTrackColor:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // background track when ON
                  inactiveThumbColor: Colors.grey[400], // thumb when OFF
                  inactiveTrackColor: Colors.grey[300],
                  onChanged: (value) {
                    setState(() => isAutoSyncOn = value);
                  },
                ),
              ],
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Last synced: Never',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
