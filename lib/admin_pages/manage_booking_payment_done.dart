import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates

class ManageBookingPaymentDone extends StatelessWidget {
  const ManageBookingPaymentDone({super.key});

  Future<List<Map<String, dynamic>>> _getBookings() async {
    QuerySnapshot bookingsSnapshot =
        await FirebaseFirestore.instance.collection('Bookings').get();

    List<Map<String, dynamic>> bookings = bookingsSnapshot.docs
        .map((doc) {
          return {
            'bookingId': doc.id,
            'carId': doc['carId'],
            'delivery': doc['delivery'],
            'deliveryLocation': doc['deliveryLocation'],
            'endDate': (doc['endDate'] as Timestamp).toDate(),
            'startDate': (doc['startDate'] as Timestamp).toDate(),
            'status': doc['status'],
            'timestamp': (doc['timestamp'] as Timestamp).toDate(),
            'totalPrice': doc['totalPrice'],
            'userEmail': doc['userEmail'],
          };
        })
        .where((booking) => booking['status'] == 'payment done')
        .toList();

    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No bookings with "payment done" found.'));
          }
          List<Map<String, dynamic>> bookings = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    return Colors
                        .blue; // Change this to your desired header color
                  },
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Booking ID',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Car ID',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Delivery',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Delivery Location',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Start Date',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'End Date',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'User Submit Time',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total Price',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'User Email',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                rows: bookings.map((booking) {
                  return DataRow(cells: [
                    DataCell(Text(booking['bookingId'])),
                    DataCell(Text(booking['carId'])),
                    DataCell(Text(booking['delivery'].toString())),
                    DataCell(Text(booking['deliveryLocation'])),
                    DataCell(Text(DateFormat('yyyy-MM-dd – kk:mm')
                        .format(booking['startDate']))),
                    DataCell(Text(DateFormat('yyyy-MM-dd – kk:mm')
                        .format(booking['endDate']))),
                    DataCell(Text(DateFormat('yyyy-MM-dd – kk:mm')
                        .format(booking['timestamp']))),
                    DataCell(
                        Text('RM ${booking['totalPrice'].toStringAsFixed(2)}')),
                    DataCell(Text(booking['userEmail'])),
                    DataCell(Text(booking['status'])),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
