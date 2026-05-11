//import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/services/google_drive_service.dart';
import 'package:to_do_app/services/google_sign.dart';

class SignInPage extends StatefulWidget {
  final String? filePath;
  final ToDoDataBase db;
  final VoidCallback onSignIn;
  final VoidCallback onImported;
  const SignInPage({
    super.key,
    required this.onSignIn,
    required this.filePath,
    required this.db,
    required this.onImported,
  });

  @override
  State<SignInPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SignInPage> {
  var isAutoSyncOn = false;
  bool isSignedIn = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        bool isReady = await GoogleAuthService.ensureApisReady();
        print("Google APIs ready: $isReady");
      } catch (e) {
        print("Error restoring last session $e");
      }
    });
    print("file path in SignInPage: ${widget.filePath}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              print("Selected: $value");
              if (value == 'signOut') {
                await GoogleAuthService.signOut();
                setState(() {
                  isSignedIn = false;
                });
                widget.onSignIn();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'signOut',
                    child: Text('sign Out'),
                  ),
                  //const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
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
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 50,
              child: ClipOval(
                child: Image.network(
                  GoogleAuthService.currentUser?.photoUrl ?? '',
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person_rounded, size: 45);
                  },
                ),
              ),
            ),
            //SizedBox(height: 10),
            Text(
              GoogleAuthService.currentUser?.displayName ?? 'Not Signed In!',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: GestureDetector(
                onTap: () async {
                  try {
                    GoogleSignInAccount? user =
                        GoogleAuthService.currentUser ??
                        await GoogleAuthService.signInSilently() ??
                        await GoogleAuthService.signIn();
                    if (user != null) {
                      // Navigate to the next page or update the UI accordingly
                      print("Signed in as ${user.displayName}");
                      // widget.db.accountDetails["userName"] =
                      //     user.displayName ?? "none";
                      // widget.db.accountDetails["profilePicture"] =
                      //     user.photoUrl ?? "none";
                      // widget.db.updateDataBase();

                      setState(() {
                        isSignedIn = true;
                      });
                      //
                      widget.onSignIn();
                    } else {
                      print("Sign-in failed");
                    }
                  } catch (e) {
                    print("Error during sign-in: $e");
                  }
                },
                child: Image.asset(
                  scale: 1.5,
                  'assets/images/google/android_light_rd_SI@2x.png',
                  key: const ValueKey('google_image'),

                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //     String boxName = "mybox";

            //     // 1. Close the box if it's open
            //     if (Hive.isBoxOpen(boxName)) {
            //       await Hive.box(boxName).close();
            //     }

            //     final hiveFile = File(widget.filePath!);

            //     // 2. Create/Get folder on Drive
            //     final folderId = await GoogleDriveService.createFolder();
            //     if (folderId == null) {
            //       print("Error creating/accessing folder on Google Drive");
            //       return;
            //     }

            //     // 3. Get file ID in that folder
            //     String? fileId = await GoogleDriveService.getFileId(folderId);

            //     // 4. Download file if exists (await is important!)
            //     if (fileId != null) {
            //       await GoogleDriveService.downloadFile(
            //         fileId,
            //         widget.filePath!,
            //       );
            //       print("Downloaded file from Drive");
            //     }

            //     // 5. Upload local file to Drive (overwrite if necessary)
            //     final uploadedId = await GoogleDriveService.uploadFileToFolder(
            //       hiveFile,
            //       folderId,
            //     );
            //     print("Uploaded/Updated file ID = $uploadedId");

            //     // 6. Reopen Hive box after file is downloaded/overwritten
            //     final _myBox = await Hive.openBox(boxName);

            //     print("Hive box opened: ${_myBox.path}");
            //     // 7. Load or initialize data
            //     if (_myBox.get("TODOLIST") == null &&
            //         _myBox.get("CATEGORIES") == null) {
            //       widget.db.createInitialData();
            //     } else {
            //       widget.db.loadData();
            //     }
            //   },

            //   child: Text('Sync Manually'),
            // ),
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

              child: Text('Backup'),
            ),

            SizedBox(height: 10),
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

              child: Text('Restore'),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Image.asset(
                  scale: 2.5,
                  'assets/images/google/logo_drive_2020q4_color_2x_web_64dp.png',
                  key: const ValueKey('drive_image'),

                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Back Up With Google Drive',
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
