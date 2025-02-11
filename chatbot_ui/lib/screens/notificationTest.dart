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
                await _notificationService.scheduleChatNotification(
                  title: 'Hi',
                  body: 'how are you ?',
                  eventId: 'demo id',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 0))
                );
              },
              child: const Text('Schedule Chat Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // You can call cancelNotification here with an example eventId
                await _notificationService.cancelAllTypeNotification("chat_001");
              },
              child: const Text('Cancel Chat Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
