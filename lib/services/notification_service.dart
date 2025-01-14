import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notifKey = 'notifications';
  OverlayEntry? _overlayEntry;

  Future<void> createNotification({
    required String userId,
    required String orderId,
    required String status,
    BuildContext? context,
  }) async {
    // Simpan ke storage
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> notifications = [];
    String? existingNotifs = prefs.getString('notifications');
    if (existingNotifs != null) {
      notifications =
          List<Map<String, dynamic>>.from(jsonDecode(existingNotifs));
    }

    notifications.add({
      'userId': userId,
      'title': 'Status Pesanan Berubah',
      'message': 'Pesanan $orderId telah $status',
      'orderId': orderId,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });

    await prefs.setString('notifications', jsonEncode(notifications));

    // Tampilkan notifikasi popup
    if (context != null) {
      _showOverlayNotification(
        context: context,
        title: 'Status Pesanan Berubah',
        message: 'Pesanan $orderId telah $status',
      );
    }
  }

  void _showOverlayNotification({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    // Hapus overlay sebelumnya jika ada
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: AnimationController(
                vsync: Navigator.of(context),
                duration: const Duration(milliseconds: 300),
              )..forward(),
              curve: Curves.easeOut,
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFC9184A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Hapus notifikasi setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? notifs = prefs.getString(_notifKey);
    if (notifs == null) return [];

    List<Map<String, dynamic>> allNotifs =
        List<Map<String, dynamic>>.from(jsonDecode(notifs));
    return allNotifs.where((notif) => notif['userId'] == userId).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt'])
          .compareTo(DateTime.parse(a['createdAt'])));
  }

  Future<void> checkOrderStatus(String orderId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String lastStatusKey = 'lastStatus_$orderId';
    String? lastStatus = prefs.getString(lastStatusKey);

    // Ambil status terbaru dari Firebase
    final orderDoc = await FirebaseFirestore.instance
        .collection('checkouts')
        .doc(orderId)
        .get();

    if (orderDoc.exists) {
      String currentStatus = orderDoc.data()?['orderStatus'];

      // Jika status berubah, buat notifikasi
      if (lastStatus != null && lastStatus != currentStatus) {
        await createNotification(
          userId: userId,
          orderId: orderId,
          status: currentStatus,
        );
      }

      // Simpan status terbaru
      await prefs.setString(lastStatusKey, currentStatus);
    }
  }
}
