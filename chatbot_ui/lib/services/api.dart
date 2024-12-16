import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";

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