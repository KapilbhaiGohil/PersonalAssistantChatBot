import 'dart:convert';
import 'dart:io';
import 'package:chatbot_ui/services/api.dart';
import 'package:crypto/crypto.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'notificationController.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initNotifications() async {
    print("Initializing Awesome Notifications...");
    // Initialize Awesome Notifications with a default icon and channel
    AwesomeNotifications().initialize(
      // set the default icon for notifications (use null for default app icon)
      null,
      [
        NotificationChannel(
          channelKey: 'scheduled_channel_id',
          channelName: 'Notifications',
          channelDescription: 'General notifications',
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
        )
      ],
      debug: true,
    );

    // Listen for notification actions (taps and button clicks)
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );
    // AwesomeNotifications().actionStream.listen(_onActionReceived);

    tz.initializeTimeZones();

    if (Platform.isAndroid) await _requestExactAlarmPermission();
  }

  Future<void> onActionReceived(ReceivedAction receivedAction) async {
    // For buttons, check the button key pressed.
    print("Notification action received: ${receivedAction.buttonKeyPressed}");

    // The payload is stored as a map (if provided in the content payload)
    if (receivedAction.payload == null ||
        !receivedAction.payload!.containsKey('data')) {
      print("No payload received.");
      return;
    }

    final data = jsonDecode(receivedAction.payload!['data']!);
    final eventId = data['eventId'];

    print("Processing notification for eventId: $eventId");

    switch (receivedAction.buttonKeyPressed) {
      case 'action_ok':
        print("User clicked OK, cancelling notification.");
        await cancelNotification(eventId);
        break;
      case 'action_remind_later':
        print("User clicked Remind Me Later, rescheduling.");
        var newData = data;
        var fetchData = await ChatAPI().generateMessage(data['body']);
        newData['body'] = fetchData['body'];
        newData['title'] = fetchData['title'];
        await _rescheduleNotification(newData, 10);
        break;
      default:
        print("Notification tapped without a registered button.");
    }
  }

  Future<void> _rescheduleNotification(Map<String, dynamic> data, int minutes) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: minutes));
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

  Future<void> showInstantNotification() async {
    print("Showing instant notification");
    final payload = jsonEncode({
      'eventId': 'instant',
      'title': 'Instant Notification',
      'body': 'This is an instant notification with options!'
    });

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'scheduled_channel_id',
        title: 'Instant Notification',
        body: 'This is an instant notification with options!',
        payload: {'data': payload},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'action_ok',
          label: 'OK',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'action_remind_later',
          label: 'Remind me later',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
      ],
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
    final payload = jsonEncode({
      'eventId': eventId,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
    });
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'scheduled_channel_id',
        title: title,
        body: body,
        payload: {'data': payload},
      ),
      schedule: NotificationCalendar(preciseAlarm: true,hour: scheduledTime.hour,minute: scheduledTime.minute,day: scheduledTime.day),
      actionButtons: [
        NotificationActionButton(
          key: 'action_ok',
          label: 'OK',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'action_remind_later',
          label: 'Remind me later',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  Future<void> cancelNotification(String eventId) async {
    final id = _generateNotificationId(eventId);
    print("Cancelling notification with ID: $id");
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    print("Cancelling all notifications");
    await AwesomeNotifications().cancelAll();
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

  Future<bool> _isAndroid12OrHigher() async {
    try {
      final int sdkInt = await const MethodChannel('flutter/device_info')
          .invokeMethod<int>('getSdkInt') ??
          0;
      print("Android SDK version: $sdkInt");
      return sdkInt >= 31;
    } catch (e) {
      print("Error checking Android version: $e");
      return false;
    }
  }

  Future<void> scheduleDailyNotification({
    required String eventId,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    // If the scheduled time is before now, schedule for tomorrow.
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    print("Scheduling daily notification for eventId: $eventId at $scheduledTime");
    final id = _generateNotificationId(eventId);
    final payload = jsonEncode({
      'eventId': eventId,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
    });
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'scheduled_channel_id',
        title: title,
        body: body,
        payload: {'data': payload},
      ),
      schedule: NotificationCalendar(
        hour: timeOfDay.hour,
        minute: timeOfDay.minute,
        second: 0,
        repeats: true,
        preciseAlarm: true
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'action_ok',
          label: 'OK',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
        NotificationActionButton(
          key: 'action_remind_later',
          label: 'Remind me later',
          autoDismissible: true,
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }
}
