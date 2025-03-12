import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_cras/components/payment_config.dart';
import 'package:fyp_cras/pages/payment_success_page.dart';
import 'package:pay/pay.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatelessWidget {
  final double totalPrice;
  final String bookingId;
  final String carId;
  final DateTime startDate;
  final DateTime endDate;

  const PaymentPage({
    super.key,
    required this.totalPrice,
    required this.bookingId,
    required this.carId,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Cars').doc(carId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final carData = snapshot.data!.data() as Map<String, dynamic>;
          final carModel = carData['model'] ?? 'Unknown';
          final carBrand = carData['brand'] ?? 'Unknown';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Car:',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$carBrand $carModel',
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Date:',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Total Price:',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RM ${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                ApplePayButton(
                  paymentConfiguration:
                      PaymentConfiguration.fromJsonString(defaultApplePay),
                  paymentItems: _getPaymentItems(),
                  style: ApplePayButtonStyle.black,
                  width: 350,
                  height: 50,
                  type: ApplePayButtonType.buy,
                  margin: const EdgeInsets.only(top: 15.0),
                  onPaymentResult: (result) async {
                    await _handlePaymentResult(
                        context, result, carBrand, carModel);
                  },
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 50),
                GooglePayButton(
                  paymentConfiguration:
                      PaymentConfiguration.fromJsonString(defaultGooglePay),
                  paymentItems: _getPaymentItems(),
                  type: GooglePayButtonType.pay,
                  width: 350,
                  height: 50,
                  margin: const EdgeInsets.only(top: 15.0),
                  onPaymentResult: (result) async {
                    await _handlePaymentResult(
                        context, result, carBrand, carModel);
                  },
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PaymentItem> _getPaymentItems() {
    return [
      PaymentItem(
        label: 'Total',
        amount: totalPrice.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];
  }

  Future<void> _handlePaymentResult(BuildContext context,
      Map<String, dynamic> result, String carBrand, String carModel) async {
    // Update booking status to 'payment done' in Firestore
    await FirebaseFirestore.instance
        .collection('Bookings')
        .doc(bookingId)
        .update({'status': 'payment done'});

    // Navigate to the payment successful page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessfulPage(
          bookingId: bookingId,
          carBrand: carBrand,
          carModel: carModel,
          totalPrice: totalPrice,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }
}
