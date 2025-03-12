import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fyp_cras/admin_pages/display_user_chat_page.dart';
import 'package:fyp_cras/components/drawer_admin.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  void signOut() async {
    FirebaseAuth.instance.signOut();
  }

  void goToChatPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayUserChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
      ),
      drawer: const AdminDrawer(), // Use the AdminDrawer here
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Back !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'SMP Car Rental Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Car Availability',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('Cars').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final carsDocs = snapshot.data!.docs;
                int availableCount = 0;
                int unavailableCount = 0;

                for (var doc in carsDocs) {
                  bool available = doc['available'];
                  if (available) {
                    availableCount++;
                  } else {
                    unavailableCount++;
                  }
                }

                return PieChartSample2(
                  availableCount: availableCount,
                  unavailableCount: unavailableCount,
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'Total Price Earning This Month',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('Bookings').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final bookingsDocs = snapshot.data!.docs;
                double totalEarnings = 0;

                for (var doc in bookingsDocs) {
                  Timestamp startDate = doc['startDate'];
                  DateTime startDateTime = startDate.toDate();
                  DateTime now = DateTime.now();

                  if (startDateTime.year == now.year &&
                      startDateTime.month == now.month) {
                    totalEarnings += doc['totalPrice'];
                  }
                }

                return Column(
                  children: [
                    Text(
                      'Total Earnings: RM ${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalEarnings,
                              color: Colors.blue,
                              title: 'Earnings',
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToChatPage(context),
        backgroundColor: Colors.grey[200],
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class PieChartSample2 extends StatefulWidget {
  final int availableCount;
  final int unavailableCount;

  const PieChartSample2({
    super.key,
    required this.availableCount,
    required this.unavailableCount,
  });

  @override
  State<StatefulWidget> createState() => PieChart2State();
}

class PieChart2State extends State<PieChartSample2> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Indicator(
                color: Colors.green,
                text: 'Available',
                isSquare: true,
              ),
              SizedBox(
                height: 4,
              ),
              Indicator(
                color: Colors.red,
                text: 'Unavailable',
                isSquare: true,
              ),
              SizedBox(
                height: 18,
              ),
            ],
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final isTouchedAvailable = 0 == touchedIndex;
    final isTouchedUnavailable = 1 == touchedIndex;
    final fontSizeAvailable = isTouchedAvailable ? 25.0 : 16.0;
    final radiusAvailable = isTouchedAvailable ? 60.0 : 50.0;
    final fontSizeUnavailable = isTouchedUnavailable ? 25.0 : 16.0;
    final radiusUnavailable = isTouchedUnavailable ? 60.0 : 50.0;
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

    return [
      PieChartSectionData(
        color: Colors.green,
        value: widget.availableCount.toDouble(),
        title:
            '${(widget.availableCount / (widget.availableCount + widget.unavailableCount) * 100).toStringAsFixed(1)}%',
        radius: radiusAvailable,
        titleStyle: TextStyle(
          fontSize: fontSizeAvailable,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: widget.unavailableCount.toDouble(),
        title:
            '${(widget.unavailableCount / (widget.availableCount + widget.unavailableCount) * 100).toStringAsFixed(1)}%',
        radius: radiusUnavailable,
        titleStyle: TextStyle(
          fontSize: fontSizeUnavailable,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      ),
    ];
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;

  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff505050),
          ),
        ),
      ],
    );
  }
}
