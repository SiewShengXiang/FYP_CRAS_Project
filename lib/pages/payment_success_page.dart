import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_cras/pages/home_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PaymentSuccessfulPage extends StatefulWidget {
  final String bookingId;
  final String carBrand;
  final String carModel;
  final double totalPrice;
  final DateTime startDate;
  final DateTime endDate;

  const PaymentSuccessfulPage({
    super.key,
    required this.bookingId,
    required this.carBrand,
    required this.carModel,
    required this.totalPrice,
    required this.startDate,
    required this.endDate,
  });

  @override
  _PaymentSuccessfulPageState createState() => _PaymentSuccessfulPageState();
}

class _PaymentSuccessfulPageState extends State<PaymentSuccessfulPage> {
  int _counter = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 0) {
          _counter--;
        } else {
          timer.cancel();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Automatically returning to Home in $_counter seconds',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(
              Icons.check_circle,
              color: Colors.yellow,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment successful',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBookingDetails(),
            const SizedBox(height: 24),
            SizedBox(
              width: 350, // Fixed width for both buttons
              child: ElevatedButton(
                onPressed: () {
                  _generateAndPrintPdf(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Download Receipt'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 350, // Fixed width for both buttons
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Reference ID:', widget.bookingId),
        _buildDetailRow(
          'Date:',
          '${DateFormat('dd/MM/yyyy').format(widget.startDate)} to ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
        ),
        _buildDetailRow(
            'Amount:', 'RM ${widget.totalPrice.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildDetailRow(String title, String data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    _buildDataRow('Booking ID:', widget.bookingId),
                    _buildDataRow(
                      'Car:',
                      '${widget.carBrand} ${widget.carModel}',
                    ),
                    _buildDataRow(
                      'Date:',
                      '${DateFormat('dd/MM/yyyy').format(widget.startDate)} to ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
                    ),
                    _buildDataRow(
                      'Total Price:',
                      'RM ${widget.totalPrice.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Thank you for your payment!',
                  style: const pw.TextStyle(fontSize: 20),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.TableRow _buildDataRow(String title, String data) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 16),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            data,
            style: const pw.TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
