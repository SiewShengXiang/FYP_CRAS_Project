import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_cras/components/button.dart';
import 'package:fyp_cras/components/text_field.dart';
import 'package:fyp_cras/pages/login_page.dart'; // Import the LoginPage

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController emailTextController = TextEditingController();

  ForgotPasswordPage({super.key});

  void resetPassword(BuildContext context) async {
    if (emailTextController.text.isEmpty) {
      _showMessage(context, "Please enter your email.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailTextController.text,
      );
      _showMessage(context, "Password reset email sent.");
    } on FirebaseAuthException catch (e) {
      _showMessage(context, e.message ?? "Failed to send reset email.");
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pushReplacement(
                // Navigate back to login page
                MaterialPageRoute(
                    builder: (context) => LoginPage(
                          onTap: () {},
                        )),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyTextField(
              controller: emailTextController,
              hintText: 'Enter your email',
              obscureText: false,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            MyButton(
              onTap: () => resetPassword(context),
              text: 'Reset Password',
            ),
          ],
        ),
      ),
    );
  }
}
