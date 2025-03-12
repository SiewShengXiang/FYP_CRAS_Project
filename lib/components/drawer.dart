import 'package:flutter/material.dart';
import 'package:fyp_cras/components/my_list_title.dart';

class Mydrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSignOut;
  final void Function()? onRentalTap;
  final void Function()? onPaymentTap;
  final void Function()? onRefundTap;
  final String? profilePictureUrl;

  const Mydrawer({
    super.key,
    required this.onProfileTap,
    required this.onSignOut,
    required this.onRentalTap,
    required this.onPaymentTap,
    required this.onRefundTap,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // header
              DrawerHeader(
                child: profilePictureUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profilePictureUrl!),
                        radius: 45,
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 64,
                      ),
              ),

              // home list tile
              MyListTile(
                icon: Icons.home,
                text: 'H O M E',
                onTap: () => Navigator.pop(context),
              ),

              //profile list tile
              MyListTile(
                icon: Icons.person,
                text: 'P R O F I L E',
                onTap: onProfileTap,
              ),

              MyListTile(
                icon: Icons.account_balance_wallet,
                text: 'P A Y M E N T',
                onTap: onPaymentTap,
              ),

              MyListTile(
                icon: Icons.directions_car,
                text: 'R E N T A L',
                onTap: onRentalTap,
              ),

              MyListTile(
                icon: Icons.monetization_on,
                text: 'R E F U N D',
                onTap: onRefundTap,
              ),
            ],
          ),

          // logout lis tiles
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: MyListTile(
              icon: Icons.logout,
              text: 'L O G O U T',
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}
