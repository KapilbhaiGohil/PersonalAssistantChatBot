import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    tz.initializeTimeZones(); // Initialize time zones

    // Check and request exact alarm permission (Android 12+)
    if (Platform.isAndroid) {
      await requestExactAlarmPermission();
    }
  }

  /// Handle notification selection
  Future<void> onSelectNotification(NotificationResponse response) async {
    if (response.payload != null) {
      print('🛎 Notification payload: ${response.payload}');
    }
  }

  /// Show an instant notification
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notifications',
      channelDescription: 'Channel for instant notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Instant Notification',
      'This is an instant notification!',
      platformDetails,
      payload: 'Instant Payload',
    );

    print('✅ Instant notification shown.');
  }

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzScheduledTime =
    tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'scheduled_channel_id',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'Scheduled Payload',
    );

    print('✅ Notification scheduled: "$title" at $scheduledTime');
  }


  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('🚫 Notification with ID $id canceled.');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('🚫 All notifications canceled.');
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
        print('⚠️ Requested exact alarm permission.');
      }
    } catch (e) {
      print('❌ Error requesting exact alarm permission: $e');
    }
  }

  /// Check if the Android version is 12 (API 31) or higher
  Future<bool> _isAndroid12OrHigher() async {
    try {
      final int sdkInt = await const MethodChannel('flutter/device_info')
          .invokeMethod<int>('getSdkInt') ?? 0;
      return sdkInt >= 31; // Android 12 (API 31) and above require exact alarms
    } catch (e) {
      print('❌ Error checking Android version: $e');
      return false;
    }
  }
}
