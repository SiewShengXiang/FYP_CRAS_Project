import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/components/button.dart';
import 'package:fyp_cras/components/text_field.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth package

class ManageBookingAdd extends StatefulWidget {
  const ManageBookingAdd({super.key});

  @override
  _ManageBookingAddState createState() => _ManageBookingAddState();
}

class _ManageBookingAddState extends State<ManageBookingAdd> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController deliveryLocationController =
      TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();

  String? selectedCarId; // Track selected car ID
  String? selectedUserEmail; // Track selected user email
  String? selectedStatus; // Track selected status
  bool? selectedDelivery; // Track selected delivery option

  DateTime? selectedStartDate; // Track selected start date
  DateTime? selectedEndDate; // Track selected end date

  List<CarModel> cars = []; // List to store cars fetched from Firestore
  List<String> userEmails =
      []; // List to store user emails fetched from Firestore
  List<String> bookingStatuses = ['pending payment', 'payment done'];
  List<String> deliveryOptions = ['true', 'false'];

  @override
  void initState() {
    super.initState();
    fetchCars();
    fetchUserEmails();
  }

  void fetchCars() async {
    try {
      QuerySnapshot carSnapshot =
          await FirebaseFirestore.instance.collection('Cars').get();
      setState(() {
        cars =
            carSnapshot.docs.map((doc) => CarModel.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error fetching cars: $e');
    }
  }

  void fetchUserEmails() async {
    try {
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('Users').get();
      setState(() {
        userEmails = userSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching user emails: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    return user?.uid;
  }

  void _addBooking(String userId) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Bookings').add({
          'carId': selectedCarId,
          'delivery': selectedDelivery,
          'deliveryLocation': deliveryLocationController.text,
          'startDate': selectedStartDate,
          'endDate': selectedEndDate,
          'status': selectedStatus ??
              'pending', // Default to 'pending' if no status is selected
          'timestamp': FieldValue.serverTimestamp(),
          'totalPrice': double.parse(totalPriceController.text),
          'userEmail': selectedUserEmail,
          'userId': userId, // Save the userId here
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking added successfully')),
        );
        // Clear all text fields after successful submission
        deliveryLocationController.clear();
        totalPriceController.clear();
        setState(() {
          selectedCarId = null;
          selectedUserEmail = null;
          selectedStartDate = null;
          selectedEndDate = null;
          selectedStatus = null; // Reset selected status
          selectedDelivery = null; // Reset selected delivery option
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: FutureBuilder<String?>(
              future: getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('No user logged in.');
                }
                //String userId = snapshot.data!;
                return ListView(
                  children: [
                    DropdownButtonFormField<CarModel>(
                      value: selectedCarId != null
                          ? cars.firstWhere(
                              (car) => car.id == selectedCarId,
                            )
                          : null,
                      onChanged: (newValue) {
                        setState(() {
                          selectedCarId = newValue?.id;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Select Car',
                        border: OutlineInputBorder(),
                      ),
                      items: cars.isEmpty
                          ? []
                          : cars.map((car) {
                              return DropdownMenuItem<CarModel>(
                                value: car,
                                child: Row(
                                  children: [
                                    Image.network(
                                      car.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(car.id),
                                  ],
                                ),
                              );
                            }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a car';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedUserEmail,
                      onChanged: (newValue) {
                        setState(() {
                          selectedUserEmail = newValue;
                        });
                      },
                      items: userEmails.map((userEmail) {
                        return DropdownMenuItem<String>(
                          value: userEmail,
                          child: Text(userEmail),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select User Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a user email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<bool>(
                      value: selectedDelivery,
                      onChanged: (newValue) {
                        setState(() {
                          selectedDelivery = newValue;
                        });
                      },
                      items: deliveryOptions.map((option) {
                        return DropdownMenuItem<bool>(
                          value: option == 'true',
                          child: Text(option == 'true'
                              ? 'Delivery: Yes'
                              : 'Delivery: No'),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select Delivery Option',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a delivery option';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: deliveryLocationController,
                      hintText: 'Delivery Location',
                      obscureText: false,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      onChanged: (newValue) {
                        setState(() {
                          selectedStatus = newValue;
                        });
                      },
                      items: bookingStatuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select Status',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a status';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: selectedStartDate == null
                                  ? ''
                                  : DateFormat('yyyy-MM-dd')
                                      .format(selectedStartDate!),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start Date (yyyy-MM-dd)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedStartDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(DateTime.now().year + 1),
                                  );
                                  if (pickedDate != null &&
                                      pickedDate != selectedStartDate) {
                                    setState(() {
                                      selectedStartDate = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a start date';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: selectedEndDate == null
                                  ? ''
                                  : DateFormat('yyyy-MM-dd')
                                      .format(selectedEndDate!),
                            ),
                            decoration: InputDecoration(
                              hintText: 'End Date (yyyy-MM-dd)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedEndDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(DateTime.now().year + 1),
                                  );
                                  if (pickedDate != null &&
                                      pickedDate != selectedEndDate) {
                                    setState(() {
                                      selectedEndDate = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an end date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: totalPriceController,
                      hintText: 'Total Price',
                      obscureText: false,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: () async {
                        String? userId = await getCurrentUserId();
                        if (userId != null) {
                          _addBooking(userId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not authenticated')),
                          );
                        }
                      },
                      text: 'Add Booking',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CarModel {
  final String id;
  final String imageUrl;

  CarModel({
    required this.id,
    required this.imageUrl,
  });

  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CarModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
