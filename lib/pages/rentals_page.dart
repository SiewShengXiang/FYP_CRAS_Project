import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fyp_cras/pages/rating_commend_page.dart';
import 'package:intl/intl.dart';
import 'car_details_page.dart'; // Import the CarDetailsPage

class RentalsPage extends StatefulWidget {
  const RentalsPage({super.key});

  @override
  _RentalsPageState createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final bookingCollection = FirebaseFirestore.instance.collection("Bookings");
  final carCollection = FirebaseFirestore.instance.collection("Cars");

  Future<DocumentSnapshot?> getCarDetails(String carId) async {
    try {
      final carDoc = await carCollection.doc(carId).get();
      return carDoc;
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

  bool isWithinDateRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();

    return currentDate.isAfter(startDate);
  }

  double calculateProgress(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    final totalDuration =
        endDate.add(const Duration(days: 0)).difference(startDate).inSeconds;
    final elapsedDuration = currentDate.difference(startDate).inSeconds;
    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('My Rentals'),
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 12.0),
            tabs: [
              Tab(text: 'Ongoing Bookings'),
              Tab(text: 'Past Bookings'),
              Tab(text: 'Canceled Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Ongoing Bookings Tab
            StreamBuilder<QuerySnapshot>(
              stream: bookingCollection
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'payment done')
                  .where('endDate', isGreaterThan: Timestamp.now())
                  .orderBy('endDate', descending: true)
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
                    child: Text(
                      'No ongoing bookings available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;

                    final DateFormat formatter = DateFormat('yyyy-MM-dd');
                    final String startDate =
                        formatter.format(data['startDate'].toDate());
                    final String endDate =
                        formatter.format(data['endDate'].toDate());

                    final bool isWithinRange = isWithinDateRange(
                        data['startDate'].toDate(), data['endDate'].toDate());

                    final double progress = calculateProgress(
                        data['startDate'].toDate(), data['endDate'].toDate());
                    final String progressPercentage =
                        '${(progress * 100).toStringAsFixed(0)}%';

                    return FutureBuilder<DocumentSnapshot?>(
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

                        final carDoc = carSnapshot.data;

                        if (carDoc == null || !carDoc.exists) {
                          return const Center(
                            child: Text('Car details not found'),
                          );
                        }

                        final carData = carDoc.data() as Map<String, dynamic>;

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
                                            'RM ${formatPrice(data['totalPrice'])}'),
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
                              if (isWithinRange)
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        color:
                                            Colors.green, // Set the color here
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      progressPercentage,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Show confirmation dialog
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
                                                                'pending refund',
                                                          });
                                                          Navigator.of(context)
                                                              .pop();
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Booking canceled successfully',
                                                              ),
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          Navigator.of(context)
                                                              .pop();
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Failed to cancel booking: $e',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                                vertical: 16,
                                                                horizontal: 24),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
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
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.grey,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                                vertical: 16,
                                                                horizontal: 24),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
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
                                      'Cancel Booking',
                                      style: TextStyle(
                                        color: Colors.white, // Set text color
                                      ),
                                    ),
                                  ),
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

            // Past Bookings Tab
            StreamBuilder<QuerySnapshot>(
              stream: bookingCollection
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'payment done')
                  .where('endDate', isLessThanOrEqualTo: Timestamp.now())
                  .orderBy('endDate', descending: true)
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
                    child: Text(
                      'No past bookings available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;

                    final DateFormat formatter = DateFormat('yyyy-MM-dd');
                    final String startDate =
                        formatter.format(data['startDate'].toDate());
                    final String endDate =
                        formatter.format(data['endDate'].toDate());

                    // Check if it's within 14 days after the end date
                    final isWithin14Days = DateTime.now().isBefore(
                        data['endDate'].toDate().add(const Duration(days: 14)));

                    // Check if the rating is not done
                    final isRatingDone = data['rating'] == 'done';

                    return FutureBuilder<DocumentSnapshot?>(
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

                        final carDoc = carSnapshot.data;

                        if (carDoc == null || !carDoc.exists) {
                          return const Center(
                            child: Text('Car details not found'),
                          );
                        }

                        final carData = carDoc.data() as Map<String, dynamic>;

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
                                            'RM ${formatPrice(data['totalPrice'])}'),
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
                              SizedBox(
                                width: double.infinity,
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to CarDetailsPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CarDetailsPage(
                                          car: carDoc,
                                        ),
                                      ),
                                    );
                                  },
                                  style: customButtonStyle(),
                                  child: const Text(
                                    'Select to Reorder',
                                    style: TextStyle(
                                      color: Colors.white, // Set text color
                                    ),
                                  ),
                                ),
                              ),
                              // Add a conditional line after the button
                              // Add a conditional line after the button
                              if (isWithin14Days && !isRatingDone)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                        height: 5), // Move the SizedBox up here
                                    // Show the RatingBar and "Tap to Rate" only if within 14 days after end date
                                    const Divider(
                                      thickness: 1,
                                      color: Colors.grey,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Tap to Rate'),
                                                Text(
                                                  'By ${data['endDate'].toDate().add(Duration(days: data['endDate'] == 1 ? 14 : 0)).add(const Duration(days: 14)).toLocal().toString().split(' ')[0]}',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ), // Add some spacing between the text and the RatingBar
                                            // RatingBar
                                            RatingBar.builder(
                                              initialRating: 0,
                                              minRating: 0,
                                              direction: Axis.horizontal,
                                              allowHalfRating: false,
                                              itemCount: 5,
                                              itemPadding: const EdgeInsets.symmetric(
                                                  horizontal: 4.0),
                                              itemBuilder: (context, _) => const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) {
                                                print(rating);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        RatingCommendPage(
                                                      initialRating: rating,
                                                      carId: data['carId'],
                                                      bookingId: booking.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
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

            // Canceled Bookings Tab
            StreamBuilder<QuerySnapshot>(
              stream: bookingCollection
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'cancel booking')
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
                    child: Text(
                      'No past bookings available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;

                    final DateFormat formatter = DateFormat('yyyy-MM-dd');
                    final String startDate =
                        formatter.format(data['startDate'].toDate());
                    final String endDate =
                        formatter.format(data['endDate'].toDate());

                    return FutureBuilder<DocumentSnapshot?>(
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

                        final carDoc = carSnapshot.data;

                        if (carDoc == null || !carDoc.exists) {
                          return const Center(
                            child: Text('Car details not found'),
                          );
                        }

                        final carData = carDoc.data() as Map<String, dynamic>;

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
                                            'RM ${formatPrice(data['totalPrice'])}'),
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
                              SizedBox(
                                width: double.infinity,
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to CarDetailsPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CarDetailsPage(
                                          car: carDoc,
                                        ),
                                      ),
                                    );
                                  },
                                  style: customButtonStyle(),
                                  child: const Text(
                                    'Select to Reorder',
                                    style: TextStyle(
                                      color: Colors.white, // Set text color
                                    ),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
