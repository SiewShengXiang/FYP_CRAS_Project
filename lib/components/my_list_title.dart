import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;
  final String? profilePictureUrl;

  const MyListTile({super.key, 
    required this.icon,
    required this.text,
    this.onTap,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: profilePictureUrl != null
            ? ClipOval(
                child: Image.network(
                  profilePictureUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(icon),
      ),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
