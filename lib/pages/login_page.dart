import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/admin_pages/admin_page.dart';
import 'package:fyp_cras/components/button.dart';
import 'package:fyp_cras/components/text_field.dart';
import 'package:fyp_cras/pages/forget_password_page.dart';
import 'package:fyp_cras/pages/home_page.dart'; // Import the ForgotPasswordPage

class LoginPage extends StatefulWidget {
  final Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text editing controllers
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  // Sign user in
  void signIn() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Sign in
      print('Attempting to sign in with email: ${emailTextController.text}');
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      print('Sign in successful for user: ${userCredential.user!.email}');
      print('User ID: ${userCredential.user!.uid}');
      // Dismiss loading circle
      Navigator.of(context).pop();

      // Get the user document from Firestore
      print('Fetching user document from Firestore');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .get();

      if (userDoc.exists) {
        // Get the role from the user document
        String? role = userDoc.get('role');
        print('User role: $role');

        // Navigate based on role
        if (role == 'admin') {
          print('Navigating to AdminPage');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
        } else if (role == 'user') {
          print('Navigating to HomePage');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Check if role is null or empty
          if (role == null || role.isEmpty) {
            print('No role associated with the user.');
            displayMessage('No role associated with the user.');
          } else {
            // Show error message for invalid role
            print('Invalid role associated with the user.');
            displayMessage('Invalid role associated with the user.');
          }
        }
      } else {
        print('User document does not exist.');
        displayMessage('User document does not exist.');
      }
    } on FirebaseAuthException catch (e) {
      // Dismiss loading circle
      Navigator.pop(context);

      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'The email address is not registered.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'The password is incorrect.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Try again later.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }

      print('FirebaseAuthException: ${e.code} - $errorMessage');
      displayMessage(errorMessage);
    } catch (e) {
      // Handle any other errors
      Navigator.pop(context);
      print('Unknown error: $e');
      displayMessage('An unknown error occurred. Please try again.');
    }
  }

  // Display a dialog message
  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const urlImage1 = 'assets/images/City.png';

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const SizedBox(height: 125),
                  Image.asset(
                    urlImage1,
                    height: 150, // Set the height to match register page
                  ),
                  const SizedBox(height: 30),

                  // Welcome back message
                  Text(
                    "Welcome Back, you've been missed!",
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Email text field
                  MyTextField(
                    controller: emailTextController,
                    hintText: 'Email',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),

                  // Password text field
                  MyTextField(
                    controller: passwordTextController,
                    hintText: 'Password',
                    obscureText: true,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 25),

                  // Forgot password link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.blue,
                        //decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Sign in button
                  MyButton(
                    onTap: signIn,
                    text: 'Sign In',
                  ),
                  const SizedBox(height: 25),

                  // Register prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member?",
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          "Register Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
