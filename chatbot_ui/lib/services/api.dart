import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> sendMessageToApi(String message, chatHistory, stage, email) async {
    String? accessToken = await _secureStorage.read(key: 'accessToken');

    if (accessToken == null) {
      return {'text': "Access token not available"};
    }

    final response = await _sendRequest(message, chatHistory, stage, email, accessToken);

    if (response['status'] == 401) {
      print("Access token expired. Refreshing token...");
      String? newAccessToken = await refreshGoogleAccessToken();

      if (newAccessToken != null) {
        // Save the new access token to secure storage
        await _secureStorage.write(key: 'accessToken', value: newAccessToken);

        // Retry the request with the new access token
        final retryResponse = await _sendRequest(message, chatHistory, stage, email, newAccessToken);
        return retryResponse;
      } else {
        // If refresh fails, prompt the user to log in again
        print("Failed to refresh access token. Please log in again.");
        await _handleReauthentication();
        return {'text': "Access token expired. Please log in again."};
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> _sendRequest(String message, chatHistory, stage, email, String accessToken) async {
    const String apiUrl = "http://10.0.2.2:8000/chat";
    final headers = {
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({
      "query": message,
      "chat_history": chatHistory,
      "stage": stage,
      "email": email,
      "accessToken": accessToken
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        return data;
      } else {
        print('Failed to get response from API: ${response.statusCode}');
        return {'status': response.statusCode, 'text': "Error during API request"};
      }
    } catch (e) {
      print('Error during API request: $e');
      return {'status': 500, 'text': "Error during API request"};
    }
  }

  Future<String?> refreshGoogleAccessToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? idToken = await user.getIdToken(true);
        print("Refreshed Firebase ID Token: $idToken");

        GoogleSignInAccount? googleUser = await GoogleSignIn().signInSilently();
        if (googleUser != null) {
          GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          String? newAccessToken = googleAuth.accessToken;
          return newAccessToken;
        }
      } else {
        print("No user signed in");
        return null;
      }
    } catch (e) {
      print("Error refreshing Google Access Token: $e");
      return null;
    }
  }

  Future<void> _handleReauthentication() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      await _secureStorage.delete(key: 'accessToken');

      print("User needs to log in again");
    } catch (e) {
      print("Error during reauthentication: $e");
    }
  }
}
