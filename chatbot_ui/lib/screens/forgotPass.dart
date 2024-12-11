import 'package:flutter/material.dart';
import 'package:chatbot_ui/widgets/Input.dart'; // Assuming you have the CustomTextField in this file
import 'package:chatbot_ui/utils/colors.dart'; // Assuming your AppColors are in this file

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  // Helper function to validate email
  bool _validateEmail() {
    String email = _emailController.text;
    if (email.isEmpty || !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Enter your email address to reset your password.",
              style: TextStyle(
                fontSize: 16.0,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 40),
            // Custom TextField for email
            CustomTextField(
              controller: _emailController,
              hintText: "Enter your email",
              labelText: "Email",
              keyboardType: TextInputType.emailAddress,
              onChanged: (text) {
                // Handle text changes if needed
              },
              icon: const Icon(Icons.email),
            ),
            const SizedBox(height: 25),
            CustomButton(
              icon: Icon(Icons.lock_reset),
              onPressed: ()=>{

              },
              text: "Reset",
              backgroundColor: AppColors.buttonBackgroundColor,
              borderRadius: 8,

            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate back to the login screen
                Navigator.pop(context);
              },
              child: const Text(
                'Remember your password? Login here.',
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