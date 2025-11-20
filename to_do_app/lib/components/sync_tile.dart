import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SyncTile extends StatelessWidget {
  final List<dynamic> task;
  const SyncTile({super.key, required this.task});

  void openCalendarEvent(int eventId) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data:
          Uri.parse(
            'content://com.android.calendar/events/$eventId',
          ).toString(),
    );

    await intent.launch();
  }

  Future<void> _openCalendarEvent() async {
    final String eventId = task[15]; // your event ID index
    if (eventId.isEmpty) {
      // fallback: just open the calendar app
      final Uri uri = Uri.parse('content://com.android.calendar/time/');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // Try to open the specific event by ID (Android)
    final Uri eventUri = Uri.parse(
      'content://com.android.calendar/events/$eventId',
    );
    if (await canLaunchUrl(eventUri)) {
      await launchUrl(eventUri);
    } else {
      // fallback: open calendar app
      final Uri fallbackUri = Uri.parse('content://com.android.calendar/time/');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final eventId = task[15]; // assuming your event id is stored here
        openCalendarEvent(int.tryParse(eventId) ?? 0);
      },
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                task[0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
