import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

class CheckoutTableScreen extends StatelessWidget {
  const CheckoutTableScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Tabel Pesanan', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF758F),
                Color(0xFFFF4D6D),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('checkouts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final checkouts = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 900,
              columns: const [
                DataColumn2(
                  label: Text('ID Pesanan'),
                  size: ColumnSize.S,
                ),
                DataColumn(
                  label: Text('Tanggal'),
                ),
                DataColumn(
                  label: Text('Pelanggan'),
                ),
                DataColumn(
                  label: Text('Total'),
                ),
                DataColumn(
                  label: Text('Status Pesanan'),
                ),
                DataColumn(
                  label: Text('Pembayaran'),
                ),
                DataColumn(
                  label: Text('Alamat'),
                ),
              ],
              rows: checkouts.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        doc.id.substring(0, 8),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(
                          (data['createdAt'] as Timestamp).toDate(),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(data['userEmail'] ?? ''),
                          Text(
                            data['contactPhone'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(data['totalPrice']),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(data['orderStatus']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['orderStatus'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(data['paymentMethod'] ?? ''),
                          Text(
                            data['paymentStatus'] ?? '',
                            style: TextStyle(
                              color: data['paymentStatus'] == 'selesai'
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: data['shippingAddress']['fullAddress'] ?? '',
                        child: Text(
                          data['shippingAddress']['fullAddress'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'dikemas':
        return Colors.blue;
      case 'dikirim':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
