import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = 'Status Pesanan Berubah';
    String message = 'Pesanan $orderId telah $status';

    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}