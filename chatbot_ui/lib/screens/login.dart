import 'package:chatbot_ui/screens/forgotPass.dart';
import 'package:chatbot_ui/screens/register.dart';
import 'package:chatbot_ui/utils/colors.dart';
import 'package:chatbot_ui/widgets/Input.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              onChanged: (text) {
                // Handle text changes
              },
              icon: const Icon(Icons.email),
            ),
            const SizedBox(height: 25),
            CustomTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              labelText: 'Password',
              obscureText: true,
              onChanged: (text) {
                // Handle text changes
              },
              icon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              TextButton(
                onPressed: () {
                  // Navigate to Forgot Password Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Login',
              onPressed: () {
                // Handle login logic here, for example, API call or validation
                String email = _emailController.text;
                String password = _passwordController.text;
                // Example: Check if email and password are not empty
                if (email.isNotEmpty && password.isNotEmpty) {
                  // Process login
                  print("Login with email: $email and password: $password");
                } else {
                  // Show error message if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              icon: const Icon(Icons.login, size: 20),
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.buttonTextColor,
            ),
            const SizedBox(height: 20),
            // TextButton for registration navigation
            TextButton(
              onPressed: () {
                // Navigate to Register Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text(
                'Don\'t have an account? Register here.',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
