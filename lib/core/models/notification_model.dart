class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool read;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: (j['id'] ?? j['_id']).toString(),
        title: (j['title'] ?? 'Notification').toString(),
        message: (j['message'] ?? j['content'] ?? '').toString(),
        read: (j['read'] == true) || (j['isRead'] == true),
        createdAt: (j['createdAt'] ?? j['date'])?.toString(),
      );
}
