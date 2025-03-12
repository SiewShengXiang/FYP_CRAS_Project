import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_cras/admin_pages/add_vehicle_page.dart';
import 'package:fyp_cras/admin_pages/modified_vehicle_page.dart';

class ManageVehiclePage extends StatelessWidget {
  const ManageVehiclePage({super.key});

  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Vehicle'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Add Vehicle'),
              Tab(text: 'Modify Vehicle'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AddVehiclePage(),
            ModifiedVehiclePage(),
          ],
        ),
      ),
    );
  }
}
