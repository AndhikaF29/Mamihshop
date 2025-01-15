import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  // Define consistent colors
  final Color primaryColor = const Color.fromARGB(255, 241, 57, 109);
  final Color accentColor = const Color.fromARGB(255, 235, 35, 38);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF2C3E50);
  final Color textSecondaryColor = const Color(0xFF7F8C8D);

  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return '#4CAF50';
      case 'diproses':
        return '#2196F3';
      case 'menunggu':
        return '#FFC107';
      case 'dibatalkan':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 241, 57, 109),
                Color.fromARGB(255, 235, 35, 38),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('checkouts')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: textSecondaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Pesanan tidak ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String statusColor = _getStatusColor(data['orderStatus']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID Pesanan',
                                  style: TextStyle(
                                    color: textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${data['checkoutId']}',
                                  style: TextStyle(
                                    color: textPrimaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                    '0xFF${statusColor.substring(1)}')),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${data['orderStatus']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 32),
                        _buildInfoRow(
                          'Total Pembayaran',
                          formatCurrency.format(data['totalPrice']),
                          isHighlighted: true,
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(
                          'Metode Pembayaran',
                          data['paymentMethod'],
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Status Pembayaran',
                          data['paymentStatus'],
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Total Item',
                          '${data['totalItems']} item',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Shipping Address Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Alamat Pengiriman',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 20,
                                    color: textSecondaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data['shippingAddress']['fullAddress'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textPrimaryColor,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                    color: textSecondaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    data['contactPhone'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? primaryColor : textPrimaryColor,
            fontSize: isHighlighted ? 18 : 15,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
