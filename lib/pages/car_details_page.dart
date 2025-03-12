import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/pages/users_booking_page.dart';
import 'package:rating_summary/rating_summary.dart';

class CarDetailsPage extends StatelessWidget {
  final DocumentSnapshot car;

  const CarDetailsPage({super.key, required this.car});

  Future<Map<String, dynamic>> fetchRatings(String carId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('Ratings')
          .where('carId', isEqualTo: carId)
          .get();

      int totalRatings = ratingsSnapshot.docs.length;
      double averageRating = 0.0;
      int counterFiveStars = 0;
      int counterFourStars = 0;
      int counterThreeStars = 0;
      int counterTwoStars = 0;
      int counterOneStars = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = doc['rating'] as double;
        averageRating += rating;

        if (rating == 5) {
          counterFiveStars++;
        } else if (rating == 4) {
          counterFourStars++;
        } else if (rating == 3) {
          counterThreeStars++;
        } else if (rating == 2) {
          counterTwoStars++;
        } else if (rating == 1) {
          counterOneStars++;
        }
      }

      if (totalRatings > 0) {
        averageRating /= totalRatings;
      }

      return {
        'totalRatings': totalRatings,
        'averageRating': averageRating.isFinite ? averageRating : 0.0,
        'counterFiveStars': counterFiveStars,
        'counterFourStars': counterFourStars,
        'counterThreeStars': counterThreeStars,
        'counterTwoStars': counterTwoStars,
        'counterOneStars': counterOneStars,
      };
    } catch (e) {
      print('Error fetching ratings: $e');
      rethrow; // rethrow the error to be caught in the FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(car['model']), // Assuming 'model' field in Firestore
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black, // Ensure the text is visible
      ),
      body: Container(
        color: Colors.grey[200], // Set the background color to grey
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Display car image with rounded corners
                      SizedBox(
                        height:
                            300, // Set a fixed height for the image container
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              8), // Set border radius for rounded corners
                          child: Image.network(
                            car['imageUrl'], // Assuming 'imageUrl' field in Firestore
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Car details container
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset:
                                  const Offset(0, 3), // Changes position of shadow
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Car Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DetailRow(label: 'Model', value: car['model']),
                            DetailRow(label: 'Brand', value: car['brand']),
                            DetailRow(
                                label: 'Price',
                                value: 'RM ${car['price']}/Day'),
                            DetailRow(
                                label: 'BodyType', value: car['bodyType']),
                            DetailRow(label: 'Segment', value: car['segment']),
                          ],
                        ),
                      ),
                      // Rating summary container
                      FutureBuilder<Map<String, dynamic>>(
                        future: fetchRatings(car.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            print('Error: ${snapshot.error}');
                            return const Center(
                                child: Text('Error fetching ratings'));
                          }

                          final ratingData = snapshot.data!;
                          final totalRatings = ratingData['totalRatings'];

                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rating Summary',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (totalRatings > 0) ...[
                                  RatingSummary(
                                    counter: ratingData['totalRatings'],
                                    average: ratingData['averageRating'],
                                    showAverage: true,
                                    counterFiveStars:
                                        ratingData['counterFiveStars'],
                                    counterFourStars:
                                        ratingData['counterFourStars'],
                                    counterThreeStars:
                                        ratingData['counterThreeStars'],
                                    counterTwoStars:
                                        ratingData['counterTwoStars'],
                                    counterOneStars:
                                        ratingData['counterOneStars'],
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  const Text('No ratings available.',
                                      style: TextStyle(fontSize: 16)),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      // Comments container
                      Container(
                        width: double
                            .infinity, // Set the width to match other containers
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Ratings')
                                    .where('carId', isEqualTo: car.id)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 4),
                                      child: const Text('Loading...'),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Error: ${snapshot.error}',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }

                                  final ratings = snapshot.data!.docs;

                                  if (ratings.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'No ratings available.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }

                                  List<Widget> commentWidgets = [];

                                  for (int i = 0; i < ratings.length; i++) {
                                    final rating = ratings[i];
                                    final data =
                                        rating.data() as Map<String, dynamic>;
                                    final userEmail = data[
                                        'userEmail']; // Get user email from the rating

                                    // Fetch user data to get the username
                                    commentWidgets
                                        .add(FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(userEmail)
                                          .get(),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: const Text('Loading...'),
                                          );
                                        }

                                        if (userSnapshot.hasError) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Text(
                                              'Error: ${userSnapshot.error}',
                                              style:
                                                  const TextStyle(color: Colors.red),
                                            ),
                                          );
                                        }

                                        final userData = userSnapshot.data!
                                            .data() as Map<String, dynamic>;
                                        final username = userData[
                                            'username']; // Get the username
                                        final profilePictureUrl = userData
                                                .containsKey('profilePicture')
                                            ? userData['profilePicture']
                                            : null; // Get the profile picture URL if it exists

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

                                        // Create stars widget
                                        Widget starWidget = Row(
                                          children: List.generate(5, (index) {
                                            return Icon(Icons.star,
                                                color: index < data['rating']
                                                    ? Colors.amber
                                                    : Colors.grey,
                                                size: 20);
                                          }),
                                        );

                                        // Display username, comment, and rating
                                        Widget commentWidget = Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  leadingWidget, // Show profile picture or default icon
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    username,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  starWidget,
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                data['comments'],
                                                maxLines:
                                                    null, // Allow text to wrap to the next line
                                              ),
                                              const SizedBox(height: 20),
                                              const Divider(
                                                thickness: 1,
                                                color: Colors.grey,
                                              ),
                                            ],
                                          ),
                                        );

                                        return commentWidget;
                                      },
                                    ));
                                  }

                                  return Column(
                                    children: commentWidgets,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //
            // Book Now button at the bottom
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersBookingPage(car: car),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87, // Dark background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style:
                      TextStyle(color: Colors.white), // Set text color to white
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
