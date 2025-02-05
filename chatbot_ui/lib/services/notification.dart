import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  /// Initialize notifications
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      await requestExactAlarmPermission();
    }
  }

  /// Handle notification selection
  Future<void> onSelectNotification(NotificationResponse response) async {
    if (response.payload != null) {
      // Decode the payload to extract data
      final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
      String eventId = payloadData['eventId'];
      String title = payloadData['title'];
      String body = payloadData['body'];

      if (response.actionId == 'action_ok') {
        // Handle the "OK" button click: Cancel the notification
        print("OK button clicked.");
        await cancelNotification(eventId); // Cancel the notification
      } else if (response.actionId == 'action_remind_later' || response.input == null) {
        // Handle the "Remind me later" button click: Reschedule the notification after 10 minutes
        print("Remind me later clicked or notification swiped away.");
        await rescheduleNotification(eventId, title, body, 10);
      }
    }
  }

  /// Reschedule the notification after the specified delay (in minutes)
  Future<void> rescheduleNotification(
      String eventId, String title, String body, int delayMinutes) async {
    // Calculate the new scheduled time by adding the delay
    DateTime newScheduledTime = DateTime.now().add(Duration(minutes: delayMinutes));

    // Reschedule the notification
    await scheduleNotification(
      eventId: eventId,
      title: title,
      body: body,
      scheduledTime: newScheduledTime,
    );

    print("Notification rescheduled for $delayMinutes minutes later at $newScheduledTime");
  }

  /// Generate a stable 32-bit integer ID from a string using SHA-256
  int generateNotificationId(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    int id = digest.bytes.sublist(0, 4).fold(0, (a, b) => (a << 8) | b);

    // Ensure the id fits within a 32-bit integer range.
    return id & 0x7FFFFFFF; // This ensures it is within the range of a 32-bit unsigned integer.
  }

  /// Show an instant notification with two action buttons: OK and Remind me later
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_channel_id',
      'Instant Notifications',
      channelDescription: 'Channel for instant notifications',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'action_ok',
          'OK',
          showsUserInterface: true
        ),
        AndroidNotificationAction(
          'action_remind_later',
          'Remind me 10 min later',
          showsUserInterface: true
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Instant Notification',
      'This is an instant notification with options!',
      platformDetails,
      payload: 'Instant Payload',
    );
  }

  /// Schedule a notification at a specific time with two action buttons
  Future<void> scheduleNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final int id = generateNotificationId(eventId);
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Create a map to hold the necessary details for rescheduling
    final Map<String, dynamic> notificationData = {
      'eventId': eventId,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(), // Store the scheduled time in ISO format
    };

    // Convert the map to a JSON string
    final String payload = jsonEncode(notificationData);

    // Define action buttons for Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_channel_id',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'action_ok',
          'OK',
            showsUserInterface: true
        ),
        AndroidNotificationAction(
          'action_remind_later',
          'Remind me later',
            showsUserInterface: true
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload, // Use the JSON string as the payload
    );

    print("Notification scheduled at $scheduledTime");
  }

  /// Schedule a repeating daily notification with two action buttons
  Future<void> scheduleDailyNotification({
    required String eventId,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final int id = generateNotificationId(eventId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hours ?? 0,
      timeOfDay.minutes ?? 0,
    );

    // If the scheduled time is already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Create a map to hold the necessary details for rescheduling
    final Map<String, dynamic> notificationData = {
      'eventId': eventId,
      'title': title,
      'body': body,
      'scheduledTime': scheduledDate.toIso8601String(), // Store the scheduled time in ISO format
    };

    // Convert the map to a JSON string
    final String payload = jsonEncode(notificationData);

    // Define action buttons for Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_channel_id',
      'Daily Notifications',
      channelDescription: 'Channel for daily notifications',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'action_ok',
          'OK',
            showsUserInterface: true
        ),
        AndroidNotificationAction(
          'action_remind_later',
          'Remind me later',
            showsUserInterface: true
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload, // Use the JSON string as the payload
    );

    print("Daily notification scheduled at $scheduledDate");
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String eventId) async {
    int id = generateNotificationId(eventId);
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Request Exact Alarm Permission (Android 12+)
  Future<void> requestExactAlarmPermission() async {
    try {
      if (Platform.isAndroid && (await _isAndroid12OrHigher())) {
        const AndroidIntent intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      print('❌ Error requesting exact alarm permission: $e');
    }
  }

  /// Check if the Android version is 12 (API 31) or higher
  Future<bool> _isAndroid12OrHigher() async {
    try {
      final int sdkInt = await const MethodChannel('flutter/device_info')
          .invokeMethod<int>('getSdkInt') ??
          0;
      return sdkInt >= 31;
    } catch (e) {
      return false;
    }
  }
}
