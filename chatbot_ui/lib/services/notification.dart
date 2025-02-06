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

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initNotifications() async {
    print("Initializing notifications...");
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    tz.initializeTimeZones();
    if (Platform.isAndroid) await _requestExactAlarmPermission();
  }

  Future<void> _onSelectNotification(NotificationResponse response) async {
    print("Notification clicked: ${response.actionId}");

    if (response.payload == null) {
      print("No payload received.");
      return;
    }

    final data = jsonDecode(response.payload!);
    final eventId = data['eventId'];

    print("Processing notification for eventId: $eventId");

    switch (response.actionId) {
      case 'action_ok':
        print("User clicked OK, cancelling notification.");
        await cancelNotification(eventId);
        break;
      case 'action_remind_later':
        print("User clicked Remind Me Later, rescheduling.");
        await _rescheduleNotification(data, 10);
        break;
      default:
        print("Unknown action: ${response.actionId}");
    }
  }


  Future<void> _rescheduleNotification(Map<String, dynamic> data, int minutes) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: 3));
    print("Rescheduling notification for eventId: ${data['eventId']} at $scheduledTime");
    await scheduleNotification(
      eventId: data['eventId'],
      title: data['title'],
      body: data['body'],
      scheduledTime: scheduledTime,
    );
  }

  int _generateNotificationId(String input) {
    final id = sha256
        .convert(utf8.encode(input))
        .bytes
        .sublist(0, 4)
        .fold(0, (a, b) => (a << 8) | b) & 0x7FFFFFFF;
    print("Generated notification ID: $id for input: $input");
    return id;
  }

  Future<void> _showNotification({required String title, required String body, required String payload}) async {
    print("Showing notification: $title");
    await _notificationsPlugin.show(
      0,
      title,
      body,
      NotificationDetails(android: _androidDetails()),
      payload: payload,
    );
  }

  AndroidNotificationDetails _androidDetails() {
    return const AndroidNotificationDetails(
      'scheduled_channel_id',
      'Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          'action_ok',
          'OK',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_remind_later',
          'Remind me later',
          showsUserInterface: true,
        ),
      ],
    );
  }

  Future<void> showInstantNotification() async {
    print("Showing instant notification");
    await _showNotification(
      title: 'Instant Notification',
      body: 'This is an instant notification with options!',
      payload: jsonEncode({'eventId': 'instant', 'title': 'Instant Notification', 'body': 'This is an instant notification with options!'}),
    );
  }

  Future<void> scheduleNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final id = _generateNotificationId(eventId);
    print("Scheduling notification for eventId: $eventId at $scheduledTime");
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: _androidDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'eventId': eventId,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
      }),
    );
  }

  Future<void> cancelNotification(String eventId) async {
    final id = _generateNotificationId(eventId);
    print("Cancelling notification with ID: $id");
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    print("Cancelling all notifications");
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid && await _isAndroid12OrHigher()) {
      print("Requesting exact alarm permission");
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  Future<void> scheduleDailyNotification({
    required String eventId,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hours ?? 0,
      timeOfDay.minutes ?? 0,
    );
    // If the scheduled time is before now, schedule for tomorrow.
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    print("Scheduling daily notification for eventId: $eventId at $scheduledTime");
    await _notificationsPlugin.zonedSchedule(
      _generateNotificationId(eventId),
      title,
      body,
      scheduledTime,
      NotificationDetails(android: _androidDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
      payload: jsonEncode({
        'eventId': eventId,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
      }),
    );
  }

  Future<bool> _isAndroid12OrHigher() async {
    try {
      final int sdkInt = await const MethodChannel('flutter/device_info').invokeMethod<int>('getSdkInt') ?? 0;
      print("Android SDK version: $sdkInt");
      return sdkInt >= 31;
    } catch (e) {
      print("Error checking Android version: $e");
      return false;
    }
  }
}
