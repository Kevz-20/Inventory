enum AppNotifType {
  ownerPayableSoon,
  customerUtangDueToday,
  lowStock,
}

class AppNotificationItem {
  final String id;
  final AppNotifType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? refId;

  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.dueDate,
    this.refId,
  });
}