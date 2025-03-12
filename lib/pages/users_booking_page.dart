import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_clean_calendar/controllers/clean_calendar_controller.dart';
import 'package:scrollable_clean_calendar/scrollable_clean_calendar.dart';
import 'package:scrollable_clean_calendar/utils/enums.dart';
import 'payment_page.dart';

class UsersBookingPage extends StatefulWidget {
  final DocumentSnapshot car;

  const UsersBookingPage({super.key, required this.car});

  @override
  _UsersBookingPageState createState() => _UsersBookingPageState();
}

class _UsersBookingPageState extends State<UsersBookingPage> {
  late CleanCalendarController _calendarController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCalendarVisible = false;
  bool _needDelivery = false;
  final TextEditingController _locationController = TextEditingController();
  List<DateTime> _unavailableDates = [];
  List<DateTime> _holdDates = [];

  @override
  void initState() {
    super.initState();
    _calendarController = CleanCalendarController(
      minDate: DateTime.now(),
      maxDate: DateTime.now().add(const Duration(days: 365)),
      onRangeSelected: (startDate, endDate) {
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
        });
      },
    );

    _fetchUnavailableDates();
    _fetchHoldDates();
  }

  Future<void> _fetchUnavailableDates() async {
    try {
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('Bookings')
          .where('carId', isEqualTo: widget.car.id)
          .where('status', isEqualTo: 'payment done')
          .get();

      List<DateTime> unavailableDates = [];
      for (var doc in bookingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime startDate = (data['startDate'] as Timestamp).toDate();
        DateTime endDate = (data['endDate'] as Timestamp).toDate();
        for (var date = startDate;
            date.isBefore(endDate);
            date = date.add(const Duration(days: 1))) {
          unavailableDates.add(date);
        }
      }

      setState(() {
        _unavailableDates = unavailableDates;
      });
    } catch (e) {
      print('Error fetching unavailable dates: $e');
    }
  }

  Future<void> _fetchHoldDates() async {
    try {
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('Bookings')
          .where('carId', isEqualTo: widget.car.id)
          .where('status', isEqualTo: 'pending payment')
          .get();

      List<DateTime> pendingDates = [];
      for (var doc in pendingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime startDate = (data['startDate'] as Timestamp).toDate();
        DateTime endDate = (data['endDate'] as Timestamp).toDate();

        // Calculate the difference between the current date and the start date
        int daysDifference = startDate.difference(DateTime.now()).inDays;

        // Check if the real date is more than 3 days from the start date
        if (daysDifference >= 2) {
          // Add all dates between startDate and endDate to pendingDates list
          for (var date = startDate;
              date.isBefore(endDate);
              date = date.add(const Duration(days: 1))) {
            pendingDates.add(date);
          }
        }
      }

      setState(() {
        _holdDates = pendingDates;
      });
    } catch (e) {
      print('Error fetching pending dates: $e');
    }
  }

  bool _isDateAvailable(DateTime date) {
    return !_unavailableDates.contains(date);
  }

  bool _isDateHold(DateTime date) {
    return _holdDates.contains(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isCalendarVisible = !_isCalendarVisible;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Date',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} to ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                      : 'Select a date range',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isCalendarVisible)
                      Stack(
                        children: [
                          Container(
                            height: 400,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ScrollableCleanCalendar(
                              calendarController: _calendarController,
                              layout: Layout.BEAUTY,
                              dayBuilder: (context, dayValues) {
                                DateTime currentDate = dayValues.day;
                                bool isUnavailable =
                                    !_isDateAvailable(currentDate);
                                bool isStartSelected = _startDate != null &&
                                    _startDate == currentDate;
                                bool isEndSelected =
                                    _endDate != null && _endDate == currentDate;
                                bool isInRange = _startDate != null &&
                                    _endDate != null &&
                                    currentDate.isAfter(_startDate!) &&
                                    currentDate.isBefore(_endDate!);
                                bool isPastDate = currentDate.isBefore(
                                    DateTime.now().subtract(const Duration(days: 1)));

                                // Inside dayBuilder method
                                bool isHold = _isDateHold(currentDate);

                                // Debugging print statements
                                print(
                                    'currentDate: $currentDate, isHold: $isHold');

                                Color? backgroundColor;
                                String? displayText;
                                IconData? iconData;

                                if (isPastDate) {
                                  backgroundColor = Colors.transparent;
                                  iconData = Icons.close;
                                } else if (isUnavailable) {
                                  backgroundColor = Colors.red.withOpacity(0.5);
                                  displayText = 'FULL';
                                } else if (isHold) {
                                  backgroundColor =
                                      Colors.yellow.withOpacity(0.5);
                                  displayText = 'HOLD'; // Display HOLD text
                                } else if (isStartSelected &&
                                    _endDate == null) {
                                  backgroundColor =
                                      Colors.blue.withOpacity(0.25);
                                } else if (isStartSelected || isEndSelected) {
                                  backgroundColor =
                                      Colors.blue.withOpacity(0.5);
                                } else if (isInRange) {
                                  backgroundColor =
                                      Colors.blue.withOpacity(0.3);
                                } else {
                                  backgroundColor = Colors.transparent;
                                }
                                return GestureDetector(
                                  onTap: () {
                                    // Check if the date is unavailable or on hold
                                    if (isHold || isUnavailable || isPastDate) {
                                      return; // If so, do not allow selection
                                    }
                                    setState(() {
                                      if (_startDate == null) {
                                        _startDate = currentDate;
                                        _endDate = null;
                                      } else if (_endDate == null) {
                                        if (currentDate.isBefore(_startDate!)) {
                                          _endDate = _startDate;
                                          _startDate = currentDate;
                                        } else {
                                          _endDate = currentDate;
                                        }
                                      } else {
                                        _startDate = currentDate;
                                        _endDate = null;
                                      }
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${currentDate.day}${displayText != null ? '\n$displayText' : ''}',
                                            style: TextStyle(
                                              color: isUnavailable ||
                                                      isStartSelected ||
                                                      isEndSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (iconData != null)
                                        Icon(
                                          iconData,
                                          color: Colors
                                              .red, // Customize cross icon color
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child:
                                Icon(Icons.arrow_drop_up, color: Colors.grey),
                          ),
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child:
                                Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: const Text('Need Delivery? +RM35'),
                            value: _needDelivery,
                            onChanged: (value) {
                              setState(() {
                                _needDelivery = value!;
                              });
                            },
                          ),
                          if (_needDelivery)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Delivery Location',
                                  hintText: 'Enter your delivery location',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'RM ${calculateTotalPrice().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                if (_startDate == null || _endDate == null) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Select Date Range'),
                        content: const Text(
                            'Please select a date range before confirming the booking.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (_holdDates.any((date) =>
                        date.isAfter(_startDate!) &&
                        date.isBefore(_endDate!)) &&
                    _unavailableDates.any((date) =>
                        date.isAfter(_startDate!) &&
                        date.isBefore(_endDate!))) {
                  // Check if any date in the selected range is both on hold and full
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Booking Not Available'),
                        content: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Some dates in the selected range are ',
                              ),
                              TextSpan(
                                text: 'FULL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' and on ',
                              ),
                              TextSpan(
                                text: 'HOLD',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '. Please choose a different date range.',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (_holdDates.any((date) =>
                    date.isAfter(_startDate!) && date.isBefore(_endDate!))) {
                  // Check if any date in the selected range is on hold
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Booking Not Available'),
                        content: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Some dates in the selected range are ',
                              ),
                              TextSpan(
                                text: 'HOLD',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '. Please choose a different date range.',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (_unavailableDates.any((date) =>
                    date.isAfter(_startDate!) && date.isBefore(_endDate!))) {
                  // Check if any date in the selected range is full
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Booking Not Available'),
                        content: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Some dates in the selected range are ',
                              ),
                              TextSpan(
                                text: 'FULL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '. Please choose a different date range.',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Are You Sure to Rent the Car?'),
                          content: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black),
                              children: [
                                TextSpan(text: 'Press '),
                                TextSpan(
                                    text: 'YES',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: ' to continue with your booking. '),
                                TextSpan(
                                    text: 'PLEASE',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text:
                                        ' make payment within last 3 days to avoid auto cancellation.'),
                                TextSpan(
                                    text:
                                        ' If you wish to book for today, tomorrow, and the day after tomorrow, payment is required immediately. Failure to make the payment will result in automatic cancellation of the booking. Press '),
                                TextSpan(
                                    text: 'NO',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: ' to return to the previous page.'),
                              ],
                            ),
                          ),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      DateTime endDateWithTime = _endDate!.add(
                                          const Duration(
                                              hours: 23,
                                              minutes: 59,
                                              seconds: 59));

                                      DocumentReference bookingRef =
                                          await FirebaseFirestore.instance
                                              .collection('Bookings')
                                              .add({
                                        'carId': widget.car.id,
                                        'startDate':
                                            Timestamp.fromDate(_startDate!),
                                        'endDate':
                                            Timestamp.fromDate(endDateWithTime),
                                        'delivery': _needDelivery,
                                        'deliveryLocation':
                                            _locationController.text,
                                        'totalPrice': calculateTotalPrice(),
                                        'status': 'pending payment',
                                        'userId': user.uid,
                                        'userEmail': user.email,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentPage(
                                            totalPrice: calculateTotalPrice(),
                                            bookingId: bookingRef.id,
                                            carId: widget.car.id,
                                            startDate: _startDate!,
                                            endDate: endDateWithTime,
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'YES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 10), // Add spacing between buttons
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'NO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('User Not Logged In'),
                          content:
                              const Text('Please log in to confirm your booking.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  double calculateTotalPrice() {
    if (_startDate == null || _endDate == null) {
      return 0.00;
    }
    double pricePerDay = double.tryParse(widget.car['price'].toString()) ?? 0.0;
    int numberOfDays = _endDate!.difference(_startDate!).inDays + 1;
    double deliveryFee = _needDelivery ? 35.0 : 0.0;
    double totalPrice = (pricePerDay * numberOfDays) + deliveryFee;
    return totalPrice;
  }
}
