import 'dart:convert';
import 'package:chatbot_ui/services/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final notificationService = NotificationService();
  Future<String?> getFreshAccessToken() async {
    try {
      final String? accessToken = await _secureStorage.read(key: 'access_token');
      final String? expirationTimeStr = await _secureStorage.read(key: 'expiration_time');

      if (accessToken == null || expirationTimeStr == null) {
        return null;
      }

      final DateTime expirationTime = DateTime.parse(expirationTimeStr);
      if (DateTime.now().isBefore(expirationTime)) {
        return accessToken;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String newAccessToken = googleAuth.accessToken!;

        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        await _secureStorage.write(key: 'expiration_time', value: DateTime.now().add(const Duration(seconds: 3600)).toIso8601String());

        return newAccessToken;
      }

      return null;
    } catch (e) {
      print('Error getting fresh access token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> sendMessageToApi(
      String message, chatHistory, stage, email) async {
    final String? accessToken = await getFreshAccessToken();

    if (accessToken == null) {
      await _signOut();
      return {'text': "Failed to retrieve access token. User signed out."};
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    var body = jsonEncode({
      "query": message,
      "chat_history": chatHistory,
      "stage": stage,
      "email": email,
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/chat'), headers: headers, body: body);
      if (response.statusCode == 200) {

        final data = json.decode(response.body);
        print(data);
        if (data['nInfo'] != null) {
          final nInfo = data['nInfo'];

          if (nInfo['delete'] != null && nInfo['delete'] is List) {
            for (var id in nInfo['delete']) {
              if (id != null && id is String) {
                await NotificationService().cancelNotification(id);
              }
            }
          } else {
            String? taskId = nInfo['task_id'] as String?;
            String title = nInfo['title'] as String? ?? "Scheduled Task";
            String body = nInfo['body'] as String? ?? "You have a scheduled event.Ask for more details.";
            String? startDate = nInfo['startdate'] as String?;
            String? startTime = nInfo['starttime'] as String?;
            // Check for null values before proceeding
            if (taskId != null && startDate != null && startTime != null) {
              DateTime scheduledTime = DateTime.parse('$startDate $startTime:00');
              if(data['payload']['daily']!= null && data['payload']['daily']==true){
                TimeOfDay scheduledTimeOfDay = TimeOfDay(
                  hour: scheduledTime.hour,
                  minute: scheduledTime.minute,
                );
                await notificationService.scheduleDailyNotification(eventId: taskId, title: title, body: body, timeOfDay: scheduledTimeOfDay);
              }else{
                await notificationService.scheduleNotification(
                  eventId: taskId,
                  title: title,
                  body: body,
                  scheduledTime: scheduledTime,
                );
              }
            }
          }
        }
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<Map<String, dynamic>> generateMessage(String msg) async {
    var body = jsonEncode({
      "task": msg
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/message'),
          headers: {"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('User signed out successfully.');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
