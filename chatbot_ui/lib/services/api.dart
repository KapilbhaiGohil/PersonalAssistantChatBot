import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  // static const apiUrl = "http://127.0.0.1:54747";

  Future<Map<String,dynamic>> sendMessageToApi(String message,chatHistory,stage,email) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if(user!=null){
      String? idToken = await user?.getIdToken();
      const String apiUrl = "http://10.0.2.2:8000/chat";
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken'
      };
      var body = jsonEncode({
        "query": message,
        "chat_history": chatHistory,
        "stage": stage,
        "email":email,

      });
      try {
        print(body);
        final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print(data);
          final String apiResponse = data['text'];
          return data;
        } else {
          print('Failed to get response from API: ${response.statusCode}');
          return {'text' : "Error during API request"};
        }
      } catch (e) {
        print('Error during API request: $e');
        return {'text':"Error during API request"};
      }
    }else{
      print("Failed to add task.");
      return {};
    }
  }
}