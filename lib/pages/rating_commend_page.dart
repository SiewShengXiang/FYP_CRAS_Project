import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingCommendPage extends StatefulWidget {
  final double initialRating;
  final String bookingId;
  final String carId;

  const RatingCommendPage({
    super.key,
    required this.initialRating,
    required this.bookingId,
    required this.carId,
  });

  @override
  _RatingCommendPageState createState() => _RatingCommendPageState();
}

class _RatingCommendPageState extends State<RatingCommendPage> {
  late double rating;
  final TextEditingController commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
  }

  @override
  void dispose() {
    commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating & Feedback'),
        backgroundColor: Colors.grey[200],
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your rent?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Bookings')
                    .doc(widget.bookingId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final bookingData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  if (bookingData == null) {
                    return const Text('Booking not found');
                  }
                  final Timestamp startDate =
                      bookingData['startDate'] ?? Timestamp.now();
                  final Timestamp endDate =
                      bookingData['endDate'] ?? Timestamp.now();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Cars')
                              .doc(widget.carId)
                              .snapshots(),
                          builder: (context, carSnapshot) {
                            if (!carSnapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final carData = carSnapshot.data!.data()
                                as Map<String, dynamic>?;
                            if (carData == null) {
                              return const Text('Car not found');
                            }
                            final String imageUrl = carData['imageUrl'] ?? '';
                            final String brand = carData['brand'] ?? '';
                            final String model = carData['model'] ?? '';

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brand,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 200),
                                    const SizedBox(height: 5),
                                    Text(
                                      model,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 70),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Rent Time: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'You rated',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              RatingBar.builder(
                                initialRating: rating,
                                minRating: 0,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemPadding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (newRating) {
                                  setState(() {
                                    rating = newRating;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Tell others more about this rent',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: commentsController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Write your comments (max 200 words)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 5,
                                maxLength: 200,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Save rating and comments to Firestore
                  await saveRatingAndComments(rating);
                  // Show a SnackBar with a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rating and comments saved successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Navigate back to the previous page after a delay
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87, // Dark background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text(
                  'Submit',
                  style:
                      TextStyle(color: Colors.white), // Set text color to white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> saveRatingAndComments(double rating) async {
    try {
      // Get the current user's ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Save rating and comments to the 'Ratings' collection
      await FirebaseFirestore.instance.collection('Ratings').add({
        'bookingId': widget.bookingId,
        'carId': widget.carId,
        'rating': rating,
        'comments': commentsController.text.trim(),
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(), // Optional: Add timestamp
      });

      // Update the 'rating' field in the 'Bookings' collection to indicate rating completion
      await FirebaseFirestore.instance
          .collection('Bookings')
          .doc(widget.bookingId)
          .update({
        'rating': 'done',
      });

      print('Rating and comments saved successfully.');
    } catch (e) {
      print('Error saving rating and comments: $e');
    }
  }
}
