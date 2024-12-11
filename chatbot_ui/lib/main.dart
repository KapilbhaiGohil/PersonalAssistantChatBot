import 'package:chatbot_ui/screens/forgotPass.dart';
import 'package:chatbot_ui/screens/home.dart';
import 'package:chatbot_ui/screens/login.dart';
import 'package:chatbot_ui/screens/register.dart';
import 'package:chatbot_ui/utils/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      theme: darkTheme,
      title: "ChatBot-V1.0",
      routes: {
        '/login':(context) => const LoginScreen(),
        '/register':(context) => const RegisterScreen(),
        '/forgot-pass':(context) => const ForgotPasswordScreen(),
        '/':(context) => const HomeScreen()
      },
    );
  }
}
