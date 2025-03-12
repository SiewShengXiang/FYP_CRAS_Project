import 'package:flutter/material.dart';
import 'package:fyp_cras/admin_pages/manage_booking_add.dart';
import 'package:fyp_cras/admin_pages/manage_booking_payment_done.dart';
import 'package:fyp_cras/admin_pages/manage_booking_pending_payment.dart';

class ManageBookingPage extends StatelessWidget {
  const ManageBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Change the length to 3 for three tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Bookings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PaymentDone'),
              Tab(text: 'PendingPayment'),
              Tab(text: 'AddBooking'), // New tab
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), // Disable swipe navigation
          children: [
            ManageBookingPaymentDone(), // First tab view: List of bookings with payment done
            ManageBookingPendingPayment(), // Second tab view: List of bookings with pending payment
            ManageBookingAdd(), // Third tab view: Add booking
          ],
        ),
      ),
    );
  }
}
