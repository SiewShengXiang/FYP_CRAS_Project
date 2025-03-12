import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_cras/admin_pages/manage_booking_page.dart';
import 'package:fyp_cras/admin_pages/manage_rating_page.dart';
import 'package:fyp_cras/admin_pages/manage_refund_page.dart';
import 'package:fyp_cras/admin_pages/manage_vehicle_page.dart';
import 'package:fyp_cras/components/my_list_title.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/SMP.jpg',
                    width: 200,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              MyListTile(
                icon: Icons.home,
                text: 'H O M E',
                onTap: () => Navigator.pop(context),
              ),
              MyListTile(
                icon: Icons.directions_car,
                text: 'Manage Vehicles',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageVehiclePage()),
                  );
                },
              ),
              MyListTile(
                icon: Icons.shopping_cart,
                text: 'Manage Orders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageBookingPage()),
                  );
                },
              ),
              MyListTile(
                icon: Icons.star,
                text: 'Manage Ratings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageRatingPage()),
                  );
                },
              ),
              MyListTile(
                icon: Icons.money_off,
                text: 'Manage Refunds',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageRefundPage()),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: MyListTile(
              icon: Icons.logout,
              text: 'L O G O U T',
              onTap: () => signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
