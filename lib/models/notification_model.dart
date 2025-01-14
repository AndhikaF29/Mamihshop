class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String orderId;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.orderId,
    required this.createdAt,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'orderId': orderId,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
