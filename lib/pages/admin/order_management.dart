import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class OrderManagement {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('checkouts').doc(orderId).update({
        'orderStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ambil data checkout untuk mendapatkan userId
      DocumentSnapshot checkout =
          await _firestore.collection('checkouts').doc(orderId).get();
      String userId = (checkout.data() as Map<String, dynamic>)['userId'];

      // Buat notifikasi
      await NotificationService().createNotification(
        userId: userId,
        orderId: orderId,
        status: newStatus,
      );
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}
