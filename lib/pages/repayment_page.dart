import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/pages/payment_page.dart';
import 'package:intl/intl.dart';

class RepaymentPage extends StatefulWidget {
  const RepaymentPage({super.key});

  @override
  _RepaymentPageState createState() => _RepaymentPageState();
}

class _RepaymentPageState extends State<RepaymentPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final bookingCollection = FirebaseFirestore.instance.collection("Bookings");
  final carCollection = FirebaseFirestore.instance.collection("Cars");

  Future<Map<String, dynamic>?> getCarDetails(String carId) async {
    try {
      final carDoc = await carCollection.doc(carId).get();
      return carDoc.data();
    } catch (e) {
      print('Error fetching car details: $e');
      return null;
    }
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  ButtonStyle customButtonStyle() {
    return ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Set button border radius
      ),
      backgroundColor: Colors.black, // Set button background color
    );
  }

  @override
  Widget build(BuildContext context) {
    final twoDaysFromNow = DateTime.now().add(const Duration(days: 2));
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                'Please Pay Before Three Bookings Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bookingCollection
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'pending payment')
                  .where('startDate',
                      isGreaterThan: Timestamp.fromDate(twoDaysFromNow))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final bookings = snapshot.data!.docs;

                if (bookings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No Pending Payments.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: getCarDetails(data['carId']),
                      builder: (context, carSnapshot) {
                        if (carSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (carSnapshot.hasError) {
                          return const Center(
                            child: Text('Error fetching car details'),
                          );
                        }

                        final carData = carSnapshot.data;

                        if (carData == null) {
                          return const Center(
                            child: Text('Car details not found'),
                          );
                        }

                        final DateFormat formatter = DateFormat('yyyy-MM-dd');
                        final String startDate =
                            formatter.format(data['startDate'].toDate());
                        final String endDate =
                            formatter.format(data['endDate'].toDate());

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image:
                                            NetworkImage(carData['imageUrl']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          carData['model'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'RM ${formatPrice(data['totalPrice'])}',
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'From: $startDate',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'To: $endDate',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PaymentPage(
                                              totalPrice:
                                                  calculateTotalPrice(data),
                                              bookingId: booking.id,
                                              carId: data['carId'],
                                              startDate: (data['startDate']
                                                      as Timestamp)
                                                  .toDate(),
                                              endDate:
                                                  (data['endDate'] as Timestamp)
                                                      .toDate(),
                                            ),
                                          ),
                                        );
                                      },
                                      style: customButtonStyle(),
                                      child: const Text(
                                        'Click to Payment',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10, // Add spacing between buttons
                                  ),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Confirmation',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              content: const Text(
                                                'Are you sure you want to cancel this booking?',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              actionsPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              backgroundColor: Colors.white,
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              actions: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            await booking
                                                                .reference
                                                                .update({
                                                              'status':
                                                                  'cancel booking',
                                                            });
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Booking canceled successfully',
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to cancel booking: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                                  vertical: 16,
                                                                  horizontal:
                                                                      24),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'YES',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ), // Add spacing between buttons
                                                    Expanded(
                                                      child: TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        style: TextButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.grey,
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                                  vertical: 16,
                                                                  horizontal:
                                                                      24),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'NO',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 100),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      style: customButtonStyle(),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double calculateTotalPrice(Map<String, dynamic> bookingData) {
    double totalPrice = bookingData['totalPrice'] ?? 0.00;
    return totalPrice;
  }
}
