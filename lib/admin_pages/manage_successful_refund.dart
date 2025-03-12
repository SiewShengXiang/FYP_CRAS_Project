import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates

class SuccessfulRefundPage extends StatefulWidget {
  const SuccessfulRefundPage({super.key});

  @override
  _SuccessfulRefundPageState createState() => _SuccessfulRefundPageState();
}

class _SuccessfulRefundPageState extends State<SuccessfulRefundPage> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _fetchBookings() {
    setState(() {
      _bookingsFuture = _getBookings();
    });
  }

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
        .where((booking) => booking['status'] == 'successful refund')
        .toList();

    return bookings;
  }

  void _updateStatus(
      BuildContext context, String bookingId, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Bookings')
          .doc(bookingId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus.')),
      );
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteBooking(BuildContext context, String bookingId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking deleted.')),
      );
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete booking: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmStatusChange(
      BuildContext context, String bookingId, String newStatus) async {
    bool confirmChange = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Status Change'),
          content:
              Text('Are you sure you want to change the status to $newStatus?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false on cancel
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true on confirm
              },
            ),
          ],
        );
      },
    );

    if (confirmChange == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('Bookings')
            .doc(bookingId)
            .update({'status': newStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus.')),
        );
        // Call any method to refresh the list or state if necessary
        _fetchBookings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No bookings with successful refund found.'));
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
                      String selectedStatus = booking['status'];
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
                        DataCell(Text(
                            'RM ${booking['totalPrice'].toStringAsFixed(2)}')),
                        DataCell(Text(booking['userEmail'])),
                        DataCell(
                          DropdownButton<String>(
                            value: selectedStatus,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedStatus = newValue;
                                });
                                _confirmStatusChange(
                                    context, booking['bookingId'], newValue);
                              }
                            },
                            items: <String>[
                              'pending refund',
                              'successful refund'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
