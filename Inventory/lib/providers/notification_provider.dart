import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../repositories/notification_repository.dart';
import 'db_service_provider.dart';

final notificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future); // ✅ uses DBService
  final repo = NotificationRepository(db);
  return repo.buildNotifications();
});