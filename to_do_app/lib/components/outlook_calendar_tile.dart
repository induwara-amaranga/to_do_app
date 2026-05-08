import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/pages/Outlook_calendar_sync_page.dart';
import 'package:to_do_app/providers/auth_provider.dart';
import 'package:to_do_app/services/Outlook_calendar_service.dart';
import 'package:to_do_app/services/outlook_sign.dart';

class OutlookCalendarTile extends StatefulWidget {
  final ToDoDataBase db;

  const OutlookCalendarTile({super.key, required this.db});

  @override
  State<OutlookCalendarTile> createState() => _OutlookCalendarTileState();
}

class _OutlookCalendarTileState extends State<OutlookCalendarTile> {
  bool _isLoading = false;

  static const _brandColor = Color(0xFF0078D4);

  Future<void> _fetchAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();

      // Ensure signed in — silent restore first, interactive if needed
      if (!authProvider.isOutlookSignedIn ||
          OutlookAuthService.accessToken == null) {
        // initialize() calls init() + acquireTokenSilently() internally
        final silentSuccess = await OutlookAuthService.initialize();

        if (!silentSuccess) {
          // _pca is already initialised by initialize(); go straight to interactive
          final token = await OutlookAuthService.signIn();

          if (!mounted) return;
          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Outlook sign-in was cancelled."),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }

        authProvider.setOutlookSignedIn(true);
      }

      List<Map<String, dynamic>> calendars = [];
      if (OutlookAuthService.accessToken != null) {
        calendars = await OutlookCalendarService.getAllCalendars();
      }

      if (!mounted) return;

      if (calendars.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OutlookCalendarSyncPage(
                  calendars: calendars,
                  db: widget.db,
                  accountName: "Outlook Account",
                ),
          ),
        );
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No Outlook calendars found on this account."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't connect to Outlook Calendar. Check your internet and try again.",
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
    widget.db.syncToCalendars["outlook"] = "none";
    widget.db.viewOnlyCalendars["outlook"] = {};
    widget.db.updateDataBase();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSyncActive =
        widget.db.syncToCalendars["outlook"] != "none" ||
        widget.db.viewOnlyCalendars["outlook"]!.isNotEmpty;
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
                    "assets/images/outlook/icons8-microsoft-outlook-2025-48-2.png",
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
                        "Outlook Calendar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isSyncActive ? "Connected" : "Not connected",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isSyncActive
                                  ? _brandColor
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
              "Sync tasks with your Microsoft Outlook calendar.",
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
