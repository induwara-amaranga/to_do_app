import "package:flutter/material.dart";
import "package:to_do_app/data/database.dart";
import "package:to_do_app/pages/import_ics_page.dart";
import "package:to_do_app/pages/settings_page.dart";
import "package:to_do_app/pages/sign_in_page.dart";
import "package:to_do_app/services/google_sign.dart";

class MyDrawer extends StatefulWidget {
  final VoidCallback onImported;
  final String? filePath;
  final ToDoDataBase db;
  MyDrawer({
    super.key,
    required this.filePath,
    required this.onImported,
    required this.db,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          //padding: EdgeInsets.zero,
          children: [
            SizedBox(
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),

                child: GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SignInPage(
                                onSignIn: () {
                                  setState(() {});
                                },
                                db: widget.db,
                                filePath: widget.filePath,
                                onImported: widget.onImported,
                              ),
                        ),
                      ),
                  child: Center(
                    child: Column(
                      children: [
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
                        Text(
                          GoogleAuthService.currentUser?.displayName ??
                              'Sign In',

                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top items scrollable
            ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(Icons.palette),
                  title: Text("Themes"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("Settings"),
                  onTap: () async {
                    Navigator.pop(context); // close drawer first

                    // Push Import Page and wait for result
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(db: widget.db),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text("Date & Time Settings"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text("Notifications"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.notifications_active),
                  title: Text("Reminders"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.download),
                  title: Text("Import"),
                  onTap: () async {
                    Navigator.pop(context); // close drawer first

                    // Push Import Page and wait for result
                    final imported = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ImportICSPage()),
                    );
                    //comes to this line after pop

                    // **DON'T call setState here**
                    print("---imported: $imported");
                    // Instead, return the result to TaskPage
                    if (imported == true) {
                      // This can be ignored; TaskPage will handle it
                      widget.onImported();
                    }
                  },
                ),
              ],
            ),

            Spacer(),

            Divider(color: Color.fromARGB(255, 213, 211, 211)),
            //Bottom items fixed
            ListTile(
              leading: Icon(Icons.star_rounded),
              title: Text("Rate the app"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text("Share with friends"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.mail),
              title: Text("Contact the support team"),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
