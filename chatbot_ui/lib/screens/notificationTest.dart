import 'package:flutter/material.dart';
import '../services/notification.dart'; // Import your NotificationService class

class TestNotificationScreen extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();

  TestNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _notificationService.showInstantNotification();
              },
              child: const Text('Show Test Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _notificationService.scheduleNotification(
                  eventId: "djkf",
                  title: 'Scheduled Test',
                  body: 'This will appear in 5 seconds!',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
                );
              },
              child: const Text('Schedule Notification (5s)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {

              },
              child: const Text('Cancel Scheduled Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
