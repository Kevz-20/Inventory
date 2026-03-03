import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../models/notification_item.dart';
import '../../providers/db_service_provider.dart';
import '../../providers/notification_provider';
import '../../providers/unread_notif_count_provider.dart';
import '../widgets/notification_3d_card.dart';


class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _didMarkSeen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeenIfPossible());
  }

  Future<void> _markSeenIfPossible() async {
    if (_didMarkSeen) return;

    final asyncItems = ref.read(notificationsStreamProvider);
    final items = asyncItems.maybeWhen(
      data: (data) => data,
      orElse: () => const <AppNotificationItem>[],
    );

    if (items.isEmpty) return;

    _didMarkSeen = true;

    final db = await ref.read(databaseProvider.future);
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final n in items) {
      batch.execute('''
        INSERT INTO notif_state (notif_id, seen, seen_at)
        VALUES (?, 1, ?)
        ON CONFLICT(notif_id) DO UPDATE SET seen=1, seen_at=?
      ''', [n.id, now, now]);
    }

    await batch.commit(noResult: true);

    ref.invalidate(unreadNotifCountProvider);
  }

  IconData _iconFor(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:
        return Icons.event_available_rounded;
      case AppNotifType.customerUtangDueToday:
        return Icons.warning_amber_rounded;
      case AppNotifType.lowStock:
        return Icons.inventory_2_rounded;
    }
  }

  String _badgeText(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:
        return 'PAYABLE';
      case AppNotifType.customerUtangDueToday:
        return 'DUE TODAY';
      case AppNotifType.lowStock:
        return 'LOW STOCK';
    }
  }

  double _badgeOpacity(AppNotifType type) {
    switch (type) {
      case AppNotifType.customerUtangDueToday:
        return 0.18;
      case AppNotifType.ownerPayableSoon:
        return 0.14;
      case AppNotifType.lowStock:
        return 0.12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsStreamProvider);

    // ✅ once it becomes data, mark seen
    async.whenData((_) => Future.microtask(_markSeenIfPossible));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerTop, AppColors.headerBottom],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No notifications right now.',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.75),
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You’re all caught up.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
              await ref.read(notificationsStreamProvider.future);
              _didMarkSeen = false; // allow re-mark after refresh
              await _markSeenIfPossible();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = items[i];

                return Notification3DCard(
                  icon: _iconFor(n.type),
                  badgeText: _badgeText(n.type),
                  badgeOpacity: _badgeOpacity(n.type),
                  title: n.title,
                  message: n.message,
                  dueText: n.dueDate == null
                      ? null
                      : 'Due: ${n.dueDate!.toLocal().toString().split(" ").first}',
                  onTap: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// keep your _Notification3DCard unchanged below