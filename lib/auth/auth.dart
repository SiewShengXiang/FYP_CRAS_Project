import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_cras/admin_pages/admin_page.dart';
import 'package:fyp_cras/auth/login_or_register.dart';
import 'package:fyp_cras/pages/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            // Get the user's role from Firestore and redirect accordingly
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(FirebaseAuth.instance.currentUser!.email)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  // Show error message if fetching user data fails
                  return Text('Error: ${userSnapshot.error}');
                }

                // Get the role from the user document
                String? role = userSnapshot.data?.get('role');

                // Redirect based on role
                if (role == 'admin') {
                  return const AdminPage();
                } else if (role == 'user') {
                  return const HomePage();
                } else {
                  // If no role or invalid role, redirect to login or register
                  return const LoginOrRegister();
                }
              },
            );
          } else {
            // User is not logged in, show login or register page
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
