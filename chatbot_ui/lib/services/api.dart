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
}