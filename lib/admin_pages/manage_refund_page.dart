import 'package:flutter/material.dart';
import 'package:fyp_cras/admin_pages/manage_successful_refund.dart';
import 'package:fyp_cras/admin_pages/manage_pending_refund.dart';

class ManageRefundPage extends StatelessWidget {
  const ManageRefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Refunds'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Refund'),
              Tab(text: 'Successful Refund'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PendingRefundPage(),
            SuccessfulRefundPage(),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: ManageRefundPage(),
  ));
}
