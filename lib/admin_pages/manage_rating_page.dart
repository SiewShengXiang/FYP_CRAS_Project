import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // Import the intl package

class ManageRatingPage extends StatelessWidget {
  const ManageRatingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists Ratings'),
        backgroundColor:
            Colors.grey[200], // Set AppBar background color to grey
      ),
      body: Container(
        color: Colors.grey[200], // Set background color to grey
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Ratings')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.red, // Set error text color to red
                    fontWeight: FontWeight.bold, // Make the error text bold
                  ),
                ),
              );
            }

            final ratingsDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: ratingsDocs.length,
              itemBuilder: (BuildContext context, int index) {
                final ratingData =
                    ratingsDocs[index].data() as Map<String, dynamic>;
                final ratingId =
                    ratingsDocs[index].id; // Get the rating document ID
                final bookingId = ratingData['bookingId'];
                final carId = ratingData['carId'];
                final comments = ratingData['comments'];
                final rating = ratingData['rating'];
                final userEmail = ratingData['userEmail']; // Get user email
                final timestamp = ratingData['timestamp'];

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Bookings')
                      .doc(bookingId)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> bookingSnapshot) {
                    if (bookingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    if (bookingSnapshot.hasError) {
                      return Text(
                        'Error: ${bookingSnapshot.error}',
                        style: const TextStyle(
                          color: Colors.red, // Set error text color to red
                          fontWeight:
                              FontWeight.bold, // Make the error text bold
                        ),
                      );
                    }

                    final bookingData =
                        bookingSnapshot.data!.data() as Map<String, dynamic>;
                    final startDate = bookingData['startDate']?.toDate();
                    final endDate = bookingData['endDate']?.toDate();
                    final totalPrice = bookingData[
                        'totalPrice']; // Get totalPrice from Bookings collection

                    // Format the startDate and endDate to display only the date
                    final formattedStartDate = startDate != null
                        ? DateFormat('yyyy-MM-dd').format(startDate)
                        : 'N/A';
                    final formattedEndDate = endDate != null
                        ? DateFormat('yyyy-MM-dd').format(endDate)
                        : 'N/A';

                    // Calculate how many days ago the comment was made
                    final daysAgo =
                        DateTime.now().difference(timestamp.toDate()).inDays;

                    return Container(
                      width:
                          double.infinity, // Set maximum width to the container
                      margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16), // Add margin for spacing
                      padding: const EdgeInsets.all(8), // Add padding for spacing
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Set container background color to white
                        borderRadius: BorderRadius.circular(
                            8), // Add border radius for rounded corners
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Leading Widget

                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(userEmail)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    if (userSnapshot.hasError) {
                                      return Text(
                                        'Error: ${userSnapshot.error}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }

                                    final userData = userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final profilePictureUrl =
                                        userData.containsKey('profilePicture')
                                            ? userData['profilePicture']
                                            : null;

                                    // Check if the profile picture URL is available
                                    Widget leadingWidget;
                                    if (profilePictureUrl != null &&
                                        profilePictureUrl.isNotEmpty) {
                                      leadingWidget = CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(profilePictureUrl),
                                      );
                                    } else {
                                      leadingWidget = const CircleAvatar(
                                        child: Icon(Icons.person),
                                      );
                                    }

                                    return Center(child: leadingWidget);
                                  },
                                ),
                                const SizedBox(height: 10),
                                // User Email
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email:',
                                      style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold, // Make the text bold
                                      ),
                                    ),
                                    Text('${userEmail ?? 'N/A'}'),
                                  ],
                                ),
                                // Rating
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rating:',
                                      style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold, // Make the text bold
                                      ),
                                    ),
                                    Center(
                                      child: RatingBarIndicator(
                                        rating: rating.toDouble(),
                                        itemBuilder: (context, index) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 20.0,
                                        direction: Axis.horizontal,
                                      ),
                                    ),
                                  ],
                                ),
                                // Car Information
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Cars')
                                      .doc(carId)
                                      .get(),
                                  builder: (context, carSnapshot) {
                                    if (carSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        'Loading Car...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }
                                    if (carSnapshot.hasError) {
                                      return Text(
                                        'Error: ${carSnapshot.error}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }

                                    final carData = carSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final carBrand = carData['brand'] ?? 'N/A';
                                    final carModel = carData['model'] ?? 'N/A';
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Car:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('$carBrand $carModel'),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Total Price:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'RM ${totalPrice.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Booking Dates
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.delete),
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
                                                  'Are you sure you want to delete this rating?',
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () async {
                                                            try {
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'Ratings')
                                                                  .doc(ratingId)
                                                                  .delete();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Rating deleted successfully'),
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
                                                                      'Failed to delete rating: $e'),
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
                                                                    vertical:
                                                                        16),
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
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          style: TextButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.grey,
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        16),
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
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 100),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const Text(
                                      'Booking ID:',
                                      style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold, // Make the text bold
                                      ),
                                    ),
                                    Text('${bookingId ?? 'N/A'}'),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Booking Dates:',
                                      style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold, // Make the text bold
                                      ),
                                    ),
                                    Text(
                                        '$formattedStartDate - $formattedEndDate'),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                                // Comments
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Comments:',
                                      style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold, // Make the text bold
                                      ),
                                    ),
                                    Text('${comments ?? 'N/A'}'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Days Ago
                                Center(
                                  child: Text(
                                    '$daysAgo days ago',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
