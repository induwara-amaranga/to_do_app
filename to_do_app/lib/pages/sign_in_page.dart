import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:to_do_app/services/google_drive_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

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
    //     GoogleSignInAccount? user = await GoogleDriveService.initializeSignIn();
    //     if (user != null) {
    //       // Navigate to the next page or update the UI accordingly
    //       print("Signed in as ${user.displayName}");
    //     } else {
    //       print("Sign-in failed");
    //     }
    //   } catch (e) {
    //     print("Error during sign-in: $e");
    //   }
    // });
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
            ElevatedButton(onPressed: () {}, child: Text('Sync Manually')),
            SizedBox(height: 40),

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
