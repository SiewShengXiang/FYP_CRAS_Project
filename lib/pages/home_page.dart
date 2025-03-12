import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/components/drawer.dart';
import 'package:fyp_cras/pages/profile_page.dart';
import 'package:fyp_cras/pages/refund_page.dart';
import 'package:fyp_cras/pages/rentals_page.dart';
import 'package:fyp_cras/pages/repayment_page.dart';
import 'package:fyp_cras/pages/user_chat_page.dart';
import 'car_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Sign out user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // Redirect to login page or any other page as needed
  }

  // Navigate to profile page
  void goToProfilePage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  void goToPaymentPage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RepaymentPage(),
      ),
    );
  }

  void goToRentalsPage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RentalsPage(),
      ),
    );
  }

  void goToRefundPage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RefundPage(),
      ),
    );
  }

  void goToChatPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIChatPage(),
      ),
    );
  }

  // Navigate to car details page
  void viewCarDetails(DocumentSnapshot car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarDetailsPage(car: car),
      ),
    );
  }

  // Scroll back to the top of the list
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  void _search(String searchKeyword) {
    setState(() {
      _isSearching = searchKeyword.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Image.asset(
          'assets/icons/UTM-LOGO-FULL.png',
          fit: BoxFit.contain,
          height: 32,
        ),
      ),
      drawer: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth
                .instance.currentUser?.email) // Fetch document by user email
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            // Return the default drawer without profile picture
            return Mydrawer(
              onProfileTap: goToProfilePage,
              onSignOut: signOut,
              onRentalTap: goToRentalsPage,
              onPaymentTap: goToPaymentPage,
              onRefundTap: goToRefundPage,
              profilePictureUrl: null, // Set profilePictureUrl to null
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final profilePictureUrl = userData['profilePicture'];
          return Mydrawer(
            onProfileTap: goToProfilePage,
            onSignOut: signOut,
            onRentalTap: goToRentalsPage,
            onPaymentTap: goToPaymentPage,
            onRefundTap: goToRefundPage,
            profilePictureUrl: profilePictureUrl,
          );
        },
      ),
      body: Column(
        children: [
          // Fixed header with welcome text and search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome To SMP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enjoy the drive with our Vehicle',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: _search,
                          decoration: const InputDecoration(
                            hintText: "Search a Car",
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                        if (_isSearching)
                          Positioned(
                            right: 0,
                            child: IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable list of cars
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Cars')
                      .where('available', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No collections available.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final List<QueryDocumentSnapshot> collectionDocs =
                        snapshot.data!.docs;
                    final List<QueryDocumentSnapshot> filteredCollectionDocs =
                        _isSearching
                            ? collectionDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                String model = data['model'];
                                return model.toLowerCase().contains(
                                    _searchController.text.toLowerCase());
                              }).toList()
                            : collectionDocs;

                    if (filteredCollectionDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No cars available.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredCollectionDocs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot car = filteredCollectionDocs[index];
                        return GestureDetector(
                          onTap: () => viewCarDetails(car),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 200,
                                      child: Image.network(
                                        car['imageUrl'], // Assuming 'imageUrl' field in Firestore
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        car['model'], // Assuming 'model' field in Firestore
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'RM ${car['price']}/Day', // Assuming 'price' field in Firestore
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToChatPage,
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.chat),
      ),
    );
  }
}
