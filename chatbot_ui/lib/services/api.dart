import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Method to send a message to your API
  Future<Map<String, dynamic>> sendMessageToApi(
      String message, chatHistory, stage, email) async {
    final String? accessToken = await getFreshAccessToken();

    if (accessToken == null) {
      await _signOut();
      return {'text': "Failed to retrieve access token. User signed out."};
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken', // Pass the fresh access token
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
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      return {'text': "Error during API request"};
    }
  }

  // Method to sign out the user
  Future<void> _signOut() async {
    try {
      await _auth.signOut(); // Sign out from Firebase
      await _googleSignIn.signOut(); // Sign out from Google Sign-In
      print('User signed out successfully.');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
