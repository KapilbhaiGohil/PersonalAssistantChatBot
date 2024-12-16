import 'package:chatbot_ui/services/api.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final chatApi = ChatAPI();

  bool _isLoading = false;  // Track the loading state

  // Helper function to validate form inputs
  bool _validateForm() {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    String name = _nameController.text;

    // Simple validation for empty fields
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty) {
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
              controller: _nameController,
              hintText: 'Enter your name',
              labelText: 'Name',
              keyboardType: TextInputType.name,
              onChanged: (text) {},
              icon: const Icon(Icons.person),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              onChanged: (text) {},
              icon: const Icon(Icons.email),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              labelText: 'Password',
              obscureText: true,
              onChanged: (text) {},
              icon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm your password',
              labelText: 'Confirm Password',
              obscureText: true,
              onChanged: (text) {},
              icon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const Center(child: CircularProgressIndicator())  // Show loader if _isLoading is true
                : CustomButton(
              text: 'Register',
              onPressed: () async {
                if (_validateForm()) {
                  setState(() {
                    _isLoading = true;  // Set loading state to true
                  });

                  String email = _emailController.text;
                  String password = _passwordController.text;
                  String name = _nameController.text;
                  print("Register with email: $email and password: $password");

                  // Implement registration logic here
                  var data = await chatApi.register(email, password, name);
                  setState(() {
                    _isLoading = false;  // Set loading state to false after the API call
                  });
                  String msg = data['msg'] ?? "Some error occured";
                  if(data['status']){
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registration Successfull')),
                    );
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
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
                Navigator.pop(context); // Navigate back to Login Screen
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
