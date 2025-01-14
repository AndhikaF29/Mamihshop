import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  String _formatPrice(num price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
        return '#2196F3'; // Blue
      case 'menunggu pembayaran':
        return '#FFA726'; // Orange
      case 'dikirim':
        return '#8E24AA'; // Purple
      case 'selesai':
        return '#4CAF50'; // Green
      case 'dibatalkan':
        return '#F44336'; // Red
      default:
        return '#250902'; // Default Blue untuk 'Diproses'
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
        return 'Diproses';
      case 'menunggu pembayaran':
        return 'Menunggu Pembayaran';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Saya'),
          backgroundColor: const Color(0xFFC9184A),
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: const Color(0xFFC9184A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('checkouts')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          print('Current userId: ${user.uid}');
          print('Connection state: ${snapshot.connectionState}');
          print('Has error: ${snapshot.hasError}');
          print('Error: ${snapshot.error}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final order =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final shippingAddress =
                  order['shippingAddress'] as Map<String, dynamic>;
              final timestamp = (order['createdAt'] as Timestamp).toDate();
              final items = (order['items'] as List?) ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Order : ${order['checkoutId']?.toString().substring(2, 8) ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(int.parse(_getStatusColor(
                                        order['orderStatus'] ?? 'pending')
                                    .replaceAll('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatStatus(
                                    order['orderStatus'] ?? 'pending'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.payment,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Pembayaran: ${order['paymentMethod'] ?? '-'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Alamat: ${shippingAddress['fullAddress'] ?? '-'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pesanan',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Rp${_formatPrice(order['totalPrice'] ?? 0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC9184A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
