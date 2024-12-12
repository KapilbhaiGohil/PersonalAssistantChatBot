import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatAPI {
  Future<http.Response> signUp(String email,String password)async{
    var body = jsonEncode(
      {
        'email':email,
        'password':password
      }
    );
    http.Response res = await http.post(Uri.parse("uri"),headers: {"Content-Type": "application/json"},body:body);
    return res;
  }

  Future<Map<String,dynamic>> sendMessageToApi(String message,chatHistory,stage) async {
    const String apiUrl = "http://10.0.2.2:8000/chat";
    final headers = {
      'Content-Type': 'application/json',
    };
    var body = jsonEncode({
      "query": message,
      "chat_history": chatHistory,
      "stage": stage
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