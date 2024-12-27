import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  // static const apiUrl = "http://127.0.0.1:54747";

  Future<Map<String,dynamic>> sendMessageToApi(String message,chatHistory,stage,email) async {
    final accessToken = await _secureStorage.read(key: 'accessToken');
      const String apiUrl = "http://10.0.2.2:8000/chat";
      final headers = {
        'Content-Type': 'application/json',
      };
      var body = jsonEncode({
        "query": message,
        "chat_history": chatHistory,
        "stage": stage,
        "email":email,
        "accessToken":accessToken
      });
      try {
        print(body);
        final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print(data);
          return data;
        } else {
          print('Failed to get response from API: ${response.statusCode}');
          return {'text' : "Error during API request"};
        }
      } catch (e) {
        print('Error during API request: $e');
        return {'text':"Error during API request"};
      }
  }
}