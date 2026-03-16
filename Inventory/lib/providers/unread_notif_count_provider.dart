import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/db_service_provider.dart';
import '../repositories/notification_repository.dart';

final unreadNotifCountProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  final repo = NotificationRepository(db);

  final controller = StreamController<int>();

  Future<void> emit() async {
    final items = await repo.buildNotifications();

    if (items.isEmpty) {
      if (!controller.isClosed) controller.add(0);
      return;
    }

    final ids = items.map((e) => e.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    final rows = await db.rawQuery('''
      SELECT notif_id, seen
      FROM notif_state
      WHERE notif_id IN ($placeholders)
    ''', ids);

    final seenMap = <String, int>{};
    for (final r in rows) {
      seenMap[r['notif_id'] as String] = (r['seen'] as int?) ?? 0;
    }

    int unread = 0;
    for (final n in items) {
      final seen = seenMap[n.id] ?? 0; // default unseen
      if (seen == 0) unread++;
    }

    if (!controller.isClosed) controller.add(unread);
  }

  // emit immediately
  await emit();

  // poll every 3 seconds
  final timer = Timer.periodic(const Duration(seconds: 3), (_) => emit());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  yield* controller.stream;
});