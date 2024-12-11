import 'package:flutter/material.dart';
import 'package:chatbot_ui/utils/colors.dart';
import 'package:chatbot_ui/widgets/Input.dart'; // Assuming CustomTextField is defined here


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Helper function to validate form inputs
  bool _validateForm() {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Simple validation for empty fields
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return false;
    }

    // Validate that password and confirm password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm your password',
              labelText: 'Confirm Password',
              obscureText: true,
              onChanged: (text) {
                // Handle text changes
              },
              icon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 25),
            CustomButton(
              text: 'Register',
              onPressed: () {
                // Perform registration if inputs are valid
                if (_validateForm()) {
                  String email = _emailController.text;
                  String password = _passwordController.text;
                  print("Register with email: $email and password: $password");
                  // Implement registration logic here, such as API call
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields correctly')),
                  );
                }
              },
              icon: const Icon(Icons.person_add),
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.buttonTextColor,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate back to Login Screen
                Navigator.pop(context);
              },
              child: const Text(
                'Already have an account? Login here.',
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
