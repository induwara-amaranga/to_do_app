import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/google_calendar_sync_page.dart';
import 'package:to_do_app/providers/auth_provider.dart';
import 'package:to_do_app/services/google_sign.dart';

class GoogleCalendarTile extends StatefulWidget {
  final ToDoDataBase db;

  const GoogleCalendarTile({super.key, required this.db});

  @override
  State<GoogleCalendarTile> createState() => _GoogleCalendarTileState();
}

class _GoogleCalendarTileState extends State<GoogleCalendarTile> {
  bool _isLoading = false;

  static const _brandColor = Color(0xFF4285F4);
  static const _connectedColor = Color(0xFF34A853);

  Future<void> _fetchAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();

      // Ensure signed in — silent restore first, interactive if needed
      if (!authProvider.isGoogleSignedIn ||
          GoogleAuthService.currentUser == null) {
        var user = await GoogleAuthService.signInSilently();
        user ??= await GoogleAuthService.signIn();

        if (!mounted) return;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Google sign-in was cancelled."),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        authProvider.setGoogleSignedIn(
          true,
          displayName: user.displayName ?? user.email,
        );
      }

      // Refresh the API client with a current token
      await GoogleAuthService.ensureApisReady();
      final calendarAPI = GoogleAuthService.calendarApi;

      gcal.CalendarList calendars = gcal.CalendarList();
      if (calendarAPI != null) {
        calendars = await calendarAPI.calendarList.list();
      }

      if (!mounted) return;

      if (calendars.items?.isNotEmpty == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => GoogleCalendarSyncPage(
                  calendars: calendars.items ?? [],
                  db: widget.db,
                  accountName:
                      GoogleAuthService.currentUser?.email ?? "Unknown",
                  calendarAPI: calendarAPI!,
                ),
          ),
        );
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No Google calendars found on this account."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't connect to Google Calendar. Check your internet and try again.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disableSync() async {
    widget.db.syncToCalendars["google"] = "none";
    widget.db.viewOnlyCalendars["google"] = {};
    widget.db.updateDataBase();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSyncActive =
        widget.db.syncToCalendars["google"] != "none" ||
        widget.db.viewOnlyCalendars["google"]!.isNotEmpty;
    final connectedEmail = GoogleAuthService.currentUser?.email;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSyncActive ? _brandColor.withValues(alpha: 0.5) : outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _brandColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    "assets/images/google/icons8-google-calendar-48-2.png",
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Google Calendar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isSyncActive && connectedEmail != null
                            ? "Connected as $connectedEmail"
                            : "Not connected",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSyncActive
                                  ? _connectedColor
                                  : onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: outline),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "Push tasks to Google Calendar as events. Changes sync automatically.",
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Switch
          SwitchListTile(
            title: const Text("Enable sync"),
            value: isSyncActive,
            onChanged:
                _isLoading
                    ? null
                    : (value) async {
                      if (value) {
                        await _fetchAndNavigate();
                      } else {
                        await _disableSync();
                      }
                    },
            activeColor: Theme.of(context).colorScheme.primary,
            secondary:
                _isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : null,
          ),
          // Manage footer (only when active)
          if (isSyncActive) ...[
            Divider(height: 1, color: outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading ? null : _fetchAndNavigate,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text("Manage"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
