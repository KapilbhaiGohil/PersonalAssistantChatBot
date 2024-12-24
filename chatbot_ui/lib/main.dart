import 'package:chatbot_ui/screens/forgotPass.dart';
import 'package:chatbot_ui/screens/home.dart';
import 'package:chatbot_ui/screens/login.dart';
import 'package:chatbot_ui/screens/register.dart';
import 'package:chatbot_ui/services/api.dart';
import 'package:chatbot_ui/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final chatApi = ChatAPI();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool isLoggedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      String? email = await _secureStorage.read(key: 'email');
      String? password = await _secureStorage.read(key: 'password');
      if (email != null && password != null) {
        var data = await chatApi.login(email, password);
        if (data['data'] != null) {
          setState(() {
            isLoggedIn = true;
          });
        }
      }
    } catch (e) {
      print("Error during login: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme,
      title: "ChatBot-V1.0",
      home: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
        )
          : isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-pass': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
