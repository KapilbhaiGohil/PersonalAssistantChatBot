import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  // static const apiUrl = "http://127.0.0.1:54747";
  Future<Map<String,dynamic>> login(String email,String password)async{
    var body = jsonEncode(
      {
        'email':email,
        'password':password
      }
    );
    http.Response res = await http.post(Uri.parse("$apiUrl/login"),headers: {"Content-Type": "application/json"},body:body);
    var data = json.decode(res.body);
    return data;
  }

  Future<Map<String,dynamic>> register(String email,String password,String name)async{
    var body = jsonEncode(
        {
          'email':email,
          'password':password,
          'name':name
        }
    );
    http.Response res = await http.post(Uri.parse("$apiUrl/register"),headers: {"Content-Type": "application/json"},body:body);
    var data = json.decode(res.body);
    if(res.statusCode == 200){
      data['status'] = true;
    }else{
      data['status'] = false;
    }
    return data;
  }

  Future<void> connectWithGoogle(GoogleSignIn googleSignIn) async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final String accessToken = auth.accessToken!;
        var data = await sendTokenToBackend(accessToken);
      }
    } catch (e) {
      print('Error connecting with Google: $e');
    }
  }
  Future<void> sendTokenToBackend(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${apiUrl}/token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        // Handle success
        print('Token sent successfully to the backend!');
        // Optionally, you could get some data back from the backend, like user info or calendar events
      } else {
        print('Failed to send token to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }

  Future<Map<String,dynamic>> sendMessageToApi(String message,chatHistory,stage,email) async {
    const String apiUrl = "http://10.0.2.2:8000/chat";
    final headers = {
      'Content-Type': 'application/json',
    };
    var body = jsonEncode({
      "query": message,
      "chat_history": chatHistory,
      "stage": stage,
      "email":email
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
  }
}